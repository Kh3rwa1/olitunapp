import { createHash } from 'crypto';
import {
  Client,
  Databases,
  ID,
  Query,
  Storage,
  Users,
} from 'node-appwrite';
import { InputFile } from 'node-appwrite/file';
import { withPaymentStateGuard } from './shared/payment_state.js';

export function stableId(value) {
  return createHash('sha256').update(value).digest('hex').slice(0, 32);
}

export const DATABASE_ID = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
export const ADMIN_TEAM_ID = process.env.ADMIN_TEAM_ID || 'admins';
export const BACKUP_BUCKET_ID =
  process.env.ADMIN_BACKUP_BUCKET_ID || 'admin_backups';
export const CONTENT_COLLECTIONS = [
  'quizzes',
  'sentences',
  'words',
  'numbers',
  'letters',
  'lessons',
  'categories',
];

const ACTIONS = new Set([
  'backup_content',
  'wipe_content',
  'restore_content',
  'record_refund',
]);

export function parseBody(body) {
  if (!body) return {};
  if (typeof body === 'object') return body;
  return JSON.parse(body);
}

export function requireConfig(env = process.env) {
  const endpoint = env.APPWRITE_FUNCTION_API_ENDPOINT || env.APPWRITE_ENDPOINT;
  const projectId = env.APPWRITE_FUNCTION_PROJECT_ID || env.APPWRITE_PROJECT_ID;
  const apiKey = env.APPWRITE_FUNCTION_API_KEY || env.APPWRITE_API_KEY;

  if (!endpoint || !projectId || !apiKey) {
    throw new Error(
      'Missing Appwrite function configuration: endpoint, project, or API key.',
    );
  }

  return { endpoint, projectId, apiKey };
}

export function validateRequest({ method, userId, body }) {
  if (method !== 'POST') {
    return { status: 405, message: 'Method not allowed.' };
  }

  if (!userId) {
    return { status: 401, message: 'Authentication required.' };
  }

  if (!ACTIONS.has(body.action)) {
    return {
      status: 400,
      message: 'Unsupported admin maintenance action.',
    };
  }

  if (body.action === 'wipe_content' && body.confirmation !== 'WIPE ALL') {
    return { status: 400, message: 'Invalid confirmation phrase.' };
  }

  if (body.action === 'restore_content' && !body.fileId) {
    return { status: 400, message: 'Missing backup file ID.' };
  }

  if (body.action === 'record_refund' && !body.purchaseId) {
    return { status: 400, message: 'Missing purchase ID.' };
  }

  return null;
}

export async function userIsAdmin(users, userId) {
  try {
    const memberships = await users.listMemberships(userId);
    return memberships.memberships.some(
      (membership) => membership.teamId === ADMIN_TEAM_ID,
    );
  } catch {
    return false;
  }
}

export async function listAllDocuments(databases, collectionId) {
  const documents = [];

  while (true) {
    const result = await databases.listDocuments(DATABASE_ID, collectionId, [
      Query.limit(100),
      Query.offset(documents.length),
    ]);

    documents.push(...result.documents);
    if (result.documents.length < 100) return documents;
  }
}

export async function buildBackupPayload(databases, actorUserId, createdAt) {
  const collections = {};
  const counts = {};

  for (const collectionId of CONTENT_COLLECTIONS) {
    const documents = await listAllDocuments(databases, collectionId);
    collections[collectionId] = documents;
    counts[collectionId] = documents.length;
  }

  return {
    schemaVersion: 1,
    createdAt,
    actorUserId,
    databaseId: DATABASE_ID,
    collections,
    counts,
  };
}

export function backupFileName(createdAt) {
  const stamp = createdAt.replaceAll(':', '-').replaceAll('.', '-');
  return `olitun-content-backup-${stamp}.json`;
}

export async function createContentBackup({
  databases,
  storage,
  actorUserId,
  createdAt = new Date().toISOString(),
}) {
  const payload = await buildBackupPayload(databases, actorUserId, createdAt);
  const fileName = backupFileName(createdAt);
  const file = InputFile.fromPlainText(
    JSON.stringify(payload, null, 2),
    fileName,
  );
  const uploaded = await storage.createFile(
    BACKUP_BUCKET_ID,
    ID.unique(),
    file,
  );

  return {
    bucketId: BACKUP_BUCKET_ID,
    fileId: uploaded.$id,
    fileName,
    counts: payload.counts,
  };
}

