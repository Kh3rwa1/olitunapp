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

  // 3. Amount validation: must be a positive safe integer and not exceed expected amount
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

  // 5. Durable Idempotency & Claim Verification
  const externalRefundId = String(body.externalRefundId || body.idempotencyKey || '').trim();
  const claimId = externalRefundId ? stableId(`refund:${externalRefundId}`) : null;

  let existingClaim = null;
  if (claimId) {
    try {
      existingClaim = await databases.getDocument(databaseId, 'refund_claims', claimId);
    } catch (err) {
      if (err.code !== 404 && err.status !== 404) {
        throw err;
      }
    }
  }

  function assertClaimPayloadBinding(claim) {
    if (
      claim.purchaseId !== purchaseId ||
      claim.amountPaise !== refundAmountPaise ||
      (claim.currency && claim.currency !== currency)
    ) {
      throw Object.assign(
        new Error('Idempotency conflict: externalRefundId was already used with different refund parameters.'),
        { status: 409, code: 409 },
      );
    }
  }

  if (existingClaim) {
    assertClaimPayloadBinding(existingClaim);
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
  const isResumingAudit = existingClaim && existingClaim.status === 'ledger_committed';
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

  // 8. Phase 1: Claim Reservation in refund_claims (if not already claimed)
  if (claimId && !existingClaim) {
    try {
      existingClaim = await databases.createDocument(
        databaseId,
        'refund_claims',
        claimId,
        {
          refundId: externalRefundId,
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
        existingClaim = await databases.getDocument(databaseId, 'refund_claims', claimId);
        assertClaimPayloadBinding(existingClaim);
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
      } else {
        throw claimErr;
      }
    }
  }

  // 9. Phase 2: Update course_purchases via guarded databases (Skipped if ledger was already committed)
  let updatedPurchase = purchase;
  const isLedgerAlreadyCommitted = Boolean(
    existingClaim && (existingClaim.status === 'ledger_committed' || existingClaim.status === 'committed')
  );

  if (!isLedgerAlreadyCommitted) {
    const guardedDb = withPaymentStateGuard(databases, { event: 'admin.refund' });
    updatedPurchase = await guardedDb.updateDocument(
      databaseId,
      'course_purchases',
      purchaseId,
      {
        status: isFullRefund ? 'refunded' : purchase.status,
        refundStatus: isFullRefund ? 'fully_refunded' : 'partially_refunded',
        refundedAmountPaise: targetRefundedPaise,
        refundEpoch: targetEpoch,
      },
    );

    if (claimId) {
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

  // 10. Phase 3: Write audit log to admin_audit_logs collection (fail-closed: do not swallow error)
  await databases.createDocument(
    databaseId,
    'admin_audit_logs',
    ID.unique(),
    {
      action: 'refund_recorded',
      actorUserId,
      targetType: 'course_purchase',
      targetId: purchaseId,
      metadata: JSON.stringify({
        userId: purchase.userId,
        categoryId: purchase.categoryId,
        externalRefundId,
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

  // 11. Finalize claim in refund_claims to audit_committed
  if (claimId) {
    try {
      await databases.updateDocument(
        databaseId,
        'refund_claims',
        claimId,
        {
          status: 'audit_committed',
        },
      );
    } catch {
      // Non-fatal if status update to audit_committed fails after audit log is created
    }
  }

  return {
    alreadyRefunded: isLedgerAlreadyCommitted,
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
