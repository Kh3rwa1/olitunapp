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

  // Verified JWT identity is preferred and never taken from the caller.
  let jwtUser = null;
  if (jwt && typeof jwt === 'string' && jwt.trim() && jwt.length <= 8192) {
    try {
      const client = new Client().setEndpoint(cfg.endpoint).setProject(cfg.projectId).setJWT(jwt.trim());
      const user = await makeAccount(client).get();
      if (user?.$id && user.status !== false) {
        jwtUser = user.$id;
      }
    } catch (_) {
      // Invalid JWT: fall through to the binding rules below (fail closed
      // unless the platform header is the only signal — see below).
    }
  }

  const rawHeaderUser = headers['x-appwrite-user-id'];
  const headerUser =
    typeof rawHeaderUser === 'string' && rawHeaderUser.trim() && rawHeaderUser.length <= 36
      ? rawHeaderUser.trim()
      : null;

  // Binding rule: when BOTH signals are present they must agree. A forged
  // header paired with another user's (or an invalid) JWT fails closed.
  // Header-only requests are accepted because this function's execute
  // access is restricted to authenticated users (`execute: ["users"]` in
  // appwrite.config.json): Appwrite's gateway rejects unauthenticated
  // direct-HTTP calls before this code runs and injects a truthful
  // x-appwrite-user-id for session executions. Direct-external forged
  // headers without a session never reach us. See README (auth section).
  if (jwtUser && headerUser && jwtUser !== headerUser) return null;
  if (jwtUser) return jwtUser;
  if (headerUser) return headerUser;

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
    // Quota state machine: claimed -> reserved -> providerSubmitted ->
    // generated -> uploaded -> delivered(completed). Failures after reserve
    // refund exactly once (failed claims are permanently non-replayable, so
    // no double-spend vector exists) and land in failed+refunded. There is
    // intentionally NO failedCharged state: uncertain provider outcomes
    // (timeouts) refund the user and absorb provider cost rather than
    // charging for undelivered audio; blind automatic resubmission is
    // forbidden (409 REQUEST_NOT_REPLAYABLE) so one claim can never bill
    // twice. Stale `submitting` claims (crash mid-flight) are reclaimed
    // after STALE_CLAIM_MS instead of locking the text forever.
    const claimId = digest(config.secret, ['voice-v1', userId, cacheKey]);
    const STALE_CLAIM_MS = 15 * 60 * 1000;
    const failClaim = async (reason) => {
      // reason: { taken, event, message }
      if (reason.taken) {
        try {
          await store.release(reason.taken, chars);
        } catch (releaseErr) {
          error(JSON.stringify({ event: 'tts_refund_failed', error: releaseErr?.message }));
        }
      }
      await store.update(claimId, { status: 'failed', quotaState: reason.taken ? 'refunded' : 'unreserved' });
      if (reason.event) error(JSON.stringify(reason.event));
    };
    let claimed = await store.claim(claimId, userId, cacheKey, chars);
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
        const age = Date.now() - (existing.checkedAt || 0);
        if (age > STALE_CLAIM_MS) {
          if (await store.reclaimIfStale(claimId, STALE_CLAIM_MS)) {
            log(JSON.stringify({ event: 'tts_stale_claim_reclaimed', ageMs: age }));
            claimed = await store.claim(claimId, userId, cacheKey, chars);
          }
        }
        if (!claimed) {
          return res.json(
            err(
              'This voice request is already in progress. Please wait for it to complete.',
              'REQUEST_NOT_REPLAYABLE'
            ),
            409
          );
        }
      } else if (!claimed) {
        return res.json(
          err(
            'This request previously could not be completed. It will not be submitted again automatically.',
            'REQUEST_NOT_REPLAYABLE'
          ),
          409
        );
      }
    }

    // ---- 4. Check and reserve character quota atomically ----
    let taken = null;
    try {
      taken = await store.reserve(userId, chars, config.policy);
      await store.update(claimId, { status: 'reserved' });
    } catch (quotaErr) {
      await store.update(claimId, { status: 'failed', quotaState: 'unreserved' });
      const code = quotaErr instanceof VoiceError ? quotaErr.code : 'QUOTA_EXCEEDED';
      const status = quotaErr instanceof VoiceError ? quotaErr.status : 429;
      return res.json(err(quotaErr.message || 'Voice quota exceeded.', code), status);
    }

    // ---- 5. Load keys and synthesize with rotation ----
    let keys = [];
    try {
      keys = await loadActiveKeys(databases, config.databaseId);
    } catch (keysErr) {
      await failClaim({ taken, event: { event: 'tts_keys_lookup_failed', error: keysErr?.message } });
      return res.json(err('Voice service is unavailable.', 'SERVER_MISCONFIGURED'), 503);
    }

    let synthesis;
    try {
      await store.update(claimId, { status: 'providerSubmitted' });
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
      await store.update(claimId, { status: 'generated' });
    } catch (synthErr) {
      // Refund: reservation is released (see state-machine note above);
      // the claim stays failed/non-replayable so this bills at most once.
      await failClaim({ taken });
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
      // Explicit upload-failure policy: provider work is absorbed as our
      // loss, the user's reservation is refunded, and retry is a new claim.
      await failClaim({ taken, event: { event: 'tts_upload_failed', error: uploadErr?.message } });
      return res.json(
        err('Voice was created but could not be saved. Try again.', 'UPLOAD_FAILED'),
        502
      );
    }
    await store.update(claimId, { status: 'uploaded' });

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
      quotaState: 'consumed',
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
