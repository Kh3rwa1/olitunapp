import { createHmac, createHash } from 'crypto';
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
  const unlockMethod = text(body.unlockMethod, 30); // 'razorpay' or 'play_store_review'
  const categoryId = text(body.categoryId, 36);

  if (!unlockMethod || !categoryId) {
    return res.json({ ok: false, message: 'Missing unlockMethod or categoryId' }, 400);
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
    // 1. Fetch category to verify exists and check unlock rules
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

    // 2. Check if a verified purchase already exists for this specific category
    try {
      const existing = await databases.getDocument(databaseId, 'course_purchases', purchaseId);
      if (existing.status === 'verified') {
        return res.json({ ok: true, message: 'Already purchased', purchase: existing });
      }
    } catch (_) {
      // Document does not exist, proceed
    }

    const documentPermissions = [
      `read("user:${userId}")`,
      `read("team:admins")`,
      `update("team:admins")`,
      `delete("team:admins")`
    ];

    if (unlockMethod === 'razorpay') {
      // --- Razorpay payment path ---
      const paymentId = text(body.razorpayPaymentId, 255);
      const orderId = text(body.razorpayOrderId, 255);
      const signature = text(body.razorpaySignature, 512);

      if (!paymentId || !orderId || !signature) {
        return res.json({ ok: false, message: 'Missing Razorpay details' }, 400);
      }

      if (unlockMode !== 'paid_only' && unlockMode !== 'review_or_paid') {
        return res.json({ ok: false, message: 'Paid unlock not allowed for this category' }, 400);
      }

      const razorpaySecret = process.env.RAZORPAY_KEY_SECRET;
      if (!razorpaySecret) {
        error('RAZORPAY_KEY_SECRET env variable not set');
        return res.json({ ok: false, message: 'Server payment configuration missing' }, 500);
      }

      // Verify Razorpay signature
      const expectedSignature = createHmac('sha256', razorpaySecret)
        .update(`${orderId}|${paymentId}`)
        .digest('hex');

      if (expectedSignature !== signature) {
        return res.json({ ok: false, message: 'Invalid payment signature' }, 400);
      }

      // Create verified purchase record
      const purchase = await databases.createDocument(
        databaseId,
        'course_purchases',
        purchaseId,
        {
          userId,
          categoryId,
          unlockMethod: 'razorpay',
          amountPaidInr: category.priceInr || 0,
          razorpayPaymentId: paymentId,
          razorpayOrderId: orderId,
          razorpaySignature: signature,
          status: 'verified',
          purchasedAt: now,
          verifiedAt: now
        },
        documentPermissions
      );

      return res.json({ ok: true, message: 'Purchase verified successfully', purchase });

    } else if (unlockMethod === 'play_store_review') {
      // --- Play Store Review path ---
      if (unlockMode !== 'review_only' && unlockMode !== 'review_or_paid') {
        return res.json({ ok: false, message: 'Review unlock not allowed for this category' }, 400);
      }

      // Check global review unlock toggle
      let globalReviewEnabled = true;
      try {
        const settings = await databases.listDocuments(databaseId, 'app_settings', [
          Query.equal('settingKey', 'global_review_unlock_enabled')
        ]);
        if (settings.documents.length > 0) {
          globalReviewEnabled = settings.documents[0].settingValue === 'true';
        }
      } catch (_) {
        // Fallback to enabled
      }

      if (!globalReviewEnabled) {
        return res.json({ ok: false, message: 'Review unlock is currently disabled by administrator' }, 403);
      }

      // Enforcement: Check if user has already unlocked *any* course via review (limit: 1 review unlock per user ever)
      const priorReviewUnlocks = await databases.listDocuments(databaseId, 'course_purchases', [
        Query.equal('userId', userId),
        Query.equal('unlockMethod', 'play_store_review'),
        Query.equal('status', 'verified'),
        Query.limit(1)
      ]);

      if (priorReviewUnlocks.total > 0) {
        return res.json({
          ok: false,
          message: 'Only one course can be unlocked via Play Store review. Please purchase other courses.'
        }, 403);
      }

      // Create verified review purchase record (price = 0)
      const purchase = await databases.createDocument(
        databaseId,
        'course_purchases',
        purchaseId,
        {
          userId,
          categoryId,
          unlockMethod: 'play_store_review',
          amountPaidInr: 0,
          reviewCompletedAt: now,
          reviewPlatform: 'play_store',
          status: 'verified',
          purchasedAt: now,
          verifiedAt: now
        },
        documentPermissions
      );

      return res.json({ ok: true, message: 'Review unlock verified successfully', purchase });

    } else {
      return res.json({ ok: false, message: 'Unsupported unlock method' }, 400);
    }

  } catch (err) {
    error(`verifyCoursePurchase failed: ${err.message}`);
    return res.json({ ok: false, message: err.message }, 500);
  }
};
