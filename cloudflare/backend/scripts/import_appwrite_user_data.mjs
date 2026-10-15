#!/usr/bin/env node
// Copy learners' per-user data from the Appwrite database (olitun_db) into
// Cloudflare D1 (olitun-db). Appwrite is now only used for login; this is the
// one-shot import for the data that could not be migrated while the Appwrite
// database was over its read quota.
//
// USAGE (from cloudflare/backend):
//   node scripts/import_appwrite_user_data.mjs ~/.appwrite/olitun_server_key --dry-run
//   node scripts/import_appwrite_user_data.mjs ~/.appwrite/olitun_server_key --state ./.appwrite-import-state.json
//
// The first argument is a file holding an Appwrite server API key with
// databases.read, tables.read/rows.read (or collections.read/documents.read)
// and users.read. It is read from disk and never printed.
//
// Options:
//   --dry-run                  Read and map only; write nothing to D1. Prints
//                              counts and 3 sample mapped rows per collection
//                              (user ids hashed, contact details redacted).
//   --collections a,b          Only these Appwrite collections (default: all
//                              in COLLECTIONS below).
//   --since <iso>              Only rows with $updatedAt >= this instant.
//   --state <file>             Resume file: the last committed cursor per
//                              collection. Re-running with the same file
//                              continues where the previous run stopped.
//   --d1 <name>                D1 database (default olitun-db).
//   --local                    Write to the local D1 (wrangler --local) instead
//                              of --remote. For testing.
//   --persist-to <dir>         With --local: wrangler persistence directory.
//   --endpoint <url>           Appwrite API (default https://sgp.cloud.appwrite.io/v1).
//   --project <id>             Appwrite project (default 699495910038e39622c5).
//   --database <id>            Appwrite database (default olitun_db).
//   --batch <n>                Rows per D1 write (default 200).
//   --deletion-secret-file <f> DELETION_HMAC_SECRET (first line) and older
//                              secrets (further lines / commas) of the old
//                              delete-account function. Needed to recognise
//                              users with an open Appwrite deletion request,
//                              whose rows only carry a pseudonymous id.
//   --allow-unmatched-deletions  Continue even though open Appwrite deletion
//                              requests exist that cannot be attributed (no
//                              secret). The users.read check still applies.
//   --no-user-check            Skip the per-user Appwrite account lookup.
//
// Users are never resurrected: a user is skipped when D1 has a
// deletion_requests row for them (any status, matched by the Worker's
// `del_` + stableId('deletion:<uid>') id or by user_id), when Appwrite has a
// deletion request for them, or when their Appwrite account no longer exists
// or is blocked.
//
// Idempotent and safe to re-run. Rows the learner created or changed on
// Cloudflare after the migration always win (see CONFLICT_SQL). The run ends
// with a JSON summary on stdout (per collection: read, written, skipped,
// errors); progress goes to stderr. Exit code 1 if any batch failed, 2 if the
// run was aborted (e.g. the Appwrite read quota is still exhausted).

import { createCipheriv, createDecipheriv, createHash, createHmac, pbkdf2Sync } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync, renameSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const BACKEND_DIR = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const PAGE_SIZE = 100;
const DAY_MS = 86_400_000;

// ---------------------------------------------------------------- helpers

export function stableId(value) {
  // Same as cloudflare/backend/src/env.ts and the old Appwrite functions.
  return createHash('sha256').update(value).digest('hex').slice(0, 32);
}

/** review_states row id (src/routes/review.ts rowIdFor). */
export function reviewRowIdFor(userId, itemId) {
  const digest = createHash('sha256')
    .update(`usr:${userId.length}:${userId}:item:${itemId.length}:${itemId}`)
    .digest('hex');
  return `r_${digest.slice(0, 31)}`;
}

/** D1 deletion_requests id written by src/routes/account.ts. */
export function d1DeletionRequestId(userId) {
  return `del_${stableId(`deletion:${userId}`)}`;
}

/** Appwrite delete-account pseudonymous id (former Appwrite delete_account_core). */
export function appwritePseudonymousId(userId, secret) {
  return createHmac('sha256', secret).update(userId).digest('hex').substring(0, 32);
}

const derivedKeys = new Map();
/** getDerivedKey in the former Appwrite delete_account_core (cached: PBKDF2 is slow). */
function deletionKey(secret) {
  if (!derivedKeys.has(secret)) derivedKeys.set(secret, pbkdf2Sync(secret, 'olitun_deletion_v1', 100000, 32, 'sha256'));
  return derivedKeys.get(secret);
}

/** Mirrors decryptUserId in the former Appwrite delete_account_core. */
export function decryptAppwriteUserId(payload, secrets) {
  if (!payload) return null;
  let parsed;
  try {
    parsed = typeof payload === 'string' ? JSON.parse(payload) : payload;
  } catch (_) {
    return null;
  }
  if (!parsed || !parsed.iv || !parsed.ct || !parsed.tag) return null;
  for (const secret of secrets) {
    try {
      const decipher = createDecipheriv('aes-256-gcm', deletionKey(secret), Buffer.from(parsed.iv, 'hex'));
      decipher.setAuthTag(Buffer.from(parsed.tag, 'hex'));
      return Buffer.concat([decipher.update(Buffer.from(parsed.ct, 'hex')), decipher.final()]).toString('utf8');
    } catch (_) {
      // try the next secret
    }
  }
  return null;
}

/** Test helper: the encryption half of the same scheme. */
export function encryptAppwriteUserId(userId, secret) {
  const iv = Buffer.alloc(12, 7);
  const cipher = createCipheriv('aes-256-gcm', deletionKey(secret), iv);
  const ct = Buffer.concat([cipher.update(userId, 'utf8'), cipher.final()]);
  return JSON.stringify({ v: 1, iv: iv.toString('hex'), ct: ct.toString('hex'), tag: cipher.getAuthTag().toString('hex') });
}

