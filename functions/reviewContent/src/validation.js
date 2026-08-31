/**
 * Request validation for the reviewContent admin function (Phase 5).
 *
 * Product-policy rules enforced here (before any DB call):
 * - POST only; all actions go through the admin gate in main.js
 * - audio can only be approved when generation completed AND an
 *   audioUrl exists — a broken/incomplete track must never become
 *   playable for learners
 * - Santali audio (isHumanRecorded or languageCode 'sat' tracks) is
 *   never *created* here; approving human recordings is fine and is
 *   exactly the CMS workflow
 * - ids are capped at 50 per batch action
 */

export const ACTIONS = {
  LIST_AUDIO: 'list_audio',
  APPROVE_AUDIO: 'approve_audio',
  REJECT_AUDIO: 'reject_audio',
  LIST_LOCALIZED: 'list_localized',
  APPROVE_LOCALIZED: 'approve_localized',
  REJECT_LOCALIZED: 'reject_localized',
};

export const MAX_BATCH_IDS = 50;
export const MAX_PAGE_LIMIT = 100;
export const DEFAULT_PAGE_LIMIT = 25;

export const ALLOWED_REVIEW_FILTERS = new Set([
  'needsReview',
  'approved',
  'rejected',
  'draft',
  'generated',
]);

export const ALLOWED_GENERATION_FILTERS = new Set([
  'notRequested',
  'queued',
  'processing',
  'completed',
  'failed',
]);

function asTrimmedString(value, maxLength = 128) {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  if (!trimmed) return null;
  return trimmed.slice(0, maxLength);
}

function asIdList(value) {
  if (!Array.isArray(value)) return null;
  const ids = value
    .map((id) => asTrimmedString(id, 100))
    .filter(Boolean);
  if (ids.length === 0) return null;
  if (ids.length > MAX_BATCH_IDS) return null;
  // de-dupe while preserving order
  return [...new Set(ids)];
}

/**
 * Returns null when the request is valid, otherwise
 * { status, message, code }.
 */
export function validateReviewRequest({ method, body }) {
  if (method !== 'POST') {
    return { status: 405, message: 'Method not allowed.', code: 'METHOD_NOT_ALLOWED' };
  }

  if (!body || typeof body !== 'object') {
    return { status: 400, message: 'Invalid JSON body.', code: 'INVALID_INPUT' };
  }

  const action = asTrimmedString(body.action, 40);
  if (!action || !Object.values(ACTIONS).includes(action)) {
    return {
      status: 400,
      message: 'Unsupported review action.',
      code: 'UNSUPPORTED_ACTION',
    };
  }

  const isList = action === ACTIONS.LIST_AUDIO || action === ACTIONS.LIST_LOCALIZED;
  const isAudio = action.endsWith('_audio');
  const isMutation =
    action.startsWith('approve_') || action.startsWith('reject_');

  const parsed = { action, isAudio, isMutation };

  if (isMutation) {
    const ids = asIdList(body.ids);
    if (!ids) {
      return {
        status: 400,
        message: `ids must be a non-empty list of at most ${MAX_BATCH_IDS} document ids.`,
        code: 'INVALID_INPUT',
      };
    }
    parsed.ids = ids;
  }

  if (isList) {
    const limitRaw = Number(body.limit);
    const limit = Number.isInteger(limitRaw) && limitRaw > 0
      ? Math.min(limitRaw, MAX_PAGE_LIMIT)
      : DEFAULT_PAGE_LIMIT;
    parsed.limit = limit;

    if (body.offset !== undefined) {
      const offsetRaw = Number(body.offset);
      if (!Number.isInteger(offsetRaw) || offsetRaw < 0 || offsetRaw > 100000) {
        return { status: 400, message: 'offset must be a non-negative integer.', code: 'INVALID_INPUT' };
      }
      parsed.offset = offsetRaw;
    } else {
      parsed.offset = 0;
    }

    // Optional filters
    if (body.reviewStatus !== undefined && body.reviewStatus !== null && body.reviewStatus !== '') {
      if (!ALLOWED_REVIEW_FILTERS.has(body.reviewStatus)) {
        return { status: 400, message: 'Unsupported reviewStatus filter.', code: 'INVALID_INPUT' };
      }
      parsed.reviewStatus = body.reviewStatus;
    } else {
      parsed.reviewStatus = 'needsReview'; // the review queue default
    }

    if (isAudio) {
      if (body.languageCode !== undefined && body.languageCode !== null && body.languageCode !== '') {
        parsed.languageCode = asTrimmedString(body.languageCode, 10)?.toLowerCase() || null;
      }
      if (body.contentKind !== undefined && body.contentKind !== null && body.contentKind !== '') {
        parsed.contentKind = asTrimmedString(body.contentKind, 30);
      }
      if (
        body.generationStatus !== undefined &&
        body.generationStatus !== null &&
        body.generationStatus !== ''
      ) {
        if (!ALLOWED_GENERATION_FILTERS.has(body.generationStatus)) {
          return { status: 400, message: 'Unsupported generationStatus filter.', code: 'INVALID_INPUT' };
        }
        parsed.generationStatus = body.generationStatus;
      }
    } else {
      if (body.languageCode !== undefined && body.languageCode !== null && body.languageCode !== '') {
        parsed.languageCode = asTrimmedString(body.languageCode, 10)?.toLowerCase() || null;
      }
      if (body.contentKind !== undefined && body.contentKind !== null && body.contentKind !== '') {
        parsed.contentKind = asTrimmedString(body.contentKind, 30);
      }
    }
  }

  return null;
}

/**
 * Whether an audio_tracks row may transition to 'approved'.
 * Synthetic or human tracks must have completed generation and a
 * usable audioUrl before they can become playable for learners.
 * Human-recorded tracks (isHumanRecorded) are uploaded directly by
 * admins, so they may be approved without a generationStatus.
 */
export function canApproveAudioTrack(doc) {
  if (!doc) return false;
  const hasAudioUrl =
    typeof doc.audioUrl === 'string' && doc.audioUrl.trim().length > 0;
  if (!hasAudioUrl) return false;

  if (doc.isHumanRecorded === true) return true;

  return doc.generationStatus === 'completed';
}
