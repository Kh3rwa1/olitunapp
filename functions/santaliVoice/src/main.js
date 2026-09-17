import { Account, Client, Databases, ID, Query, Storage } from 'node-appwrite';
import { InputFile } from 'node-appwrite/file';
import {
  createTtsCacheKey,
  normalizeSantaliVoiceRequest,
  validateSantaliVoiceRequest,
} from './validation.js';
import { BODHAN_KEYS_COLLECTION, loadActiveKeys, synthesizeWithRotation } from './key_rotation.js';
import { VoiceStore, VoiceError, digest, limits } from './store.js';

export const DB_ID = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
export const TTS_CACHE_COLLECTION = 'tts_cache';
export const AUDIO_BUCKET_ID = process.env.AUDIO_BUCKET_ID || 'audio';

const ok = (data) => ({ success: true, data });
const err = (message, code = 'VOICE_ERROR') => ({
  success: false,
  error: code,
  message,
});

export function parseBody(body) {
  if (!body) return null;
  if (typeof body === 'object') return body;
  try {
    return JSON.parse(body);
  } catch {
    return null;
  }
}

export function requireConfig(env = process.env) {
  const endpoint = env.APPWRITE_FUNCTION_API_ENDPOINT || env.APPWRITE_ENDPOINT;
  const projectId = env.APPWRITE_FUNCTION_PROJECT_ID || env.APPWRITE_PROJECT_ID;
  const apiKey = env.APPWRITE_FUNCTION_API_KEY || env.APPWRITE_API_KEY;
  const secret = env.SANTALI_VOICE_HMAC_SECRET || env.AI_STUDIO_HMAC_SECRET;

  if (env.SANTALI_VOICE_ENABLED !== 'true') {
    return { disabled: true };
  }

  const missing = [];
  if (!endpoint) missing.push('APPWRITE_FUNCTION_API_ENDPOINT');
  if (!projectId) missing.push('APPWRITE_FUNCTION_PROJECT_ID');
  if (!apiKey) missing.push('APPWRITE_FUNCTION_API_KEY');
  if (!secret || secret.length < 32) missing.push('SANTALI_VOICE_HMAC_SECRET');
  if (missing.length > 0) return { missing };

  return {
    endpoint,
    projectId,
    apiKey,
    databaseId: env.APPWRITE_DATABASE_ID || DB_ID,
    secret,
    policy: limits(env),
  };
}

function storageViewUrl(env, fileId) {
  const endpoint = env.APPWRITE_FUNCTION_API_ENDPOINT || env.APPWRITE_ENDPOINT;
  const projectId = env.APPWRITE_FUNCTION_PROJECT_ID || env.APPWRITE_PROJECT_ID;
  return `${endpoint}/storage/buckets/${AUDIO_BUCKET_ID}/files/${fileId}/view?project=${projectId}`;
}

async function findCachedTrack(databases, dbId, cacheKey) {
  try {
    const cached = await databases.listDocuments(dbId, TTS_CACHE_COLLECTION, [
      Query.equal('cacheKey', cacheKey),
      Query.limit(1),
    ]);
    const doc = cached.documents?.[0];
    if (doc && doc.audioUrl) return doc;
  } catch {
    // Cache is best-effort; a lookup failure just means generation.
  }
  return null;
}

export async function authenticate(req, cfg, makeAccount = (client) => new Account(client)) {
  const headers = Object.fromEntries(
    Object.entries(req.headers || {}).map(([k, v]) => [k.toLowerCase(), v])
  );
  const bearer =
    typeof headers.authorization === 'string' && /^Bearer /i.test(headers.authorization)
      ? headers.authorization.slice(7)
      : '';
  const jwt = bearer || headers['x-appwrite-user-jwt'];

  if (jwt && typeof jwt === 'string' && jwt.trim() && jwt.length <= 8192) {
    try {
      const client = new Client().setEndpoint(cfg.endpoint).setProject(cfg.projectId).setJWT(jwt.trim());
      const user = await makeAccount(client).get();
      if (user?.$id && user.status !== false) {
        return user.$id;
      }
    } catch (_) {
      // Fallback to session header if JWT validation fails
    }
  }

  const userId = headers['x-appwrite-user-id'];
  if (typeof userId === 'string' && userId.trim() && userId.length <= 36) {
    return userId.trim();
  }

  return null;
}

