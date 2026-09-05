import { Client, Users, Databases, Storage, Query } from 'node-appwrite';
import crypto from 'node:crypto';

const USER_DATA_COLLECTIONS = [
  'user_preferences', 'user_mistakes', 'mistake_review_sessions',
  'bakhed_listening_progress', 'learning_analytics_events', 'user_badges',
  'reward_events', 'binti_guru_waitlist',
];
const ANONYMIZED_USER_ID = 'anonymized_deleted_user';
const PAGE_LIMIT = 100;
const MAX_ITERATIONS = 50;
const STORAGE_ATTEMPTS = 3;

export const ERROR_CODES = {
  STATE_INITIALIZATION_FAILED: 'STATE_INITIALIZATION_FAILED',
  COLLECTION_QUERY_FAILED: 'COLLECTION_QUERY_FAILED',
  DOCUMENT_DELETE_FAILED: 'DOCUMENT_DELETE_FAILED',
  STORAGE_DELETE_FAILED: 'STORAGE_DELETE_FAILED',
  ANONYMIZATION_FAILED: 'ANONYMIZATION_FAILED',
  VERIFICATION_FAILED: 'VERIFICATION_FAILED',
  AUTH_DELETE_FAILED: 'AUTH_DELETE_FAILED',
  STATE_TRANSITION_FAILED: 'STATE_TRANSITION_FAILED',
  ITERATION_LIMIT_EXCEEDED: 'ITERATION_LIMIT_EXCEEDED',
};

function getDerivedKey(secret, salt = 'olitun_deletion_v1') {
  if (!secret) throw new Error('DELETION_HMAC_SECRET environment variable is missing');
  return crypto.pbkdf2Sync(secret, salt, 100000, 32, 'sha256');
}

export function generatePseudonymousId(userId, hmacSecret) {
  if (!hmacSecret) throw new Error('DELETION_HMAC_SECRET environment variable is missing');
  return crypto.createHmac('sha256', hmacSecret).update(userId).digest('hex').substring(0, 32);
}

export function deletionRequestId(userId, hmacSecret) {
  return `del_${generatePseudonymousId(userId, hmacSecret)}`;
}

export function encryptUserId(userId, hmacSecret) {
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', getDerivedKey(hmacSecret), iv);
  const encrypted = Buffer.concat([cipher.update(userId, 'utf8'), cipher.final()]);
  return JSON.stringify({ v: 1, iv: iv.toString('hex'), ct: encrypted.toString('hex'), tag: cipher.getAuthTag().toString('hex') });
}

export function decryptUserId(payload, primarySecret, previousSecrets = []) {
  if (!payload) return null;
  let parsed;
  try { parsed = typeof payload === 'string' ? JSON.parse(payload) : payload; } catch (_) { return null; }
  if (!parsed?.iv || !parsed?.ct || !parsed?.tag) return null;
  for (const secret of [primarySecret, ...previousSecrets].filter(Boolean)) {
    try {
      const decipher = crypto.createDecipheriv('aes-256-gcm', getDerivedKey(secret), Buffer.from(parsed.iv, 'hex'));
      decipher.setAuthTag(Buffer.from(parsed.tag, 'hex'));
      return Buffer.concat([decipher.update(Buffer.from(parsed.ct, 'hex')), decipher.final()]).toString('utf8');
    } catch (_) {}
  }
  return null;
}

export async function reconcileOrphanedAuthDeletions({ databases, users, databaseId, hmacSecret = process.env.DELETION_HMAC_SECRET, previousSecrets = process.env.DELETION_OLD_HMAC_SECRETS ? process.env.DELETION_OLD_HMAC_SECRETS.split(',') : [], log = console.log, error = console.error }) {
  const correlationId = crypto.randomUUID();
  const stats = { scanned: 0, completed: 0, failed: 0 };
  log(`[${correlationId}] [ORPHAN_RECOVERY_START] Initiating scan`);
  try {
    const result = await databases.listDocuments(databaseId, 'deletion_requests', [Query.equal('status', ['cleanup_complete', 'auth_deleted']), Query.limit(50)]);
    stats.scanned = result.documents.length;
    for (const doc of result.documents) {
      try {
        const userId = decryptUserId(doc.encryptedUserId, hmacSecret, previousSecrets) || (doc.userId && doc.userId !== ANONYMIZED_USER_ID ? doc.userId : null);
        if (!userId) { stats.failed++; continue; }
        let status = doc.status;
        if (status === 'cleanup_complete') {
          let exists = false;
          try { await users.get(userId); exists = true; } catch (e) { if (e.code !== 404) throw e; }
          if (exists) { try { await users.delete(userId); } catch (e) { if (e.code !== 404) throw e; } }
          await databases.updateDocument(databaseId, 'deletion_requests', doc.$id, { status: 'auth_deleted', updatedAt: new Date().toISOString() });
          status = 'auth_deleted';
        }
        if (status === 'auth_deleted') {
          await databases.updateDocument(databaseId, 'deletion_requests', doc.$id, { status: 'completed', updatedAt: new Date().toISOString() });
          stats.completed++;
        }
      } catch (_) { stats.failed++; error(`[${correlationId}] [ORPHAN_RECOVERY_FAILED] Code: ${ERROR_CODES.STATE_TRANSITION_FAILED}`); }
    }
  } catch (_) { error(`[${correlationId}] [ORPHAN_RECOVERY_SCAN_FAILED] Code: ${ERROR_CODES.STATE_INITIALIZATION_FAILED}`); }
  return stats;
}

