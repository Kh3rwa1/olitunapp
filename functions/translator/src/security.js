import { createHash, createHmac } from 'node:crypto';
import { Account, Client } from 'node-appwrite';

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
    .update(JSON.stringify({
      from: String(from || 'auto').toLowerCase(),
      to: String(to || 'sat').toLowerCase(),
      text: String(text || '').trim(),
    }))
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

export function normalizeClientIp(ip) {
  if (!ip || typeof ip !== 'string') return '127.0.0.1';
  let cleaned = ip.trim();
  if (cleaned.startsWith('::ffff:')) {
    cleaned = cleaned.substring(7);
  }
  return cleaned || '127.0.0.1';
}

/**
 * Derives a domain-separated, privacy-preserving HMAC identifier.
 *
 * Requirements:
 * - Domain separated for verified users: HMAC(salt, "translator-rate-limit:user:v1:" + verifiedUserId)
 * - Domain separated for anonymous networks: HMAC(salt, "translator-rate-limit:network:v1:" + normalizedIp)
 * - Mandatory dedicated RATE_LIMIT_SALT in production environments.
 */
export const deriveRateLimitIdentifier = ({
  verifiedUserId,
  clientIp,
  salt,
  env = process.env,
}) => {
  const isProduction = env.NODE_ENV === 'production';
  const effectiveSalt = salt || env.RATE_LIMIT_SALT;

  if (!effectiveSalt) {
    if (isProduction) {
      throw new Error(
        'SECURITY FATAL: RATE_LIMIT_SALT is mandatory in production environment.'
      );
    }
    // Explicitly gated deterministic development fallback (strictly non-production)
    return _deriveHmacIdentifier({
      verifiedUserId,
      clientIp,
      salt: 'olitun-dev-salt-do-not-use-in-production',
    });
  }

  return _deriveHmacIdentifier({
    verifiedUserId,
    clientIp,
    salt: effectiveSalt,
  });
};

function _deriveHmacIdentifier({ verifiedUserId, clientIp, salt }) {
  if (verifiedUserId && typeof verifiedUserId === 'string' && verifiedUserId.trim().length > 0) {
    const message = `translator-rate-limit:user:v1:${verifiedUserId.trim()}`;
    const hash = createHmac('sha256', salt).update(message).digest('hex').slice(0, 32);
    return `usr_${hash}`;
  }

  const normalizedIp = normalizeClientIp(clientIp);
  const message = `translator-rate-limit:network:v1:${normalizedIp}`;
  const hash = createHmac('sha256', salt).update(message).digest('hex').slice(0, 32);
  return `net_${hash}`;
}

/**
 * Cryptographically verifies caller identity via Appwrite JWT.
 * Never trusts unverified caller headers (e.g., x-appwrite-user-id).
 *
 * @param {Object} params
 * @param {string} [params.jwt] - Appwrite JWT
 * @param {string} params.endpoint - Appwrite API endpoint
 * @param {string} params.projectId - Appwrite project ID
 * @param {Object} [params.accountServiceOverride] - Test double for Account service
 * @returns {Promise<{ isVerified: boolean, userId: string | null, error?: string }>}
 */
export async function verifyAppwriteIdentity({
  jwt,
  endpoint,
  projectId,
  accountServiceOverride = null,
}) {
  if (!jwt || typeof jwt !== 'string' || jwt.trim().length === 0) {
    return { isVerified: false, userId: null };
  }

  try {
    let account = accountServiceOverride;
    if (!account) {
      const client = new Client()
        .setEndpoint(endpoint)
        .setProject(projectId)
        .setJWT(jwt.trim());
      account = new Account(client);
    }

    const user = await account.get();
    if (user && user.$id && typeof user.$id === 'string' && user.$id.length > 0) {
      return { isVerified: true, userId: user.$id };
    }
    return { isVerified: false, userId: null, error: 'invalid_user_payload' };
  } catch (err) {
    return { isVerified: false, userId: null, error: err?.message || 'verification_failed' };
  }
}
