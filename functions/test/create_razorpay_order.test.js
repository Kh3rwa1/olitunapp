import { test, describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { createHash, createHmac } from 'crypto';
import { createOrderHandler, STALE_RESERVATION_TIMEOUT_MS, LEASE_DURATION_MS } from '../createRazorpayOrder/src/main.js';
import { createVerifyCoursePurchaseHandler } from '../verifyCoursePurchase/src/main.js';
import { createRazorpayWebhookHandler } from '../razorpayWebhook/src/main.js';

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

  test('4b. An 11th distinct order in an hour is rate limited with 429', async () => {
    const db = new InMemDb();
    const userId = 'u_rate_limited';
    const categoryId = 'cat_rate_limit';
    db.collections.set('categories', new Map([
      [categoryId, { name: 'Rate Limited Course', priceInr: 199, unlockMode: 'paid_only' }]
    ]));

    const mockFetch = async () => ({
      ok: true,
      json: async () => ({ id: 'order_rate_limit_test', amount: 19900, currency: 'INR' })
    });

    const handler = createOrderHandler({ databases: db, fetchImpl: mockFetch });

    let lastRes;
    for (let i = 0; i < 11; i++) {
      const req = {
        method: 'POST',
        headers: { 'x-appwrite-user-id': userId },
        body: JSON.stringify({ categoryId, idempotencyKey: `key_rate_limit_${i}` })
      };
      lastRes = createMockRes();
      await handler({ req, res: lastRes, error: createMockErrorLogger() });
    }

    assert.equal(lastRes.statusCode, 429);
    assert.equal(lastRes.body.ok, false);
    assert.match(lastRes.body.message, /Too many checkout attempts/i);
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
    const { reconcileStuckPaymentAttempts } = await import('../_shared/payment_reconcile.js');
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

    const mockFetch = async (url) => {
      if (String(url).includes('/payments')) {
        return {
          ok: true,
          json: async () => ({
            items: [
              { id: 'pay_rec_1', status: 'captured', amount: 29900, created_at: 1700000000 }
            ]
          })
        };
      }
      return {
        ok: true,
        json: async () => ({ id: 'order_rzp_paid_123', status: 'paid', amount: 29900 })
      };
    };

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

    // The reconciled grant must land on the canonical stableId ledger row
    // with the verified schema, not an orphaned `purch_user_category` doc.
    const ledgerRow = db.collections.get('course_purchases').get(stableId(`${userId}:${categoryId}`));
    assert.ok(ledgerRow, 'canonical course_purchases ledger row was written');
    assert.equal(ledgerRow.status, 'verified');
    assert.equal(ledgerRow.providerPaymentId, 'pay_rec_1');
    assert.equal(ledgerRow.expectedAmount, 299);
    assert.equal(ledgerRow.paidAmount, 299);
    assert.ok(![...db.collections.get('course_purchases').keys()].some(k => k.startsWith('purch_')),
      'no orphaned purch_user_category docs created');
  });

  test('8a. Razorpay 5xx failure -> retry succeeds (200 OK)', async () => {
    const db = new InMemDb();
    const userId = 'u_lockout_user_a';
    const categoryId = 'cat_lockout_test_a';
    db.collections.set('categories', new Map([
      [categoryId, { name: 'Lockout Course A', priceInr: 399, unlockMode: 'paid_only' }]
    ]));

    let rzpCalls = 0;
    const mockFetch = async () => {
      rzpCalls++;
      if (rzpCalls === 1) {
        return {
          ok: false,
          status: 500,
          json: async () => ({ error: { description: 'Razorpay 500 internal error' } })
        };
      }
      return {
        ok: true,
        json: async () => ({ id: 'order_rzp_retry_5xx_ok', amount: 39900, currency: 'INR' })
      };
    };

    const handler = createOrderHandler({ databases: db, fetchImpl: mockFetch });

    // 1st request fails at Razorpay
    const req1 = {
      method: 'POST',
      headers: { 'x-appwrite-user-id': userId },
      body: JSON.stringify({ categoryId })
    };
    const res1 = createMockRes();
    await handler({ req: req1, res: res1, error: createMockErrorLogger() });
    assert.equal(res1.statusCode, 502);

    const attemptDocId = `att_${stableId(`${userId}:${categoryId}:${stableId(`${userId}:${categoryId}:checkout_default`)}`)}`;
    const attemptInDb = db.collections.get('payment_attempts').get(attemptDocId);
    assert.ok(attemptInDb);
    assert.equal(attemptInDb.status, 'failed');
    assert.equal(attemptInDb.providerOrderId, null);

    // 2nd request (retry) succeeds with 200 OK
    const req2 = {
      method: 'POST',
      headers: { 'x-appwrite-user-id': userId },
      body: JSON.stringify({ categoryId })
    };
    const res2 = createMockRes();
    await handler({ req: req2, res: res2, error: createMockErrorLogger() });
    assert.equal(res2.statusCode, 200, `Expected 200 on retry, got ${res2.statusCode}: ${JSON.stringify(res2.body)}`);
    assert.equal(res2.body.ok, true);
    assert.equal(res2.body.orderId, 'order_rzp_retry_5xx_ok');
    assert.equal(rzpCalls, 2);
  });

  test('8b. Stale in_progress attempt (>60s) -> retry succeeds (200 OK)', async () => {
    const db = new InMemDb();
    const userId = 'u_stale_user_b';
    const categoryId = 'cat_stale_test_b';
    const idempotencyKey = 'stale_attempt_key_b';
    db.collections.set('categories', new Map([
      [categoryId, { name: 'Stale Course B', priceInr: 499, unlockMode: 'paid_only' }]
    ]));

    const attemptDocId = `att_${stableId(`${userId}:${categoryId}:${idempotencyKey}`)}`;
    const staleTime = new Date(Date.now() - 65000).toISOString();
    db.collections.set('payment_attempts', new Map([
      [attemptDocId, {
        $id: attemptDocId,
        userId,
        categoryId,
        idempotencyKey,
        attemptId: attemptDocId,
        expectedAmount: 499,
        currency: 'INR',
        status: 'in_progress',
        provider: 'razorpay',
        providerOrderId: null,
        providerReceipt: 'rec_stale_123',
        leaseOwner: 'crashed_worker_1',
        leaseExpiresAt: staleTime,
        reconciliationStatus: 'none',
        createdAt: staleTime,
        updatedAt: staleTime,
      }]
    ]));

    let rzpCalls = 0;
    const mockFetch = async () => {
      rzpCalls++;
      return {
        ok: true,
        json: async () => ({ id: 'order_rzp_stale_recovery', amount: 49900, currency: 'INR' })
      };
    };

    const handler = createOrderHandler({ databases: db, fetchImpl: mockFetch });

    const req = {
      method: 'POST',
      headers: { 'x-appwrite-user-id': userId },
      body: JSON.stringify({ categoryId, idempotencyKey })
    };
    const res = createMockRes();
    await handler({ req, res, error: createMockErrorLogger() });

    assert.equal(res.statusCode, 200, `Expected 200 but got ${res.statusCode}: ${JSON.stringify(res.body)}`);
    assert.equal(res.body.ok, true);
    assert.equal(res.body.orderId, 'order_rzp_stale_recovery');
    assert.equal(rzpCalls, 1);

    const updated = db.collections.get('payment_attempts').get(attemptDocId);
    assert.equal(updated.providerOrderId, 'order_rzp_stale_recovery');
  });

  test('8c. Fresh in_progress attempt (<60s) -> retry returns 409 in_progress', async () => {
    const db = new InMemDb();
    const userId = 'u_fresh_user_c';
    const categoryId = 'cat_fresh_test_c';
    const idempotencyKey = 'fresh_attempt_key_c';
    db.collections.set('categories', new Map([
      [categoryId, { name: 'Fresh Course C', priceInr: 299, unlockMode: 'paid_only' }]
    ]));

    // Subcase 1: Active lease in future (+25s)
    const attemptDocId = `att_${stableId(`${userId}:${categoryId}:${idempotencyKey}`)}`;
    const freshExpiry = new Date(Date.now() + 25000).toISOString();
    db.collections.set('payment_attempts', new Map([
      [attemptDocId, {
        $id: attemptDocId,
        userId,
        categoryId,
        idempotencyKey,
        attemptId: attemptDocId,
        expectedAmount: 299,
        currency: 'INR',
        status: 'in_progress',
        provider: 'razorpay',
        providerOrderId: null,
        providerReceipt: 'rec_fresh_123',
        leaseOwner: 'active_worker_2',
        leaseExpiresAt: freshExpiry,
        reconciliationStatus: 'none',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      }]
    ]));

    let rzpCalls = 0;
    const mockFetch = async () => {
      rzpCalls++;
      return { ok: true, json: async () => ({ id: 'order_fresh_not_expected' }) };
    };

    const handler = createOrderHandler({ databases: db, fetchImpl: mockFetch });

    const req = {
      method: 'POST',
      headers: { 'x-appwrite-user-id': userId },
      body: JSON.stringify({ categoryId, idempotencyKey })
    };
    const res = createMockRes();
    await handler({ req, res, error: createMockErrorLogger() });

    assert.equal(res.statusCode, 409);
    assert.equal(res.body.ok, false);
    assert.equal(res.body.code, 'in_progress');
    assert.equal(rzpCalls, 0, 'Razorpay must not be called when an active lease exists');

    // Subcase 2: Attempt created 45s ago (< 60s stale threshold) with expired lease
    const time45sAgo = new Date(Date.now() - 45000).toISOString();
    db.collections.get('payment_attempts').set(attemptDocId, {
      $id: attemptDocId,
      userId,
      categoryId,
      idempotencyKey,
      attemptId: attemptDocId,
      expectedAmount: 299,
      currency: 'INR',
      status: 'in_progress',
      provider: 'razorpay',
      providerOrderId: null,
      providerReceipt: 'rec_fresh_123',
      leaseOwner: 'active_worker_2',
      leaseExpiresAt: time45sAgo,
      reconciliationStatus: 'none',
      createdAt: time45sAgo,
      updatedAt: time45sAgo,
    });

    const res2 = createMockRes();
    await handler({ req, res: res2, error: createMockErrorLogger() });
    assert.equal(res2.statusCode, 409);
    assert.equal(res2.body.ok, false);
    assert.equal(res2.body.code, 'in_progress');
    assert.equal(rzpCalls, 0, 'Razorpay must not be called when attempt age is < 60s');
  });

  test('8d. Rate-limited retry -> attempt marked failed -> retry succeeds once rate limit resets', async () => {
    const db = new InMemDb();
    const userId = 'u_rate_limit_user_d';
    const categoryId = 'cat_rate_limit_test_d';
    const idempotencyKey = 'rate_limited_attempt_key_d';
    db.collections.set('categories', new Map([
      [categoryId, { name: 'Rate Limited Course D', priceInr: 199, unlockMode: 'paid_only' }]
    ]));

    let rzpCalls = 0;
    const mockFetch = async () => {
      rzpCalls++;
      return {
        ok: true,
        json: async () => ({ id: `order_rl_${rzpCalls}`, amount: 19900, currency: 'INR' })
      };
    };

    const handler = createOrderHandler({ databases: db, fetchImpl: mockFetch });

    // Exhaust the rate limit (10 per hour) by filling slots in rate_limits
    for (let i = 0; i < 10; i++) {
      const dummyCat = `cat_dummy_${i}`;
      db.collections.get('categories').set(dummyCat, { name: 'Dummy', priceInr: 199, unlockMode: 'paid_only' });
      const req = {
        method: 'POST',
        headers: { 'x-appwrite-user-id': userId },
        body: JSON.stringify({ categoryId: dummyCat, idempotencyKey: `dummy_key_${i}` })
      };
      const res = createMockRes();
      await handler({ req, res, error: createMockErrorLogger() });
      assert.equal(res.statusCode, 200);
    }
    assert.equal(rzpCalls, 10);

    // The 11th request with categoryId and idempotencyKey will exceed the limit and get 429
    const reqExceeded = {
      method: 'POST',
      headers: { 'x-appwrite-user-id': userId },
      body: JSON.stringify({ categoryId, idempotencyKey })
    };
    const resExceeded = createMockRes();
    await handler({ req: reqExceeded, res: resExceeded, error: createMockErrorLogger() });
    assert.equal(resExceeded.statusCode, 429);

    // Verify attempt record was marked failed, not stuck in_progress!
    const attemptDocId = `att_${stableId(`${userId}:${categoryId}:${idempotencyKey}`)}`;
    const attemptInDb = db.collections.get('payment_attempts').get(attemptDocId);
    assert.ok(attemptInDb);
    assert.equal(attemptInDb.status, 'failed');
    assert.equal(attemptInDb.providerOrderId, null);

    // Now clear/reset the rate_limits table (simulating time window elapsed)
    db.collections.set('rate_limits', new Map());

    // Retry the same request
    const reqRetry = {
      method: 'POST',
      headers: { 'x-appwrite-user-id': userId },
      body: JSON.stringify({ categoryId, idempotencyKey })
    };
    const resRetry = createMockRes();
    await handler({ req: reqRetry, res: resRetry, error: createMockErrorLogger() });

    assert.equal(resRetry.statusCode, 200, `Expected 200 after rate limit reset, but got ${resRetry.statusCode}: ${JSON.stringify(resRetry.body)}`);
    assert.equal(resRetry.body.ok, true);
    assert.equal(resRetry.body.orderId, 'order_rl_11');
    assert.equal(rzpCalls, 11);
  });

  test('8e. Concurrent retries (20 simultaneous calls to re-reserve a failed attempt) -> Razorpay called exactly ONCE, order returned to all or yields 409 in_progress', async () => {
    const db = new InMemDb();
    const userId = 'u_concurrent_retry_user';
    const categoryId = 'cat_concurrent_retry';
    const idempotencyKey = 'concurrent_retry_blast_20';
    db.collections.set('categories', new Map([
      [categoryId, { name: 'Concurrent Retry Course', priceInr: 599, unlockMode: 'paid_only' }]
    ]));

    // Seed a previously failed attempt document
    const attemptDocId = `att_${stableId(`${userId}:${categoryId}:${idempotencyKey}`)}`;
    const nowIso = new Date().toISOString();
    db.collections.set('payment_attempts', new Map([
      [attemptDocId, {
        $id: attemptDocId,
        userId,
        categoryId,
        idempotencyKey,
        attemptId: attemptDocId,
        expectedAmount: 599,
        currency: 'INR',
        status: 'failed',
        provider: 'razorpay',
        providerOrderId: null,
        providerReceipt: 'rec_initial_failed',
        leaseOwner: 'worker_crashed',
        leaseExpiresAt: nowIso,
        reconciliationStatus: 'none',
        createdAt: nowIso,
        updatedAt: nowIso,
      }]
    ]));

    let rzpCallCount = 0;
    const mockFetch = async () => {
      rzpCallCount++;
      await new Promise(r => setTimeout(r, 15));
      return {
        ok: true,
        json: async () => ({ id: 'order_concurrent_retry_winner', amount: 59900, currency: 'INR' })
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

    // CRITICAL ASSERTION: Razorpay API was called EXACTLY ONCE!
    assert.equal(rzpCallCount, 1, `Razorpay API was called ${rzpCallCount} times instead of 1`);

    const okCount = results.filter(r => r.statusCode === 200).length;
    const conflictCount = results.filter(r => r.statusCode === 409).length;

    assert.equal(okCount + conflictCount, 20);
    assert.equal(okCount >= 1, true, 'At least 1 request succeeded');

    const okResults = results.filter(r => r.statusCode === 200);
    for (const r of okResults) {
      assert.equal(r.body.orderId, 'order_concurrent_retry_winner');
    }
  });

  test('8f. Adversarial interleaving: two concurrent contenders race on a failed/stale attempt -> contender 1 wins atomic election lock, contender 2 receives 409 conflict, Razorpay called exactly ONCE, retry returns canonical order', async () => {
    const db = new InMemDb();
    const userId = 'u_adversarial_user';
    const categoryId = 'cat_adversarial_test';
    const idempotencyKey = 'adversarial_key_123';
    db.collections.set('categories', new Map([
      [categoryId, { name: 'Adversarial Course', priceInr: 399, unlockMode: 'paid_only' }]
    ]));

    // Seed a previously failed attempt
    const attemptDocId = `att_${stableId(`${userId}:${categoryId}:${idempotencyKey}`)}`;
    const pastTime = new Date(Date.now() - 70000).toISOString();
    db.collections.set('payment_attempts', new Map([
      [attemptDocId, {
        $id: attemptDocId,
        userId,
        categoryId,
        idempotencyKey,
        attemptId: attemptDocId,
        expectedAmount: 399,
        currency: 'INR',
        status: 'failed',
        provider: 'razorpay',
        providerOrderId: null,
        providerReceipt: 'rec_adv_1',
        leaseOwner: 'crashed_worker',
        leaseExpiresAt: pastTime,
        reconciliationStatus: 'none',
        createdAt: pastTime,
        updatedAt: pastTime,
      }]
    ]));

    let rzpCalls = 0;
    let rzpFetchResolve;
    const rzpGatePromise = new Promise(resolve => { rzpFetchResolve = resolve; });

    const mockFetch = async () => {
      rzpCalls++;
      // Pause worker 1 while holding the lease election lock to simulate network latency
      await rzpGatePromise;
      return {
        ok: true,
        json: async () => ({ id: 'order_rzp_adversarial_winner', amount: 39900, currency: 'INR' })
      };
    };

    const handler = createOrderHandler({ databases: db, fetchImpl: mockFetch });

    const req = {
      method: 'POST',
      headers: { 'x-appwrite-user-id': userId },
      body: JSON.stringify({ categoryId, idempotencyKey })
    };

    // Contender 1 initiates re-reservation and enters Razorpay fetch (paused on rzpGatePromise)
    const res1 = createMockRes();
    const contender1Promise = handler({ req, res: res1, error: createMockErrorLogger() });

    // Yield execution to allow contender 1 to win the atomic election lock and enter mockFetch
    await new Promise(r => setTimeout(r, 20));

    // Verify election lock document exists in DB
    const electionLocks = [...db.collections.get('payment_attempts').keys()].filter(k => k.startsWith('elc_'));
    assert.equal(electionLocks.length, 1, 'Exactly one election lock document created');

    // Contender 2 arrives concurrently while contender 1 is awaiting Razorpay gateway response
    const res2 = createMockRes();
    await handler({ req, res: res2, error: createMockErrorLogger() });

    // Contender 2 must receive 409 conflict with code 'in_progress'
    assert.equal(res2.statusCode, 409);
    assert.equal(res2.body.ok, false);
    assert.equal(res2.body.code, 'in_progress');

    // Razorpay has only been called by Contender 1 so far
    assert.equal(rzpCalls, 1);

    // Contender 1 finishes gateway call and saves order
    rzpFetchResolve();
    await contender1Promise;

    // Contender 1 must succeed with 200 OK
    assert.equal(res1.statusCode, 200);
    assert.equal(res1.body.ok, true);
    assert.equal(res1.body.orderId, 'order_rzp_adversarial_winner');

    // Contender 2 now retries (or client retry) after contender 1 finished
    const res3 = createMockRes();
    await handler({ req, res: res3, error: createMockErrorLogger() });

    // Retry must succeed with 200 OK and return the exact canonical order without calling Razorpay again
    assert.equal(res3.statusCode, 200);
    assert.equal(res3.body.ok, true);
    assert.equal(res3.body.orderId, 'order_rzp_adversarial_winner');
    assert.equal(res3.body.isDuplicateRetry, true);

    // CRITICAL: Razorpay API was called EXACTLY ONCE
    assert.equal(rzpCalls, 1, 'Razorpay must be called exactly once across both contenders and retries');
  });

  test('8g. Unsaved second order / recovery: payment for newly elected order is granted and committed by verifyCoursePurchase and razorpayWebhook', async () => {
    const db = new InMemDb();
    const userId = 'u_recovery_payer_g';
    const categoryId = 'cat_recovery_test_g';
    const idempotencyKey = 'recovery_attempt_key_g';
    const priceInr = 499;

    db.collections.set('categories', new Map([
      [categoryId, { name: 'Recovery Course G', priceInr, unlockMode: 'paid_only' }]
    ]));

    // Step 1: Simulate worker 1 crashing after creating an order at the gateway, leaving the attempt
    // stale without providerOrderId in payment_attempts and with no course_purchases row.
    const attemptDocId = `att_${stableId(`${userId}:${categoryId}:${idempotencyKey}`)}`;
    const staleTime = new Date(Date.now() - 75000).toISOString();
    db.collections.set('payment_attempts', new Map([
      [attemptDocId, {
        $id: attemptDocId,
        userId,
        categoryId,
        idempotencyKey,
        attemptId: attemptDocId,
        expectedAmount: priceInr,
        currency: 'INR',
        status: 'in_progress',
        provider: 'razorpay',
        providerOrderId: null,
        providerReceipt: stableId(`${userId}:${categoryId}`),
        leaseOwner: 'crashed_worker_1',
        leaseExpiresAt: staleTime,
        reconciliationStatus: 'none',
        createdAt: staleTime,
        updatedAt: staleTime,
      }]
    ]));

    // Step 2: User retries after stale timeout. Worker 2 creates second order 'order_rzp_rec_2'
    let rzpCalls = 0;
    const mockOrderFetch = async () => {
      rzpCalls++;
      return {
        ok: true,
        json: async () => ({ id: 'order_rzp_rec_2', amount: priceInr * 100, currency: 'INR' })
      };
    };

    const orderHandler = createOrderHandler({ databases: db, fetchImpl: mockOrderFetch });
    const req = {
      method: 'POST',
      headers: { 'x-appwrite-user-id': userId },
      body: JSON.stringify({ categoryId, idempotencyKey })
    };
    const res = createMockRes();
    await orderHandler({ req, res, error: createMockErrorLogger() });

    assert.equal(res.statusCode, 200);
    assert.equal(res.body.ok, true);
    assert.equal(res.body.orderId, 'order_rzp_rec_2');

    // Confirm course_purchases has the newly elected order 'order_rzp_rec_2' in status 'created'
    const purchaseDocId = stableId(`${userId}:${categoryId}`);
    const pendingPurchase = db.collections.get('course_purchases')?.get(purchaseDocId);
    assert.ok(pendingPurchase);
    assert.equal(pendingPurchase.status, 'created');
    assert.equal(pendingPurchase.providerOrderId, 'order_rzp_rec_2');

    // Step 3: User pays 'order_rzp_rec_2' and client calls verifyCoursePurchase
    const paymentId = 'pay_rzp_rec_captured_2';
    const razorpaySecret = process.env.RAZORPAY_KEY_SECRET;
    const signature = createHmac('sha256', razorpaySecret)
      .update(`order_rzp_rec_2|${paymentId}`)
      .digest('hex');

    const mockVerifyFetch = async (url) => {
      assert.ok(url.includes(paymentId));
      return {
        ok: true,
        status: 200,
        json: async () => ({
          id: paymentId,
          order_id: 'order_rzp_rec_2',
          status: 'captured',
          amount: priceInr * 100,
          currency: 'INR',
        })
      };
    };

    const verifyHandler = createVerifyCoursePurchaseHandler({ databases: db, fetchImpl: mockVerifyFetch });
    const verifyReq = {
      method: 'POST',
      headers: { 'x-appwrite-user-id': userId },
      body: JSON.stringify({
        categoryId,
        unlockMethod: 'razorpay',
        razorpayPaymentId: paymentId,
        razorpayOrderId: 'order_rzp_rec_2',
        razorpaySignature: signature,
      })
    };
    const verifyRes = createMockRes();
    await verifyHandler({ req: verifyReq, res: verifyRes, error: createMockErrorLogger() });

    // Entitlement must be granted with 200 OK!
    assert.equal(verifyRes.statusCode, 200, `Verify failed: ${JSON.stringify(verifyRes.body)}`);
    assert.equal(verifyRes.body.ok, true);

    const verifiedPurchase = db.collections.get('course_purchases').get(purchaseDocId);
    assert.equal(verifiedPurchase.status, 'verified');
    assert.equal(verifiedPurchase.providerOrderId, 'order_rzp_rec_2');
    assert.equal(verifiedPurchase.providerPaymentId, paymentId);
    assert.equal(verifiedPurchase.paidAmount, priceInr);

    // Payment claim must be committed
    const claimDocId = stableId(`claim:${paymentId}`);
    const claim = db.collections.get('payment_claims').get(claimDocId);
    assert.ok(claim);
    assert.equal(claim.status, 'committed');

    // Step 4: Idempotent verify retry on already verified purchase succeeds
    const verifyRes2 = createMockRes();
    await verifyHandler({ req: verifyReq, res: verifyRes2, error: createMockErrorLogger() });
    assert.equal(verifyRes2.statusCode, 200);
    assert.equal(verifyRes2.body.ok, true);
    assert.equal(verifyRes2.body.message, 'Purchase already verified');

    // Step 5: Verify that razorpayWebhook also handles order_rzp_rec_2 safely
    const webhookSecret = 'whsec_test_secret_123';
    process.env.RAZORPAY_WEBHOOK_SECRET = webhookSecret;
    const webhookPayload = JSON.stringify({
      event: 'payment.captured',
      payload: {
        payment: {
          entity: {
            id: paymentId,
            order_id: 'order_rzp_rec_2',
            amount: priceInr * 100,
            currency: 'INR',
            notes: { userId, categoryId }
          }
        }
      }
    });
    const webhookSig = createHmac('sha256', webhookSecret).update(webhookPayload).digest('hex');
    const webhookHandler = createRazorpayWebhookHandler({ databases: db });
    const webhookReq = {
      method: 'POST',
      headers: { 'x-razorpay-signature': webhookSig },
      body: webhookPayload,
      bodyRaw: webhookPayload,
    };
    const webhookRes = createMockRes();
    await webhookHandler({ req: webhookReq, res: webhookRes, error: createMockErrorLogger() });
    assert.equal(webhookRes.statusCode, 200);
  });

  test('8h. Backward compatibility: clients omitting idempotencyKey default to deterministic per-user-category key and can recover from failure', async () => {
    const db = new InMemDb();
    const userId = 'u_legacy_client_user';
    const categoryId = 'cat_legacy_course';
    db.collections.set('categories', new Map([
      [categoryId, { name: 'Legacy Course', priceInr: 299, unlockMode: 'paid_only' }]
    ]));

    let rzpCalls = 0;
    const mockFetch = async () => {
      rzpCalls++;
      if (rzpCalls === 1) {
        return {
          ok: false,
          status: 502,
          json: async () => ({ error: { description: 'Gateway error' } })
        };
      }
      return {
        ok: true,
        json: async () => ({ id: 'order_legacy_recovery', amount: 29900, currency: 'INR' })
      };
    };

    const handler = createOrderHandler({ databases: db, fetchImpl: mockFetch });

    // Client sends NO idempotencyKey in body
    const req1 = {
      method: 'POST',
      headers: { 'x-appwrite-user-id': userId },
      body: JSON.stringify({ categoryId })
    };
    const res1 = createMockRes();
    await handler({ req: req1, res: res1, error: createMockErrorLogger() });
    assert.equal(res1.statusCode, 502);

    // Verify the attempt document was keyed using the deterministic default
    const expectedDefaultKey = stableId(`${userId}:${categoryId}:checkout_default`);
    const attemptDocId = `att_${stableId(`${userId}:${categoryId}:${expectedDefaultKey}`)}`;
    const attemptInDb = db.collections.get('payment_attempts').get(attemptDocId);
    assert.ok(attemptInDb, 'Attempt document should exist with deterministic default key');
    assert.equal(attemptInDb.idempotencyKey, expectedDefaultKey);
    assert.equal(attemptInDb.status, 'failed');

    // Second request with no idempotencyKey recovers the failed attempt
    const req2 = {
      method: 'POST',
      headers: { 'x-appwrite-user-id': userId },
      body: JSON.stringify({ categoryId })
    };
    const res2 = createMockRes();
    await handler({ req: req2, res: res2, error: createMockErrorLogger() });

    assert.equal(res2.statusCode, 200);
    assert.equal(res2.body.ok, true);
    assert.equal(res2.body.orderId, 'order_legacy_recovery');
    assert.equal(rzpCalls, 2);
  });
});

