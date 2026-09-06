import test from 'node:test';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { readFileSync } from 'node:fs';

const require = createRequire(new URL('../admin-maintenance/package.json', import.meta.url));
const { Client, Databases } = require('node-appwrite');

test('installed restore SDK forwards transactionId on every document operation', async () => {
  const client = new Client().setEndpoint('https://example.invalid/v1').setProject('test');
  const requests = [];
  client.call = async (...args) => {
    requests.push(args);
    return { $id: 'tx1', documents: [] };
  };
  const db = new Databases(client);
  assert.equal(typeof db.createTransaction, 'function');
  assert.equal(typeof db.updateTransaction, 'function');
  const address = { databaseId: 'db', collectionId: 'content', documentId: 'doc', transactionId: 'tx1' };
  await db.getDocument(address);
  await db.createDocument({ ...address, data: { title: 'value' }, permissions: [] });
  await db.updateDocument({ ...address, data: { title: 'value' } });
  await db.deleteDocument(address);
  await db.listDocuments({ databaseId: 'db', collectionId: 'content', queries: [], transactionId: 'tx1' });
  assert.equal(requests.length, 5);
  for (const request of requests) {
    assert.ok(request.some(arg => arg && typeof arg === 'object' && arg.transactionId === 'tx1'),
      'SDK must send transactionId, not silently perform an unguarded request');
  }
});

test('production restore dispatch precedes ordinary backup creation', () => {
  const text = readFileSync(new URL('../admin-maintenance/src/main.js', import.meta.url), 'utf8');
  const handler = text.slice(text.indexOf('export default async'));
  assert.ok(handler.indexOf("body.action === 'restore_content'") < handler.indexOf('await createContentBackup('));
  assert.ok(text.includes('return runResumableRestore({'));
  assert.ok(!text.includes('return restoreValidatedContent({'));
  assert.ok(handler.includes('result.complete ? 200 : 202'));
});
