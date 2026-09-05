import { describe, test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import handler, { deletionRequestId } from '../delete-account/src/main.js';

class Db {
  constructor(userId) {
    this.userId = userId;
    this.deleted = [];
    this.docs = new Map([
      ['user_assets', new Map([['asset_1', { $id: 'asset_1', userId, bucketId: 'bucket', fileId: 'file' }]])],
    ]);
  }
  async getDocument(_db, collection, id) {
    const doc = this.docs.get(collection)?.get(id);
    if (!doc) { const e = new Error('missing'); e.code = 404; throw e; }
    return { ...doc };
  }
  async createDocument(_db, collection, id, data) {
    assert.ok(id.length <= 36, `Appwrite ID exceeds 36 characters: ${id}`);
    if (!this.docs.has(collection)) this.docs.set(collection, new Map());
    const doc = { $id: id, ...data };
    this.docs.get(collection).set(id, doc);
    return { ...doc };
  }
  async updateDocument(_db, collection, id, data) {
    const doc = { ...(this.docs.get(collection)?.get(id) ?? { $id: id }), ...data };
    if (!this.docs.has(collection)) this.docs.set(collection, new Map());
    this.docs.get(collection).set(id, doc);
    return { ...doc };
  }
  async deleteDocument(_db, collection, id) {
    this.deleted.push(`${collection}:${id}`);
    this.docs.get(collection)?.delete(id);
  }
  async listDocuments(_db, collection, queries = []) {
    let values = [...(this.docs.get(collection)?.values() ?? [])];
    let limit;
    for (const query of queries) {
      try {
        const parsed = JSON.parse(query);
        if (parsed.method === 'equal') {
          const expected = Array.isArray(parsed.values) ? parsed.values.flat() : [parsed.value];
          values = values.filter((doc) => expected.includes(doc[parsed.attribute]));
        }
        if (parsed.method === 'limit') limit = Number(parsed.values?.[0] ?? parsed.value);
      } catch (_) {}
    }
    if (Number.isFinite(limit)) values = values.slice(0, limit);
    return { documents: values.map((doc) => ({ ...doc })), total: values.length };
  }
}

class Users {
  constructor(userId) { this.present = new Set([userId]); }
  async delete(id) { this.present.delete(id); }
}

function response() {
  return { statusCode: 200, body: null, json(body, status = 200) { this.statusCode = status; this.body = body; return body; } };
}

async function run(storage) {
  const userId = 'user_storage_regression';
  const db = new Db(userId);
  const users = new Users(userId);
  const res = response();
  await handler({
    req: { method: 'POST', headers: { 'x-appwrite-user-id': userId } },
    res,
    databases: db,
    users,
    storage,
    log: () => {},
    error: () => {},
  });
  return { userId, db, users, res };
}

describe('delete-account production regressions', () => {
  beforeEach(() => {
    process.env.APPWRITE_FUNCTION_API_ENDPOINT = 'https://localhost/v1';
    process.env.APPWRITE_FUNCTION_PROJECT_ID = 'project';
    process.env.APPWRITE_FUNCTION_API_KEY = 'key';
    process.env.APPWRITE_DATABASE_ID = 'database';
    process.env.DELETION_HMAC_SECRET = '0123456789abcdef0123456789abcdef';
  });

  test('stable deletion request ID satisfies Appwrite 36-character maximum', () => {
    const a = deletionRequestId('user_1', process.env.DELETION_HMAC_SECRET);
    const b = deletionRequestId('user_1', process.env.DELETION_HMAC_SECRET);
    assert.equal(a, b);
    assert.match(a, /^del_[a-f0-9]{32}$/);
    assert.equal(a.length, 36);
  });

  test('storage failure retries and success removes registry before Auth deletion', async () => {
    let attempts = 0;
    const result = await run({ async deleteFile() { attempts++; if (attempts < 3) { const e = new Error('temporary'); e.code = 503; throw e; } } });
    assert.equal(attempts, 3);
    assert.equal(result.res.statusCode, 200);
    assert.equal(result.db.docs.get('user_assets').has('asset_1'), false);
    assert.equal(result.users.present.has(result.userId), false);
  });

  test('non-404 storage failure preserves registry and fails closed', async () => {
    const result = await run({ async deleteFile() { const e = new Error('unavailable'); e.code = 503; throw e; } });
    assert.equal(result.res.statusCode, 500);
    assert.equal(result.db.docs.get('user_assets').has('asset_1'), true);
    assert.equal(result.users.present.has(result.userId), true);
  });

  test('404 storage response removes stale registry and completes', async () => {
    const result = await run({ async deleteFile() { const e = new Error('gone'); e.code = 404; throw e; } });
    assert.equal(result.res.statusCode, 200);
    assert.equal(result.db.docs.get('user_assets').has('asset_1'), false);
    assert.equal(result.users.present.has(result.userId), false);
  });
});
