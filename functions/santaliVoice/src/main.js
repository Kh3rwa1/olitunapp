import { Client, Databases, ID, Query, Storage } from 'node-appwrite';
import { InputFile } from 'node-appwrite/file';
import {
  createTtsCacheKey,
  normalizeSantaliVoiceRequest,
  validateSantaliVoiceRequest,
} from './validation.js';
import { BODHAN_KEYS_COLLECTION, loadActiveKeys, synthesizeWithRotation } from './key_rotation.js';

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
  const missing = [];
  if (!endpoint) missing.push('APPWRITE_FUNCTION_API_ENDPOINT');
  if (!projectId) missing.push('APPWRITE_FUNCTION_PROJECT_ID');
  if (!apiKey) missing.push('APPWRITE_FUNCTION_API_KEY');
  if (missing.length > 0) return { missing };
  return { endpoint, projectId, apiKey };
}

function storageViewUrl(env, fileId) {
  const endpoint = env.APPWRITE_FUNCTION_API_ENDPOINT || env.APPWRITE_ENDPOINT;
  const projectId = env.APPWRITE_FUNCTION_PROJECT_ID || env.APPWRITE_PROJECT_ID;
  return `${endpoint}/storage/buckets/${AUDIO_BUCKET_ID}/files/${fileId}/view?project=${projectId}`;
}

async function findCachedTrack(databases, cacheKey) {
  try {
    const cached = await databases.listDocuments(DB_ID, TTS_CACHE_COLLECTION, [
      Query.equal('cacheKey', cacheKey),
      Query.limit(1),
    ]);
    const doc = cached.documents?.[0];
    if (doc && doc.audioUrl) return doc;
  } catch {
    // Cache is best-effort; a lookup failure just means regeneration.
  }
  return null;
}

export default async ({ req, res, log, error }) => {
  const startTime = Date.now();
  const body = parseBody(req.body);

  const invalid = validateSantaliVoiceRequest({ method: req.method, body });
  if (invalid) {
    return res.json(err(invalid.message, invalid.code), invalid.status);
  }

  // Voice generation spends real Bodhan credits per character, so unlike
  // the free translator it requires a signed-in caller (execute: users).
  const userId = req.headers['x-appwrite-user-id'];
  if (!userId) {
    return res.json(err('Sign in to create voice clips.', 'LOGIN_REQUIRED'), 401);
  }

  const config = requireConfig();
  if (config.missing) {
    error(JSON.stringify({ event: 'server_misconfigured', missing: config.missing }));
    return res.json(err('Voice service is unavailable.', 'SERVER_MISCONFIGURED'), 500);
  }

  const { text, voice, lang, style } = normalizeSantaliVoiceRequest(body);
  const cacheKey = createTtsCacheKey({ text, voice, lang, style });

  const client = new Client()
    .setEndpoint(config.endpoint)
    .setProject(config.projectId)
    .setKey(config.apiKey);
  const databases = new Databases(client);
  const storage = new Storage(client);

  // ---- Cache lookup: repeat clips cost zero credits ----
  const cached = await findCachedTrack(databases, cacheKey);
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
        chars: text.length,
      })
    );
  }

  // ---- Synthesize with key rotation ----
  let keys = [];
  try {
    keys = await loadActiveKeys(databases, DB_ID);
  } catch (keysErr) {
    error(JSON.stringify({ event: 'tts_keys_lookup_failed', error: keysErr?.message }));
    return res.json(err('Voice service is unavailable.', 'SERVER_MISCONFIGURED'), 500);
  }

  let synthesis;
  try {
    synthesis = await synthesizeWithRotation({
      databases,
      dbId: DB_ID,
      keys,
      text,
      voice,
      lang,
      style,
    });
  } catch (synthErr) {
    if (synthErr?.reason === 'bad_request') {
      return res.json(err(synthErr.message, 'UPSTREAM_REJECTED'), 422);
    }
    const code = synthErr?.code || 'ALL_KEYS_EXHAUSTED';
    const status = code === 'NO_KEYS_CONFIGURED' ? 500 : 503;
    error(
      JSON.stringify({
        event: 'tts_all_keys_failed',
        voice,
        lang,
        failures: synthErr?.failures || [],
        durationMs: Date.now() - startTime,
      })
    );
    return res.json(err(synthErr?.message || 'Voice service is busy.', code), status);
  }

  // ---- Persist audio to Storage so the client streams/downloads a URL ----
  let uploaded;
  try {
    const file = InputFile.fromBuffer(
      synthesis.audio,
      `santali_voice_${cacheKey.slice(0, 12)}.wav`,
      'audio/wav'
    );
    uploaded = await storage.createFile(AUDIO_BUCKET_ID, ID.unique(), file);
  } catch (uploadErr) {
    error(JSON.stringify({ event: 'tts_upload_failed', error: uploadErr?.message }));
    return res.json(err('Voice was created but could not be saved. Try again.', 'UPLOAD_FAILED'), 502);
  }

  const audioUrl = storageViewUrl(process.env, uploaded.$id);
  const timestamp = new Date().toISOString();

  // Best-effort cache write (never fails the request).
  try {
    await databases.createDocument(DB_ID, TTS_CACHE_COLLECTION, ID.unique(), {
      cacheKey,
      text: text.slice(0, 2000),
      voice,
      lang,
      style,
      audioUrl,
      storageFileId: uploaded.$id,
      chars: text.length,
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
      chars: text.length,
      keyLabel: synthesis.keyLabel,
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
      chars: text.length,
    })
  );
};

// Re-exported for unit tests without invoking the handler.
export { BODHAN_KEYS_COLLECTION };
