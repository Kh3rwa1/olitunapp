import { createHash } from 'node:crypto';
import { Query } from 'node-appwrite';

/**
 * Vendored copy: Appwrite function runtimes package only the function's own
 * directory, so cross-function imports fail at runtime. Keep this file in
 * sync with the source module when it changes.
 */

export const WINDOW_HOUR_MS = 60 * 60 * 1000;
export const WINDOW_MINUTE_MS = 60 * 1000;

/**
 * Generates an Appwrite-compatible deterministic slot document ID (alphanumeric, max 36 chars).
 *
 * @param {string} prefix - Window prefix ('m' or 'h')
 * @param {string} identifier - Domain-separated HMAC rate limit identifier
 * @param {number} windowIndex - Integer window bucket index
 * @param {number} slot - 1-indexed slot number (1 .. limit)
 * @returns {string} Deterministic document ID
 */
export function generateSlotDocId(prefix, identifier, windowIndex, slot) {
  const hash = createHash('sha256')
    .update(`${prefix}:${identifier}:${windowIndex}:${slot}`)
    .digest('hex')
    .slice(0, 28);
  return `${prefix}_${hash}`;
}

/**
 * Enforces a rate limit for a specific time window using atomic slot-reservation.
 * Each allowed request reserves a unique slot document ID (1..limit).
 * Relies on Appwrite's database-level primary key uniqueness constraint to guarantee atomicity.
 *
 * @param {Object} params
 * @param {Object} params.databases - Appwrite Databases service instance
 * @param {string} params.dbId - Database ID
 * @param {string} params.collectionId - Collection ID
 * @param {string} params.identifier - Domain-separated HMAC rate limit identifier
 * @param {string} params.windowType - 'm' (minute) or 'h' (hour)
 * @param {number} params.windowMs - Duration of the window in ms
 * @param {number} params.limit - Maximum allowed requests in this window (positive integer)
 * @param {number} params.now - Current timestamp in ms
 * @returns {Promise<{ allowed: boolean, remaining: number, slotDocId?: string, reason?: string, retryAfterSeconds?: number, error?: string }>}
 */
export const MAX_ALLOWED_LIMIT = 500;

/**
 * Enforces a rate limit for a specific time window using atomic slot-reservation.
 * Each allowed request reserves a unique slot document ID (1..limit).
 * Relies on Appwrite's database-level primary key uniqueness constraint to guarantee atomicity.
 *
 * @param {Object} params
 * @param {Object} params.databases - Appwrite Databases service instance
 * @param {string} params.dbId - Database ID
 * @param {string} params.collectionId - Collection ID
 * @param {string} params.identifier - Domain-separated HMAC rate limit identifier
 * @param {string} params.windowType - 'm' (minute) or 'h' (hour)
 * @param {number} params.windowMs - Duration of the window in ms
 * @param {number} params.limit - Maximum allowed requests in this window (positive integer <= MAX_ALLOWED_LIMIT)
 * @param {number} params.now - Current timestamp in ms
 * @returns {Promise<{ allowed: boolean, remaining: number, slotDocId?: string, reason?: string, retryAfterSeconds?: number, error?: string }>}
 */
export async function enforceWindowRateLimit({
  databases,
  dbId,
  collectionId,
  identifier,
  windowType,
  windowMs,
  limit,
  now = Date.now(),
}) {
  if (!Number.isInteger(limit) || limit <= 0 || limit > MAX_ALLOWED_LIMIT) {
    return {
      allowed: false,
      reason: 'rate_limit_storage_error',
      error: `Invalid rate limit configuration: limit must be an integer between 1 and ${MAX_ALLOWED_LIMIT}`,
    };
  }

  const windowIndex = Math.floor(now / windowMs);
  const windowStart = windowIndex * windowMs;
  const windowEnd = windowStart + windowMs;

  for (let slot = 1; slot <= limit; slot++) {
    const slotDocId = generateSlotDocId(windowType, identifier, windowIndex, slot);
    try {
      await databases.createDocument(dbId, collectionId, slotDocId, {
        clientIp: identifier,
        count: slot,
        windowStart: windowStart,
      });

      // Slot claimed successfully
      return {
        allowed: true,
        remaining: limit - slot,
        slotDocId,
      };
    } catch (err) {
      // Document already exists indicates slot was occupied by a concurrent request
      const isDuplicateConflict =
        err?.type === 'document_already_exists' ||
        ((err?.code === 409 || err?.status === 409) &&
          (err?.type === 'document_already_exists' ||
            (err?.message && /already exists|duplicate|unique|document with the requested id/i.test(err.message)) ||
            !err?.type));

      if (isDuplicateConflict) {
        // Slot is already occupied by a concurrent request -> probe next slot
        continue;
      }

      // Non-duplicate error or storage engine failure -> fail closed immediately
      return {
        allowed: false,
        reason: 'rate_limit_storage_error',
        error: err?.message || 'Database error during rate limit slot reservation',
      };
    }
  }

  // All slots 1..limit are occupied
  const retryAfterSeconds = Math.max(1, Math.ceil((windowEnd - now) / 1000));
  return {
    allowed: false,
    reason: windowType === 'm' ? 'burst_limit_exceeded' : 'hourly_limit_exceeded',
    retryAfterSeconds,
  };
}