export async function deleteCollectionDocuments(databases, collectionId) {
  let deleted = 0;

  while (true) {
    const result = await databases.listDocuments(DATABASE_ID, collectionId, [
      Query.limit(100),
    ]);

    if (result.documents.length === 0) {
      return deleted;
    }

    for (const document of result.documents) {
      await databases.deleteDocument(DATABASE_ID, collectionId, document.$id);
      deleted += 1;
    }
  }
}

export function sanitizeDocument(doc) {
  if (!doc || typeof doc !== 'object') return {};
  const data = { ...doc };
  for (const key of Object.keys(data)) {
    if (key.startsWith('$')) {
      delete data[key];
    }
  }
  return data;
}

export async function restoreContent({ databases, storage, fileId }) {
  const buffer = await storage.getFileDownload(BACKUP_BUCKET_ID, fileId);
  const backupData = JSON.parse(buffer.toString('utf-8'));
  if (!backupData || typeof backupData !== 'object' || !backupData.collections) {
    throw new Error('Invalid backup file structure.');
  }

  const deleted = {};
  for (const collectionId of CONTENT_COLLECTIONS) {
    deleted[collectionId] = await deleteCollectionDocuments(
      databases,
      collectionId,
    );
  }

  const restored = {};
  for (const collectionId of CONTENT_COLLECTIONS) {
    const docs = backupData.collections[collectionId] || [];
    restored[collectionId] = 0;
    for (const doc of docs) {
      const sanitized = sanitizeDocument(doc);
      await databases.createDocument(
        DATABASE_ID,
        collectionId,
        doc.$id,
        sanitized,
        doc.$permissions
      );
      restored[collectionId] += 1;
    }
  }

  return { restored, deleted };
}

