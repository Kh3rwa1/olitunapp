import { test, describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { withPaymentStateGuard } from '../_shared/payment_state.js';
import { reconcileDisputedPurchases } from '../_shared/payment_reconcile.js';
import { executeAdminRefund, stableId } from '../admin-maintenance/src/main.js';
import adminMaintenanceHandler from '../admin-maintenance/src/main.js';
import { MemoryDatabase, withTransactions } from './helpers/transaction_db.js';

function createMockRes() {
  const res = {
    statusCode: 200,
    body: null,
    json(data, status = 200) {
      res.statusCode = status;
      res.body = data;
      return res;
    },
  };
  return res;
}

const basePurchase = {
  userId: 'user-learner-1',
  categoryId: 'category-santali-1',
  provider: 'razorpay',
  providerOrderId: 'order-123',
  providerPaymentId: 'pay-123',
  status: 'verified',
  expectedAmount: 499,
  paidAmount: 499,
  currency: 'INR',
  refundedAmountPaise: 0,
  refundEpoch: 0,
};

describe('Priority 0B: Payment Dispute Lifecycle & Reconciliation', () => {
  test('Dispute transitions: active dispute (open/under_review) keeps status disputed', async () => {
    const db = new MemoryDatabase({ ...basePurchase, status: 'disputed' });
    const transactional = withTransactions(db);

    // Mock Razorpay API returning an open dispute
    const fetchFake = async (url) => {
      if (url.includes('/disputes')) {
        return {
          ok: true,
          json: async () => ({
            items: [
              {
                id: 'disp_1',
                status: 'under_review',
                created_at: 1700000000,
              },
            ],
          }),
        };
      }
      return { ok: false, status: 404 };
    };

    const stats = await reconcileDisputedPurchases({
      databases: transactional,
      razorpayKeyId: 'rzp_test_key',
      razorpayKeySecret: 'rzp_test_secret',
      fetchImpl: fetchFake,
    });

    assert.equal(stats.scanned, 1);
    assert.equal(stats.pending, 1);
    assert.equal(stats.won, 0);
    assert.equal(stats.lost, 0);

    const doc = await db.getDocument('olitun_db', 'course_purchases', 'purchase');
    assert.equal(doc.status, 'disputed');
  });

  test('Dispute transitions: won dispute authoritatively reinstates verified status', async () => {
    const db = new MemoryDatabase({ ...basePurchase, status: 'disputed' });
    const guardedDb = withPaymentStateGuard(withTransactions(db), { event: 'reconcile.dispute' });

    // Mock Razorpay API returning a won dispute
    const fetchFake = async (url) => {
      if (url.includes('/disputes')) {
        return {
          ok: true,
          json: async () => ({
            items: [
              {
                id: 'disp_1',
                status: 'won',
                created_at: 1700000000,
              },
            ],
          }),
        };
      }
      return { ok: false, status: 404 };
    };

    const stats = await reconcileDisputedPurchases({
      databases: guardedDb,
      razorpayKeyId: 'rzp_test_key',
      razorpayKeySecret: 'rzp_test_secret',
      fetchImpl: fetchFake,
    });

    assert.equal(stats.scanned, 1);
    assert.equal(stats.won, 1);
    assert.equal(stats.lost, 0);

    const doc = await db.getDocument('olitun_db', 'course_purchases', 'purchase');
    assert.equal(doc.status, 'verified');
  });

  test('Dispute transitions: lost dispute authoritatively revokes entitlement', async () => {
    const db = new MemoryDatabase({ ...basePurchase, status: 'disputed' });
    const guardedDb = withPaymentStateGuard(withTransactions(db), { event: 'reconcile.dispute' });

    // Mock Razorpay API returning a lost dispute
    const fetchFake = async (url) => {
      if (url.includes('/disputes')) {
        return {
          ok: true,
          json: async () => ({
            items: [
              {
                id: 'disp_1',
                status: 'lost',
                created_at: 1700000000,
              },
            ],
          }),
        };
      }
      return { ok: false, status: 404 };
    };

    const stats = await reconcileDisputedPurchases({
      databases: guardedDb,
      razorpayKeyId: 'rzp_test_key',
      razorpayKeySecret: 'rzp_test_secret',
      fetchImpl: fetchFake,
    });

    assert.equal(stats.scanned, 1);
    assert.equal(stats.lost, 1);
    assert.equal(stats.won, 0);

    const doc = await db.getDocument('olitun_db', 'course_purchases', 'purchase');
    assert.equal(doc.status, 'revoked');
  });

  test('Out-of-order race: late webhook won cannot restore once dispute lost/revoked', async () => {
    const db = new MemoryDatabase({ ...basePurchase, status: 'revoked' });
    const guardedDb = withPaymentStateGuard(withTransactions(db), { event: 'payment.dispute.won' });

    await guardedDb.listDocuments('olitun_db', 'course_purchases', []);
    const result = await guardedDb.updateDocument('olitun_db', 'course_purchases', 'purchase', {
      status: 'verified',
    });

    // Guard returns current document without mutating
    assert.equal(result.status, 'revoked');
    const doc = await db.getDocument('olitun_db', 'course_purchases', 'purchase');
    assert.equal(doc.status, 'revoked');
  });

  test('Out-of-order race: terminal refund blocks dispute won reconciliation from reinstating access', async () => {
    const db = new MemoryDatabase({
      ...basePurchase,
      status: 'refunded',
      refundStatus: 'fully_refunded',
      refundedAmountPaise: 49900,
    });
    const guardedDb = withPaymentStateGuard(withTransactions(db), { event: 'reconcile.dispute' });

    const fetchFake = async () => ({
      ok: true,
      json: async () => ({
        items: [{ id: 'disp_1', status: 'won', created_at: 1700000000 }],
      }),
    });

    const stats = await reconcileDisputedPurchases({
      databases: guardedDb,
      razorpayKeyId: 'rzp_test',
      razorpayKeySecret: 'rzp_secret',
      fetchImpl: fetchFake,
    });

    // Attempt to reinstate is contained, purchase remains refunded
    const doc = await db.getDocument('olitun_db', 'course_purchases', 'purchase');
    assert.equal(doc.status, 'refunded');
  });

  test('Dispute positive evidence: missing dispute or 404 with captured payment does NOT assume won (keeps disputed)', async () => {
    const db = new MemoryDatabase({ ...basePurchase, status: 'disputed' });
    const guardedDb = withPaymentStateGuard(withTransactions(db), { event: 'reconcile.dispute' });

    const fetchFake = async (url) => {
      if (url.includes('/disputes')) {
        return { ok: false, status: 404 };
      }
      if (url.includes('/payments/')) {
        return {
          ok: true,
          json: async () => ({
            id: 'pay-123',
            status: 'captured',
            disputed: false,
            amount_refunded: 0,
          }),
        };
      }
      return { ok: false, status: 404 };
    };

    const stats = await reconcileDisputedPurchases({
      databases: guardedDb,
      razorpayKeyId: 'rzp_test',
      razorpayKeySecret: 'rzp_secret',
      fetchImpl: fetchFake,
    });

    assert.equal(stats.scanned, 1);
    assert.equal(stats.pending, 1);
    assert.equal(stats.won, 0);
    assert.equal(stats.lost, 0);

    const doc = await db.getDocument('olitun_db', 'course_purchases', 'purchase');
    assert.equal(doc.status, 'disputed');
  });

  test('Dispute positive evidence: closed dispute with ambiguous reason and no winner does NOT assume won', async () => {
    const db = new MemoryDatabase({ ...basePurchase, status: 'disputed' });
    const guardedDb = withPaymentStateGuard(withTransactions(db), { event: 'reconcile.dispute' });

    const fetchFake = async (url) => {
      if (url.includes('/disputes')) {
        return {
          ok: true,
          json: async () => ({
            items: [
              {
                id: 'disp_1',
                status: 'closed',
                reason_code: 'fraudulent',
                created_at: 1700000000,
              },
            ],
          }),
        };
      }
      return { ok: false, status: 404 };
    };

    const stats = await reconcileDisputedPurchases({
      databases: guardedDb,
      razorpayKeyId: 'rzp_test',
      razorpayKeySecret: 'rzp_secret',
      fetchImpl: fetchFake,
    });

    assert.equal(stats.scanned, 1);
    assert.equal(stats.pending, 1);
    assert.equal(stats.won, 0);
    assert.equal(stats.lost, 0);

    const doc = await db.getDocument('olitun_db', 'course_purchases', 'purchase');
    assert.equal(doc.status, 'disputed');
  });

  test('Dispute positive evidence: closed dispute with winner merchant authoritatively reinstates verified', async () => {
    const db = new MemoryDatabase({ ...basePurchase, status: 'disputed' });
    const guardedDb = withPaymentStateGuard(withTransactions(db), { event: 'reconcile.dispute' });

    const fetchFake = async (url) => {
      if (url.includes('/disputes')) {
        return {
          ok: true,
          json: async () => ({
            items: [
              {
                id: 'disp_1',
                status: 'closed',
                winner: 'merchant',
                created_at: 1700000000,
              },
            ],
          }),
        };
      }
      return { ok: false, status: 404 };
    };

    const stats = await reconcileDisputedPurchases({
      databases: guardedDb,
      razorpayKeyId: 'rzp_test',
      razorpayKeySecret: 'rzp_secret',
      fetchImpl: fetchFake,
    });

    assert.equal(stats.scanned, 1);
    assert.equal(stats.won, 1);
    assert.equal(stats.lost, 0);

    const doc = await db.getDocument('olitun_db', 'course_purchases', 'purchase');
    assert.equal(doc.status, 'verified');
  });

  test('Dispute positive evidence: closed dispute with resolution lost authoritatively revokes entitlement', async () => {
    const db = new MemoryDatabase({ ...basePurchase, status: 'disputed' });
    const guardedDb = withPaymentStateGuard(withTransactions(db), { event: 'reconcile.dispute' });

    const fetchFake = async (url) => {
      if (url.includes('/disputes')) {
        return {
          ok: true,
          json: async () => ({
            items: [
              {
                id: 'disp_1',
                status: 'closed',
                resolution: 'lost',
                created_at: 1700000000,
              },
            ],
          }),
        };
      }
      return { ok: false, status: 404 };
    };

    const stats = await reconcileDisputedPurchases({
      databases: guardedDb,
      razorpayKeyId: 'rzp_test',
      razorpayKeySecret: 'rzp_secret',
      fetchImpl: fetchFake,
    });

    assert.equal(stats.scanned, 1);
    assert.equal(stats.lost, 1);
    assert.equal(stats.won, 0);

    const doc = await db.getDocument('olitun_db', 'course_purchases', 'purchase');
    assert.equal(doc.status, 'revoked');
  });

  test('Dispute positive evidence: missing dispute but payment entity indicates refund revokes entitlement', async () => {
    const db = new MemoryDatabase({ ...basePurchase, status: 'disputed' });
    const guardedDb = withPaymentStateGuard(withTransactions(db), { event: 'reconcile.dispute' });

    const fetchFake = async (url) => {
      if (url.includes('/disputes')) {
        return { ok: false, status: 404 };
      }
      if (url.includes('/payments/')) {
        return {
          ok: true,
          json: async () => ({
            id: 'pay-123',
            status: 'refunded',
            amount_refunded: 49900,
          }),
        };
      }
      return { ok: false, status: 404 };
    };

    const stats = await reconcileDisputedPurchases({
      databases: guardedDb,
      razorpayKeyId: 'rzp_test',
      razorpayKeySecret: 'rzp_secret',
      fetchImpl: fetchFake,
    });

    assert.equal(stats.scanned, 1);
    assert.equal(stats.lost, 1);
    assert.equal(stats.won, 0);

    const doc = await db.getDocument('olitun_db', 'course_purchases', 'purchase');
    assert.equal(doc.status, 'revoked');
  });

  test('Dispute reconciliation enforces transaction state guarding even if unguarded database passed', async () => {
    const db = new MemoryDatabase({ ...basePurchase, status: 'disputed' });
    // Unguarded db without createTransaction
    const fetchFake = async () => ({
      ok: true,
      json: async () => ({
        items: [{ id: 'disp_1', status: 'won', created_at: 1700000000 }],
      }),
    });

    const stats = await reconcileDisputedPurchases({
      databases: db,
      razorpayKeyId: 'rzp_test',
      razorpayKeySecret: 'rzp_secret',
      fetchImpl: fetchFake,
    });

    // Guard fails closed because transactions are unavailable, preventing unguarded update
    assert.equal(stats.failed, 1);
    assert.equal(stats.won, 0);

    const doc = await db.getDocument('olitun_db', 'course_purchases', 'purchase');
    assert.equal(doc.status, 'disputed');
  });
});

describe('Priority 0B: Admin-Authorized Refund Endpoint', () => {
  beforeEach(() => {
    process.env.APPWRITE_FUNCTION_API_ENDPOINT = 'http://localhost/v1';
    process.env.APPWRITE_FUNCTION_PROJECT_ID = 'test_project';
    process.env.APPWRITE_FUNCTION_API_KEY = 'test_api_key';
    process.env.ADMIN_TEAM_ID = 'admins';
  });

  test('Rejects unauthenticated call with 401', async () => {
    const req = {
      method: 'POST',
      headers: {},
      body: JSON.stringify({ action: 'record_refund', purchaseId: 'purchase_1' }),
    };
    const res = createMockRes();

    await adminMaintenanceHandler({ req, res, log: () => {}, error: () => {} });

    assert.equal(res.statusCode, 401);
    assert.equal(res.body.success, false);
    assert.match(res.body.message, /Authentication required/i);
  });

  test('Rejects non-POST method with 405', async () => {
    const req = {
      method: 'GET',
      headers: { 'x-appwrite-user-id': 'admin_user' },
      body: '',
    };
    const res = createMockRes();

    await adminMaintenanceHandler({ req, res, log: () => {}, error: () => {} });

    assert.equal(res.statusCode, 405);
    assert.equal(res.body.success, false);
    assert.match(res.body.message, /Method not allowed/i);
  });

  test('Rejects missing purchaseId with 400', async () => {
    const req = {
      method: 'POST',
      headers: { 'x-appwrite-user-id': 'admin_user' },
      body: JSON.stringify({ action: 'record_refund' }),
    };
    const res = createMockRes();

    await adminMaintenanceHandler({ req, res, log: () => {}, error: () => {} });

    assert.equal(res.statusCode, 400);
    assert.equal(res.body.success, false);
    assert.match(res.body.message, /Missing purchase ID/i);
  });

  test('Rejects non-admin user with 403 Forbidden', async () => {
    const req = {
      method: 'POST',
      headers: { 'x-appwrite-user-id': 'normal_student_user' },
      body: JSON.stringify({ action: 'record_refund', purchaseId: 'purchase_1' }),
    };
    const res = createMockRes();

    // With invalid/mock endpoint, users.listMemberships will fail, userIsAdmin returns false
    await adminMaintenanceHandler({ req, res, log: () => {}, error: () => {} });

    assert.equal(res.statusCode, 403);
    assert.equal(res.body.success, false);
    assert.match(res.body.message, /Admin team membership required/i);
  });

  test('executeAdminRefund successfully revokes entitlement and writes audit trail', async () => {
    const db = new MemoryDatabase({ ...basePurchase });
    const transactional = withTransactions(db);

    const result = await executeAdminRefund({
      databases: transactional,
      actorUserId: 'admin_ops_1',
      body: {
        purchaseId: 'purchase',
        reason: 'Customer requested refund via support ticket #1042',
        externalRefundId: 'rfnd_ext_999',
      },
    });

    assert.equal(result.alreadyRefunded, false);
    assert.equal(result.status, 'refunded');
    assert.equal(result.refundStatus, 'fully_refunded');
    assert.equal(result.refundedAmountPaise, 49900);
    assert.equal(result.refundEpoch, 1);

    const purchaseDoc = await db.getDocument('olitun_db', 'course_purchases', 'purchase');
    assert.equal(purchaseDoc.status, 'refunded');
    assert.equal(purchaseDoc.refundStatus, 'fully_refunded');
    assert.equal(purchaseDoc.refundedAmountPaise, 49900);
    assert.equal(purchaseDoc.refundEpoch, 1);

    // Verify audit log creation
    const auditLogs = await db.listDocuments('olitun_db', 'admin_audit_logs');
    assert.equal(auditLogs.documents.length, 1);
    const log = auditLogs.documents[0];
    assert.equal(log.action, 'refund_recorded');
    assert.equal(log.actorUserId, 'admin_ops_1');
    assert.equal(log.targetId, 'purchase');
    assert.equal(log.targetType, 'course_purchase');
    assert.equal(log.success, true);
    assert.match(log.metadata, /rfnd_ext_999/);
    assert.match(log.metadata, /ticket #1042/);
  });

  test('executeAdminRefund is idempotent when invoked repeatedly', async () => {
    const db = new MemoryDatabase({ ...basePurchase });
    const transactional = withTransactions(db);

    // First execution
    const firstResult = await executeAdminRefund({
      databases: transactional,
      actorUserId: 'admin_ops_1',
      body: { purchaseId: 'purchase', externalRefundId: 'rfnd_ext_1' },
    });
    assert.equal(firstResult.alreadyRefunded, false);
    assert.equal(firstResult.status, 'refunded');

    // Second execution with same purchaseId
    const secondResult = await executeAdminRefund({
      databases: transactional,
      actorUserId: 'admin_ops_1',
      body: { purchaseId: 'purchase', externalRefundId: 'rfnd_ext_1' },
    });
    assert.equal(secondResult.alreadyRefunded, true);
    assert.equal(secondResult.status, 'refunded');
    assert.equal(secondResult.refundStatus, 'fully_refunded');

    // Exactly one refund write occurred, no duplicate modification
    const purchaseDoc = await db.getDocument('olitun_db', 'course_purchases', 'purchase');
    assert.equal(purchaseDoc.refundEpoch, 1);
  });

  test('executeAdminRefund rejects refund on unverified/created purchase', async () => {
    const db = new MemoryDatabase({ ...basePurchase, status: 'created', providerPaymentId: null });
    const transactional = withTransactions(db);

    await assert.rejects(
      () =>
        executeAdminRefund({
          databases: transactional,
          actorUserId: 'admin_ops_1',
          body: { purchaseId: 'purchase' },
        }),
      { status: 409 },
    );
  });

  test('executeAdminRefund fails with 503 if transactions are unavailable (0 writes)', async () => {
    const db = new MemoryDatabase({ ...basePurchase });
    // Note: db without withTransactions has no createTransaction

    await assert.rejects(
      () =>
        executeAdminRefund({
          databases: db,
          actorUserId: 'admin_ops_1',
          body: { purchaseId: 'purchase' },
        }),
      { status: 503 },
    );

    assert.equal(db.writes.length, 0);
  });

  test('executeAdminRefund supports partial refund without revoking entitlement', async () => {
    const db = new MemoryDatabase({ ...basePurchase });
    const transactional = withTransactions(db);

    const result = await executeAdminRefund({
      databases: transactional,
      actorUserId: 'admin_ops_1',
      body: {
        purchaseId: 'purchase',
        amountPaise: 15000,
        externalRefundId: 'rfnd_part_1',
      },
    });

    assert.equal(result.alreadyRefunded, false);
    assert.equal(result.status, 'verified'); // Entitlement retained!
    assert.equal(result.refundStatus, 'partially_refunded');
    assert.equal(result.refundedAmountPaise, 15000);
    assert.equal(result.refundEpoch, 1);

    const purchaseDoc = await db.getDocument('olitun_db', 'course_purchases', 'purchase');
    assert.equal(purchaseDoc.status, 'verified');
    assert.equal(purchaseDoc.refundStatus, 'partially_refunded');
    assert.equal(purchaseDoc.refundedAmountPaise, 15000);
    assert.equal(purchaseDoc.refundEpoch, 1);
  });

  test('executeAdminRefund partial refund is idempotent on replay with same externalRefundId', async () => {
    const db = new MemoryDatabase({ ...basePurchase });
    const transactional = withTransactions(db);

    // First call: partial refund
    const firstResult = await executeAdminRefund({
      databases: transactional,
      actorUserId: 'admin_ops_1',
      body: {
        purchaseId: 'purchase',
        amountPaise: 15000,
        externalRefundId: 'rfnd_part_idem_1',
      },
    });
    assert.equal(firstResult.alreadyRefunded, false);
    assert.equal(firstResult.status, 'verified');
    assert.equal(firstResult.refundStatus, 'partially_refunded');

    const writesAfterFirst = db.writes.length;

    // Second call: replay with same externalRefundId
    const secondResult = await executeAdminRefund({
      databases: transactional,
      actorUserId: 'admin_ops_1',
      body: {
        purchaseId: 'purchase',
        amountPaise: 15000,
        externalRefundId: 'rfnd_part_idem_1',
      },
    });
    assert.equal(secondResult.alreadyRefunded, true);
    assert.equal(secondResult.status, 'verified');
    assert.equal(secondResult.refundStatus, 'partially_refunded');
    assert.equal(secondResult.refundedAmountPaise, 15000);

    // Zero extra writes to course_purchases occurred
    const writesAfterSecond = db.writes.length;
    assert.equal(writesAfterSecond, writesAfterFirst);
  });

  test('executeAdminRefund rejects invalid or excessive refund amounts', async () => {
    const db = new MemoryDatabase({ ...basePurchase });
    const transactional = withTransactions(db);

    // Negative amount
    await assert.rejects(
      () =>
        executeAdminRefund({
          databases: transactional,
          actorUserId: 'admin_ops_1',
          body: { purchaseId: 'purchase', amountPaise: -500 },
        }),
      { status: 400 },
    );

    // Excessive amount (exceeds 49900 paise)
    await assert.rejects(
      () =>
        executeAdminRefund({
          databases: transactional,
          actorUserId: 'admin_ops_1',
          body: { purchaseId: 'purchase', amountPaise: 99999 },
        }),
      { status: 400 },
    );
  });

  test('executeAdminRefund fails closed if audit log creation fails (swallowed audit fix)', async () => {
    const db = new MemoryDatabase({ ...basePurchase });
    const originalCreate = db.createDocument.bind(db);
    db.createDocument = async (...args) => {
      const col = typeof args[0] === 'object' ? args[0].collectionId : args[1];
      if (col === 'admin_audit_logs') {
        throw new Error('Audit log service outage');
      }
      return originalCreate(...args);
    };
    const transactional = withTransactions(db);

    await assert.rejects(
      () =>
        executeAdminRefund({
          databases: transactional,
          actorUserId: 'admin_ops_1',
          body: { purchaseId: 'purchase', externalRefundId: 'rfnd_fail_audit' },
        }),
      /Audit log service outage/,
    );
  });

  test('Failure path B recovery: retry resumes at Phase 3 and writes missing audit log without updating purchase again', async () => {
    const db = new MemoryDatabase({ ...basePurchase });
    let failAudit = true;
    const originalCreate = db.createDocument.bind(db);
    db.createDocument = async (...args) => {
      const col = typeof args[0] === 'object' ? args[0].collectionId : args[1];
      if (col === 'admin_audit_logs' && failAudit) {
        throw new Error('Audit log service outage');
      }
      return originalCreate(...args);
    };
    const transactional = withTransactions(db);

    // First attempt fails during audit log creation
    await assert.rejects(
      () =>
        executeAdminRefund({
          databases: transactional,
          actorUserId: 'admin_ops_1',
          body: { purchaseId: 'purchase', externalRefundId: 'rfnd_fail_b' },
        }),
      /Audit log service outage/,
    );

    // Purchase ledger was updated to refunded
    const purchaseAfterFail = await db.getDocument('olitun_db', 'course_purchases', 'purchase');
    assert.equal(purchaseAfterFail.status, 'refunded');
    assert.equal(purchaseAfterFail.refundEpoch, 1);

    // Audit logs collection is currently EMPTY (missing audit record)
    const logsBeforeRetry = await db.listDocuments('olitun_db', 'admin_audit_logs');
    assert.equal(logsBeforeRetry.documents.length, 0);

    // Now service recovers
    failAudit = false;

    // Retry with the same externalRefundId: must resume Phase 3 and repair the audit log!
    const retryResult = await executeAdminRefund({
      databases: transactional,
      actorUserId: 'admin_ops_1',
      body: { purchaseId: 'purchase', externalRefundId: 'rfnd_fail_b' },
    });

    assert.equal(retryResult.alreadyRefunded, true);
    assert.equal(retryResult.status, 'refunded');

    // Purchase epoch was NOT incremented again (no duplicate purchase write)
    const purchaseAfterRetry = await db.getDocument('olitun_db', 'course_purchases', 'purchase');
    assert.equal(purchaseAfterRetry.refundEpoch, 1);

    // Audit log was durably created on retry!
    const logsAfterRetry = await db.listDocuments('olitun_db', 'admin_audit_logs');
    assert.equal(logsAfterRetry.documents.length, 1);
    assert.equal(logsAfterRetry.documents[0].targetId, 'purchase');
    assert.match(logsAfterRetry.documents[0].metadata, /rfnd_fail_b/);
  });

  test('Failure path A recovery: retry after failed purchase update resumes Phase 2 and completes ledger update', async () => {
    const db = new MemoryDatabase({ ...basePurchase });
    let failPurchaseUpdate = true;
    const originalUpdate = db.updateDocument.bind(db);
    db.updateDocument = async (...args) => {
      const col = typeof args[0] === 'object' ? args[0].collectionId : args[1];
      if (col === 'course_purchases' && failPurchaseUpdate) {
        throw new Error('Database transaction timeout on purchase write');
      }
      return originalUpdate(...args);
    };
    const transactional = withTransactions(db);

    // First attempt fails during purchase ledger update
    await assert.rejects(
      () =>
        executeAdminRefund({
          databases: transactional,
          actorUserId: 'admin_ops_1',
          body: { purchaseId: 'purchase', externalRefundId: 'rfnd_fail_a' },
        }),
      /Database transaction timeout on purchase write/,
    );

    // Purchase was NOT updated yet
    const purchaseAfterFail = await db.getDocument('olitun_db', 'course_purchases', 'purchase');
    assert.equal(purchaseAfterFail.status, 'verified');
    assert.equal(purchaseAfterFail.refundEpoch, 0);

    // Claim exists in 'claimed' state
    const claimDoc = await db.getDocument('olitun_db', 'refund_claims', stableId('refund:rfnd_fail_a'));
    assert.equal(claimDoc.status, 'claimed');

    // Database recovers
    failPurchaseUpdate = false;

    // Retry must resume Phase 2 and update purchase ledger, NOT return alreadyRefunded without writing
    const retryResult = await executeAdminRefund({
      databases: transactional,
      actorUserId: 'admin_ops_1',
      body: { purchaseId: 'purchase', externalRefundId: 'rfnd_fail_a' },
    });

    assert.equal(retryResult.alreadyRefunded, false);
    assert.equal(retryResult.status, 'refunded');

    const purchaseAfterRetry = await db.getDocument('olitun_db', 'course_purchases', 'purchase');
    assert.equal(purchaseAfterRetry.status, 'refunded');
    assert.equal(purchaseAfterRetry.refundEpoch, 1);

    // Audit log was also created
    const logs = await db.listDocuments('olitun_db', 'admin_audit_logs');
    assert.equal(logs.documents.length, 1);
  });

  test('Payload mismatch: reusing externalRefundId with different purchaseId or amount throws 409 Conflict', async () => {
    const db = new MemoryDatabase({ ...basePurchase });
    await db.createDocument('olitun_db', 'course_purchases', 'other_purchase', {
      ...basePurchase,
      $id: 'other_purchase',
    });
    const transactional = withTransactions(db);

    // Initial refund for purchase
    await executeAdminRefund({
      databases: transactional,
      actorUserId: 'admin_ops_1',
      body: { purchaseId: 'purchase', externalRefundId: 'rfnd_same_key', amountPaise: 49900 },
    });

    // Attempt to reuse same externalRefundId with different purchaseId
    await assert.rejects(
      () =>
        executeAdminRefund({
          databases: transactional,
          actorUserId: 'admin_ops_1',
          body: { purchaseId: 'other_purchase', externalRefundId: 'rfnd_same_key', amountPaise: 49900 },
        }),
      (err) => err.status === 409 && /Idempotency conflict/.test(err.message),
    );

    // Attempt to reuse same externalRefundId with different amountPaise
    await assert.rejects(
      () =>
        executeAdminRefund({
          databases: transactional,
          actorUserId: 'admin_ops_1',
          body: { purchaseId: 'purchase', externalRefundId: 'rfnd_same_key', amountPaise: 20000 },
        }),
      (err) => err.status === 409 && /Idempotency conflict/.test(err.message),
    );
  });
});
