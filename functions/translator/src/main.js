import { Client, Databases, ID, Query } from 'node-appwrite';
import translate from '@vitalets/google-translate-api';
import {
  createCacheKey,
  MAX_TRANSLATION_CHARS,
  normalizeLanguage,
} from './security.js';

const DB_ID = 'olitun_db';
const CACHE_COLLECTION = 'translation_cache';
const RATE_COLLECTION = 'rate_limits';
const RATE_LIMIT_PER_HOUR = parseInt(process.env.RATE_LIMIT_PER_HOUR || '20', 10);
const WINDOW_MS = 60 * 60 * 1000;

const ok = (data) => ({ success: true, data });
const err = (message) => ({ success: false, message });

export default async ({ req, res, log, error }) => {
  if (req.method !== 'POST') {
    return res.json(err('Method not allowed'), 405);
  }

  let body;
  try {
    body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  } catch {
    return res.json(err('Invalid JSON'), 400);
  }

  const text = (body?.text || '').trim();
  const from = normalizeLanguage(body?.from, 'auto');
  const to = normalizeLanguage(body?.to, 'sat');
  if (!text) return res.json(err('Missing "text"'), 400);
  if (text.length > MAX_TRANSLATION_CHARS) {
    return res.json(
      err(`Text too long (max ${MAX_TRANSLATION_CHARS} chars)`),
      400
    );
  }

  // API key comes ONLY from server-side env. We deliberately do NOT trust
  // the `x-appwrite-key` request header — that would let a caller override
  // the function's identity by injecting their own key. Configure the key
  // in the Appwrite Console → Function Settings → Environment.
  const apiKey = process.env.APPWRITE_API_KEY;
  if (!apiKey) {
    error('APPWRITE_API_KEY env var is not set');
    return res.json(err('Server misconfigured'), 500);
  }
  const client = new Client()
    .setEndpoint(process.env.APPWRITE_FUNCTION_API_ENDPOINT)
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(apiKey);
  const db = new Databases(client);

  const clientIp =
    req.headers['x-forwarded-for']?.split(',')[0]?.trim() ||
    req.headers['x-real-ip'] ||
    'unknown';

  // ---- Rate limit ----
  try {
    const existing = await db.listDocuments(DB_ID, RATE_COLLECTION, [
      Query.equal('clientIp', clientIp),
      Query.limit(1),
    ]);
    const now = Date.now();
    const row = existing.documents[0];
    if (!row) {
      await db.createDocument(DB_ID, RATE_COLLECTION, ID.unique(), {
        clientIp,
        count: 1,
        windowStart: now,
      });
    } else if (now - row.windowStart > WINDOW_MS) {
      await db.updateDocument(DB_ID, RATE_COLLECTION, row.$id, {
        count: 1,
        windowStart: now,
      });
    } else if (row.count >= RATE_LIMIT_PER_HOUR) {
      return res.json(err('Rate limit exceeded'), 429);
    } else {
      await db.updateDocument(DB_ID, RATE_COLLECTION, row.$id, {
        count: row.count + 1,
      });
    }
  } catch (e) {
    log(`Rate limit check failed (continuing): ${e.message}`);
  }

  // ---- Cache lookup ----
  const cacheKey = createCacheKey({ from, to, text });
  try {
    const cached = await db.listDocuments(DB_ID, CACHE_COLLECTION, [
      Query.equal('cacheKey', cacheKey),
      Query.limit(1),
    ]);
    if (cached.documents[0]) {
      const c = cached.documents[0];
      return res.json(
        ok({
          translation: c.translation,
          detectedLanguage: c.detectedLanguage || from,
          cached: true,
        })
      );
    }
  } catch (e) {
    log(`Cache lookup failed (continuing): ${e.message}`);
  }

  // ---- Translate ----
  try {
    const opts = { to };
    if (from !== 'auto') opts.from = from;
    const result = await translate(text, opts);
    const translation = result.text;
    const detected = result.from?.language?.iso || from;

    try {
      await db.createDocument(DB_ID, CACHE_COLLECTION, ID.unique(), {
        cacheKey,
        translation,
        detectedLanguage: detected,
        targetLang: to,
      });
    } catch (e) {
      log(`Cache write failed (non-fatal): ${e.message}`);
    }

    return res.json(
      ok({ translation, detectedLanguage: detected, cached: false })
    );
  } catch (e) {
    error(`Translate failed: ${e.message}`);
    return res.json(err('Translation failed'), 500);
  }
};
