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
