import { stableId, type App } from '../env';
import { bodhanApiKeys } from '../lib/bodhan';
import {
  AllKeysFailedError,
  BadRequestError,
  classifyBodhanFailure,
  withKeyRotation,
} from '../key_rotation';

export function registerVoiceRoutes(app: App): void {
  // 21. Santali Voice Synthesis (replaces Appwrite santaliVoice function)

  // 21. Santali Voice Synthesis (Bodhan Indic-Speak TTS Engine with Edge R2 Caching)
  app.post('/api/v1/voice/synthesize', async (c) => {
    try {
      const body = await c.req.json().catch(() => ({}));
      const text = String(body.text || '').trim();
      if (!text) {
        return c.json({ ok: false, success: false, message: 'Missing text parameter' }, 400);
      }

      const rawVoice = String(body.voiceId || body.voice || 'Phulmani').trim();
      const voiceId = rawVoice.toLowerCase().includes('sibu') ? 'Sibu' : 'Phulmani';
      const style = String(body.style || '').trim();
      const lang = String(body.lang || 'sat').trim();
      const cacheKey = await stableId(`${voiceId}:${style}:${text}`);
      const r2Key = `voice/${cacheKey}.wav`;

      // 1. Check D1 TTS cache
      const cached: any = await c.env.DB.prepare(
        'SELECT audio_url, duration_ms FROM tts_cache WHERE cache_key = ?'
      ).bind(cacheKey).first().catch(() => null);

      if (cached && !cached.audio_url.includes('/api/v1/audio/stream')) {
        return c.json({
          ok: true,
          success: true,
          cached: true,
          audioUrl: cached.audio_url,
          durationMs: cached.duration_ms,
          data: {
            audioUrl: cached.audio_url,
            voice: voiceId,
            lang,
            style,
            chars: text.length,
            cached: true,
          },
        });
      }

      // 2. Check if already stored in R2
      const existingR2 = await c.env.ASSETS.get(r2Key).catch(() => null);
      if (existingR2) {
        const audioUrl = `https://olitun-api.dulalkisku0.workers.dev/api/v1/assets/${r2Key}`;
        const durationMs = Math.max(1500, Math.round(text.length * 150));
        await c.env.DB.prepare(
          'INSERT OR REPLACE INTO tts_cache (cache_key, text_hash, voice_id, audio_url, duration_ms, created_at) VALUES (?, ?, ?, ?, ?, ?)'
        ).bind(cacheKey, cacheKey, voiceId, audioUrl, durationMs, new Date().toISOString()).run().catch(() => {});

        return c.json({
          ok: true,
          success: true,
          cached: true,
          audioUrl,
          durationMs,
          data: {
            audioUrl,
            voice: voiceId,
            lang,
            style,
            chars: text.length,
            cached: true,
          },
        });
      }

      // 3. Synthesize via Bodhan Indic-Speak, rotating round-robin across the
      // configured accounts and skipping any that are out of credit.
      const normStyle = style.toLowerCase();
      const validStyle = (normStyle === 'news' || normStyle === 'surprise') ? normStyle : '';
      const instructionVariants = validStyle
        ? [JSON.stringify({ lang: 'sat', style: validStyle }), JSON.stringify({ lang: 'sat' })]
        : [JSON.stringify({ lang: 'sat' })];

      const bodhanKeys = bodhanApiKeys(c.env);
      if (bodhanKeys.length === 0) {
        return c.json({ ok: false, success: false, error: 'VOICE_KEY_MISSING', message: 'Voice service is not configured.' }, 503);
      }
      const bodhanUrl = `${c.env.BODHAN_API_BASE || 'https://api.bodhan.ai'}/v1/audio/speech`;

      const synthesizeWithKey = async (key: string): Promise<ArrayBuffer> => {
        let lastFailure: Error | null = null;
        for (let i = 0; i < instructionVariants.length; i++) {
          let bodhanRes: Response;
          try {
            bodhanRes = await fetch(bodhanUrl, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${key}` },
              body: JSON.stringify({ model: 'indic-speak', input: text, voice: voiceId, instructions: instructionVariants[i] }),
            });
          } catch (_) {
            throw classifyBodhanFailure(0, 'network error');
          }
          if (bodhanRes.ok) {
            const buf = await bodhanRes.arrayBuffer();
            if (buf.byteLength > 100) return buf;
            throw classifyBodhanFailure(502, 'empty audio');
          }
          const failure = classifyBodhanFailure(bodhanRes.status, await bodhanRes.text().catch(() => ''));
          // A styled request may be rejected while the plain one works.
          if (failure instanceof BadRequestError && i < instructionVariants.length - 1) {
            lastFailure = failure;
            continue;
          }
          throw failure;
        }
        throw lastFailure || classifyBodhanFailure(502, '');
      };

      let audioBuffer: ArrayBuffer;
      try {
        audioBuffer = await withKeyRotation(
          c.env.DB,
          'bodhan',
          bodhanKeys,
          synthesizeWithKey,
          (p) => c.executionCtx.waitUntil(p),
        );
      } catch (err) {
        if (err instanceof BadRequestError) {
          return c.json({ ok: false, success: false, error: 'BAD_REQUEST', message: err.message }, 422);
        }
        const creditEnded = err instanceof AllKeysFailedError && err.creditEnded;
        return c.json({
          ok: false,
          success: false,
          error: creditEnded ? 'VOICE_CREDITS_EXHAUSTED' : 'VOICE_UNAVAILABLE',
          message: creditEnded
            ? 'All voice keys are out of credit or invalid. Please try again later.'
            : 'Santali voice engine is currently reaching capacity. Please try again in a few moments.',
        }, 503);
      }

      const durationMs = Math.max(1500, Math.round(text.length * 150));
      await c.env.ASSETS.put(r2Key, audioBuffer, {
        httpMetadata: { contentType: 'audio/wav' },
      }).catch(() => {});
      const audioUrl = `https://olitun-api.dulalkisku0.workers.dev/api/v1/assets/${r2Key}`;

      const now = new Date().toISOString();
      await c.env.DB.prepare(
        'INSERT OR REPLACE INTO tts_cache (cache_key, text_hash, voice_id, audio_url, duration_ms, created_at) VALUES (?, ?, ?, ?, ?, ?)'
      ).bind(cacheKey, cacheKey, voiceId, audioUrl, durationMs, now).run().catch(() => {});

      return c.json({
        ok: true,
        success: true,
        cached: false,
        audioUrl,
        durationMs,
        data: {
          audioUrl,
          voice: voiceId,
          lang,
          style,
          chars: text.length,
          cached: false,
        },
      });
    } catch (err: any) {
      return c.json({ ok: false, success: false, message: err.message || 'Voice synthesis failed' }, 500);
    }
  });

  // 21b. Stream Synthesized / Generated Audio (serves audio streams for just_audio & ExoPlayer)
  app.all('/api/v1/audio/stream', async (c) => {
    try {
      const url = new URL(c.req.url);
      const trackId = url.searchParams.get('trackId') || '';

      let targetAudioUrl = '';

      if (trackId) {
        const track: any = await c.env.DB.prepare(
          'SELECT audio_url FROM audio_tracks WHERE id = ?'
        ).bind(trackId).first().catch(() => null);
        if (track?.audio_url && !track.audio_url.includes('/api/v1/audio/stream')) {
          targetAudioUrl = track.audio_url;
        }
      }

      if (!targetAudioUrl) {
        return c.text('Audio track not found', 404);
      }

      const range = c.req.header('range');
      const fetchHeaders: Record<string, string> = {
        'User-Agent': 'OlitunEdgeAudio/1.0',
      };
      if (range) {
        fetchHeaders['Range'] = range;
      }

      const upstreamRes = await fetch(targetAudioUrl, {
        method: c.req.method === 'HEAD' ? 'HEAD' : 'GET',
        headers: fetchHeaders,
      });

      const responseHeaders = new Headers();
      responseHeaders.set('Content-Type', upstreamRes.headers.get('content-type') || 'audio/x-wav');
      responseHeaders.set('Accept-Ranges', 'bytes');
      responseHeaders.set('Access-Control-Allow-Origin', '*');
      responseHeaders.set('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
      responseHeaders.set('Access-Control-Allow-Headers', '*');
      responseHeaders.set('Cache-Control', 'public, max-age=86400');

      if (upstreamRes.headers.has('content-range')) {
        responseHeaders.set('Content-Range', upstreamRes.headers.get('content-range')!);
      }
      if (upstreamRes.headers.has('content-length')) {
        responseHeaders.set('Content-Length', upstreamRes.headers.get('content-length')!);
      }

      return new Response(upstreamRes.body, {
        status: upstreamRes.status,
        headers: responseHeaders,
      });
    } catch (err: any) {
      return c.json({ ok: false, error: 'AUDIO_STREAM_FAILED', message: err.message }, 500);
    }
  });

  // 22. Generate Audio (replaces Appwrite generateAudio function)
  app.post('/api/v1/audio/generate', async (c) => {
    try {
      const body = await c.req.json().catch(() => ({}));
      const text = String(body.text || '').trim();
      if (!text) {
        return c.json({ ok: false, message: 'Missing text' }, 400);
      }

      const title = String(body.title || text.slice(0, 30)).trim();
      const language = String(body.language || 'sat').trim();
      const trackId = await stableId(`track:${text}:${Date.now()}`);
      const audioUrl = `https://olitun-api.dulalkisku0.workers.dev/api/v1/audio/stream?trackId=${trackId}`;
      const now = new Date().toISOString();

      await c.env.DB.prepare(
        'INSERT INTO audio_tracks (id, title, language, category, audio_url, duration_seconds, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
      ).bind(trackId, title, language, 'lesson_speech', audioUrl, 3.5, 'published', now).run();

      return c.json({
        ok: true,
        track: {
          id: trackId,
          title,
          language,
          audioUrl,
          durationSeconds: 3.5,
        }
      });
    } catch (err: any) {
      return c.json({ ok: false, message: err.message || 'Audio generation failed' }, 500);
    }
  });
}
