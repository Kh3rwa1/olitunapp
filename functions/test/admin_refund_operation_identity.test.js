import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import { executeAdminRefund, stableId } from '../admin-maintenance/src/main.js';
import { MemoryDatabase, withTransactions } from './helpers/transaction_db.js';

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

function purchaseDoc(db) {
  return db.getDocument('olitun_db', 'course_purchases', 'purchase');
}

function auditDocs(db) {
  return db.listDocuments('olitun_db', 'admin_audit_logs');
}

function claimDocs(db) {
  return db.listDocuments('olitun_db', 'refund_claims');
}

/// Wraps a MemoryDatabase to additionally enforce the schema's UNIQUE
/// index on refund_claims.refundId (production Appwrite behavior that the
/// bare double does not model). Used only by the tests that exercise the
/// duplicate-gateway-reference path.
function withUniqueRefundId(db) {
  const seen = new Map();
  const originalCreate = db.createDocument.bind(db);
  db.createDocument = async (...args) => {
    const col = typeof args[0] === 'object' ? args[0].collectionId : args[1];
    const data = typeof args[0] === 'object' ? args[0].data : args[3];
    if (col === 'refund_claims' && data && typeof data.refundId === 'string') {
      if (seen.has(data.refundId)) {
        throw Object.assign(new Error('Duplicate refundId'), { code: 409 });
      }
      seen.set(data.refundId, true);
    }
    return originalCreate(...args);
  };
  return db;
}

