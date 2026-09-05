import { test } from 'node:test';
import assert from 'node:assert/strict';
import { withPaymentStateGuard } from '../_shared/payment_state.js';
import { MemoryDatabase, withTransactions } from './helpers/transaction_db.js';

const pending = (extra = {}) => ({ userId: 'learner', categoryId: 'course',
  providerOrderId: 'order_one', providerPaymentId: '', expectedAmount: 499,
  currency: 'INR', status: 'created', ...extra });
const grant = { userId: 'learner', categoryId: 'course', providerOrderId: 'order_one',
  providerPaymentId: 'pay_one', expectedAmount: 499, currency: 'INR', status: 'verified' };
const update = (db, data = grant) => db.updateDocument('db', 'course_purchases', 'purchase', data);
const read = db => db.getDocument('db', 'course_purchases', 'purchase');
function setup(extra = {}, event = 'capture') {
  const raw = new MemoryDatabase(pending(extra));
  const tx = withTransactions(raw);
  return { raw, tx, db: withPaymentStateGuard(tx, { event }) };
}

for (const status of ['refunded', 'disputed', 'revoked', 'cancelled', 'unknown']) {
  test(`capture cannot restore ${status}, including an existing committed claim`, async () => {
    const { raw, db, tx } = setup({ status });
    await raw.createDocument('db', 'payment_claims', 'claim', { status: 'committed' });
    await assert.rejects(read(db), { code: 409 });
    await assert.rejects(update(db), { code: 409 });
    assert.equal((await read(raw)).status, status);
    assert.equal(raw.writes.filter(w => w.collection === 'course_purchases').length, 0);
    assert.equal(tx.transactions.size, 0);
  });
}
for (const status of ['created', 'failed']) {
  test(`valid capture verifies ${status} through a transaction`, async () => {
    const { raw, db, tx } = setup({ status });
    assert.equal((await update(db)).status, 'verified');
    assert.equal((await read(raw)).providerPaymentId, 'pay_one');
    assert.equal(tx.transactions.size, 0);
  });
}

