import { timingSafeEqualStr } from '../auth';
import { getRequestUserId, stableId, type App, type Bindings } from '../env';
import { reconcilePaymentOrders } from '../lib/maintenance';

// Razorpay checkout runs entirely on the Worker with D1 as the purchase
// ledger. Prices come from D1, never the client; access is granted only after
// the Razorpay signature and the captured payment are verified server-side.

const ORDER_REUSE_WINDOW_MS = 60 * 60 * 1000;

function razorpayApi(env: Bindings, path: string): string {
  return `${env.RAZORPAY_API_BASE || 'https://api.razorpay.com'}${path}`;
}

function razorpayAuth(env: Bindings): string | null {
  if (!env.RAZORPAY_KEY_ID || !env.RAZORPAY_KEY_SECRET) return null;
  return 'Basic ' + btoa(`${env.RAZORPAY_KEY_ID}:${env.RAZORPAY_KEY_SECRET}`);
}

async function userOwnsCategory(db: D1Database, userId: string, categoryId: string): Promise<boolean> {
  const row = await db.prepare(
    'SELECT 1 FROM course_purchases WHERE user_id = ? AND category_id = ? AND (status = "completed" OR status = "verified") LIMIT 1'
  ).bind(userId, categoryId).first();
  return Boolean(row);
}

// 19. User Entitlements for the authenticated user (D1 is the ledger).
const entitlementsHandler = async (c: any) => {
  try {
    const userId = getRequestUserId(c);
    const result: any = await c.env.DB.prepare(
      'SELECT DISTINCT category_id FROM course_purchases WHERE user_id = ? AND (status = "completed" OR status = "verified")'
    ).bind(userId).all();
    const categoryIds = (result.results || [])
      .map((r: any) => r.category_id)
      .filter((id: any) => typeof id === 'string' && id.trim().length > 0);
    return c.json({ ok: true, userId, categoryIds, total: categoryIds.length });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Failed to fetch entitlements', categoryIds: [] }, 500);
  }
};

async function hmacSha256Hex(secret: string, payload: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(payload));
  return Array.from(new Uint8Array(sig)).map((b) => b.toString(16).padStart(2, '0')).join('');
}

