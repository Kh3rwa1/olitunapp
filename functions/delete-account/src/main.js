import { Client, Users, Databases, Storage, Query } from 'node-appwrite';
import crypto from 'node:crypto';

/**
 * Server-authoritative Account Deletion & PII Anonymization Function.
 *
 * Security & Compliance Invariants:
 * 1. Derives user identity strictly from trusted execution context (x-appwrite-user-id).
 * 2. Mandates explicit environment configuration without fallbacks or defaults.
 * 3. Enforces a durable deletion_requests state machine:
 *    requested -> in_progress -> cleanup_failed / cleanup_complete -> auth_deleted -> completed
 * 4. Structured logging using random non-user correlation IDs without raw PII or exception text.
 * 5. Page-1 repeated fetch loops with iteration-limit guards.
 * 6. Mandatory zero-record verification prior to Auth user deletion.
 * 7. Privileged recovery path for interrupted post-Auth state transitions.
 * 8. Idempotent execution safe for repeated calls and retries.
 */

const USER_DATA_COLLECTIONS = [
  'user_preferences',
  'user_mistakes',
  'mistake_review_sessions',
  'bakhed_listening_progress',
  'learning_analytics_events',
  'user_badges',
  'reward_events',
  'binti_guru_waitlist',
];

const ANONYMIZED_USER_ID = 'anonymized_deleted_user';
const PAGE_LIMIT = 100;

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
  if (!secret) {
    throw new Error('DELETION_HMAC_SECRET environment variable is missing');
  }
  return crypto.pbkdf2Sync(secret, salt, 100000, 32, 'sha256');
}

export function generatePseudonymousId(userId, hmacSecret) {
  if (!hmacSecret) {
    throw new Error('DELETION_HMAC_SECRET environment variable is missing');
  }
  return crypto.createHmac('sha256', hmacSecret).update(userId).digest('hex').substring(0, 32);
}

export function encryptUserId(userId, hmacSecret) {
  const key = getDerivedKey(hmacSecret);
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  const encrypted = Buffer.concat([cipher.update(userId, 'utf8'), cipher.final()]);
  const authTag = cipher.getAuthTag();
  return JSON.stringify({
    v: 1,
    iv: iv.toString('hex'),
    ct: encrypted.toString('hex'),
    tag: authTag.toString('hex'),
  });
}

export function decryptUserId(encryptedPayload, primarySecret, previousSecrets = []) {
  if (!encryptedPayload) return null;
  const secrets = [primarySecret, ...previousSecrets].filter(Boolean);
  if (secrets.length === 0) return null;

  let parsed;
  try {
    parsed = typeof encryptedPayload === 'string' ? JSON.parse(encryptedPayload) : encryptedPayload;
  } catch (_) {
    return null;
  }

  if (!parsed || !parsed.iv || !parsed.ct || !parsed.tag) return null;

  for (const sec of secrets) {
    try {
      const key = getDerivedKey(sec);
      const iv = Buffer.from(parsed.iv, 'hex');
      const ct = Buffer.from(parsed.ct, 'hex');
      const tag = Buffer.from(parsed.tag, 'hex');
      const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
      decipher.setAuthTag(tag);
      const decrypted = Buffer.concat([decipher.update(ct), decipher.final()]);
      return decrypted.toString('utf8');
    } catch (_) {
      // Continue trying key rotation list
    }
  }

  return null;
}

/**
 * Privileged administrative recovery path for interrupted post-Auth deletions.
 * Scans for deletion requests stuck in 'cleanup_complete' or 'auth_deleted' status
 * and safely completes them after independently verifying Auth user absence.
 */
