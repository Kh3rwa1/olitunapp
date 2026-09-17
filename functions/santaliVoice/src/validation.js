import { createHash } from 'node:crypto';

/**
 * Bodhan indic-speak contract (https://console.bodhan.ai/api-docs/).
 * Santali-only by product decision: the app exposes just the two native
 * Santali voices, Phulmani (female) and Sibu (male).
 */
export const BODHAN_TTS_URL = 'https://api.bodhan.ai/v1/audio/speech';
export const BODHAN_MODEL = 'indic-speak';

export const MAX_TEXT_CHARS = 600;
export const MIN_TEXT_CHARS = 1;

/** The two native Santali voices: [voiceName, langCode, gender]. */
const VOICE_ROWS = [
  ['Phulmani', 'sat', 'female'],
  ['Sibu', 'sat', 'male'],
];

export const ALLOWED_VOICES = Object.freeze(new Set(VOICE_ROWS.map(([v]) => v)));

export const DEFAULT_VOICE = 'Phulmani';

/** Languages accepted in `instructions.lang`. Defaults to Santali. */
export const ALLOWED_LANGS = Object.freeze(
  new Set([
    'as', 'bn', 'brx', 'doi', 'en', 'gu', 'hi', 'sat', 'kn', 'kok', 'ks',
    'mai', 'ml', 'mni', 'mr', 'ne', 'or', 'pa', 'sa', 'sd', 'ta', 'te', 'ur',
  ])
);

export const DEFAULT_LANG = 'sat';

/**
 * Speaking styles accepted in `instructions.style`. Absent/empty means
 * the voice's neutral reading (Bodhan default).
 */
export const ALLOWED_STYLES = Object.freeze(
  new Set([
    'AIR style news',
    'Customer Care',
    'TV style news',
    'advertisements',
    'anger',
    "children's stories",
    'disgust',
    'educational lecture',
    'fear',
    'happy',
    'news',
    'sad',
    'single person narration audiobook',
    'surprise',
  ])
);

/**
 * Stable cache key over the exact synthesis inputs so repeat requests
 * (same text + voice + lang + style) never spend Bodhan credits twice.
 */
export function createTtsCacheKey({ text, voice, lang, style }) {
  return createHash('sha256')
    .update(
      JSON.stringify({
        text: String(text || '').trim(),
        voice: String(voice || DEFAULT_VOICE),
        lang: String(lang || DEFAULT_LANG).toLowerCase(),
        style: String(style || '').trim(),
      })
    )
    .digest('hex');
}

/**
 * Validates a voice request. Returns null when valid, otherwise a
 * `{ status, code, message }` rejection. Exported for unit tests.
 */
export function validateSantaliVoiceRequest({ method, body }) {
  if (method !== 'POST') {
    return { status: 405, code: 'METHOD_NOT_ALLOWED', message: 'Method not allowed.' };
  }
  if (!body || typeof body !== 'object') {
    return { status: 400, code: 'INVALID_JSON', message: 'Invalid JSON payload.' };
  }

  const text = typeof body.text === 'string' ? body.text.trim() : '';
  if (!text) {
    return { status: 400, code: 'INVALID_INPUT', message: 'Text is empty. Type something first.' };
  }
  if (text.length > MAX_TEXT_CHARS) {
    return {
      status: 400,
      code: 'INPUT_TOO_LONG',
      message: `Text too long (max ${MAX_TEXT_CHARS} characters). Bodhan reads a sentence or two at a time.`,
    };
  }

  const voice = typeof body.voice === 'string' ? body.voice.trim() : DEFAULT_VOICE;
  if (!ALLOWED_VOICES.has(voice)) {
    return { status: 400, code: 'UNSUPPORTED_VOICE', message: `Unsupported voice: ${voice}.` };
  }

  const lang = typeof body.lang === 'string' && body.lang.trim()
    ? body.lang.trim().toLowerCase()
    : DEFAULT_LANG;
  if (!ALLOWED_LANGS.has(lang)) {
    return { status: 400, code: 'UNSUPPORTED_LANGUAGE', message: `Unsupported language: ${lang}.` };
  }

  const style = typeof body.style === 'string' ? body.style.trim() : '';
  if (style && !ALLOWED_STYLES.has(style)) {
    return { status: 400, code: 'UNSUPPORTED_STYLE', message: `Unsupported style: ${style}.` };
  }

  return null;
}

/** Normalized request values (applies defaults). */
export function normalizeSantaliVoiceRequest(body) {
  const style = typeof body.style === 'string' ? body.style.trim() : '';
  return {
    text: body.text.trim(),
    voice: typeof body.voice === 'string' && body.voice.trim() ? body.voice.trim() : DEFAULT_VOICE,
    lang: typeof body.lang === 'string' && body.lang.trim()
      ? body.lang.trim().toLowerCase()
      : DEFAULT_LANG,
    style,
  };
}
