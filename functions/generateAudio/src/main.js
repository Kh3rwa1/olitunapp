import { Client, Databases, ID, Query, Storage, Users } from 'node-appwrite';
import { InputFile } from 'node-appwrite/file';
import {
  DEFAULT_MODEL,
  DEFAULT_PACE,
  DEFAULT_SPEAKER,
  MAX_TEXT_CHARS,
  SARVAM_LANGUAGE_TAGS,
  clampPace,
  createContentHash,
  extractCleanSpeechPrompt,
  validateGenerateAudioRequest,
} from './validation.js';
import { synthesizeSpeech } from './sarvam_client.js';

export const DB_ID = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
export const AUDIO_TRACKS_COLLECTION = 'audio_tracks';
export const AUDIO_BUCKET_ID = process.env.AUDIO_BUCKET_ID || 'audio';
export const ADMIN_TEAM_ID = process.env.ADMIN_TEAM_ID || 'admins';

const ok = (data) => ({ success: true, data });
const err = (message, code = 'GENERATION_ERROR') => ({
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
  const sarvamApiKey = env.SARVAM_API_KEY;

  const missing = [];
  if (!endpoint) missing.push('APPWRITE_FUNCTION_API_ENDPOINT');
  if (!projectId) missing.push('APPWRITE_FUNCTION_PROJECT_ID');
  if (!apiKey) missing.push('APPWRITE_FUNCTION_API_KEY');
  if (!sarvamApiKey) missing.push('SARVAM_API_KEY');

  if (missing.length > 0) {
    return { missing };
  }
  return { endpoint, projectId, apiKey, sarvamApiKey };
}

export async function userIsAdmin(users, userId) {
  if (!userId) return false;
  try {
    const memberships = await users.listMemberships(userId);
    return memberships.memberships.some(
      (membership) => membership.teamId === ADMIN_TEAM_ID
    );
  } catch {
    return false;
  }
}

/**
 * Finds an existing audio_tracks row for the composite idempotency key.
 * Appwrite skips null attribute values in unique indexes, so generation
 * must enforce the key by lookup (per scripts/appwrite_setup.mjs note).
 * segmentId is normalized to '-' when absent so the query is stable.
 */
export async function findExistingTrack(databases, { contentKind, contentId, segmentId, languageCode, trackType, contentHash }) {
  const queries = [
    Query.equal('contentKind', contentKind),
    Query.equal('contentId', contentId),
    Query.equal('segmentId', segmentId || '-'),
    Query.equal('languageCode', languageCode),
    Query.equal('trackType', trackType),
    Query.equal('contentHash', contentHash),
    Query.limit(1),
  ];
  const existing = await databases.listDocuments(DB_ID, AUDIO_TRACKS_COLLECTION, queries);
  return existing.documents && existing.documents.length > 0
    ? existing.documents[0]
    : null;
}

/**
 * Core generation pipeline for a single track. Kept pure-ish (all
 * services injected) so tests can exercise the full flow with fakes.
 *
 * Guarantees:
 * - idempotent: an existing completed row for the same composite key
 *   is returned untouched instead of regenerating
 * - synthetic tracks are never auto-approved: reviewStatus stays
 *   'needsReview' (admins approve via the CMS; Phase 5)
 * - Santali never reaches Sarvam: validation rejects 'sat' before this
 *   function is ever called
 */
export async function generateTrack({
  databases,
  storage,
  sarvamApiKey,
  fetchImpl,
  contentKind,
  contentId,
  segmentId,
  languageCode,
  trackType,
  text,
  speaker = DEFAULT_SPEAKER,
  model = DEFAULT_MODEL,
  pace = DEFAULT_PACE,
  now = () => new Date().toISOString(),
  audioUrlBuilder,
}) {
  const cleanText = extractCleanSpeechPrompt(String(text || '').trim()).slice(0, MAX_TEXT_CHARS);
  if (!cleanText) {
    return { status: 400, payload: err('Text yields no speakable prompt after cleaning.', 'INVALID_INPUT') };
  }

  const contentHash = createContentHash({
    text: cleanText,
    languageCode,
    trackType,
    model,
    speaker,
    pace,
  });

  const existing = await findExistingTrack(databases, {
    contentKind,
    contentId,
    segmentId: segmentId || '-',
    languageCode,
    trackType,
    contentHash,
  });

  if (existing) {
    // Idempotent replay: never regenerate, never alter review state.
    return {
      status: 200,
      payload: ok({
        trackId: existing.$id,
        audioUrl: existing.audioUrl,
        storageFileId: existing.storageFileId,
        generationStatus: existing.generationStatus,
        reviewStatus: existing.reviewStatus,
        cached: true,
      }),
    };
  }

  const languageTag = SARVAM_LANGUAGE_TAGS[languageCode] || 'hi-IN';
  const timestamp = now();

  // Upsert intent row first (processing) so failures are visible in the
  // admin tooling via generationStatus/errorMessage.
  const doc = await databases.createDocument(DB_ID, AUDIO_TRACKS_COLLECTION, ID.unique(), {
    contentKind,
    contentId,
    segmentId: segmentId || '-',
    languageCode,
    trackType,
    contentHash,
    provider: 'sarvam',
    model,
    voiceId: speaker,
    isHumanRecorded: false,
    playbackRatePurpose: null,
    generationStatus: 'processing',
    reviewStatus: 'needsReview', // synthetic audio is NEVER auto-approved
    errorMessage: null,
    createdAt: timestamp,
    updatedAt: timestamp,
  });

  try {
    const { audio, model: usedModel } = await synthesizeSpeech({
      text: cleanText,
      languageTag,
      speaker,
      model,
      pace,
      apiKey: sarvamApiKey,
      fetchImpl,
    });

    const file = InputFile.fromBuffer(audio, `${contentKind}_${contentId}_${languageCode}_${trackType}.wav`, 'audio/wav');
    const uploaded = await storage.createFile(AUDIO_BUCKET_ID, ID.unique(), file);

    const buildUrl =
      audioUrlBuilder ||
      ((fileId) =>
        `${process.env.APPWRITE_FUNCTION_API_ENDPOINT || process.env.APPWRITE_ENDPOINT}/storage/buckets/${AUDIO_BUCKET_ID}/files/${fileId}/view?project=${process.env.APPWRITE_FUNCTION_PROJECT_ID || process.env.APPWRITE_PROJECT_ID}`);

    const audioUrl = buildUrl(uploaded.$id);

    await databases.updateDocument(DB_ID, AUDIO_TRACKS_COLLECTION, doc.$id, {
      audioUrl,
      storageFileId: uploaded.$id,
      durationMs: null,
      model: usedModel,
      generationStatus: 'completed',
      errorMessage: null,
      updatedAt: now(),
    });

    return {
      status: 200,
      payload: ok({
        trackId: doc.$id,
        audioUrl,
        storageFileId: uploaded.$id,
        generationStatus: 'completed',
        reviewStatus: 'needsReview',
        model: usedModel,
        cached: false,
      }),
    };
  } catch (genErr) {
    // Redact any provider secret leakage before persisting.
    const safeMessage = String(genErr?.message || 'generation_failed').replace(
      /api-subscription-key[^\s]*/gi,
      '[redacted]'
    );
    await databases
      .updateDocument(DB_ID, AUDIO_TRACKS_COLLECTION, doc.$id, {
        generationStatus: 'failed',
        errorMessage: safeMessage.slice(0, 1000),
        updatedAt: now(),
      })
      .catch(() => {});

    return {
      status: 502,
      payload: err('Audio generation failed. Please try again later.', 'GENERATION_FAILED'),
    };
  }
}

export default async ({ req, res, log, error }) => {
  const startTime = Date.now();
  const body = parseBody(req.body);

  const invalid = validateGenerateAudioRequest({ method: req.method, body });
  if (invalid) {
    return res.json(err(invalid.message, invalid.code), invalid.status);
  }

  const config = requireConfig();
  if (config.missing) {
    error(JSON.stringify({ event: 'server_misconfigured', missing: config.missing }));
    return res.json(err('Audio generation service unavailable.', 'SERVER_MISCONFIGURED'), 500);
  }

  const client = new Client()
    .setEndpoint(config.endpoint)
    .setProject(config.projectId)
    .setKey(config.apiKey);
  const users = new Users(client);
  const databases = new Databases(client);
  const storage = new Storage(client);

  // Admin-team gate (matches admin-maintenance): generation is an
  // editorial/admin operation, never a public learner endpoint.
  const userId = req.headers['x-appwrite-user-id'];
  const isAdmin = await userIsAdmin(users, userId);
  if (!isAdmin) {
    return res.json(err('Admin team membership required.', 'FORBIDDEN'), 403);
  }

  const result = await generateTrack({
    databases,
    storage,
    sarvamApiKey: config.sarvamApiKey,
    contentKind: body.contentKind.trim().toLowerCase(),
    contentId: body.contentId.trim(),
    segmentId: body.segmentId ? String(body.segmentId).trim() : null,
    languageCode: body.languageCode.trim().toLowerCase(),
    trackType: body.trackType.trim(),
    text: body.text,
    speaker: body.speaker,
    model: body.model || DEFAULT_MODEL,
    pace: body.pace !== undefined ? body.pace : DEFAULT_PACE,
  });

  if (!result.payload.success) {
    log(JSON.stringify({
      event: 'generation_failed',
      contentKind: body.contentKind,
      contentId: body.contentId,
      languageCode: body.languageCode,
      durationMs: Date.now() - startTime,
    }));
  } else {
    log(JSON.stringify({
      event: 'generation_success',
      contentKind: body.contentKind,
      contentId: body.contentId,
      languageCode: body.languageCode,
      trackType: body.trackType,
      cached: result.payload.data.cached,
      durationMs: Date.now() - startTime,
    }));
  }

  return res.json(result.payload, result.status);
};
