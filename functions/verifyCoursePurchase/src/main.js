import { createHmac, createHash } from 'crypto';
import { Client, Databases } from 'node-appwrite';

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

export default async ({ req, res, error }) => {
  if (req.method !== 'POST') {
    return res.json({ ok: false, message: 'Method not allowed' }, 405);
  }

  const userId = req.headers['x-appwrite-user-id'];
  if (!userId) {
    return res.json({ ok: false, message: 'Unauthenticated' }, 401);
  }

  const endpoint = process.env.APPWRITE_FUNCTION_API_ENDPOINT;
  const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID;
  const apiKey = process.env.APPWRITE_FUNCTION_API_KEY || process.env.APPWRITE_API_KEY;

  if (!endpoint || !projectId || !apiKey) {
    error('Missing Appwrite environment variables');
    return res.json({ ok: false, message: 'Server misconfiguration' }, 500);
  }

  const body = parseBody(req);
  const unlockMethod = text(body.unlockMethod, 30);
  const categoryId = text(body.categoryId, 36);

  if (!unlockMethod || !categoryId) {
    return res.json({ ok: false, message: 'Missing unlockMethod or categoryId' }, 400);
  }

  // Reject unverifiable review unlocks from granting financial purchase entitlements
  if (unlockMethod === 'play_store_review') {
    return res.json({
      ok: false,
      message: 'Play Store review cannot issue a verified purchase entitlement. Use official course purchase.'
    }, 400);
  }

  if (unlockMethod !== 'razorpay') {
    return res.json({ ok: false, message: 'Unsupported unlock method' }, 400);
  }

  const client = new Client()
    .setEndpoint(endpoint)
    .setProject(projectId)
    .setKey(apiKey);
  const databases = new Databases(client);
  const databaseId = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
  const purchaseId = stableId(`${userId}:${categoryId}`);
  const now = new Date().toISOString();

  try {
    // 1. Fetch official category from database
    let category;
    try {
      category = await databases.getDocument(databaseId, 'categories', categoryId);
    } catch (err) {
      return res.json({ ok: false, message: 'Category not found' }, 404);
    }

    const unlockMode = category.unlockMode || 'free';
    if (unlockMode === 'free') {
      return res.json({ ok: false, message: 'Category is already free' }, 400);
    }

    const expectedAmount = category.priceInr || 0;

    // 2. Check existing purchase status (idempotency)
    try {
      const existing = await databases.getDocument(databaseId, 'course_purchases', purchaseId);
      if (existing.status === 'verified') {
        return res.json({ ok: true, message: 'Already verified', purchase: existing });
      }
    } catch (_) {
      // Proceed
    }

    // 3. Extract Razorpay payment details from client
    const paymentId = text(body.razorpayPaymentId, 255);
    const orderId = text(body.razorpayOrderId, 255);
    const signature = text(body.razorpaySignature, 512);

    if (!paymentId || !orderId || !signature) {
      return res.json({ ok: false, message: 'Missing Razorpay details' }, 400);
    }

    const razorpaySecret = process.env.RAZORPAY_KEY_SECRET;
    const razorpayKeyId = process.env.RAZORPAY_KEY_ID;

    if (!razorpaySecret) {
      error('RAZORPAY_KEY_SECRET env variable not set');
      return res.json({ ok: false, message: 'Server payment configuration missing' }, 500);
    }

    // 4. Verify Razorpay HMAC signature
    const expectedSignature = createHmac('sha256', razorpaySecret)
      .update(`${orderId}|${paymentId}`)
      .digest('hex');

    if (expectedSignature !== signature) {
      return res.json({ ok: false, message: 'Invalid payment signature' }, 400);
    }

    // 5. Query Razorpay API if credentials available to confirm payment captured & amount match
    let actualPaidAmount = expectedAmount;
    if (razorpayKeyId && razorpaySecret) {
      try {
        const authHeader = 'Basic ' + Buffer.from(`${razorpayKeyId}:${razorpaySecret}`).toString('base64');
        const paymentRes = await fetch(`https://api.razorpay.com/v1/payments/${paymentId}`, {
          headers: { 'Authorization': authHeader }
        });

        if (paymentRes.ok) {
          const paymentData = await paymentRes.json();
          // Razorpay amount is in paise
          const paidInr = Math.floor((paymentData.amount || 0) / 100);
          actualPaidAmount = paidInr;

          if (paymentData.status !== 'captured' && paymentData.status !== 'authorized') {
            return res.json({ ok: false, message: `Payment not captured: ${paymentData.status}` }, 400);
          }

          if (paidInr < expectedAmount) {
            return res.json({
              ok: false,
              message: `Paid amount (₹${paidInr}) is less than required category price (₹${expectedAmount})`
            }, 400);
          }
        }
      } catch (e) {
        error(`Failed to verify payment details with Razorpay API: ${e.message}`);
      }
    }

    const adminTeamId = process.env.ADMIN_TEAM_ID || 'admins';
    const documentPermissions = [
      `read("user:${userId}")`,
      `read("team:${adminTeamId}")`,
      `update("team:${adminTeamId}")`,
      `delete("team:${adminTeamId}")`
    ];

    // 6. Record verified purchase ledger document
    const verifiedLedger = {
      userId,
      categoryId,
      provider: 'razorpay',
      providerOrderId: orderId,
      providerPaymentId: paymentId,
      expectedAmount: expectedAmount,
      paidAmount: actualPaidAmount,
      currency: 'INR',
      status: 'verified',
      purchasedAt: now,
      paidAt: now,
      verifiedAt: now,
      failureReason: ''
    };

    let purchase;
    try {
      purchase = await databases.updateDocument(
        databaseId,
        'course_purchases',
        purchaseId,
        verifiedLedger,
        documentPermissions
      );
    } catch (_) {
      purchase = await databases.createDocument(
        databaseId,
        'course_purchases',
        purchaseId,
        verifiedLedger,
        documentPermissions
      );
    }

    return res.json({ ok: true, message: 'Purchase verified successfully', purchase });

  } catch (err) {
    error(`verifyCoursePurchase failed: ${err.message}`);
    return res.json({ ok: false, message: err.message }, 500);
  }
};
