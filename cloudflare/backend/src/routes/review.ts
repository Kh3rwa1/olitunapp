import type { Context } from 'hono';
import { requireUser } from '../auth';
import { getRequestUserId, type App, type AppEnv } from '../env';

// Learner spaced-repetition (SRS) sync. Ports the Appwrite Function
// `mutateReviewState` (functions/mutateReviewState/src/main.js) to D1:
//
// - Ownership is server-derived from the verified JWT. A body `userId` that
//   differs from the caller is rejected with 403, never trusted.
// - Row identity is deterministic and identical to the Appwrite row id
//   (`r_` + sha256 of the length-prefixed user/item pair), so rows copied
//   from Appwrite keep their ids.
// - applyRecall is idempotent per (user, operationId) via the
//   `review_operations` ledger. Counters are applied as deltas, scheduling
//   fields follow newest-occurredAt-wins (ties by operationId). The snapshot
//   write and the ledger row commit in one D1 batch, guarded by an
//   optimistic version check, so a recall applies exactly once.

type ReviewContext = Context<AppEnv>;

const USER_ID_MAX_LENGTH = 80;
const ITEM_ID_MAX_LENGTH = 120;
const STATE_JSON_MAX_BYTES = 8192;
const ITEM_TYPES = new Set(['word', 'sentence']);
const EXERCISE_TYPES = new Set(['recognition', 'typing', 'listening', 'sentence']);
const SUPPORTED_SCHEMA_VERSIONS = [1, 2, 3];
const DEFAULT_SCHEMA_VERSION = 3;
const OPERATION_ID_MAX_LENGTH = 128;
const DEVICE_ID_MAX_LENGTH = 128;
const RESPONSE_TIME_MAX_MS = 3_600_000;
const DEFAULT_LIST_PAGE_SIZE = 500;
const MAX_LIST_PAGE_SIZE = 500;
const MAX_APPLY_ATTEMPTS = 3;
const RECENT_OPERATION_IDS = 10;

type RecallOp = {
  operationId: string;
  itemId: string;
  itemType: string;
  exerciseType: string;
  correct: boolean;
  responseTimeMs: number | null;
  occurredAt: string;
  deviceId: string;
  localSequence: number;
  schemaVersion: number;
};

type StateRow = {
  id: string;
  user_id: string;
  item_id: string;
  item_type: string;
  state_json: string;
  next_review_at: string;
  last_reviewed_at: string | null;
  schema_version: number;
  version: number;
};

type Parsed<T> = { ok: true; value: T } | { ok: false; status: 400 | 413; error: string; message: string };

const invalid = (message: string): Parsed<never> => ({ ok: false, status: 400, error: 'INVALID_ARGUMENT', message });
const tooLarge = (message: string): Parsed<never> => ({ ok: false, status: 413, error: 'PAYLOAD_TOO_LARGE', message });

const encoder = new TextEncoder();
const byteLength = (value: string) => encoder.encode(value).length;
const isTimestamp = (value: unknown) => typeof value === 'string' && value !== '' && !Number.isNaN(Date.parse(value));
const toIso = (value: string) => new Date(Date.parse(value)).toISOString();

async function sha256Hex(input: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', encoder.encode(input));
  return Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, '0')).join('');
}

/** Same id as the Appwrite `review_states` row for this user/item. */
export async function rowIdFor(userId: string, itemId: string): Promise<string> {
  const digest = await sha256Hex(`usr:${userId.length}:${userId}:item:${itemId.length}:${itemId}`);
  return `r_${digest.slice(0, 31)}`;
}

/** Same id as the Appwrite `review_operations` ledger row. */
export async function operationRowIdFor(userId: string, operationId: string): Promise<string> {
  const digest = await sha256Hex(`usr:${userId.length}:${userId}:op:${operationId.length}:${operationId}`);
  return `op_${digest.slice(0, 30)}`;
}

function parseSchemaVersion(raw: unknown): Parsed<number> {
  if (raw === undefined || raw === null) return { ok: true, value: DEFAULT_SCHEMA_VERSION };
  const v = Number(raw);
  if (!Number.isInteger(v) || !SUPPORTED_SCHEMA_VERSIONS.includes(v)) {
    return invalid('Invalid or unsupported schemaVersion');
  }
  return { ok: true, value: v };
}

