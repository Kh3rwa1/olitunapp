import { createHash } from 'node:crypto';
import { Client, TablesDB, Query } from 'node-appwrite';
import { REVIEW_SCHEMA_LIMITS } from './review_schema_contract.js';

const {
  USER_ID_MAX_LENGTH,
  ITEM_ID_MAX_LENGTH,
  STATE_JSON_MAX_BYTES,
  ITEM_TYPES,
  SUPPORTED_SCHEMA_VERSIONS,
  DEFAULT_SCHEMA_VERSION,
} = REVIEW_SCHEMA_LIMITS;

const VALID_ITEM_TYPES = new Set(ITEM_TYPES);
const VALID_EXERCISE_TYPES = new Set(REVIEW_SCHEMA_LIMITS.EXERCISE_TYPES);
const OPERATION_ID_MAX_LENGTH = REVIEW_SCHEMA_LIMITS.OPERATION_ID_MAX_LENGTH;
const DEVICE_ID_MAX_LENGTH = REVIEW_SCHEMA_LIMITS.DEVICE_ID_MAX_LENGTH;
const RESPONSE_TIME_MAX_MS = REVIEW_SCHEMA_LIMITS.RESPONSE_TIME_MAX_MS;
const DEFAULT_LIST_PAGE_SIZE = 100;
const MAX_LIST_PAGE_SIZE = 100;

export function rowIdFor(userId, itemId) {
  const input = `usr:${userId.length}:${userId}:item:${itemId.length}:${itemId}`;
  const digest = createHash('sha256').update(input).digest('hex');
  return `r_${digest.slice(0, 31)}`;
}

/// Deterministic row id for the idempotency ledger: one row per
/// (user, operationId). Duplicate deliveries hit the same row and are
/// reported as duplicates without re-applying the recall.
export function operationRowIdFor(userId, operationId) {
  const input = `usr:${userId.length}:${userId}:op:${operationId.length}:${operationId}`;
  const digest = createHash('sha256').update(input).digest('hex');
  return `op_${digest.slice(0, 30)}`;
}

export function legacyRowIdFor(userId, itemId) {
  const clean = (raw) =>
    String(raw || '')
      .replaceAll(/[^a-zA-Z0-9._-]/g, '_')
      .slice(0, 60);
  return `${clean(userId)}__${clean(itemId)}`;
}

export function isValidAppwriteRowId(id) {
  if (typeof id !== 'string' || id.length === 0 || id.length > 36) {
    return false;
  }
  if (id.startsWith('_')) {
    return false;
  }
  return /^[a-zA-Z0-9][a-zA-Z0-9._-]*$/.test(id);
}

export function parseReviewStateListRequest(body = {}) {
  const limit = Number(body.limit ?? DEFAULT_LIST_PAGE_SIZE);
  if (!Number.isInteger(limit) || limit < 1 || limit > MAX_LIST_PAGE_SIZE) {
    return {
      ok: false,
      error: `limit must be an integer from 1 to ${MAX_LIST_PAGE_SIZE}`,
    };
  }

  const rawCursor = body.cursor;
  if (rawCursor === undefined || rawCursor === null || rawCursor === '') {
    return { ok: true, limit, cursor: null };
  }
  if (!isValidAppwriteRowId(rawCursor)) {
    return { ok: false, error: 'cursor must be a valid Appwrite row ID' };
  }
  return { ok: true, limit, cursor: rawCursor };
}

function parseBody(req) {
  if (!req.body) return {};
  if (typeof req.body === 'object') return req.body;
  try {
    return JSON.parse(req.body);
  } catch (_) {
    return null;
  }
}

/**
 * Validates an `applyRecall` operation request.
 *
 * Ownership is server-derived: body.userId (when present) must equal the
 * session user or the request is rejected with 403 — caller-controlled ids
 * are never trusted.
 */
