/**
 * reviewContent — Phase 5 admin review workflow Appwrite Function.
 *
 * Gives admins a CMS-style queue over the two review-gated
 * collections so learner-facing content can be moderated:
 *
 * - audio_tracks        (Sarvam-generated in Phase 4 + human uploads)
 * - localized_contents  (Phase 2 translated meanings/explanations)
 *
 * Actions:
 *   list_audio / approve_audio / reject_audio
 *   list_localized / approve_localized / reject_localized
 *
 * Guarantees:
 * - admin-team gate (fails closed) — same as admin-maintenance
 * - approving audio requires a completed track with an audioUrl
 *   (or a human-recorded upload); broken audio never becomes
 *   playable for learners (see canApproveAudioTrack)
 * - every decision stamps reviewedBy/reviewedAt for audit
 * - batch actions are capped at 50 ids
 */

import { Client, Databases, Query, Users } from 'node-appwrite';
import {
  ACTIONS,
  canApproveAudioTrack,
  validateReviewRequest,
} from './validation.js';

export const DB_ID = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
export const AUDIO_TRACKS_COLLECTION = 'audio_tracks';
export const LOCALIZED_CONTENTS_COLLECTION = 'localized_contents';
export const ADMIN_TEAM_ID = process.env.ADMIN_TEAM_ID || 'admins';