function parseItemId(body: any): Parsed<string> {
  const itemId = String(body.itemId || '').trim();
  if (!itemId || itemId.length > ITEM_ID_MAX_LENGTH) {
    return invalid(`Invalid or missing itemId (must be non-empty and <= ${ITEM_ID_MAX_LENGTH} characters)`);
  }
  return { ok: true, value: itemId };
}

/** Parses `stateJson` (string or object) into a non-array JSON object. */
function parseStateObject(raw: unknown): Parsed<{ json: string; state: any }> {
  let json: string;
  let state: any;
  if (typeof raw === 'string') {
    json = raw;
    if (byteLength(json) > STATE_JSON_MAX_BYTES) {
      return tooLarge(`stateJson exceeds maximum allowed size (${STATE_JSON_MAX_BYTES} UTF-8 bytes)`);
    }
    try {
      state = JSON.parse(json);
    } catch (_) {
      return invalid('stateJson is not valid JSON');
    }
  } else if (typeof raw === 'object' && raw !== null) {
    state = raw;
    json = JSON.stringify(raw);
    if (byteLength(json) > STATE_JSON_MAX_BYTES) {
      return tooLarge(`stateJson exceeds maximum allowed size (${STATE_JSON_MAX_BYTES} UTF-8 bytes)`);
    }
  } else {
    return invalid('Missing or invalid stateJson');
  }
  if (typeof state !== 'object' || state === null || Array.isArray(state)) {
    return invalid('stateJson must be a JSON object');
  }
  return { ok: true, value: { json, state } };
}

type UpsertCandidate = {
  itemId: string;
  itemType: string;
  stateJson: string;
  nextReviewAt: string;
  lastReviewedAt: string | null;
  schemaVersion: number;
};

export function parseUpsertRequest(body: any): Parsed<UpsertCandidate> {
  const itemId = parseItemId(body);
  if (!itemId.ok) return itemId;
  const itemType = String(body.itemType || '').trim();
  if (!ITEM_TYPES.has(itemType)) return invalid('Invalid itemType. Must be "word" or "sentence"');

  const parsedState = parseStateObject(body.stateJson);
  if (!parsedState.ok) return parsedState;
  const state = parsedState.value.state;

  if (!isTimestamp(body.nextReviewAt)) return invalid('Invalid or missing nextReviewAt ISO timestamp');
  const outerNext = Date.parse(body.nextReviewAt);

  let lastReviewedAt: string | null = null;
  const hasOuterLast = body.lastReviewedAt !== undefined && body.lastReviewedAt !== null;
  if (hasOuterLast) {
    if (!isTimestamp(body.lastReviewedAt)) return invalid('Invalid lastReviewedAt ISO timestamp');
    lastReviewedAt = toIso(body.lastReviewedAt);
  }

  const schemaVersion = parseSchemaVersion(body.schemaVersion);
  if (!schemaVersion.ok) return schemaVersion;

  // The indexed columns must agree with the snapshot they summarise.
  if (state.itemId !== itemId.value) return invalid('stateJson.itemId must equal request.itemId');
  if (state.itemType !== itemType) return invalid('stateJson.itemType must equal request.itemType');
  if (!isTimestamp(state.nextReviewAt)) return invalid('stateJson.nextReviewAt must be a valid ISO timestamp');
  if (Date.parse(state.nextReviewAt) !== outerNext) {
    return invalid('stateJson.nextReviewAt must represent the same instant as request.nextReviewAt');
  }
  const hasInnerLast = state.lastReviewedAt !== undefined && state.lastReviewedAt !== null;
  if (hasOuterLast !== hasInnerLast) {
    return invalid('Mismatched lastReviewedAt presence between request and stateJson');
  }
  if (hasInnerLast) {
    if (!isTimestamp(state.lastReviewedAt)) return invalid('stateJson.lastReviewedAt must be a valid ISO timestamp');
    if (Date.parse(state.lastReviewedAt) !== Date.parse(body.lastReviewedAt)) {
      return invalid('stateJson.lastReviewedAt must represent the same instant as request.lastReviewedAt');
    }
  }
  if (body.schemaVersion !== undefined && body.schemaVersion !== null &&
      state.schemaVersion !== undefined && state.schemaVersion !== null &&
      Number(state.schemaVersion) !== Number(body.schemaVersion)) {
    return invalid('stateJson.schemaVersion must match request.schemaVersion');
  }

  return {
    ok: true,
    value: {
      itemId: itemId.value,
      itemType,
      stateJson: parsedState.value.json,
      nextReviewAt: new Date(outerNext).toISOString(),
      lastReviewedAt,
      schemaVersion: schemaVersion.value,
    },
  };
}

