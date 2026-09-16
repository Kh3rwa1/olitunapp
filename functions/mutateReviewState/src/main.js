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
const DEFAULT_LIST_PAGE_SIZE = 100;
const MAX_LIST_PAGE_SIZE = 100;

export function rowIdFor(userId, itemId) {
  const input = `usr:${userId.length}:${userId}:item:${itemId.length}:${itemId}`;
  const digest = createHash('sha256').update(input).digest('hex');
  return `r_${digest.slice(0, 31)}`;
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
  if (action !== 'upsert' && action !== 'delete' && action !== 'list') {
    return res.json({ ok: false, error: 'INVALID_ARGUMENT', message: `Unknown action: ${action}` }, 400);
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