const APPWRITE_ID = /^[A-Za-z0-9][A-Za-z0-9._-]{0,35}$/;
const ROW_ID = /^[A-Za-z0-9][A-Za-z0-9._:-]{0,99}$/;
export const isValidUserId = (v) => typeof v === 'string' && APPWRITE_ID.test(v);
const isValidRowId = (v) => typeof v === 'string' && ROW_ID.test(v);

/** SQL literal. Strings are single-quote escaped; NUL bytes are dropped. */
export function sqlValue(v) {
  if (v === null || v === undefined) return 'NULL';
  if (typeof v === 'boolean') return v ? '1' : '0';
  if (typeof v === 'number') return Number.isFinite(v) ? String(v) : 'NULL';
  return `'${String(v).replace(/\u0000/g, '').replace(/'/g, "''")}'`;
}

const SAFE_IDENT = /^[a-z_][a-z0-9_]*$/;

export function insertSql(table, row, conflict = '') {
  const cols = Object.keys(row);
  for (const c of [table, ...cols]) if (!SAFE_IDENT.test(c)) throw new Error(`unsafe identifier ${c}`);
  return `INSERT INTO ${table} (${cols.join(', ')}) VALUES (${cols.map((c) => sqlValue(row[c])).join(', ')})${conflict ? ` ${conflict}` : ''};`;
}

const text = (v, max) => (v === undefined || v === null ? '' : String(v).trim().slice(0, max));
const parseTs = (v) => (typeof v === 'string' && v !== '' ? Date.parse(v) : NaN);
const isTimestamp = (v) => !Number.isNaN(parseTs(v));
/** ISO-8601 UTC, or `fallback` when missing/unparseable. */
export function iso(v, fallback = '') {
  const t = parseTs(v);
  return Number.isNaN(t) ? fallback : new Date(t).toISOString();
}
function int(v, def, min, max) {
  const n = Math.round(Number(v));
  if (!Number.isFinite(n)) return def;
  return Math.max(min, Math.min(max, n));
}
const byteLength = (s) => Buffer.byteLength(s, 'utf8');
const skip = (reason) => ({ skip: reason });

// ---------------------------------------------------------------- conflicts

// Conflict policy per table. Appwrite is frozen, so anything written on
// Cloudflare after the migration is newer and must win.
export const CONFLICT_SQL = {
  // Newest snapshot wins: only replace when the imported row is strictly
  // newer (updated_at) and not behind on lastReviewedAt. Re-runs are no-ops.
  review_states: `ON CONFLICT(id) DO UPDATE SET item_type = excluded.item_type, state_json = excluded.state_json,
  next_review_at = excluded.next_review_at, last_reviewed_at = excluded.last_reviewed_at,
  schema_version = excluded.schema_version, version = review_states.version + 1,
  write_token = excluded.write_token, updated_at = excluded.updated_at
  WHERE review_states.user_id = excluded.user_id
    AND excluded.updated_at > review_states.updated_at
    AND COALESCE(excluded.last_reviewed_at, '') >= COALESCE(review_states.last_reviewed_at, '')`,
  // Replace only when the imported mistake saw more recent activity.
  user_mistakes: `ON CONFLICT(id) DO UPDATE SET question_index = excluded.question_index, wrong_answer = excluded.wrong_answer,
  correct_answer = excluded.correct_answer, question_snapshot = excluded.question_snapshot,
  times_missed = excluded.times_missed, times_reviewed = excluded.times_reviewed, is_mastered = excluded.is_mastered,
  mastered_at = excluded.mastered_at, last_missed_at = excluded.last_missed_at, last_reviewed_at = excluded.last_reviewed_at
  WHERE user_mistakes.user_id = excluded.user_id
    AND MAX(COALESCE(excluded.last_missed_at, ''), COALESCE(excluded.last_reviewed_at, ''), COALESCE(excluded.mastered_at, ''))
      > MAX(COALESCE(user_mistakes.last_missed_at, ''), COALESCE(user_mistakes.last_reviewed_at, ''), COALESCE(user_mistakes.mastered_at, ''))`,
  mistake_review_sessions: 'ON CONFLICT(session_id) DO NOTHING',
  // Monotonic merge, as the Worker does: highest percent, completion sticks,
  // playback position from whichever side is newer.
  bakhed_listening_progress: `ON CONFLICT(id) DO UPDATE SET
  listened_percent = MAX(bakhed_listening_progress.listened_percent, excluded.listened_percent),
  completed_80_percent = MAX(bakhed_listening_progress.completed_80_percent, excluded.completed_80_percent),
  completed_at = CASE WHEN COALESCE(bakhed_listening_progress.completed_at, '') <> '' THEN bakhed_listening_progress.completed_at ELSE excluded.completed_at END,
  last_position_ms = CASE WHEN excluded.updated_at > COALESCE(bakhed_listening_progress.updated_at, '') THEN excluded.last_position_ms ELSE bakhed_listening_progress.last_position_ms END,
  updated_at = MAX(COALESCE(bakhed_listening_progress.updated_at, ''), excluded.updated_at)
  WHERE bakhed_listening_progress.user_id = excluded.user_id`,
  user_badges: `ON CONFLICT(id) DO UPDATE SET
  progress = MAX(user_badges.progress, excluded.progress),
  is_unlocked = MAX(user_badges.is_unlocked, excluded.is_unlocked),
  unlocked_at = CASE WHEN COALESCE(user_badges.unlocked_at, '') <> '' THEN user_badges.unlocked_at ELSE excluded.unlocked_at END,
  updated_at = MAX(COALESCE(user_badges.updated_at, ''), COALESCE(excluded.updated_at, ''))
  WHERE user_badges.user_id = excluded.user_id`,
  reward_events: 'ON CONFLICT(id) DO NOTHING',
  learning_analytics_events: 'ON CONFLICT(id) DO NOTHING',
  learning_analytics_event_details: 'ON CONFLICT(event_id) DO NOTHING',
  binti_waitlist: 'ON CONFLICT(id) DO NOTHING',
  // A purchase already in D1 (bought, refunded or anonymised there) wins.
  course_purchases: 'ON CONFLICT(id) DO NOTHING',
  purchase_refunds: 'ON CONFLICT(purchase_id) DO NOTHING',
};

