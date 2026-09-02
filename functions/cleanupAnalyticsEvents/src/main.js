import { Client, Databases, Query } from 'node-appwrite';
import { pruneExpiredRateLimits } from './shared/rate_limiter.js';

export const DATABASE_ID =
  process.env.OLITUN_APPWRITE_DATABASE_ID ||
  process.env.APPWRITE_DATABASE_ID ||
  'olitun_db';
export const EVENTS_COLLECTION = 'learning_analytics_events';
export const TRANSLATION_CACHE_COLLECTION = 'translation_cache';

export function getCutoffDateKey(now = new Date(), days = 90) {
  const cutoff = new Date(now);
  cutoff.setUTCDate(cutoff.getUTCDate() - days);
  return cutoff.toISOString().slice(0, 10);
}

/**
 * Retention sweep for translation_cache (90-day retention, as documented in
 * PRIVACY.md). Entries carry a numeric `createdAt` epoch-ms field.
 */
export async function pruneTranslationCache({
  databases,
  dbId = DATABASE_ID,
  collectionId = TRANSLATION_CACHE_COLLECTION,
  now = Date.now(),
  retentionDays = 90,
}) {
  const cutoffMs = now - retentionDays * 24 * 60 * 60 * 1000;
  let prunedCount = 0;

  try {
    while (true) {
      const result = await databases.listDocuments(dbId, collectionId, [
        Query.lessThan('createdAt', cutoffMs),
        Query.limit(100),
      ]);

      if (result.documents.length === 0) break;

      for (const doc of result.documents) {
        try {
          await databases.deleteDocument(dbId, collectionId, doc.$id);
          prunedCount++;
        } catch (_) {
          // Continue cleaning other documents
        }
      }

      if (result.documents.length < 100) break;
    }
  } catch (_) {
    // Non-fatal background maintenance error
  }

  return { prunedCount };
}

function appwriteClient() {
  const endpoint =
    process.env.APPWRITE_FUNCTION_API_ENDPOINT ||
    process.env.OLITUN_APPWRITE_ENDPOINT;
  const projectId =
    process.env.APPWRITE_FUNCTION_PROJECT_ID ||
    process.env.OLITUN_APPWRITE_PROJECT_ID;
  const apiKey =
    process.env.OLITUN_APPWRITE_API_KEY ||
    process.env.APPWRITE_FUNCTION_API_KEY;

  if (!endpoint || !projectId || !apiKey) {
    throw new Error('Missing Appwrite endpoint, project ID, or API key.');
  }

  return new Client().setEndpoint(endpoint).setProject(projectId).setKey(apiKey);
}

export default async ({ req, res, log, error }) => {
  try {
    const databases = new Databases(appwriteClient());
    const cutoffDateKey = getCutoffDateKey();
    log(`Starting analytics cleanup. Cutoff dateKey: ${cutoffDateKey} (older than 90 days).`);

    let deletedCount = 0;
    while (true) {
      // Find events older than 90 days
      const result = await databases.listDocuments(DATABASE_ID, EVENTS_COLLECTION, [
        Query.lessThan('dateKey', cutoffDateKey),
        Query.limit(100),
      ]);

      if (result.documents.length === 0) {
        break;
      }

      log(`Found ${result.documents.length} events to delete.`);
      const deletePromises = result.documents.map((doc) =>
        databases.deleteDocument(DATABASE_ID, EVENTS_COLLECTION, doc.$id)
      );
      await Promise.all(deletePromises);
      deletedCount += result.documents.length;
      log(`Deleted ${result.documents.length} events. Total deleted so far: ${deletedCount}`);

      // Stop safety check to avoid infinite loop in edge cases
      if (result.documents.length < 100) {
        break;
      }
    }

    // Retention maintenance for infrastructure collections that would
    // otherwise grow unbounded (the rate limiter's window records and the
    // translation cache). Each sweep is isolated so one failure does not
    // block the others.
    let rateLimitsPrunedCount = 0;
    let translationCachePrunedCount = 0;
    try {
      const rateLimitsResult = await pruneExpiredRateLimits({
        databases,
        dbId: DATABASE_ID,
      });
      rateLimitsPrunedCount = rateLimitsResult.prunedCount;
    } catch (pruneErr) {
      error('Rate limits pruning failed: ' + (pruneErr?.message || String(pruneErr)));
    }
    try {
      const cacheResult = await pruneTranslationCache({ databases });
      translationCachePrunedCount = cacheResult.prunedCount;
    } catch (pruneErr) {
      error('Translation cache pruning failed: ' + (pruneErr?.message || String(pruneErr)));
    }

    log(`Analytics retention cleanup completed. Deleted ${deletedCount} events, ${rateLimitsPrunedCount} rate-limit records, ${translationCachePrunedCount} cache entries.`);
    return res.json({
      ok: true,
      deletedCount,
      rateLimitsPrunedCount,
      translationCachePrunedCount,
      cutoffDateKey,
    });
  } catch (err) {
    const message = err?.message || String(err);
    error('Analytics cleanup failed: ' + message);
    return res.json(
      { ok: false, message: 'Analytics cleanup failed.' },
      500,
    );
  }
};