export function parseApplyRecallRequest(body: any): Parsed<RecallOp> {
  const operationId = String(body.operationId || '').trim();
  if (!operationId || operationId.length > OPERATION_ID_MAX_LENGTH) {
    return invalid(`Invalid operationId (must be non-empty and <= ${OPERATION_ID_MAX_LENGTH} characters)`);
  }
  if (!/^[a-zA-Z0-9][a-zA-Z0-9._:-]*$/.test(operationId)) return invalid('Invalid operationId format');
  const itemId = parseItemId(body);
  if (!itemId.ok) return itemId;
  const itemType = String(body.itemType || '').trim();
  if (!ITEM_TYPES.has(itemType)) return invalid('Invalid itemType. Must be "word" or "sentence"');
  const exerciseType = String(body.exerciseType || '').trim();
  if (!EXERCISE_TYPES.has(exerciseType)) {
    return invalid('Invalid exerciseType. Must be one of recognition/typing/listening/sentence');
  }
  if (typeof body.correct !== 'boolean') return invalid('Missing or invalid correct flag (must be boolean)');
  let responseTimeMs: number | null = null;
  if (body.responseTimeMs !== undefined && body.responseTimeMs !== null) {
    const rt = Number(body.responseTimeMs);
    if (!Number.isInteger(rt) || rt < 0 || rt > RESPONSE_TIME_MAX_MS) return invalid('Invalid responseTimeMs');
    responseTimeMs = rt;
  }
  if (!isTimestamp(body.occurredAt)) return invalid('Invalid or missing occurredAt ISO timestamp');
  const deviceId = String(body.deviceId || '').trim();
  if (!deviceId || deviceId.length > DEVICE_ID_MAX_LENGTH) {
    return invalid(`Invalid deviceId (must be non-empty and <= ${DEVICE_ID_MAX_LENGTH} characters)`);
  }
  const localSequence = Number(body.localSequence ?? 0);
  if (!Number.isInteger(localSequence) || localSequence < 0) {
    return invalid('Invalid localSequence (must be an integer >= 0)');
  }
  const schemaVersion = parseSchemaVersion(body.schemaVersion);
  if (!schemaVersion.ok) return schemaVersion;
  return {
    ok: true,
    value: {
      operationId,
      itemId: itemId.value,
      itemType,
      exerciseType,
      correct: body.correct,
      responseTimeMs,
      occurredAt: toIso(body.occurredAt),
      deviceId,
      localSequence,
      schemaVersion: schemaVersion.value,
    },
  };
}

const recentOf = (s: any): string[] => (Array.isArray(s?.recentOperationIds) ? s.recentOperationIds : []);

/**
 * Applies one recall to the stored snapshot. Counters move by delta so
 * concurrent recalls from different devices are all kept; scheduling and
 * display fields follow newest-occurredAt-wins, ties by operationId.
 */