// ---------------------------------------------------------------- mappers
// Each mapper takes an Appwrite row/document and returns
// { userId, id, rows: [{table, row}], statements: [sql] } or { skip: reason }.

const REVIEW_ITEM_TYPES = new Set(['word', 'sentence']);
const STATE_JSON_MAX_BYTES = 8192;

export function mapReviewState(doc) {
  const userId = text(doc.userId, 80);
  if (!isValidUserId(userId)) return skip('invalid_user');
  let state = doc.stateJson;
  let json;
  if (typeof state === 'string') {
    json = state;
    try { state = JSON.parse(state); } catch (_) { return skip('invalid_state_json'); }
  } else if (state && typeof state === 'object') {
    json = JSON.stringify(state);
  } else return skip('invalid_state_json');
  if (!state || typeof state !== 'object' || Array.isArray(state)) return skip('invalid_state_json');
  if (byteLength(json) > STATE_JSON_MAX_BYTES) return skip('state_too_large');
  const itemId = text(doc.itemId ?? state.itemId, 1000);
  if (!itemId || itemId.length > 120) return skip('invalid_item');
  const itemType = text(doc.itemType ?? state.itemType, 20);
  if (!REVIEW_ITEM_TYPES.has(itemType)) return skip('invalid_item_type');
  const nextReviewAt = iso(doc.nextReviewAt) || iso(state.nextReviewAt);
  if (!nextReviewAt) return skip('invalid_next_review_at');
  const lastReviewedAt = iso(doc.lastReviewedAt) || iso(state.lastReviewedAt) || null;
  const sv = Number(doc.schemaVersion ?? state.schemaVersion ?? 3);
  const schemaVersion = [1, 2, 3].includes(sv) ? sv : 3;
  const id = reviewRowIdFor(userId, itemId);
  const updatedAt = iso(doc.$updatedAt) || lastReviewedAt || iso(state.introducedAt) || nextReviewAt;
  const row = {
    id, user_id: userId, item_id: itemId, item_type: itemType, state_json: json,
    next_review_at: nextReviewAt, last_reviewed_at: lastReviewedAt, schema_version: schemaVersion,
    version: 1, write_token: `import_${stableId(`${id}:${updatedAt}`)}`, updated_at: updatedAt,
  };
  return {
    userId, id, legacy: doc.$id !== id,
    effectiveTs: parseTs(lastReviewedAt) || parseTs(state.introducedAt) || parseTs(nextReviewAt) || 0,
    rows: [{ table: 'review_states', row }],
  };
}

/**
 * Collapses several Appwrite rows for the same (user, item) - legacy
 * `user__item` ids next to the hashed id - into the newest one, judged like
 * mutateReviewState did: lastReviewedAt / introducedAt / nextReviewAt, then
 * $updatedAt, then the hashed (non-legacy) row.
 */
export function dedupeReviewStates(mapped) {
  const best = new Map();
  for (const m of mapped) {
    const cur = best.get(m.id);
    if (!cur) { best.set(m.id, m); continue; }
    const a = [m.effectiveTs, m.rows[0].row.updated_at, m.legacy ? 0 : 1];
    const b = [cur.effectiveTs, cur.rows[0].row.updated_at, cur.legacy ? 0 : 1];
    const newer = a[0] !== b[0] ? a[0] > b[0] : a[1] !== b[1] ? a[1] > b[1] : a[2] > b[2];
    if (newer) best.set(m.id, m);
  }
  return { kept: [...best.values()], dropped: mapped.length - best.size };
}

export function mapUserMistake(doc) {
  const userId = text(doc.userId, 80);
  if (!isValidUserId(userId)) return skip('invalid_user');
  const quizId = text(doc.quizId, 100);
  const questionIndex = Number.isInteger(doc.questionIndex) ? doc.questionIndex : 0;
  const questionId = text(doc.questionId || `${quizId}_${questionIndex}`, 100);
  if (!quizId || !questionId) return skip('invalid_question');
  let snapshot = typeof doc.questionSnapshot === 'string' ? doc.questionSnapshot
    : doc.questionSnapshot && typeof doc.questionSnapshot === 'object' ? JSON.stringify(doc.questionSnapshot) : '{}';
  if (snapshot.length > 10000) snapshot = '{}';
  const id = stableId(`${userId}:${quizId}:${questionId}`);
  const row = {
    id, user_id: userId, quiz_id: quizId, question_id: questionId, question_index: questionIndex,
    wrong_answer: text(doc.wrongAnswer, 2048), correct_answer: text(doc.correctAnswer, 2048),
    question_snapshot: snapshot,
    times_missed: int(doc.timesMissed, 1, 0, 1_000_000), times_reviewed: int(doc.timesReviewed, 0, 0, 1_000_000),
    is_mastered: doc.isMastered === true ? 1 : 0,
    mastered_at: iso(doc.masteredAt), last_missed_at: iso(doc.lastMissedAt) || iso(doc.$createdAt),
    last_reviewed_at: iso(doc.lastReviewedAt),
  };
  return { userId, id, rows: [{ table: 'user_mistakes', row }] };
}

