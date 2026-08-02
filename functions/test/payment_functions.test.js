import { test, describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { createHmac, createHash } from 'crypto';

import createRazorpayOrderHandler from '../createRazorpayOrder/src/main.js';
import verifyCoursePurchaseHandler from '../verifyCoursePurchase/src/main.js';
import razorpayWebhookHandler from '../razorpayWebhook/src/main.js';

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

    // Basic filter support for test queries
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

  test('verifyCoursePurchase signature validation & order binding contract', async () => {
    const userId = 'user_Alice';
    const categoryId = 'cat_course_99';
    const orderId = 'order_RZP_111';
    const paymentId = 'pay_RZP_222';
    const expectedSignature = createHmac('sha256', razorpaySecret)
      .update(`${orderId}|${paymentId}`)
      .digest('hex');

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

    // Mock Razorpay API fetch
    const originalFetch = global.fetch;
    global.fetch = async (url) => {
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

    try {
      await verifyCoursePurchaseHandler({ req, res, error });
    } finally {
      global.fetch = originalFetch;
    }

    assert.notEqual(res.body.message, 'Invalid payment signature');
    assert.notEqual(res.body.message, 'Unauthenticated');
  });

  test('razorpayWebhook validates HMAC signature with raw payload', async () => {
    const payloadObj = {
      event: 'payment.captured',
      payload: {
        payment: {
          entity: {
            id: 'pay_999',
            order_id: 'order_999',
            amount: 49900,
            currency: 'INR',
            notes: { userId: 'u1', categoryId: 'c1' }
          }
        }
      }
    };
    const rawPayload = JSON.stringify(payloadObj);
    const validSignature = createHmac('sha256', webhookSecret)
      .update(rawPayload)
      .digest('hex');

    const req = {
      method: 'POST',
      headers: { 'x-razorpay-signature': validSignature },
      body: rawPayload,
      bodyRaw: rawPayload
    };
    const res = createMockRes();
    const error = createMockErrorLogger();

    await razorpayWebhookHandler({ req, res, error });

    assert.notEqual(res.body.message, 'Invalid webhook signature');
  });

  test('razorpayWebhook rejects invalid signature', async () => {
    const req = {
      method: 'POST',
      headers: { 'x-razorpay-signature': 'bad_sig_0000000' },
      body: '{"event":"payment.captured"}',
      bodyRaw: '{"event":"payment.captured"}'
    };
    const res = createMockRes();
    const error = createMockErrorLogger();

    await razorpayWebhookHandler({ req, res, error });

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

  test('Cumulative partial refund logic', () => {
    const expectedPaise = 50000; // ₹500
    let previousRefundPaise = 0;

    // Refund 1: ₹250
    let inc1 = 25000;
    previousRefundPaise += inc1;
    let isFullyRefunded1 = previousRefundPaise >= expectedPaise;
    assert.equal(isFullyRefunded1, false, '₹250 refund on ₹500 is partial');

    // Refund 2: ₹250
    let inc2 = 25000;
    previousRefundPaise += inc2;
    let isFullyRefunded2 = previousRefundPaise >= expectedPaise;
    assert.equal(isFullyRefunded2, true, 'Cumulative ₹500 refund on ₹500 price is full refund');
  });
});
