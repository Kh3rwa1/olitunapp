import { Client, Databases, ID, Query } from 'node-appwrite';
import {
  createCacheKey,
  MAX_TRANSLATION_CHARS,
  normalizeLanguage,
  isLanguageSupported,
  deriveRateLimitIdentifier,
} from './security.js';
import { checkRateLimit } from './rate_limiter.js';
import { getTranslationProvider } from './providers/translation_provider.js';

const DB_ID = 'olitun_db';
const CACHE_COLLECTION = 'translation_cache';
const RATE_COLLECTION = 'rate_limits';

const ok = (data) => ({ success: true, data });
const err = (message, code = 'TRANSLATION_ERROR', retryAfter = undefined) => ({
  success: false,
  error: code,
  message,
  ...(retryAfter ? { retryAfterSeconds: retryAfter } : {}),
});

export default async ({ req, res, log, error }) => {
  const startTime = Date.now();
  if (req.method !== 'POST') {
    return res.json(err('Method not allowed', 'METHOD_NOT_ALLOWED'), 405);
  }

  let body;
  try {
    body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  } catch {
    return res.json(err('Invalid JSON payload', 'INVALID_JSON'), 400);
  }

  const rawText = body?.text;
  if (rawText === undefined || rawText === null || typeof rawText !== 'string' || rawText.trim().length === 0) {
    return res.json(err('Missing or empty text parameter', 'INVALID_INPUT'), 400);
  }
  const text = rawText.trim();
  if (text.length > MAX_TRANSLATION_CHARS) {
    return res.json(
      err('Text too long (max ' + MAX_TRANSLATION_CHARS + ' characters)', 'INPUT_TOO_LONG'),
      400
    );
  }

  const reqFrom = String(body?.from || 'auto').trim().toLowerCase();
  const reqTo = String(body?.to || 'sat').trim().toLowerCase();

  if (!isLanguageSupported(reqFrom) || !isLanguageSupported(reqTo)) {
    return res.json(err('Unsupported source or target language code', 'UNSUPPORTED_LANGUAGE'), 400);
  }
  const from = normalizeLanguage(reqFrom, 'auto');
  const to = normalizeLanguage(reqTo, 'sat');

  const apiKey = process.env.APPWRITE_API_KEY;
  if (!apiKey) {
    error(JSON.stringify({ event: 'server_misconfigured', error: 'Missing APPWRITE_API_KEY' }));
    return res.json(err('Translation service unavailable', 'SERVER_MISCONFIGURED'), 500);
  }

  const client = new Client()
    .setEndpoint(process.env.APPWRITE_FUNCTION_API_ENDPOINT)
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(apiKey);
  const db = new Databases(client);

  // Determine authentication & privacy-preserving rate limit identifier
  const authUserId = req.headers['x-appwrite-user-id'] || body?.userId || null;
  const clientIp = req.headers['x-forwarded-for']?.split(',')[0]?.trim() || req.headers['x-real-ip'] || '127.0.0.1';
  const isAuth = Boolean(authUserId && typeof authUserId === 'string' && authUserId.trim().length > 0);
  const rateLimitIdentifier = deriveRateLimitIdentifier({ userId: authUserId, clientIp });

  // ---- Rate Limit Check (Fail-closed) ----
  const rlResult = await checkRateLimit({
    databases: db,
    dbId: DB_ID,
    collectionId: RATE_COLLECTION,
    identifier: rateLimitIdentifier,
    isAuth,
    now: startTime,
  });

  if (!rlResult.allowed) {
    log(JSON.stringify({
      event: 'rate_limited',
      identifier: rateLimitIdentifier,
      reason: rlResult.reason,
      isAuth,
      durationMs: Date.now() - startTime,
    }));
    if (rlResult.reason === 'rate_limit_storage_error') {
      return res.json(err('Rate limit service temporarily unavailable. Please retry shortly.', 'RATE_LIMIT_ERROR'), 503);
    }
    return res.json(
      err('Rate limit exceeded. Please wait before translating again.', 'RATE_LIMIT_EXCEEDED', rlResult.retryAfterSeconds),
      429
    );
  }

  // ---- Cache Lookup (SHA-256 hashed cacheKey) ----
  const cacheKey = createCacheKey({ from, to, text });
  try {
    const cached = await db.listDocuments(DB_ID, CACHE_COLLECTION, [
      Query.equal('cacheKey', cacheKey),
      Query.limit(1),
    ]);
    if (cached.documents && cached.documents.length > 0) {
      const c = cached.documents[0];
      log(JSON.stringify({
        event: 'cache_hit',
        cacheKey,
        from: c.from,
        to: c.to,
        durationMs: Date.now() - startTime,
      }));
      return res.json(ok({
        translatedText: c.translatedText,
        from: c.from,
        to: c.to,
        cached: true,
      }));
    }
  } catch (cacheErr) {
    log(JSON.stringify({ event: 'cache_lookup_failed', error: cacheErr.message }));
  }

  // ---- Upstream Translation Provider Call ----
  const provider = getTranslationProvider();
  try {
    const translationResult = await provider.translate({ text, from, to, timeoutMs: 8000 });
    const translatedText = translationResult.text;
    const detectedFrom = translationResult.from || from;

    // Asynchronously update cache without blocking client response
    db.createDocument(DB_ID, CACHE_COLLECTION, ID.unique(), {
      cacheKey,
      from: detectedFrom,
      to,
      translatedText,
      createdAt: Date.now(),
    }).catch((saveErr) => {
      log(JSON.stringify({ event: 'cache_save_failed', error: saveErr.message }));
    });

    log(JSON.stringify({
      event: 'translation_success',
      provider: translationResult.provider,
      from: detectedFrom,
      to,
      durationMs: Date.now() - startTime,
    }));

    return res.json(ok({
      translatedText,
      from: detectedFrom,
      to,
      cached: false,
    }));
  } catch (upstreamErr) {
    error(JSON.stringify({
      event: 'upstream_translation_failed',
      error: upstreamErr.message,
      durationMs: Date.now() - startTime,
    }));
    if (upstreamErr.message && (upstreamErr.message.includes('timeout') || upstreamErr.name === 'AbortError')) {
      return res.json(err('Upstream translation service timed out. Please try again.', 'UPSTREAM_TIMEOUT'), 504);
    }
    return res.json(err('Translation service failed. Please try again later.', 'UPSTREAM_ERROR'), 502);
  }
};