/**
 * Concurrency-safe rate limit checker enforcing both burst and sustained limits.
 *
 * @param {Object} params
 * @param {Object} params.databases - Appwrite Databases service instance
 * @param {string} [params.dbId='olitun_db'] - Database ID
 * @param {string} [params.collectionId='rate_limits'] - Collection ID
 * @param {string} params.identifier - Domain-separated HMAC rate limit identifier
 * @param {boolean} [params.isAuth=false] - Whether caller identity is cryptographically verified
 * @param {number} [params.now=Date.now()] - Current timestamp in ms
 * @param {Object} [params.env=process.env] - Environment variables
 * @returns {Promise<{ allowed: boolean, remaining?: number, reason?: string, retryAfterSeconds?: number, error?: string }>}
 */
export async function checkRateLimit({
  databases,
  dbId = 'olitun_db',
  collectionId = 'rate_limits',
  identifier,
  isAuth = false,
  now = Date.now(),
  env = process.env,
}) {
  if (!identifier || typeof identifier !== 'string' || identifier.trim().length === 0) {
    return {
      allowed: false,
      reason: 'rate_limit_storage_error',
      error: 'Missing rate limit identifier',
    };
  }

  const isProduction = env.NODE_ENV === 'production';

  const sustainedLimit = parseInt(
    isAuth
      ? (env.RATE_LIMIT_AUTH_PER_HOUR || (isProduction ? '' : '60'))
      : (env.RATE_LIMIT_ANON_PER_HOUR || (isProduction ? '' : '20')),
    10
  );
  const burstLimit = parseInt(
    isAuth
      ? (env.RATE_LIMIT_AUTH_PER_MINUTE || (isProduction ? '' : '15'))
      : (env.RATE_LIMIT_ANON_PER_MINUTE || (isProduction ? '' : '5')),
    10
  );

  if (isNaN(burstLimit) || burstLimit <= 0 || isNaN(sustainedLimit) || sustainedLimit <= 0) {
    return {
      allowed: false,
      reason: 'rate_limit_storage_error',
      error: 'Invalid or missing rate limit configuration values',
    };
  }

  try {
    // 1. Enforce burst limit (1-minute window)
    const burstResult = await enforceWindowRateLimit({
      databases,
      dbId,
      collectionId,
      identifier,
      windowType: 'm',
      windowMs: WINDOW_MINUTE_MS,
      limit: burstLimit,
      now,
    });

    if (!burstResult.allowed) {
      return burstResult;
    }

    // 2. Enforce sustained limit (1-hour window)
    const sustainedResult = await enforceWindowRateLimit({
      databases,
      dbId,
      collectionId,
      identifier,
      windowType: 'h',
      windowMs: WINDOW_HOUR_MS,
      limit: sustainedLimit,
      now,
    });

    if (!sustainedResult.allowed) {
      // Partial accounting rollback: release the minute slot so hourly rejection doesn't consume burst quota
      if (burstResult.slotDocId) {
        try {
          await databases.deleteDocument(dbId, collectionId, burstResult.slotDocId);
        } catch (_) {
          // Non-fatal rollback attempt
        }
      }
      return sustainedResult;
    }

    return {
      allowed: true,
      remaining: Math.min(burstResult.remaining, sustainedResult.remaining),
    };
  } catch (err) {
    return {
      allowed: false,
      reason: 'rate_limit_storage_error',
      error: err?.message || 'Unexpected rate limit check failure',
    };
  }
}

/**
 * Retention cleanup for expired rate limit records.
 *
 * @param {Object} params
 * @param {Object} params.databases - Appwrite Databases service instance
 * @param {string} [params.dbId='olitun_db'] - Database ID
 * @param {string} [params.collectionId='rate_limits'] - Collection ID
 * @param {number} [params.now=Date.now()] - Current timestamp in ms
 * @param {number} [params.retentionBufferMs=2 * WINDOW_HOUR_MS] - Retention buffer
 * @returns {Promise<{ prunedCount: number }>}
 */
export async function pruneExpiredRateLimits({
  databases,
  dbId = 'olitun_db',
  collectionId = 'rate_limits',
  now = Date.now(),
  retentionBufferMs = 2 * WINDOW_HOUR_MS,
}) {
  const expiryThreshold = now - retentionBufferMs;
  let prunedCount = 0;

  try {
    const expiredDocs = await databases.listDocuments(dbId, collectionId, [
      Query.lessThan('windowStart', expiryThreshold),
      Query.limit(100),
    ]);

    for (const doc of expiredDocs.documents) {
      try {
        await databases.deleteDocument(dbId, collectionId, doc.$id);
        prunedCount++;
      } catch (_) {
        // Continue cleaning other documents
      }
    }
  } catch (err) {
    // Non-fatal background maintenance error
  }

  return { prunedCount };
}