export function computeMerged(base: any, op: RecallOp, clientSnap: any): { merged?: any; error?: string } {
  const b = base || {};
  const isTyping = op.exerciseType === 'typing';
  const successes = Number(b.successfulRecalls ?? 0) + (op.correct ? (isTyping ? 2 : 1) : 0);
  const failed = Number(b.failedRecalls ?? 0) + (op.correct ? 0 : 1);
  const typing = Number(b.typingSuccesses ?? 0) + (op.correct && isTyping ? 1 : 0);
  const baseMastery = b.masteryState || 'new';
  const lapsing = baseMastery === 'review' || baseMastery === 'mastered';
  const lapse = Number(b.lapseCount ?? 0) + (!op.correct && lapsing ? 1 : 0);

  let firstRecallAt = b.firstRecallAt || null;
  if (op.correct && (!b.firstRecallAt || Date.parse(b.firstRecallAt) > Date.parse(op.occurredAt))) {
    firstRecallAt = op.occurredAt;
  }
  const introducedAt = b.introducedAt || op.occurredAt;

  const storedLast = b.lastReviewedAt || null;
  const storedOp = b.lastOperationId || '';
  const opIsNewest = !storedLast ||
    Date.parse(op.occurredAt) > Date.parse(storedLast) ||
    (Date.parse(op.occurredAt) === Date.parse(storedLast) && op.operationId > storedOp);
  const pick = (clientVal: any, storedVal: any, fallback: any) => {
    if (opIsNewest && clientVal !== undefined && clientVal !== null) return clientVal;
    if (storedVal !== undefined && storedVal !== null) return storedVal;
    return fallback;
  };
  const nextReviewAt = pick(clientSnap?.nextReviewAt, b.nextReviewAt, op.occurredAt);
  if (!isTimestamp(nextReviewAt)) return { error: 'Cannot determine nextReviewAt' };
  // lastReviewedAt is monotonic: an older op never moves it back.
  const prevLast = isTimestamp(b.lastReviewedAt) ? b.lastReviewedAt : null;
  const lastReviewedAt = !prevLast || Date.parse(op.occurredAt) >= Date.parse(prevLast) ? op.occurredAt : prevLast;

  return {
    merged: {
      ...b,
      itemId: op.itemId,
      itemType: op.itemType,
      introducedAt,
      lastPresentedAt: opIsNewest ? op.occurredAt : (b.lastPresentedAt || op.occurredAt),
      lastReviewedAt,
      nextReviewAt: toIso(nextReviewAt),
      intervalDays: pick(clientSnap?.intervalDays, b.intervalDays, 0),
      ease: pick(clientSnap?.ease, b.ease, 2.5),
      successfulRecalls: successes,
      failedRecalls: failed,
      lapseCount: lapse,
      masteryState: pick(clientSnap?.masteryState, b.masteryState, 'new'),
      lastResponseTimeMs: opIsNewest
        ? (op.responseTimeMs ?? clientSnap?.lastResponseTimeMs ?? b.lastResponseTimeMs ?? null)
        : (b.lastResponseTimeMs ?? null),
      lastExerciseType: opIsNewest ? op.exerciseType : (b.lastExerciseType || op.exerciseType),
      typingSuccesses: typing,
      firstRecallAt,
      lastOperationId: opIsNewest ? op.operationId : storedOp,
      recentOperationIds: [...recentOf(b), op.operationId].slice(-RECENT_OPERATION_IDS),
    },
  };
}

function toClientRow(row: StateRow) {
  return {
    $id: row.id,
    userId: row.user_id,
    itemId: row.item_id,
    itemType: row.item_type,
    stateJson: row.state_json,
    nextReviewAt: row.next_review_at,
    lastReviewedAt: row.last_reviewed_at,
    schemaVersion: row.schema_version,
  };
}

function parseStoredState(row: StateRow | null): any {
  if (!row) return null;
  try {
    const stored = JSON.parse(row.state_json);
    return stored && typeof stored === 'object' && !Array.isArray(stored) ? stored : null;
  } catch (_) {
    return null;
  }
}

async function listStates(c: ReviewContext, userId: string, rawLimit: unknown, rawCursor: unknown) {
  const limit = rawLimit === undefined || rawLimit === null || rawLimit === ''
    ? DEFAULT_LIST_PAGE_SIZE
    : Number(rawLimit);
  if (!Number.isInteger(limit) || limit < 1 || limit > MAX_LIST_PAGE_SIZE) {
    return c.json({ ok: false, error: 'INVALID_ARGUMENT', message: `limit must be an integer from 1 to ${MAX_LIST_PAGE_SIZE}` }, 400);
  }
  const cursor = typeof rawCursor === 'string' ? rawCursor : '';
  if (cursor && !/^r_[a-f0-9]{31}$/.test(cursor)) {
    return c.json({ ok: false, error: 'INVALID_ARGUMENT', message: 'cursor must be a row id from a previous page' }, 400);
  }
  const { results } = await c.env.DB.prepare(
    `SELECT id, user_id, item_id, item_type, state_json, next_review_at, last_reviewed_at, schema_version
       FROM review_states WHERE user_id = ? AND id > ? ORDER BY id ASC LIMIT ?`
  ).bind(userId, cursor, limit).all<StateRow>();
  const rows = (results || []).map(toClientRow);
  const nextCursor = rows.length === limit ? rows[rows.length - 1].$id : null;
  return c.json({ ok: true, rows, hasMore: Boolean(nextCursor), nextCursor });
}