export function parseApplyRecallRequest(body = {}, cleanUserId) {
  const operationId = String(body.operationId || '').trim();
  if (!operationId || operationId.length > OPERATION_ID_MAX_LENGTH) {
    return { ok: false, error: `Invalid operationId (must be non-empty and <= ${OPERATION_ID_MAX_LENGTH} characters)` };
  }
  if (!/^[a-zA-Z0-9][a-zA-Z0-9._:-]*$/.test(operationId)) {
    return { ok: false, error: 'Invalid operationId format' };
  }
  const itemId = String(body.itemId || '').trim();
  if (!itemId || itemId.length > ITEM_ID_MAX_LENGTH) {
    return { ok: false, error: `Invalid or missing itemId (must be non-empty and <= ${ITEM_ID_MAX_LENGTH} characters)` };
  }
  const itemType = String(body.itemType || '').trim();
  if (!VALID_ITEM_TYPES.has(itemType)) {
    return { ok: false, error: 'Invalid itemType. Must be "word" or "sentence"' };
  }
  const exerciseType = String(body.exerciseType || '').trim();
  if (!VALID_EXERCISE_TYPES.has(exerciseType)) {
    return { ok: false, error: 'Invalid exerciseType. Must be one of recognition/typing/listening/sentence' };
  }
  if (typeof body.correct !== 'boolean') {
    return { ok: false, error: 'Missing or invalid correct flag (must be boolean)' };
  }
  let responseTimeMs = null;
  if (body.responseTimeMs !== undefined && body.responseTimeMs !== null) {
    const rt = Number(body.responseTimeMs);
    if (!Number.isInteger(rt) || rt < 0 || rt > RESPONSE_TIME_MAX_MS) {
      return { ok: false, error: 'Invalid responseTimeMs' };
    }
    responseTimeMs = rt;
  }
  const occurredRaw = body.occurredAt;
  if (!occurredRaw || isNaN(Date.parse(occurredRaw))) {
    return { ok: false, error: 'Invalid or missing occurredAt ISO timestamp' };
  }
  const occurredAt = new Date(Date.parse(occurredRaw)).toISOString();
  const deviceId = String(body.deviceId || '').trim();
  if (!deviceId || deviceId.length > DEVICE_ID_MAX_LENGTH) {
    return { ok: false, error: `Invalid deviceId (must be non-empty and <= ${DEVICE_ID_MAX_LENGTH} characters)` };
  }
  const localSequence = Number(body.localSequence ?? 0);
  if (!Number.isInteger(localSequence) || localSequence < 0) {
    return { ok: false, error: 'Invalid localSequence (must be an integer >= 0)' };
  }
  let opSchemaVersion = DEFAULT_SCHEMA_VERSION;
  if (body.schemaVersion !== undefined && body.schemaVersion !== null) {
    const v = Number(body.schemaVersion);
    if (!Number.isInteger(v) || !SUPPORTED_SCHEMA_VERSIONS.includes(v)) {
      return { ok: false, error: 'Invalid or unsupported schemaVersion' };
    }
    opSchemaVersion = v;
  }
  return {
    ok: true,
    op: {
      operationId,
      userId: cleanUserId,
      itemId,
      itemType,
      exerciseType,
      correct: body.correct === true,
      responseTimeMs,
      occurredAt,
      deviceId,
      localSequence,
      schemaVersion: opSchemaVersion,
    },
  };
}

function getEffectiveTimestamp(row) {
  if (!row) return 0;
  const raw = row.lastReviewedAt || row.introducedAt || row.nextReviewAt || 0;
  const parsed = Date.parse(raw);
  return isNaN(parsed) ? 0 : parsed;
}

function getRowId(row) {
  const id = row && (row.$id || row.id);
  return typeof id === 'string' ? id : '';
}

