import { test, describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'crypto';
import { createOrderHandler } from '../createRazorpayOrder/src/main.js';

function stableId(value) {
  return createHash('sha256').update(value).digest('hex').slice(0, 32);
}

function createMockRes() {
  const res = {
    statusCode: 200,
    body: null,
    json(data, status = 200) {
      res.statusCode = status;
      res.body = data;
      return res;
    }
  };
  return res;
}

function createMockErrorLogger() {
  const logs = [];
  const fn = (msg) => logs.push(msg);
  fn.logs = logs;
  return fn;
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

  async createDocument(dbId, col, id, data, permissions = []) {
    if (!this.collections.has(col)) this.collections.set(col, new Map());
    const table = this.collections.get(col);
    if (table.has(id)) {
      const err = new Error('Document already exists');
      err.code = 409;
      throw err;
    }
    const doc = { $id: id, $createdAt: new Date().toISOString(), ...data, $permissions: permissions };
    table.set(id, doc);
    return JSON.parse(JSON.stringify(doc));
  }

  async updateDocument(dbId, col, id, data, permissions) {
    const table = this.collections.get(col);
    if (!table || !table.has(id)) {
      const err = new Error('Document not found');
      err.code = 404;
      throw err;
    }
    const existing = table.get(id);
    const updated = { ...existing, ...data, ...(permissions ? { $permissions: permissions } : {}) };
    table.set(id, updated);
    return JSON.parse(JSON.stringify(updated));
  }

  async listDocuments(dbId, col, queries = []) {
    const table = this.collections.get(col);
    if (!table) return { documents: [], total: 0 };
    let docs = Array.from(table.values());

    for (const q of queries) {
      if (q && (q.attribute || q.target) && (q.values !== undefined || q.value !== undefined)) {
        const attr = q.attribute || q.target;
        const vals = q.values !== undefined ? q.values : [q.value];
        const flatVals = Array.isArray(vals) ? vals.flat() : [vals];
        docs = docs.filter(d => flatVals.includes(d[attr]));
      }
    }
    return { documents: JSON.parse(JSON.stringify(docs)), total: docs.length };
  }
}

describe('createRazorpayOrder Atomic Idempotency & Concurrency Suite', () => {
  const razorpayKeyId = 'rzp_test_key_111';
  const razorpayKeySecret = 'rzp_test_sec_222';

  beforeEach(() => {
    process.env.APPWRITE_FUNCTION_API_ENDPOINT = 'https://localhost/v1';
    process.env.APPWRITE_FUNCTION_PROJECT_ID = 'test_proj';
    process.env.APPWRITE_FUNCTION_API_KEY = 'test_key';
    process.env.RAZORPAY_KEY_ID = razorpayKeyId;
    process.env.RAZORPAY_KEY_SECRET = razorpayKeySecret;
  });

  test('1. Unauthenticated request fails with 401', async () => {
    const handler = createOrderHandler({ databases: new InMemDb() });
    const req = { method: 'POST', headers: {}, body: JSON.stringify({ categoryId: 'cat1' }) };
    const res = createMockRes();
    await handler({ req, res, error: createMockErrorLogger() });

    assert.equal(res.statusCode, 401);
    assert.equal(res.body.ok, false);
    assert.equal(res.body.message, 'Unauthenticated');
  });

  test('2. Spoofed price in client request body is ignored in favor of server DB price', async () => {
    const db = new InMemDb();
    const userId = 'u_spoof';
    const categoryId = 'cat_paid_499';
    db.collections.set('categories', new Map([
      [categoryId, { name: 'Paid Course', priceInr: 499, unlockMode: 'paid_only' }]
    ]));

    let rzpCalls = 0;
    const mockFetch = async () => {
      rzpCalls++;
      return {
        ok: true,
        json: async () => ({ id: 'order_official_499', amount: 49900, currency: 'INR' })
      };
    };

    const handler = createOrderHandler({ databases: db, fetchImpl: mockFetch });
    const req = {
      method: 'POST',
      headers: { 'x-appwrite-user-id': userId },
      body: JSON.stringify({ categoryId, amount: 1, priceInr: 10, idempotencyKey: 'key_test_spoof_1' })
    };
    const res = createMockRes();
    await handler({ req, res, error: createMockErrorLogger() });

    assert.equal(res.statusCode, 200);
    assert.equal(res.body.ok, true);
    assert.equal(res.body.amount, 49900); // 499 * 100 in paise
    assert.equal(rzpCalls, 1);
  });

  test('3. Same idempotency key sequentially returns the same order (isDuplicateRetry: true)', async () => {
    const db = new InMemDb();
    const userId = 'u_seq';
    const categoryId = 'cat_seq';
    db.collections.set('categories', new Map([
      [categoryId, { name: 'Seq Course', priceInr: 299, unlockMode: 'paid_only' }]
    ]));

    let rzpCalls = 0;
    const mockFetch = async () => {
      rzpCalls++;
      return {
        ok: true,
        json: async () => ({ id: 'order_rzp_seq_1', amount: 29900, currency: 'INR' })
      };
    };

    const handler = createOrderHandler({ databases: db, fetchImpl: mockFetch });
    const req1 = {
      method: 'POST',
      headers: { 'x-appwrite-user-id': userId },
      body: JSON.stringify({ categoryId, idempotencyKey: 'idem_key_seq_100' })
    };
    const res1 = createMockRes();
    await handler({ req: req1, res: res1, error: createMockErrorLogger() });

    assert.equal(res1.statusCode, 200);
    assert.equal(res1.body.orderId, 'order_rzp_seq_1');
    assert.equal(rzpCalls, 1);

    // Second call with same idempotency key
    const req2 = {
      method: 'POST',
      headers: { 'x-appwrite-user-id': userId },
      body: JSON.stringify({ categoryId, idempotencyKey: 'idem_key_seq_100' })
    };
    const res2 = createMockRes();
    await handler({ req: req2, res: res2, error: createMockErrorLogger() });

    assert.equal(res2.statusCode, 200);
    assert.equal(res2.body.orderId, 'order_rzp_seq_1');
    assert.equal(res2.body.isDuplicateRetry, true);
    assert.equal(rzpCalls, 1); // Razorpay SDK WAS NOT CALLED A SECOND TIME!
  });

  test('4. EXACTLY 20 concurrent requests create EXACTLY ONE Razorpay order (lock election guard)', async () => {
    const db = new InMemDb();
    const userId = 'u_concurrent_user';
    const categoryId = 'cat_concurrent';
    const idempotencyKey = 'idem_concurrent_blast_20';
    db.collections.set('categories', new Map([
      [categoryId, { name: 'Concurrent Course', priceInr: 999, unlockMode: 'paid_only' }]
    ]));

    let rzpCallCount = 0;
    const mockFetch = async () => {
      rzpCallCount++;
      await new Promise(r => setTimeout(r, 10));
      return {
        ok: true,
        json: async () => ({ id: 'order_concurrent_winner_999', amount: 99900, currency: 'INR' })
      };
    };

    const handler = createOrderHandler({ databases: db, fetchImpl: mockFetch });

    const promises = Array.from({ length: 20 }, () => {
      const req = {
        method: 'POST',
        headers: { 'x-appwrite-user-id': userId },
        body: JSON.stringify({ categoryId, idempotencyKey })
      };
      const res = createMockRes();
      return handler({ req, res, error: createMockErrorLogger() }).then(() => res);
    });

    const results = await Promise.all(promises);

    // CRITICAL ASSERTION 1: Razorpay API was called EXACTLY ONCE!
    assert.equal(rzpCallCount, 1, `Razorpay API was called ${rzpCallCount} times instead of 1`);

    const okCount = results.filter(r => r.statusCode === 200).length;
    const conflictCount = results.filter(r => r.statusCode === 409).length;

    assert.equal(okCount + conflictCount, 20);
    assert.equal(okCount >= 1, true, 'At least 1 request succeeded');
  });

  test('5. Verified purchase blocks order creation', async () => {
    const db = new InMemDb();
    const userId = 'u_already_bought';
    const categoryId = 'cat_bought';
    const purchaseId = stableId(`${userId}:${categoryId}`);

    db.collections.set('course_purchases', new Map([
      [purchaseId, { status: 'verified' }]
    ]));

    const handler = createOrderHandler({ databases: db });
    const req = {
      method: 'POST',
      headers: { 'x-appwrite-user-id': userId },
      body: JSON.stringify({ categoryId, idempotencyKey: 'key_test_bought_1' })
    };
    const res = createMockRes();
    await handler({ req, res, error: createMockErrorLogger() });

    assert.equal(res.statusCode, 200);
    assert.equal(res.body.ok, false);
    assert.equal(res.body.message, 'Category already unlocked');
  });

  test('6. Gateway network timeout returns 504 with sanitized error', async () => {
    const db = new InMemDb();
    const userId = 'u_timeout';
    const categoryId = 'cat_timeout';
    db.collections.set('categories', new Map([
      [categoryId, { name: 'Timeout Course', priceInr: 199, unlockMode: 'paid_only' }]
    ]));

    const mockFetch = async () => {
      throw new Error('Connection timeout to https://api.razorpay.com/v1/orders');
    };

    const handler = createOrderHandler({ databases: db, fetchImpl: mockFetch });
    const req = {
      method: 'POST',
      headers: { 'x-appwrite-user-id': userId },
      body: JSON.stringify({ categoryId, idempotencyKey: 'idem_timeout_123' })
    };
    const res = createMockRes();
    await handler({ req, res, error: createMockErrorLogger() });

    assert.equal(res.statusCode, 504);
    assert.equal(res.body.ok, false);
    assert.equal(res.body.code, 'reconciliation_required');
  });

  test('7. Payment reconciliation converts paid attempt to verified status and unlocks purchase', async () => {
    const { reconcileStuckPaymentAttempts } = await import('../createRazorpayOrder/src/reconcile.js');
    const db = new InMemDb();
    const userId = 'u_rec';
    const categoryId = 'cat_rec';
    const attemptId = 'att_rec_1';

    db.collections.set('payment_attempts', new Map([
      [attemptId, {
        $id: attemptId,
        userId,
        categoryId,
        status: 'reconciliation_required',
        providerOrderId: 'order_rzp_paid_123',
        expectedAmount: 299,
        reconciliationStatus: 'pending'
      }]
    ]));

    const mockFetch = async () => ({
      ok: true,
      json: async () => ({ id: 'order_rzp_paid_123', status: 'paid', amount: 29900 })
    });

    const stats = await reconcileStuckPaymentAttempts({
      databases: db,
      databaseId: 'olitun_db',
      fetchImpl: mockFetch,
      razorpayKeyId: 'rzp_test_key',
      razorpayKeySecret: 'rzp_test_secret',
      log: () => {},
      error: () => {}
    });

    assert.equal(stats.scanned, 1);
    assert.equal(stats.reconciled, 1);
    assert.equal(stats.failed, 0);

    const updatedAttempt = db.collections.get('payment_attempts').get(attemptId);
    assert.equal(updatedAttempt.status, 'verified');
    assert.equal(updatedAttempt.reconciliationStatus, 'reconciled_paid');
  });
});