export async function executeAdminRefund({
  databases,
  actorUserId,
  body,
  databaseId = DATABASE_ID,
}) {
  const purchaseId = String(body.purchaseId || '').trim();
  if (!purchaseId) {
    throw Object.assign(new Error('Missing purchase ID.'), { status: 400 });
  }

  // 0. Durable operation identity is required BEFORE any financial
  // bookkeeping mutation. `operationKey` (alias: `idempotencyKey`) is the
  // internal idempotency identity; the optional `gatewayRefundId`
  // (alias: legacy `externalRefundId`-as-gateway) is informational only and
  // never used for identity. Requests without any identity are rejected so
  // every accepted operation owns a claim anchor plus a deterministic audit
  // ID, which is what makes crash-window retry repairable. Keyless writes
  // (full refund committed, audit failed, retry skipping audit repair) are
  // therefore impossible: without a key the request never reaches Phase 1.
  const operationKey = String(
    body.operationKey || body.idempotencyKey || body.externalRefundId || '',
  ).trim();
  if (!operationKey) {
    throw Object.assign(
      new Error(
        'Missing operation identity: provide operationKey (or idempotencyKey).',
      ),
      { status: 400 },
    );
  }
  // Informational gateway-side refund identifier. When the caller passes a
  // legacy `externalRefundId` without a separate gateway field, it doubles
  // as the gateway reference to preserve existing audit-trail content.
  const gatewayRefundId = String(
    body.gatewayRefundId || body.externalRefundId || '',
  ).trim();

  // 1. Transactions are mandatory; fail closed if unavailable before any state changes
  if (
    typeof databases.createTransaction !== 'function' ||
    typeof databases.updateTransaction !== 'function'
  ) {
    throw Object.assign(new Error('Payment transactions are unavailable.'), {
      status: 503,
      code: 503,
    });
  }

  // 2. Fetch current purchase document
  let purchase;
  try {
    purchase = await databases.getDocument(databaseId, 'course_purchases', purchaseId);
  } catch (err) {
    if (err.code === 404 || err.status === 404) {
      throw Object.assign(new Error(`Purchase ${purchaseId} not found.`), { status: 404 });
    }
    throw err;
  }

  const expectedPaise = Math.round(Number(purchase.expectedAmount || 0) * 100);
  const currentRefundedPaise = Number(purchase.refundedAmountPaise || 0);

  // 3. Amount validation: `amountPaise` is the CUMULATIVE refunded total as
  // of this operation (not an incremental delta). Application uses
  // max-floor semantics (see payment_state.js `admin.refund`): the stored
  // cumulative never decreases, concurrent same-key retries converge to the
  // same values, and a purchase is fully refunded once the cumulative total
  // reaches the expected amount. Partial operations therefore pass the
  // running total, not just the latest increment.
  let refundAmountPaise;
  if (body.amountPaise !== undefined) {
    const rawAmount = Number(body.amountPaise);
    if (!Number.isSafeInteger(rawAmount) || rawAmount <= 0) {
      throw Object.assign(
        new Error('Invalid refund amount: amountPaise must be a positive integer.'),
        { status: 400 },
      );
    }
    if (expectedPaise > 0 && rawAmount > expectedPaise) {
      throw Object.assign(
        new Error(`Refund amount (${rawAmount} paise) exceeds purchase amount (${expectedPaise} paise).`),
        { status: 400 },
      );
    }
    refundAmountPaise = rawAmount;
  } else {
    refundAmountPaise = expectedPaise || (Number(purchase.paidAmount || 0) * 100);
    if (!Number.isSafeInteger(refundAmountPaise) || refundAmountPaise <= 0) {
      throw Object.assign(new Error('Unable to determine refund amount from purchase.'), { status: 400 });
    }
  }

  const currency = purchase.currency || 'INR';
  const now = new Date().toISOString();
  const reason = String(body.reason || 'Admin recorded refund').trim();
  const targetRefundedPaise = Math.max(currentRefundedPaise, refundAmountPaise);
  const isFullRefund = !(expectedPaise > 0) || targetRefundedPaise >= expectedPaise;

  // 4. Monotonic epoch computation
  const currentEpoch = Number(purchase.refundEpoch || 0);
  const targetEpoch = currentEpoch + 1;

  // 5. Durable Idempotency & Claim Verification. The claim document ID is
  // derived from the required operation key, so every accepted request owns
  // a recovery anchor before any bookkeeping mutation.
  const claimId = stableId(`refund:${operationKey}`);

  let existingClaim = null;
  try {
    existingClaim = await databases.getDocument(
      databaseId,
      'refund_claims',
      claimId,
    );
  } catch (err) {
    if (err.code !== 404 && err.status !== 404) {
      throw err;
    }
  }

  function assertClaimPayloadBinding(claim) {
    if (
      claim.purchaseId !== purchaseId ||
      claim.amountPaise !== refundAmountPaise ||
      (claim.currency && claim.currency !== currency)
    ) {
      throw Object.assign(
        new Error('Idempotency conflict: operation key was already used with different refund parameters.'),
        { status: 409, code: 409 },
      );
    }
  }

  if (existingClaim) {
    assertClaimPayloadBinding(existingClaim);
    // A repeated gateway reference is informational only: adopt it onto the
    // claim when the claim does not already carry one. Never conflicts.
    if (
      gatewayRefundId &&
      (!existingClaim.refundId || existingClaim.refundId === operationKey) &&
      existingClaim.refundId !== gatewayRefundId
    ) {
      try {
        existingClaim = await databases.updateDocument(
          databaseId,
          'refund_claims',
          claimId,
          { refundId: gatewayRefundId },
        );
      } catch {
        // Best-effort linkage only; the operation proceeds regardless.
      }
    }
    if (existingClaim.status === 'audit_committed' || existingClaim.status === 'committed') {
      return {
        alreadyRefunded: true,
        purchaseId,
        status: purchase.status,
        refundStatus: purchase.refundStatus,
        refundedAmountPaise: purchase.refundedAmountPaise,
        refundEpoch: purchase.refundEpoch,
      };
    }
  }

  // 6. Check if already refunded on purchase (only short-circuit if NOT resuming an incomplete claim)
  const isThisClaimLedgerCommitted = Boolean(
    existingClaim && (
      existingClaim.status === 'ledger_committed' ||
      existingClaim.status === 'audit_committed' ||
      existingClaim.status === 'committed' ||
      (purchase.lastRefundClaimId && purchase.lastRefundClaimId === claimId)
    )
  );
  const isResumingAudit = Boolean(existingClaim && isThisClaimLedgerCommitted);
  const isAlreadyRefunded =
    purchase.status === 'refunded' ||
    purchase.refundStatus === 'fully_refunded' ||
    (expectedPaise > 0 && currentRefundedPaise >= expectedPaise);

  if (isAlreadyRefunded && !isResumingAudit) {
    return {
      alreadyRefunded: true,
      purchaseId,
      status: purchase.status,
      refundStatus: purchase.refundStatus,
      refundedAmountPaise: purchase.refundedAmountPaise,
      refundEpoch: purchase.refundEpoch,
    };
  }

  // 7. Validate current status allows refund (if not resuming audit step)
  if (!isResumingAudit) {
    if (!['verified', 'disputed', 'failed'].includes(purchase.status)) {
      throw Object.assign(
        new Error(`Cannot refund purchase in status '${purchase.status}'.`),
        { status: 409 },
      );
    }
  }

  // 8. Phase 1: Claim Reservation in refund_claims (if not already claimed).
  // `refundId` carries the informational gateway reference (unique index);
  // identity lives in the claim document ID derived from the operation key.
  if (!existingClaim) {
    try {
      existingClaim = await databases.createDocument(
        databaseId,
        'refund_claims',
        claimId,
        {
          refundId: gatewayRefundId || operationKey,
          paymentId: purchase.providerPaymentId || `admin_${purchaseId}`,
          purchaseId,
          amountPaise: refundAmountPaise,
          currency,
          status: 'claimed',
          claimedAt: now,
          committedAt: null,
          lastError: '',
        },
      );
    } catch (claimErr) {
      if (claimErr.code === 409 || claimErr.status === 409) {
        let raced = null;
        try {
          raced = await databases.getDocument(
            databaseId,
            'refund_claims',
            claimId,
          );
        } catch (readErr) {
          if (readErr.code === 404 || readErr.status === 404) {
            // The 409 came from the unique refundId index, not our claim ID:
            // this gateway refund was already recorded under a DIFFERENT
            // operation. Reusing a fresh key cannot recover it; the original
            // operation key must be retried instead. Fail closed, write nothing.
            throw Object.assign(
              new Error(
                'This gateway refund was already recorded under a different operation. Retry with the original operation key.',
              ),
              { status: 409, code: 409 },
            );
          }
          throw readErr;
        }
        existingClaim = raced;
        assertClaimPayloadBinding(existingClaim);
        if (existingClaim.status === 'audit_committed' || existingClaim.status === 'committed') {          return {
            alreadyRefunded: true,
            purchaseId,
            status: purchase.status,
            refundStatus: purchase.refundStatus,
            refundedAmountPaise: purchase.refundedAmountPaise,
            refundEpoch: purchase.refundEpoch,
          };
        }
      } else {
        throw claimErr;
      }
    }
  } else {
    // A repeated gateway reference is informational only: adopt it onto the
    // claim when the claim does not already carry one. Never conflicts.
    if (
      gatewayRefundId &&
      (!existingClaim.refundId || existingClaim.refundId === operationKey) &&
      existingClaim.refundId !== gatewayRefundId
    ) {
      try {
        existingClaim = await databases.updateDocument(
          databaseId,
          'refund_claims',
          claimId,
          { refundId: gatewayRefundId },
        );
      } catch {
        // Best-effort linkage only; the operation proceeds regardless.
      }
    }
  }

  // 9. Phase 2: Update course_purchases via guarded databases (Skipped if ledger was already committed)
  let updatedPurchase = purchase;
  let ledgerAlreadyCommitted = isThisClaimLedgerCommitted;

  if (!ledgerAlreadyCommitted) {
    const guardedDb = withPaymentStateGuard(databases, { event: 'admin.refund' });
    try {
      updatedPurchase = await guardedDb.updateDocument(
        databaseId,
        'course_purchases',
        purchaseId,
        {
          status: isFullRefund ? 'refunded' : purchase.status,
          refundStatus: isFullRefund ? 'fully_refunded' : 'partially_refunded',
          refundedAmountPaise: targetRefundedPaise,
          refundEpoch: targetEpoch,
          lastRefundClaimId: claimId,
        },
      );
    } catch (ledgerErr) {
      if (ledgerErr.code !== 409 && ledgerErr.status !== 409) throw ledgerErr;
      // A concurrent writer moved the ledger under us. Resume (do not
      // duplicate) only when THIS operation's claim shows ledger progress;
      // otherwise the conflict belongs to another operation and the caller
      // must retry with fresh state.
      let recheck = null;
      let freshPurchase = null;
      try {
        recheck = await databases.getDocument(databaseId, 'refund_claims', claimId);
      } catch {
        // Treated as not-committed below.
      }
      try {
        freshPurchase = await databases.getDocument(databaseId, 'course_purchases', purchaseId);
      } catch {
        // Treated as not-committed below.
      }
      const mineCommitted = Boolean(
        recheck &&
          (recheck.status === 'ledger_committed' ||
            recheck.status === 'audit_committed' ||
            recheck.status === 'committed'),
      );
      const pointerMine = Boolean(
        freshPurchase &&
          freshPurchase.lastRefundClaimId &&
          freshPurchase.lastRefundClaimId === claimId,
      );
      if ((mineCommitted || pointerMine) && freshPurchase) {
        existingClaim = recheck || existingClaim;
        updatedPurchase = freshPurchase;
        ledgerAlreadyCommitted = true;
      } else {
        throw ledgerErr;
      }
    }

    if (!ledgerAlreadyCommitted) {
      try {
        await databases.updateDocument(
          databaseId,
          'refund_claims',
          claimId,
          {
            status: 'ledger_committed',
            committedAt: new Date().toISOString(),
          },
        );
      } catch {
        // Non-fatal if claim status update fails after course_purchases is committed
      }
    }
  }

  // 10. Phase 3: Write audit log to admin_audit_logs collection.
  // The audit ID is deterministic per operation key, so retries and
  // concurrent same-key requests converge on exactly one audit row.
  const auditDocId = stableId(`audit:${claimId}`);

  try {
    await databases.createDocument(
      databaseId,
      'admin_audit_logs',
      auditDocId,
      {
        action: 'refund_recorded',
        actorUserId,
        targetType: 'course_purchase',
        targetId: purchaseId,
        metadata: JSON.stringify({
          userId: purchase.userId,
          categoryId: purchase.categoryId,
          operationKey,
          externalRefundId: gatewayRefundId || operationKey,
          reason,
          refundAmountPaise,
          totalRefundedPaise: updatedPurchase.refundedAmountPaise,
          previousStatus: purchase.status,
          newStatus: updatedPurchase.status,
          refundStatus: updatedPurchase.refundStatus,
          refundEpoch: updatedPurchase.refundEpoch || targetEpoch,
        }),
        success: true,
        createdAt: now,
      },
    );
  } catch (auditErr) {
    if (auditErr.code === 409 || auditErr.status === 409) {
      // Audit log already written for this operation (idempotent retry)
    } else {
      throw auditErr;
    }
  }

  // 11. Finalize claim in refund_claims to audit_committed
  try {
    await databases.updateDocument(
      databaseId,
      'refund_claims',
      claimId,
      {
        status: 'audit_committed',
        committedAt: new Date().toISOString(),
      },
    );
  } catch {
    // Non-fatal if status update to audit_committed fails after audit log is created
  }

  return {
    alreadyRefunded: ledgerAlreadyCommitted,
    purchaseId,
    status: updatedPurchase.status,
    refundStatus: updatedPurchase.refundStatus,
    refundedAmountPaise: updatedPurchase.refundedAmountPaise,
    refundEpoch: updatedPurchase.refundEpoch || targetEpoch,
  };
}

