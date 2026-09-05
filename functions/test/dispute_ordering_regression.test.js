import { test } from 'node:test';
import assert from 'node:assert/strict';
import { withPaymentStateGuard } from '../_shared/payment_state.js';

class TransactionalDb {
  constructor(doc) { this.doc = { ...doc }; this.writes = []; }
  async listDocuments() { return { documents: [{ ...this.doc }] }; }
  async getDocument() { return { ...this.doc }; }
  async createTransaction() { return { $id: 'tx_test' }; }
  async updateTransaction() { return {}; }
  async updateDocument(arg, col, id, data) {
    const patch = typeof arg === 'object' ? arg.data : data;
    this.doc = { ...this.doc, ...patch };
    this.writes.push(patch);
    return { ...this.doc };
  }
}

async function apply(db, event, status) {
  const guarded = withPaymentStateGuard(db, { event });
  const listed = await guarded.listDocuments('olitun_db', 'course_purchases', []);
  await guarded.updateDocument(
    'olitun_db',
    'course_purchases',
    listed.documents[0].$id,
    { status },
  );
}

test('stale dispute.won cannot restore a later disputed entitlement', async () => {
  const db = new TransactionalDb({
    $id: 'purchase_1',
    status: 'verified',
    expectedAmount: 500,
    refundedAmountPaise: 0,
  });

  await apply(db, 'payment.dispute.created', 'disputed');
  assert.equal(db.doc.status, 'disputed');

  await apply(db, 'payment.dispute.won', 'verified');
  assert.equal(db.doc.status, 'disputed');
  assert.equal(db.writes.length, 1, 'restorative webhook must be a no-op');
});

test('dispute events cannot overwrite a terminal full refund', async () => {
  const db = new TransactionalDb({
    $id: 'purchase_refunded',
    status: 'refunded',
    refundStatus: 'fully_refunded',
    expectedAmount: 500,
    refundedAmountPaise: 50000,
  });

  await apply(db, 'payment.dispute.created', 'disputed');
  await apply(db, 'payment.dispute.won', 'verified');
  assert.equal(db.doc.status, 'refunded');
  assert.ok(db.writes.every((write) => write.status === 'refunded'));
});