export function mapMistakeReviewSession(doc) {
  const userId = text(doc.userId, 80);
  if (!isValidUserId(userId)) return skip('invalid_user');
  const sessionId = text(doc.sessionId || doc.$id, 100);
  if (!isValidRowId(sessionId)) return skip('invalid_id');
  let ids = [];
  try {
    const parsed = typeof doc.questionIds === 'string' ? JSON.parse(doc.questionIds) : doc.questionIds;
    if (Array.isArray(parsed)) ids = parsed.map((q) => String(q).slice(0, 100)).filter(Boolean).slice(0, 50);
  } catch (_) { /* leave empty */ }
  const total = int(doc.total, ids.length, 0, 1000);
  const row = {
    session_id: sessionId, user_id: userId, question_ids: JSON.stringify(ids),
    score: int(doc.score, 0, 0, total), total, completed_at: iso(doc.completedAt) || iso(doc.$createdAt),
  };
  return { userId, id: sessionId, rows: [{ table: 'mistake_review_sessions', row }] };
}

export function mapBakhedProgress(doc) {
  const userId = text(doc.userId, 80);
  if (!isValidUserId(userId)) return skip('invalid_user');
  const bakhedId = text(doc.bakhedId, 100);
  if (!bakhedId) return skip('invalid_bakhed');
  const listened = int(doc.listenedPercent, 0, 0, 100);
  const completed = doc.completed80Percent === true || listened >= 80 ? 1 : 0;
  const updatedAt = iso(doc.updatedAt) || iso(doc.$updatedAt);
  const id = stableId(`${userId}:${bakhedId}`);
  const row = {
    id, user_id: userId, bakhed_id: bakhedId, listened_percent: listened, completed_80_percent: completed,
    completed_at: completed ? (iso(doc.completedAt) || updatedAt) : '',
    last_position_ms: int(doc.lastPositionMs, 0, 0, 86_400_000), updated_at: updatedAt,
  };
  return { userId, id, rows: [{ table: 'bakhed_listening_progress', row }] };
}

export function mapUserBadge(doc) {
  const userId = text(doc.userId, 80);
  if (!isValidUserId(userId)) return skip('invalid_user');
  const badgeId = text(doc.badgeId, 100);
  if (!badgeId) return skip('invalid_badge');
  const unlocked = doc.isUnlocked === true ? 1 : 0;
  const id = stableId(`${userId}:${badgeId}`);
  const row = {
    id, user_id: userId, badge_id: badgeId, progress: int(doc.progress, 0, 0, 1_000_000),
    target: int(doc.target, 1, 1, 1_000_000), is_unlocked: unlocked,
    unlocked_at: unlocked ? iso(doc.unlockedAt) : '', updated_at: iso(doc.updatedAt) || iso(doc.$updatedAt),
  };
  return { userId, id, rows: [{ table: 'user_badges', row }] };
}

export function mapRewardEvent(doc) {
  const userId = text(doc.userId, 80);
  if (!isValidUserId(userId)) return skip('invalid_user');
  const id = text(doc.rewardEventId || doc.$id, 100);
  if (!isValidRowId(id)) return skip('invalid_id');
  const row = {
    id, user_id: userId, source_type: text(doc.sourceType, 80), source_id: text(doc.sourceId, 120),
    stars_awarded: int(doc.starsAwarded, 0, 0, 100_000), badge_id: text(doc.badgeId, 100) || null,
    reason: text(doc.reason, 2048), created_at: iso(doc.createdAt) || iso(doc.$createdAt),
  };
  return { userId, id, rows: [{ table: 'reward_events', row }] };
}

const EVENT_NAME = /^[a-z][a-z0-9_]{1,63}$/;
const EVENT_ID = /^[A-Za-z0-9][A-Za-z0-9._-]{0,35}$/;
const ANALYTICS_RETENTION_DAYS = 90;

function optionalText(v, max) {
  if (v === undefined || v === null) return null;
  const t = String(v).trim();
  if (t.length > max) throw new Error('too_long');
  return t === '' ? null : t;
}

export function mapAnalyticsEvent(doc, now = Date.now()) {
  // Guests have no user id; the Worker stores them under ''.
  const rawUser = doc.userId === undefined || doc.userId === null ? '' : String(doc.userId).trim();
  if (rawUser && !isValidUserId(rawUser)) return skip('invalid_user');
  const eventId = text(doc.eventId, 100);
  if (!EVENT_ID.test(eventId)) return skip('invalid_event_id');
  const eventName = text(doc.eventName, 100);
  if (!EVENT_NAME.test(eventName)) return skip('invalid_event_name');
  const occurredMs = parseTs(doc.occurredAt);
  if (Number.isNaN(occurredMs)) return skip('invalid_occurred_at');
  if (occurredMs > now + DAY_MS) return skip('future_event');
  // The Worker's daily cleanup drops anything older than the retention window.
  const cutoff = new Date(now - ANALYTICS_RETENTION_DAYS * DAY_MS).toISOString().slice(0, 10);
  const occurredAt = new Date(occurredMs).toISOString();
  const dateKey = occurredAt.slice(0, 10);
  if (dateKey < cutoff) return skip('expired');
  let details;
  let sourceId;
  try {
    let metadata = null;
    if (typeof doc.metadata === 'string') metadata = doc.metadata;
    else if (doc.metadata && typeof doc.metadata === 'object') metadata = JSON.stringify(doc.metadata);
    if (metadata !== null && metadata.length > 4096) throw new Error('too_long');
    const version = doc.eventVersion === undefined || doc.eventVersion === null ? 1 : doc.eventVersion;
    if (!Number.isInteger(version) || version < 1 || version > 1000) throw new Error('bad_version');
    details = {
      session_id: optionalText(doc.sessionId, 64), source: optionalText(doc.source, 80),
      learner_level: optionalText(doc.learnerLevel, 40), script_mode: optionalText(doc.scriptMode, 40),
      platform: optionalText(doc.platform, 20), event_version: version, metadata_json: metadata,
    };
    sourceId = optionalText(doc.sourceId, 120);
  } catch (_) {
    return skip('invalid_event_fields');
  }
  const id = stableId(`analytics:${rawUser}:${eventId}`);
  return {
    userId: rawUser || null, id,
    rows: [
      {
        table: 'learning_analytics_events',
        row: { id, user_id: rawUser, event_name: eventName, date_key: dateKey, source_id: sourceId, occurred_at: occurredAt, created_at: iso(doc.$createdAt) || occurredAt },
      },
      { table: 'learning_analytics_event_details', row: { event_id: id, user_id: rawUser, date_key: dateKey, ...details } },
    ],
  };
}