export function registerPaymentRoutes(app: App): void {
  // 17. Create Razorpay Order
  app.post('/api/v1/payments/order', async (c) => {
    try {
      const body = await c.req.json().catch(() => ({}));
      const userId = getRequestUserId(c);
      const categoryId = String(body.categoryId || body.courseId || '').trim().slice(0, 64);
      if (!categoryId) {
        return c.json({ ok: false, message: 'Missing categoryId' }, 400);
      }

      const auth = razorpayAuth(c.env);
      if (!auth) {
        return c.json({ ok: false, message: 'Server payment configuration missing' }, 503);
      }

      const category: any = await c.env.DB.prepare(
        'SELECT id, title_latin, unlock_mode, raw_json FROM categories WHERE id = ? AND is_active = 1'
      ).bind(categoryId).first();
      if (!category) {
        return c.json({ ok: false, message: 'Category not found' }, 404);
      }
      let meta: any = {};
      try { meta = JSON.parse(category.raw_json || '{}'); } catch (_) {}
      const unlockMode = category.unlock_mode || meta.unlockMode || 'free';
      if (unlockMode === 'free') {
        return c.json({ ok: false, message: 'Category is already free' }, 400);
      }
      const priceInr = Number(meta.priceInr);
      if (!Number.isSafeInteger(priceInr) || priceInr <= 0) {
        return c.json({ ok: false, message: 'Invalid category price' }, 400);
      }
      const amount = priceInr * 100; // paise

      if (await userOwnsCategory(c.env.DB, userId, categoryId)) {
        return c.json({ ok: false, message: 'Category already unlocked' }, 409);
      }

      const categoryTitle = meta.name || meta.title || category.title_latin || '';

      // Reuse a recent unpaid order at the same price so retries don't create
      // a fresh Razorpay order each time.
      const since = new Date(Date.now() - ORDER_REUSE_WINDOW_MS).toISOString();
      const existing: any = await c.env.DB.prepare(
        'SELECT order_id, amount, currency FROM payment_orders WHERE user_id = ? AND category_id = ? AND status = "created" AND amount = ? AND created_at > ? ORDER BY created_at DESC LIMIT 1'
      ).bind(userId, categoryId, amount, since).first();
      if (existing) {
        return c.json({
          ok: true,
          orderId: existing.order_id,
          amount: existing.amount,
          currency: existing.currency,
          keyId: c.env.RAZORPAY_KEY_ID,
          categoryId,
          categoryTitle,
          isDuplicateRetry: true,
        });
      }

      const receipt = `rcpt_${(await stableId(`${userId}:${categoryId}:${Date.now()}`)).slice(0, 30)}`;
      const rzRes = await fetch(razorpayApi(c.env, '/v1/orders'), {
        method: 'POST',
        headers: { Authorization: auth, 'Content-Type': 'application/json' },
        body: JSON.stringify({ amount, currency: 'INR', receipt, notes: { userId, categoryId } }),
      });
      if (!rzRes.ok) {
        console.error(`Razorpay order creation failed (HTTP ${rzRes.status})`);
        return c.json({ ok: false, message: 'Unable to create payment order' }, 502);
      }
      const order: any = await rzRes.json();
      if (!order?.id || Number(order.amount) !== amount || order.currency !== 'INR') {
        return c.json({ ok: false, message: 'Unexpected payment gateway response' }, 502);
      }

      const now = new Date().toISOString();
      await c.env.DB.prepare(
        'INSERT INTO payment_orders (order_id, user_id, category_id, amount, currency, status, receipt, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
      ).bind(order.id, userId, categoryId, amount, 'INR', 'created', receipt, now, now).run();

      return c.json({
        ok: true,
        orderId: order.id,
        amount,
        currency: 'INR',
        keyId: c.env.RAZORPAY_KEY_ID,
        categoryId,
        categoryTitle,
        isDuplicateRetry: false,
      });
    } catch (err: any) {
      return c.json({ ok: false, message: err.message || 'Unable to create payment order' }, 500);
    }
  });

  // 18. Verify Course Purchase
  app.post('/api/v1/payments/verify', async (c) => {
    try {
      const body = await c.req.json().catch(() => ({}));
      const userId = getRequestUserId(c);
      const orderId = String(body.orderId || body.razorpayOrderId || '').trim();
      const paymentId = String(body.paymentId || body.razorpayPaymentId || '').trim();
      const signature = String(body.signature || body.razorpaySignature || '').trim().toLowerCase();
      if (!orderId || !paymentId || !signature) {
        return c.json({ ok: false, message: 'Missing Razorpay details' }, 400);
      }

      const auth = razorpayAuth(c.env);
      if (!auth) {
        return c.json({ ok: false, message: 'Server payment configuration missing' }, 503);
      }

      // The order must be one this Worker created for this user.
      const order: any = await c.env.DB.prepare(
        'SELECT order_id, user_id, category_id, amount, currency, status, payment_id FROM payment_orders WHERE order_id = ?'
      ).bind(orderId).first();
      if (!order || order.user_id !== userId) {
        return c.json({ ok: false, message: 'Order not found' }, 404);
      }
      if (order.status === 'paid') {
        if (order.payment_id === paymentId && await userOwnsCategory(c.env.DB, userId, order.category_id)) {
          return c.json({ ok: true, verified: true, categoryId: order.category_id, isRetry: true });
        }
        return c.json({ ok: false, message: 'Order already settled with a different payment' }, 409);
      }

      const expected = await hmacSha256Hex(c.env.RAZORPAY_KEY_SECRET!, `${orderId}|${paymentId}`);
      if (!timingSafeEqualStr(signature, expected)) {
        return c.json({ ok: false, message: 'Invalid payment signature' }, 400);
      }

      // Fail closed unless Razorpay confirms a captured payment for exactly
      // this order and amount.
      let payment: any;
      try {
        const payRes = await fetch(razorpayApi(c.env, `/v1/payments/${encodeURIComponent(paymentId)}`), {
          headers: { Authorization: auth },
        });
        if (!payRes.ok) {
          return c.json({ ok: false, message: 'Payment verification failed with payment gateway' }, 400);
        }
        payment = await payRes.json();
      } catch (_) {
        return c.json({ ok: false, message: 'Payment gateway verification failed due to network error' }, 502);
      }
      if (payment?.status !== 'captured') {
        return c.json({ ok: false, message: 'Payment is not captured' }, 400);
      }
      if (payment.order_id !== orderId) {
        return c.json({ ok: false, message: 'Payment does not belong to this order' }, 400);
      }
      if (Number(payment.amount) !== Number(order.amount) || payment.currency !== 'INR' || order.currency !== 'INR') {
        return c.json({ ok: false, message: 'Paid amount does not match the order' }, 400);
      }

      const now = new Date().toISOString();
      const purchaseId = await stableId(`purch:${userId}:${order.category_id}`);
      await c.env.DB.batch([
        c.env.DB.prepare(
          'UPDATE payment_orders SET status = "paid", payment_id = ?, signature = ?, updated_at = ? WHERE order_id = ?'
        ).bind(paymentId, signature, now, orderId),
        c.env.DB.prepare(
          'INSERT OR REPLACE INTO course_purchases (id, user_id, category_id, course_id, amount_in_cents, currency, status, order_id, payment_id, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        ).bind(purchaseId, userId, order.category_id, order.category_id, order.amount, 'INR', 'completed', orderId, paymentId, now),
      ]);

      return c.json({
        ok: true,
        verified: true,
        purchaseId,
        categoryId: order.category_id,
        message: 'Course purchase successfully verified and unlocked.',
      });
    } catch (err: any) {
      return c.json({ ok: false, message: err.message || 'Verification failed' }, 500);
    }
  });

  app.get('/api/v1/payments/entitlements', entitlementsHandler);

  app.post('/api/v1/payments/entitlements', entitlementsHandler);

  // Older app builds pushed category ids here. Writes are no longer accepted;
  // the route only returns the caller's entitlements.
  app.post('/api/v1/payments/entitlements/sync', entitlementsHandler);

  // 20. Razorpay Webhook. Rejects anything not signed with
  // RAZORPAY_WEBHOOK_SECRET over the exact raw body.
  app.post('/api/v1/payments/webhook', async (c) => {
    try {
      const secret = c.env.RAZORPAY_WEBHOOK_SECRET || '';
      if (!secret) {
        return c.json({ ok: false, message: 'Webhook secret not configured' }, 503);
      }
      const rawBody = await c.req.text();
      const signature = (c.req.header('x-razorpay-signature') || '').trim().toLowerCase();
      const expected = await hmacSha256Hex(secret, rawBody);
      if (!signature || !timingSafeEqualStr(signature, expected)) {
        return c.json({ ok: false, message: 'Invalid signature' }, 401);
      }

      let body: any = {};
      try { body = JSON.parse(rawBody); } catch (_) {
        return c.json({ ok: false, message: 'Invalid JSON' }, 400);
      }
      const event = body.event || '';
      const payload = body.payload || {};

      if (event === 'order.paid' || event === 'payment.captured') {
        const payment = payload.payment?.entity || {};
        const orderId = payment.order_id || payload.order?.entity?.id;
        const paymentId = payment.id;
        const now = new Date().toISOString();

        if (orderId) {
          const orderRow: any = await c.env.DB.prepare(
            'SELECT user_id, category_id, amount FROM payment_orders WHERE order_id = ?'
          ).bind(orderId).first();

          // Only honour the payment if Razorpay captured the full order amount.
          const paidAmount = Number(payment.amount ?? payload.order?.entity?.amount_paid ?? 0);
          const currency = payment.currency || payload.order?.entity?.currency;
          if (orderRow && Number(orderRow.amount) > 0 && paidAmount === Number(orderRow.amount) && currency === 'INR') {
            const purchaseId = await stableId(`purch:${orderRow.user_id}:${orderRow.category_id}`);
            await c.env.DB.batch([
              c.env.DB.prepare(
                'UPDATE payment_orders SET status = "paid", payment_id = ?, updated_at = ? WHERE order_id = ?'
              ).bind(paymentId || '', now, orderId),
              // A redelivered webhook for an order an admin already refunded
              // must not restore access; a new order (repurchase) still does.
              c.env.DB.prepare(
                `INSERT INTO course_purchases (id, user_id, category_id, course_id, amount_in_cents, currency, status, order_id, payment_id, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
               ON CONFLICT(id) DO UPDATE SET user_id = excluded.user_id, category_id = excluded.category_id, course_id = excluded.course_id,
                 amount_in_cents = excluded.amount_in_cents, currency = excluded.currency, status = excluded.status,
                 order_id = excluded.order_id, payment_id = excluded.payment_id, created_at = excluded.created_at
               WHERE NOT (course_purchases.status = 'refunded' AND course_purchases.order_id = excluded.order_id)`
              ).bind(purchaseId, orderRow.user_id, orderRow.category_id, orderRow.category_id, orderRow.amount, 'INR', 'completed', orderId, paymentId || '', now),
            ]);
          }
        }
      }

      return c.json({ ok: true, received: true });
    } catch (err: any) {
      return c.json({ ok: false, message: err.message || 'Webhook processing failed' }, 500);
    }
  });

  // 20. Reconcile Payment Attempts (replaces Appwrite reconcilePaymentAttempts function)
  app.post('/api/v1/payments/reconcile', async (c) => {
    try {
      const { reconciledCount } = await reconcilePaymentOrders(c.env.DB);
      return c.json({ ok: true, reconciledCount });
    } catch (err: any) {
      return c.json({ ok: false, message: err.message || 'Reconciliation failed' }, 500);
    }
  });
}
