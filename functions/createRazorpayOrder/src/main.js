import { createHash, createHmac } from 'crypto';
import { Client, Databases } from 'node-appwrite';
import { publishPendingPurchase, isPayablePurchase } from './purchase_ledger.js';
import { enforceWindowRateLimit, WINDOW_HOUR_MS } from './shared/rate_limiter.js';

function stableId(value) {
  return createHash('sha256').update(value).digest('hex').slice(0, 32);
}

function paymentRateLimitIdentifier(userId) {
  const salt = process.env.RATE_LIMIT_SALT || 'olitun-dev-salt-do-not-use-in-production';
  const hash = createHmac('sha256', salt)
    .update(`payments-rate-limit:v1:${userId}`)
    .digest('hex')
    .slice(0, 32);
  return `pay_${hash}`;
}

function parseBody(req) {
  try {
    return JSON.parse(req.body || '{}');
  } catch (_) {
    return {};
  }
}

function text(value, max = 255) {
  return String(value || '').trim().slice(0, max);
}

export function createOrderHandler({ databases: customDb, fetchImpl = fetch } = {}) {
  return async ({ req, res, error, log = () => {} }) => {
    if (req.method !== 'POST') {
      return res.json({ ok: false, message: 'Method not allowed' }, 405);
    }

    const userId = req.headers['x-appwrite-user-id'];
    if (!userId) {
      return res.json({ ok: false, message: 'Unauthenticated' }, 401);
    }

    const endpoint = process.env.APPWRITE_FUNCTION_API_ENDPOINT || process.env.APPWRITE_ENDPOINT;
    const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID || process.env.APPWRITE_PROJECT_ID;
    const apiKey = process.env.APPWRITE_FUNCTION_API_KEY || process.env.APPWRITE_API_KEY;
    const razorpayKeyId = process.env.RAZORPAY_KEY_ID;
    const razorpayKeySecret = process.env.RAZORPAY_KEY_SECRET;

    if (!endpoint || !projectId || !apiKey) {
      error('Missing Appwrite environment variables');
      return res.json({ ok: false, message: 'Server misconfiguration' }, 500);
    }

    if (!razorpayKeyId || !razorpayKeySecret) {
      error('Missing Razorpay Key environment variables');
      return res.json({ ok: false, message: 'Payment gateway misconfiguration' }, 500);
    }

    const body = parseBody(req);
    const categoryId = text(body.categoryId, 36);
    let idempotencyKey = text(body.idempotencyKey, 128);

    if (!categoryId) {
      return res.json({ ok: false, message: 'Missing categoryId' }, 400);
    }

    if (!idempotencyKey) {
      idempotencyKey = stableId(`${userId}:${categoryId}:checkout_default`);
    } else if (idempotencyKey.length < 8) {
      return res.json({ ok: false, message: 'Invalid idempotencyKey length' }, 400);
    }

    let databases = customDb;
    if (!databases) {
      const client = new Client()
        .setEndpoint(endpoint)
        .setProject(projectId)
        .setKey(apiKey);
      databases = new Databases(client);
    }

    const databaseId = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
    const purchaseId = stableId(`${userId}:${categoryId}`);
    const attemptDocId = `att_${stableId(`${userId}:${categoryId}:${idempotencyKey}`)}`;
    const now = new Date().toISOString();

    try {
      // 1. Check if a verified purchase already exists
      try {
        const existing = await databases.getDocument(databaseId, 'course_purchases', purchaseId);
        if (existing.status === 'verified') {
          return res.json({ ok: false, message: 'Category already unlocked', purchase: existing });
        }
      } catch (err) {
        if (err.code !== 404) {
          throw err;
        }
      }

      // 2. Fetch category from database to read official server price
      let category;
      try {
        category = await databases.getDocument(databaseId, 'categories', categoryId);
      } catch (err) {
        if (err.code === 404) {
          return res.json({ ok: false, message: 'Category not found' }, 404);
        }
        throw err;
      }

      const unlockMode = category.unlockMode || 'free';
      if (unlockMode === 'free') {
        return res.json({ ok: false, message: 'Category is already free' }, 400);
      }

      const expectedAmount = category.priceInr || 0;
      if (!Number.isSafeInteger(expectedAmount) || expectedAmount <= 0 ||
          !Number.isSafeInteger(expectedAmount * 100)) {
        return res.json({ ok: false, message: 'Invalid category price' }, 400);
      }

      // Publish/repair the canonical ledger before returning ANY gateway order,
      // including idempotent retries after a partial database failure.
      const finishCheckout = async (attempt, duplicateRetry) => {
        const adminTeamId = process.env.ADMIN_TEAM_ID || 'admins';
        const permissions = [
          `read("user:${userId}")`, `read("team:${adminTeamId}")`,
          `update("team:${adminTeamId}")`, `delete("team:${adminTeamId}")`,
        ];
        const data = {
          userId, categoryId, provider: 'razorpay',
          providerOrderId: attempt.providerOrderId, providerPaymentId: '',
          expectedAmount: attempt.expectedAmount, paidAmount: 0,
          currency: attempt.currency, status: 'created',
          createdAt: attempt.createdAt || now,
          paidAt: null, verifiedAt: null, failureReason: '',
        };
        if (!isPayablePurchase(data)) throw new Error('Invalid stored order');
        let purchase;
        try {
          purchase = await publishPendingPurchase({
            databases, databaseId, purchaseId, data, permissions,
          });
        } catch (publishError) {
          const conflict = publishError.code === 409;
          await databases.updateDocument(databaseId, 'payment_attempts', attemptDocId, {
            status: conflict ? 'blocked' : 'reconciliation_required',
            reconciliationStatus: conflict ? 'purchase_state_conflict' : 'pending',
            updatedAt: new Date().toISOString(),
          });
          return res.json({
            ok: false, code: conflict ? 'purchase_state_conflict' : 'reconciliation_required',
            message: conflict
              ? 'Purchase state changed. Please refresh before starting a new checkout.'
              : 'Checkout could not be confirmed. Please retry after reconciliation.',
          }, conflict ? 409 : 503);
        }
        const canonical = purchase.providerOrderId === attempt.providerOrderId;
        try {
          await databases.updateDocument(databaseId, 'payment_attempts', attemptDocId, {
            status: canonical ? 'created' : 'superseded',
            reconciliationStatus: canonical ? 'none' : 'canonical_order_reused',
            updatedAt: new Date().toISOString(),
          });
        } catch {
          error('Checkout ledger committed; attempt finalization needs reconciliation');
        }
        if (purchase.status === 'verified') {
          return res.json({ ok: false, message: 'Category already unlocked', purchase });
        }
        if (!isPayablePurchase(purchase)) throw new Error('Invalid canonical purchase');
        return res.json({
          ok: true, message: 'Razorpay checkout ready',
          orderId: purchase.providerOrderId,
          amount: purchase.expectedAmount * 100, currency: purchase.currency,
          keyId: razorpayKeyId, categoryId,
          categoryTitle: category.name || category.title || '',
          isDuplicateRetry: duplicateRetry || !canonical,
        });
      };

      // 3. Concurrency & Idempotency Reservation via payment_attempts
      let attemptRecord = null;
      try {
        const leaseExpiresAt = new Date(Date.now() + 30000).toISOString();
        attemptRecord = await databases.createDocument(
          databaseId,
          'payment_attempts',
          attemptDocId,
          {
            userId,
            categoryId,
            idempotencyKey,
            attemptId: attemptDocId,
            expectedAmount,
            currency: 'INR',
            status: 'in_progress',
            provider: 'razorpay',
            providerOrderId: null,
            providerReceipt: purchaseId,
            leaseOwner: process.env.APPWRITE_FUNCTION_ID || 'createRazorpayOrder',
            leaseExpiresAt,
            reconciliationStatus: 'none',
            createdAt: now,
            updatedAt: now,
          },
          [`read("user:${userId}")`]
        );
      } catch (createErr) {
        if (createErr.code === 409 || createErr.message?.includes('already exists') || createErr.message?.includes('conflict')) {
          try {
            attemptRecord = await databases.getDocument(databaseId, 'payment_attempts', attemptDocId);
          } catch (getErr) {
            throw getErr;
          }

          if (attemptRecord.providerOrderId) {
            log(`Returning existing idempotency attempt for order ${attemptRecord.providerOrderId}`);
            return await finishCheckout(attemptRecord, true);
          }

          if (attemptRecord.reconciliationStatus === 'pending' || attemptRecord.status === 'reconciliation_required') {
            return res.json({
              ok: false,
              code: 'reconciliation_required',
              message: 'Order creation status is ambiguous due to gateway timeout. Reconciliation required.',
            }, 504);
          }

          const leaseExpires = new Date(attemptRecord.leaseExpiresAt || 0).getTime();
          if (attemptRecord.status === 'in_progress' && leaseExpires > Date.now()) {
            return res.json({
              ok: false,
              code: 'in_progress',
              message: 'Order creation is in progress by another request. Please retry shortly.',
            }, 409);
          }

          return res.json({
            ok: false,
            code: 'reservation_conflict',
            message: 'Order creation attempt reservation conflict. Please retry.',
          }, 409);
        } else {
          throw createErr;
        }
      }

      // 4. Create Razorpay order via Razorpay REST API

      // Per-user hourly ceiling on real Razorpay order creation. Identity
      // comes from the runtime-injected header, so this bucket cannot be
      // rotated; placed after the idempotency lease so concurrent deduped
      // requests do not consume quota.
      {
        const limitResult = await enforceWindowRateLimit({
          databases,
          dbId: databaseId,
          collectionId: 'rate_limits',
          identifier: paymentRateLimitIdentifier(userId),
          windowType: 'h',
          windowMs: WINDOW_HOUR_MS,
          limit: parseInt(process.env.PAYMENT_ORDERS_PER_HOUR || '10', 10),
        });
        if (!limitResult.allowed) {
          return res.json(
            { ok: false, message: 'Too many checkout attempts. Please try again later.' },
            429,
          );
        }
      }

      const authHeader = 'Basic ' + Buffer.from(`${razorpayKeyId}:${razorpayKeySecret}`).toString('base64');
      const orderPayload = {
        amount: expectedAmount * 100,
        currency: 'INR',
        receipt: purchaseId,
        notes: {
          userId,
          categoryId,
          idempotencyKey,
          categoryTitle: category.name || category.title || ''
        }
      };

      let razorpayRes;
      try {
        razorpayRes = await fetchImpl('https://api.razorpay.com/v1/orders', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authHeader
          },
          body: JSON.stringify(orderPayload),
          signal: AbortSignal.timeout(12000),
        });
      } catch (netErr) {
        error(`[${attemptDocId}] Gateway network timeout or connection error`);
        try {
          await databases.updateDocument(databaseId, 'payment_attempts', attemptDocId, {
            status: 'reconciliation_required',
            reconciliationStatus: 'pending',
            updatedAt: new Date().toISOString(),
          });
        } catch (flagErr) {
          error(`[${attemptDocId}] Failed to flag attempt for reconciliation: ${flagErr?.message}`);
        }

        return res.json({
          ok: false,
          code: 'reconciliation_required',
          message: 'Payment gateway connection timed out. Reconciliation required.',
        }, 504);
      }

      if (!razorpayRes.ok) {
        error(`[${attemptDocId}] Razorpay order creation request returned error status ${razorpayRes.status}`);
        try {
          await databases.updateDocument(databaseId, 'payment_attempts', attemptDocId, {
            status: 'failed',
            updatedAt: new Date().toISOString(),
          });
        } catch (markErr) {
          error(`[${attemptDocId}] Failed to mark attempt failed: ${markErr?.message}`);
        }

        return res.json({ ok: false, message: 'Failed to create order with payment gateway' }, 502);
      }

      const razorpayOrder = await razorpayRes.json();
      if (typeof razorpayOrder.id !== 'string' || !razorpayOrder.id ||
          razorpayOrder.amount !== expectedAmount * 100 || razorpayOrder.currency !== 'INR') {
        await databases.updateDocument(databaseId, 'payment_attempts', attemptDocId, {
          status: 'reconciliation_required', reconciliationStatus: 'pending',
          providerOrderId: typeof razorpayOrder.id === 'string' ? razorpayOrder.id : null,
          updatedAt: new Date().toISOString(),
        });
        return res.json({ ok: false, message: 'Invalid payment gateway response' }, 502);
      }

      // Persist the gateway ID as unresolved until the canonical ledger is safe.
      try {
        await databases.updateDocument(databaseId, 'payment_attempts', attemptDocId, {
          status: 'reconciliation_required',
          providerOrderId: razorpayOrder.id,
          reconciliationStatus: 'pending',
          updatedAt: new Date().toISOString(),
        });
      } catch (updateErr) {
        error(`[${attemptDocId}] Failed to record providerOrderId in payment_attempts doc`);
        // Flag for reconciliation rather than ignoring
        try {
          await databases.updateDocument(databaseId, 'payment_attempts', attemptDocId, {
            status: 'reconciliation_required',
            reconciliationStatus: 'pending',
            providerOrderId: razorpayOrder.id,
            updatedAt: new Date().toISOString(),
          });
        } catch (flagErr) {
          error(`[${attemptDocId}] Failed flagging attempt for reconciliation`);
        }
      }

      return await finishCheckout({ ...attemptRecord, providerOrderId: razorpayOrder.id }, false);

    } catch (err) {
      error('[createRazorpayOrder] Internal server error occurred');
      return res.json({ ok: false, message: 'An internal server error occurred' }, 500);
    }
  };
}

export default async (context) => createOrderHandler()(context);