const CEREMONY_TYPES = new Set(['wedding', 'karam', 'sohrai', 'baha', 'naming', 'funeral', 'other']);
const WAITLIST_STATUSES = new Set(['new', 'contacted', 'converted', 'closed']);
const PHONE_PATTERN = /^\+?[0-9][0-9\s-]{6,19}$/;

export function mapWaitlistEntry(doc) {
  const rawUser = doc.userId ? String(doc.userId).trim() : '';
  if (rawUser && !isValidUserId(rawUser)) return skip('invalid_user');
  const id = text(doc.$id, 100);
  if (!isValidRowId(id)) return skip('invalid_id');
  const fullName = text(doc.fullName, 1000);
  const phone = text(doc.phoneNumber, 1000);
  const ceremony = text(doc.ceremonyType, 100).toLowerCase();
  const city = text(doc.city, 1000);
  const state = text(doc.state, 1000);
  if (fullName.length < 2 || fullName.length > 100 || !PHONE_PATTERN.test(phone) || phone.length > 20 ||
      !CEREMONY_TYPES.has(ceremony) || city.length < 2 || city.length > 100 || state.length < 2 || state.length > 100) {
    return skip('invalid_waitlist_fields');
  }
  const submittedAt = iso(doc.submittedAt) || iso(doc.$createdAt);
  if (!submittedAt) return skip('invalid_submitted_at');
  const status = WAITLIST_STATUSES.has(doc.status) ? doc.status : 'new';
  const row = {
    id, user_id: rawUser || null, full_name: fullName, phone_number: phone, ceremony_type: ceremony,
    city, state, event_date: iso(doc.eventDate) || null, notes: text(doc.notes, 1000) || null,
    submitted_at: submittedAt, status,
  };
  return { userId: rawUser || null, id, rows: [{ table: 'binti_waitlist', row }], waitlistDedupe: status === 'new' };
}

export function mapCoursePurchase(doc) {
  if (doc.status !== 'verified') return skip('not_verified');
  const userId = text(doc.userId, 80);
  if (!isValidUserId(userId)) return skip('invalid_user');
  const categoryId = text(doc.categoryId, 100);
  if (!categoryId) return skip('invalid_category');
  const orderId = text(doc.providerOrderId || doc.razorpayOrderId, 255);
  const paymentId = text(doc.providerPaymentId || doc.razorpayPaymentId, 255);
  if (!orderId || !paymentId) return skip('no_payment_reference');
  const rupees = Number(doc.paidAmount ?? doc.amountPaidInr ?? doc.expectedAmount);
  const paise = Math.round(rupees * 100);
  if (!Number.isFinite(paise) || paise <= 0) return skip('no_amount');
  const refunded = int(doc.refundedAmountPaise, 0, 0, Number.MAX_SAFE_INTEGER);
  if (doc.refundStatus === 'fully_refunded' || refunded >= paise) return skip('refunded');
  const currency = text(doc.currency, 10).toUpperCase() || 'INR';
  const id = stableId(`purch:${userId}:${categoryId}`);
  const createdAt = iso(doc.verifiedAt) || iso(doc.paidAt) || iso(doc.purchasedAt) || iso(doc.createdAt) || iso(doc.$createdAt);
  const rows = [{
    table: 'course_purchases',
    row: {
      id, user_id: userId, category_id: categoryId, course_id: categoryId, amount_in_cents: paise, currency,
      status: 'completed', order_id: orderId, payment_id: paymentId, created_at: createdAt,
    },
  }];
  const extra = [];
  if (refunded > 0) {
    // Partial refund: keep the running total so a later admin refund adds to it.
    const refund = {
      purchase_id: id, order_id: orderId, refund_status: 'partially_refunded', refunded_amount_paise: refunded,
      refund_epoch: int(doc.refundEpoch, 0, 0, 1_000_000), last_refund_claim_id: text(doc.lastRefundClaimId, 255) || null,
      updated_at: iso(doc.$updatedAt) || createdAt,
    };
    const cols = Object.keys(refund);
    extra.push(
      `INSERT INTO purchase_refunds (${cols.join(', ')}) SELECT ${cols.map((c) => sqlValue(refund[c])).join(', ')} ` +
      `WHERE EXISTS (SELECT 1 FROM course_purchases WHERE id = ${sqlValue(id)} AND order_id = ${sqlValue(orderId)}) ${CONFLICT_SQL.purchase_refunds};`,
    );
  }
  return { userId, id, rows, extraStatements: extra };
}

/** SQL statements for one mapped record. */
export function statementsFor(mapped) {
  const out = [];
  for (const { table, row } of mapped.rows) {
    if (table === 'binti_waitlist' && mapped.waitlistDedupe) {
      // The Worker treats a second 'new' entry for the same phone + ceremony
      // as a duplicate; never create one.
      const cols = Object.keys(row);
      out.push(
        `INSERT INTO binti_waitlist (${cols.join(', ')}) SELECT ${cols.map((c) => sqlValue(row[c])).join(', ')} ` +
        `WHERE NOT EXISTS (SELECT 1 FROM binti_waitlist WHERE phone_number = ${sqlValue(row.phone_number)} ` +
        `AND ceremony_type = ${sqlValue(row.ceremony_type)} AND status = 'new' AND id <> ${sqlValue(row.id)}) ${CONFLICT_SQL.binti_waitlist};`,
      );
    } else {
      out.push(insertSql(table, row, CONFLICT_SQL[table]));
    }
  }
  return out.concat(mapped.extraStatements || []);
}

