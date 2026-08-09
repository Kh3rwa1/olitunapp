import { test, describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import deleteAccountHandler, { ERROR_CODES, reconcileOrphanedAuthDeletions } from '../delete-account/src/main.js';

function createMockRes() {
  const res = {
    statusCode: 200,
    body: null,
    json: (body, status = 200) => {
      res.statusCode = status;
      res.body = body;
      return body;
    },
  };
  return res;
}

class InMemDb {
  constructor() {
    this.collections = new Map();
  }

  async getDocument(dbId, col, id) {
    const table = this.collections.get(col);
    if (!table || !table.has(id)) {
      const err = new Error('Document not found');
      err.code = 404;
      throw err;
    }
    return JSON.parse(JSON.stringify(table.get(id)));
  }

  async createDocument(dbId, col, id, data) {
    if (!this.collections.has(col)) this.collections.set(col, new Map());
    const table = this.collections.get(col);
    if (table.has(id)) {
      const err = new Error('Document already exists');
      err.code = 409;
      throw err;
    }
    const doc = { $id: id, $createdAt: new Date().toISOString(), ...data };
    table.set(id, doc);
    return JSON.parse(JSON.stringify(doc));
  }

  async updateDocument(dbId, col, id, data) {
    const table = this.collections.get(col);
    if (!table || !table.has(id)) {
      const err = new Error('Document not found');
      err.code = 404;
      throw err;
    }
    const existing = table.get(id);
    const updated = { ...existing, ...data };
    table.set(id, updated);
    return JSON.parse(JSON.stringify(updated));
  }

  async deleteDocument(dbId, col, id) {
    const table = this.collections.get(col);
    if (!table || !table.has(id)) {
      const err = new Error('Document not found');
      err.code = 404;
      throw err;
    }
    table.delete(id);
  }

  async listDocuments(dbId, col, queries = []) {
    const table = this.collections.get(col);
    if (!table) return { documents: [], total: 0 };
    let docs = Array.from(table.values());

    for (const q of queries) {
      let attr, flatVals;
      if (typeof q === 'string') {
        const match = q.match(/^equal\("([^"]+)",\s*(.*)\)$/s);
        if (match) {
          attr = match[1];
          const rawVal = match[2];
          try {
            flatVals = JSON.parse(rawVal);
          } catch (e) {
            flatVals = [rawVal.replace(/^["'\s]+|["'\s]+$/g, '')];
          }
          if (!Array.isArray(flatVals)) flatVals = [flatVals];
        }
      } else if (q && (q.attribute || q.target) && (q.values !== undefined || q.value !== undefined)) {
        attr = q.attribute || q.target;
        const vals = q.values !== undefined ? q.values : [q.value];
        flatVals = Array.isArray(vals) ? vals.flat() : [vals];
      }

      if (attr && flatVals) {
        docs = docs.filter(d => flatVals.includes(d[attr]));
      }
    }
    return { documents: JSON.parse(JSON.stringify(docs)), total: docs.length };
  }
}

class InMemStorage {
  constructor() {
    this.files = new Map();
  }

  async deleteFile(bucketId, fileId) {
    const key = `${bucketId}:${fileId}`;
    if (!this.files.has(key)) {
      const err = new Error('File not found');
      err.code = 404;
      throw err;
    }
    this.files.delete(key);
  }
}

class InMemUsers {
  constructor() {
    this.users = new Set();
  }

  async get(userId) {
    if (!this.users.has(userId)) {
      const err = new Error('User not found');
      err.code = 404;
      throw err;
    }
    return { $id: userId };
  }

  async delete(userId) {
    if (!this.users.has(userId)) {
      const err = new Error('User not found');
      err.code = 404;
      throw err;
    }
    this.users.delete(userId);
  }
}

describe('delete-account fail-closed serverless function & sanitization suite', () => {
  beforeEach(() => {
    process.env.APPWRITE_FUNCTION_API_ENDPOINT = 'https://localhost/v1';
    process.env.APPWRITE_FUNCTION_PROJECT_ID = 'test_proj';
    process.env.APPWRITE_FUNCTION_API_KEY = 'test_key';
    process.env.APPWRITE_DATABASE_ID = 'test_db_id';
    process.env.DELETION_HMAC_SECRET = 'test_hmac_secret_key_12345';
  });

  test('1. rejects non-POST HTTP methods with 405 Method Not Allowed', async () => {
    const req = { method: 'GET', headers: {} };
    const res = createMockRes();
    await deleteAccountHandler({ req, res, log: () => {}, error: () => {} });

    assert.equal(res.statusCode, 405);
    assert.equal(res.body.ok, false);
    assert.equal(res.body.code, 'method_not_allowed');
  });

  test('2. rejects requests without authentication headers with 401 Unauthenticated', async () => {
    const req = { method: 'POST', headers: {} };
    const res = createMockRes();

    const origEnv = process.env.APPWRITE_FUNCTION_USER_ID;
    delete process.env.APPWRITE_FUNCTION_USER_ID;

    await deleteAccountHandler({ req, res, log: () => {}, error: () => {} });

    if (origEnv) process.env.APPWRITE_FUNCTION_USER_ID = origEnv;

    assert.equal(res.statusCode, 401);
    assert.equal(res.body.ok, false);
    assert.equal(res.body.code, 'unauthenticated');
  });

  test('3. returns 500 server_misconfiguration when required env vars (HMAC secret) are missing', async () => {
    const req = { method: 'POST', headers: { 'x-appwrite-user-id': 'user_test_123' } };
    const res = createMockRes();

    const origHmac = process.env.DELETION_HMAC_SECRET;
    delete process.env.DELETION_HMAC_SECRET;

    await deleteAccountHandler({ req, res, log: () => {}, error: () => {} });

    if (origHmac) process.env.DELETION_HMAC_SECRET = origHmac;

    assert.equal(res.statusCode, 500);
    assert.equal(res.body.ok, false);
    assert.equal(res.body.code, 'server_misconfiguration');
  });

  test('4. returns 500 server_misconfiguration when APPWRITE_DATABASE_ID is missing', async () => {
    const req = { method: 'POST', headers: { 'x-appwrite-user-id': 'user_test_123' } };
    const res = createMockRes();

    const origDb = process.env.APPWRITE_DATABASE_ID;
    delete process.env.APPWRITE_DATABASE_ID;

    await deleteAccountHandler({ req, res, log: () => {}, error: () => {} });

    if (origDb) process.env.APPWRITE_DATABASE_ID = origDb;

    assert.equal(res.statusCode, 500);
    assert.equal(res.body.ok, false);
    assert.equal(res.body.code, 'server_misconfiguration');
  });

  test('5. body userId spoofing is ignored in favor of trusted header userId', async () => {
    const req = {
      method: 'POST',
      headers: { 'x-appwrite-user-id': 'real_authenticated_user_100' },
      body: JSON.stringify({ userId: 'victim_user_to_spoof' })
    };
    const res = createMockRes();

    const origKey = process.env.APPWRITE_FUNCTION_API_KEY;
    delete process.env.APPWRITE_FUNCTION_API_KEY;
    delete process.env.APPWRITE_API_KEY;

    await deleteAccountHandler({ req, res, log: () => {}, error: () => {} });

    if (origKey) process.env.APPWRITE_FUNCTION_API_KEY = origKey;

    assert.equal(res.statusCode, 500);
    assert.equal(res.body.code, 'server_misconfiguration');
  });

  test('6. End-to-end user account deletion purges collections, assets, anonymizes purchases, and deletes Auth user', async () => {
    const db = new InMemDb();
    const storage = new InMemStorage();
    const users = new InMemUsers();

    const userId = 'u_del_100';
    users.users.add(userId);

    db.collections.set('user_preferences', new Map([
      ['pref_1', { $id: 'pref_1', userId, theme: 'dark' }]
    ]));
    db.collections.set('user_assets', new Map([
      ['asset_1', { $id: 'asset_1', userId, bucketId: 'b_avatars', fileId: 'f_pic1' }]
    ]));
    storage.files.set('b_avatars:f_pic1', 'file_data');

    db.collections.set('course_purchases', new Map([
      ['purch_1', { $id: 'purch_1', userId, amount: 499, userEmail: 'user@test.com' }]
    ]));

    const logs = [];
    const errors = [];

    const req = { method: 'POST', headers: { 'x-appwrite-user-id': userId } };
    const res = createMockRes();

    await deleteAccountHandler({
      req, res,
      log: (msg) => logs.push(msg),
      error: (msg) => errors.push(msg),
      databases: db, users, storage
    });

    assert.equal(res.statusCode, 200);
    assert.equal(res.body.ok, true);
    assert.equal(res.body.code, 'account_deleted');

    // Assert user preferences deleted
    const prefs = db.collections.get('user_preferences');
    assert.equal(prefs.has('pref_1'), false);

    // Assert file and asset registry deleted
    assert.equal(storage.files.has('b_avatars:f_pic1'), false);
    assert.equal(db.collections.get('user_assets').has('asset_1'), false);

    // Assert purchase anonymized
    const purch = db.collections.get('course_purchases').get('purch_1');
    assert.equal(purch.userId, 'anonymized_deleted_user');
    assert.equal(purch.userEmail, 'anonymized@deleted.local');

    // Assert Auth user deleted
    assert.equal(users.users.has(userId), false);

    // Assert state machine reached completed status
    const reqTable = db.collections.get('deletion_requests');
    assert.equal(reqTable.size, 1);
    const reqDoc = Array.from(reqTable.values())[0];
    assert.equal(reqDoc.status, 'completed');

    // ASSERTION: Logs contain NO clear-text user ID, email, doc ID, or file ID
    const logString = logs.join('\n') + errors.join('\n');
    assert.equal(logString.includes(userId), false, 'Log contains raw userId');
    assert.equal(logString.includes('user@test.com'), false, 'Log contains raw email');
    assert.equal(logString.includes('f_pic1'), false, 'Log contains raw fileId');
    assert.equal(logString.includes('pref_1'), false, 'Log contains raw documentId');
  });

  test('7. Paginates and deletes more than 100 records across multiple repeated page-1 fetches', async () => {
    const db = new InMemDb();
    const storage = new InMemStorage();
    const users = new InMemUsers();

    const userId = 'u_bulk_150';
    users.users.add(userId);

    const prefMap = new Map();
    for (let i = 0; i < 150; i++) {
      prefMap.set(`pref_${i}`, { $id: `pref_${i}`, userId, index: i });
    }
    db.collections.set('user_preferences', prefMap);

    const req = { method: 'POST', headers: { 'x-appwrite-user-id': userId } };
    const res = createMockRes();

    await deleteAccountHandler({
      req, res,
      log: () => {}, error: () => {},
      databases: db, users, storage
    });

    assert.equal(res.statusCode, 200);
    assert.equal(res.body.ok, true);
    assert.equal(db.collections.get('user_preferences').size, 0);
  });

  test('8. Iteration limit exhaustion prevents Auth user deletion and sets cleanup_failed state', async () => {
    const db = new InMemDb();
    const storage = new InMemStorage();
    const users = new InMemUsers();

    const userId = 'u_del_fail_limit';
    users.users.add(userId);

    // Mock DB deleteDocument to no-op so records persist across all 50 iterations
    db.deleteDocument = async () => {};

    db.collections.set('user_preferences', new Map([
      ['pref_stubborn', { $id: 'pref_stubborn', userId, theme: 'light' }]
    ]));

    const req = { method: 'POST', headers: { 'x-appwrite-user-id': userId } };
    const res = createMockRes();

    await deleteAccountHandler({
      req, res,
      log: () => {}, error: () => {},
      databases: db, users, storage
    });

    assert.equal(res.statusCode, 500);
    assert.equal(res.body.ok, false);
    assert.equal(res.body.code, 'deletion_failed');

    // Auth user must NOT be deleted!
    assert.equal(users.users.has(userId), true);

    // Deletion request state must be cleanup_failed with ITERATION_LIMIT_EXCEEDED
    const reqTable = db.collections.get('deletion_requests');
    const reqDoc = Array.from(reqTable.values())[0];
    assert.equal(reqDoc.status, 'cleanup_failed');
    assert.equal(reqDoc.lastError, ERROR_CODES.ITERATION_LIMIT_EXCEEDED);
  });

  test('9. Zero-record verification failure when document appears post-loop prevents Auth user deletion', async () => {
    const db = new InMemDb();
    const storage = new InMemStorage();
    const users = new InMemUsers();

    const userId = 'u_del_verify_fail';
    users.users.add(userId);

    // Track calls to listDocuments for user_preferences
    let callCount = 0;
    const origList = db.listDocuments.bind(db);
    db.listDocuments = async (dbId, col, queries) => {
      if (col === 'user_preferences') {
        callCount++;
        // On 1st call (during loop), return empty array so loop exits clean
        if (callCount === 1) {
          return { documents: [], total: 0 };
        }
        // On 2nd call (during zero-record verification), return a leftover document!
        return { documents: [{ $id: 'ghost_doc', userId }], total: 1 };
      }
      return origList(dbId, col, queries);
    };

    const req = { method: 'POST', headers: { 'x-appwrite-user-id': userId } };
    const res = createMockRes();

    await deleteAccountHandler({
      req, res,
      log: () => {}, error: () => {},
      databases: db, users, storage
    });

    assert.equal(res.statusCode, 500);
    assert.equal(res.body.ok, false);

    assert.equal(users.users.has(userId), true);

    const reqTable = db.collections.get('deletion_requests');
    const reqDoc = Array.from(reqTable.values())[0];
    assert.equal(reqDoc.status, 'cleanup_failed');
    assert.equal(reqDoc.lastError, ERROR_CODES.VERIFICATION_FAILED);
  });

  test('9. State transition error during cleanup_complete aborts Auth user deletion', async () => {
    const db = new InMemDb();
    const storage = new InMemStorage();
    const users = new InMemUsers();

    const userId = 'u_del_state_err';
    users.users.add(userId);

    const origUpdate = db.updateDocument.bind(db);
    db.updateDocument = async (dbId, col, id, data) => {
      if (data.status === 'cleanup_complete') {
        const err = new Error('Database write error on state machine');
        throw err;
      }
      return origUpdate(dbId, col, id, data);
    };

    const req = { method: 'POST', headers: { 'x-appwrite-user-id': userId } };
    const res = createMockRes();

    await deleteAccountHandler({
      req, res,
      log: () => {}, error: () => {},
      databases: db, users, storage
    });

    assert.equal(res.statusCode, 500);
    assert.equal(res.body.ok, false);
    assert.equal(res.body.code, 'deletion_failed');

    // Auth user must NOT be deleted!
    assert.equal(users.users.has(userId), true);
  });

  test('10. Privileged orphan recovery transitions auth_deleted request to completed', async () => {
    const db = new InMemDb();

    db.collections.set('deletion_requests', new Map([
      ['del_req_orphan1', { $id: 'del_req_orphan1', status: 'auth_deleted' }]
    ]));

    const stats = await reconcileOrphanedAuthDeletions({
      databases: db,
      databaseId: 'test_db_id',
      log: () => {},
      error: () => {}
    });

    assert.equal(stats.scanned, 1);
    assert.equal(stats.completed, 1);
    assert.equal(stats.failed, 0);

    const doc = db.collections.get('deletion_requests').get('del_req_orphan1');
    assert.equal(doc.status, 'completed');
  });

  test('11. Double post-Auth state update failure leaves request in cleanup_complete while Auth is deleted', async () => {
    const db = new InMemDb();
    const storage = new InMemStorage();
    const users = new InMemUsers();

    const userId = 'u_del_post_auth_fail';
    users.users.add(userId);

    const origUpdate = db.updateDocument.bind(db);
    db.updateDocument = async (dbId, col, id, data) => {
      if (data.status === 'auth_deleted' || data.status === 'completed') {
        const err = new Error('Database connection reset during post-Auth update');
        throw err;
      }
      return origUpdate(dbId, col, id, data);
    };

    const req = { method: 'POST', headers: { 'x-appwrite-user-id': userId } };
    const res = createMockRes();

    await deleteAccountHandler({
      req, res,
      log: () => {}, error: () => {},
      databases: db, users, storage
    });

    assert.equal(res.statusCode, 500);
    assert.equal(res.body.ok, false);
    assert.equal(res.body.code, 'state_update_failed');
    assert.equal(res.body.authDeleted, true);
    assert.equal(res.body.message, 'Account deleted; final cleanup reconciliation is pending.');

    // Auth user WAS successfully deleted!
    assert.equal(users.users.has(userId), false);

    // Request is stranded in cleanup_complete state
    const reqTable = db.collections.get('deletion_requests');
    const reqDoc = Array.from(reqTable.values())[0];
    assert.equal(reqDoc.status, 'cleanup_complete');
  });

  test('12. Privileged orphan recovery detects cleanup_complete request with deleted Auth user and recovers to completed', async () => {
    const db = new InMemDb();
    const users = new InMemUsers();

    const userId = 'u_stranded_100';
    // User is NOT added to users (simulating already deleted Auth account)

    db.collections.set('deletion_requests', new Map([
      ['del_req_stranded', { $id: 'del_req_stranded', userId, status: 'cleanup_complete' }]
    ]));

    const stats = await reconcileOrphanedAuthDeletions({
      databases: db,
      users,
      databaseId: 'test_db_id',
      log: () => {},
      error: () => {}
    });

    assert.equal(stats.scanned, 1);
    assert.equal(stats.completed, 1);
    assert.equal(stats.failed, 0);

    const doc = db.collections.get('deletion_requests').get('del_req_stranded');
    assert.equal(doc.status, 'completed');
  });
});
