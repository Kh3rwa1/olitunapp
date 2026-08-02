import { test, describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { createHmac, createHash } from 'crypto';
import { readFileSync } from 'fs';
import { join } from 'path';

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

// Load schema fixtures for schema-aware validation
const paymentClaimsSchema = JSON.parse(readFileSync(join(process.cwd(), 'test/fixtures/schema/payment_claims.json'), 'utf8'));
const refundClaimsSchema = JSON.parse(readFileSync(join(process.cwd(), 'test/fixtures/schema/refund_claims.json'), 'utf8'));

class SchemaAwareInMemDb {
  constructor() {
    this.collections = new Map();
    this.schemas = new Map([
      ['payment_claims', paymentClaimsSchema],
      ['refund_claims', refundClaimsSchema]
    ]);
  }

  validateSchema(col, data) {
    const schema = this.schemas.get(col);
    if (!schema) return; // Unconstrained collections for generic tests

    const allowedKeys = new Set(['$id', '$createdAt', '$updatedAt', ...schema.attributes.map(a => a.key)]);
    for (const key of Object.keys(data)) {
      if (!allowedKeys.has(key)) {
        const err = new Error(`Schema validation error: attribute '${key}' is not declared in '${col}' schema`);
        err.code = 400;
        throw err;
      }
    }
  }

  setDocument(col, id, doc) {
    this.validateSchema(col, doc);
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
    this.validateSchema(col, data);
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
    this.validateSchema(col, updated);
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

describe('Full Schema-Aware Backend Payment Integration Tests', () => {
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

  test('Schema-aware DB rejects undeclared attributes', () => {
    const db = new SchemaAwareInMemDb();
    assert.throws(() => {
      db.validateSchema('refund_claims', {
        refundId: 'ref_1',
        paymentId: 'pay_1',
        providerOrderId: 'INVALID_FIELD' // Not in refund_claims.json
      });
    }, /Schema validation error/);
  });

  test('verifyCoursePurchase full positive verification & claim state mutation', async () => {
    const db = new SchemaAwareInMemDb();
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

    const claimId = stableId(`claim:${paymentId}`);
    const claimDoc = await db.getDocument('olitun_db', 'payment_claims', claimId);
    assert.equal(claimDoc.status, 'committed');
  });

  test('razorpayWebhook refund.processed with authoritative total & interrupted recovery', async () => {
    const db = new SchemaAwareInMemDb();
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

    // Verify refund claim was written to refund_claims and has status 'committed'
    const refundClaimId = stableId('refund:ref_1001');
    const claimDoc = await db.getDocument('olitun_db', 'refund_claims', refundClaimId);
    assert.equal(claimDoc.status, 'committed');
    assert.equal(claimDoc.purchaseId, purchaseId); // Confirmed actual purchaseId!

    // 2. Test Interrupted Claim Recovery: Simulate claim in 'claimed' state
    db.setDocument('refund_claims', refundClaimId, {
      ...claimDoc,
      status: 'claimed'
    });

    const resResume = createMockRes();
    const errorResume = createMockErrorLogger();
    await handler({ req: req1, res: resResume, error: errorResume });

    assert.equal(resResume.statusCode, 200);
    assert.equal(resResume.body.ok, true);

    // Verify claim transitioned back to committed
    const resumedClaimDoc = await db.getDocument('olitun_db', 'refund_claims', refundClaimId);
    assert.equal(resumedClaimDoc.status, 'committed');

    // 3. Test Committed Idempotent Duplicate Replay
    const resCommitted = createMockRes();
    const errorCommitted = createMockErrorLogger();
    await handler({ req: req1, res: resCommitted, error: errorCommitted });

    assert.equal(resCommitted.statusCode, 200);
    assert.match(resCommitted.body.message, /already processed \(committed\)/i);
  });

  test('razorpayWebhook refund.created acknowledges without mutating entitlement', async () => {
    const db = new SchemaAwareInMemDb();
    const purchaseId = stableId('user_C:cat_C');
    db.setDocument('course_purchases', purchaseId, {
      userId: 'user_C',
      categoryId: 'cat_C',
      providerPaymentId: 'pay_C',
      expectedAmount: 100,
      refundedAmountPaise: 0,
      status: 'verified'
    });

    const handler = createRazorpayWebhookHandler({ databases: db });

    const createdPayload = {
      event: 'refund.created',
      payload: {
        refund: {
          entity: {
            id: 'ref_created_1',
            payment_id: 'pay_C',
            amount: 10000,
            status: 'created'
          }
        }
      }
    };
    const rawPayload = JSON.stringify(createdPayload);
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
    assert.match(res.body.message, /acknowledged/i);

    // Ensure course_purchases entitlement WAS NOT MUTATED
    const purchase = await db.getDocument('olitun_db', 'course_purchases', purchaseId);
    assert.equal(purchase.status, 'verified');
    assert.equal(purchase.refundedAmountPaise, 0);
  });

  test('razorpayWebhook fails closed (503) when authoritative refund total is unavailable', async () => {
    const db = new SchemaAwareInMemDb();
    const purchaseId = stableId('user_D:cat_D');
    db.setDocument('course_purchases', purchaseId, {
      userId: 'user_D',
      categoryId: 'cat_D',
      providerPaymentId: 'pay_D',
      expectedAmount: 100,
      refundedAmountPaise: 0,
      status: 'verified'
    });

    // Mock fetch that fails API call
    const failingFetch = async () => ({ ok: false, status: 500, text: async () => 'Error' });

    const handler = createRazorpayWebhookHandler({ databases: db, fetchImpl: failingFetch });

    const payloadWithoutAuthoritativeTotal = {
      event: 'refund.processed',
      payload: {
        refund: {
          entity: {
            id: 'ref_no_total',
            payment_id: 'pay_D',
            amount: 10000,
            status: 'processed'
          }
        }
      }
    };
    const rawPayload = JSON.stringify(payloadWithoutAuthoritativeTotal);
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

    assert.equal(res.statusCode, 503);
    assert.equal(res.body.ok, false);
    assert.match(res.body.message, /unavailable/i);
  });
});