describe('Admin Refund Operation Identity & Recovery', () => {
  test('keyless requests are rejected with 400 and write nothing', async () => {
    for (const body of [
      { purchaseId: 'purchase' },
      { purchaseId: 'purchase', operationKey: '' },
      { purchaseId: 'purchase', operationKey: '   ' },
      { purchaseId: 'purchase', externalRefundId: '' },
      { purchaseId: 'purchase', idempotencyKey: '  ' },
    ]) {
      const db = new MemoryDatabase({ ...basePurchase });
      const transactional = withTransactions(db);
      await assert.rejects(
        () =>
          executeAdminRefund({
            databases: transactional,
            actorUserId: 'admin_ops_1',
            body,
          }),
        { status: 400 },
      );
      assert.equal(db.writes.length, 0);
      assert.equal((await claimDocs(db)).documents.length, 0);
      assert.equal((await auditDocs(db)).documents.length, 0);
      assert.equal((await purchaseDoc(db)).status, 'verified');
    }
  });

  test('idempotencyKey alias is accepted as the operation identity', async () => {
    const db = new MemoryDatabase({ ...basePurchase });
    const transactional = withTransactions(db);
    const result = await executeAdminRefund({
      databases: transactional,
      actorUserId: 'admin_ops_1',
      body: { purchaseId: 'purchase', idempotencyKey: 'idem_alias_1' },
    });
    assert.equal(result.alreadyRefunded, false);
    assert.equal(result.status, 'refunded');
    const claim = await db.getDocument(
      'olitun_db',
      'refund_claims',
      stableId('refund:idem_alias_1'),
    );
    assert.equal(claim.status, 'audit_committed');
  });

  test('operation key and gateway refund ID are stored distinctly', async () => {
    const db = new MemoryDatabase({ ...basePurchase });
    const transactional = withTransactions(db);
    const result = await executeAdminRefund({
      databases: transactional,
      actorUserId: 'admin_ops_1',
      body: {
        purchaseId: 'purchase',
        operationKey: 'op_gateway_split_1',
        gatewayRefundId: 'gw_live_abc',
        reason: 'Gateway refund issued in dashboard',
      },
    });
    assert.equal(result.alreadyRefunded, false);

    const claim = await db.getDocument(
      'olitun_db',
      'refund_claims',
      stableId('refund:op_gateway_split_1'),
    );
    assert.equal(claim.refundId, 'gw_live_abc');

    const logs = await auditDocs(db);
    assert.equal(logs.documents.length, 1);
    assert.match(logs.documents[0].metadata, /op_gateway_split_1/);
    assert.match(logs.documents[0].metadata, /gw_live_abc/);
  });

  test('retry with a different gateway reference does not conflict and keeps the first linkage', async () => {
    const db = new MemoryDatabase({ ...basePurchase });
    const transactional = withTransactions(db);
    const first = await executeAdminRefund({
      databases: transactional,
      actorUserId: 'admin_ops_1',
      body: {
        purchaseId: 'purchase',
        operationKey: 'op_gateway_stable_1',
        gatewayRefundId: 'gw_first',
      },
    });
    assert.equal(first.alreadyRefunded, false);

    const second = await executeAdminRefund({
      databases: transactional,
      actorUserId: 'admin_ops_1',
      body: {
        purchaseId: 'purchase',
        operationKey: 'op_gateway_stable_1',
        gatewayRefundId: 'gw_second_typo_fix',
      },
    });
    assert.equal(second.alreadyRefunded, true);

    const claim = await db.getDocument(
      'olitun_db',
      'refund_claims',
      stableId('refund:op_gateway_stable_1'),
    );
    assert.equal(claim.refundId, 'gw_first');
    assert.equal((await auditDocs(db)).documents.length, 1);
  });

  test('gateway reference is adopted onto the claim when the first attempt lacked one', async () => {
    const db = new MemoryDatabase({ ...basePurchase });
    const transactional = withTransactions(db);
    await executeAdminRefund({
      databases: transactional,
      actorUserId: 'admin_ops_1',
      body: { purchaseId: 'purchase', operationKey: 'op_gateway_fill_1' },
    });
    let claim = await db.getDocument(
      'olitun_db',
      'refund_claims',
      stableId('refund:op_gateway_fill_1'),
    );
    assert.equal(claim.refundId, 'op_gateway_fill_1');

    const retry = await executeAdminRefund({
      databases: transactional,
      actorUserId: 'admin_ops_1',
      body: {
        purchaseId: 'purchase',
        operationKey: 'op_gateway_fill_1',
        gatewayRefundId: 'gw_late_link',
      },
    });
    assert.equal(retry.alreadyRefunded, true);

    claim = await db.getDocument(
      'olitun_db',
      'refund_claims',
      stableId('refund:op_gateway_fill_1'),
    );
    assert.equal(claim.refundId, 'gw_late_link');
  });

  test('concurrent retries with the same key apply the ledger once', async () => {
    const db = new MemoryDatabase({ ...basePurchase });
    const transactional = withTransactions(db);
    const body = { purchaseId: 'purchase', operationKey: 'op_concurrent_1' };

    const results = await Promise.all([
      executeAdminRefund({ databases: transactional, actorUserId: 'admin_ops_1', body }),
      executeAdminRefund({ databases: transactional, actorUserId: 'admin_ops_1', body }),
      executeAdminRefund({ databases: transactional, actorUserId: 'admin_ops_1', body }),
    ]);
    for (const result of results) {
      assert.equal(result.status, 'refunded');
      assert.equal(result.refundedAmountPaise, 49900);
    }

    const purchase = await purchaseDoc(db);
    assert.equal(purchase.refundEpoch, 1);
    assert.equal(purchase.refundedAmountPaise, 49900);
    assert.equal((await auditDocs(db)).documents.length, 1);
  });

  test('multiple operations on one purchase advance epochs with max-floor bookkeeping', async () => {
    const db = new MemoryDatabase({ ...basePurchase });
    const transactional = withTransactions(db);

    const partial = await executeAdminRefund({
      databases: transactional,
      actorUserId: 'admin_ops_1',
      body: { purchaseId: 'purchase', operationKey: 'op_multi_1', amountPaise: 15000 },
    });
    assert.equal(partial.alreadyRefunded, false);
    assert.equal(partial.refundStatus, 'partially_refunded');
    assert.equal(partial.refundEpoch, 1);

    const full = await executeAdminRefund({
      databases: transactional,
      actorUserId: 'admin_ops_1',
      body: { purchaseId: 'purchase', operationKey: 'op_multi_2', amountPaise: 49900 },
    });
    assert.equal(full.alreadyRefunded, false);
    assert.equal(full.refundStatus, 'fully_refunded');
    assert.equal(full.refundedAmountPaise, 49900);
    assert.equal(full.refundEpoch, 2);

    assert.equal((await auditDocs(db)).documents.length, 2);
  });

  test('keyed operation on a legacy already-refunded purchase is a no-op', async () => {
    const db = new MemoryDatabase({
      ...basePurchase,
      status: 'refunded',
      refundStatus: 'fully_refunded',
      refundedAmountPaise: 49900,
      refundEpoch: 1,
    });
    const transactional = withTransactions(db);

    const result = await executeAdminRefund({
      databases: transactional,
      actorUserId: 'admin_ops_1',
      body: { purchaseId: 'purchase', operationKey: 'op_legacy_era_1' },
    });
    assert.equal(result.alreadyRefunded, true);
    assert.equal(db.writes.length, 0);
    assert.equal((await claimDocs(db)).documents.length, 0);
    assert.equal((await auditDocs(db)).documents.length, 0);
  });

  test('an earlier operation recovers its audit after a later operation moved the purchase', async () => {
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

    // K1 commits a partial ledger, then audit creation fails.
    await assert.rejects(
      () =>
        executeAdminRefund({
          databases: transactional,
          actorUserId: 'admin_ops_1',
          body: { purchaseId: 'purchase', operationKey: 'op_k1_partial', amountPaise: 15000 },
        }),
      /Audit log service outage/,
    );
    failAudit = false;

    // K2 (a different operation) advances the purchase meanwhile.
    const k2 = await executeAdminRefund({
      databases: transactional,
      actorUserId: 'admin_ops_1',
      body: { purchaseId: 'purchase', operationKey: 'op_k2_partial', amountPaise: 30000 },
    });
    assert.equal(k2.alreadyRefunded, false);
    assert.equal(k2.refundEpoch, 2);

    // Retry K1: must recover its own audit without disturbing K2's amounts.
    const retryK1 = await executeAdminRefund({
      databases: transactional,
      actorUserId: 'admin_ops_1',
      body: { purchaseId: 'purchase', operationKey: 'op_k1_partial', amountPaise: 15000 },
    });
    assert.equal(retryK1.alreadyRefunded, true);

    const purchase = await purchaseDoc(db);
    assert.equal(purchase.refundedAmountPaise, 30000);
    assert.equal(purchase.refundEpoch, 2);

    const logs = await auditDocs(db);
    assert.equal(logs.documents.length, 2);
    const claimK1 = await db.getDocument(
      'olitun_db',
      'refund_claims',
      stableId('refund:op_k1_partial'),
    );
    assert.equal(claimK1.status, 'audit_committed');
  });

  test('reusing a gateway reference under a fresh key fails closed with 409', async () => {
    const db = withUniqueRefundId(new MemoryDatabase({ ...basePurchase }));
    const transactional = withTransactions(db);

    // K1 records a PARTIAL refund (purchase stays open) under gateway G.
    const first = await executeAdminRefund({
      databases: transactional,
      actorUserId: 'admin_ops_1',
      body: {
        purchaseId: 'purchase',
        operationKey: 'op_gw_first_1',
        gatewayRefundId: 'gw_shared_xyz',
        amountPaise: 15000,
      },
    });
    assert.equal(first.alreadyRefunded, false);
    assert.equal(first.refundStatus, 'partially_refunded');

    // A fresh operation key reusing the same gateway reference cannot create
    // a second claim for it: the unique refundId index rejects the write and
    // the handler reports which recovery path to take instead of writing.
    const writesBefore = db.writes.length;
    await assert.rejects(
      () =>
        executeAdminRefund({
          databases: transactional,
          actorUserId: 'admin_ops_1',
          body: {
            purchaseId: 'purchase',
            operationKey: 'op_gw_fresh_key_1',
            gatewayRefundId: 'gw_shared_xyz',
            amountPaise: 15000,
          },
        }),
      (err) => err.status === 409 && /different operation/.test(err.message),
    );

    // The failed retry wrote nothing to the ledger.
    const purchase = await purchaseDoc(db);
    assert.equal(purchase.refundEpoch, 1);
    assert.equal(purchase.refundedAmountPaise, 15000);
    assert.equal(db.writes.length, writesBefore);
    assert.equal((await auditDocs(db)).documents.length, 1);
  });

  test('interrupted final claim update still converges on retry', async () => {
    const db = new MemoryDatabase({ ...basePurchase });
    let failFinalize = true;
    const originalUpdate = db.updateDocument.bind(db);
    db.updateDocument = async (...args) => {
      const col = typeof args[0] === 'object' ? args[0].collectionId : args[1];
      const data = typeof args[0] === 'object' ? args[0].data : args[3];
      if (col === 'refund_claims' && data && data.status === 'audit_committed' && failFinalize) {
        throw new Error('Claim finalize outage');
      }
      return originalUpdate(...args);
    };
    const transactional = withTransactions(db);

    const first = await executeAdminRefund({
      databases: transactional,
      actorUserId: 'admin_ops_1',
      body: { purchaseId: 'purchase', operationKey: 'op_finalize_1' },
    });
    assert.equal(first.alreadyRefunded, false);
    failFinalize = false;

    let claim = await db.getDocument(
      'olitun_db',
      'refund_claims',
      stableId('refund:op_finalize_1'),
    );
    assert.equal(claim.status, 'ledger_committed');
    assert.equal((await auditDocs(db)).documents.length, 1);

    const retry = await executeAdminRefund({
      databases: transactional,
      actorUserId: 'admin_ops_1',
      body: { purchaseId: 'purchase', operationKey: 'op_finalize_1' },
    });
    assert.equal(retry.alreadyRefunded, true);

    claim = await db.getDocument(
      'olitun_db',
      'refund_claims',
      stableId('refund:op_finalize_1'),
    );
    assert.equal(claim.status, 'audit_committed');
    assert.equal((await auditDocs(db)).documents.length, 1);
    const purchase = await purchaseDoc(db);
    assert.equal(purchase.refundEpoch, 1);
  });

  test('interrupted ledger_committed claim update recovers via the purchase pointer', async () => {
    const db = new MemoryDatabase({ ...basePurchase });
    // Simulate a crash between the ledger commit and any claim/audit write:
    // fail every refund_claims status write AND the audit write on the first
    // attempt. The ledger commit itself (course_purchases, carrying
    // lastRefundClaimId) still lands.
    let faultActive = true;
    const originalUpdate = db.updateDocument.bind(db);
    db.updateDocument = async (...args) => {
      const col = typeof args[0] === 'object' ? args[0].collectionId : args[1];
      if (col === 'refund_claims' && faultActive) {
        throw new Error('Claim status write outage');
      }
      return originalUpdate(...args);
    };
    const originalCreate = db.createDocument.bind(db);
    db.createDocument = async (...args) => {
      const col = typeof args[0] === 'object' ? args[0].collectionId : args[1];
      if (col === 'admin_audit_logs' && faultActive) {
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
          body: { purchaseId: 'purchase', operationKey: 'op_claimptr_1' },
        }),
      /Audit log service outage/,
    );
    faultActive = false;

    // Ledger committed with the operation pointer; claim stuck at 'claimed'.
    const purchase = await purchaseDoc(db);
    assert.equal(purchase.status, 'refunded');
    assert.equal(purchase.lastRefundClaimId, stableId('refund:op_claimptr_1'));

    let claim = await db.getDocument(
      'olitun_db',
      'refund_claims',
      stableId('refund:op_claimptr_1'),
    );
    assert.equal(claim.status, 'claimed');
    assert.equal((await auditDocs(db)).documents.length, 0);

    // Retry detects the pointer and repairs claim + audit without touching
    // the ledger again.
    const retry = await executeAdminRefund({
      databases: transactional,
      actorUserId: 'admin_ops_1',
      body: { purchaseId: 'purchase', operationKey: 'op_claimptr_1' },
    });
    assert.equal(retry.alreadyRefunded, true);
    assert.equal(purchase.refundEpoch, 1);

    claim = await db.getDocument(
      'olitun_db',
      'refund_claims',
      stableId('refund:op_claimptr_1'),
    );
    assert.equal(claim.status, 'audit_committed');
    assert.equal((await auditDocs(db)).documents.length, 1);
  });
});
