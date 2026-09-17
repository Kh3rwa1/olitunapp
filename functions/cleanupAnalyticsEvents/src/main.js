import { Client, Databases, Query, Storage } from 'node-appwrite';
import { pruneExpiredRateLimits } from './shared/rate_limiter.js';

export const DATABASE_ID =
  process.env.OLITUN_APPWRITE_DATABASE_ID ||
  process.env.APPWRITE_DATABASE_ID ||
  'olitun_db';
export const EVENTS_COLLECTION = 'learning_analytics_events';
export const TRANSLATION_CACHE_COLLECTION = 'translation_cache';
export const AI_STUDIO_INPUTS_BUCKET = 'ai_studio_inputs';
export const AI_STUDIO_JOBS_COLLECTION = 'ai_studio_jobs';
export const TTS_CACHE_COLLECTION = 'tts_cache';
export const AUDIO_BUCKET_ID = 'audio';
export const VOICE_CLAIMS_COLLECTION = 'voice_claims';

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
  maxDocs = 500,
  dryRun = false,
}) {
  const cutoffMs = now - retentionDays * 24 * 60 * 60 * 1000;
  let prunedCount = 0;

  try {
    while (prunedCount < maxDocs) {
      const result = await databases.listDocuments(dbId, collectionId, [
        Query.lessThan('createdAt', cutoffMs),
        Query.limit(Math.min(100, maxDocs - prunedCount)),
      ]);

      if (!result.documents || result.documents.length === 0) break;

      for (const doc of result.documents) {
        if (!dryRun) {
          try {
            await databases.deleteDocument(dbId, collectionId, doc.$id);
          } catch (_) {
            // Continue cleaning other documents
          }
        }
        prunedCount++;
      }

      if (result.documents.length < 100) break;
    }
  } catch (_) {
    // Non-fatal background maintenance error
  }

  return { prunedCount };
}

/**
 * Retention sweep for ai_studio_inputs (24-hour retention).
 * Prunes abandoned / completed input files uploaded by users.
 */
export async function pruneAiStudioInputs({
  storage,
  bucketId = AI_STUDIO_INPUTS_BUCKET,
  now = Date.now(),
  retentionHours = 24,
  maxFiles = 500,
  dryRun = false,
}) {
  const cutoffMs = now - retentionHours * 60 * 60 * 1000;
  let prunedCount = 0;

  try {
    let files = [];
    if (typeof storage.listFiles === 'function') {
      try {
        const res = await storage.listFiles(bucketId, [Query.limit(Math.min(100, maxFiles))]);
        files = res.files || [];
      } catch (_) {
        try {
          const res = await storage.listFiles({ bucketId, queries: [Query.limit(Math.min(100, maxFiles))] });
          files = res.files || [];
        } catch (_) {}
      }
    }

    for (const file of files) {
      if (prunedCount >= maxFiles) break;
      const createdAtMs = file.$createdAt ? new Date(file.$createdAt).getTime() : 0;
      if (createdAtMs > 0 && createdAtMs < cutoffMs) {
        if (!dryRun) {
          try {
            if (typeof storage.deleteFile === 'function') {
              try {
                await storage.deleteFile(bucketId, file.$id);
              } catch (_) {
                await storage.deleteFile({ bucketId, fileId: file.$id });
              }
            }
          } catch (_) {}
        }
        prunedCount++;
      }
    }
  } catch (_) {
    // Non-fatal background maintenance error
  }

  return { prunedCount };
}

/**
 * Retention sweep for ai_studio_jobs (30-day retention).
 * Prunes terminal / expired OCR, translation, and transcription job records.
 */
export async function pruneAiStudioJobs({
  databases,
  dbId = DATABASE_ID,
  collectionId = AI_STUDIO_JOBS_COLLECTION,
  now = Date.now(),
  retentionDays = 30,
  maxDocs = 500,
  dryRun = false,
}) {
  const cutoffMs = now - retentionDays * 24 * 60 * 60 * 1000;
  let prunedCount = 0;

  try {
    while (prunedCount < maxDocs) {
      const result = await databases.listDocuments(dbId, collectionId, [
        Query.lessThan('checkedAt', cutoffMs),
        Query.limit(Math.min(100, maxDocs - prunedCount)),
      ]);

      if (!result.documents || result.documents.length === 0) break;

      for (const doc of result.documents) {
        if (!dryRun) {
          try {
            await databases.deleteDocument(dbId, collectionId, doc.$id);
          } catch (_) {}
        }
        prunedCount++;
      }

      if (result.documents.length < 100) break;
    }
  } catch (_) {
    // Non-fatal background maintenance error
  }

  return { prunedCount };
}

/**
 * Retention sweep for tts_cache (90-day retention).
 * Prunes shared TTS cache entries AND deletes associated synthesized audio files in storage.
 */
export async function pruneTtsCache({
  databases,
  storage,
  dbId = DATABASE_ID,
  collectionId = TTS_CACHE_COLLECTION,
  bucketId = AUDIO_BUCKET_ID,
  now = Date.now(),
  retentionDays = 90,
  maxDocs = 500,
  dryRun = false,
}) {
  const cutoffIso = new Date(now - retentionDays * 24 * 60 * 60 * 1000).toISOString();
  let prunedCount = 0;

  try {
    while (prunedCount < maxDocs) {
      const result = await databases.listDocuments(dbId, collectionId, [
        Query.lessThan('createdAt', cutoffIso),
        Query.limit(Math.min(100, maxDocs - prunedCount)),
      ]);

      if (!result.documents || result.documents.length === 0) break;

      for (const doc of result.documents) {
        if (!dryRun) {
          if (storage && doc.storageFileId) {
            try {
              if (typeof storage.deleteFile === 'function') {
                try {
                  await storage.deleteFile(bucketId, doc.storageFileId);
                } catch (_) {
                  await storage.deleteFile({ bucketId, fileId: doc.storageFileId });
                }
              }
            } catch (_) {}
          }
          try {
            await databases.deleteDocument(dbId, collectionId, doc.$id);
          } catch (_) {}
        }
        prunedCount++;
      }

      if (result.documents.length < 100) break;
    }
  } catch (_) {
    // Non-fatal background maintenance error
  }

  return { prunedCount };
}

