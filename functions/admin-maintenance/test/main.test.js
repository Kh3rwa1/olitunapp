import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  backupFileName,
  buildBackupPayload,
  createContentBackup,
  parseBody,
  requireConfig,
  userIsAdmin,
  validateRequest,
  sanitizeDocument,
  restoreContent,
} from '../src/main.js';

describe('admin-maintenance request validation', () => {
  it('parses JSON request bodies', () => {
    assert.deepEqual(parseBody('{"action":"backup_content"}'), {
      action: 'backup_content',
    });
  });

  it('rejects unsupported actions', () => {
    assert.deepEqual(
      validateRequest({
        method: 'POST',
        userId: 'user-1',
        body: { action: 'delete_everything' },
      }),
      {
        status: 400,
        message: 'Unsupported admin maintenance action.',
      },
    );
  });

  it('requires the destructive confirmation phrase for wipes', () => {
    assert.deepEqual(
      validateRequest({
        method: 'POST',
        userId: 'user-1',
        body: { action: 'wipe_content', confirmation: 'wipe all' },
      }),
      {
        status: 400,
        message: 'Invalid confirmation phrase.',
      },
    );
  });

  it('does not require a destructive phrase for backup-only requests', () => {
    assert.equal(
      validateRequest({
        method: 'POST',
        userId: 'user-1',
        body: { action: 'backup_content' },
      }),
      null,
    );
  });

  it('requires a fileId for restore_content', () => {
    assert.deepEqual(
      validateRequest({
        method: 'POST',
        userId: 'user-1',
        body: { action: 'restore_content' },
      }),
      {
        status: 400,
        message: 'Missing backup file ID.',
      },
    );
  });

  it('passes validation when restore_content has fileId', () => {
    assert.equal(
      validateRequest({
        method: 'POST',
        userId: 'user-1',
        body: { action: 'restore_content', fileId: 'backup-123' },
      }),
      null,
    );
  });
});

describe('admin-maintenance configuration', () => {
  it('requires endpoint, project id, and API key', () => {
    assert.throws(() => requireConfig({}), /Missing Appwrite/);
  });

  it('accepts Appwrite function runtime variables', () => {
    assert.deepEqual(
      requireConfig({
        APPWRITE_FUNCTION_API_ENDPOINT: 'https://example.com/v1',
        APPWRITE_FUNCTION_PROJECT_ID: 'project',
        APPWRITE_FUNCTION_API_KEY: 'key',
      }),
      {
        endpoint: 'https://example.com/v1',
        projectId: 'project',
        apiKey: 'key',
      },
    );
  });
});

describe('content backups', () => {
  it('builds a stable JSON backup payload for all content collections', async () => {
    const databases = {
      async listDocuments(_databaseId, collectionId) {
        return {
          documents:
            collectionId === 'lessons'
              ? [{ $id: 'lesson-1', titleLatin: 'Intro' }]
              : [],
        };
      },
    };

    const backup = await buildBackupPayload(
      databases,
      'admin-user',
      '2026-05-21T08:00:00.000Z',
    );

    assert.equal(backup.schemaVersion, 1);
    assert.equal(backup.actorUserId, 'admin-user');
    assert.equal(backup.counts.lessons, 1);
    assert.deepEqual(backup.collections.lessons[0], {
      $id: 'lesson-1',
      titleLatin: 'Intro',
    });
  });

  it('uploads backup snapshots to the admin backup bucket', async () => {
    const databases = {
      async listDocuments() {
        return { documents: [] };
      },
    };
    const storage = {
      async createFile(bucketId, _fileId, file) {
        assert.equal(bucketId, 'admin_backups');
        assert.match(file.filename, /^olitun-content-backup-/);
        return { $id: 'backup-file-1' };
      },
    };

    const result = await createContentBackup({
      databases,
      storage,
      actorUserId: 'admin-user',
      createdAt: '2026-05-21T08:00:00.000Z',
    });

    assert.equal(result.bucketId, 'admin_backups');
    assert.equal(result.fileId, 'backup-file-1');
  });

  it('uses filesystem-safe backup file names', () => {
    assert.equal(
      backupFileName('2026-05-21T08:00:00.000Z'),
      'olitun-content-backup-2026-05-21T08-00-00-000Z.json',
    );
  });
});