export function createHandler({
  env = process.env,
  authenticateImpl = authenticate,
  services,
  fetchImpl = fetch,
} = {}) {
  return async ({ req, res, log = () => {}, error = () => {} }) => {
    const startTime = Date.now();
    const rawBody = req.body;
    const body = parseBody(rawBody);

    const invalid = validateSantaliVoiceRequest({
      method: req.method,
      body,
      rawBody: typeof rawBody === 'string' ? rawBody : null,
    });
    if (invalid) {
      return res.json(err(invalid.message, invalid.code), invalid.status);
    }

    const config = requireConfig(env);
    if (config.disabled) {
      return res.json(err('Voice service is currently unavailable.', 'SERVICE_UNAVAILABLE'), 503);
    }
    if (config.missing) {
      error(JSON.stringify({ event: 'server_misconfigured', missing: config.missing }));
      return res.json(err('Voice service is unavailable.', 'SERVER_MISCONFIGURED'), 503);
    }

    const userId = await authenticateImpl(req, config);
    if (!userId) {
      return res.json(err('Sign in to create voice clips.', 'LOGIN_REQUIRED'), 401);
    }

    const { text, voice, lang, style, chars } = normalizeSantaliVoiceRequest(body);
    const cacheKey = createTtsCacheKey({ text, voice, lang, style });

    let databases;
    let storage;
    let store;
    let synthRotation = synthesizeWithRotation;

    if (services) {
      const injected = services(config, userId);
      databases = injected.databases;
      storage = injected.storage;
      store = injected.store || new VoiceStore(databases, config.databaseId, config.secret);
      if (injected.synthesizeWithRotation) {
        synthRotation = injected.synthesizeWithRotation;
      }
    } else {
      const client = new Client()
        .setEndpoint(config.endpoint)
        .setProject(config.projectId)
        .setKey(config.apiKey);
      databases = new Databases(client);
      storage = new Storage(client);
      store = new VoiceStore(databases, config.databaseId, config.secret);
    }

    // ---- 1. Check per-user and global rate limits ----
    try {
      await store.requestLimit(userId, config.policy);
    } catch (limitErr) {
      const code = limitErr instanceof VoiceError ? limitErr.code : 'RATE_LIMITED';
      const status = limitErr instanceof VoiceError ? limitErr.status : 429;
      return res.json(err(limitErr.message || 'Voice is busy. Try again in a moment.', code), status);
    }

    // ---- 2. Cache lookup: repeat clips cost zero credits ----
    const cached = await findCachedTrack(databases, config.databaseId, cacheKey);
    if (cached) {
      log(JSON.stringify({ event: 'tts_cache_hit', voice, lang, durationMs: Date.now() - startTime }));
      return res.json(
        ok({
          audioUrl: cached.audioUrl,
          storageFileId: cached.storageFileId || null,
          cached: true,
          voice,
          lang,
          style,
          chars,
        })
      );
    }

    // ---- 3. Durable Request Claim: prevent concurrent identical submissions ----
    const claimId = digest(config.secret, ['voice-v1', userId, cacheKey]);
    const claimed = await store.claim(claimId, userId, cacheKey, chars);
    if (!claimed) {
      const existing = await store.get(claimId);
      if (existing?.status === 'completed' && existing.audioUrl) {
        return res.json(
          ok({
            audioUrl: existing.audioUrl,
            storageFileId: existing.storageFileId || null,
            cached: true,
            voice,
            lang,
            style,
            chars,
          })
        );
      }
      if (existing?.status === 'submitting') {
        return res.json(
          err(
            'This voice request is already in progress. Please wait for it to complete.',
            'REQUEST_NOT_REPLAYABLE'
          ),
          409
        );
      }
      return res.json(
        err(
          'This request previously could not be completed. It will not be submitted again automatically.',
          'REQUEST_NOT_REPLAYABLE'
        ),
        409
      );
    }

    // ---- 4. Check and reserve character quota atomically ----
    try {
      await store.reserve(userId, chars, config.policy);
    } catch (quotaErr) {
      await store.update(claimId, { status: 'failed' });
      const code = quotaErr instanceof VoiceError ? quotaErr.code : 'QUOTA_EXCEEDED';
      const status = quotaErr instanceof VoiceError ? quotaErr.status : 429;
      return res.json(err(quotaErr.message || 'Voice quota exceeded.', code), status);
    }

    // ---- 5. Load keys and synthesize with rotation ----
    let keys = [];
    try {
      keys = await loadActiveKeys(databases, config.databaseId);
    } catch (keysErr) {
      await store.update(claimId, { status: 'failed' });
      error(JSON.stringify({ event: 'tts_keys_lookup_failed', error: keysErr?.message }));
      return res.json(err('Voice service is unavailable.', 'SERVER_MISCONFIGURED'), 503);
    }

    let synthesis;
    try {
      synthesis = await synthRotation({
        databases,
        dbId: config.databaseId,
        keys,
        text,
        voice,
        lang,
        style,
        fetchImpl,
      });
    } catch (synthErr) {
      // Fail closed: keep claim marked as failed to prevent duplicate charging on uncertain outcome
      await store.update(claimId, { status: 'failed' });
      if (synthErr?.reason === 'bad_request') {
        return res.json(err('The voice service could not synthesize this text.', 'UPSTREAM_REJECTED'), 422);
      }
      const code = synthErr?.code || 'ALL_KEYS_EXHAUSTED';
      const status = code === 'NO_KEYS_CONFIGURED' ? 500 : 503;
      error(
        JSON.stringify({
          event: 'tts_all_keys_failed',
          voice,
          lang,
          durationMs: Date.now() - startTime,
        })
      );
      return res.json(err(synthErr?.message || 'Voice service is busy.', code), status);
    }

    // ---- 6. Persist audio to Storage ----
    let uploaded;
    try {
      const file = InputFile.fromBuffer(
        synthesis.audio,
        `santali_voice_${cacheKey.slice(0, 12)}.wav`,
        'audio/wav'
      );
      uploaded = await storage.createFile(AUDIO_BUCKET_ID, ID.unique(), file);
    } catch (uploadErr) {
      await store.update(claimId, { status: 'failed' });
      error(JSON.stringify({ event: 'tts_upload_failed', error: uploadErr?.message }));
      return res.json(
        err('Voice was created but could not be saved. Try again.', 'UPLOAD_FAILED'),
        502
      );
    }

    const audioUrl = storageViewUrl(env, uploaded.$id);
    const timestamp = new Date().toISOString();

    // ---- 7. Link to user_assets for account deletion tracking ----
    try {
      await databases.createDocument(config.databaseId, 'user_assets', ID.unique(), {
        userId,
        bucketId: AUDIO_BUCKET_ID,
        fileId: uploaded.$id,
        createdAt: timestamp,
      });
    } catch (_) {
      // Best-effort registry
    }

    // ---- 8. Update claim to completed & save to tts_cache ----
    await store.update(claimId, {
      status: 'completed',
      audioUrl,
      storageFileId: uploaded.$id,
    });

    try {
      await databases.createDocument(config.databaseId, TTS_CACHE_COLLECTION, ID.unique(), {
        cacheKey,
        text: text.slice(0, 2000),
        voice,
        lang,
        style,
        audioUrl,
        storageFileId: uploaded.$id,
        chars,
        createdAt: timestamp,
      });
    } catch (cacheErr) {
      log(JSON.stringify({ event: 'tts_cache_save_failed', error: cacheErr?.message }));
    }

    log(
      JSON.stringify({
        event: 'tts_success',
        voice,
        lang,
        style: style || 'neutral',
        chars,
        attempts: synthesis.attempts,
        durationMs: Date.now() - startTime,
      })
    );

    return res.json(
      ok({
        audioUrl,
        storageFileId: uploaded.$id,
        cached: false,
        voice,
        lang,
        style,
        chars,
      })
    );
  };
}

export default (context) => createHandler()(context);

export { BODHAN_KEYS_COLLECTION };
