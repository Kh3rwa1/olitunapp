import type { App } from '../env';
import {
  computeCacheKey,
  INDICTRANS2_TARGETS,
  M2M100_LANGS,
  translateWithAiLlama,
  translateWithGoogle,
  translateWithM2M100,
  translateWithWorkersAi,
} from '../lib/translate';

export function registerTranslateRoutes(app: App): void {
  // 8. Translation (AI IndicTrans2 via Workers AI + Instant Google Translate + D1 Caching)
  app.all('/api/v1/translate', async (c) => {
    try {
      let text = '';
      let from = 'auto';
      let to = 'sat';
      let engine = 'google';

      if (c.req.method === 'POST') {
        const body = await c.req.json().catch(() => ({}));
        text = body?.text || '';
        from = body?.from || 'auto';
        to = body?.to || 'sat';
        engine = (body?.engine || body?.provider || 'google').toLowerCase();
      } else {
        text = c.req.query('text') || '';
        from = c.req.query('from') || 'auto';
        to = c.req.query('to') || 'sat';
        engine = (c.req.query('engine') || 'google').toLowerCase();
      }

      if (!text || text.trim().length === 0) {
        return c.json({ success: false, error: 'INVALID_INPUT', message: 'Missing text parameter' }, 400);
      }

      text = text.trim();
      if (text.length > 5000) {
        return c.json({ success: false, error: 'INPUT_TOO_LONG', message: 'Text too long (max 5000 chars)' }, 400);
      }

      // A. Check D1 Cache
      const cacheKey = await computeCacheKey(from, to, text, engine);
      try {
        const cached = await c.env.DB.prepare(
          'SELECT translated_text, from_lang, to_lang, engine FROM translation_cache WHERE cache_key = ?'
        ).bind(cacheKey).first();

        if (cached && (cached as any).translated_text) {
          return c.json({
            success: true,
            data: {
              translation: (cached as any).translated_text,
              detectedLanguage: (cached as any).from_lang,
              detectedLanguageCode: (cached as any).from_lang,
              translatedText: (cached as any).translated_text,
              from: (cached as any).from_lang,
              to: (cached as any).to_lang,
              cached: true,
              provider: (cached as any).engine,
            }
          });
        }
      } catch (_) {
        // cache miss or table lookup issue
      }

      // B. Execute Translation
      let result: { translation: string; detectedLanguage: string; provider: string };
      const isGoogleDefault = engine === 'google' || engine === 'vitalets' || engine === 'instant';

      if (isGoogleDefault) {
        // Google Translate as default for instant translation
        try {
          result = await translateWithGoogle(text, from, to);
        } catch (err: any) {
          // Fallback to Workers AI if Google is temporarily unreachable
          const targetTag = INDICTRANS2_TARGETS[to.toLowerCase()];
          const isEnglishOrAuto = from === 'auto' || from === 'en' || from === 'eng';
          if (isEnglishOrAuto && targetTag && c.env.AI) {
            const aiRes = await translateWithWorkersAi(c.env.AI, text, targetTag);
            result = { translation: aiRes.translation, detectedLanguage: 'en', provider: 'cloudflare-indictrans2-ai-fallback' };
          } else if (c.env.AI) {
            const llamaRes = await translateWithAiLlama(c.env.AI, text, from, to);
            result = { translation: llamaRes.translation, detectedLanguage: from, provider: 'cloudflare-llama-ai-fallback' };
          } else {
            throw err;
          }
        }
      } else {
        // Cloudflare Workers AI explicitly requested (IndicTrans2 / M2M100)
        const targetTag = INDICTRANS2_TARGETS[to.toLowerCase()];
        const isEnglishOrAuto = from === 'auto' || from === 'en' || from === 'eng';

        if (isEnglishOrAuto && targetTag && c.env.AI) {
          try {
            const aiRes = await translateWithWorkersAi(c.env.AI, text, targetTag);
            result = { translation: aiRes.translation, detectedLanguage: 'en', provider: aiRes.provider };
          } catch (_) {
            result = await translateWithGoogle(text, from, to);
          }
        } else if (M2M100_LANGS[to.toLowerCase()] && c.env.AI) {
          try {
            const m2mRes = await translateWithM2M100(c.env.AI, text, from, to);
            result = { translation: m2mRes.translation, detectedLanguage: from, provider: m2mRes.provider };
          } catch (_) {
            result = await translateWithGoogle(text, from, to);
          }
        } else {
          result = await translateWithGoogle(text, from, to);
        }
      }

      // C. Save to D1 Cache
      try {
        await c.env.DB.prepare(
          'INSERT OR REPLACE INTO translation_cache (cache_key, from_lang, to_lang, source_text, translated_text, engine, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)'
        ).bind(cacheKey, result.detectedLanguage, to, text, result.translation, result.provider, Date.now()).run();
      } catch (_) {
        // ignore cache write error
      }

      return c.json({
        success: true,
        data: {
          translation: result.translation,
          detectedLanguage: result.detectedLanguage,
          detectedLanguageCode: result.detectedLanguage,
          translatedText: result.translation,
          from: result.detectedLanguage,
          to: to,
          cached: false,
          provider: result.provider,
        }
      });
    } catch (err: any) {
      return c.json({
        success: false,
        error: 'TRANSLATION_ERROR',
        message: err.message || 'Translation service failed',
      }, 500);
    }
  });
}