const ok = (data) => ({ success: true, data });
const err = (message, code = 'REVIEW_ERROR') => ({
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

  if (missing.length > 0) {
    return { missing };
  }
  return { endpoint, projectId, apiKey };
}

export async function userIsAdmin(users, userId) {
  if (!userId) return false;
  try {
    const memberships = await users.listMemberships(userId);
    return memberships.memberships.some(
      (membership) => membership.teamId === ADMIN_TEAM_ID,
    );
  } catch {
    return false;
  }
}

/** Builds the Appwrite queries for a list action. */
export function buildListQueries({ reviewStatus, languageCode, contentKind, generationStatus, limit, offset }) {
  const queries = [Query.limit(limit), Query.offset(offset)];
  if (reviewStatus) queries.push(Query.equal('reviewStatus', reviewStatus));
  if (languageCode) queries.push(Query.equal('languageCode', languageCode));
  if (contentKind) queries.push(Query.equal('contentKind', contentKind));
  if (generationStatus) queries.push(Query.equal('generationStatus', generationStatus));
  return queries;
}

/** Projects a document into a lean review-queue row. */
export function toAudioRow(doc) {
  return {
    id: doc.$id,
    contentKind: doc.contentKind,
    contentId: doc.contentId,
    segmentId: doc.segmentId,
    languageCode: doc.languageCode,
    trackType: doc.trackType,
    audioUrl: doc.audioUrl,
    storageFileId: doc.storageFileId,
    provider: doc.provider,
    model: doc.model,
    voiceId: doc.voiceId,
    isHumanRecorded: doc.isHumanRecorded === true,
    generationStatus: doc.generationStatus,
    reviewStatus: doc.reviewStatus,
    errorMessage: doc.errorMessage,
    reviewedBy: doc.reviewedBy,
    reviewedAt: doc.reviewedAt,
    updatedAt: doc.updatedAt,
    createdAt: doc.createdAt,
  };
}

/** Projects a localized_contents document into a review-queue row. */
export function toLocalizedRow(doc) {
  return {
    id: doc.$id,
    contentKind: doc.contentKind,
    contentId: doc.contentId,
    languageCode: doc.languageCode,
    meaning: doc.meaning,
    explanation: doc.explanation,
    hint: doc.hint,
    grammarNote: doc.grammarNote,
    exampleTranslation: doc.exampleTranslation,
    pronunciationGuide: doc.pronunciationGuide,
    reviewStatus: doc.reviewStatus,
    reviewedBy: doc.reviewedBy,
    reviewedAt: doc.reviewedAt,
    version: doc.version,
  };
}

/**
 * Mutates reviewStatus for a batch of ids in one collection.
 * All services are injected so tests can drive the full flow.
 *
 * For approve_audio, each track must pass canApproveAudioTrack;
 * failures are reported per-id and never block the rest of the
 * batch (partial success with explicit results is the sane admin
 * UX for a 50-item queue).
 */
export async function applyReviewDecisions({
  databases,
  collectionId,
  ids,
  decision, // 'approved' | 'rejected'
  reviewedBy,
  now = () => new Date().toISOString(),
}) {
  const results = [];
  const timestamp = now();

  for (const id of ids) {
    let doc;
    try {
      doc = await databases.getDocument(DB_ID, collectionId, id);
    } catch {
      results.push({ id, ok: false, reason: 'NOT_FOUND' });
      continue;
    }

    if (collectionId === AUDIO_TRACKS_COLLECTION && decision === 'approved') {
      if (!canApproveAudioTrack(doc)) {
        results.push({ id, ok: false, reason: 'TRACK_NOT_APPROVABLE' });
        continue;
      }
    }

    const patch = {
      reviewStatus: decision,
      reviewedBy,
      reviewedAt: timestamp,
      updatedAt: timestamp,
    };

    // localized_contents clears stale error metadata on approval;
    // audio_tracks keeps generation/error info for diagnostics.
    await databases.updateDocument(DB_ID, collectionId, id, patch);

    results.push({ id, ok: true, reviewStatus: decision, reviewedAt: timestamp });
  }

  const approvedCount = results.filter((r) => r.ok).length;
  return {
    status: 200,
    payload: ok({
      decision,
      reviewedBy,
      requested: ids.length,
      updated: approvedCount,
      failed: results.filter((r) => !r.ok).length,
      results,
    }),
  };
}

/**
 * Core handler for a validated request. All services injected for
 * testability; assumes the caller has already passed the admin gate.
 */
export async function handleReviewRequest({
  databases,
  action,
  ids,
  reviewStatus,
  languageCode,
  contentKind,
  generationStatus,
  limit,
  offset,
  reviewedBy,
  now = () => new Date().toISOString(),
}) {
  switch (action) {
    case ACTIONS.LIST_AUDIO: {
      const queries = buildListQueries({
        reviewStatus,
        languageCode,
        contentKind,
        generationStatus,
        limit,
        offset,
      });
      const page = await databases.listDocuments(
        DB_ID,
        AUDIO_TRACKS_COLLECTION,
        queries,
      );
      return {
        status: 200,
        payload: ok({
          kind: 'audio',
          total: page.total,
          documents: (page.documents || []).map(toAudioRow),
        }),
      };
    }

    case ACTIONS.LIST_LOCALIZED: {
      const queries = buildListQueries({
        reviewStatus,
        languageCode,
        contentKind,
        generationStatus: null, // not a localized_contents attribute
        limit,
        offset,
      });
      const page = await databases.listDocuments(
        DB_ID,
        LOCALIZED_CONTENTS_COLLECTION,
        queries,
      );
      return {
        status: 200,
        payload: ok({
          kind: 'localized',
          total: page.total,
          documents: (page.documents || []).map(toLocalizedRow),
        }),
      };
    }

    case ACTIONS.APPROVE_AUDIO:
      return applyReviewDecisions({
        databases,
        collectionId: AUDIO_TRACKS_COLLECTION,
        ids,
        decision: 'approved',
        reviewedBy,
        now,
      });

    case ACTIONS.REJECT_AUDIO:
      return applyReviewDecisions({
        databases,
        collectionId: AUDIO_TRACKS_COLLECTION,
        ids,
        decision: 'rejected',
        reviewedBy,
        now,
      });

    case ACTIONS.APPROVE_LOCALIZED:
      return applyReviewDecisions({
        databases,
        collectionId: LOCALIZED_CONTENTS_COLLECTION,
        ids,
        decision: 'approved',
        reviewedBy,
        now,
      });

    case ACTIONS.REJECT_LOCALIZED:
      return applyReviewDecisions({
        databases,
        collectionId: LOCALIZED_CONTENTS_COLLECTION,
        ids,
        decision: 'rejected',
        reviewedBy,
        now,
      });

    default:
      return { status: 400, payload: err('Unsupported review action.', 'UNSUPPORTED_ACTION') };
  }
}

export default async ({ req, res, log, error }) => {
  const startTime = Date.now();
  const body = parseBody(req.body);

  const invalid = validateReviewRequest({ method: req.method, body });
  if (invalid) {
    return res.json(err(invalid.message, invalid.code), invalid.status);
  }

  const config = requireConfig();
  if (config.missing) {
    error(JSON.stringify({ event: 'server_misconfigured', missing: config.missing }));
    return res.json(err('Review service unavailable.', 'SERVER_MISCONFIGURED'), 500);
  }

  const client = new Client()
    .setEndpoint(config.endpoint)
    .setProject(config.projectId)
    .setKey(config.apiKey);
  const users = new Users(client);
  const databases = new Databases(client);

  // Admin-team gate — fails closed (same pattern as admin-maintenance
  // and generateAudio). Learners never hold review rights.
  const userId = req.headers['x-appwrite-user-id'];
  const isAdmin = await userIsAdmin(users, userId);
  if (!isAdmin) {
    return res.json(err('Admin team membership required.', 'FORBIDDEN'), 403);
  }

  const result = await handleReviewRequest({
    databases,
    action: body.action,
    ids: body.ids,
    reviewStatus: body.reviewStatus,
    languageCode: body.languageCode,
    contentKind: body.contentKind,
    generationStatus: body.generationStatus,
    limit: body.limit,
    offset: body.offset,
    reviewedBy: userId,
  });

  log(JSON.stringify({
    event: result.payload.success ? 'review_action_completed' : 'review_action_failed',
    action: body.action,
    userId,
    durationMs: Date.now() - startTime,
  }));

  return res.json(result.payload, result.status);
};
