import test from 'node:test';
import assert from 'node:assert/strict';
import { setup, schema } from '../../scripts/setup_ai_studio.mjs';

test('setup creates private resources and waits for compatible attributes', async () => {
  const collections = []; const attrs = new Map(); let bucket;
  await setup({ databaseId: 'test', storage: { createBucket: async p => { bucket = p; } }, db: {
    createCollection: async p => collections.push(p),
    createStringAttribute: async p => attrs.set(`${p.collectionId}:${p.key}`, { ...p, type: 'string', status: 'available' }),
    createIntegerAttribute: async p => attrs.set(`${p.collectionId}:${p.key}`, { ...p, type: 'integer', status: 'available' }),
    getAttribute: async p => attrs.get(`${p.collectionId}:${p.key}`),
  } });
  assert.equal(bucket.bucketId, 'ai_studio_inputs'); assert.equal(bucket.fileSecurity, true);
  assert.deepEqual(bucket.permissions, ['create("users")']); assert.equal(bucket.maximumFileSize, 10 * 1024 * 1024);
  assert.equal(collections.length, Object.keys(schema).length);
  assert.ok(collections.every(c => c.permissions.length === 0 && c.documentSecurity === false));
  assert.equal(attrs.get('ai_studio_quotas:used').min, 0);
});
test('setup refuses an existing non-private bucket rather than silently changing it', async () => {
  let collectionsCreated = 0;
  await assert.rejects(setup({ databaseId: 'test', storage: {
    createBucket: async () => { throw { code: 409 }; },
    getBucket: async () => ({ fileSecurity: false, maximumFileSize: 10485760, $permissions: ['read("any")'] }),
  }, db: { createCollection: async () => { collectionsCreated++; } } }));
  assert.equal(collectionsCreated, 0);
});
