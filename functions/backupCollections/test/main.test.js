import test from 'node:test';
import assert from 'node:assert/strict';

import {
  backupFileName,
} from '../src/main.js';

test('backupFileName formats date stamp correctly', () => {
  const createdAt = '2026-05-22T12:00:00.123Z';
  const expected = 'olitun-content-backup-2026-05-22T12-00-00-123Z.json';
  assert.equal(backupFileName(createdAt), expected);
});