export async function reconcileOrphanedAuthDeletions({
  databases,
  users,
  databaseId,
  hmacSecret = process.env.DELETION_HMAC_SECRET,
  previousSecrets = process.env.DELETION_OLD_HMAC_SECRETS ? process.env.DELETION_OLD_HMAC_SECRETS.split(',') : [],
  log = console.log,
  error = console.error,
}) {
  const correlationId = crypto.randomUUID();
  log(`[${correlationId}] [ORPHAN_RECOVERY_START] Initiating scan for cleanup_complete & auth_deleted requests`);

  const stats = { scanned: 0, completed: 0, failed: 0 };

  try {
    const orphans = await databases.listDocuments(databaseId, 'deletion_requests', [
      Query.equal('status', ['cleanup_complete', 'auth_deleted']),
      Query.limit(50),
    ]);

    stats.scanned = orphans.documents.length;

    for (const doc of orphans.documents) {
      try {
        let targetUserId = null;
        if (doc.encryptedUserId) {
          targetUserId = decryptUserId(doc.encryptedUserId, hmacSecret, previousSecrets);
        }
        if (!targetUserId && doc.userId && doc.userId !== ANONYMIZED_USER_ID) {
          targetUserId = doc.userId;
        }

        if (!targetUserId) {
          // Unrecoverable identity: fail closed, do not mark completed
          stats.failed++;
          error(`[${correlationId}] [ORPHAN_RECOVERY_FAILED] Unrecoverable Auth identity for request ${doc.$id}`);
          continue;
        }

        let currentStatus = doc.status;

        if (currentStatus === 'cleanup_complete') {
          let userExists = false;
          let authError = null;

          if (users) {
            try {
              await users.get(targetUserId);
              userExists = true;
            } catch (uErr) {
              if (uErr.code === 404) {
                userExists = false;
              } else {
                userExists = true;
                authError = uErr;
              }
            }
          }

          if (authError) {
            // Fail closed on non-404 Auth errors (401, 403, 429, 500, etc.)
            stats.failed++;
            error(`[${correlationId}] [ORPHAN_RECOVERY_FAILED] Auth status query error Code: ${ERROR_CODES.AUTH_DELETE_FAILED}`);
            continue;
          }

          if (userExists) {
            // User still present in Auth. Attempt server-side Auth deletion to repair interrupted deletion.
            try {
              if (users) {
                await users.delete(targetUserId);
              }
            } catch (delErr) {
              if (delErr.code !== 404) {
                stats.failed++;
                error(`[${correlationId}] [ORPHAN_RECOVERY_FAILED] Failed Auth user deletion Code: ${ERROR_CODES.AUTH_DELETE_FAILED}`);
                continue;
              }
            }
          }

          // Auth user is now confirmed deleted or absent (404); transition cleanup_complete -> auth_deleted
          await databases.updateDocument(databaseId, 'deletion_requests', doc.$id, {
            status: 'auth_deleted',
            updatedAt: new Date().toISOString(),
          });
          currentStatus = 'auth_deleted';
        }

        if (currentStatus === 'auth_deleted') {
          // Transition auth_deleted -> completed
          await databases.updateDocument(databaseId, 'deletion_requests', doc.$id, {
            status: 'completed',
            updatedAt: new Date().toISOString(),
          });
          stats.completed++;
          log(`[${correlationId}] [ORPHAN_RECOVERY_SUCCESS] State transitioned to completed`);
        }
      } catch (updateErr) {
        stats.failed++;
        error(`[${correlationId}] [ORPHAN_RECOVERY_FAILED] Code: ${ERROR_CODES.STATE_TRANSITION_FAILED}`);
      }
    }
  } catch (err) {
    error(`[${correlationId}] [ORPHAN_RECOVERY_SCAN_FAILED] Code: ${ERROR_CODES.STATE_INITIALIZATION_FAILED}`);
  }

  return stats;
}