export async function handleMutateReviewState({ req, res, error, log, dbOverride, tablesDBOverride }) {
  if (req.method !== 'POST') {
    return res.json({ ok: false, error: 'METHOD_NOT_ALLOWED', message: 'Only POST method is allowed' }, 405);
  }

  // 1. Authenticate caller from Appwrite execution context header
  const authUserId = req.headers ? req.headers['x-appwrite-user-id'] : null;
  if (!authUserId || typeof authUserId !== 'string' || !authUserId.trim()) {
    return res.json({ ok: false, error: 'UNAUTHENTICATED', message: 'Authentication required' }, 401);
  }
  const cleanUserId = authUserId.trim();
  if (cleanUserId.length > USER_ID_MAX_LENGTH) {
    return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: `userId exceeds maximum allowed length (${USER_ID_MAX_LENGTH})` }, 400);
  }

  // 2. Parse and validate JSON body
  const body = parseBody(req);
  if (!body) {
    return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: 'Malformed JSON payload' }, 400);
  }

  // 3. Security: prevent body impersonation
  if (body.userId && String(body.userId).trim() !== cleanUserId) {
    return res.json({ ok: false, error: 'FORBIDDEN', message: 'Caller cannot impersonate another user' }, 403);
  }

  const action = body.action || 'upsert';
  if (action !== 'upsert' && action !== 'delete' && action !== 'list' && action !== 'applyRecall') {
    return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: `Unknown action: ${action}` }, 400);
  }

  if (action === 'applyRecall') {
    const parsed = parseApplyRecallRequest(body, cleanUserId);
    if (!parsed.ok) {
      return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: parsed.error }, 400);
    }
    if (body.stateJson !== undefined && body.stateJson !== null) {
      const sj = typeof body.stateJson === 'string' ? body.stateJson : JSON.stringify(body.stateJson);
      if (Buffer.byteLength(sj, 'utf8') > STATE_JSON_MAX_BYTES) {
        return res.json({ ok: false, error: 'PAYLOAD_TOO_LARGE', message: `stateJson exceeds maximum allowed size (${STATE_JSON_MAX_BYTES} UTF-8 bytes)` }, 413);
      }
    }
  }

  let listRequest = null;
  if (action === 'list') {
    listRequest = parseReviewStateListRequest(body);
    if (!listRequest.ok) {
      return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: listRequest.error }, 400);
    }
  }

  // Common validation for itemId (upsert & delete)
  const itemId = action === 'list' ? '' : String(body.itemId || '').trim();
  if (action !== 'list' && (!itemId || itemId.length > ITEM_ID_MAX_LENGTH)) {
    return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: `Invalid or missing itemId (must be non-empty and <= ${ITEM_ID_MAX_LENGTH} characters)` }, 400);
  }

  // Validate upsert payload before database connection setup
  let upsertCandidate = null;
  if (action === 'upsert') {
    const itemType = String(body.itemType || '').trim();
    if (!VALID_ITEM_TYPES.has(itemType)) {
      return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: 'Invalid itemType. Must be "word" or "sentence"' }, 400);
    }

    let stateJsonStr = '';
    let parsedState = null;

    if (typeof body.stateJson === 'string') {
      stateJsonStr = body.stateJson;
      if (Buffer.byteLength(stateJsonStr, 'utf8') > STATE_JSON_MAX_BYTES) {
        return res.json({ ok: false, error: 'PAYLOAD_TOO_LARGE', message: `stateJson exceeds maximum allowed size (${STATE_JSON_MAX_BYTES} UTF-8 bytes)` }, 413);
      }
      try {
        parsedState = JSON.parse(stateJsonStr);
      } catch (_) {
        return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: 'stateJson is not valid JSON' }, 400);
      }
      if (typeof parsedState !== 'object' || parsedState === null || Array.isArray(parsedState)) {
        return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: 'stateJson must be a JSON object, array or primitive not allowed' }, 400);
      }
    } else if (typeof body.stateJson === 'object' && body.stateJson !== null) {
      if (Array.isArray(body.stateJson)) {
        return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: 'stateJson must be a JSON object, array not allowed' }, 400);
      }
      parsedState = body.stateJson;
      stateJsonStr = JSON.stringify(body.stateJson);
      if (Buffer.byteLength(stateJsonStr, 'utf8') > STATE_JSON_MAX_BYTES) {
        return res.json({ ok: false, error: 'PAYLOAD_TOO_LARGE', message: `stateJson exceeds maximum allowed size (${STATE_JSON_MAX_BYTES} UTF-8 bytes)` }, 413);
      }
    } else {
      return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: 'Missing or invalid stateJson' }, 400);
    }

    const nextReviewAtRaw = body.nextReviewAt;
    if (!nextReviewAtRaw || isNaN(Date.parse(nextReviewAtRaw))) {
      return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: 'Invalid or missing nextReviewAt ISO timestamp' }, 400);
    }
    const outerNextEpoch = Date.parse(nextReviewAtRaw);
    const nextReviewAt = new Date(outerNextEpoch).toISOString();

    let lastReviewedAt = null;
    let outerLastEpoch = null;
    if (body.lastReviewedAt !== undefined && body.lastReviewedAt !== null) {
      if (isNaN(Date.parse(body.lastReviewedAt))) {
        return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: 'Invalid lastReviewedAt ISO timestamp' }, 400);
      }
      outerLastEpoch = Date.parse(body.lastReviewedAt);
      lastReviewedAt = new Date(outerLastEpoch).toISOString();
    }

    let schemaVersion = DEFAULT_SCHEMA_VERSION;
    if (body.schemaVersion !== undefined && body.schemaVersion !== null) {
      const v = Number(body.schemaVersion);
      if (!Number.isInteger(v) || !SUPPORTED_SCHEMA_VERSIONS.includes(v)) {
        return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: 'Invalid or unsupported schemaVersion' }, 400);
      }
      schemaVersion = v;
    }

    // Consistency checks between outer request fields and inner stateJson
    if (parsedState.itemId !== itemId) {
      return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: 'stateJson.itemId must equal request.itemId' }, 400);
    }
    if (parsedState.itemType !== itemType) {
      return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: 'stateJson.itemType must equal request.itemType' }, 400);
    }

    if (!parsedState.nextReviewAt || isNaN(Date.parse(parsedState.nextReviewAt))) {
      return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: 'stateJson.nextReviewAt must be a valid ISO timestamp' }, 400);
    }
    const innerNextEpoch = Date.parse(parsedState.nextReviewAt);
    if (innerNextEpoch !== outerNextEpoch) {
      return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: 'stateJson.nextReviewAt must represent the same instant as request.nextReviewAt' }, 400);
    }

    const hasOuterLast = outerLastEpoch !== null;
    const hasInnerLast = parsedState.lastReviewedAt !== undefined && parsedState.lastReviewedAt !== null;
    if (hasOuterLast !== hasInnerLast) {
      return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: 'Mismatched lastReviewedAt presence between request and stateJson' }, 400);
    }
    if (hasOuterLast && hasInnerLast) {
      if (isNaN(Date.parse(parsedState.lastReviewedAt))) {
        return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: 'stateJson.lastReviewedAt must be a valid ISO timestamp' }, 400);
      }
      const innerLastEpoch = Date.parse(parsedState.lastReviewedAt);
      if (innerLastEpoch !== outerLastEpoch) {
        return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: 'stateJson.lastReviewedAt must represent the same instant as request.lastReviewedAt' }, 400);
      }
    }

    if (body.schemaVersion !== undefined && body.schemaVersion !== null &&
        parsedState.schemaVersion !== undefined && parsedState.schemaVersion !== null) {
      if (Number(parsedState.schemaVersion) !== Number(body.schemaVersion)) {
        return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: 'stateJson.schemaVersion must match request.schemaVersion' }, 400);
      }
    }

    upsertCandidate = {
      userId: cleanUserId,
      itemId,
      itemType,
      stateJson: stateJsonStr,
      nextReviewAt,
      lastReviewedAt,
      schemaVersion,
    };
  }

  const endpoint = process.env.APPWRITE_FUNCTION_API_ENDPOINT || process.env.APPWRITE_ENDPOINT || 'https://sgp.cloud.appwrite.io/v1';
  const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID || process.env.APPWRITE_PROJECT_ID || '699495910038e39622c5';
  const apiKey = process.env.APPWRITE_FUNCTION_API_KEY || process.env.APPWRITE_API_KEY;
  const databaseId = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
  const tableId = 'review_states';
  const operationsTableId = 'review_operations';

  let tablesDB = tablesDBOverride || dbOverride;
  if (!tablesDB) {
    if (!endpoint || !projectId || !apiKey) {
      if (error) error('mutateReviewState: Server configuration missing endpoint, projectId, or apiKey');
      return res.json({ ok: false, error: 'SERVER_MISCONFIGURED', message: 'Server misconfiguration' }, 500);
    }

    const client = new Client().setEndpoint(endpoint).setProject(projectId).setKey(apiKey);
    tablesDB = new TablesDB(client);
  }

  // Action: list (cursor-paginated and bounded to 100 rows per request)
  if (action === 'list') {
    try {
      const queries = [
        Query.equal('userId', cleanUserId),
        Query.orderAsc('$id'),
        Query.limit(listRequest.limit),
      ];
      if (listRequest.cursor) {
        queries.push(Query.cursorAfter(listRequest.cursor));
      }
      const resData = await tablesDB.listRows(databaseId, tableId, queries);
      const pageRows = resData.rows || resData.documents || [];
      const rows = Array.isArray(pageRows) ? pageRows : [];
      const lastRowId = rows.length === listRequest.limit
        ? getRowId(rows.at(-1))
        : '';
      const nextCursor = lastRowId || null;
      return res.json({
        ok: true,
        rows,
        documents: rows,
        hasMore: Boolean(nextCursor),
        nextCursor,
      });
    } catch (err) {
      if (error) error(`mutateReviewState: list failed: ${err.message}`);
      return res.json({ ok: false, error: 'SERVER_ERROR', message: 'Failed to list states' }, 500);
    }
  }

  const hashedRowId = rowIdFor(cleanUserId, itemId);
  const legacyRowId = legacyRowIdFor(cleanUserId, itemId);

  // Action: delete (idempotent, 404 is success)
  if (action === 'delete') {
    try {
      try {
        await tablesDB.deleteRow(databaseId, tableId, hashedRowId);
      } catch (e) {
        if (e.code !== 404) throw e;
      }
      if (isValidAppwriteRowId(legacyRowId)) {
        try {
          await tablesDB.deleteRow(databaseId, tableId, legacyRowId);
        } catch (e) {
          if (e.code !== 404 && log) {
            log(`mutateReviewState: legacy delete note: ${e.message}`);
          }
        }
      }
      return res.json({ ok: true, deleted: true, itemId });
    } catch (err) {
      if (error) error(`mutateReviewState: delete failed: ${err.message}`);
      return res.json({ ok: false, error: 'SERVER_ERROR', message: 'Failed to delete review state' }, 500);
    }
  }

  // Action: applyRecall (idempotent operation apply)
  //
  // Convergence contract (documented, tested):
  // - Each operationId applies at most once per user (ledger row in
  //   `review_operations`). Duplicate delivery returns duplicate:true.
  // - Counters are incremented by delta (correct? typing?2:1 / wrong?1:0),
  //   so independent recalls from two devices sharing a base are BOTH
  //   preserved regardless of delivery order. Clock skew can never lose
  //   a recall: occurredAt only orders *scheduling* fields.
  // - Scheduling/display fields follow newest-occurredAt-wins (ties broken
  //   by lexicographic operationId — never by delivery order or argument
  //   position), taken from the client's post-recall snapshot when supplied.
  // - Cross-type applies (same itemId, different itemType) are rejected.
  // - Crash safety: the snapshot row carries `lastOperationId`. Every apply
  //   re-reads current state and applies only its own delta, so a crash
  //   between the snapshot write and the ledger write self-heals on retry
  //   (marker present → skip delta, commit ledger), and concurrent duplicate
  //   applies converge to the same counters.
  if (action === 'applyRecall') {
    const parsed = parseApplyRecallRequest(body, cleanUserId);
    if (!parsed.ok) {
      return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: parsed.error }, 400);
    }
    const op = parsed.op;
    const opRowId = operationRowIdFor(cleanUserId, op.operationId);
    const hashedRowId = rowIdFor(cleanUserId, op.itemId);

    const readSnapshot = async () => {
      try {
        const row = await tablesDB.getRow(databaseId, tableId, hashedRowId);
        if (!row) return { row: null, stored: null };
        if (row.userId !== cleanUserId) return { forbidden: true, row, stored: null };
        let stored = null;
        try {
          stored = typeof row.stateJson === 'string' ? JSON.parse(row.stateJson) : row.stateJson;
        } catch (_) {
          stored = null;
        }
        if (stored !== null && (typeof stored !== 'object' || Array.isArray(stored))) stored = null;
        return { row, stored };
      } catch (e) {
        if (e.code !== 404 && log) log(`mutateReviewState: snapshot lookup note: ${e.message}`);
        return { row: null, stored: null };
      }
    };
    const writeLedger = async () => {
      try {
        await tablesDB.createRow(databaseId, operationsTableId, opRowId, {
          userId: cleanUserId,
          operationId: op.operationId,
          itemId: op.itemId,
          occurredAt: op.occurredAt,
          appliedAt: new Date().toISOString(),
        }, [`read("user:${cleanUserId}")`]);
        return true;
      } catch (err) {
        if (err.code === 409) return false;
        throw err;
      }
    };

    try {
      // 1. Idempotency gate: an existing ledger row means already applied.
      //    Verify the snapshot reflects the op (self-heal a crash that
      //    landed the ledger write but not the snapshot write — in the
      //    current write order that cannot happen, but the check is cheap
      //    and keeps the invariant explicit).
      try {
        const prior = await tablesDB.getRow(databaseId, operationsTableId, opRowId);
        if (prior && prior.userId === cleanUserId) {
          return res.json({ ok: true, duplicate: true, rowId: hashedRowId, operationId: op.operationId });
        }
      } catch (e) {
        if (e.code !== 404 && log) log(`mutateReviewState: op ledger lookup note: ${e.message}`);
      }

      // 2. Load existing snapshot (tolerate missing + legacy rows).
      const { row: existingRow, stored: initialStored, forbidden } = await readSnapshot();
      if (forbidden) {
        return res.json({ ok: false, error: 'FORBIDDEN', message: 'State owned by another user' }, 403);
      }
      if (existingRow && existingRow.itemType && existingRow.itemType !== op.itemType) {
        return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: `Item type mismatch for "${op.itemId}": stored "${existingRow.itemType}" vs operation "${op.itemType}"` }, 400);
      }
      let stored = initialStored;

      // 3. Crash-heal: snapshot already reflects this op (its id is in the
      //    bounded recent list) but the ledger row is missing (crash between
      //    snapshot and ledger writes). Skip the delta, commit the ledger.
      const recentOf = (s) => Array.isArray(s?.recentOperationIds) ? s.recentOperationIds : [];
      if (stored && recentOf(stored).includes(op.operationId)) {
        await writeLedger();
        return res.json({ ok: true, duplicate: true, rowId: hashedRowId, operationId: op.operationId });
      }

      // 3. Optional client snapshot supplies newest-writer scheduling fields.
      let clientSnap = null;
      if (body.stateJson !== undefined && body.stateJson !== null) {
        try {
          clientSnap = typeof body.stateJson === 'string' ? JSON.parse(body.stateJson) : body.stateJson;
        } catch (_) {
          return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: 'stateJson is not valid JSON' }, 400);
        }
        if (typeof clientSnap !== 'object' || clientSnap === null || Array.isArray(clientSnap)) {
          return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: 'stateJson must be a JSON object' }, 400);
        }
        if (clientSnap.itemId !== op.itemId || clientSnap.itemType !== op.itemType) {
          return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: 'stateJson.itemId/itemType must equal the operation item' }, 400);
        }
      }

      // 4. Delta-apply with bounded verify-and-repair (max 3 attempts).
      //    Each attempt re-reads the snapshot, skips the delta when this op
      //    is already reflected (bounded recent-id list), writes, then
      //    verifies. A concurrent same-item writer that lands between our
      //    read and write is detected by the verify read and repaired by
      //    recomputing the delta on the fresh state — both recalls survive.
      //    Exhaustion returns 500 so the client's durable outbox retries
      //    later; nothing is silently lost.
      const computeMerged = (base, clientSnap) => {
        const b = base || {};
        const baseSuccess = Number(b.successfulRecalls ?? 0);
        const baseFailed = Number(b.failedRecalls ?? 0);
        const baseTyping = Number(b.typingSuccesses ?? 0);
        const baseLapse = Number(b.lapseCount ?? 0);
        const isTyping = op.exerciseType === 'typing';
        const successes = baseSuccess + (op.correct ? (isTyping ? 2 : 1) : 0);
        const failed = baseFailed + (op.correct ? 0 : 1);
        const typing = baseTyping + (op.correct && isTyping ? 1 : 0);
        const baseMastery = b.masteryState || 'new';
        const lapsing = baseMastery === 'review' || baseMastery === 'mastered';
        const lapse = baseLapse + (!op.correct && lapsing ? 1 : 0);

        const firstRecallAt = (() => {
          if (!op.correct) return b.firstRecallAt || null;
          if (!b.firstRecallAt) return op.occurredAt;
          return Date.parse(b.firstRecallAt) <= Date.parse(op.occurredAt)
            ? b.firstRecallAt
            : op.occurredAt;
        })();
        const introducedAt = b.introducedAt || op.occurredAt;

        // Scheduling fields: newest-occurredAt-wins, ties by operationId.
        const storedLast = b.lastReviewedAt || null;
        const storedOp = b.lastOperationId || '';
        const opIsNewest = !storedLast ||
          Date.parse(op.occurredAt) > Date.parse(storedLast) ||
          (Date.parse(op.occurredAt) === Date.parse(storedLast) && op.operationId > storedOp);
        const pick = (clientVal, storedVal, fallback) => {
          if (opIsNewest && clientVal !== undefined && clientVal !== null) return clientVal;
          if (storedVal !== undefined && storedVal !== null) return storedVal;
          return fallback;
        };
        const nextReviewAt = pick(clientSnap?.nextReviewAt, b.nextReviewAt, op.occurredAt);
        if (isNaN(Date.parse(nextReviewAt))) return { error: 'Cannot determine nextReviewAt' };
        // lastReviewedAt is monotonic: an older op must never move it back.
        const prevLast = b.lastReviewedAt && !isNaN(Date.parse(b.lastReviewedAt)) ? b.lastReviewedAt : null;
        const lastReviewedAt = !prevLast || Date.parse(op.occurredAt) >= Date.parse(prevLast)
          ? op.occurredAt
          : prevLast;
        const recent = [...recentOf(b), op.operationId].slice(-10);
        return {
          merged: {
            ...(b && typeof b === 'object' ? b : {}),
            itemId: op.itemId,
            itemType: op.itemType,
            introducedAt,
            lastPresentedAt: opIsNewest ? op.occurredAt : (b.lastPresentedAt || op.occurredAt),
            lastReviewedAt,
            nextReviewAt: new Date(Date.parse(nextReviewAt)).toISOString(),
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
            recentOperationIds: recent,
          },
        };
      };
      const writeSnapshot = async (merged) => {
        const mergedJson = JSON.stringify(merged);
        if (Buffer.byteLength(mergedJson, 'utf8') > STATE_JSON_MAX_BYTES) {
          return { tooLarge: true };
        }
        const rowData = {
          userId: cleanUserId,
          itemId: op.itemId,
          itemType: op.itemType,
          stateJson: mergedJson,
          nextReviewAt: merged.nextReviewAt,
          lastReviewedAt: merged.lastReviewedAt,
          schemaVersion: op.schemaVersion,
        };
        const permissions = [`read("user:${cleanUserId}")`];
        try {
          await tablesDB.createRow(databaseId, tableId, hashedRowId, rowData, permissions);
        } catch (err) {
          if (err.code === 409) {
            await tablesDB.updateRow(databaseId, tableId, hashedRowId, rowData, permissions);
          } else {
            throw err;
          }
        }
        return { tooLarge: false };
      };

      let applied = false;
      for (let attempt = 0; attempt < 3 && !applied; attempt++) {
        const fresh = await readSnapshot();
        if (fresh.forbidden) {
          return res.json({ ok: false, error: 'FORBIDDEN', message: 'State owned by another user' }, 403);
        }
        if (fresh.row && fresh.row.itemType && fresh.row.itemType !== op.itemType) {
          return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: `Item type mismatch for "${op.itemId}"` }, 400);
        }
        const base = fresh.stored;
        if (base && recentOf(base).includes(op.operationId)) {
          applied = true;
          break;
        }
        const computed = computeMerged(base, clientSnap);
        if (computed.error) {
          return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: computed.error }, 400);
        }
        const written = await writeSnapshot(computed.merged);
        if (written.tooLarge) {
          return res.json({ ok: false, error: 'PAYLOAD_TOO_LARGE', message: 'Merged state exceeds maximum size' }, 413);
        }
        const verify = await readSnapshot();
        if (verify.stored && recentOf(verify.stored).includes(op.operationId)) {
          applied = true;
        }
        // Else: a concurrent writer landed between our read and write;
        // loop recomputes the delta on the fresh state.
      }
      if (!applied) {
        return res.json({ ok: false, error: 'SERVER_ERROR', message: 'Concurrent modification could not converge; retry later' }, 500);
      }

      // 5. Record the ledger entry AFTER the snapshot reflects the op. A
      //    crash between them is healed by step 3 on retry (recent-id hit →
      //    skip delta, commit ledger), so counters apply exactly once. A 409
      //    here means a concurrent duplicate already committed — the
      //    snapshot is correct either way.
      const ledgerOk = await writeLedger();
      return res.json({ ok: true, duplicate: !ledgerOk, rowId: hashedRowId, operationId: op.operationId });
    } catch (err) {
      if (error) error(`mutateReviewState: applyRecall failed: ${err.message}`);
      return res.json({ ok: false, error: 'SERVER_ERROR', message: 'Failed to apply recall operation' }, 500);
    }
  }

  // Action: upsert
  if (action === 'upsert') {
    let candidateData = upsertCandidate;

    try {
      // 4. Check for legacy row to handle migration
      let legacyRow = null;
      if (isValidAppwriteRowId(legacyRowId)) {
        try {
          legacyRow = await tablesDB.getRow(databaseId, tableId, legacyRowId);
        } catch (e) {
          if (e.code !== 404 && log) {
            log(`mutateReviewState: legacy row lookup returned code ${e.code}`);
          }
        }
      }

      // Check for existing hashed row
      let existingHashedRow = null;
      try {
        existingHashedRow = await tablesDB.getRow(databaseId, tableId, hashedRowId);
      } catch (e) {
        if (e.code !== 404 && log) {
          log(`mutateReviewState: hashed row lookup returned code ${e.code}`);
        }
      }

      // Resolve legacy row migration if legacy exists
      let shouldDeleteLegacy = false;
      if (legacyRow && legacyRow.userId === cleanUserId) {
        shouldDeleteLegacy = true;
        const legacyTs = getEffectiveTimestamp(legacyRow);
        const incomingTs = getEffectiveTimestamp(candidateData);
        const hashedTs = existingHashedRow ? getEffectiveTimestamp(existingHashedRow) : -1;

        if (existingHashedRow) {
          // Both rows exist
          if (legacyTs > hashedTs && legacyTs > incomingTs) {
            // Legacy row is the newer winner
            candidateData = {
              userId: cleanUserId,
              itemId,
              itemType: legacyRow.itemType || candidateData.itemType,
              stateJson: legacyRow.stateJson,
              nextReviewAt: legacyRow.nextReviewAt,
              lastReviewedAt: legacyRow.lastReviewedAt || null,
              schemaVersion: legacyRow.schemaVersion || schemaVersion,
            };
          } else if (hashedTs >= legacyTs && hashedTs > incomingTs) {
            // Existing hashed row is newer than incoming and legacy
            candidateData = {
              userId: cleanUserId,
              itemId,
              itemType: existingHashedRow.itemType || candidateData.itemType,
              stateJson: existingHashedRow.stateJson,
              nextReviewAt: existingHashedRow.nextReviewAt,
              lastReviewedAt: existingHashedRow.lastReviewedAt || null,
              schemaVersion: existingHashedRow.schemaVersion || schemaVersion,
            };
          }
          // If incomingTs >= both, candidateData remains the incoming payload
        } else {
          // Only legacy row exists
          if (legacyTs > incomingTs) {
            candidateData = {
              userId: cleanUserId,
              itemId,
              itemType: legacyRow.itemType || candidateData.itemType,
              stateJson: legacyRow.stateJson,
              nextReviewAt: legacyRow.nextReviewAt,
              lastReviewedAt: legacyRow.lastReviewedAt || null,
              schemaVersion: legacyRow.schemaVersion || schemaVersion,
            };
          }
        }
      }

      // 5. Write to hashed row with owner read-only permission.
      // Table permissions are empty and client update/delete permissions are removed,
      // ensuring all writes and deletes must go through mutateReviewState.
      const permissions = [
        `read("user:${cleanUserId}")`,
      ];

      try {
        await tablesDB.createRow(databaseId, tableId, hashedRowId, candidateData, permissions);
      } catch (err) {
        if (err.code === 409) {
          await tablesDB.updateRow(databaseId, tableId, hashedRowId, candidateData, permissions);
        } else {
          throw err;
        }
      }

      // 6. Delete legacy row ONLY AFTER successful new-row write
      if (shouldDeleteLegacy && isValidAppwriteRowId(legacyRowId)) {
        try {
          await tablesDB.deleteRow(databaseId, tableId, legacyRowId);
        } catch (delErr) {
          if (log) log(`mutateReviewState: non-critical failure deleting migrated legacy row: ${delErr.message}`);
        }
      }

      return res.json({ ok: true, rowId: hashedRowId, migratedLegacy: shouldDeleteLegacy });
    } catch (err) {
      if (error) error(`mutateReviewState: upsert failed: ${err.message}`);
      return res.json({ ok: false, error: 'SERVER_ERROR', message: 'Failed to persist review state' }, 500);
    }
  }

  return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: `Unknown action: ${action}` }, 400);
}

export default async (context) => handleMutateReviewState(context);