async function deleteStorageFile(storage, asset) {
  for (let attempt = 1; attempt <= STORAGE_ATTEMPTS; attempt++) {
    try { await storage.deleteFile(asset.bucketId, asset.fileId); return true; }
    catch (e) {
      if (e.code === 404) return true;
      if (attempt === STORAGE_ATTEMPTS) return false;
    }
  }
  return false;
}

export default async ({ req, res, log = console.log, error = console.error, databases: injectedDb, users: injectedUsers, storage: injectedStorage }) => {
  const correlationId = crypto.randomUUID();
  if (req.method !== 'POST') return res.json({ ok: false, code: 'method_not_allowed', message: 'Only POST is allowed' }, 405);
  const userId = req.headers['x-appwrite-user-id'] || process.env.APPWRITE_FUNCTION_USER_ID;
  if (!userId) return res.json({ ok: false, code: 'unauthenticated', message: 'Authentication required' }, 401);

  const endpoint = process.env.APPWRITE_FUNCTION_API_ENDPOINT || process.env.APPWRITE_ENDPOINT;
  const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID || process.env.APPWRITE_PROJECT_ID;
  const apiKey = process.env.APPWRITE_FUNCTION_API_KEY || process.env.APPWRITE_API_KEY;
  const databaseId = process.env.APPWRITE_DATABASE_ID;
  const secret = process.env.DELETION_HMAC_SECRET;
  if (!endpoint || !projectId || !apiKey || !databaseId || !secret) return res.json({ ok: false, code: 'server_misconfiguration', message: 'Server configuration error' }, 500);

  const client = new Client().setEndpoint(endpoint).setProject(projectId).setKey(apiKey);
  const databases = injectedDb || new Databases(client);
  const users = injectedUsers || new Users(client);
  const storage = injectedStorage || new Storage(client);
  const pseudo = generatePseudonymousId(userId, secret);
  const requestId = deletionRequestId(userId, secret);
  let stateDoc;
  try {
    try {
      stateDoc = await databases.getDocument(databaseId, 'deletion_requests', requestId);
      if (stateDoc.status === 'completed') return res.json({ ok: true, code: 'account_deleted', message: 'Account deletion was already completed' });
      stateDoc = await databases.updateDocument(databaseId, 'deletion_requests', requestId, { status: 'in_progress', encryptedUserId: encryptUserId(userId, secret), retryCount: (stateDoc.retryCount || 0) + 1, updatedAt: new Date().toISOString() });
    } catch (e) {
      if (e.code !== 404) throw e;
      stateDoc = await databases.createDocument(databaseId, 'deletion_requests', requestId, { userId: ANONYMIZED_USER_ID, pseudonymousId: pseudo, encryptedUserId: encryptUserId(userId, secret), status: 'in_progress', retryCount: 1, lastError: null, createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
    }
  } catch (_) {
    return res.json({ ok: false, code: 'deletion_failed', message: 'Failed to record deletion state machine. Deletion aborted for safety.' }, 500);
  }

  let cleanupSuccess = true;
  let failure = null;
  const fail = (code) => { cleanupSuccess = false; failure = code; };
  try {
    for (const collection of USER_DATA_COLLECTIONS) {
      let exhausted = true;
      try {
        for (let i = 0; i < MAX_ITERATIONS; i++) {
          const page = await databases.listDocuments(databaseId, collection, [Query.equal('userId', userId), Query.limit(PAGE_LIMIT)]);
          if (page.documents.length === 0) { exhausted = false; break; }
          for (const doc of page.documents) {
            try { await databases.deleteDocument(databaseId, collection, doc.$id); }
            catch (e) { if (e.code !== 404) fail(ERROR_CODES.DOCUMENT_DELETE_FAILED); }
          }
        }
        if (exhausted) {
          const remaining = await databases.listDocuments(databaseId, collection, [Query.equal('userId', userId), Query.limit(1)]);
          if (remaining.documents.length) fail(ERROR_CODES.ITERATION_LIMIT_EXCEEDED);
        }
      } catch (_) { fail(ERROR_CODES.COLLECTION_QUERY_FAILED); }
    }

    try {
      let exhausted = true;
      for (let i = 0; i < MAX_ITERATIONS; i++) {
        const page = await databases.listDocuments(databaseId, 'user_assets', [Query.equal('userId', userId), Query.limit(PAGE_LIMIT)]);
        if (page.documents.length === 0) { exhausted = false; break; }
        let retryableFailure = false;
        for (const asset of page.documents) {
          if (!(await deleteStorageFile(storage, asset))) {
            fail(ERROR_CODES.STORAGE_DELETE_FAILED);
            retryableFailure = true;
            continue;
          }
          try { await databases.deleteDocument(databaseId, 'user_assets', asset.$id); }
          catch (e) { if (e.code !== 404) fail(ERROR_CODES.DOCUMENT_DELETE_FAILED); }
        }
        if (retryableFailure) { exhausted = false; break; }
      }
      if (exhausted) {
        const remaining = await databases.listDocuments(databaseId, 'user_assets', [Query.equal('userId', userId), Query.limit(1)]);
        if (remaining.documents.length) fail(ERROR_CODES.ITERATION_LIMIT_EXCEEDED);
      }
    } catch (_) { fail(ERROR_CODES.COLLECTION_QUERY_FAILED); }

    try {
      let exhausted = true;
      for (let i = 0; i < MAX_ITERATIONS; i++) {
        const page = await databases.listDocuments(databaseId, 'course_purchases', [Query.equal('userId', userId), Query.limit(PAGE_LIMIT)]);
        const pending = page.documents.filter((p) => p.userId === userId);
        if (pending.length === 0) { exhausted = false; break; }
        for (const purchase of pending) {
          try { await databases.updateDocument(databaseId, 'course_purchases', purchase.$id, { userId: ANONYMIZED_USER_ID, userEmail: 'anonymized@deleted.local', userName: 'Anonymized User', pseudonymousId: pseudo }); }
          catch (_) { fail(ERROR_CODES.ANONYMIZATION_FAILED); }
        }
      }
      if (exhausted) fail(ERROR_CODES.ITERATION_LIMIT_EXCEEDED);
    } catch (_) { fail(ERROR_CODES.COLLECTION_QUERY_FAILED); }

    if (cleanupSuccess) {
      for (const collection of USER_DATA_COLLECTIONS) {
        const check = await databases.listDocuments(databaseId, collection, [Query.equal('userId', userId), Query.limit(1)]);
        if (check.documents.length) { fail(ERROR_CODES.VERIFICATION_FAILED); break; }
      }
      if (cleanupSuccess) {
        const assets = await databases.listDocuments(databaseId, 'user_assets', [Query.equal('userId', userId), Query.limit(1)]);
        if (assets.documents.length) fail(ERROR_CODES.VERIFICATION_FAILED);
      }
      if (cleanupSuccess) {
        const purchases = await databases.listDocuments(databaseId, 'course_purchases', [Query.equal('userId', userId), Query.limit(1)]);
        if (purchases.documents.some((p) => p.userId === userId)) fail(ERROR_CODES.VERIFICATION_FAILED);
      }
    }

    if (!cleanupSuccess) {
      try { await databases.updateDocument(databaseId, 'deletion_requests', requestId, { status: 'cleanup_failed', lastError: failure || ERROR_CODES.VERIFICATION_FAILED, updatedAt: new Date().toISOString() }); } catch (_) {}
      return res.json({ ok: false, code: 'deletion_failed', message: 'An error occurred during account deletion. Partial progress saved for retry.' }, 500);
    }

    try { await databases.updateDocument(databaseId, 'deletion_requests', requestId, { status: 'cleanup_complete', updatedAt: new Date().toISOString() }); }
    catch (_) { return res.json({ ok: false, code: 'deletion_failed', message: 'Failed state machine transition to cleanup_complete. Auth deletion aborted.' }, 500); }

    try { await users.delete(userId); } catch (e) { if (e.code !== 404) throw e; }
    try { await databases.updateDocument(databaseId, 'deletion_requests', requestId, { status: 'auth_deleted', updatedAt: new Date().toISOString() }); } catch (_) {}
    try { await databases.updateDocument(databaseId, 'deletion_requests', requestId, { status: 'completed', updatedAt: new Date().toISOString() }); }
    catch (_) { return res.json({ ok: false, code: 'state_update_failed', authDeleted: true, message: 'Account deleted; final cleanup reconciliation is pending.' }, 500); }
    log(`[${correlationId}] [DELETION_COMPLETED] Account deletion successfully finalized`);
    return res.json({ ok: true, code: 'account_deleted', message: 'Account and associated personal data successfully deleted' });
  } catch (_) {
    try { await databases.updateDocument(databaseId, 'deletion_requests', requestId, { status: 'cleanup_failed', lastError: failure || ERROR_CODES.STATE_TRANSITION_FAILED, updatedAt: new Date().toISOString() }); } catch (_) {}
    error(`[${correlationId}] [GLOBAL_CATCH] Code: ${failure || ERROR_CODES.STATE_TRANSITION_FAILED}`);
    return res.json({ ok: false, code: 'deletion_failed', message: 'An error occurred during account deletion. Partial progress saved for retry.' }, 500);
  }
};