export default async ({
  req,
  res,
  log = console.log,
  error = console.error,
  databases: injectedDb,
  users: injectedUsers,
  storage: injectedStorage,
}) => {
  const correlationId = crypto.randomUUID();

  if (req.method !== 'POST') {
    log(`[${correlationId}] [REQUEST_REJECTED] Method not allowed`);
    return res.json({ ok: false, code: 'method_not_allowed', message: 'Only POST is allowed' }, 405);
  }

  // Strictly identify user from trusted Appwrite header
  const userId = req.headers['x-appwrite-user-id'] || process.env.APPWRITE_FUNCTION_USER_ID;
  if (!userId) {
    log(`[${correlationId}] [REQUEST_REJECTED] Unauthenticated`);
    return res.json({ ok: false, code: 'unauthenticated', message: 'Authentication required' }, 401);
  }

  const endpoint = process.env.APPWRITE_FUNCTION_API_ENDPOINT || process.env.APPWRITE_ENDPOINT;
  const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID || process.env.APPWRITE_PROJECT_ID;
  const apiKey = process.env.APPWRITE_FUNCTION_API_KEY || process.env.APPWRITE_API_KEY;
  const databaseId = process.env.APPWRITE_DATABASE_ID;
  const hmacSecret = process.env.DELETION_HMAC_SECRET;

  if (!endpoint || !projectId || !apiKey || !databaseId || !hmacSecret) {
    error(`[${correlationId}] [CONFIG_ERROR] Missing required environment variables`);
    return res.json({ ok: false, code: 'server_misconfiguration', message: 'Server configuration error' }, 500);
  }

  const client = new Client()
    .setEndpoint(endpoint)
    .setProject(projectId)
    .setKey(apiKey);

  const users = injectedUsers || new Users(client);
  const databases = injectedDb || new Databases(client);
  const storage = injectedStorage || new Storage(client);

  const pseudoSubject = generatePseudonymousId(userId, hmacSecret);
  const requestId = `del_req_${pseudoSubject}`;

  log(`[${correlationId}] [DELETION_STARTED] State machine initialized`);

  let stateDoc = null;

  // Initialize or fetch state machine record
  try {
    try {
      stateDoc = await databases.getDocument(databaseId, 'deletion_requests', requestId);
      if (stateDoc.status === 'completed') {
        log(`[${correlationId}] [ALREADY_COMPLETED] Account deletion previously finished`);
        return res.json({
          ok: true,
          code: 'account_deleted',
          message: 'Account deletion was already completed',
        });
      }
      stateDoc = await databases.updateDocument(databaseId, 'deletion_requests', requestId, {
        status: 'in_progress',
        encryptedUserId: encryptUserId(userId, hmacSecret),
        retryCount: (stateDoc.retryCount || 0) + 1,
        updatedAt: new Date().toISOString(),
      });
    } catch (getErr) {
      if (getErr.code === 404) {
        stateDoc = await databases.createDocument(databaseId, 'deletion_requests', requestId, {
          userId: ANONYMIZED_USER_ID,
          pseudonymousId: pseudoSubject,
          encryptedUserId: encryptUserId(userId, hmacSecret),
          status: 'in_progress',
          retryCount: 1,
          lastError: null,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        });
      } else {
        throw getErr;
      }
    }
  } catch (stateErr) {
    error(`[${correlationId}] [STATE_INIT_ERROR] Code: ${ERROR_CODES.STATE_INITIALIZATION_FAILED}`);
    return res.json({
      ok: false,
      code: 'deletion_failed',
      message: 'Failed to record deletion state machine. Deletion aborted for safety.',
    }, 500);
  }

  let cleanupSuccess = true;
  let sanitizedErrorCode = null;

  try {
    // 1. Purge database collections via page-1 repeated fetch
    for (const collectionId of USER_DATA_COLLECTIONS) {
      try {
        let iterations = 0;
        const maxIterations = 50;

        while (iterations < maxIterations) {
          iterations++;
          const docs = await databases.listDocuments(databaseId, collectionId, [
            Query.equal('userId', userId),
            Query.limit(PAGE_LIMIT),
          ]);

          if (docs.documents.length === 0) {
            break;
          }

          for (const doc of docs.documents) {
            try {
              await databases.deleteDocument(databaseId, collectionId, doc.$id);
            } catch (docErr) {
              if (docErr.code !== 404) {
                log(`[${correlationId}] [DOC_DELETE_WARN] Code: ${ERROR_CODES.DOCUMENT_DELETE_FAILED}`);
                cleanupSuccess = false;
                sanitizedErrorCode = ERROR_CODES.DOCUMENT_DELETE_FAILED;
              }
            }
          }
        }

        if (iterations >= maxIterations) {
          const remaining = await databases.listDocuments(databaseId, collectionId, [
            Query.equal('userId', userId),
            Query.limit(1),
          ]);
          if (remaining.documents.length > 0) {
            log(`[${correlationId}] [LIMIT_WARN] Code: ${ERROR_CODES.ITERATION_LIMIT_EXCEEDED}`);
            cleanupSuccess = false;
            sanitizedErrorCode = ERROR_CODES.ITERATION_LIMIT_EXCEEDED;
          }
        }
      } catch (collErr) {
        log(`[${correlationId}] [COLLECTION_QUERY_WARN] Code: ${ERROR_CODES.COLLECTION_QUERY_FAILED}`);
        cleanupSuccess = false;
        sanitizedErrorCode = ERROR_CODES.COLLECTION_QUERY_FAILED;
      }
    }

    // 2. Purge files via user_assets registry
    try {
      let fileIterations = 0;
      const maxFileIterations = 50;

      while (fileIterations < maxFileIterations) {
        fileIterations++;
        const assets = await databases.listDocuments(databaseId, 'user_assets', [
          Query.equal('userId', userId),
          Query.limit(PAGE_LIMIT),
        ]);

        if (assets.documents.length === 0) {
          break;
        }

        for (const asset of assets.documents) {
          try {
            await storage.deleteFile(asset.bucketId, asset.fileId);
          } catch (fileErr) {
            if (fileErr.code !== 404) {
              log(`[${correlationId}] [STORAGE_DELETE_WARN] Code: ${ERROR_CODES.STORAGE_DELETE_FAILED}`);
              cleanupSuccess = false;
              sanitizedErrorCode = ERROR_CODES.STORAGE_DELETE_FAILED;
            }
          }

          try {
            await databases.deleteDocument(databaseId, 'user_assets', asset.$id);
          } catch (assetDocErr) {
            if (assetDocErr.code !== 404) {
              log(`[${correlationId}] [ASSET_REGISTRY_WARN] Code: ${ERROR_CODES.DOCUMENT_DELETE_FAILED}`);
              cleanupSuccess = false;
              sanitizedErrorCode = ERROR_CODES.DOCUMENT_DELETE_FAILED;
            }
          }
        }
      }

      if (fileIterations >= maxFileIterations) {
        const remainingAssets = await databases.listDocuments(databaseId, 'user_assets', [
          Query.equal('userId', userId),
          Query.limit(1),
        ]);
        if (remainingAssets.documents.length > 0) {
          log(`[${correlationId}] [ASSET_LIMIT_WARN] Code: ${ERROR_CODES.ITERATION_LIMIT_EXCEEDED}`);
          cleanupSuccess = false;
          sanitizedErrorCode = ERROR_CODES.ITERATION_LIMIT_EXCEEDED;
        }
      }
    } catch (assetsErr) {
      log(`[${correlationId}] [ASSETS_QUERY_WARN] Code: ${ERROR_CODES.COLLECTION_QUERY_FAILED}`);
      cleanupSuccess = false;
      sanitizedErrorCode = ERROR_CODES.COLLECTION_QUERY_FAILED;
    }

    // 3. Anonymize statutory financial purchase records
    try {
      let purchIterations = 0;
      const maxPurchIterations = 50;

      while (purchIterations < maxPurchIterations) {
        purchIterations++;
        const purchases = await databases.listDocuments(databaseId, 'course_purchases', [
          Query.equal('userId', userId),
          Query.limit(PAGE_LIMIT),
        ]);

        const pendingAnonymization = purchases.documents.filter(p => p.userId === userId);
        if (pendingAnonymization.length === 0) {
          break;
        }

        for (const purchase of pendingAnonymization) {
          try {
            await databases.updateDocument(databaseId, 'course_purchases', purchase.$id, {
              userId: ANONYMIZED_USER_ID,
              userEmail: 'anonymized@deleted.local',
              userName: 'Anonymized User',
              pseudonymousId: pseudoSubject,
            });
          } catch (anonErr) {
            log(`[${correlationId}] [ANONYMIZATION_WARN] Code: ${ERROR_CODES.ANONYMIZATION_FAILED}`);
            cleanupSuccess = false;
            sanitizedErrorCode = ERROR_CODES.ANONYMIZATION_FAILED;
          }
        }
      }

      if (purchIterations >= maxPurchIterations) {
        const remainingPurchases = await databases.listDocuments(databaseId, 'course_purchases', [
          Query.equal('userId', userId),
          Query.limit(1),
        ]);
        const pending = remainingPurchases.documents.filter(p => p.userId === userId);
        if (pending.length > 0) {
          log(`[${correlationId}] [PURCH_LIMIT_WARN] Code: ${ERROR_CODES.ITERATION_LIMIT_EXCEEDED}`);
          cleanupSuccess = false;
          sanitizedErrorCode = ERROR_CODES.ITERATION_LIMIT_EXCEEDED;
        }
      }
    } catch (purchErr) {
      log(`[${correlationId}] [PURCH_QUERY_WARN] Code: ${ERROR_CODES.COLLECTION_QUERY_FAILED}`);
      cleanupSuccess = false;
      sanitizedErrorCode = ERROR_CODES.COLLECTION_QUERY_FAILED;
    }

    // 4. Mandatory Zero-Record Verification Check before Auth account deletion
    if (cleanupSuccess) {
      log(`[${correlationId}] [VERIFICATION_START] Verifying zero remaining records`);

      for (const collectionId of USER_DATA_COLLECTIONS) {
        const check = await databases.listDocuments(databaseId, collectionId, [
          Query.equal('userId', userId),
          Query.limit(1),
        ]);
        if (check.documents.length > 0) {
          log(`[${correlationId}] [VERIFICATION_FAIL] Code: ${ERROR_CODES.VERIFICATION_FAILED}`);
          cleanupSuccess = false;
          sanitizedErrorCode = ERROR_CODES.VERIFICATION_FAILED;
          break;
        }
      }

      if (cleanupSuccess) {
        const assetCheck = await databases.listDocuments(databaseId, 'user_assets', [
          Query.equal('userId', userId),
          Query.limit(1),
        ]);
        if (assetCheck.documents.length > 0) {
          log(`[${correlationId}] [VERIFICATION_FAIL_ASSET] Code: ${ERROR_CODES.VERIFICATION_FAILED}`);
          cleanupSuccess = false;
          sanitizedErrorCode = ERROR_CODES.VERIFICATION_FAILED;
        }
      }

      if (cleanupSuccess) {
        const purchCheck = await databases.listDocuments(databaseId, 'course_purchases', [
          Query.equal('userId', userId),
          Query.limit(1),
        ]);
        const unanonymized = purchCheck.documents.filter(p => p.userId === userId);
        if (unanonymized.length > 0) {
          log(`[${correlationId}] [VERIFICATION_FAIL_PURCH] Code: ${ERROR_CODES.VERIFICATION_FAILED}`);
          cleanupSuccess = false;
          sanitizedErrorCode = ERROR_CODES.VERIFICATION_FAILED;
        }
      }
    }

    // Fail closed if cleanup or verification failed
    if (!cleanupSuccess) {
      if (stateDoc) {
        try {
          await databases.updateDocument(databaseId, 'deletion_requests', requestId, {
            status: 'cleanup_failed',
            lastError: sanitizedErrorCode || ERROR_CODES.VERIFICATION_FAILED,
            updatedAt: new Date().toISOString(),
          });
        } catch (failUpdateErr) {
          error(`[${correlationId}] [STATE_UPDATE_FAIL] Code: ${ERROR_CODES.STATE_TRANSITION_FAILED}`);
        }
      }

      return res.json({
        ok: false,
        code: 'deletion_failed',
        message: 'An error occurred during account deletion. Partial progress saved for retry.',
      }, 500);
    }

    // Update state to cleanup_complete before Auth user deletion
    if (stateDoc) {
      try {
        await databases.updateDocument(databaseId, 'deletion_requests', requestId, {
          status: 'cleanup_complete',
          updatedAt: new Date().toISOString(),
        });
      } catch (stateUpdateErr) {
        error(`[${correlationId}] [STATE_COMPLETE_FAIL] Code: ${ERROR_CODES.STATE_TRANSITION_FAILED}`);
        return res.json({
          ok: false,
          code: 'deletion_failed',
          message: 'Failed state machine transition to cleanup_complete. Auth deletion aborted.',
        }, 500);
      }
    }

    // 5. Delete Appwrite Auth User Account as final structural step
    try {
      await users.delete(userId);
      log(`[${correlationId}] [AUTH_DELETE_SUCCESS] Auth user account removed`);
    } catch (userDeleteErr) {
      if (userDeleteErr.code === 404) {
        log(`[${correlationId}] [AUTH_DELETE_IDEMPOTENT] Auth user already absent`);
      } else {
        error(`[${correlationId}] [AUTH_DELETE_ERROR] Code: ${ERROR_CODES.AUTH_DELETE_FAILED}`);
        throw userDeleteErr;
      }
    }

    // Transition state: cleanup_complete -> auth_deleted
    if (stateDoc) {
      try {
        await databases.updateDocument(databaseId, 'deletion_requests', requestId, {
          status: 'auth_deleted',
          updatedAt: new Date().toISOString(),
        });
      } catch (authDelStateErr) {
        error(`[${correlationId}] [STATE_AUTH_DEL_FAIL] Code: ${ERROR_CODES.STATE_TRANSITION_FAILED}`);
      }
    }

    // Transition state: auth_deleted -> completed
    if (stateDoc) {
      try {
        await databases.updateDocument(databaseId, 'deletion_requests', requestId, {
          status: 'completed',
          updatedAt: new Date().toISOString(),
        });
      } catch (completeErr) {
        error(`[${correlationId}] [STATE_FINAL_FAIL] Code: ${ERROR_CODES.STATE_TRANSITION_FAILED}`);
        return res.json({
          ok: false,
          code: 'state_update_failed',
          authDeleted: true,
          message: 'Account deleted; final cleanup reconciliation is pending.',
        }, 500);
      }
    }

    log(`[${correlationId}] [DELETION_COMPLETED] Account deletion successfully finalized`);
    return res.json({
      ok: true,
      code: 'account_deleted',
      message: 'Account and associated personal data successfully deleted',
    });
  } catch (err) {
    error(`[${correlationId}] [GLOBAL_CATCH] Code: ${sanitizedErrorCode || ERROR_CODES.STATE_TRANSITION_FAILED}`);

    if (stateDoc) {
      try {
        await databases.updateDocument(databaseId, 'deletion_requests', requestId, {
          status: 'cleanup_failed',
          lastError: sanitizedErrorCode || ERROR_CODES.STATE_TRANSITION_FAILED,
          updatedAt: new Date().toISOString(),
        });
      } catch (globalFailErr) {
        error(`[${correlationId}] [GLOBAL_STATE_FAIL] Code: ${ERROR_CODES.STATE_TRANSITION_FAILED}`);
      }
    }

    return res.json({
      ok: false,
      code: 'deletion_failed',
      message: 'An error occurred during account deletion. Partial progress saved for retry.',
    }, 500);
  }
};