// Appwrite collection -> mapper. Order matters only for readability.
export const COLLECTIONS = {
  review_states: mapReviewState,
  user_mistakes: mapUserMistake,
  mistake_review_sessions: mapMistakeReviewSession,
  bakhed_listening_progress: mapBakhedProgress,
  user_badges: mapUserBadge,
  reward_events: mapRewardEvent,
  learning_analytics_events: mapAnalyticsEvent,
  binti_guru_waitlist: mapWaitlistEntry,
  course_purchases: mapCoursePurchase,
};

// ---------------------------------------------------------------- deletion guard

/**
 * Decides whether a user asked to be deleted. Fail closed: any D1
 * deletion_requests row (whatever its status) or any Appwrite request that
 * can be attributed to the user marks them deleted.
 */
export function makeDeletionGuard({ d1Rows = [], appwriteDocs = [], secrets = [] }) {
  const d1Ids = new Set(d1Rows.map((r) => r.id));
  const d1Users = new Set(d1Rows.map((r) => r.user_id).filter(Boolean));
  const awUsers = new Set();
  const awPseudo = new Set();
  let unattributedOpen = 0;
  for (const doc of appwriteDocs) {
    const pseudo = doc.pseudonymousId || (String(doc.$id || '').startsWith('del_') ? String(doc.$id).slice(4) : '');
    if (pseudo) awPseudo.add(pseudo);
    if (doc.userId && doc.userId !== 'anonymized_deleted_user') awUsers.add(doc.userId);
    const decrypted = decryptAppwriteUserId(doc.encryptedUserId, secrets);
    if (decrypted) awUsers.add(decrypted);
    // A completed Appwrite deletion already removed the login; the account
    // lookup catches those. Open ones keep the login, so they must be matched.
    const open = doc.status !== 'completed';
    if (open && !decrypted && !(doc.userId && doc.userId !== 'anonymized_deleted_user') && secrets.length === 0) {
      unattributedOpen += 1;
    }
  }
  return {
    unattributedOpen,
    isDeleted(userId) {
      if (!userId) return false;
      if (d1Ids.has(d1DeletionRequestId(userId)) || d1Users.has(userId)) return true;
      if (awUsers.has(userId)) return true;
      return secrets.some((s) => awPseudo.has(appwritePseudonymousId(userId, s)));
    },
  };
}

// ---------------------------------------------------------------- Appwrite REST

export class QuotaError extends Error {}

export function appwriteClient({ endpoint, project, key, database }) {
  const headers = { 'X-Appwrite-Project': project, 'X-Appwrite-Key': key, 'Content-Type': 'application/json' };
  async function getJson(path, queries = []) {
    const url = new URL(`${endpoint}${path}`);
    for (const q of queries) url.searchParams.append('queries[]', JSON.stringify(q));
    const res = await fetch(url, { headers });
    const body = await res.text();
    let json = null;
    try { json = JSON.parse(body); } catch (_) { /* not JSON */ }
    if (res.status === 402 || json?.type === 'limit_databases_reads_exceeded') {
      throw new QuotaError(`Appwrite database read quota still exhausted (${json?.type || 'HTTP 402'}); retry after it resets`);
    }
    if (!res.ok) {
      const err = new Error(`Appwrite ${path} -> HTTP ${res.status} ${json?.type || ''}`.trim());
      err.status = res.status;
      throw err;
    }
    return json;
  }
  let mode = null; // 'tablesdb' | 'databases', decided on the first call
  async function page(collection, queries) {
    const tables = `/tablesdb/${encodeURIComponent(database)}/tables/${encodeURIComponent(collection)}/rows`;
    const legacy = `/databases/${encodeURIComponent(database)}/collections/${encodeURIComponent(collection)}/documents`;
    if (mode !== 'databases') {
      try {
        const res = await getJson(tables, queries);
        mode = 'tablesdb';
        return res.rows || [];
      } catch (err) {
        if (err.status !== 404) throw err;
        if (mode === 'tablesdb') throw err; // endpoint exists; the table does not
      }
    }
    const res = await getJson(legacy, queries);
    mode = 'databases';
    return res.documents || [];
  }
  return {
    getJson,
    /** Yields pages of rows; `cursor` resumes after that row id. */
    async *pages(collection, { since = null, cursor = null } = {}) {
      for (;;) {
        const queries = [{ method: 'limit', values: [PAGE_SIZE] }];
        if (since) queries.push({ method: 'greaterThanEqual', attribute: '$updatedAt', values: [since] });
        if (cursor) queries.push({ method: 'cursorAfter', values: [cursor] });
        const items = await page(collection, queries);
        if (items.length === 0) return;
        cursor = items[items.length - 1].$id;
        yield items;
        if (items.length < PAGE_SIZE) return;
      }
    },
    /** 'ok' | 'missing' | 'blocked' for an Appwrite account. */
    async userStatus(userId) {
      try {
        const user = await getJson(`/users/${encodeURIComponent(userId)}`);
        return user?.status === false ? 'blocked' : 'ok';
      } catch (err) {
        if (err.status === 404) return 'missing';
        throw err;
      }
    },
  };
}

// ---------------------------------------------------------------- D1 via wrangler

function wranglerBin() {
  const local = join(BACKEND_DIR, 'node_modules', '.bin', 'wrangler');
  return existsSync(local) ? { cmd: local, pre: [] } : { cmd: 'npx', pre: ['wrangler'] };
}

