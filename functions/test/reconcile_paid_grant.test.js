import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'crypto';

import { reconcileStuckPaymentAttempts } from '../_shared/payment_reconcile.js';

function stableId(value) {
  return createHash('sha256').update(value).digest('hex').slice(0, 32);
}

function createInMemoryDb() {
  const calls = [];
  const docs = new Map();
  const key = (col, id) => `${col}/${id}`;

  return {
    calls,
    docs,
    seed(col, id, data) {
      docs.set(key(col, id), { $id: id, ...data });
    },
    async listDocuments(_db, col, _queries) {
      calls.push({ op: 'list', col });
      const items = [];
      for (const [k, v] of docs.entries()) {
        if (k.startsWith(`${col}/`)) items.push(v);
      }
      return { documents: items, total: items.length };
    },
    async updateDocument(_db, col, id, data, permissions) {
      calls.push({ op: 'update', col, id, data, permissions });
      const k = key(col, id);
      if (!docs.has(k)) {
        const err = new Error('Document not found');
        err.code = 404;
        throw err;
      }
      const existing = docs.get(k);
      const updated = { ...existing, ...data };
      docs.set(k, updated);
      return updated;
    },
    async createDocument(_db, col, id, data, permissions) {
      calls.push({ op: 'create', col, id, data, permissions });
      docs.set(key(col, id), { $id: id, ...data });
      return { $id: id, ...data };
    },
  };
}

function createFetchFake(orderStatus, paymentOverrides = {}) {
  return async (url) => {
    if (url.includes('/payments')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              id: 'pay_capture_1',
              status: paymentOverrides.status ?? 'captured',
              amount: paymentOverrides.amount ?? 49900,
              created_at: 1700000000,
            },
          ],
        }),
      };
    }
    return {
      ok: true,
      json: async () => ({ id: 'ord_X', status: orderStatus, amount: 49900, amount_paid: 49900 }),
    };
  };
}

const USER = 'user-abc';
const CATEGORY = 'category-xyz';
const EXPECTED_PURCHASE_ID = stableId(`${USER}:${CATEGORY}`);

function buildAttempt(overrides = {}) {
  return {
    $id: 'att_1',
    userId: USER,
    categoryId: CATEGORY,
    providerOrderId: 'ord_X',
    expectedAmount: 499,
    currency: 'INR',
    status: 'reconciliation_required',
    reconciliationStatus: 'gateway_timeout',
    ...overrides,
  };
}

const LOG = () => {};
const ERR = () => {};

