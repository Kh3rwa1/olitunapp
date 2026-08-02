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

const paymentClaimsSchema = JSON.parse(readFileSync(join(process.cwd(), 'test/fixtures/schema/payment_claims.json'), 'utf8'));
const refundClaimsSchema = JSON.parse(readFileSync(join(process.cwd(), 'test/fixtures/schema/refund_claims.json'), 'utf8'));
const coursePurchasesSchema = JSON.parse(readFileSync(join(process.cwd(), 'test/fixtures/schema/course_purchases.json'), 'utf8'));

class SchemaAwareInMemDb {
  constructor() {
    this.collections = new Map();
    this.schemas = new Map([
      ['payment_claims', paymentClaimsSchema],
      ['refund_claims', refundClaimsSchema],
      ['course_purchases', coursePurchasesSchema]
    ]);
  }

  validateSchema(col, data, isUpdate = false) {
    const schema = this.schemas.get(col);
    if (!schema) return;

    const allowedKeys = new Set(['$id', '$createdAt', '$updatedAt', ...schema.attributes.map(a => a.key)]);
    for (const key of Object.keys(data)) {
      if (!allowedKeys.has(key)) {
        const err = new Error(`Schema validation error: attribute '${key}' is not declared in '${col}' schema`);
        err.code = 400;
        throw err;
      }
    }

    if (!isUpdate) {
      for (const attr of schema.attributes) {
        if (attr.required && (data[attr.key] === undefined || data[attr.key] === null)) {
          const err = new Error(`Schema validation error: required attribute '${attr.key}' is missing in '${col}'`);
          err.code = 400;
          throw err;
        }
      }
    }

    for (const attr of schema.attributes) {
      const val = data[attr.key];
      if (val !== undefined && val !== null) {
        if (attr.type === 'string') {
          if (typeof val !== 'string') {
            const err = new Error(`Schema type error: attribute '${attr.key}' in '${col}' must be string`);
            err.code = 400;
            throw err;
          }
          if (attr.size && val.length > attr.size) {
            const err = new Error(`Schema size error: attribute '${attr.key}' in '${col}' exceeds max size ${attr.size}`);
            err.code = 400;
            throw err;
          }
        } else if (attr.type === 'integer') {
          if (typeof val !== 'number' || !Number.isInteger(val)) {
            const err = new Error(`Schema type error: attribute '${attr.key}' in '${col}' must be integer`);
            err.code = 400;
            throw err;
          }
        }
      }
    }
  }

  checkUniqueIndexes(col, id, data) {
    const schema = this.schemas.get(col);
    if (!schema || !schema.indexes) return;

    const table = this.collections.get(col) || new Map();
    const existingDocs = Array.from(table.values()).filter(d => d.$id !== id);

    for (const idx of schema.indexes) {
      if (idx.type === 'unique') {
        for (const existing of existingDocs) {
          const isMatch = idx.attributes.every(attr => existing[attr] === data[attr]);
          if (isMatch) {
            const err = new Error(`Unique index violation on '${idx.key}' in '${col}'`);
            err.code = 409;
            throw err;
          }
        }
      }
    }
  }

  setDocument(col, id, doc) {
    this.validateSchema(col, doc, false);
    this.checkUniqueIndexes(col, id, doc);
    if (!this.collections.has(col)) this.collections.set(col, new Map());
    const existing = this.collections.get(col).get(id) || {};
    this.collections.get(col).set(id, { $createdAt: new Date().toISOString(), ...existing, ...doc, $id: id });
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
    this.validateSchema(col, data, false);
    this.checkUniqueIndexes(col, id, data);
    if (!this.collections.has(col)) this.collections.set(col, new Map());
    const table = this.collections.get(col);
    if (table.has(id)) {
      const err = new Error('Document already exists');
      err.code = 409;
      throw err;
    }
    const created = { $id: id, $createdAt: new Date().toISOString(), ...data };
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
    this.validateSchema(col, updated, true);
    this.checkUniqueIndexes(col, id, updated);
    table.set(id, updated);
    return JSON.parse(JSON.stringify(updated));
  }

  async deleteDocument(dbId, col, id) {
    const table = this.collections.get(col);
    if (!table || !table.has(id)) {
      const err = new Error('Document not found');
      err.code = 404;
      throw err;
    }
    table.delete(id);
    return true;
  }

