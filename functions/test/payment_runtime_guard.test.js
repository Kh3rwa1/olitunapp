import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createHash, createHmac } from 'node:crypto';
import { Databases } from 'node-appwrite';
import verify from '../verifyCoursePurchase/src/main.js';
import webhook from '../razorpayWebhook/src/main.js';
import reconcile from '../reconcilePaymentAttempts/src/main.js';
import { MemoryDatabase, withTransactions } from './helpers/transaction_db.js';

const hash = value => createHash('sha256').update(value).digest('hex').slice(0, 32);
const purchaseId = hash('learner:course');
const sign = raw => createHmac('sha256', 'test-only').update(raw).digest('hex');
const ledger = extra => ({ $id: purchaseId, userId: 'learner', categoryId: 'course',
  provider: 'razorpay', providerOrderId: 'order_one', providerPaymentId: '',
  expectedAmount: 499, paidAmount: 0, currency: 'INR', status: 'created', ...extra });
const payment = { id: 'pay_one', order_id: 'order_one', amount: 49900,
  currency: 'INR', status: 'captured', notes: { userId: 'learner', categoryId: 'course' } };
function setup(t, extra = {}) {
  Object.assign(process.env, { APPWRITE_FUNCTION_API_ENDPOINT: 'https://example.invalid/v1',
    APPWRITE_FUNCTION_PROJECT_ID: 'test', APPWRITE_FUNCTION_API_KEY: 'test-only',
    APPWRITE_DATABASE_ID: 'olitun_db', RAZORPAY_KEY_ID: 'test-only',
    RAZORPAY_KEY_SECRET: 'test-only', RAZORPAY_WEBHOOK_SECRET: 'test-only' });
  const raw = new MemoryDatabase();
  raw.docs.set(`course_purchases/${purchaseId}`, ledger(extra));
  const tx = withTransactions(raw);
  // Mock SDK I/O, NOT the production handler factory or state gate. Default
  // Appwrite entrypoints must construct and use the real guarded SDK adapter.
  for (const name of ['getDocument', 'listDocuments', 'createDocument',
    'updateDocument', 'createTransaction', 'updateTransaction']) {
    t.mock.method(Databases.prototype, name, (...args) => tx[name](...args));
  }
  t.mock.method(globalThis, 'fetch', async () => ({ ok: true, json: async () => payment }));
  return { raw, tx, current: () => raw.getDocument('', 'course_purchases', purchaseId) };
}
async function run(handler, req) {
  const res = { status: 200, body: null, json(body, status = 200) {
    Object.assign(this, { body, status }); return this;
  } };
  await handler({ req, res, log() {}, error() {} });
  return res;
}
const verifyRequest = () => ({ method: 'POST', headers: { 'x-appwrite-user-id': 'learner' },
  body: JSON.stringify({ unlockMethod: 'razorpay', categoryId: 'course',
    razorpayPaymentId: 'pay_one', razorpayOrderId: 'order_one', razorpaySignature: sign('order_one|pay_one') }) });
function webhookRequest(event, payload) {
  const raw = JSON.stringify({ event, payload });
  return { method: 'POST', body: raw, bodyRaw: raw, headers: { 'x-razorpay-signature': sign(raw) } };
}
for (const status of ['refunded', 'disputed', 'revoked']) {
  test(`default verification entrypoint rejects ${status}`, async t => {
    const { current } = setup(t, { status });
    const result = await run(verify, verifyRequest());
    assert.equal(result.status, 409);
    assert.equal((await current()).status, status);
  });
}
test('default verification entrypoint commits a valid purchase and payment claim', async t => {
  const { raw, tx, current } = setup(t);
  const result = await run(verify, verifyRequest());
  assert.equal(result.status, 200);
  assert.equal((await current()).status, 'verified');
  assert.equal((await raw.getDocument('', 'payment_claims', hash('claim:pay_one'))).status, 'committed');
  assert.equal(tx.transactions.size, 0);
});
test('default verification entrypoint rejects a committed-claim replay against pending state', async t => {
  const { raw, current } = setup(t);
  await raw.createDocument('', 'payment_claims', hash('claim:pay_one'), {
    paymentId: 'pay_one', purchaseId, providerOrderId: 'order_one', userId: 'learner',
    categoryId: 'course', status: 'committed',
  });
  assert.equal((await run(verify, verifyRequest())).status, 409);
  assert.equal((await current()).status, 'created');
});
test('default webhook entrypoint rejects late capture after dispute', async t => {
  const { current } = setup(t, { status: 'disputed', providerPaymentId: 'pay_one' });
  const result = await run(webhook, webhookRequest('payment.captured', { payment: { entity: payment } }));
  assert.equal(result.status, 503);
  assert.equal((await current()).status, 'disputed');
});
test('default webhook entrypoint preserves dispute on partial refund', async t => {
  const { current } = setup(t, { status: 'disputed', providerPaymentId: 'pay_one' });
  const result = await run(webhook, webhookRequest('refund.processed', {
    payment: { entity: { ...payment, amount_refunded: 10000 } },
    refund: { entity: { id: 'refund_one', payment_id: 'pay_one', amount: 10000, currency: 'INR' } },
  }));
  assert.equal(result.status, 200);
  assert.equal((await current()).status, 'disputed');
  assert.equal((await current()).refundedAmountPaise, 10000);
});
test('default recovery entrypoint cannot restore a refunded purchase', async t => {
  const { raw, current } = setup(t, { status: 'refunded', providerPaymentId: 'pay_one' });
  await raw.createDocument('', 'payment_attempts', 'attempt', { userId: 'learner', categoryId: 'course',
    providerOrderId: 'order_one', expectedAmount: 499, currency: 'INR', status: 'reconciliation_required' });
  t.mock.method(globalThis, 'fetch', async url => ({ ok: true,
    json: async () => String(url).endsWith('/payments') ? { items: [payment] } : { status: 'paid' } }));
  const result = await run(reconcile, {});
  assert.equal(result.body.stats.failed, 1);
  assert.equal(result.body.stats.reconciled, 0);
  assert.equal((await current()).status, 'refunded');
});