export function d1Runner(opts) {
  const target = opts.local ? ['--local', ...(opts.persistTo ? ['--persist-to', resolve(opts.persistTo)] : [])] : ['--remote'];
  const { cmd, pre } = wranglerBin();
  function run(extra) {
    const res = spawnSync(cmd, [...pre, 'd1', 'execute', opts.d1, ...target, '--yes', '--json', ...extra], {
      cwd: BACKEND_DIR, encoding: 'utf8', maxBuffer: 256 * 1024 * 1024, env: { ...process.env, CI: '1' },
    });
    if (res.status !== 0) {
      throw new Error(`wrangler d1 execute failed: ${(res.stderr || res.stdout || '').trim().slice(-500)}`);
    }
    return res.stdout;
  }
  return {
    query(sql) {
      const out = run(['--command', sql]);
      const start = out.indexOf('[');
      const parsed = JSON.parse(out.slice(start));
      return parsed.flatMap((r) => r.results || []);
    },
    execFile(statements) {
      const dir = mkdtempSync(join(tmpdir(), 'aw-import-'));
      const file = join(dir, 'batch.sql');
      try {
        writeFileSync(file, `${statements.join('\n')}\n`);
        run(['--file', file]);
      } finally {
        rmSync(dir, { recursive: true, force: true });
      }
    },
  };
}

// ---------------------------------------------------------------- CLI

export function parseArgs(argv) {
  const opts = {
    keyFile: '', dryRun: false, collections: null, since: null, state: null, d1: 'olitun-db', local: false,
    persistTo: null, endpoint: 'https://sgp.cloud.appwrite.io/v1', project: '699495910038e39622c5',
    database: 'olitun_db', batch: 200, deletionSecretFile: null, allowUnmatchedDeletions: false, userCheck: true,
  };
  const rest = [...argv];
  while (rest.length) {
    const arg = rest.shift();
    const value = () => {
      const v = rest.shift();
      if (v === undefined) throw new Error(`${arg} needs a value`);
      return v;
    };
    if (arg === '--dry-run') opts.dryRun = true;
    else if (arg === '--collections') opts.collections = value().split(',').map((s) => s.trim()).filter(Boolean);
    else if (arg === '--since') {
      const v = value();
      if (!isTimestamp(v)) throw new Error('--since needs an ISO timestamp');
      opts.since = new Date(Date.parse(v)).toISOString();
    } else if (arg === '--state') opts.state = value();
    else if (arg === '--d1') opts.d1 = value();
    else if (arg === '--local') opts.local = true;
    else if (arg === '--persist-to') opts.persistTo = value();
    else if (arg === '--endpoint') opts.endpoint = value().replace(/\/+$/, '');
    else if (arg === '--project') opts.project = value();
    else if (arg === '--database') opts.database = value();
    else if (arg === '--batch') {
      const n = Number(value());
      if (!Number.isInteger(n) || n < 1 || n > 5000) throw new Error('--batch must be 1..5000');
      opts.batch = n;
    } else if (arg === '--deletion-secret-file') opts.deletionSecretFile = value();
    else if (arg === '--allow-unmatched-deletions') opts.allowUnmatchedDeletions = true;
    else if (arg === '--no-user-check') opts.userCheck = false;
    else if (arg === '-h' || arg === '--help') {
      console.log(readFileSync(new URL(import.meta.url), 'utf8').split('\n').filter((l) => l.startsWith('//')).join('\n'));
      process.exit(0);
    } else if (arg.startsWith('--')) throw new Error(`Unknown option ${arg}`);
    else if (!opts.keyFile) opts.keyFile = arg;
    else throw new Error(`Unexpected argument ${arg}`);
  }
  if (!opts.keyFile) throw new Error('Usage: import_appwrite_user_data.mjs <appwrite-key-file> [--dry-run] [options]');
  if (opts.persistTo && !opts.local) throw new Error('--persist-to only applies with --local');
  for (const c of opts.collections || []) {
    if (!COLLECTIONS[c]) throw new Error(`Unknown collection ${c}; known: ${Object.keys(COLLECTIONS).join(', ')}`);
  }
  return opts;
}

const hashUser = (uid) => (uid ? `u_${createHash('sha256').update(`sample:${uid}`).digest('hex').slice(0, 12)}` : uid);

/** Sample row safe to print: user ids hashed, contact details redacted. */
export function redactSample(mapped) {
  return mapped.rows.map(({ table, row }) => {
    const r = { ...row };
    if (r.user_id) r.user_id = hashUser(r.user_id);
    for (const k of ['full_name', 'phone_number', 'notes', 'city']) if (r[k]) r[k] = '[redacted]';
    for (const k of ['state_json', 'question_snapshot', 'metadata_json']) {
      if (typeof r[k] === 'string' && r[k].length > 120) r[k] = `${r[k].slice(0, 120)}...`;
    }
    return { table, row: r };
  });
}

function loadState(file) {
  if (!file || !existsSync(file)) return { version: 1, collections: {} };
  const s = JSON.parse(readFileSync(file, 'utf8'));
  return s && typeof s === 'object' && s.collections ? s : { version: 1, collections: {} };
}

function saveState(file, state) {
  if (!file) return;
  const tmp = `${file}.tmp`;
  writeFileSync(tmp, `${JSON.stringify(state, null, 2)}\n`);
  renameSync(tmp, file);
}

async function readAll(aw, collection) {
  const out = [];
  try {
    for await (const items of aw.pages(collection)) out.push(...items);
  } catch (err) {
    if (err.status === 404) return null;
    throw err;
  }
  return out;
}

