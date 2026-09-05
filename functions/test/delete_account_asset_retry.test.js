import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import deleteAccount, { generatePseudonymousId } from '../delete-account/src/main.js';

const fail = (code) => Object.assign(new Error('Injected dependency failure'), { code });

// Enforce the production ID constraint and Query.limit instead of accepting
// arbitrary IDs or returning every record in one page.
class StrictDb {
  tables = new Map();
  assetPageSizes = [];
  failRegistryDelete = false;

  table(name) {
    if (!this.tables.has(name)) this.tables.set(name, new Map());
    return this.tables.get(name);
  }

  validateId(id) {
    if (!/^[A-Za-z0-9][A-Za-z0-9._-]{0,35}$/.test(id)) throw fail(400);
  }

  async getDocument(_db, collection, id) {
    this.validateId(id);
    const doc = this.table(collection).get(id);
    if (!doc) throw fail(404);
    return { ...doc };
  }

  async createDocument(_db, collection, id, data) {
    this.validateId(id);
    if (this.table(collection).has(id)) throw fail(409);
    const doc = { $id: id, ...data };
    this.table(collection).set(id, doc);
    return { ...doc };
  }

  async updateDocument(db, collection, id, data) {
    const previous = await this.getDocument(db, collection, id);
    const doc = { ...previous, ...data };
    this.table(collection).set(id, doc);
    return { ...doc };
  }

  async deleteDocument(db, collection, id) {
    if (collection === 'user_assets' && this.failRegistryDelete) throw fail(503);
    await this.getDocument(db, collection, id);
    this.table(collection).delete(id);
  }

  async listDocuments(_db, collection, queries = []) {
    let documents = [...this.table(collection).values()];
    let limit = 25;
    for (const encoded of queries) {
      const query = typeof encoded === 'string' ? JSON.parse(encoded) : encoded;
      if (query.method === 'equal') {
        documents = documents.filter(doc => query.values.includes(doc[query.attribute]));
      } else if (query.method === 'limit') {
        limit = query.values[0];
      } else {
        throw new Error(`Unsupported test query: ${query.method}`);
      }
    }
    const total = documents.length;
    documents = documents.slice(0, limit).map(doc => ({ ...doc }));
    if (collection === 'user_assets') this.assetPageSizes.push(documents.length);
    return { documents, total };
  }
}

function fixture(count = 1) {
  const db = new StrictDb();
  const files = new Set();
  const userId = 'disposable_staging_user';
  for (let i = 0; i < count; i++) {
    db.table('user_assets').set(`asset_${i}`, {
      $id: `asset_${i}`, userId, bucketId: 'avatars', fileId: `file_${i}`,
    });
    files.add(`file_${i}`);
  }
  let storageFailure = null;
  let storageCalls = 0;
  let authDeletes = 0;
  const storage = {
    async deleteFile(_bucket, id) {
      storageCalls++;
      if (storageFailure) throw fail(storageFailure);
      if (!files.delete(id)) throw fail(404);
    },
  };
  const users = { async delete() { authDeletes++; } };
  return {
    db, files, userId,
    set storageFailure(code) { storageFailure = code; },
    get storageCalls() { return storageCalls; },
    get authDeletes() { return authDeletes; },
    async invoke() {
      let response;
      await deleteAccount({
        req: { method: 'POST', headers: { 'x-appwrite-user-id': userId } },
        res: { json(body, status = 200) { response = { body, status }; } },
        databases: db, storage, users, log() {}, error() {},
      });
      return response;
    },
    get request() { return [...db.table('deletion_requests').values()][0]; },
  };
}

beforeEach(() => {
  process.env.APPWRITE_FUNCTION_API_ENDPOINT = 'https://localhost/v1';
  process.env.APPWRITE_FUNCTION_PROJECT_ID = 'test_project';
  process.env.APPWRITE_FUNCTION_API_KEY = 'test_key';
  process.env.APPWRITE_DATABASE_ID = 'test_database';
  process.env.DELETION_HMAC_SECRET = 'test_only_deletion_secret';
});

test('request ID is valid, deterministic, and preserves the pseudonymous digest', async () => {
  const f = fixture(0);
  assert.equal((await f.invoke()).status, 200);
  const id = f.request.$id;
  assert.equal(id, `del_${generatePseudonymousId(f.userId, process.env.DELETION_HMAC_SECRET)}`);
  assert.equal(id.length, 36);
  assert.equal((await f.invoke()).status, 200);
  assert.equal(f.db.table('deletion_requests').size, 1);
  assert.equal(f.authDeletes, 1);
});

for (const code of [401, 403, 429, 500]) {
  test(`storage ${code} preserves file/registry/Auth until a successful retry`, async () => {
    const f = fixture();
    f.storageFailure = code;
    assert.equal((await f.invoke()).status, 500);
    assert.equal(f.files.has('file_0'), true);
    assert.equal(f.db.table('user_assets').has('asset_0'), true);
    assert.equal(f.authDeletes, 0);
    assert.equal(f.storageCalls, 1, 'must not spin on the same failed page');
    assert.equal(f.request.status, 'cleanup_failed');
    assert.equal(f.request.lastError, 'STORAGE_DELETE_FAILED');
    const requestId = f.request.$id;
    f.storageFailure = null;
    assert.equal((await f.invoke()).status, 200);
    assert.equal(f.files.size, 0);
    assert.equal(f.db.table('user_assets').size, 0);
    assert.equal(f.request.$id, requestId);
    assert.equal(f.request.retryCount, 2);
    assert.equal(f.request.status, 'completed');
    assert.equal(f.authDeletes, 1);
  });
}

test('already-missing file 404 permits registry cleanup', async () => {
  const f = fixture();
  f.files.clear();
  assert.equal((await f.invoke()).status, 200);
  assert.equal(f.db.table('user_assets').size, 0);
  assert.equal(f.authDeletes, 1);
});

test('registry failure keeps Auth and retries safely after the file is gone', async () => {
  const f = fixture();
  f.db.failRegistryDelete = true;
  assert.equal((await f.invoke()).status, 500);
  assert.equal(f.files.size, 0);
  assert.equal(f.db.table('user_assets').size, 1);
  assert.equal(f.authDeletes, 0);
  assert.equal(f.storageCalls, 1);
  f.db.failRegistryDelete = false;
  assert.equal((await f.invoke()).status, 200);
  assert.equal(f.db.table('user_assets').size, 0);
  assert.equal(f.authDeletes, 1);
});

test('more than 100 assets require multiple limited page-one fetches', async () => {
  const f = fixture(151);
  assert.equal((await f.invoke()).status, 200);
  assert.deepEqual(f.db.assetPageSizes, [100, 51, 0, 0]);
  assert.equal(f.files.size, 0);
  assert.equal(f.authDeletes, 1);
});
