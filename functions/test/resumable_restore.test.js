import test from 'node:test';
import assert from 'node:assert/strict';
import { runResumableRestore } from '../admin-maintenance/src/resumable_restore.js';

const clone = value => structuredClone(value);
const error = code => Object.assign(new Error(`injected ${code}`), { code });
class Database {
  docs = new Map(); transactions = new Map(); revision = 0; sequence = 0;
  contentOps = []; beforeCommit; loseResponse; failWrite;
  key(a) { return `${a.collectionId}/${a.documentId}`; }
  tx(a) {
    assert.ok(a.transactionId, 'every database request must be transaction-bound');
    const tx = this.transactions.get(a.transactionId);
    if (!tx) throw error(409);
    return tx;
  }
  async createTransaction() {
    const txId = `tx${++this.sequence}`;
    this.transactions.set(txId, { docs: clone(this.docs), revision: this.revision, ops: [] });
    return { $id: txId };
  }
  async getDocument(a) {
    const doc = this.tx(a).docs.get(this.key(a));
    if (!doc) throw error(404);
    return clone(doc);
  }
  async listDocuments(a) {
    const docs = [...this.tx(a).docs.entries()].filter(([key]) => key.startsWith(`${a.collectionId}/`));
    return { documents: docs.slice(0, a.queries[0]).map(([, doc]) => clone(doc)) };
  }
  async createDocument(a) {
    if (this.failWrite?.(a)) throw error(503);
    const tx = this.tx(a);
    if (tx.docs.has(this.key(a))) throw error(409);
    const doc = { ...clone(a.data), $id: a.documentId, $permissions: clone(a.permissions || []) };
    tx.docs.set(this.key(a), doc);
    if (a.collectionId !== 'admin_restore_jobs') tx.ops.push(['create', this.key(a)]);
    return clone(doc);
  }
  async updateDocument(a) {
    const tx = this.tx(a);
    if (!tx.docs.has(this.key(a))) throw error(404);
    const doc = { ...tx.docs.get(this.key(a)), ...clone(a.data) };
    tx.docs.set(this.key(a), doc);
    return clone(doc);
  }
  async deleteDocument(a) {
    const tx = this.tx(a);
    if (!tx.docs.delete(this.key(a))) throw error(404);
    tx.ops.push(['delete', this.key(a)]);
  }
  async updateTransaction(a) {
    const tx = this.transactions.get(a.transactionId);
    if (!tx) throw error(409);
    if (a.rollback) { this.transactions.delete(a.transactionId); return; }
    await this.beforeCommit?.(tx);
    if (tx.revision !== this.revision) throw error(409);
    this.docs = tx.docs;
    this.revision++;
    this.transactions.delete(a.transactionId);
    this.contentOps.push(...tx.ops);
    if (this.loseResponse?.(tx)) throw error(503);
  }
}
function fixture() {
  const db = new Database();
  db.docs.set('words/old', { $id: 'old', $permissions: [], title: 'Before' });
  db.docs.set('numbers/old', { $id: 'old', $permissions: [], value: 99 });
  const f = { db, backups: new Map(), backupCreates: 0, failBackupOnce: false };
  f.payload = {
    schemaVersion: 1, createdAt: '2026-09-06T00:00:00Z', databaseId: 'db',
    collections: {
      words: [{ $id: 'new1', $permissions: ['read("team:admins")'], title: 'One' },
        { $id: 'new2', $permissions: [], title: 'Two' }], numbers: [],
    }, counts: { words: 2, numbers: 0 },
  };
  f.options = {
    databases: db, storage: { getFileDownload: async () => Buffer.from(JSON.stringify(f.payload)) },
    fileId: 'source', restoreId: 'operation1', actorUserId: 'admin', databaseId: 'db', bucketId: 'backups',
    collectionIds: ['words', 'numbers'], pageQueries: limit => [limit],
    sanitizeDocument: doc => Object.fromEntries(Object.entries(doc).filter(([key]) => !key.startsWith('$'))),
    ensureSafetyBackup: async ({ fileId }) => {
      if (!f.backups.has(fileId)) { f.backups.set(fileId, clone(db.docs)); f.backupCreates++; }
      if (f.failBackupOnce) { f.failBackupOnce = false; throw error(503); }
      return { fileId, bucketId: 'backups', fileName: 'safety.json' };
    },
  };
  f.run = overrides => runResumableRestore({ ...f.options, ...overrides });
  f.state = () => JSON.parse(db.docs.get('admin_restore_jobs/active').payload);
  return f;
}
function assertRestored(f) {
  const content = [...f.db.docs.keys()].filter(key => !key.startsWith('admin_restore_jobs/')).sort();
  assert.deepEqual(content, ['words/new1', 'words/new2']);
  assert.deepEqual(f.db.docs.get('words/new1').$permissions, ['read("team:admins")']);
  assert.equal(f.db.docs.get('words/new1').title, 'One');
  assert.equal(f.backupCreates, 1);
}

