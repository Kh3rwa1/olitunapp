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

  // 1. Fetch current purchase document
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
  const isAlreadyRefunded =
    purchase.status === 'refunded' ||
    purchase.refundStatus === 'fully_refunded' ||
    (expectedPaise > 0 && Number(purchase.refundedAmountPaise || 0) >= expectedPaise);

  if (isAlreadyRefunded) {
    return {
      alreadyRefunded: true,
      purchaseId,
      status: purchase.status,
      refundStatus: purchase.refundStatus,
      refundedAmountPaise: purchase.refundedAmountPaise,
    };
  }

  // 2. Validate current status allows refund
  if (!['verified', 'disputed', 'failed'].includes(purchase.status)) {
    throw Object.assign(
      new Error(`Cannot refund purchase in status '${purchase.status}'.`),
      { status: 409 },
    );
  }

  const now = new Date().toISOString();
  const reason = String(body.reason || 'Admin recorded refund').trim();
  const externalRefundId = String(body.externalRefundId || body.idempotencyKey || '').trim();
  const refundAmountPaise = Number(body.amountPaise) || expectedPaise || (Number(purchase.paidAmount || 0) * 100);

  // 3. Monotonic epoch computation
  const currentEpoch = Number(purchase.refundEpoch || 0);
  const targetEpoch = currentEpoch + 1;

  // 4. Update course_purchases via guarded databases
  let guardedDb = databases;
  if (typeof databases.createTransaction === 'function') {
    guardedDb = withPaymentStateGuard(databases, { event: 'admin.refund' });
  }

  const updatedPurchase = await guardedDb.updateDocument(
    databaseId,
    'course_purchases',
    purchaseId,
    {
      status: 'refunded',
      refundStatus: 'fully_refunded',
      refundedAmountPaise: Math.max(Number(purchase.refundedAmountPaise || 0), refundAmountPaise),
      refundEpoch: targetEpoch,
    },
  );

  // 5. Write audit log to admin_audit_logs collection (fail-safe)
  try {
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
          previousStatus: purchase.status,
          refundEpoch: targetEpoch,
        }),
        success: true,
        createdAt: now,
      },
    );
  } catch (auditErr) {
    console.error(`Warning: Failed to write admin audit log for refund: ${auditErr.message}`);
  }

  return {
    alreadyRefunded: false,
    purchaseId,
    status: 'refunded',
    refundStatus: 'fully_refunded',
    refundedAmountPaise: updatedPurchase.refundedAmountPaise,
    refundEpoch: targetEpoch,
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
