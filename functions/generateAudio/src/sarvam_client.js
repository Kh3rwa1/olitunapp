import {
  DEFAULT_MODEL,
  FALLBACK_MODEL,
  clampPace,
} from './validation.js';

const SARVAM_TTS_URL = 'https://api.sarvam.ai/text-to-speech';

/**
 * Calls the Sarvam AI bulbul TTS API for a single speech request.
 *
 * Mirrors the contract of scripts/generate_audio_sarvam.mjs:
 * - model preference bulbul:v4 with automatic fallback to bulbul:v3
 *   when the key's tier does not have v4 enabled (400/404)
 * - retries with linear backoff on 429 rate limits
 * - returns the audio as a Node Buffer (wav bytes)
 *
 * `fetchImpl` is injectable for unit tests.
 */
export async function synthesizeSpeech({
  text,
  languageTag = 'hi-IN',
  speaker = 'shubh',
  model = DEFAULT_MODEL,
  pace = 0.9,
  apiKey,
  fetchImpl = fetch,
  retries = 3,
}) {
  if (!apiKey) {
    throw new Error('SARVAM_API_KEY is not configured');
  }
  if (!text || typeof text !== 'string' || text.trim().length === 0) {
    throw new Error('Empty speech text');
  }

  const payload = {
    text: text.slice(0, 2500),
    language_code: languageTag,
    speaker,
    model,
    pace: clampPace(pace),
  };

  const doFetch = async (body) =>
    fetchImpl(SARVAM_TTS_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'api-subscription-key': apiKey,
      },
      body: JSON.stringify(body),
    });

  let lastError = null;
  for (let attempt = 0; attempt <= retries; attempt++) {
    let res = await doFetch(payload);

    // Auto-fallback from bulbul:v4 to bulbul:v3 when the v4 preview is
    // not enabled for this key's tier (matches the existing script).
    if (
      !res.ok &&
      payload.model === DEFAULT_MODEL &&
      (res.status === 400 || res.status === 404)
    ) {
      payload.model = FALLBACK_MODEL;
      res = await doFetch(payload);
    }

    if (res.ok) {
      const json = await res.json();
      if (!json.audios || !Array.isArray(json.audios) || !json.audios[0]) {
        throw new Error('No audio returned in Sarvam AI response');
      }
      return {
        audio: Buffer.from(json.audios[0], 'base64'),
        model: payload.model,
      };
    }

    if (res.status === 429 && attempt < retries) {
      lastError = new Error(`Sarvam rate limited (429)`);
      await new Promise((r) => setTimeout(r, (attempt + 1) * 1500));
      continue;
    }

    const errText = await res.text().catch(() => '');
    throw new Error(
      `Sarvam AI API failed (${res.status}): ${errText.slice(0, 500)}`
    );
  }

  throw lastError || new Error('Sarvam AI API failed after retries');
}
