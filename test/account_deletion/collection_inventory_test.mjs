import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import deleteAccountHandler from '../../functions/delete-account/src/main.js';
import { schema as aiStudioSchema } from '../../scripts/setup_ai_studio.mjs';
import { voiceSchema } from '../../scripts/setup_santali_voice.mjs';
import { REVIEW_COLUMNS_SPEC } from '../../functions/mutateReviewState/src/review_schema_contract.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const root = path.resolve(__dirname, '../..');

function extractUserDataCollections(filePath) {
  const code = fs.readFileSync(filePath, 'utf8');
  const match = code.match(/const USER_DATA_COLLECTIONS = \[([\s\S]*?)\];/);
  if (!match) throw new Error(`Could not find USER_DATA_COLLECTIONS in ${filePath}`);
  return match[1]
    .split(',')
    .map((s) => s.replace(/['"\s]/g, ''))
    .filter(Boolean);
}

describe('Account Deletion Complete Collection Inventory Suite', () => {
  const mainCollections = extractUserDataCollections(
    path.join(root, 'functions/delete-account/src/main.js'),
  );
  const sharedCollections = extractUserDataCollections(
    path.join(root, 'functions/_shared/delete_account_core.js'),
  );

  test('Parity: USER_DATA_COLLECTIONS matches between main.js and delete_account_core.js', () => {
    assert.deepEqual(
      [...mainCollections].sort(),
      [...sharedCollections].sort(),
      'USER_DATA_COLLECTIONS in delete-account/src/main.js and functions/_shared/delete_account_core.js must be identical',
    );
  });

  test('Coverage: newly audited collections with userId are included in USER_DATA_COLLECTIONS', () => {
    assert.ok(
      mainCollections.includes('ai_studio_jobs'),
      'ai_studio_jobs must be included in USER_DATA_COLLECTIONS',
    );
    assert.ok(
      mainCollections.includes('review_states'),
      'review_states must be included in USER_DATA_COLLECTIONS',
    );
    assert.ok(
      mainCollections.includes('voice_claims'),
      'voice_claims must be included in USER_DATA_COLLECTIONS',
    );
  });

  test('Audit: every collection in schema definitions with userId attribute is accounted for', () => {
    // Collect all collections with userId attribute
    const collectionsWithUserId = new Set();

    // 1. Check AI Studio schema
    for (const [col, spec] of Object.entries(aiStudioSchema)) {
      if (spec.strings && spec.strings.userId) {
        collectionsWithUserId.add(col);
      }
    }

    // 2. Check Voice schema
    for (const [col, spec] of Object.entries(voiceSchema)) {
      if (spec.strings && spec.strings.userId) {
        collectionsWithUserId.add(col);
      }
    }

    // 3. Check Review table spec
    if (REVIEW_COLUMNS_SPEC.some((c) => c.key === 'userId')) {
      collectionsWithUserId.add('review_states');
    }

    // 4. Check appwrite_setup.mjs collections
    const setupContent = fs.readFileSync(path.join(root, 'scripts/appwrite_setup.mjs'), 'utf8');
    const colRegex = /id:\s*'([a-z0-9_]+)',[\s\S]*?attributes:\s*\[([\s\S]*?)\]/g;
    let match;
    while ((match = colRegex.exec(setupContent)) !== null) {
      const colId = match[1];
      const attrs = match[2];
      if (attrs.includes("key: 'userId'")) {
        collectionsWithUserId.add(colId);
      }
    }

    // Explicit statutory/system collections that preserve records or track deletion lifecycle
    const EXEMPT_OR_SYSTEM_COLLECTIONS = new Set([
      'course_purchases',  // Financial/statutory audit records — anonymized, not purged
      'payment_claims',    // Idempotency records for payments — anonymized
      'payment_attempts',  // Payment attempt logs — anonymized
      'user_assets',       // Storage asset ownership registry — purged via file deletion
      'deletion_requests', // Deletion state machine itself
    ]);

    for (const col of collectionsWithUserId) {
      const isHandled = mainCollections.includes(col) || EXEMPT_OR_SYSTEM_COLLECTIONS.has(col);
      assert.ok(
        isHandled,
        `Collection '${col}' has a userId attribute but is NOT in USER_DATA_COLLECTIONS or EXEMPT_OR_SYSTEM_COLLECTIONS`,
      );
    }
  });

  test('Functional: deleting user purges ai_studio_jobs, review_states, voice_claims, and user_assets', async () => {
    const testUserId = 'user_to_delete_999';
    const docs = new Map();

    const db = {
      async listDocuments(dbId, col, queries) {
        const list = docs.get(col) || [];
        const filtered = list.filter((d) => d.userId === testUserId);
        return { documents: filtered, total: filtered.length };
      },
      async getDocument(dbId, col, id) {
        const list = docs.get(col) || [];
        const found = list.find((d) => d.$id === id);
        if (!found) {
          const err = new Error('Document not found');
          err.code = 404;
          throw err;
        }
        return { ...found };
      },
      async createDocument(dbId, col, id, data) {
        if (!docs.has(col)) docs.set(col, []);
        const doc = { $id: id, ...data };
        docs.get(col).push(doc);
        return { ...doc };
      },
      async updateDocument(dbId, col, id, data) {
        const list = docs.get(col) || [];
        const found = list.find((d) => d.$id === id);
        if (!found) {
          const err = new Error('Document not found');
          err.code = 404;
          throw err;
        }
        Object.assign(found, data);
        return { ...found };
      },
      async deleteDocument(dbId, col, id) {
        const list = docs.get(col) || [];
        const idx = list.findIndex((d) => d.$id === id);
        if (idx !== -1) list.splice(idx, 1);
        return {};
      },
    };

    const deletedFiles = [];
    const storage = {
      async deleteFile(bucketId, fileId) {
        deletedFiles.push(`${bucketId}/${fileId}`);
        return {};
      },
    };

    let userDeleted = false;
    const users = {
      async delete(id) {
        if (id === testUserId) userDeleted = true;
        return {};
      },
    };

    // Seed test documents
    docs.set('ai_studio_jobs', [
      { $id: 'job_1', userId: testUserId, action: 'translate', text: 'secret' },
    ]);
    docs.set('review_states', [
      { $id: 'rev_1', userId: testUserId, itemId: 'word_1', stateJson: '{}' },
    ]);
    docs.set('voice_claims', [
      { $id: 'claim_1', userId: testUserId, cacheKey: 'hash', status: 'completed' },
    ]);
    docs.set('user_assets', [
      { $id: 'asset_1', userId: testUserId, bucketId: 'audio', fileId: 'audio_file_1' },
    ]);
    docs.set('course_purchases', [
      { $id: 'purch_1', userId: testUserId, categoryId: 'courses', amount: 100 },
    ]);

    const req = {
      method: 'POST',
      headers: {
        'x-appwrite-user-id': testUserId,
      },
    };

    let responseCode = 200;
    let responseBody = null;
    const res = {
      json(body, code = 200) {
        responseCode = code;
        responseBody = body;
        return body;
      },
    };

    const origEnv = { ...process.env };
    process.env.APPWRITE_DATABASE_ID = 'test_db';
    process.env.DELETION_HMAC_SECRET = 'test-secret-at-least-32-chars-long-deletion';
    process.env.APPWRITE_FUNCTION_API_ENDPOINT = 'https://appwrite.example/v1';
    process.env.APPWRITE_FUNCTION_PROJECT_ID = 'olitun_test';
    process.env.APPWRITE_FUNCTION_API_KEY = 'test_api_key';

    try {
      await deleteAccountHandler({
        req,
        res,
        databases: db,
        storage,
        users,
        log: () => {},
        error: (e) => console.error(e),
      });

      if (responseCode !== 200) {
        console.error('Test failed with response:', responseBody);
      }
      assert.equal(responseCode, 200);
      assert.equal(responseBody.ok, true);

      // Verify all collections purged
      assert.equal(docs.get('ai_studio_jobs').length, 0, 'ai_studio_jobs must be purged');
      assert.equal(docs.get('review_states').length, 0, 'review_states must be purged');
      assert.equal(docs.get('voice_claims').length, 0, 'voice_claims must be purged');
      assert.equal(docs.get('user_assets').length, 0, 'user_assets must be purged');

      // Verify storage file deleted
      assert.deepEqual(deletedFiles, ['audio/audio_file_1']);

      // Verify purchase was anonymized
      const purch = docs.get('course_purchases')[0];
      assert.equal(purch.userId, 'anonymized_deleted_user');

      // Verify Auth user deleted
      assert.equal(userDeleted, true, 'Auth user must be deleted');
    } finally {
      process.env = origEnv;
    }
  });
});
