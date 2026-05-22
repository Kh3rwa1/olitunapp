import { Client, Databases, Query } from 'node-appwrite';

export const DATABASE_ID =
  process.env.OLITUN_APPWRITE_DATABASE_ID ||
  process.env.APPWRITE_DATABASE_ID ||
  'olitun_db';
export const EVENTS_COLLECTION = 'learning_analytics_events';

export function getCutoffDateKey(now = new Date(), days = 90) {
  const cutoff = new Date(now);
  cutoff.setUTCDate(cutoff.getUTCDate() - days);
  return cutoff.toISOString().slice(0, 10);
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

    log(`Analytics retention cleanup completed. Deleted ${deletedCount} events.`);
    return res.json({
      ok: true,
      deletedCount,
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
