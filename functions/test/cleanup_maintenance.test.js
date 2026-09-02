import { test, describe } from 'node:test';
import assert from 'node:assert/strict';

import {
  getCutoffDateKey,
  pruneTranslationCache,
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
});
