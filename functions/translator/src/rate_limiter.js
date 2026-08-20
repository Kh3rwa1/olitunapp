import { ID, Query } from 'node-appwrite';

const WINDOW_HOUR_MS = 60 * 60 * 1000;
const WINDOW_MINUTE_MS = 60 * 1000;

export async function checkRateLimit({
  databases,
  dbId = 'olitun_db',
  collectionId = 'rate_limits',
  identifier,
  isAuth = false,
  now = Date.now(),
  env = process.env,
}) {
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
    const existing = await databases.listDocuments(dbId, collectionId, [
      Query.equal('clientIp', identifier),
      Query.limit(1),
    ]);
    const row = existing.documents[0];

    if (!row) {
      await databases.createDocument(dbId, collectionId, ID.unique(), {
        clientIp: identifier,
        count: 1,
        windowStart: now,
        minuteCount: 1,
        minuteWindowStart: now,
      });
      return { allowed: true, remaining: sustainedLimit - 1 };
    }

    let hourCount = row.count || 0;
    let windowStart = row.windowStart || now;
    let minuteCount = row.minuteCount || 0;
    let minuteWindowStart = row.minuteWindowStart || now;

    // Reset 1-hour window if expired
    if (now - windowStart > WINDOW_HOUR_MS) {
      hourCount = 0;
      windowStart = now;
    }
    // Reset 1-minute burst window if expired
    if (now - minuteWindowStart > WINDOW_MINUTE_MS) {
      minuteCount = 0;
      minuteWindowStart = now;
    }

    // Check burst limit
    if (minuteCount >= burstLimit) {
      const retryAfter = Math.max(1, Math.ceil((minuteWindowStart + WINDOW_MINUTE_MS - now) / 1000));
      return { allowed: false, reason: 'burst_limit_exceeded', retryAfterSeconds: retryAfter };
    }
    // Check sustained hourly limit
    if (hourCount >= sustainedLimit) {
      const retryAfter = Math.max(1, Math.ceil((windowStart + WINDOW_HOUR_MS - now) / 1000));
      return { allowed: false, reason: 'hourly_limit_exceeded', retryAfterSeconds: retryAfter };
    }

    // Increment counters
    await databases.updateDocument(dbId, collectionId, row.$id, {
      count: hourCount + 1,
      windowStart: windowStart,
      minuteCount: minuteCount + 1,
      minuteWindowStart: minuteWindowStart,
    });

    return { allowed: true, remaining: sustainedLimit - (hourCount + 1) };
  } catch (err) {
    // Fail closed policy for security hardening
    return { allowed: false, reason: 'rate_limit_storage_error', error: err.message };
  }
}