/**
 * Retention sweep for voice_claims (7-day retention).
 * Prunes idempotency and concurrency claim records.
 */
export async function pruneVoiceClaims({
  databases,
  dbId = DATABASE_ID,
  collectionId = VOICE_CLAIMS_COLLECTION,
  now = Date.now(),
  retentionDays = 7,
  maxDocs = 500,
  dryRun = false,
}) {
  const cutoffMs = now - retentionDays * 24 * 60 * 60 * 1000;
  let prunedCount = 0;

  try {
    while (prunedCount < maxDocs) {
      const result = await databases.listDocuments(dbId, collectionId, [
        Query.lessThan('checkedAt', cutoffMs),
        Query.limit(Math.min(100, maxDocs - prunedCount)),
      ]);

      if (!result.documents || result.documents.length === 0) break;

      for (const doc of result.documents) {
        if (!dryRun) {
          try {
            await databases.deleteDocument(dbId, collectionId, doc.$id);
          } catch (_) {}
        }
        prunedCount++;
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

export function createHandler({ getClient = appwriteClient } = {}) {
  return async ({ req, res, log = () => {}, error = () => {} }) => {
    try {
      const client = getClient();
      const databases = new Databases(client);
      const storage = new Storage(client);
      const cutoffDateKey = getCutoffDateKey();

      const rawPayload = typeof req?.body === 'string' ? req.body : JSON.stringify(req?.body || {});
      const dryRun = req?.body?.dryRun === true || rawPayload.includes('"dryRun":true') || rawPayload.includes('--dry-run');

      log(`Starting analytics & retention cleanup${dryRun ? ' [DRY RUN]' : ''}. Cutoff dateKey: ${cutoffDateKey} (older than 90 days).`);

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
        if (!dryRun) {
          const deletePromises = result.documents.map((doc) =>
            databases.deleteDocument(DATABASE_ID, EVENTS_COLLECTION, doc.$id)
          );
          await Promise.all(deletePromises);
        }
        deletedCount += result.documents.length;
        log(`Processed ${result.documents.length} events. Total processed so far: ${deletedCount}`);

        if (result.documents.length < 100) {
          break;
        }
      }

      // Retention maintenance for infrastructure collections that would
      // otherwise grow unbounded. Each sweep is isolated so one failure does not
      // block the others.
      let rateLimitsPrunedCount = 0;
      let translationCachePrunedCount = 0;
      let aiStudioInputsPrunedCount = 0;
      let aiStudioJobsPrunedCount = 0;
      let ttsCachePrunedCount = 0;
      let voiceClaimsPrunedCount = 0;

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
        const cacheResult = await pruneTranslationCache({ databases, dryRun });
        translationCachePrunedCount = cacheResult.prunedCount;
      } catch (pruneErr) {
        error('Translation cache pruning failed: ' + (pruneErr?.message || String(pruneErr)));
      }

      try {
        const inputsResult = await pruneAiStudioInputs({ storage, dryRun });
        aiStudioInputsPrunedCount = inputsResult.prunedCount;
      } catch (pruneErr) {
        error('AI Studio inputs pruning failed: ' + (pruneErr?.message || String(pruneErr)));
      }

      try {
        const jobsResult = await pruneAiStudioJobs({ databases, dryRun });
        aiStudioJobsPrunedCount = jobsResult.prunedCount;
      } catch (pruneErr) {
        error('AI Studio jobs pruning failed: ' + (pruneErr?.message || String(pruneErr)));
      }

      try {
        const ttsResult = await pruneTtsCache({ databases, storage, dryRun });
        ttsCachePrunedCount = ttsResult.prunedCount;
      } catch (pruneErr) {
        error('TTS cache pruning failed: ' + (pruneErr?.message || String(pruneErr)));
      }

      try {
        const voiceClaimsResult = await pruneVoiceClaims({ databases, dryRun });
        voiceClaimsPrunedCount = voiceClaimsResult.prunedCount;
      } catch (pruneErr) {
        error('Voice claims pruning failed: ' + (pruneErr?.message || String(pruneErr)));
      }

      log(`Retention cleanup completed. Deleted: ${deletedCount} events, ${rateLimitsPrunedCount} rate-limits, ${translationCachePrunedCount} translation cache, ${aiStudioInputsPrunedCount} AI inputs, ${aiStudioJobsPrunedCount} AI jobs, ${ttsCachePrunedCount} TTS cache, ${voiceClaimsPrunedCount} voice claims.`);
      return res.json({
        ok: true,
        dryRun,
        deletedCount,
        rateLimitsPrunedCount,
        translationCachePrunedCount,
        aiStudioInputsPrunedCount,
        aiStudioJobsPrunedCount,
        ttsCachePrunedCount,
        voiceClaimsPrunedCount,
        cutoffDateKey,
      });
    } catch (err) {
      const message = err?.message || String(err);
      error('Analytics retention cleanup failed: ' + message);
      return res.json(
        { ok: false, message: 'Analytics retention cleanup failed.' },
        500,
      );
    }
  };
}

export default (context) => createHandler()(context);