test('a verified ledger with full-refund metadata is not an idempotent success', async () => {
  const { db } = setup({ status: 'verified', refundedAmountPaise: 49900 });
  await assert.rejects(read(db), { code: 409 });
  await assert.rejects(update(db), { code: 409 });
});
test('same-payment verified retry is safe; a different payment conflicts', async () => {
  const { db } = setup({ status: 'verified', providerPaymentId: 'pay_one' });
  await update(db);
  await assert.rejects(update(db, { ...grant, providerPaymentId: 'pay_two' }), { code: 409 });
});
for (const terminal of ['refunded', 'disputed', 'revoked']) {
  test(`${terminal} arriving between verification read and commit wins`, async () => {
    const { raw, tx, db } = setup();
    await read(db);
    raw.beforeCommit = async () => {
      raw.beforeCommit = null;
      await raw.updateDocument('db', 'course_purchases', 'purchase', { status: terminal });
    };
    await assert.rejects(update(db), { code: 409 });
    assert.equal((await read(raw)).status, terminal);
    assert.equal(tx.transactions.size, 0);
  });
}
test('gateway-latency race rechecks the latest ledger before staging the write', async () => {
  const { raw, db } = setup();
  await read(db);
  await raw.updateDocument('db', 'course_purchases', 'purchase', { status: 'disputed' });
  await assert.rejects(update(db), { code: 409 });
  assert.equal((await read(raw)).status, 'disputed');
});
test('commit failure rolls back, with no unconditional-update fallback', async () => {
  const { raw, tx, db } = setup();
  raw.failCommit = true;
  await assert.rejects(update(db), { code: 503 });
  assert.equal((await read(raw)).status, 'created');
  assert.equal(raw.writes.length, 0);
  assert.equal(tx.transactions.size, 0);
});
test('unsupported transaction API fails closed', async () => {
  const raw = new MemoryDatabase(pending());
  await assert.rejects(update(withPaymentStateGuard(raw)), { code: 503 });
  assert.equal(raw.writes.length, 0);
});
test('recovery cannot recreate a missing entitlement from a stale attempt', async () => {
  const raw = new MemoryDatabase();
  const db = withPaymentStateGuard(withTransactions(raw));
  await assert.rejects(update(db), { code: 404 });
  await assert.rejects(db.createDocument('db', 'course_purchases', 'purchase', grant), { code: 409 });
  assert.equal(raw.writes.length, 0);
});
for (const field of ['userId', 'categoryId', 'providerOrderId']) {
  test(`recovery/capture rejects a changed ${field}`, async () => {
    const { db } = setup({ [field]: 'replacement' });
    await assert.rejects(update(db), { code: 409 });
  });
}
for (const status of ['verified', 'refunded', 'disputed', 'revoked']) {
  test(`late payment.failed does not downgrade ${status}`, async () => {
    const { raw, db } = setup({ status, providerPaymentId: 'pay_one' }, 'payment.failed');
    await update(db, { status: 'failed' });
    assert.equal((await read(raw)).status, status);
    assert.equal(raw.writes.length, 0);
  });
}
test('partial refund does not restore a disputed entitlement', async () => {
  const { raw, db } = setup({ status: 'disputed', providerPaymentId: 'pay_one' }, 'refund.processed');
  await update(db, { status: 'verified', refundedAmountPaise: 10000, refundEpoch: 1 });
  assert.equal((await read(raw)).status, 'disputed');
});
test('out-of-order partial refund retains full-refund status and total', async () => {
  const { raw, db } = setup({ status: 'refunded', refundedAmountPaise: 49900, refundEpoch: 1 }, 'refund.processed');
  await update(db, { status: 'verified', refundedAmountPaise: 10000, refundEpoch: 2 });
  assert.equal((await read(raw)).status, 'refunded');
  assert.equal((await read(raw)).refundedAmountPaise, 49900);
});
for (const status of ['refunded', 'revoked']) {
  test(`dispute won does not restore ${status}`, async () => {
    const { raw, db } = setup({ status }, 'payment.dispute.won');
    await update(db, { status: 'verified' });
    assert.equal((await read(raw)).status, status);
  });
}
test('legitimate dispute won restores a disputed, non-refunded purchase', async () => {
  const { raw, db } = setup({ status: 'disputed', providerPaymentId: 'pay_one' }, 'payment.dispute.won');
  await update(db, { status: 'verified' });
  assert.equal((await read(raw)).status, 'verified');
});
test('late refund cannot mutate a new order replacing the observed purchase', async () => {
  const { raw, db } = setup({ status: 'verified', providerPaymentId: 'pay_one' }, 'refund.processed');
  await db.listDocuments('db', 'course_purchases');
  await raw.updateDocument('db', 'course_purchases', 'purchase', { providerOrderId: 'order_two', providerPaymentId: '', status: 'created' });
  await assert.rejects(update(db, { status: 'refunded', refundedAmountPaise: 49900, refundEpoch: 1 }), { code: 409 });
  assert.equal((await read(raw)).providerOrderId, 'order_two');
  assert.equal((await read(raw)).status, 'created');
});

test('concurrent capture and dispute conflict; retry leaves access disputed', async () => {
  const { raw, tx, db } = setup();
  const dispute = withPaymentStateGuard(tx, { event: 'payment.dispute.created' });
  const results = await Promise.allSettled([update(db), update(dispute, { status: 'disputed' })]);
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
  assert.equal(results.find(r => r.status === 'rejected').reason.code, 409);
  if ((await read(raw)).status !== 'disputed') await update(dispute, { status: 'disputed' });
  assert.equal((await read(raw)).status, 'disputed');
  await assert.rejects(update(db), { code: 409 });
  assert.equal(tx.transactions.size, 0);
});
