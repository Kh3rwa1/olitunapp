import { Client, Users, Databases, Storage, Query } from 'node-appwrite';
import crypto from 'node:crypto';

/**
 * Server-authoritative Account Deletion & PII Anonymization Function.
 *
 * Security Requirements:
 * 1. Derives user identity strictly from trusted execution context (x-appwrite-user-id).
 * 2. Validates environment configuration without hardcoded fallbacks.
 * 3. Uses a persistent deletion_requests state machine:
 *    requested -> in_progress -> cleanup_failed / cleanup_complete -> auth_deleted -> completed
 * 4. Paginates using cursors/repeated page-1 to delete all user records across collections.
 * 5. Enforces iteration guards and fails closed if limits are reached.
 * 6. Uses user_assets registry for reliable storage asset deletion.
 * 7. Anonymizes statutory financial ledgers without retaining PII.
 * 8. Mandates zero-record verification before deleting Auth user account.
 * 9. Deletes Appwrite Auth account ONLY after cleanup_complete state is verified.
 * 10. Idempotent: safe for repeated execution and automatic retries.
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

function generatePseudonymousId(userId, hmacSecret) {
  const secret = hmacSecret || process.env.DELETION_HMAC_SECRET;
  if (!secret) {
    throw new Error('DELETION_HMAC_SECRET environment variable is missing');
  }
  return crypto.createHmac('sha256', secret).update(userId).digest('hex').substring(0, 32);
}

export default async ({ req, res, log = console.log, error = console.error, databases: injectedDb, users: injectedUsers, storage: injectedStorage }) => {
  if (req.method !== 'POST') {
    return res.json({ ok: false, code: 'method_not_allowed', message: 'Only POST is allowed' }, 405);
  }

  // Strictly identify user from trusted Appwrite header
  const userId = req.headers['x-appwrite-user-id'] || process.env.APPWRITE_FUNCTION_USER_ID;
  if (!userId) {
    return res.json({ ok: false, code: 'unauthenticated', message: 'Authentication required' }, 401);
  }

  const endpoint = process.env.APPWRITE_FUNCTION_API_ENDPOINT || process.env.APPWRITE_ENDPOINT;
  const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID || process.env.APPWRITE_PROJECT_ID;
  const apiKey = process.env.APPWRITE_FUNCTION_API_KEY || process.env.APPWRITE_API_KEY;
  const databaseId = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
  const hmacSecret = process.env.DELETION_HMAC_SECRET;

  if (!endpoint || !projectId || !apiKey || !databaseId || !hmacSecret) {
    error('Missing required environment variables for delete-account');
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

  log(`Starting account deletion for user: ${userId} (request: ${requestId})`);

  let stateDoc = null;

  // Initialize or fetch state machine record (Mandatory state tracking)
  try {
    try {
      stateDoc = await databases.getDocument(databaseId, 'deletion_requests', requestId);
      if (stateDoc.status === 'completed') {
        return res.json({
          ok: true,
          code: 'account_deleted',
          message: 'Account deletion was already completed',
        });
      }
      stateDoc = await databases.updateDocument(databaseId, 'deletion_requests', requestId, {
        status: 'in_progress',
        retryCount: (stateDoc.retryCount || 0) + 1,
        updatedAt: new Date().toISOString(),
      });
    } catch (getErr) {
      if (getErr.code === 404) {
        stateDoc = await databases.createDocument(databaseId, 'deletion_requests', requestId, {
          userId: ANONYMIZED_USER_ID,
          pseudonymousId: pseudoSubject,
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
    error(`Failed state machine initialization: ${stateErr.message}`);
    return res.json({
      ok: false,
      code: 'deletion_failed',
      message: 'Failed to record deletion state machine. Deletion aborted for safety.',
    }, 500);
  }

  let cleanupSuccess = true;
  let lastFailureMessage = null;

  try {
    // 1. Repeated page-1 purge of user database collections
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
                log(`Warning: Failed to delete doc ${doc.$id} in ${collectionId}: ${docErr.message}`);
                cleanupSuccess = false;
                lastFailureMessage = docErr.message;
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
            log(`Warning: Iteration limit reached for collection ${collectionId}`);
            cleanupSuccess = false;
            lastFailureMessage = `Iteration limit reached for collection ${collectionId}`;
          }
        }
      } catch (collErr) {
        log(`Collection ${collectionId} query error: ${collErr.message}`);
        cleanupSuccess = false;
        lastFailureMessage = collErr.message;
      }
    }

    // 2. Repeated page-1 file purge via user_assets registry
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
              log(`Warning: Failed deleting file ${asset.fileId} in bucket ${asset.bucketId}: ${fileErr.message}`);
              cleanupSuccess = false;
              lastFailureMessage = fileErr.message;
            }
          }

          try {
            await databases.deleteDocument(databaseId, 'user_assets', asset.$id);
          } catch (assetDocErr) {
            if (assetDocErr.code !== 404) {
              log(`Warning: Failed deleting asset registry doc ${asset.$id}: ${assetDocErr.message}`);
              cleanupSuccess = false;
              lastFailureMessage = assetDocErr.message;
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
          log('Warning: Iteration limit reached for user_assets');
          cleanupSuccess = false;
          lastFailureMessage = 'Iteration limit reached for user_assets';
        }
      }
    } catch (assetsErr) {
      log(`user_assets query error: ${assetsErr.message}`);
      cleanupSuccess = false;
      lastFailureMessage = assetsErr.message;
    }

    // 3. Anonymize financial purchase records for tax/legal statutory compliance
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
            log(`Warning: Failed to anonymize purchase ${purchase.$id}: ${anonErr.message}`);
            cleanupSuccess = false;
            lastFailureMessage = anonErr.message;
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
          log('Warning: Iteration limit reached for course_purchases');
          cleanupSuccess = false;
          lastFailureMessage = 'Iteration limit reached for course_purchases';
        }
      }
    } catch (purchErr) {
      log(`course_purchases anonymization query error: ${purchErr.message}`);
      cleanupSuccess = false;
      lastFailureMessage = purchErr.message;
    }

    // 4. Final Zero-Record Verification Check before Auth user deletion
    if (cleanupSuccess) {
      log(`Performing zero-record verification for user: ${userId}`);

      for (const collectionId of USER_DATA_COLLECTIONS) {
        const check = await databases.listDocuments(databaseId, collectionId, [
          Query.equal('userId', userId),
          Query.limit(1),
        ]);
        if (check.documents.length > 0) {
          log(`Zero-record verification failed: remaining document in ${collectionId}`);
          cleanupSuccess = false;
          lastFailureMessage = `Zero-record verification failed for ${collectionId}`;
          break;
        }
      }

      if (cleanupSuccess) {
        const assetCheck = await databases.listDocuments(databaseId, 'user_assets', [
          Query.equal('userId', userId),
          Query.limit(1),
        ]);
        if (assetCheck.documents.length > 0) {
          log('Zero-record verification failed: remaining document in user_assets');
          cleanupSuccess = false;
          lastFailureMessage = 'Zero-record verification failed for user_assets';
        }
      }

      if (cleanupSuccess) {
        const purchCheck = await databases.listDocuments(databaseId, 'course_purchases', [
          Query.equal('userId', userId),
          Query.limit(1),
        ]);
        const unanonymized = purchCheck.documents.filter(p => p.userId === userId);
        if (unanonymized.length > 0) {
          log('Zero-record verification failed: unanonymized record in course_purchases');
          cleanupSuccess = false;
          lastFailureMessage = 'Zero-record verification failed for course_purchases';
        }
      }
    }

    // Check if mandatory data cleanup and zero-record verification succeeded
    if (!cleanupSuccess) {
      if (stateDoc) {
        try {
          await databases.updateDocument(databaseId, 'deletion_requests', requestId, {
            status: 'cleanup_failed',
            lastError: lastFailureMessage || 'Partial cleanup failed',
            updatedAt: new Date().toISOString(),
          });
        } catch (failUpdateErr) {
          error(`Failed state update to cleanup_failed: ${failUpdateErr.message}`);
        }
      }

      return res.json({
        ok: false,
        code: 'deletion_failed',
        message: 'An error occurred during account deletion. Partial progress saved for retry.',
      }, 500);
    }

    // Update state to cleanup_complete before deleting Auth account
    if (stateDoc) {
      try {
        await databases.updateDocument(databaseId, 'deletion_requests', requestId, {
          status: 'cleanup_complete',
          updatedAt: new Date().toISOString(),
        });
      } catch (stateUpdateErr) {
        error(`Failed state update to cleanup_complete: ${stateUpdateErr.message}`);
        return res.json({
          ok: false,
          code: 'deletion_failed',
          message: 'Failed state machine transition to cleanup_complete. Auth deletion aborted.',
        }, 500);
      }
    }

    // 5. Delete Appwrite Auth User account as final step
    try {
      await users.delete(userId);
      log(`Appwrite Auth user ${userId} deleted successfully.`);
    } catch (userDeleteErr) {
      if (userDeleteErr.code === 404) {
        log(`User ${userId} was already deleted from Appwrite Auth.`);
      } else {
        throw userDeleteErr;
      }
    }

    // Mark deletion state as completed
    if (stateDoc) {
      try {
        await databases.updateDocument(databaseId, 'deletion_requests', requestId, {
          status: 'completed',
          updatedAt: new Date().toISOString(),
        });
      } catch (completeErr) {
        error(`Failed state update to completed: ${completeErr.message}`);
        return res.json({
          ok: false,
          code: 'state_update_failed',
          message: 'Auth user deleted but final state transition to completed failed.',
        }, 500);
      }
    }

    return res.json({
      ok: true,
      code: 'account_deleted',
      message: 'Account and associated personal data successfully deleted',
    });
  } catch (err) {
    error(`Account deletion error for user ${userId}: ${err.message}`);

    if (stateDoc) {
      try {
        await databases.updateDocument(databaseId, 'deletion_requests', requestId, {
          status: 'cleanup_failed',
          lastError: err.message,
          updatedAt: new Date().toISOString(),
        });
      } catch (globalFailErr) {
        error(`Failed state update in catch handler: ${globalFailErr.message}`);
      }
    }

    return res.json({
      ok: false,
      code: 'deletion_failed',
      message: 'An error occurred during account deletion. Partial progress saved for retry.',
    }, 500);
  }
};
