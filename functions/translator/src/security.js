import { createHash } from 'node:crypto';

export const MAX_TRANSLATION_CHARS = parseInt(
  process.env.MAX_TRANSLATION_CHARS || '5000',
  10
);

const LANGUAGE_TAG_PATTERN = /^[a-z]{2,5}(-[a-z0-9]{2,8})?$/i;

export const createCacheKey = ({ from, to, text }) =>
  createHash('sha256')
    .update(JSON.stringify({ from, to, text }))
    .digest('hex');

export const normalizeLanguage = (value, fallback) => {
  const language = `${value || fallback}`.trim().toLowerCase();
  return LANGUAGE_TAG_PATTERN.test(language) ? language : fallback;
};