describe('admin membership checks', () => {
  it('treats lookup failures as non-admin instead of server errors', async () => {
    const users = {
      async listMemberships() {
        throw new Error('User not found');
      },
    };

    assert.equal(await userIsAdmin(users, 'missing-user'), false);
  });
});

describe('sanitizeDocument', () => {
  it('strips all properties starting with $', () => {
    const input = {
      $id: '123',
      $collectionId: 'abc',
      name: 'Test',
      description: 'Hello',
      $createdAt: '2026-05-24',
    };
    assert.deepEqual(sanitizeDocument(input), {
      name: 'Test',
      description: 'Hello',
    });
  });

  it('handles empty or non-object inputs gracefully', () => {
    assert.deepEqual(sanitizeDocument(null), {});
    assert.deepEqual(sanitizeDocument('not-an-object'), {});
  });
});

describe('restoreContent', () => {
  it('downloads the backup JSON, clears old content, and creates new documents', async () => {
    const backupData = {
      schemaVersion: 1,
      collections: {
        lessons: [
          {
            $id: 'lesson-1',
            $collectionId: 'lessons',
            $databaseId: 'olitun_db',
            titleLatin: 'Intro to Letters',
            $permissions: ['read("users")', 'write("admins")'],
          },
        ],
      },
    };

    const storage = {
      async getFileDownload(bucketId, fileId) {
        assert.equal(bucketId, 'admin_backups');
        assert.equal(fileId, 'backup-123');
        return Buffer.from(JSON.stringify(backupData), 'utf-8');
      },
    };

    const deletedDocs = [];
    const createdDocs = [];

    const databases = {
      async listDocuments(databaseId, collectionId, queries) {
        // Mocking listDocuments for deletion loop.
        // Return 1 document initially, then empty list to break the deletion loop
        if (deletedDocs.some((d) => d.collectionId === collectionId)) {
          return { documents: [] };
        }
        return {
          documents: [
            {
              $id: `${collectionId}-old-id`,
            },
          ],
        };
      },
      async deleteDocument(databaseId, collectionId, documentId) {
        deletedDocs.push({ collectionId, documentId });
        return {};
      },
      async createDocument(databaseId, collectionId, documentId, data, permissions) {
        createdDocs.push({ collectionId, documentId, data, permissions });
        return { $id: documentId };
      },
    };

    const result = await restoreContent({
      databases,
      storage,
      fileId: 'backup-123',
    });

    // Verify restore count output
    assert.equal(result.restored.lessons, 1);
    assert.equal(result.restored.quizzes, 0); // No quizzes in mock backup

    // Verify document deletion was called on all content collections
    // CONTENT_COLLECTIONS: quizzes, sentences, words, numbers, letters, lessons, categories
    assert.equal(deletedDocs.length, 7);
    assert.ok(deletedDocs.some((d) => d.collectionId === 'lessons' && d.documentId === 'lessons-old-id'));
    assert.ok(deletedDocs.some((d) => d.collectionId === 'quizzes' && d.documentId === 'quizzes-old-id'));

    // Verify document creation was called with sanitized properties and original permissions
    assert.equal(createdDocs.length, 1);
    assert.deepEqual(createdDocs[0], {
      collectionId: 'lessons',
      documentId: 'lesson-1',
      data: {
        titleLatin: 'Intro to Letters',
      },
      permissions: ['read("users")', 'write("admins")'],
    });
  });

  it('throws an error if backup data has invalid structure', async () => {
    const storage = {
      async getFileDownload() {
        return Buffer.from(JSON.stringify({}), 'utf-8'); // Missing collections
      },
    };
    const databases = {};

    await assert.rejects(
      restoreContent({
        databases,
        storage,
        fileId: 'backup-invalid',
      }),
      /Invalid backup file structure/,
    );
  });
});