describe('reconcileStuckPaymentAttempts paid-order grant', () => {
  test('grants entitlement using the canonical stableId purchase key, schema, and permissions', async () => {
    const db = createInMemoryDb();
    db.seed('payment_attempts', 'att_1', buildAttempt());

    const stats = await reconcileStuckPaymentAttempts({
      databases: db,
      databaseId: 'olitun_db',
      fetchImpl: createFetchFake('paid'),
      razorpayKeyId: 'key',
      razorpayKeySecret: 'secret',
      log: LOG,
      error: ERR,
    });

    assert.equal(stats.reconciled, 1);
    assert.equal(stats.failed, 0);

    const purchase = db.docs.get(`course_purchases/${EXPECTED_PURCHASE_ID}`);
    assert.ok(purchase, `ledger row exists at canonical id ${EXPECTED_PURCHASE_ID}`);
    assert.equal(purchase.status, 'verified');
    assert.equal(purchase.provider, 'razorpay');
    assert.equal(purchase.providerOrderId, 'ord_X');
    assert.equal(purchase.providerPaymentId, 'pay_capture_1');
    assert.equal(purchase.expectedAmount, 499, 'rupee-denominated expected amount');
    assert.equal(purchase.paidAmount, 499, 'paidAmount converted from paise to rupees');
    assert.equal(purchase.currency, 'INR');
    assert.ok(purchase.paidAt, 'paidAt stamped');
    assert.ok(purchase.verifiedAt, 'verifiedAt stamped');

    const createOrUpdate = db.calls.find((c) => c.col === 'course_purchases');
    assert.deepEqual(createOrUpdate.permissions, [
      `read("user:${USER}")`,
      'read("team:admins")',
      'update("team:admins")',
      'delete("team:admins")',
    ]);

    const attemptUpdate = db.calls.find((c) => c.col === 'payment_attempts' && c.op === 'update' && c.data.status);
    assert.equal(attemptUpdate.data.status, 'verified');
    const grantIndex = db.calls.findIndex((c) => c.col === 'course_purchases');
    const attemptVerifiedIndex = db.calls.findIndex(
      (c) => c.col === 'payment_attempts' && c.op === 'update' && c.data.status === 'verified',
    );
    assert.ok(grantIndex < attemptVerifiedIndex, 'ledger is written before the attempt is marked verified');
  });

  test('reuses and verifies an existing pending ledger row instead of creating a duplicate', async () => {
    const db = createInMemoryDb();
    db.seed('payment_attempts', 'att_1', buildAttempt());
    db.seed('course_purchases', EXPECTED_PURCHASE_ID, {
      userId: USER,
      categoryId: CATEGORY,
      provider: 'razorpay',
      providerOrderId: 'ord_X',
      providerPaymentId: '',
      expectedAmount: 499,
      paidAmount: 0,
      currency: 'INR',
      status: 'created',
      createdAt: '2026-01-01T00:00:00.000Z',
      paidAt: null,
      verifiedAt: null,
      failureReason: '',
    });

    const stats = await reconcileStuckPaymentAttempts({
      databases: db,
      databaseId: 'olitun_db',
      fetchImpl: createFetchFake('paid'),
      razorpayKeyId: 'key',
      razorpayKeySecret: 'secret',
      log: LOG,
      error: ERR,
    });

    assert.equal(stats.reconciled, 1);
    assert.ok(
      !db.calls.some((c) => c.op === 'create' && c.col === 'course_purchases'),
      'no duplicate ledger row is created',
    );
    assert.equal(db.docs.get(`course_purchases/${EXPECTED_PURCHASE_ID}`).status, 'verified');
  });

  test('fails closed on amount mismatch: no grant, attempt flagged amount_mismatch', async () => {
    const db = createInMemoryDb();
    db.seed('payment_attempts', 'att_1', buildAttempt());

    const stats = await reconcileStuckPaymentAttempts({
      databases: db,
      databaseId: 'olitun_db',
      fetchImpl: createFetchFake('paid', { amount: 10000 }),
      razorpayKeyId: 'key',
      razorpayKeySecret: 'secret',
      log: LOG,
      error: ERR,
    });

    assert.equal(stats.failed, 1);
    assert.ok(!db.docs.has(`course_purchases/${EXPECTED_PURCHASE_ID}`), 'no ledger row granted');
    const attemptUpdate = db.calls.find((c) => c.col === 'payment_attempts' && c.op === 'update');
    assert.equal(attemptUpdate.data.reconciliationStatus, 'amount_mismatch');
    assert.equal(attemptUpdate.data.status, undefined, 'attempt is not marked verified');
  });

  test('fails closed when the paid order has no captured payment', async () => {
    const db = createInMemoryDb();
    db.seed('payment_attempts', 'att_1', buildAttempt());

    const stats = await reconcileStuckPaymentAttempts({
      databases: db,
      databaseId: 'olitun_db',
      fetchImpl: createFetchFake('paid', { status: 'authorized' }),
      razorpayKeyId: 'key',
      razorpayKeySecret: 'secret',
      log: LOG,
      error: ERR,
    });

    assert.equal(stats.failed, 1);
    assert.ok(!db.docs.has(`course_purchases/${EXPECTED_PURCHASE_ID}`), 'no ledger row granted');
  });

  test('expires attempts whose gateway order is not paid', async () => {
    const db = createInMemoryDb();
    db.seed('payment_attempts', 'att_1', buildAttempt());

    const stats = await reconcileStuckPaymentAttempts({
      databases: db,
      databaseId: 'olitun_db',
      fetchImpl: createFetchFake('created'),
      razorpayKeyId: 'key',
      razorpayKeySecret: 'secret',
      log: LOG,
      error: ERR,
    });

    assert.equal(stats.reconciled, 1);
    const attemptUpdate = db.calls.find((c) => c.col === 'payment_attempts' && c.op === 'update');
    assert.equal(attemptUpdate.data.status, 'expired');
    assert.ok(!db.docs.has(`course_purchases/${EXPECTED_PURCHASE_ID}`));
  });

  test('abandons attempts without a gateway order id', async () => {
    const db = createInMemoryDb();
    db.seed('payment_attempts', 'att_1', buildAttempt({ providerOrderId: null }));

    const stats = await reconcileStuckPaymentAttempts({
      databases: db,
      databaseId: 'olitun_db',
      fetchImpl: createFetchFake('paid'),
      razorpayKeyId: 'key',
      razorpayKeySecret: 'secret',
      log: LOG,
      error: ERR,
    });

    assert.equal(stats.reconciled, 1);
    const attemptUpdate = db.calls.find((c) => c.col === 'payment_attempts' && c.op === 'update');
    assert.equal(attemptUpdate.data.status, 'abandoned');
  });
});