  async listDocuments(dbId, col, queries = []) {
    const table = this.collections.get(col) || new Map();
    let docs = Array.from(table.values());

    let hasOrderDescCreatedAt = false;
    for (const q of queries) {
      if (typeof q === 'object' && q !== null) {
        const method = q.method || q.type;
        if (method === 'startsWith') {
          const sAttr = q.attribute;
          const sVal = Array.isArray(q.values) ? q.values[0] : q.values;
          docs = docs.filter(d => String(d[sAttr] || '').startsWith(sVal));
        } else if (method === 'orderDesc' || method === 'orderAsc') {
          hasOrderDescCreatedAt = true;
        } else if (method === 'equal' && q.attribute && Array.isArray(q.values)) {
          docs = docs.filter(d => q.values.includes(d[q.attribute]));
        }
      } else if (typeof q === 'string') {
        if (q.includes('orderDesc("$createdAt")')) {
          hasOrderDescCreatedAt = true;
        }
        const startsWithMatch = q.match(/^startsWith\("([^"]+)",\s*\[?"?([^"\]]+)"?\]?\)/);
        if (startsWithMatch) {
          const sAttr = startsWithMatch[1];
          const sVal = startsWithMatch[2];
          docs = docs.filter(d => String(d[sAttr] || '').startsWith(sVal));
        } else {
          const match = q.match(/^equal\("([^"]+)",\s*\[?"?([^"\]]+)"?\]?\)/);
          if (match) {
            docs = docs.filter(d => d[match[1]] === match[2]);
          }
        }
      }
    }

    if (hasOrderDescCreatedAt) {
      docs.sort((a, b) => new Date(b.claimedAt || b.$createdAt || 0).getTime() - new Date(a.claimedAt || a.$createdAt || 0).getTime());
    }

    return { documents: JSON.parse(JSON.stringify(docs)) };
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

  test('1. Schema-aware DB validates course_purchases required fields, types, and unique indexes', () => {
    const db = new SchemaAwareInMemDb();

    assert.doesNotThrow(() => {
      db.setDocument('course_purchases', 'p1', {
        userId: 'u1',
        categoryId: 'c1',
        provider: 'razorpay',
        providerOrderId: 'order_1',
        expectedAmount: 499,
        paidAmount: 499,
        currency: 'INR',
        status: 'verified',
        createdAt: '2026-08-02T00:00:00Z'
      });
    });

    assert.throws(() => {
      db.setDocument('course_purchases', 'p2', {
        userId: 'u2',
        status: 'verified'
      });
    }, /required attribute/);

    assert.throws(() => {
      db.setDocument('course_purchases', 'p3', {
        userId: 'u1',
        categoryId: 'c1',
        provider: 'razorpay',
        providerOrderId: 'order_3',
        expectedAmount: 499,
        paidAmount: 499,
        currency: 'INR',
        status: 'created',
        createdAt: '2026-08-02T00:00:00Z'
      });
    }, /Unique index violation/);
  });

  test('2. verifyCoursePurchase full positive verification & claim state mutation', async () => {
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
      paidAmount: 0,
      currency: 'INR',
      status: 'created',
      createdAt: new Date().toISOString()
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

  test('3. razorpayWebhook payment.captured processes atomically to committed claim', async () => {
    const db = new SchemaAwareInMemDb();
    const userId = 'user_Bob';
    const categoryId = 'cat_course_bob';
    const orderId = 'order_RZP_bob';
    const paymentId = 'pay_RZP_bob';
    const purchaseId = stableId(`${userId}:${categoryId}`);

    db.setDocument('course_purchases', purchaseId, {
      userId,
      categoryId,
      provider: 'razorpay',
      providerOrderId: orderId,
      expectedAmount: 299,
      paidAmount: 0,
      currency: 'INR',
      status: 'created',
      createdAt: new Date().toISOString()
    });

    const handler = createRazorpayWebhookHandler({ databases: db });

    const payload = {
      event: 'payment.captured',
      payload: {
        payment: {
          entity: {
            id: paymentId,
            order_id: orderId,
            amount: 29900,
            currency: 'INR',
            notes: { userId, categoryId }
          }
        }
      }
    };
    const rawPayload = JSON.stringify(payload);
    const signature = createHmac('sha256', webhookSecret).update(rawPayload).digest('hex');

    const req = { method: 'POST', headers: { 'x-razorpay-signature': signature }, body: rawPayload, bodyRaw: rawPayload };
    const res = createMockRes();

    await handler({ req, res, error: createMockErrorLogger() });

    assert.equal(res.statusCode, 200);
    assert.equal(res.body.ok, true);

    const claimId = stableId(`claim:${paymentId}`);
    const claimDoc = await db.getDocument('olitun_db', 'payment_claims', claimId);
    assert.equal(claimDoc.status, 'committed');
  });

  test('4. Idempotent retry repairs payment_claim if left in claimed state', async () => {
    const db = new SchemaAwareInMemDb();
    const userId = 'user_Repair';
    const categoryId = 'cat_course_repair';
    const paymentId = 'pay_RZP_repair';
    const orderId = 'order_RZP_repair';
    const purchaseId = stableId(`${userId}:${categoryId}`);
    const claimId = stableId(`claim:${paymentId}`);

    db.setDocument('course_purchases', purchaseId, {
      userId, categoryId, provider: 'razorpay', providerOrderId: orderId, providerPaymentId: paymentId,
      expectedAmount: 500, paidAmount: 500, currency: 'INR', status: 'verified', createdAt: new Date().toISOString()
    });

    db.setDocument('payment_claims', claimId, {
      paymentId, purchaseId, providerOrderId: orderId, userId, categoryId, status: 'claimed', claimedAt: new Date().toISOString()
    });

    const handler = createRazorpayWebhookHandler({ databases: db });

    const payload = {
      event: 'payment.captured',
      payload: {
        payment: { entity: { id: paymentId, order_id: orderId, amount: 50000, currency: 'INR', notes: { userId, categoryId } } }
      }
    };
    const raw = JSON.stringify(payload);
    const sig = createHmac('sha256', webhookSecret).update(raw).digest('hex');

    const req = { method: 'POST', headers: { 'x-razorpay-signature': sig }, body: raw, bodyRaw: raw };
    const res = createMockRes();

    await handler({ req, res, error: createMockErrorLogger() });

    assert.equal(res.statusCode, 200);
    assert.equal(res.body.message, 'Already processed');

    const claimDoc = await db.getDocument('olitun_db', 'payment_claims', claimId);
    assert.equal(claimDoc.status, 'committed');
  });

  test('5. Per-payment atomic lock rejects active concurrent refund execution on same payment with 503', async () => {
    const db = new SchemaAwareInMemDb();
    const paymentId = 'pay_lock_test';
    const purchaseId = stableId('user_lock:cat_lock');

    db.setDocument('course_purchases', purchaseId, {
      userId: 'user_lock', categoryId: 'cat_lock', provider: 'razorpay', providerOrderId: 'order_lock',
      providerPaymentId: paymentId, expectedAmount: 500, paidAmount: 500, refundedAmountPaise: 0,
      currency: 'INR', status: 'verified', createdAt: new Date().toISOString()
    });

    const epoch1Id = stableId(`lock:payment:${paymentId}:epoch:1`);
    db.setDocument('refund_claims', epoch1Id, {
      refundId: `lock:${paymentId}:epoch:1`, paymentId, purchaseId, amountPaise: 0, currency: 'INR',
      status: 'locked', claimedAt: new Date(Date.now() - 5000).toISOString(), lastError: 'owner1|epoch:1'
    });

    const handler = createRazorpayWebhookHandler({ databases: db });

    const payload = {
      event: 'refund.processed',
      payload: {
        payment: { entity: { id: paymentId, amount_refunded: 25000 } },
        refund: { entity: { id: 'ref_different_99', payment_id: paymentId, amount: 25000, status: 'processed', currency: 'INR' } }
      }
    };
    const raw = JSON.stringify(payload);
    const sig = createHmac('sha256', webhookSecret).update(raw).digest('hex');

    const req = { method: 'POST', headers: { 'x-razorpay-signature': sig }, body: raw, bodyRaw: raw };
    const res = createMockRes();

    await handler({ req, res, error: createMockErrorLogger() });

    assert.equal(res.statusCode, 503);
    assert.equal(res.body.ok, false);
    assert.match(res.body.message, /Payment ledger update in progress/i);
  });

  test('6. Cross-epoch stale worker fencing with refundEpoch token prevents ledger regression', async () => {
    const db = new SchemaAwareInMemDb();
    const paymentId = 'pay_fence_epoch_token_99';
    const purchaseId = stableId('u_fence:c_fence');

    // Purchase ledger starts at refundEpoch = 0
    db.setDocument('course_purchases', purchaseId, {
      userId: 'u_fence', categoryId: 'c_fence', provider: 'razorpay', providerOrderId: 'o_fence',
      providerPaymentId: paymentId, expectedAmount: 500, paidAmount: 500, refundedAmountPaise: 0,
      refundEpoch: 0, currency: 'INR', status: 'verified', createdAt: new Date().toISOString()
    });

    // Epoch 1 lock exists and is expired (> 60s)
    const epoch1Id = stableId(`lock:payment:${paymentId}:epoch:1`);
    db.setDocument('refund_claims', epoch1Id, {
      refundId: `lock:${paymentId}:epoch:1`, paymentId, purchaseId, amountPaise: 0, currency: 'INR',
      status: 'locked', claimedAt: new Date(Date.now() - 70000).toISOString(), lastError: 'worker1|epoch:1'
    });

    // Worker 2 takes over: creates Epoch 2 lock, updates purchase ledger to 50000 paise and refundEpoch = 2
    const handler2 = createRazorpayWebhookHandler({ databases: db });

    const payload2 = {
      event: 'refund.processed',
      payload: {
        payment: { entity: { id: paymentId, amount_refunded: 50000 } },
        refund: { entity: { id: 'ref_w2_500', payment_id: paymentId, amount: 50000, status: 'processed', currency: 'INR' } }
      }
    };
    const raw2 = JSON.stringify(payload2);
    const sig2 = createHmac('sha256', webhookSecret).update(raw2).digest('hex');

    await handler2({
      req: { method: 'POST', headers: { 'x-razorpay-signature': sig2 }, body: raw2, bodyRaw: raw2 },
      res: createMockRes(),
      error: createMockErrorLogger()
    });

    // Verify Worker 2 updated purchase ledger to 50000 paise and set refundEpoch = 2
    let purchase = await db.getDocument('olitun_db', 'course_purchases', purchaseId);
    assert.equal(purchase.status, 'refunded');
    assert.equal(purchase.refundedAmountPaise, 50000);
    assert.equal(purchase.refundEpoch, 2);

    // Verify active Epoch 2 lock rejects concurrent worker with 503
    const epoch2Id = stableId(`lock:payment:${paymentId}:epoch:2`);
    db.setDocument('refund_claims', epoch2Id, {
      refundId: `lock:${paymentId}:epoch:2`, paymentId, purchaseId, amountPaise: 0, currency: 'INR',
      status: 'locked', claimedAt: new Date().toISOString(), lastError: 'worker2|epoch:2'
    });

    const handlerActiveConflict = createRazorpayWebhookHandler({ databases: db });
    const payloadConflict = {
      event: 'refund.processed',
      payload: {
        payment: { entity: { id: paymentId, amount_refunded: 25000 } },
        refund: { entity: { id: 'ref_conflict_99', payment_id: paymentId, amount: 25000, status: 'processed', currency: 'INR' } }
      }
    };
    const rawConflict = JSON.stringify(payloadConflict);
    const sigConflict = createHmac('sha256', webhookSecret).update(rawConflict).digest('hex');
    const resConflict = createMockRes();

    await handlerActiveConflict({
      req: { method: 'POST', headers: { 'x-razorpay-signature': sigConflict }, body: rawConflict, bodyRaw: rawConflict },
      res: resConflict,
      error: createMockErrorLogger()
    });

    // Active lock conflict correctly rejected with 503
    assert.equal(resConflict.statusCode, 503);
    assert.match(resConflict.body.message, /Payment ledger update in progress/i);

    // Now test a stalled Worker 1 resuming execution past lock acquisition with targetEpoch = 1
    const dbStalledWorker = new SchemaAwareInMemDb();
    dbStalledWorker.setDocument('course_purchases', purchaseId, {
      userId: 'u_fence', categoryId: 'c_fence', provider: 'razorpay', providerOrderId: 'o_fence',
      providerPaymentId: paymentId, expectedAmount: 500, paidAmount: 500, refundedAmountPaise: 50000,
      refundEpoch: 2, currency: 'INR', status: 'refunded', createdAt: new Date().toISOString()
    });

    const epoch1IdStalled = stableId(`lock:payment:${paymentId}:epoch:1`);
    dbStalledWorker.setDocument('refund_claims', epoch1IdStalled, {
      refundId: `lock:${paymentId}:epoch:1`, paymentId, purchaseId, amountPaise: 0, currency: 'INR',
      status: 'locked', claimedAt: new Date().toISOString(), lastError: 'worker1|epoch:1'
    });

    // Mock DB wrapper where lock discovery returns no higher locks (so targetEpoch = 1)
    const dbMockStalled = {
      ...dbStalledWorker,
      listDocuments: async (dbId, col, queries) => {
        if (col === 'refund_claims' && queries.some(q => typeof q === 'object' && q.attribute === 'refundId')) {
          return { documents: [] }; // No higher locks found -> targetEpoch = 1
        }
        return dbStalledWorker.listDocuments(dbId, col, queries);
      },
      createDocument: async (dbId, col, id, data) => {
        return { $id: id, ...data };
      },
      getDocument: async (dbId, col, id) => {
        return dbStalledWorker.getDocument(dbId, col, id);
      },
      updateDocument: async (dbId, col, id, data) => {
        return dbStalledWorker.updateDocument(dbId, col, id, data);
      }
    };

    const handlerStalledWorker1 = createRazorpayWebhookHandler({ databases: dbMockStalled });
    const payloadStalled = {
      event: 'refund.processed',
      payload: {
        payment: { entity: { id: paymentId, amount_refunded: 25000 } },
        refund: { entity: { id: 'ref_stale_w1', payment_id: paymentId, amount: 25000, status: 'processed', currency: 'INR' } }
      }
    };
    const rawStalled = JSON.stringify(payloadStalled);
    const sigStalled = createHmac('sha256', webhookSecret).update(rawStalled).digest('hex');
    const resStalled = createMockRes();

    await handlerStalledWorker1({
      req: { method: 'POST', headers: { 'x-razorpay-signature': sigStalled }, body: rawStalled, bodyRaw: rawStalled },
      res: resStalled,
      error: createMockErrorLogger()
    });

    // Worker 1 is FENCED by defense-in-depth fencing guards! Responds HTTP 503 and leaves purchase ledger untouched at 50000 paise!
    assert.equal(resStalled.statusCode, 503);
    assert.match(resStalled.body.message, /Payment ledger update in progress|Stale epoch update prevented|Payment lock invalidated/i);

    // Purchase ledger remains protected at 50000 paise & refundEpoch 2
    purchase = await dbStalledWorker.getDocument('olitun_db', 'course_purchases', purchaseId);
    assert.equal(purchase.status, 'refunded');
    assert.equal(purchase.refundedAmountPaise, 50000);
    assert.equal(purchase.refundEpoch, 2);
  });

  test('7. Query.startsWith("refundId", "lock:") discriminator isolates epoch lock records even when 30+ refund claims exist', async () => {
    const db = new SchemaAwareInMemDb();
    const paymentId = 'pay_discriminator_test';
    const purchaseId = stableId('u_disc:c_disc');

    db.setDocument('course_purchases', purchaseId, {
      userId: 'u_disc', categoryId: 'c_disc', provider: 'razorpay', providerOrderId: 'o_disc',
      providerPaymentId: paymentId, expectedAmount: 500, paidAmount: 500, refundedAmountPaise: 0,
      currency: 'INR', status: 'verified', createdAt: new Date().toISOString()
    });

    // Create Epoch 1 lock (unlocked/expired)
    db.setDocument('refund_claims', stableId(`lock:payment:${paymentId}:epoch:1`), {
      refundId: `lock:${paymentId}:epoch:1`, paymentId, purchaseId, amountPaise: 0, currency: 'INR',
      status: 'unlocked', claimedAt: new Date(Date.now() - 100000).toISOString()
    });

    // Create 30 ordinary refund claims (simulating heavy refund history)
    for (let i = 1; i <= 30; i++) {
      db.setDocument('refund_claims', stableId(`refund:rfnd_${i}`), {
        refundId: `rfnd_${i}`, paymentId, purchaseId, amountPaise: 1000, currency: 'INR',
        status: 'committed', claimedAt: new Date(Date.now() - 50000 + i).toISOString()
      });
    }

    const handler = createRazorpayWebhookHandler({ databases: db });

    const payload = {
      event: 'refund.processed',
      payload: {
        payment: { entity: { id: paymentId, amount_refunded: 50000 } },
        refund: { entity: { id: 'ref_latest_99', payment_id: paymentId, amount: 50000, status: 'processed', currency: 'INR' } }
      }
    };
    const raw = JSON.stringify(payload);
    const sig = createHmac('sha256', webhookSecret).update(raw).digest('hex');

    const req = { method: 'POST', headers: { 'x-razorpay-signature': sig }, body: raw, bodyRaw: raw };
    const res = createMockRes();

    await handler({ req, res, error: createMockErrorLogger() });

    assert.equal(res.statusCode, 200);

    // Verify Epoch 2 lock was discovered and created!
    const epoch2Doc = await db.getDocument('olitun_db', 'refund_claims', stableId(`lock:payment:${paymentId}:epoch:2`));
    assert.equal(epoch2Doc.refundId, `lock:${paymentId}:epoch:2`);
  });

  test('8. payment.failed event binds strictly to matching orderId', async () => {
    const db = new SchemaAwareInMemDb();
    const userId = 'user_fail_test';
    const categoryId = 'cat_fail_test';
    const purchaseId = stableId(`${userId}:${categoryId}`);

    db.setDocument('course_purchases', purchaseId, {
      userId, categoryId, provider: 'razorpay', providerOrderId: 'order_correct_123',
      expectedAmount: 500, paidAmount: 0, currency: 'INR', status: 'created', createdAt: new Date().toISOString()
    });

    const handler = createRazorpayWebhookHandler({ databases: db });

    const mismatchPayload = {
      event: 'payment.failed',
      payload: {
        payment: { entity: { id: 'pay_failed_1', order_id: 'order_WRONG_999', notes: { userId, categoryId }, error_description: 'Card declined' } }
      }
    };
    const rawMismatch = JSON.stringify(mismatchPayload);
    const sigMismatch = createHmac('sha256', webhookSecret).update(rawMismatch).digest('hex');

    await handler({
      req: { method: 'POST', headers: { 'x-razorpay-signature': sigMismatch }, body: rawMismatch, bodyRaw: rawMismatch },
      res: createMockRes(),
      error: createMockErrorLogger()
    });

    let purchase = await db.getDocument('olitun_db', 'course_purchases', purchaseId);
    assert.equal(purchase.status, 'created');

    const matchPayload = {
      event: 'payment.failed',
      payload: {
        payment: { entity: { id: 'pay_failed_2', order_id: 'order_correct_123', notes: { userId, categoryId }, error_description: 'Card declined' } }
      }
    };
    const rawMatch = JSON.stringify(matchPayload);
    const sigMatch = createHmac('sha256', webhookSecret).update(rawMatch).digest('hex');

    await handler({
      req: { method: 'POST', headers: { 'x-razorpay-signature': sigMatch }, body: rawMatch, bodyRaw: rawMatch },
      res: createMockRes(),
      error: createMockErrorLogger()
    });

    purchase = await db.getDocument('olitun_db', 'course_purchases', purchaseId);
    assert.equal(purchase.status, 'failed');
    assert.equal(purchase.failureReason, 'Card declined');
  });

  test('9. refund.processed two-phase claim & interrupted recovery', async () => {
    const db = new SchemaAwareInMemDb();
    const paymentId = 'pay_recovery_11';
    const refundId = 'ref_interrupted_11';
    const purchaseId = stableId('u_rec:c_rec');

    db.setDocument('course_purchases', purchaseId, {
      userId: 'u_rec', categoryId: 'c_rec', provider: 'razorpay', providerOrderId: 'o_rec',
      providerPaymentId: paymentId, expectedAmount: 500, paidAmount: 500, refundedAmountPaise: 0,
      currency: 'INR', status: 'verified', createdAt: new Date().toISOString()
    });

    const claimId = stableId(`refund:${refundId}`);
    db.setDocument('refund_claims', claimId, {
      refundId, paymentId, purchaseId, amountPaise: 50000, currency: 'INR',
      status: 'claimed', claimedAt: new Date().toISOString()
    });

    const handler = createRazorpayWebhookHandler({ databases: db });

    const payload = {
      event: 'refund.processed',
      payload: {
        payment: { entity: { id: paymentId, amount_refunded: 50000 } },
        refund: { entity: { id: refundId, payment_id: paymentId, amount: 50000, status: 'processed', currency: 'INR' } }
      }
    };
    const raw = JSON.stringify(payload);
    const sig = createHmac('sha256', webhookSecret).update(raw).digest('hex');

    const req = { method: 'POST', headers: { 'x-razorpay-signature': sig }, body: raw, bodyRaw: raw };
    const res = createMockRes();

    await handler({ req, res, error: createMockErrorLogger() });

    assert.equal(res.statusCode, 200);

    const claimDoc = await db.getDocument('olitun_db', 'refund_claims', claimId);
    assert.equal(claimDoc.status, 'committed');

    const purchase = await db.getDocument('olitun_db', 'course_purchases', purchaseId);
    assert.equal(purchase.status, 'refunded');
  });

  test('10. Monotonic non-decreasing calculation retains higher refund total on out-of-order delivery', async () => {
    const db = new SchemaAwareInMemDb();
    const paymentId = 'pay_ooo_1';
    const purchaseId = stableId('u_ooo:c_ooo');

    db.setDocument('course_purchases', purchaseId, {
      userId: 'u_ooo', categoryId: 'c_ooo', provider: 'razorpay', providerOrderId: 'o_ooo',
      providerPaymentId: paymentId, expectedAmount: 500, paidAmount: 500, refundedAmountPaise: 50000,
      currency: 'INR', status: 'refunded', refundStatus: 'fully_refunded', createdAt: new Date().toISOString()
    });

    const handler = createRazorpayWebhookHandler({ databases: db });

    const payload = {
      event: 'refund.processed',
      payload: {
        payment: { entity: { id: paymentId, amount_refunded: 25000 } },
        refund: { entity: { id: 'ref_stale_99', payment_id: paymentId, amount: 25000, status: 'processed', currency: 'INR' } }
      }
    };
    const raw = JSON.stringify(payload);
    const sig = createHmac('sha256', webhookSecret).update(raw).digest('hex');

    const req = { method: 'POST', headers: { 'x-razorpay-signature': sig }, body: raw, bodyRaw: raw };
    const res = createMockRes();

    await handler({ req, res, error: createMockErrorLogger() });

    assert.equal(res.statusCode, 200);

    const purchase = await db.getDocument('olitun_db', 'course_purchases', purchaseId);
    assert.equal(purchase.refundedAmountPaise, 50000);
    assert.equal(purchase.status, 'refunded');
  });

  test('11. razorpayWebhook rejects ambiguous matching payment IDs with 409 Conflict', async () => {
    const db = new SchemaAwareInMemDb();
    const paymentId = 'pay_duplicate_111';

    db.setDocument('course_purchases', stableId('u1:c1'), {
      userId: 'u1', categoryId: 'c1', provider: 'razorpay', providerOrderId: 'o1', providerPaymentId: paymentId,
      expectedAmount: 100, paidAmount: 100, currency: 'INR', status: 'verified', createdAt: new Date().toISOString()
    });

    db.setDocument('course_purchases', stableId('u2:c2'), {
      userId: 'u2', categoryId: 'c2', provider: 'razorpay', providerOrderId: 'o2', providerPaymentId: paymentId,
      expectedAmount: 100, paidAmount: 100, currency: 'INR', status: 'verified', createdAt: new Date().toISOString()
    });

    const handler = createRazorpayWebhookHandler({ databases: db });

    const payload = {
      event: 'refund.processed',
      payload: {
        payment: { entity: { id: paymentId, amount_refunded: 10000 } },
        refund: { entity: { id: 'ref_dup_1', payment_id: paymentId, amount: 10000, status: 'processed', currency: 'INR' } }
      }
    };
    const raw = JSON.stringify(payload);
    const sig = createHmac('sha256', webhookSecret).update(raw).digest('hex');

    const req = { method: 'POST', headers: { 'x-razorpay-signature': sig }, body: raw, bodyRaw: raw };
    const res = createMockRes();

    await handler({ req, res, error: createMockErrorLogger() });

    assert.equal(res.statusCode, 409);
    assert.equal(res.body.ok, false);
    assert.match(res.body.message, /Multiple purchase records match/i);
  });

  test('12. razorpayWebhook dispute.won does NOT restore access to fully refunded purchases', async () => {
    const db = new SchemaAwareInMemDb();
    const paymentId = 'pay_disputed_refunded_100';
    const purchaseId = stableId('user_dispute:cat_dispute');

    db.setDocument('course_purchases', purchaseId, {
      userId: 'user_dispute', categoryId: 'cat_dispute', provider: 'razorpay', providerOrderId: 'order_disp',
      providerPaymentId: paymentId, expectedAmount: 500, paidAmount: 500, refundedAmountPaise: 50000,
      currency: 'INR', status: 'refunded', refundStatus: 'fully_refunded', createdAt: new Date().toISOString()
    });

    const handler = createRazorpayWebhookHandler({ databases: db });

    const disputeWonPayload = {
      event: 'payment.dispute.won',
      payload: { dispute: { entity: { id: 'disp_100', payment_id: paymentId, status: 'won' } } }
    };
    const rawPayload = JSON.stringify(disputeWonPayload);
    const signature = createHmac('sha256', webhookSecret).update(rawPayload).digest('hex');

    const req = { method: 'POST', headers: { 'x-razorpay-signature': signature }, body: rawPayload, bodyRaw: rawPayload };
    const res = createMockRes();

    await handler({ req, res, error: createMockErrorLogger() });

    assert.equal(res.statusCode, 200);

    const purchase = await db.getDocument('olitun_db', 'course_purchases', purchaseId);
    assert.equal(purchase.status, 'refunded');
    assert.equal(purchase.refundStatus, 'fully_refunded');
  });

  test('13. refund.created acknowledges event without mutating entitlement', async () => {
    const db = new SchemaAwareInMemDb();
    const handler = createRazorpayWebhookHandler({ databases: db });

    const payload = { event: 'refund.created', payload: { refund: { entity: { id: 'ref_created_1' } } } };
    const raw = JSON.stringify(payload);
    const sig = createHmac('sha256', webhookSecret).update(raw).digest('hex');

    const req = { method: 'POST', headers: { 'x-razorpay-signature': sig }, body: raw, bodyRaw: raw };
    const res = createMockRes();

    await handler({ req, res, error: createMockErrorLogger() });

    assert.equal(res.statusCode, 200);
    assert.match(res.body.message, /acknowledged/i);
  });

  test('14. razorpayWebhook rejects invalid signature with HTTP 400', async () => {
    const db = new SchemaAwareInMemDb();
    const handler = createRazorpayWebhookHandler({ databases: db });

    const req = {
      method: 'POST',
      headers: { 'x-razorpay-signature': 'bad_signature_12345' },
      body: JSON.stringify({ event: 'payment.captured' }),
      bodyRaw: JSON.stringify({ event: 'payment.captured' })
    };
    const res = createMockRes();

    await handler({ req, res, error: createMockErrorLogger() });

    assert.equal(res.statusCode, 400);
    assert.equal(res.body.ok, false);
    assert.match(res.body.message, /Invalid webhook signature/i);
  });

  test('15. Authoritative-total failure returns 503 fail closed', async () => {
    const db = new SchemaAwareInMemDb();
    const paymentId = 'pay_no_auth_total';
    const purchaseId = stableId('u_fail:c_fail');

    db.setDocument('course_purchases', purchaseId, {
      userId: 'u_fail', categoryId: 'c_fail', provider: 'razorpay', providerOrderId: 'o_fail',
      providerPaymentId: paymentId, expectedAmount: 500, paidAmount: 500, refundedAmountPaise: 0,
      currency: 'INR', status: 'verified', createdAt: new Date().toISOString()
    });

    const mockFetchFail = async () => ({ ok: false, status: 500, text: async () => 'Gateway Error' });

    const handler = createRazorpayWebhookHandler({ databases: db, fetchImpl: mockFetchFail });

    const payload = {
      event: 'refund.processed',
      payload: {
        payment: { entity: { id: paymentId, amount_refunded: 0 } },
        refund: { entity: { id: 'ref_no_total_1', payment_id: paymentId, amount: 25000, status: 'processed', currency: 'INR' } }
      }
    };
    const raw = JSON.stringify(payload);
    const sig = createHmac('sha256', webhookSecret).update(raw).digest('hex');

    const req = { method: 'POST', headers: { 'x-razorpay-signature': sig }, body: raw, bodyRaw: raw };
    const res = createMockRes();

    await handler({ req, res, error: createMockErrorLogger() });

    assert.equal(res.statusCode, 503);
    assert.equal(res.body.ok, false);
    assert.match(res.body.message, /Authoritative payment refund state unavailable/i);
  });
});
