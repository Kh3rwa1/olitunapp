import { createHash } from 'crypto';
import { Client, Databases, Query } from 'node-appwrite';

function stableId(value) {
  return createHash('sha256').update(value).digest('hex').slice(0, 32);
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
      if (expectedAmount <= 0) {
        return res.json({ ok: false, message: 'Invalid category price' }, 400);
      }

      // 3. Concurrency & Idempotency Reservation via payment_attempts
      let attemptRecord = null;
      try {
        attemptRecord = await databases.getDocument(databaseId, 'payment_attempts', attemptDocId);
        
        if (attemptRecord.providerOrderId) {
          log(`Returning existing idempotency attempt for order ${attemptRecord.providerOrderId}`);
          return res.json({
            ok: true,
            message: 'Razorpay order retrieved from existing attempt',
            orderId: attemptRecord.providerOrderId,
            amount: expectedAmount * 100,
            currency: 'INR',
            keyId: razorpayKeyId,
            categoryId: categoryId,
            categoryTitle: category.name || category.title || '',
            isDuplicateRetry: true,
          });
        }

        if (attemptRecord.reconciliationStatus === 'pending') {
          return res.json({
            ok: false,
            code: 'reconciliation_required',
            message: 'Order creation status is ambiguous due to gateway timeout. Reconciliation required.',
          }, 504);
        }
      } catch (attErr) {
        if (attErr.code === 404) {
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
              [] // Function-only permissions
            );
          } catch (createErr) {
            log(`Note: Concurrency reservation attempt document conflict: ${createErr.message}`);
          }
        }
      }

      // 4. Create Razorpay order via Razorpay REST API
      const authHeader = 'Basic ' + Buffer.from(`${razorpayKeyId}:${razorpayKeySecret}`).toString('base64');
      const orderPayload = {
        amount: expectedAmount * 100, // Razorpay amount in paise
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
          body: JSON.stringify(orderPayload)
        });
      } catch (netErr) {
        error(`Gateway network error / timeout: ${netErr.message}`);
        try {
          await databases.updateDocument(databaseId, 'payment_attempts', attemptDocId, {
            status: 'reconciliation_required',
            reconciliationStatus: 'pending',
            updatedAt: new Date().toISOString(),
          });
        } catch (_) {}

        return res.json({
          ok: false,
          code: 'reconciliation_required',
          message: 'Payment gateway connection timed out. Reconciliation required.',
        }, 504);
      }

      if (!razorpayRes.ok) {
        const errText = await razorpayRes.text();
        error(`Razorpay order creation failed: ${errText}`);
        try {
          await databases.updateDocument(databaseId, 'payment_attempts', attemptDocId, {
            status: 'failed',
            updatedAt: new Date().toISOString(),
          });
        } catch (_) {}

        return res.json({ ok: false, message: 'Failed to create order with payment gateway' }, 502);
      }

      const razorpayOrder = await razorpayRes.json();

      // Update payment_attempts record with verified provider order ID
      try {
        await databases.updateDocument(databaseId, 'payment_attempts', attemptDocId, {
          status: 'created',
          providerOrderId: razorpayOrder.id,
          reconciliationStatus: 'none',
          updatedAt: new Date().toISOString(),
        });
      } catch (_) {}

      const adminTeamId = process.env.ADMIN_TEAM_ID || 'admins';
      const documentPermissions = [
        `read("user:${userId}")`,
        `read("team:${adminTeamId}")`,
        `update("team:${adminTeamId}")`,
        `delete("team:${adminTeamId}")`
      ];

      // 5. Create or update pending purchase ledger entry
      const ledgerData = {
        userId,
        categoryId,
        provider: 'razorpay',
        providerOrderId: razorpayOrder.id,
        providerPaymentId: '',
        expectedAmount: expectedAmount,
        paidAmount: 0,
        currency: 'INR',
        status: 'created',
        createdAt: now,
        paidAt: null,
        verifiedAt: null,
        failureReason: ''
      };

      try {
        await databases.updateDocument(
          databaseId,
          'course_purchases',
          purchaseId,
          ledgerData,
          documentPermissions
        );
      } catch (err) {
        if (err.code === 404) {
          await databases.createDocument(
            databaseId,
            'course_purchases',
            purchaseId,
            ledgerData,
            documentPermissions
          );
        } else {
          throw err;
        }
      }

      return res.json({
        ok: true,
        message: 'Razorpay order created successfully',
        orderId: razorpayOrder.id,
        amount: razorpayOrder.amount,
        currency: razorpayOrder.currency,
        keyId: razorpayKeyId,
        categoryId: categoryId,
        categoryTitle: category.name || category.title || ''
      });

    } catch (err) {
      error(`createRazorpayOrder failed: ${err.message}`);
      return res.json({ ok: false, message: err.message }, 500);
    }
  };
}

export default async (context) => createOrderHandler()(context);
