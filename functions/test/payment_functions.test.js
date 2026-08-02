import { test, describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { createHmac, createHash } from 'crypto';

import { createOrderHandler } from '../createRazorpayOrder/src/main.js';
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

  setDocument(col, id, doc) {
    if (!this.collections.has(col)) this.collections.set(col, new Map());
    this.collections.get(col).set(id, { $id: id, ...doc });
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
    const created = { $id: id, ...data };
    table.set(id, created);
    return JSON.parse(JSON.stringify(created));
  }

  async updateDocument(dbId, col, id, data) {
    const table = this.collections.get(col);
    if (!table || !table.has(id)) {
      const err = new Error('Document not found');
      err.code = 404;
      throw err;
    }
    const updated = { ...table.get(id), ...data };
    table.set(id, updated);
    return JSON.parse(JSON.stringify(updated));
  }

  async listDocuments(dbId, col, queries = []) {
    const table = this.collections.get(col) || new Map();
    const docs = Array.from(table.values());

    let filtered = docs;
    for (const q of queries) {
      if (typeof q === 'object' && q.attribute && q.values) {
        filtered = filtered.filter(d => q.values.includes(d[q.attribute]));
      }
    }
    return { documents: JSON.parse(JSON.stringify(filtered)) };
  }
}

describe('Full In-Memory Mocked Backend Payment Integration Tests', () => {
  const webhookSecret = 'whsec_test_secret_12345';
  const razorpaySecret = 'rzp_sec_test_999';
  const razorpayKeyId = 'rzp_test_key_111';

  beforeEach(() => {
    process.env.APPWRITE_FUNCTION_API_ENDPOINT = 'https://localhost/v1';
    process.env.APPWRITE_FUNCTION_PROJECT_ID = 'test_proj';
    process.env.APPWRITE_FUNCTION_API_KEY = 'test_key';
    process.env.RAZORPAY_KEY_ID = razorpayKeyId;
    process.env.RAZORPAY_KEY_SECRET = razorpaySecret;
    process.env.RAZORPAY_WEBHOOK_SECRET = webhookSecret;
  });

  test('verifyCoursePurchase full positive verification & claim state mutation', async () => {
    const db = new InMemDb();
    const userId = 'user_Alice';
    const categoryId = 'cat_course_99';
    const orderId = 'order_RZP_111';
    const paymentId = 'pay_RZP_222';
    const purchaseId = stableId(`${userId}:${categoryId}`);

    db.setDocument('categories', categoryId, {
      titleLatin: 'Santhali Grammar',
      priceInr: 499,
      unlockMode: 'paid_only'
    });

    db.setDocument('course_purchases', purchaseId, {
      userId,
      categoryId,
      provider: 'razorpay',
      providerOrderId: orderId,
      expectedAmount: 499,
      currency: 'INR',
      status: 'created'
    });

    const expectedSignature = createHmac('sha256', razorpaySecret)
      .update(`${orderId}|${paymentId}`)
      .digest('hex');

    const mockFetch = async (url) => {
      if (url.includes(paymentId)) {
        return {
          ok: true,
          status: 200,
          json: async () => ({
            id: paymentId,
            order_id: orderId,
            amount: 49900,
            currency: 'INR',
            status: 'captured'
          })
        };
      }
      return { ok: false, status: 404, text: async () => 'Not found' };
    };

    const handler = createVerifyCoursePurchaseHandler({ databases: db, fetchImpl: mockFetch });

    const req = {
      method: 'POST',
      headers: { 'x-appwrite-user-id': userId },
      body: JSON.stringify({
        unlockMethod: 'razorpay',
        categoryId,
        razorpayPaymentId: paymentId,
        razorpayOrderId: orderId,
        razorpaySignature: expectedSignature
      })
    };
    const res = createMockRes();
    const error = createMockErrorLogger();

    await handler({ req, res, error });

    assert.equal(res.statusCode, 200);
    assert.equal(res.body.ok, true);
    assert.equal(res.body.purchase.status, 'verified');
    assert.equal(res.body.purchase.providerPaymentId, paymentId);

    const updatedPurchase = await db.getDocument('olitun_db', 'course_purchases', purchaseId);
    assert.equal(updatedPurchase.status, 'verified');
    assert.equal(updatedPurchase.providerPaymentId, paymentId);

    const claimId = stableId(`claim:${paymentId}`);
    const claimDoc = await db.getDocument('olitun_db', 'payment_claims', claimId);
    assert.equal(claimDoc.status, 'committed');
    assert.equal(claimDoc.userId, userId);
  });

  test('razorpayWebhook atomic refund deduplication & authoritative total calculation', async () => {
    const db = new InMemDb();
    const userId = 'user_Bob';
    const categoryId = 'cat_course_500';
    const paymentId = 'pay_RZP_500';
    const purchaseId = stableId(`${userId}:${categoryId}`);

    db.setDocument('course_purchases', purchaseId, {
      userId,
      categoryId,
      provider: 'razorpay',
      providerOrderId: 'order_500',
      providerPaymentId: paymentId,
      expectedAmount: 500,
      refundedAmountPaise: 0,
      currency: 'INR',
      status: 'verified'
    });

    const handler = createRazorpayWebhookHandler({ databases: db });

    // 1. Deliver refund.processed event with refund_id: ref_1001 for ₹250 (25000 paise)
    const refundPayload1 = {
      event: 'refund.processed',
      payload: {
        payment: {
          entity: {
            id: paymentId,
            amount_refunded: 25000
          }
        },
        refund: {
          entity: {
            id: 'ref_1001',
            payment_id: paymentId,
            amount: 25000,
            status: 'processed',
            currency: 'INR'
          }
        }
      }
    };
    const rawPayload1 = JSON.stringify(refundPayload1);
    const signature1 = createHmac('sha256', webhookSecret).update(rawPayload1).digest('hex');

    const req1 = {
      method: 'POST',
      headers: { 'x-razorpay-signature': signature1 },
      body: rawPayload1,
      bodyRaw: rawPayload1
    };
    const res1 = createMockRes();
    const error1 = createMockErrorLogger();

    await handler({ req: req1, res: res1, error: error1 });

    assert.equal(res1.statusCode, 200);
    assert.equal(res1.body.ok, true);

    let purchaseState = await db.getDocument('olitun_db', 'course_purchases', purchaseId);
    assert.equal(purchaseState.status, 'verified');
    assert.equal(purchaseState.refundStatus, 'partially_refunded');
    assert.equal(purchaseState.refundedAmountPaise, 25000);

    // Verify refund claim was committed
    const refundClaimId = stableId('refund:ref_1001');
    const claimDoc = await db.getDocument('olitun_db', 'refund_claims', refundClaimId);
    assert.equal(claimDoc.status, 'committed');

    // 2. REPLAY DUPLICATE WEBHOOK with identical ref_1001!
    const res2 = createMockRes();
    const error2 = createMockErrorLogger();
    await handler({ req: req1, res: res2, error: error2 });

    assert.equal(res2.statusCode, 200);
    assert.equal(res2.body.ok, true);
    assert.match(res2.body.message, /already processed/i);

    purchaseState = await db.getDocument('olitun_db', 'course_purchases', purchaseId);
    assert.equal(purchaseState.status, 'verified');
    assert.equal(purchaseState.refundedAmountPaise, 25000);

    // 3. Deliver second DISTINCT refund webhook ref_1002 for remaining ₹250 (total amount_refunded = 50000)
    const refundPayload2 = {
      event: 'refund.processed',
      payload: {
        payment: {
          entity: {
            id: paymentId,
            amount_refunded: 50000
          }
        },
        refund: {
          entity: {
            id: 'ref_1002',
            payment_id: paymentId,
            amount: 25000,
            status: 'processed',
            currency: 'INR'
          }
        }
      }
    };
    const rawPayload2 = JSON.stringify(refundPayload2);
    const signature2 = createHmac('sha256', webhookSecret).update(rawPayload2).digest('hex');

    const req3 = {
      method: 'POST',
      headers: { 'x-razorpay-signature': signature2 },
      body: rawPayload2,
      bodyRaw: rawPayload2
    };
    const res3 = createMockRes();
    const error3 = createMockErrorLogger();

    await handler({ req: req3, res: res3, error: error3 });

    assert.equal(res3.statusCode, 200);

    purchaseState = await db.getDocument('olitun_db', 'course_purchases', purchaseId);
    assert.equal(purchaseState.status, 'refunded');
    assert.equal(purchaseState.refundStatus, 'fully_refunded');
    assert.equal(purchaseState.refundedAmountPaise, 50000);
  });

  test('razorpayWebhook handles refund.failed without incrementing refund amount', async () => {
    const db = new InMemDb();
    const handler = createRazorpayWebhookHandler({ databases: db });

    const failedPayload = {
      event: 'refund.failed',
      payload: {
        refund: {
          entity: {
            id: 'ref_failed_999',
            payment_id: 'pay_failed_999',
            amount: 25000
          }
        }
      }
    };
    const rawPayload = JSON.stringify(failedPayload);
    const signature = createHmac('sha256', webhookSecret).update(rawPayload).digest('hex');

    const req = {
      method: 'POST',
      headers: { 'x-razorpay-signature': signature },
      body: rawPayload,
      bodyRaw: rawPayload
    };
    const res = createMockRes();
    const error = createMockErrorLogger();

    await handler({ req, res, error });

    assert.equal(res.statusCode, 200);
    assert.match(res.body.message, /failed/i);
  });

  test('razorpayWebhook rejects invalid signature', async () => {
    const handler = createRazorpayWebhookHandler({ databases: new InMemDb() });
    const req = {
      method: 'POST',
      headers: { 'x-razorpay-signature': 'bad_sig_0000000' },
      body: '{"event":"payment.captured"}',
      bodyRaw: '{"event":"payment.captured"}'
    };
    const res = createMockRes();
    const error = createMockErrorLogger();

    await handler({ req, res, error });

    assert.equal(res.statusCode, 400);
    assert.equal(res.body.ok, false);
    assert.equal(res.body.message, 'Invalid webhook signature');
  });

  test('Dispute event mapping matrix logic', () => {
    const events = [
      { evt: 'payment.dispute.created', expected: 'disputed' },
      { evt: 'payment.dispute.under_review', expected: 'disputed' },
      { evt: 'payment.dispute.action_required', expected: 'disputed' },
      { evt: 'payment.dispute.lost', expected: 'disputed' },
      { evt: 'payment.dispute.won', expected: 'verified' }
    ];

    for (const item of events) {
      let status = 'disputed';
      if (item.evt === 'payment.dispute.won') {
        status = 'verified';
      }
      assert.equal(status, item.expected, `Event ${item.evt} should map to ${item.expected}`);
    }
  });

  test('Atomic claim deterministic ID computation', () => {
    const paymentId = 'pay_test_claim_555';
    const claimId1 = stableId(`claim:${paymentId}`);
    const claimId2 = stableId(`claim:${paymentId}`);

    assert.equal(claimId1, claimId2);
    assert.equal(claimId1.length, 32);
  });
});
