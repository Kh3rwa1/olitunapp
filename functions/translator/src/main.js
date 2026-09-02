import { Client, Databases, ID, Query } from 'node-appwrite';
import {
  createCacheKey,
  MAX_TRANSLATION_CHARS,
  normalizeLanguage,
  isLanguageSupported,
} from './security.js';
import { getTranslationProvider } from './providers/translation_provider.js';

const DB_ID = 'olitun_db';
const CACHE_COLLECTION = 'translation_cache';

// Translation is a free, unlimited service: identity verification and rate
// limiting were intentionally removed (see README + SECURITY.md §C).

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
  const endpoint = process.env.APPWRITE_FUNCTION_API_ENDPOINT;
  const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID;

  if (!apiKey || !endpoint || !projectId) {
    error(JSON.stringify({ event: 'server_misconfigured', error: 'Missing Appwrite configuration' }));
    return res.json(err('Translation service unavailable', 'SERVER_MISCONFIGURED'), 500);
  }

  const client = new Client()
    .setEndpoint(endpoint)
    .setProject(projectId)
    .setKey(apiKey);
  const db = new Databases(client);

  // ---- Cache Lookup (SHA-256 hashed cacheKey) ----
  const cacheKey = createCacheKey({ from, to, text });
  try {
    const cached = await db.listDocuments(DB_ID, CACHE_COLLECTION, [
      Query.equal('cacheKey', cacheKey),
      Query.limit(1),
    ]);
    if (cached.documents && cached.documents.length > 0) {
      const c = cached.documents[0];
      // Legacy rows may predate the `translatedText` field name (older
      // deployments stored `translation`) or be empty — returning them
      // produced translations that vanished in the app. Treat a stale or
      // empty row as a miss: self-heal by deleting it and re-translating.
      const cachedText = String(c.translatedText || c.translation || '').trim();
      if (cachedText.length > 0) {
        log(JSON.stringify({
          event: 'cache_hit',
          from: c.from,
          to: c.to,
          durationMs: Date.now() - startTime,
        }));
        return res.json(ok(translationPayload(cachedText, c.from || from, to, true)));
      }
      log(JSON.stringify({ event: 'cache_stale_discarded', cacheKey: cacheKey.slice(0, 12) }));
      db.deleteDocument(DB_ID, CACHE_COLLECTION, c.$id).catch((delErr) => {
        log(JSON.stringify({ event: 'cache_stale_delete_failed', error: delErr?.message }));
      });
    }
  } catch (cacheErr) {
    log(JSON.stringify({ event: 'cache_lookup_failed', error: cacheErr?.message }));
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
      log(JSON.stringify({ event: 'cache_save_failed', error: saveErr?.message }));
    });

    log(JSON.stringify({
      event: 'translation_success',
      provider: translationResult.provider,
      from: detectedFrom,
      to,
      durationMs: Date.now() - startTime,
    }));

    return res.json(ok(translationPayload(translatedText, detectedFrom, to, false)));
  } catch (upstreamErr) {
    error(JSON.stringify({
      event: 'upstream_translation_failed',
      error: upstreamErr?.message,
      durationMs: Date.now() - startTime,
    }));
    if (upstreamErr?.message && (upstreamErr.message.includes('timeout') || upstreamErr.name === 'AbortError')) {
      return res.json(err('Upstream translation service timed out. Please try again.', 'UPSTREAM_TIMEOUT'), 504);
    }
    return res.json(err('Translation service failed. Please try again later.', 'UPSTREAM_ERROR'), 502);
  }
};

/**
 * Neutral response payload. The app reads `translation` + `detectedLanguage`
 * (lib/core/api/ai_service.dart); `translatedText`/`from`/`to`/`cached` are
 * kept for older clients and the content pipelines.
 */
function translationPayload(translatedText, detectedLanguage, to, cached) {
  return {
    translation: translatedText,
    detectedLanguage,
    detectedLanguageCode: detectedLanguage,
    translatedText,
    from: detectedLanguage,
    to,
    cached,
  };
}