async function upsertState(c: ReviewContext, userId: string, body: any) {
  const parsed = parseUpsertRequest(body);
  if (!parsed.ok) return c.json({ ok: false, error: parsed.error, message: parsed.message }, parsed.status);
  const s = parsed.value;
  const rowId = await rowIdFor(userId, s.itemId);
  const now = new Date().toISOString();
  // Last write wins, as in the Appwrite function. `version` bumps so a
  // concurrent applyRecall retries on top of this snapshot.
  await c.env.DB.prepare(
    `INSERT INTO review_states (id, user_id, item_id, item_type, state_json, next_review_at, last_reviewed_at, schema_version, version, write_token, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
     ON CONFLICT(id) DO UPDATE SET item_type = excluded.item_type, state_json = excluded.state_json,
       next_review_at = excluded.next_review_at, last_reviewed_at = excluded.last_reviewed_at,
       schema_version = excluded.schema_version, version = review_states.version + 1,
       write_token = excluded.write_token, updated_at = excluded.updated_at
     WHERE review_states.user_id = excluded.user_id`
  ).bind(rowId, userId, s.itemId, s.itemType, s.stateJson, s.nextReviewAt, s.lastReviewedAt, s.schemaVersion, crypto.randomUUID(), now).run();
  return c.json({ ok: true, rowId, migratedLegacy: false });
}

async function deleteState(c: ReviewContext, userId: string, body: any) {
  const itemId = parseItemId(body);
  if (!itemId.ok) return c.json({ ok: false, error: itemId.error, message: itemId.message }, itemId.status);
  const rowId = await rowIdFor(userId, itemId.value);
  // Idempotent: deleting a missing row is still success.
  await c.env.DB.prepare('DELETE FROM review_states WHERE id = ? AND user_id = ?').bind(rowId, userId).run();
  return c.json({ ok: true, deleted: true, itemId: itemId.value });
}

async function applyRecall(c: ReviewContext, userId: string, body: any) {
  const parsed = parseApplyRecallRequest(body);
  if (!parsed.ok) return c.json({ ok: false, error: parsed.error, message: parsed.message }, parsed.status);
  const op = parsed.value;

  // Optional client post-recall snapshot supplies newest-writer scheduling fields.
  let clientSnap: any = null;
  if (body.stateJson !== undefined && body.stateJson !== null) {
    const snap = parseStateObject(body.stateJson);
    if (!snap.ok) return c.json({ ok: false, error: snap.error, message: snap.message }, snap.status);
    clientSnap = snap.value.state;
    if (clientSnap.itemId !== op.itemId || clientSnap.itemType !== op.itemType) {
      return c.json({ ok: false, error: 'INVALID_ARGUMENT', message: 'stateJson.itemId/itemType must equal the operation item' }, 400);
    }
  }

  const db = c.env.DB;
  const rowId = await rowIdFor(userId, op.itemId);
  const opRowId = await operationRowIdFor(userId, op.operationId);
  const duplicate = () => c.json({ ok: true, duplicate: true, rowId, operationId: op.operationId });
  const ledgerInsert = (condition: string, ...conditionArgs: unknown[]) => db.prepare(
    `INSERT OR IGNORE INTO review_operations (id, user_id, operation_id, item_id, occurred_at, applied_at)
     SELECT ?, ?, ?, ?, ?, ? WHERE ${condition}`
  ).bind(opRowId, userId, op.operationId, op.itemId, op.occurredAt, new Date().toISOString(), ...conditionArgs);

  for (let attempt = 0; attempt < MAX_APPLY_ATTEMPTS; attempt++) {
    // 1. Idempotency gate: a ledger row means this operation already applied.
    const prior = await db.prepare('SELECT 1 FROM review_operations WHERE user_id = ? AND operation_id = ?')
      .bind(userId, op.operationId).first();
    if (prior) return duplicate();

    const row = await db.prepare(
      `SELECT id, user_id, item_id, item_type, state_json, next_review_at, last_reviewed_at, schema_version, version
         FROM review_states WHERE id = ?`
    ).bind(rowId).first<StateRow>();
    if (row && row.user_id !== userId) {
      return c.json({ ok: false, error: 'FORBIDDEN', message: 'State owned by another user' }, 403);
    }
    if (row && row.item_type !== op.itemType) {
      return c.json({ ok: false, error: 'INVALID_ARGUMENT', message: `Item type mismatch for "${op.itemId}": stored "${row.item_type}" vs operation "${op.itemType}"` }, 400);
    }
    const stored = parseStoredState(row);

    // 2. Snapshot already reflects this op (e.g. rows copied from Appwrite
    //    without their ledger): record the ledger row, skip the delta.
    if (stored && recentOf(stored).includes(op.operationId)) {
      await ledgerInsert('1').run();
      return duplicate();
    }

    const computed = computeMerged(stored, op, clientSnap);
    if (computed.error) return c.json({ ok: false, error: 'INVALID_ARGUMENT', message: computed.error }, 400);
    const mergedJson = JSON.stringify(computed.merged);
    if (byteLength(mergedJson) > STATE_JSON_MAX_BYTES) {
      return c.json({ ok: false, error: 'PAYLOAD_TOO_LARGE', message: 'Merged state exceeds maximum size' }, 413);
    }

    // 3. Snapshot + ledger in one transaction. The snapshot write only lands
    //    if nobody wrote since our read (version check); the ledger row only
    //    lands if our snapshot did (write token check).
    const token = crypto.randomUUID();
    const now = new Date().toISOString();
    const m = computed.merged;
    const snapshotWrite = row
      ? db.prepare(
        `UPDATE review_states SET state_json = ?, next_review_at = ?, last_reviewed_at = ?, schema_version = ?,
           version = version + 1, write_token = ?, updated_at = ?
         WHERE id = ? AND user_id = ? AND version = ?`
      ).bind(mergedJson, m.nextReviewAt, m.lastReviewedAt, op.schemaVersion, token, now, rowId, userId, row.version)
      : db.prepare(
        `INSERT INTO review_states (id, user_id, item_id, item_type, state_json, next_review_at, last_reviewed_at, schema_version, version, write_token, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?) ON CONFLICT(id) DO NOTHING`
      ).bind(rowId, userId, op.itemId, op.itemType, mergedJson, m.nextReviewAt, m.lastReviewedAt, op.schemaVersion, token, now);
    const [written, ledger] = await db.batch([
      snapshotWrite,
      ledgerInsert('EXISTS (SELECT 1 FROM review_states WHERE id = ? AND write_token = ?)', rowId, token),
    ]);
    if ((written.meta?.changes ?? 0) > 0) {
      return c.json({ ok: true, duplicate: (ledger.meta?.changes ?? 0) === 0, rowId, operationId: op.operationId });
    }
    // A concurrent writer landed between our read and write: recompute on
    // the fresh state so both recalls survive.
  }
  return c.json({ ok: false, error: 'SERVER_ERROR', message: 'Concurrent modification could not converge; retry later' }, 500);
}