export async function run(opts, log = (m) => process.stderr.write(`${m}\n`)) {
  const key = readFileSync(opts.keyFile, 'utf8').trim();
  if (!key) throw new Error('Appwrite key file is empty');
  const secrets = opts.deletionSecretFile
    ? readFileSync(opts.deletionSecretFile, 'utf8').split(/[\n,]/).map((s) => s.trim()).filter(Boolean)
    : [];
  const aw = appwriteClient({ endpoint: opts.endpoint, project: opts.project, key, database: opts.database });
  const d1 = d1Runner(opts);
  const summary = { dryRun: opts.dryRun, target: opts.local ? 'local' : 'remote', d1: opts.d1, since: opts.since, collections: {}, aborted: null };

  // 1. Who must never be imported.
  let d1Rows;
  try {
    d1Rows = d1.query('SELECT id, user_id, status FROM deletion_requests');
  } catch (err) {
    if (!opts.dryRun) throw new Error(`Cannot read D1 deletion_requests (refusing to import blind): ${err.message}`);
    log(`[dry-run] warning: could not read D1 deletion_requests: ${err.message}`);
    d1Rows = [];
  }
  const awDeletion = await readAll(aw, 'deletion_requests');
  if (awDeletion === null) log('Appwrite deletion_requests not found; relying on D1 + account checks');
  const guard = makeDeletionGuard({ d1Rows, appwriteDocs: awDeletion || [], secrets });
  summary.deletionRequests = { d1: d1Rows.length, appwrite: (awDeletion || []).length, unattributedOpen: guard.unattributedOpen };
  if (guard.unattributedOpen > 0 && !opts.allowUnmatchedDeletions) {
    throw new Error(
      `${guard.unattributedOpen} open Appwrite deletion request(s) cannot be attributed without the delete-account ` +
      'secret. Pass --deletion-secret-file (DELETION_HMAC_SECRET) or --allow-unmatched-deletions.',
    );
  }

  const userCache = new Map();
  async function userSkipReason(userId) {
    if (!userId) return null;
    if (guard.isDeleted(userId)) return 'deletion_requested';
    if (!opts.userCheck) return null;
    if (!userCache.has(userId)) userCache.set(userId, await aw.userStatus(userId));
    const st = userCache.get(userId);
    return st === 'missing' ? 'user_missing' : st === 'blocked' ? 'user_blocked' : null;
  }

  const state = opts.dryRun ? { version: 1, collections: {} } : loadState(opts.state);
  const names = opts.collections || Object.keys(COLLECTIONS);
  let failed = false;

  for (const name of names) {
    const mapper = COLLECTIONS[name];
    const stats = { read: 0, written: 0, skipped: 0, errors: 0, skipReasons: {} };
    summary.collections[name] = stats;
    const prior = state.collections[name] || {};
    if (prior.done && opts.state) {
      Object.assign(stats, prior.totals || {}, { resumed: 'already_done' });
      log(`${name}: already done in ${opts.state}; skipping`);
      continue;
    }
    if (prior.totals) for (const k of ['read', 'written', 'skipped', 'errors']) stats[k] = prior.totals[k] || 0;
    const samples = [];
    const bump = (reason) => {
      stats.skipped += 1;
      stats.skipReasons[reason] = (stats.skipReasons[reason] || 0) + 1;
    };
    let pending = [];
    let pendingCursor = null;
    const flush = () => {
      if (pending.length === 0) return true;
      let records = pending;
      if (name === 'review_states') {
        const { kept, dropped } = dedupeReviewStates(records);
        for (let i = 0; i < dropped; i++) bump('superseded_duplicate');
        records = kept;
      }
      if (!opts.dryRun) {
        try {
          d1.execFile(records.flatMap(statementsFor));
        } catch (err) {
          stats.errors += records.length;
          log(`${name}: batch failed (${records.length} rows): ${err.message}`);
          return false;
        }
        stats.written += records.length;
        state.collections[name] = { cursor: pendingCursor, done: false, totals: { ...stats, skipReasons: undefined } };
        saveState(opts.state, state);
      } else {
        stats.wouldWrite = (stats.wouldWrite || 0) + records.length;
      }
      pending = [];
      return true;
    };

    let ok = true;
    try {
      for await (const items of aw.pages(name, { since: opts.since, cursor: prior.cursor || null })) {
        for (const doc of items) {
          stats.read += 1;
          const mapped = name === 'learning_analytics_events' ? mapper(doc, Date.now()) : mapper(doc);
          if (mapped.skip) { bump(mapped.skip); continue; }
          const reason = await userSkipReason(mapped.userId);
          if (reason) { bump(reason); continue; }
          if (name === 'review_states' && mapped.legacy) stats.legacyRewritten = (stats.legacyRewritten || 0) + 1;
          if (samples.length < 3) samples.push(redactSample(mapped));
          pending.push(mapped);
        }
        pendingCursor = items[items.length - 1].$id;
        if (pending.length >= opts.batch && !flush()) { ok = false; break; }
      }
      if (ok && !flush()) ok = false;
    } catch (err) {
      if (err instanceof QuotaError) throw Object.assign(err, { summary });
      if (err.status === 404) {
        stats.missing = true;
        log(`${name}: collection not found in Appwrite; skipping`);
      } else {
        stats.errors += 1;
        ok = false;
        log(`${name}: ${err.message}`);
      }
    }
    if (!ok) failed = true;
    if (ok && !opts.dryRun) {
      state.collections[name] = { cursor: pendingCursor || prior.cursor || null, done: true, totals: { ...stats, skipReasons: undefined } };
      saveState(opts.state, state);
    }
    if (opts.dryRun) stats.samples = samples;
    log(`${name}: read ${stats.read}, ${opts.dryRun ? `would write ${stats.wouldWrite || 0}` : `written ${stats.written}`}, skipped ${stats.skipped}, errors ${stats.errors}`);
  }
  summary.ok = !failed;
  return summary;
}

async function main() {
  let opts;
  try {
    opts = parseArgs(process.argv.slice(2));
  } catch (err) {
    console.error(err.message);
    process.exit(2);
  }
  try {
    const summary = await run(opts);
    console.log(JSON.stringify(summary, null, 2));
    process.exit(summary.ok ? 0 : 1);
  } catch (err) {
    console.error(`Aborted: ${err.message}`);
    if (err.summary) console.log(JSON.stringify({ ...err.summary, aborted: err.message }, null, 2));
    process.exit(2);
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  main();
}
