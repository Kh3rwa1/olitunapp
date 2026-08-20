import { createHash } from 'node:crypto';
import { Query } from 'node-appwrite';

export const WINDOW_HOUR_MS = 60 * 60 * 1000;
export const WINDOW_MINUTE_MS = 60 * 1000;
const MAX_CAS_RETRIES = 12;

/**
 * Generates a valid Appwrite-compatible deterministic document ID (alphanumeric, max 36 chars)
 */
export function generateWindowDocId(prefix, identifier, windowIndex) {
  const hash = createHash('sha256')
    .update(`${prefix}:${identifier}:${windowIndex}`)
    .digest('hex')
    .slice(0, 28);
  return `${prefix}_${hash}`;
}

/**
 * Atomic/CAS-safe rate limit increment for a specific time window.
 *
 * @param {Object} params
 * @param {Object} params.databases - Appwrite Databases service instance
 * @param {string} params.dbId - Database ID
 * @param {string} params.collectionId - Collection ID
 * @param {string} params.identifier - Domain-separated HMAC rate limit identifier
 * @param {string} params.windowType - 'm' (minute) or 'h' (hour)
 * @param {number} params.windowMs - Duration of the window in ms
 * @param {number} params.limit - Maximum allowed requests in this window
 * @param {number} params.now - Current timestamp in ms
 * @returns {Promise<{ allowed: boolean, remaining: number, reason?: string, retryAfterSeconds?: number }>}
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
  const windowIndex = Math.floor(now / windowMs);
  const windowStart = windowIndex * windowMs;
  const windowEnd = windowStart + windowMs;
  const docId = generateWindowDocId(windowType, identifier, windowIndex);

  for (let attempt = 0; attempt < MAX_CAS_RETRIES; attempt++) {
    try {
      // Attempt 1: Race-safe document creation with initial count = 1
      await databases.createDocument(dbId, collectionId, docId, {
        clientIp: identifier,
        count: 1,
        windowStart: windowStart,
        expiresAt: windowEnd + WINDOW_HOUR_MS, // Retain for window duration + 1h buffer
        _revision: 1,
      });
      return { allowed: true, remaining: Math.max(0, limit - 1) };
    } catch (createErr) {
      const isConflict =
        createErr?.code === 409 ||
        createErr?.status === 409 ||
        (createErr?.message && /already exists|duplicate|409/i.test(createErr.message));

      if (!isConflict) {
        // Unknown database error -> fail closed
        return {
          allowed: false,
          reason: 'rate_limit_storage_error',
          error: createErr?.message || 'Database error during rate limit creation',
        };
      }

      // Document already exists for this window -> read and attempt CAS increment
      try {
        const doc = await databases.getDocument(dbId, collectionId, docId);
        const currentCount = typeof doc?.count === 'number' ? doc.count : 1;
        const currentRevision = typeof doc?._revision === 'number' ? doc._revision : 1;

        if (currentCount >= limit) {
          const retryAfterSeconds = Math.max(1, Math.ceil((windowEnd - now) / 1000));
          return {
            allowed: false,
            reason: windowType === 'm' ? 'burst_limit_exceeded' : 'hourly_limit_exceeded',
            retryAfterSeconds,
          };
        }

        // Bounded optimistic update with revision CAS
        const updated = await databases.updateDocument(dbId, collectionId, docId, {
          count: currentCount + 1,
          _revision: currentRevision + 1,
          _expectedRevision: currentRevision,
        });

        const newCount = updated?.count ?? currentCount + 1;
        return { allowed: true, remaining: Math.max(0, limit - newCount) };
      } catch (updateErr) {
        // Jittered backoff between retry attempts to alleviate high thundering herds
        await new Promise((r) => setTimeout(r, Math.random() * 5 + 2));
        if (attempt === MAX_CAS_RETRIES - 1) {
          return {
            allowed: false,
            reason: 'rate_limit_storage_error',
            error: updateErr?.message || 'Exceeded retry limit during concurrent rate limit update',
          };
        }
      }
    }
  }

  return {
    allowed: false,
    reason: 'rate_limit_storage_error',
    error: 'Max retries exhausted',
  };
}

/**
 * Concurrency-safe rate limit checker enforcing both burst and sustained limits.
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
    return { allowed: false, reason: 'rate_limit_storage_error', error: 'Missing rate limit identifier' };
  }

  const sustainedLimit = parseInt(
    isAuth
      ? (env.RATE_LIMIT_AUTH_PER_HOUR || '60')
      : (env.RATE_LIMIT_ANON_PER_HOUR || '20'),
    10
  );
  const burstLimit = parseInt(
    isAuth
      ? (env.RATE_LIMIT_AUTH_PER_MINUTE || '15')
      : (env.RATE_LIMIT_ANON_PER_MINUTE || '5'),
    10
  );

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
      return sustainedResult;
    }

    return {
      allowed: true,
      remaining: Math.min(burstResult.remaining, sustainedResult.remaining),
    };
  } catch (err) {
    // Fail-closed policy for high security
    return {
      allowed: false,
      reason: 'rate_limit_storage_error',
      error: err?.message || 'Unexpected rate limit check failure',
    };
  }
}

/**
 * Automated retention cleanup for expired rate limit records.
 */
export async function pruneExpiredRateLimits({
  databases,
  dbId = 'olitun_db',
  collectionId = 'rate_limits',
  now = Date.now(),
  batchSize = 50,
}) {
  try {
    const expiredDocs = await databases.listDocuments(dbId, collectionId, [
      Query.lessThan('expiresAt', now),
      Query.limit(batchSize),
    ]);

    let deletedCount = 0;
    for (const doc of expiredDocs.documents || []) {
      try {
        await databases.deleteDocument(dbId, collectionId, doc.$id);
        deletedCount++;
      } catch {
        // Individual delete failure ignored during background prune
      }
    }
    return { success: true, deletedCount };
  } catch (err) {
    return { success: false, error: err?.message || 'Prune failed' };
  }
}
