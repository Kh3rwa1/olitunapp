import { test, describe } from 'node:test';
import assert from 'node:assert/strict';

import {
  getCutoffDateKey,
  pruneTranslationCache,
  pruneAiStudioInputs,
  pruneAiStudioJobs,
  pruneTtsCache,
  pruneVoiceClaims,
  DATABASE_ID,
  TRANSLATION_CACHE_COLLECTION,
} from '../cleanupAnalyticsEvents/src/main.js';
import { pruneExpiredRateLimits } from '../_shared/rate_limiter.js';

function createFilteringDb({ docsByCollection }) {
  const deleted = [];
  return {
    deleted,
    async listDocuments(dbId, collectionId, queries) {
      void dbId;
      let items = docsByCollection.get(collectionId) || [];
      for (const q of queries) {
        const parsed = typeof q === 'string' ? JSON.parse(q) : q;
        if (parsed.method === 'lessThan') {
          const [threshold] = parsed.values;
          items = items.filter((d) => Number(d[parsed.attribute]) < threshold);
        } else if (parsed.method === 'limit') {
          // limit is applied implicitly by the query contract; return as-is
        }
      }
      return { documents: items, total: items.length };
    },
    async deleteDocument(dbId, collectionId, id) {
      void dbId;
      deleted.push(`${collectionId}/${id}`);
      const items = docsByCollection.get(collectionId) || [];
      docsByCollection.set(
        collectionId,
        items.filter((d) => d.$id !== id),
      );
      return {};
    },
  };
}

describe('daily retention maintenance', () => {
  test('getCutoffDateKey returns a UTC date key N days back', () => {
    const cutoff = getCutoffDateKey(new Date('2026-09-01T10:00:00Z'), 90);
    assert.equal(cutoff, '2026-06-03');
  });

  test('pruneTranslationCache deletes only entries older than the retention window', async () => {
    const now = Date.now();
    const stale = { $id: 'cache_old_1', createdAt: now - 91 * 24 * 60 * 60 * 1000 };
    const fresh = { $id: 'cache_new_1', createdAt: now - 1 * 24 * 60 * 60 * 1000 };
    const db = createFilteringDb({
      docsByCollection: new Map([[TRANSLATION_CACHE_COLLECTION, [stale, fresh]]]),
    });

    const result = await pruneTranslationCache({ databases: db, now, retentionDays: 90 });

    assert.equal(result.prunedCount, 1);
    assert.deepEqual(db.deleted, [`${TRANSLATION_CACHE_COLLECTION}/cache_old_1`]);
  });

  test('pruneTranslationCache survives upstream list failures without throwing', async () => {
    const failingDb = {
      async listDocuments() {
        throw new Error('storage unavailable');
      },
      async deleteDocument() {
        throw new Error('should not be called');
      },
    };
    const result = await pruneTranslationCache({ databases: failingDb });
    assert.equal(result.prunedCount, 0);
  });

  test('pruneExpiredRateLimits (imported from translator) removes expired window records', async () => {
    const now = 1_700_000_000_000;
    const expired = { $id: 'rl_expired', windowStart: now - 3 * 60 * 60 * 1000 };
    const active = { $id: 'rl_active', windowStart: now - 10 * 60 * 1000 };
    const db = createFilteringDb({
      docsByCollection: new Map([['rate_limits', [expired, active]]]),
    });

    const result = await pruneExpiredRateLimits({ databases: db, dbId: DATABASE_ID, now });

    assert.equal(result.prunedCount, 1);
    assert.deepEqual(db.deleted, ['rate_limits/rl_expired']);
  });

  test('pruneAiStudioInputs removes files older than 24 hours', async () => {
    const now = Date.now();
    const staleFile = {
      $id: 'stale_audio_file',
      $createdAt: new Date(now - 25 * 60 * 60 * 1000).toISOString(),
    };
    const freshFile = {
      $id: 'fresh_audio_file',
      $createdAt: new Date(now - 1 * 60 * 60 * 1000).toISOString(),
    };
    const deletedFiles = [];
    const mockStorage = {
      async listFiles() {
        return { files: [staleFile, freshFile] };
      },
      async deleteFile(bucketId, fileId) {
        deletedFiles.push(`${bucketId}/${fileId}`);
        return {};
      },
    };

    // Dry run does not delete
    const dryResult = await pruneAiStudioInputs({
      storage: mockStorage,
      now,
      retentionHours: 24,
      dryRun: true,
    });
    assert.equal(dryResult.prunedCount, 1);
    assert.equal(deletedFiles.length, 0);

    // Live run deletes stale file
    const liveResult = await pruneAiStudioInputs({
      storage: mockStorage,
      now,
      retentionHours: 24,
      dryRun: false,
    });
    assert.equal(liveResult.prunedCount, 1);
    assert.deepEqual(deletedFiles, ['ai_studio_inputs/stale_audio_file']);
  });

  test('pruneAiStudioJobs removes jobs older than 30 days', async () => {
    const now = Date.now();
    const staleJob = { $id: 'job_old', checkedAt: now - 31 * 24 * 60 * 60 * 1000 };
    const freshJob = { $id: 'job_new', checkedAt: now - 2 * 24 * 60 * 60 * 1000 };
    const db = createFilteringDb({
      docsByCollection: new Map([['ai_studio_jobs', [staleJob, freshJob]]]),
    });

    const result = await pruneAiStudioJobs({ databases: db, now, retentionDays: 30 });
    assert.equal(result.prunedCount, 1);
    assert.deepEqual(db.deleted, ['ai_studio_jobs/job_old']);
  });

  test('pruneTtsCache removes cache older than 90 days and deletes storage audio file', async () => {
    const now = Date.now();
    const staleIso = new Date(now - 92 * 24 * 60 * 60 * 1000).toISOString();
    const freshIso = new Date(now - 2 * 24 * 60 * 60 * 1000).toISOString();
    const staleDoc = { $id: 'tts_old', createdAt: staleIso, storageFileId: 'audio_old_file' };
    const freshDoc = { $id: 'tts_new', createdAt: freshIso, storageFileId: 'audio_new_file' };

    const db = {
      deleted: [],
      async listDocuments(dbId, colId, queries) {
        return { documents: [staleDoc] };
      },
      async deleteDocument(dbId, colId, docId) {
        this.deleted.push(`${colId}/${docId}`);
        return {};
      },
    };
    const deletedFiles = [];
    const mockStorage = {
      async deleteFile(bucketId, fileId) {
        deletedFiles.push(`${bucketId}/${fileId}`);
        return {};
      },
    };

    const result = await pruneTtsCache({
      databases: db,
      storage: mockStorage,
      now,
      retentionDays: 90,
      dryRun: false,
    });
    assert.equal(result.prunedCount, 1);
    assert.deepEqual(db.deleted, ['tts_cache/tts_old']);
    assert.deepEqual(deletedFiles, ['audio/audio_old_file']);
  });

  test('pruneVoiceClaims removes claims older than 7 days', async () => {
    const now = Date.now();
    const staleClaim = { $id: 'claim_old', checkedAt: now - 8 * 24 * 60 * 60 * 1000 };
    const freshClaim = { $id: 'claim_new', checkedAt: now - 1 * 24 * 60 * 60 * 1000 };
    const db = createFilteringDb({
      docsByCollection: new Map([['voice_claims', [staleClaim, freshClaim]]]),
    });

    const result = await pruneVoiceClaims({ databases: db, now, retentionDays: 7 });
    assert.equal(result.prunedCount, 1);
    assert.deepEqual(db.deleted, ['voice_claims/claim_old']);
  });
});

