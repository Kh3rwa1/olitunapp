import assert from 'node:assert/strict';
import test from 'node:test';
import { restoreValidatedContent } from '../admin-maintenance/src/restore_backup.js';

const collectionIds = ['quizzes', 'sentences', 'words', 'numbers', 'letters', 'lessons', 'categories'];
function backup() {
  return {
    schemaVersion: 1,
    createdAt: '2026-09-06T00:00:00.000Z',
    databaseId: 'olitun_db',
    collections: Object.fromEntries(collectionIds.map(id => [id, [{
      $id: `${id}_1`, $permissions: ['read("team:admins")'], title: id,
    }]])),
    counts: Object.fromEntries(collectionIds.map(id => [id, 1])),
  };
}
function harness(raw, { failWrite = false, asArrayBuffer = false } = {}) {
  const calls = [];
  const run = () => restoreValidatedContent({
    databases: { async createDocument(db, collection, id, data, permissions) {
      calls.push({ operation: 'create', collection, id, data, permissions });
      if (failWrite) throw new Error('write unavailable');
    } },
    storage: { async getFileDownload() {
      const bytes = Buffer.from(typeof raw === 'string' ? raw : JSON.stringify(raw));
      return asArrayBuffer ? bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength) : bytes;
    } },
    fileId: 'backup', databaseId: 'olitun_db', bucketId: 'admin_backups', collectionIds,
    async deleteCollection(collection) { calls.push({ operation: 'delete', collection }); return 1; },
    sanitizeDocument(doc) { return Object.fromEntries(Object.entries(doc).filter(([key]) => !key.startsWith('$'))); },
  });
  return { calls, run };
}

const invalidCases = [
  ['invalid JSON', () => '{'],
  ['null', () => null],
  ['empty collections', () => ({ collections: {} })],
  ['unsupported version', b => ({ ...b, schemaVersion: 2 })],
  ['wrong database', b => ({ ...b, databaseId: 'another_database' })],
  ['invalid timestamp', b => ({ ...b, createdAt: 'invalid' })],
  ['missing final collection', b => { delete b.collections.categories; return b; }],
  ['malformed final collection', b => { b.collections.categories = {}; return b; }],
  ['incorrect count', b => { b.counts.categories = 10; return b; }],
  ['missing counts', b => { delete b.counts; return b; }],
  ['missing document ID', b => { delete b.collections.categories[0].$id; return b; }],
  ['invalid document ID', b => { b.collections.categories[0].$id = '../bad'; return b; }],
  ['duplicate ID', b => { b.collections.categories.push(b.collections.categories[0]); b.counts.categories++; return b; }],
  ['missing permissions', b => { delete b.collections.categories[0].$permissions; return b; }],
  ['invalid permissions', b => { b.collections.categories[0].$permissions = [null]; return b; }],
];
for (const [name, change] of invalidCases) {
  test(`runtime restore rejects ${name} before ANY mutation`, async () => {
    const { calls, run } = harness(change(backup()));
    await assert.rejects(run, error => error.status === 400);
    assert.deepEqual(calls, []);
  });
}
test('runtime restore preserves document data and permissions with ArrayBuffer transport', async () => {
  const { calls, run } = harness(backup(), { asArrayBuffer: true });
  const result = await run();
  assert.equal(calls.filter(c => c.operation === 'delete').length, 7);
  const creates = calls.filter(c => c.operation === 'create');
  assert.equal(creates.length, 7);
  assert.deepEqual(creates[0].data, { title: 'quizzes' });
  assert.deepEqual(creates[0].permissions, ['read("team:admins")']);
  assert.deepEqual(result.restored, Object.fromEntries(collectionIds.map(id => [id, 1])));
});
test('explicit empty collections remain valid; absent collections are not inferred empty', async () => {
  const b = backup();
  b.collections.categories = [];
  b.counts.categories = 0;
  const { run } = harness(b);
  assert.equal((await run()).restored.categories, 0);
});
test('write failure propagates instead of reporting successful restoration', async () => {
  const { run } = harness(backup(), { failWrite: true });
  await assert.rejects(run, /write unavailable/);
});
