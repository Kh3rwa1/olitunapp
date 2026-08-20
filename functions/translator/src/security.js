import { createHash, createHmac } from 'node:crypto';

export const MAX_TRANSLATION_CHARS = parseInt(
  process.env.MAX_TRANSLATION_CHARS || '5000',
  10
);

export const SUPPORTED_LANGUAGES = Object.freeze(new Set([
  'auto',
  'sat', // Santali (Ol Chiki)
  'en',  // English
  'hi',  // Hindi
  'bn',  // Bengali
  'or',  // Odia
  'sa',  // Sanskrit
  'ta',  // Tamil
  'te',  // Telugu
  'mr',  // Marathi
  'gu',  // Gujarati
  'ur',  // Urdu
  'pa',  // Punjabi
  'as',  // Assamese
  'zh',  // Chinese
  'zh-cn',
  'es',  // Spanish
  'fr',  // French
  'de',  // German
  'ja',  // Japanese
]));

const LANGUAGE_TAG_PATTERN = /^[a-z]{2,5}(-[a-z0-9]{2,8})?$/i;

export const createCacheKey = ({ from, to, text }) =>
  createHash('sha256')
    .update(JSON.stringify({ from: String(from || 'auto').toLowerCase(), to: String(to || 'sat').toLowerCase(), text: String(text || '').trim() }))
    .digest('hex');

export const normalizeLanguage = (value, fallback = 'sat') => {
  const language = String(value || fallback).trim().toLowerCase();
  if (!LANGUAGE_TAG_PATTERN.test(language)) return fallback;
  return SUPPORTED_LANGUAGES.has(language) ? language : fallback;
};

export const isLanguageSupported = (code) => {
  if (!code) return false;
  return SUPPORTED_LANGUAGES.has(String(code).trim().toLowerCase());
};

export const deriveRateLimitIdentifier = ({ userId, clientIp, salt }) => {
  if (userId && typeof userId === 'string' && userId.trim().length > 0) {
    return 'usr_' + createHash('sha256').update(userId.trim()).digest('hex').slice(0, 32);
  }
  const effectiveSalt = salt || process.env.RATE_LIMIT_SALT || process.env.APPWRITE_API_KEY || 'olitun-default-salt-v1';
  const ip = String(clientIp || '127.0.0.1').trim();
  const hashedIp = createHmac('sha256', effectiveSalt).update(ip).digest('hex').slice(0, 32);
  return 'ip_' + hashedIp;
};