function json(res, status, payload) {
  return res.json(payload, status);
}

export default async ({ req, res, log, error }) => {
  try {
    const body = parseBody(req.body);
    const userId = req.headers['x-appwrite-user-id'];
    const invalid = validateRequest({ method: req.method, userId, body });
    if (invalid) {
      return json(res, invalid.status, {
        success: false,
        message: invalid.message,
      });
    }

    const { endpoint, projectId, apiKey } = requireConfig();
    const client = new Client()
      .setEndpoint(endpoint)
      .setProject(projectId)
      .setKey(apiKey);
    const users = new Users(client);

    if (!(await userIsAdmin(users, userId))) {
      return json(res, 403, {
        success: false,
        message: 'Admin team membership required.',
      });
    }

    const databases = new Databases(client);

    if (body.action === 'record_refund') {
      const refundResult = await executeAdminRefund({
        databases,
        actorUserId: userId,
        body,
        databaseId: DATABASE_ID,
      });
      log(
        `Admin maintenance record_refund completed by ${userId} for purchase ${body.purchaseId}.`,
      );
      return json(res, 200, {
        success: true,
        ...refundResult,
      });
    }

    const storage = new Storage(client);
    const backup = await createContentBackup({
      databases,
      storage,
      actorUserId: userId,
    });

    if (body.action === 'backup_content') {
      log(
        `Admin maintenance backup_content completed by ${userId}: ${backup.fileId}.`,
      );
      return json(res, 200, {
        success: true,
        backup,
      });
    }

    if (body.action === 'restore_content') {
      const { restored, deleted } = await restoreContent({
        databases,
        storage,
        fileId: body.fileId,
      });

      log(
        `Admin maintenance restore_content completed by ${userId} using backup ${body.fileId}; safety backup ${backup.fileId}.`,
      );
      return json(res, 200, {
        success: true,
        backup,
        restored,
        deleted,
      });
    }

    const deleted = {};
    for (const collectionId of CONTENT_COLLECTIONS) {
      deleted[collectionId] = await deleteCollectionDocuments(
        databases,
        collectionId,
      );
    }

    log(
      `Admin maintenance wipe_content completed by ${userId}; backup ${backup.fileId}.`,
    );
    return json(res, 200, {
      success: true,
      backup,
      deleted,
    });
  } catch (err) {
    error(err.message || String(err));
    const statusCode = err.status || (Number.isInteger(err.code) && err.code >= 400 && err.code < 600 ? err.code : 500);
    return json(res, statusCode, {
      success: false,
      message: err.message || 'Admin maintenance failed.',
    });
  }
};