export function registerReviewRoutes(app: App): void {
  for (const path of ['/api/v1/review/states', '/api/v1/review/mutate']) {
    app.use(path, requireUser);
  }

  // Caller's review states, paginated by row id.
  app.get('/api/v1/review/states', async (c) => {
    const userId = getRequestUserId(c);
    try {
      return await listStates(c, userId, c.req.query('limit'), c.req.query('cursor'));
    } catch (err: any) {
      console.error('review/states failed', err?.message);
      return c.json({ ok: false, error: 'SERVER_ERROR', message: 'Failed to list states' }, 500);
    }
  });

  app.post('/api/v1/review/mutate', async (c) => {
    const userId = getRequestUserId(c);
    if (!userId || userId.length > USER_ID_MAX_LENGTH) {
      return c.json({ ok: false, error: 'UNAUTHENTICATED', message: 'Authentication required' }, 401);
    }
    const body: any = await c.req.json().catch(() => null);
    if (!body || typeof body !== 'object' || Array.isArray(body)) {
      return c.json({ ok: false, error: 'INVALID_ARGUMENT', message: 'Malformed JSON payload' }, 400);
    }
    if (body.userId && String(body.userId).trim() !== userId) {
      return c.json({ ok: false, error: 'FORBIDDEN', message: 'Caller cannot impersonate another user' }, 403);
    }

    const action = body.action || 'upsert';
    try {
      switch (action) {
        case 'upsert':
          return await upsertState(c, userId, body);
        case 'applyRecall':
          return await applyRecall(c, userId, body);
        case 'delete':
          return await deleteState(c, userId, body);
        case 'list':
          return await listStates(c, userId, body.limit, body.cursor);
        default:
          return c.json({ ok: false, error: 'INVALID_ARGUMENT', message: `Unknown action: ${action}` }, 400);
      }
    } catch (err: any) {
      console.error(`review/mutate ${action} failed`, err?.message);
      return c.json({ ok: false, error: 'SERVER_ERROR', message: 'Failed to mutate review state' }, 500);
    }
  });
}