test('bounded calls resume to completion with original safety backup', async () => {
  const f = fixture(); let result;
  for (let n = 0; n < 20; n++) { result = await f.run({ maxSteps: 1 }); if (result.complete) break; }
  assert.equal(result.complete, true);
  assert.deepEqual(result.deleted, { words: 1, numbers: 1 });
  assert.deepEqual(result.restored, { words: 2, numbers: 0 });
  assertRestored(f);
  const old = f.backups.values().next().value;
  assert.equal(old.get('words/old').title, 'Before');
});
for (const operation of ['delete', 'create']) {
  test(`resume after committed ${operation} response is lost`, async () => {
    const f = fixture(); let lost = false;
    f.db.loseResponse = tx => !lost && tx.ops.some(([type]) => type === operation) && (lost = true);
    await assert.rejects(f.run(), { code: 503 });
    const checkpoint = f.state();
    const result = await f.run();
    assert.equal(result.complete, true); assertRestored(f);
    assert.notEqual(checkpoint.phase, 'prepare');
    const writes = f.db.contentOps.filter(([type]) => type === operation).map(([, key]) => key);
    assert.equal(new Set(writes).size, writes.length, 'committed operations are not replayed');
  });
}
test('upload response loss reuses create-only safety identity', async () => {
  const f = fixture(); f.failBackupOnce = true;
  await assert.rejects(f.run(), { code: 503 });
  assert.equal(f.db.contentOps.length, 0);
  await f.run(); assertRestored(f);
});
test('failed write rolls back whole batch and checkpoint', async () => {
  const f = fixture();
  f.db.failWrite = a => a.collectionId === 'words' && a.documentId === 'new2';
  await assert.rejects(f.run(), { code: 503 });
  assert.equal(f.db.docs.has('words/new1'), false);
  assert.equal(f.state().restored.words, 0);
  f.db.failWrite = undefined;
  await f.run(); assertRestored(f);
});
test('complete retry does not delete or restore again', async () => {
  const f = fixture(); await f.run(); const before = f.db.contentOps.length;
  assert.equal((await f.run()).complete, true);
  assert.equal(f.db.contentOps.length, before); assertRestored(f);
});
test('another operation cannot displace an unfinished restore', async () => {
  const f = fixture(); await f.run({ maxSteps: 0 });
  await assert.rejects(f.run({ restoreId: 'other' }), { code: 409 });
  assert.equal(f.db.contentOps.length, 0);
});
test('changed backup cannot reuse a checkpoint', async () => {
  const f = fixture(); await f.run({ maxSteps: 1 });
  f.payload.collections.words[0].title = 'Tampered';
  await assert.rejects(f.run(), { code: 409 });
  assert.equal(f.db.contentOps.length, 0);
});
test('old operation cannot restart after a later restore', async () => {
  const f = fixture(); await f.run(); await f.run({ restoreId: 'operation2' });
  const before = f.db.contentOps.length;
  await assert.rejects(f.run(), { code: 409 });
  assert.equal(f.db.contentOps.length, before); assert.equal(f.backupCreates, 2);
});
test('invalid payload fails before any journal or content mutation', async () => {
  const f = fixture(); f.payload.counts.words = 1;
  await assert.rejects(f.run(), { status: 400 });
  assert.equal(f.db.revision, 0); assert.equal(f.backupCreates, 0);
});
test('missing transaction support fails closed', async () => {
  const f = fixture(); f.db.createTransaction = undefined;
  await assert.rejects(f.run(), { code: 503 });
  assert.equal(f.db.revision, 0); assert.equal(f.backupCreates, 0);
});
test('paused stale delete worker cannot overwrite a resumed restore', async () => {
  const f = fixture(); await f.run({ maxSteps: 1 });
  let release; const gate = new Promise(resolve => { release = resolve; });
  let entered; const ready = new Promise(resolve => { entered = resolve; });
  let held = false;
  f.db.beforeCommit = async tx => {
    if (!held && tx.ops.some(([type]) => type === 'delete')) { held = true; entered(); await gate; }
  };
  const stale = f.run(); const rejected = assert.rejects(stale, { code: 409 });
  await ready;
  await f.run();
  release(); await rejected;
  assertRestored(f);
});
for (const corrupt of ['active', 'history']) {
  test(`corrupted ${corrupt} checkpoint fails closed`, async () => {
    const f = fixture(); await f.run({ maxSteps: 1 });
    const key = [...f.db.docs.keys()].find(key => key.startsWith('admin_restore_jobs/') && (corrupt === 'active' ? key.endsWith('/active') : !key.endsWith('/active')));
    f.db.docs.get(key).payload = '{broken';
    const before = f.db.contentOps.length;
    await assert.rejects(f.run(), { code: 409 });
    assert.equal(f.db.contentOps.length, before);
  });
}
