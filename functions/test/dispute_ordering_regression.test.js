import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { withPaymentStateGuard } from '../_shared/payment_state.js';
import { MemoryDatabase, withTransactions } from './helpers/transaction_db.js';

const purchase = {
  userId: 'user-1', categoryId: 'category-1', providerOrderId: 'order-1',
  providerPaymentId: 'payment-1', status: 'verified', expectedAmount: 500,
  currency: 'INR', refundedAmountPaise: 0,
};
const read = db => db.getDocument('olitun_db', 'course_purchases', 'purchase');
async function apply(db, event, status) {
  const guarded = withPaymentStateGuard(db, { event });
  await guarded.listDocuments('olitun_db', 'course_purchases', []);
  return guarded.updateDocument('olitun_db', 'course_purchases', 'purchase', { status });
}

test('late won notification cannot restore a disputed entitlement', async () => {
  const db = new MemoryDatabase(purchase);
  const transactional = withTransactions(db);
  await apply(transactional, 'payment.dispute.created', 'disputed');
  await apply(transactional, 'payment.dispute.won', 'verified');
  assert.equal((await read(db)).status, 'disputed');
  assert.equal(db.writes.length, 1);
  assert.equal(transactional.transactions.size, 0);
});

test('won before created cannot authorize a later disputed purchase', async () => {
  const db = new MemoryDatabase(purchase);
  const transactional = withTransactions(db);
  await apply(transactional, 'payment.dispute.won', 'verified');
  await apply(transactional, 'payment.dispute.created', 'disputed');
  assert.equal((await read(db)).status, 'disputed');
});

test('legitimate wins remain blocked pending authoritative reconciliation', async () => {
  const db = new MemoryDatabase({ ...purchase, status: 'disputed' });
  await apply(withTransactions(db), 'payment.dispute.won', 'verified');
  assert.equal((await read(db)).status, 'disputed');
  assert.equal(db.writes.length, 0);
});

test('disputes never overwrite terminal refunds or revocations', async () => {
  for (const status of ['refunded', 'revoked']) {
    const db = new MemoryDatabase({ ...purchase, status });
    const transactional = withTransactions(db);
    await apply(transactional, 'payment.dispute.created', 'disputed');
    await apply(transactional, 'payment.dispute.won', 'verified');
    assert.equal((await read(db)).status, status);
  }
});

test('failed commit does not alter the entitlement', async () => {
  const db = new MemoryDatabase(purchase);
  db.failCommit = true;
  const transactional = withTransactions(db);
  await assert.rejects(apply(transactional, 'payment.dispute.created', 'disputed'));
  assert.equal((await read(db)).status, 'verified');
  assert.equal(db.writes.length, 0);
  assert.equal(transactional.transactions.size, 0);
});

test('repurchase binding conflict aborts a delayed dispute', async () => {
  const db = new MemoryDatabase(purchase);
  const transactional = withTransactions(db);
  const guard = withPaymentStateGuard(transactional, { event: 'payment.dispute.created' });
  await guard.listDocuments('olitun_db', 'course_purchases', []);
  await db.updateDocument('olitun_db', 'course_purchases', 'purchase', {
    providerOrderId: 'order-2', providerPaymentId: 'payment-2',
  });
  await assert.rejects(guard.updateDocument('olitun_db', 'course_purchases', 'purchase', { status: 'disputed' }), { code: 409 });
  assert.equal((await read(db)).status, 'verified');
  assert.equal((await read(db)).providerPaymentId, 'payment-2');
});

test('deployed payment guard copies match their canonical source', () => {
  const canonical = readFileSync(new URL('../_shared/payment_state.js', import.meta.url), 'utf8');
  for (const name of ['razorpayWebhook', 'reconcilePaymentAttempts', 'verifyCoursePurchase']) {
    assert.equal(readFileSync(new URL(`../${name}/src/shared/payment_state.js`, import.meta.url), 'utf8'), canonical);
  }
});
