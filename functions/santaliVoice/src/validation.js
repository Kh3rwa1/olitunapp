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
export const MAX_BODY_BYTES = 32768;

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
 * Counts Unicode code points (runes) correctly across all script planes,
 * preventing astral-plane characters or combining marks from breaking bounds.
 */
export function countCodePoints(text) {
  return [...String(text || '').normalize('NFC')].length;
}

/**
 * Stable cache key over the exact synthesis inputs so repeat requests
 * (same text + voice + lang + style) never spend Bodhan credits twice.
 */
export function createTtsCacheKey({ text, voice, lang, style }) {
  const normalizedText = String(text || '').normalize('NFC').trim();
  return createHash('sha256')
    .update(
      JSON.stringify({
        text: normalizedText,
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
export function validateSantaliVoiceRequest({ method, body, rawBody }) {
  if (method !== 'POST') {
    return { status: 405, code: 'METHOD_NOT_ALLOWED', message: 'Method not allowed.' };
  }
  if (!body || typeof body !== 'object') {
    return { status: 400, code: 'INVALID_JSON', message: 'Invalid JSON payload.' };
  }

  // Enforce request body size limits
  if (rawBody && typeof rawBody === 'string' && rawBody.length > MAX_BODY_BYTES) {
    return { status: 400, code: 'PAYLOAD_TOO_LARGE', message: 'Request body exceeds size limit.' };
  }
  try {
    if (JSON.stringify(body).length > MAX_BODY_BYTES) {
      return { status: 400, code: 'PAYLOAD_TOO_LARGE', message: 'Request body exceeds size limit.' };
    }
  } catch (_) {
    return { status: 400, code: 'INVALID_JSON', message: 'Invalid JSON payload.' };
  }

  const rawText = typeof body.text === 'string' ? body.text : '';
  const normalizedText = rawText.normalize('NFC').trim();
  const codePoints = countCodePoints(normalizedText);

  if (codePoints < MIN_TEXT_CHARS) {
    return { status: 400, code: 'INVALID_INPUT', message: 'Text is empty. Type something first.' };
  }
  if (codePoints > MAX_TEXT_CHARS) {
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

/** Normalized request values (applies defaults, Unicode NFC, code point counts). */
export function normalizeSantaliVoiceRequest(body) {
  const style = typeof body.style === 'string' ? body.style.trim() : '';
  const normalizedText = String(body.text || '').normalize('NFC').trim();
  return {
    text: normalizedText,
    voice: typeof body.voice === 'string' && body.voice.trim() ? body.voice.trim() : DEFAULT_VOICE,
    lang: typeof body.lang === 'string' && body.lang.trim()
      ? body.lang.trim().toLowerCase()
      : DEFAULT_LANG,
    style,
    chars: countCodePoints(normalizedText),
  };
}
