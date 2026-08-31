import { createHash } from 'node:crypto';

export const MAX_TEXT_CHARS = 2500; // Sarvam TTS hard cap (matches scripts/generate_audio_sarvam.mjs)

/** Content kinds that may carry generated teaching-language audio. */
export const ALLOWED_CONTENT_KINDS = Object.freeze(
  new Set(['word', 'sentence', 'letter', 'number', 'rhyme', 'story'])
);

/**
 * Track types that may be generated with Sarvam TTS.
 *
 * Target (Santali) track types are deliberately absent: product policy
 * (docs/MULTILINGUAL_FOUNDATION.md) forbids synthetic Santali — target
 * audio is human-recorded via the admin CMS only. "Never send Santali
 * text to a teaching-language TTS voice."
 */
export const GENERATABLE_TRACK_TYPES = Object.freeze(
  new Set([
    'explanation',
    'translation',
    'instruction',
    'storyTranslation',
    'exampleSentence',
    'feedback',
  ])
);

/** Teaching languages supported by Sarvam bulbul TTS. 'sat' is intentionally absent. */
export const TEACHING_LANGUAGE_CODES = Object.freeze(new Set(['en', 'hi', 'bn', 'or']));

/** Bulbul speakers exposed by Sarvam AI. */
export const ALLOWED_SPEAKERS = Object.freeze(
  new Set(['shubh', 'aditi', 'priya', 'amartya'])
);

export const DEFAULT_SPEAKER = 'shubh';
export const DEFAULT_MODEL = 'bulbul:v4';
export const FALLBACK_MODEL = 'bulbul:v3';
export const DEFAULT_PACE = 0.9;

/**
 * Maps olitun teaching-language codes to Sarvam bulbul language tags.
 * Odia uses Sarvam's 'od-IN' tag.
 */
export const SARVAM_LANGUAGE_TAGS = Object.freeze({
  en: 'en-IN',
  hi: 'hi-IN',
  bn: 'bn-IN',
  or: 'od-IN',
});

export const clampPace = (value) => {
  const pace = Number(value);
  if (!Number.isFinite(pace)) return DEFAULT_PACE;
  return Math.min(2.0, Math.max(0.5, pace));
};

/**
 * Normalizes the raw speech prompt the way the existing batch script does
 * (scripts/generate_audio_sarvam.mjs): strips brackets/quotes, trims
 * parenthetical asides and dash suffixes.
 */
export function extractCleanSpeechPrompt(text) {
  if (!text) return '';
  let s = text.replace(/[()[\]"']/g, '').split('–')[0].trim();
  if (s.startsWith('-')) {
    s = s.replace(/^-+/, '').trim();
  } else if (s.includes(' - ')) {
    s = s.split(' - ')[0].trim();
  }
  return s;
}

/**
 * Stable idempotency hash over the source text + language + track type +
 * voice/model parameters. Mirrors AudioTrack.contentHash semantics from
 * lib/features/content/domain/entities/audio_track_entity.dart: the same
 * content generated twice must resolve to the same hash so the composite
 * idempotency lookup finds the existing row instead of duplicating it.
 */
export function createContentHash({ text, languageCode, trackType, model, speaker, pace }) {
  return createHash('sha256')
    .update(
      JSON.stringify({
        text: String(text || '').trim(),
        languageCode: String(languageCode || '').toLowerCase(),
        trackType: String(trackType || ''),
        model: String(model || DEFAULT_MODEL),
        speaker: String(speaker || DEFAULT_SPEAKER),
        pace: clampPace(pace),
      })
    )
    .digest('hex');
}

/**
 * Validates a generation request. Returns null when valid, otherwise a
 * `{ status, code, message }` rejection. Exported for unit tests.
 */
export function validateGenerateAudioRequest({ method, body }) {
  if (method !== 'POST') {
    return { status: 405, code: 'METHOD_NOT_ALLOWED', message: 'Method not allowed.' };
  }

  if (!body || typeof body !== 'object') {
    return { status: 400, code: 'INVALID_JSON', message: 'Invalid JSON payload.' };
  }

  const required = ['contentKind', 'contentId', 'languageCode', 'trackType', 'text'];
  for (const field of required) {
    if (!body[field] || typeof body[field] !== 'string' || body[field].trim().length === 0) {
      return {
        status: 400,
        code: 'INVALID_INPUT',
        message: `Missing or empty field: ${field}.`,
      };
    }
  }

  const contentKind = body.contentKind.trim().toLowerCase();
  if (!ALLOWED_CONTENT_KINDS.has(contentKind)) {
    return {
      status: 400,
      code: 'UNSUPPORTED_CONTENT_KIND',
      message: `Unsupported contentKind: ${contentKind}.`,
    };
  }

  const languageCode = body.languageCode.trim().toLowerCase();
  if (!TEACHING_LANGUAGE_CODES.has(languageCode)) {
    return {
      status: 400,
      code: languageCode === 'sat' ? 'TARGET_LANGUAGE_FORBIDDEN' : 'UNSUPPORTED_LANGUAGE',
      message:
        languageCode === 'sat'
          ? 'Synthetic Santali audio is forbidden by product policy. Santali tracks are human-recorded via the admin CMS.'
          : `Unsupported teaching language: ${languageCode}. Supported: en, hi, bn, or.`,
    };
  }

  const trackType = body.trackType.trim();
  if (!GENERATABLE_TRACK_TYPES.has(trackType)) {
    const isTargetType = ['targetNormal', 'targetSlow', 'targetSyllable', 'storyNarration'].includes(
      trackType
    );
    return {
      status: 400,
      code: isTargetType ? 'TARGET_TRACK_FORBIDDEN' : 'UNSUPPORTED_TRACK_TYPE',
      message: isTargetType
        ? `Target track type ${trackType} must be human-recorded; synthetic generation is forbidden.`
        : `Unsupported trackType: ${trackType}.`,
    };
  }

  const cleanText = extractCleanSpeechPrompt(body.text.trim());
  if (!cleanText) {
    return {
      status: 400,
      code: 'INVALID_INPUT',
      message: 'Text yields no speakable prompt after cleaning.',
    };
  }
  if (cleanText.length > MAX_TEXT_CHARS) {
    return {
      status: 400,
      code: 'INPUT_TOO_LONG',
      message: `Text too long (max ${MAX_TEXT_CHARS} characters).`,
    };
  }

  const speaker = (body.speaker || DEFAULT_SPEAKER).trim();
  if (!ALLOWED_SPEAKERS.has(speaker)) {
    return {
      status: 400,
      code: 'UNSUPPORTED_SPEAKER',
      message: `Unsupported speaker: ${speaker}. Supported: shubh, aditi, priya, amartya.`,
    };
  }

  return null;
}
