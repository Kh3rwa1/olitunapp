import { beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { createOrderHandler } from '../createRazorpayOrder/src/main.js';
import { publishPendingPurchase } from '../createRazorpayOrder/src/purchase_ledger.js';

const hash = value => createHash('sha256').update(value).digest('hex').slice(0, 32);
const purchaseId = hash('learner:course');
const attemptId = key => `att_${hash(`learner:course:${key}`)}`;
const clone = value => structuredClone(value);
const failure = code => Object.assign(new Error(`Database ${code}`), { code });

class Database {
  constructor() {
    this.tables = new Map();
    this.transactions = new Map();
    this.version = 0;
    this.failNextLedgerCreate = false;
    this.conflictOnCommit = false;
    this.commitFailure = false;
    this.seed('categories', 'course', { priceInr: 499, unlockMode: 'paid_only' });
  }
  seed(collection, id, value) {
    if (!this.tables.has(collection)) this.tables.set(collection, new Map());
    this.tables.get(collection).set(id, { ...clone(value), $id: id });
    this.version++;
  }
  async getDocument(db, collection, id) {
    if (typeof db === 'object') ({ collectionId: collection, documentId: id } = db);
    const row = this.tables.get(collection)?.get(id);
    if (!row) throw failure(404);
    return clone(row);
  }
  async createDocument(db, collection, id, data, permissions = []) {
    if (collection === 'course_purchases' && this.failNextLedgerCreate) {
      this.failNextLedgerCreate = false;
      throw failure(503);
    }
    if (this.tables.get(collection)?.has(id)) throw failure(409);
    this.seed(collection, id, { ...data, $permissions: permissions });
    return this.getDocument(db, collection, id);
  }
  async updateDocument(db, collection, id, data, permissions) {
    if (typeof db === 'object') {
      const txn = this.transactions.get(db.transactionId);
      assert.ok(txn, 'replacement writes must be transactional');
      const old = await this.getDocument(db.databaseId, db.collectionId, db.documentId);
      txn.write = { collection: db.collectionId, id: db.documentId,
        data: { ...old, ...clone(db.data), $permissions: db.permissions } };
      return clone(txn.write.data);
    }
    const old = await this.getDocument(db, collection, id);
    this.seed(collection, id, { ...old, ...data,
      ...(permissions ? { $permissions: permissions } : {}) });
    return this.getDocument(db, collection, id);
  }
  async createTransaction({ ttl }) {
    assert.equal(ttl, 15);
    const id = `tx_${this.transactions.size}`;
    this.transactions.set(id, { version: this.version });
    return { $id: id };
  }
  async updateTransaction({ transactionId, commit, rollback }) {
    const txn = this.transactions.get(transactionId);
    assert.ok(txn);
    if (commit) {
      if (this.commitFailure) throw failure(503);
      if (this.conflictOnCommit || txn.version !== this.version) throw failure(409);
      if (txn.write) this.seed(txn.write.collection, txn.write.id, txn.write.data);
    }
    if (commit || rollback) this.transactions.delete(transactionId);
    return {};
  }
}

const ledger = (overrides = {}) => ({
  userId: 'learner', categoryId: 'course', provider: 'razorpay',
  providerOrderId: 'order_old', providerPaymentId: '', expectedAmount: 499,
  paidAmount: 0, currency: 'INR', status: 'created', createdAt: '2026-09-05T00:00:00Z',
  ...overrides,
});
const response = () => ({
  statusCode: 200, body: null,
  json(body, statusCode = 200) { Object.assign(this, { body, statusCode }); return this; },
});
const request = key => ({ method: 'POST', headers: { 'x-appwrite-user-id': 'learner' },
  body: JSON.stringify({ categoryId: 'course', idempotencyKey: key }) });
async function checkout(handler, key) {
  const res = response();
  await handler({ req: request(key), res, error() {}, log() {} });
  return res;
}
function gateway() {
  let calls = 0;
  return {
    get calls() { return calls; },
    fetch: async (_, options) => {
      const body = JSON.parse(options.body);
      const id = `order_${++calls}`;
      return { ok: true, json: async () => ({ id, amount: body.amount, currency: 'INR' }) };
    },
  };
}

beforeEach(() => {
  process.env.APPWRITE_FUNCTION_API_ENDPOINT = 'https://example.invalid/v1';
  process.env.APPWRITE_FUNCTION_PROJECT_ID = 'test';
  process.env.APPWRITE_FUNCTION_API_KEY = 'test-only';
  process.env.RAZORPAY_KEY_ID = 'test-only';
  process.env.RAZORPAY_KEY_SECRET = 'test-only';
  process.env.PAYMENT_ORDERS_PER_HOUR = '10';
});

test('different checkout keys cannot replace the order already returned to a learner', async () => {
  const db = new Database();
  const api = gateway();
  const handler = createOrderHandler({ databases: db, fetchImpl: api.fetch });
  const first = await checkout(handler, 'device-one');
  const second = await checkout(handler, 'device-two');
  assert.equal(first.statusCode, 200);
  assert.equal(second.statusCode, 200);
  assert.equal(first.body.orderId, second.body.orderId);
  const current = await db.getDocument('', 'course_purchases', purchaseId);
  assert.equal(current.providerOrderId, first.body.orderId);
  assert.equal((await db.getDocument('', 'payment_attempts', attemptId('device-two'))).status, 'superseded');
});

test('simultaneous different keys return one canonical payable order', async () => {
  const db = new Database();
  const api = gateway();
  const handler = createOrderHandler({ databases: db, fetchImpl: api.fetch });
  const results = await Promise.all(['parallel-one', 'parallel-two'].map(key => checkout(handler, key)));
  assert.ok(results.every(res => res.statusCode === 200 && res.body.ok));
  assert.equal(new Set(results.map(res => res.body.orderId)).size, 1);
  assert.equal((await db.getDocument('', 'course_purchases', purchaseId)).providerOrderId, results[0].body.orderId);
});

test('a verified entitlement arriving during gateway creation is never downgraded', async () => {
  const db = new Database();
  const api = gateway();
  const handler = createOrderHandler({ databases: db, fetchImpl: async (...args) => {
    db.seed('course_purchases', purchaseId, ledger({ status: 'verified', providerPaymentId: 'pay_captured', paidAmount: 499 }));
    return api.fetch(...args);
  } });
  const result = await checkout(handler, 'verification-race');
  assert.equal(result.body.ok, false);
  assert.match(result.body.message, /already unlocked/);
  const current = await db.getDocument('', 'course_purchases', purchaseId);
  assert.equal(current.status, 'verified');
  assert.equal(current.providerPaymentId, 'pay_captured');
});

test('idempotent retry uses the original order price after the catalog changes', async () => {
  const db = new Database();
  const api = gateway();
  const handler = createOrderHandler({ databases: db, fetchImpl: api.fetch });
  await checkout(handler, 'price-retry');
  db.seed('categories', 'course', { priceInr: 799, unlockMode: 'paid_only' });
  const result = await checkout(handler, 'price-retry');
  assert.equal(result.body.amount, 49900);
  assert.equal(api.calls, 1);
});

test('retry repairs a missing ledger before returning an order, without a second gateway call', async () => {
  const db = new Database();
  db.failNextLedgerCreate = true;
  const api = gateway();
  const handler = createOrderHandler({ databases: db, fetchImpl: api.fetch });
  const first = await checkout(handler, 'repair-retry');
  assert.equal(first.body.ok, false);
  assert.equal((await db.getDocument('', 'payment_attempts', attemptId('repair-retry'))).status, 'reconciliation_required');
  const retry = await checkout(handler, 'repair-retry');
  assert.equal(retry.statusCode, 200);
  assert.equal(retry.body.ok, true);
  assert.equal(api.calls, 1);
  assert.equal((await db.getDocument('', 'course_purchases', purchaseId)).providerOrderId, retry.body.orderId);
});

test('repeated storage failure never returns an unbound checkout order', async () => {
  const db = new Database();
  const api = gateway();
  const handler = createOrderHandler({ databases: db, fetchImpl: api.fetch });
  for (let i = 0; i < 2; i++) {
    db.failNextLedgerCreate = true;
    const result = await checkout(handler, 'storage-retry');
    assert.equal(result.statusCode, 503);
    assert.equal(result.body.ok, false);
    assert.equal(result.body.orderId, undefined);
  }
  assert.equal(api.calls, 1);
});

test('old checkout retry cannot revive a refunded order or enqueue it for granting', async () => {
  const db = new Database();
  const api = gateway();
  const handler = createOrderHandler({ databases: db, fetchImpl: api.fetch });
  const first = await checkout(handler, 'refund-retry');
  db.seed('course_purchases', purchaseId, ledger({ status: 'refunded', providerOrderId: first.body.orderId, refundedAmountPaise: 49900 }));
  const result = await checkout(handler, 'refund-retry');
  assert.equal(result.statusCode, 409);
  assert.equal(result.body.ok, false);
  assert.equal((await db.getDocument('', 'course_purchases', purchaseId)).status, 'refunded');
  assert.notEqual((await db.getDocument('', 'payment_attempts', attemptId('refund-retry'))).status, 'reconciliation_required');
});

test('a malformed gateway amount fails closed', async () => {
  const db = new Database();
  const handler = createOrderHandler({ databases: db, fetchImpl: async () => ({
    ok: true, json: async () => ({ id: 'wrong_order', amount: 1, currency: 'INR' }),
  }) });
  const result = await checkout(handler, 'malformed-response');
  assert.equal(result.statusCode, 502);
  await assert.rejects(db.getDocument('', 'course_purchases', purchaseId), { code: 404 });
});

test('fractional catalog rupees are rejected instead of violating the integer ledger schema', async () => {
  const db = new Database();
  db.seed('categories', 'course', { priceInr: 499.5, unlockMode: 'paid_only' });
  const api = gateway();
  const result = await checkout(createOrderHandler({ databases: db, fetchImpl: api.fetch }), 'invalid-price');
  assert.equal(result.statusCode, 400);
  assert.equal(api.calls, 0);
});

test('same-key concurrent requests still create at most one gateway order', async () => {
  const db = new Database();
  const api = gateway();
  const handler = createOrderHandler({ databases: db, fetchImpl: api.fetch });
  const results = await Promise.all(Array.from({ length: 20 }, () => checkout(handler, 'same-key-retry')));
  assert.equal(api.calls, 1);
  assert.ok(results.every(res => [200, 409].includes(res.statusCode)));
});

const publish = db => publishPendingPurchase({ databases: db, databaseId: 'db', purchaseId,
  data: ledger({ providerOrderId: 'order_new' }), permissions: ['read("user:learner")'] });

test('refunded repurchase commits atomically and clears the prior refund total', async () => {
  const db = new Database();
  db.seed('course_purchases', purchaseId, ledger({ status: 'refunded', refundStatus: 'fully_refunded', refundedAmountPaise: 49900 }));
  await publish(db);
  const result = await db.getDocument('', 'course_purchases', purchaseId);
  assert.equal(result.providerOrderId, 'order_new');
  assert.equal(result.status, 'created');
  assert.equal(result.refundedAmountPaise, 0);
  assert.equal(result.refundStatus, '');
  assert.equal(db.transactions.size, 0);
});

test('a transaction conflict rolls back without replacing a refunded purchase', async () => {
  const db = new Database();
  db.seed('course_purchases', purchaseId, ledger({ status: 'refunded' }));
  db.conflictOnCommit = true;
  await assert.rejects(publish(db), { code: 409 });
  assert.equal((await db.getDocument('', 'course_purchases', purchaseId)).providerOrderId, 'order_old');
  assert.equal(db.transactions.size, 0);
});

test('transaction service failure fails closed with no plain-update fallback', async () => {
  const db = new Database();
  db.seed('course_purchases', purchaseId, ledger({ status: 'refunded' }));
  db.commitFailure = true;
  await assert.rejects(publish(db), { code: 503 });
  assert.equal((await db.getDocument('', 'course_purchases', purchaseId)).status, 'refunded');
  assert.equal(db.transactions.size, 0);
});

test('purchase ownership mismatch is a conflict, never a replacement', async () => {
  const db = new Database();
  db.seed('course_purchases', purchaseId, ledger({ userId: 'another-learner' }));
  await assert.rejects(publish(db), { code: 409 });
  assert.equal((await db.getDocument('', 'course_purchases', purchaseId)).userId, 'another-learner');
});

test('disputed purchases cannot be silently replaced by checkout', async () => {
  const db = new Database();
  db.seed('course_purchases', purchaseId, ledger({ status: 'disputed' }));
  await assert.rejects(publish(db), { code: 409 });
  assert.equal((await db.getDocument('', 'course_purchases', purchaseId)).status, 'disputed');
});
