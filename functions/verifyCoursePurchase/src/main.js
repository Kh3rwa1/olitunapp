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
    // 1. Fetch pending purchase ledger entry by purchaseId (exact userId:categoryId)
    let pendingPurchase;
    try {
      pendingPurchase = await databases.getDocument(databaseId, 'course_purchases', purchaseId);
    } catch (err) {
      if (err.code === 404) {
        return res.json({ ok: false, message: 'No pending purchase order found for this category. Please initiate order first.' }, 404);
      }
      throw err;
    }

    // Idempotency: if already verified for this exact purchase, return existing purchase
    if (pendingPurchase.status === 'verified') {
      return res.json({ ok: true, message: 'Purchase already verified', purchase: pendingPurchase });
    }

    // 2. Extract submitted Razorpay payment details
    const paymentId = text(body.razorpayPaymentId, 255);
    const orderId = text(body.razorpayOrderId, 255);
    const signature = text(body.razorpaySignature, 512);

    if (!paymentId || !orderId || !signature) {
      return res.json({ ok: false, message: 'Missing Razorpay details' }, 400);
    }

    // 3. Order binding check between client submitted order ID & stored order ID
    if (pendingPurchase.providerOrderId !== orderId) {
      return res.json({ ok: false, message: 'Submitted order ID does not match the pending order stored for this course' }, 400);
    }

    const razorpaySecret = process.env.RAZORPAY_KEY_SECRET;
    const razorpayKeyId = process.env.RAZORPAY_KEY_ID;

    if (!razorpaySecret || !razorpayKeyId) {
      error('RAZORPAY_KEY_SECRET or RAZORPAY_KEY_ID env variable missing');
      return res.json({ ok: false, message: 'Server payment configuration missing' }, 500);
    }

    // 4. Verify Razorpay HMAC signature
    const expectedSignature = createHmac('sha256', razorpaySecret)
      .update(`${orderId}|${paymentId}`)
      .digest('hex');

    if (expectedSignature !== signature) {
      return res.json({ ok: false, message: 'Invalid payment signature' }, 400);
    }

    // 5. Mandatory Razorpay API verification (FAIL CLOSED if API call fails or status != 200)
    let paymentData;
    try {
      const authHeader = 'Basic ' + Buffer.from(`${razorpayKeyId}:${razorpaySecret}`).toString('base64');
      const paymentRes = await fetch(`https://api.razorpay.com/v1/payments/${paymentId}`, {
        headers: { 'Authorization': authHeader }
      });

      if (!paymentRes.ok) {
        const errBody = await paymentRes.text();
        error(`Razorpay API payment fetch failed (HTTP ${paymentRes.status}): ${errBody}`);
        return res.json({ ok: false, message: `Payment verification failed with payment gateway (HTTP ${paymentRes.status})` }, 400);
      }

      paymentData = await paymentRes.json();
    } catch (e) {
      error(`Network exception calling Razorpay API: ${e.message}`);
      // FAIL CLOSED: Never grant entitlement on API error/timeout
      return res.json({ ok: false, message: `Payment gateway verification failed due to network error: ${e.message}` }, 502);
    }

    // 6. Strict Field Validation against Razorpay Payment Object:
    // Only accept 'captured' status (reject 'authorized' unless settled)
    if (paymentData.status !== 'captured') {
      return res.json({ ok: false, message: `Payment status is '${paymentData.status}', not 'captured'. Access denied.` }, 400);
    }

    // Verify order_id on payment object matches stored order_id
    if (paymentData.order_id !== pendingPurchase.providerOrderId) {
      return res.json({ ok: false, message: 'Payment gateway order ID does not match stored order ID' }, 400);
    }

    // Verify exact amount in paise (integer comparison)
    const expectedAmountPaise = Math.round((pendingPurchase.expectedAmount || 0) * 100);
    const actualAmountPaise = Number(paymentData.amount || 0);

    if (actualAmountPaise !== expectedAmountPaise) {
      return res.json({
        ok: false,
        message: `Paid amount (${actualAmountPaise} paise) does not match required category price (${expectedAmountPaise} paise)`
      }, 400);
    }

    // Verify currency is INR
    if (paymentData.currency !== 'INR' || pendingPurchase.currency !== 'INR') {
      return res.json({ ok: false, message: 'Currency mismatch; INR required' }, 400);
    }

    // 7. Atomic Payment ID Replay Protection & Safe Recovery
    const claimId = stableId(`claim:${paymentId}`);
    let isRetry = false;
    try {
      await databases.createDocument(databaseId, 'payment_claims', claimId, {
        paymentId,
        purchaseId,
        providerOrderId: orderId,
        userId,
        categoryId,
        status: 'claimed',
        claimedAt: now,
        committedAt: null
      });
    } catch (claimErr) {
      if (claimErr.code === 409) {
        // Safe Recovery Check: Fetch existing claim to verify ownership
        try {
          const existingClaim = await databases.getDocument(databaseId, 'payment_claims', claimId);
          if (existingClaim.paymentId === paymentId &&
              existingClaim.userId === userId &&
              existingClaim.categoryId === categoryId &&
              existingClaim.providerOrderId === orderId) {
            // Same user & transaction retrying safely after partial failure
            isRetry = true;
          } else {
            error(`REPLAY ATTACK: Payment ID ${paymentId} claimed by user ${existingClaim.userId}`);
            return res.json({ ok: false, message: 'This payment ID has already been claimed by another purchase' }, 409);
          }
        } catch (fetchClaimErr) {
          error(`Failed to fetch existing claim: ${fetchClaimErr.message}`);
          return res.json({ ok: false, message: 'Payment claim verification failed. Verification aborted.' }, 503);
        }
      } else {
        // FAIL CLOSED on database/schema/network errors (NO silent fallback)
        error(`FAIL CLOSED: Claim creation failed with non-409 code ${claimErr.code}: ${claimErr.message}`);
        return res.json({ ok: false, message: 'Payment claim service unavailable. Verification aborted.' }, 503);
      }
    }

    // 8. Update purchase ledger to verified
    const adminTeamId = process.env.ADMIN_TEAM_ID || 'admins';
    const documentPermissions = [
      `read("user:${userId}")`,
      `read("team:${adminTeamId}")`,
      `update("team:${adminTeamId}")`,
      `delete("team:${adminTeamId}")`
    ];

    const verifiedLedger = {
      userId,
      categoryId,
      provider: 'razorpay',
      providerOrderId: orderId,
      providerPaymentId: paymentId,
      expectedAmount: pendingPurchase.expectedAmount,
      paidAmount: Math.round(actualAmountPaise / 100),
      currency: 'INR',
      status: 'verified',
      paidAt: now,
      verifiedAt: now,
      failureReason: ''
    };

    const purchase = await databases.updateDocument(
      databaseId,
      'course_purchases',
      purchaseId,
      verifiedLedger,
      documentPermissions
    );

    // 9. Update claim status to committed
    try {
      await databases.updateDocument(databaseId, 'payment_claims', claimId, {
        status: 'committed',
        committedAt: now
      });
    } catch (_) {
      // Non-fatal if claim update timestamp fails after purchase is already verified
    }

    return res.json({
      ok: true,
      message: isRetry ? 'Purchase verification completed (retry)' : 'Purchase verified successfully',
      purchase
    });

  } catch (err) {
    error(`verifyCoursePurchase failed: ${err.message}`);
    return res.json({ ok: false, message: err.message }, 500);
  }
};
