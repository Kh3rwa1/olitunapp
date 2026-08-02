import { createHmac, createHash, timingSafeEqual } from 'crypto';
import { Client, Databases, Query } from 'node-appwrite';

function stableId(value) {
  return createHash('sha256').update(value).digest('hex').slice(0, 32);
}

function safeCompare(a, b) {
  const bufA = Buffer.from(String(a || ''));
  const bufB = Buffer.from(String(b || ''));
  if (bufA.length !== bufB.length) return false;
  return timingSafeEqual(bufA, bufB);
}

function parseRawAndJson(req) {
  if (typeof req.bodyRaw === 'string' && req.bodyRaw.length > 0) {
    try {
      return { raw: req.bodyRaw, json: JSON.parse(req.bodyRaw) };
    } catch (_) {
      return { raw: req.bodyRaw, json: {} };
    }
  }
  if (typeof req.body === 'string') {
    try {
      return { raw: req.body, json: JSON.parse(req.body) };
    } catch (_) {
      return { raw: req.body, json: {} };
    }
  }
  if (typeof req.body === 'object' && req.body !== null) {
    return { raw: JSON.stringify(req.body), json: req.body };
  }
  return { raw: '{}', json: {} };
}

export function createRazorpayWebhookHandler({ databases: customDb } = {}) {
  return async ({ req, res, error }) => {
    if (req.method !== 'POST') {
      return res.json({ ok: false, message: 'Method not allowed' }, 405);
    }

    const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;
    if (!webhookSecret) {
      error('RAZORPAY_WEBHOOK_SECRET missing in environment');
      return res.json({ ok: false, message: 'Webhook misconfiguration' }, 500);
    }

    const signature = req.headers['x-razorpay-signature'];
    if (!signature) {
      return res.json({ ok: false, message: 'Missing webhook signature' }, 400);
    }

    const { raw, json: payload } = parseRawAndJson(req);

    // 1. Verify Razorpay webhook HMAC signature using raw bytes & constant-time comparison
    const expectedSignature = createHmac('sha256', webhookSecret)
      .update(raw)
      .digest('hex');

    if (!safeCompare(expectedSignature, signature)) {
      error('Invalid webhook signature attempt');
      return res.json({ ok: false, message: 'Invalid webhook signature' }, 400);
    }

    const event = String(payload.event || '').trim();
    if (!event) {
      return res.json({ ok: false, message: 'Missing event in payload' }, 400);
    }

    const endpoint = process.env.APPWRITE_FUNCTION_API_ENDPOINT;
    const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID;
    const apiKey = process.env.APPWRITE_FUNCTION_API_KEY || process.env.APPWRITE_API_KEY;

    if (!endpoint || !projectId || !apiKey) {
      error('Missing Appwrite configuration');
      return res.json({ ok: false, message: 'Server configuration error' }, 500);
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
    const now = new Date().toISOString();

    try {
      if (event === 'payment.captured' || event === 'order.paid') {
        const payment = payload.payload?.payment?.entity || {};
        const paymentId = String(payment.id || '').trim();
        const orderId = String(payment.order_id || '').trim();
        const amountPaise = Number(payment.amount || 0);
        const currency = String(payment.currency || '').trim();
        const notes = payment.notes || {};
        const userId = String(notes.userId || '').trim();
        const categoryId = String(notes.categoryId || '').trim();

        if (!paymentId || !orderId || !userId || !categoryId) {
          return res.json({ ok: false, message: 'Invalid payment payload data' }, 400);
        }

        const purchaseId = stableId(`${userId}:${categoryId}`);

        let pendingPurchase;
        try {
          pendingPurchase = await databases.getDocument(databaseId, 'course_purchases', purchaseId);
        } catch (err) {
          if (err.code === 404) {
            return res.json({ ok: false, message: 'Pending purchase document not found' }, 404);
          }
          throw err;
        }

        if (pendingPurchase.providerOrderId !== orderId) {
          return res.json({ ok: false, message: 'Order ID mismatch with pending ledger' }, 400);
        }
        if (pendingPurchase.userId !== userId) {
          return res.json({ ok: false, message: 'User ID mismatch with pending ledger' }, 400);
        }
        if (pendingPurchase.categoryId !== categoryId) {
          return res.json({ ok: false, message: 'Category ID mismatch with pending ledger' }, 400);
        }
        if ((pendingPurchase.expectedAmount * 100) !== amountPaise) {
          return res.json({ ok: false, message: 'Exact amount in paise mismatch' }, 400);
        }
        if (pendingPurchase.currency !== 'INR' || currency !== 'INR') {
          return res.json({ ok: false, message: 'Currency mismatch; INR required' }, 400);
        }

        if (pendingPurchase.status === 'verified' && pendingPurchase.providerPaymentId === paymentId) {
          return res.json({ ok: true, message: 'Already processed' });
        }

        // Atomic Payment ID Replay Protection & Safe Recovery
        const claimId = stableId(`claim:${paymentId}`);
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
            try {
              const existingClaim = await databases.getDocument(databaseId, 'payment_claims', claimId);
              if (existingClaim.paymentId === paymentId &&
                  existingClaim.userId === userId &&
                  existingClaim.categoryId === categoryId &&
                  existingClaim.providerOrderId === orderId) {
                // Safe idempotent retry for same transaction
              } else {
                error(`ATOMIC REPLAY ATTEMPT in webhook: Payment ID ${paymentId} already claimed by user ${existingClaim.userId}`);
                return res.json({ ok: false, message: 'Payment ID already claimed by another purchase' }, 409);
              }
            } catch (fetchClaimErr) {
              error(`Failed to fetch claim doc in webhook: ${fetchClaimErr.message}`);
              return res.json({ ok: false, message: 'Claim verification failed' }, 503);
            }
          } else {
            error(`FAIL CLOSED in webhook: Claim creation error ${claimErr.code}: ${claimErr.message}`);
            return res.json({ ok: false, message: 'Claim service unavailable' }, 503);
          }
        }

        const adminTeamId = process.env.ADMIN_TEAM_ID || 'admins';
        const documentPermissions = [
          `read("user:${userId}")`,
          `read("team:${adminTeamId}")`,
          `update("team:${adminTeamId}")`,
          `delete("team:${adminTeamId}")`
        ];

        await databases.updateDocument(
          databaseId,
          'course_purchases',
          purchaseId,
          {
            providerPaymentId: paymentId,
            paidAmount: Math.round(amountPaise / 100),
            status: 'verified',
            paidAt: now,
            verifiedAt: now
          },
          documentPermissions
        );

        try {
          await databases.updateDocument(databaseId, 'payment_claims', claimId, {
            status: 'committed',
            committedAt: now
          });
        } catch (_) {}

        return res.json({ ok: true, message: 'Webhook payment.captured processed' });

      } else if (event === 'payment.failed') {
        const payment = payload.payload?.payment?.entity || {};
        const orderId = String(payment.order_id || '').trim();
        const notes = payment.notes || {};
        const userId = String(notes.userId || '').trim();
        const categoryId = String(notes.categoryId || '').trim();

        if (userId && categoryId) {
          const purchaseId = stableId(`${userId}:${categoryId}`);
          try {
            const pendingPurchase = await databases.getDocument(databaseId, 'course_purchases', purchaseId);

            if (pendingPurchase.providerOrderId === orderId &&
                pendingPurchase.status !== 'verified' &&
                pendingPurchase.status !== 'refunded') {
              await databases.updateDocument(databaseId, 'course_purchases', purchaseId, {
                status: 'failed',
                failureReason: payment.error_description || 'Payment failed'
              });
            }
          } catch (_) {}
        }
        return res.json({ ok: true, message: 'Webhook payment.failed processed' });

      } else if (event === 'refund.created') {
        const refund = payload.payload?.refund?.entity || {};
        const refundId = String(refund.id || '').trim();
        const paymentId = String(refund.payment_id || '').trim();
        const incrementalRefundPaise = Number(refund.amount || 0);

        if (refundId && paymentId) {
          // Atomic Refund Deduplication: sha256("refund:" + refundId)
          const claimId = stableId(`refund:${refundId}`);
          try {
            await databases.createDocument(databaseId, 'payment_claims', claimId, {
              paymentId,
              purchaseId: refundId,
              providerOrderId: 'refund',
              userId: 'system',
              categoryId: 'refund',
              status: 'committed',
              claimedAt: now,
              committedAt: now
            });
          } catch (claimErr) {
            if (claimErr.code === 409) {
              // Safe Idempotency: Refund ID already processed!
              return res.json({ ok: true, message: `Refund ${refundId} already processed (idempotent)` });
            }
            error(`FAIL CLOSED in refund webhook: Claim creation error ${claimErr.code}: ${claimErr.message}`);
            return res.json({ ok: false, message: 'Claim service unavailable for refund' }, 503);
          }

          const matchingDocs = await databases.listDocuments(databaseId, 'course_purchases', [
            Query.equal('providerPaymentId', paymentId),
            Query.limit(5)
          ]);

          for (const doc of matchingDocs.documents) {
            const expectedPaise = Math.round((doc.expectedAmount || 0) * 100);
            const previousRefundPaise = Number(doc.refundedAmountPaise || 0);
            const totalRefundPaise = previousRefundPaise + incrementalRefundPaise;
            
            const isFullyRefunded = totalRefundPaise >= expectedPaise || expectedPaise === 0;

            await databases.updateDocument(databaseId, 'course_purchases', doc.$id, {
              status: isFullyRefunded ? 'refunded' : 'verified',
              refundStatus: isFullyRefunded ? 'fully_refunded' : 'partially_refunded',
              refundedAmountPaise: totalRefundPaise
            });
          }
        }
        return res.json({ ok: true, message: 'Webhook refund.created processed' });

      } else if (event.startsWith('payment.dispute.')) {
        const dispute = payload.payload?.dispute?.entity || {};
        const paymentId = String(dispute.payment_id || '').trim();
        const disputeStatus = String(dispute.status || '').trim();

        if (paymentId) {
          const matchingDocs = await databases.listDocuments(databaseId, 'course_purchases', [
            Query.equal('providerPaymentId', paymentId),
            Query.limit(5)
          ]);

          let newStatus = 'disputed';
          if (event === 'payment.dispute.won' || (event === 'payment.dispute.closed' && disputeStatus === 'won')) {
            newStatus = 'verified';
          }

          for (const doc of matchingDocs.documents) {
            await databases.updateDocument(databaseId, 'course_purchases', doc.$id, {
              status: newStatus
            });
          }
        }
        return res.json({ ok: true, message: `Webhook ${event} processed` });

      } else {
        return res.json({ ok: true, message: `Ignored unhandled event: ${event}` });
      }

    } catch (err) {
      error(`razorpayWebhook processing error: ${err.message}`);
      return res.json({ ok: false, message: err.message }, 500);
    }
  };
}

export default async (context) => createRazorpayWebhookHandler()(context);
