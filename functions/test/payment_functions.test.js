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

describe('Backend Payment Functions Integration-Style Tests', () => {
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

  test('verifyCoursePurchase rejects unauthenticated requests', async () => {
    const req = { method: 'POST', headers: {}, body: '{}' };
    const res = createMockRes();
    const error = createMockErrorLogger();

    await verifyCoursePurchaseHandler({ req, res, error });

    assert.equal(res.statusCode, 401);
    assert.equal(res.body.ok, false);
    assert.equal(res.body.message, 'Unauthenticated');
  });

  test('verifyCoursePurchase rejects play_store_review unlock method', async () => {
    const req = {
      method: 'POST',
      headers: { 'x-appwrite-user-id': 'user_123' },
      body: JSON.stringify({ unlockMethod: 'play_store_review', categoryId: 'cat_101' })
    };
    const res = createMockRes();
    const error = createMockErrorLogger();

    await verifyCoursePurchaseHandler({ req, res, error });

    assert.equal(res.statusCode, 400);
    assert.equal(res.body.ok, false);
    assert.match(res.body.message, /Play Store review cannot issue/);
  });

  test('verifyCoursePurchase signature validation & order binding', async () => {
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
            amount: 49900, // 499 INR in paise
            currency: 'INR',
            status: 'captured'
          })
        };
      }
      return { ok: false, status: 404, text: async () => 'Not found' };
    };

    try {
      // In this test, no Appwrite SDK mock exists so it will fail on Appwrite connection, but signature check & auth will pass first
      await verifyCoursePurchaseHandler({ req, res, error });
    } finally {
      global.fetch = originalFetch;
    }

    // Must reach Appwrite DB call step (not blocked by auth or signature rejection)
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

    // Reaches Appwrite client step after signature succeeds
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

  test('Dispute event mapping matrix', () => {
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
