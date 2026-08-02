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

const LOCK_TTL_MS = 30000; // 30 seconds crash-recovery TTL for payment locks

export function createRazorpayWebhookHandler({ databases: customDb, fetchImpl = fetch } = {}) {
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
          // Claim repair on idempotent retry
          const claimId = stableId(`claim:${paymentId}`);
          try {
            const existingClaim = await databases.getDocument(databaseId, 'payment_claims', claimId);
            if (existingClaim.status === 'claimed') {
              await databases.updateDocument(databaseId, 'payment_claims', claimId, {
                status: 'committed',
                committedAt: now
              });
            }
          } catch (claimRepairErr) {
            error(`Claim repair failed on retry for payment ${paymentId}: ${claimRepairErr.message}`);
            return res.json({ ok: false, message: 'Payment claim repair failed. Retry shortly.' }, 503);
          }
          return res.json({ ok: true, message: 'Already processed' });
        }

        // Two-phase Payment Claim: claimed -> update ledger -> committed
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
                if (existingClaim.status === 'committed') {
                  return res.json({ ok: true, message: 'Payment already processed (committed)' });
                }
                // status is 'claimed'; resume processing safely
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

        // Transition claim status to committed after ledger update succeeds
        try {
          await databases.updateDocument(databaseId, 'payment_claims', claimId, {
            status: 'committed',
            committedAt: now
          });
        } catch (commitErr) {
          error(`Failed to commit payment claim ${claimId}: ${commitErr.message}`);
          return res.json({ ok: false, message: 'Failed to commit payment claim' }, 503);
        }

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
        return res.json({ ok: true, message: `Refund ${refundId} created acknowledged; awaiting refund.processed` });

      } else if (event === 'refund.processed') {
        const refund = payload.payload?.refund?.entity || {};
        const refundId = String(refund.id || '').trim();
        const paymentId = String(refund.payment_id || '').trim();
        const incrementalRefundPaise = Number(refund.amount || 0);
        const currency = String(refund.currency || 'INR').trim();

        if (!refundId || !paymentId) {
          return res.json({ ok: false, message: 'Missing refundId or paymentId in payload' }, 400);
        }

        const matchingDocs = await databases.listDocuments(databaseId, 'course_purchases', [
          Query.equal('providerPaymentId', paymentId),
          Query.limit(5)
        ]);

        if (matchingDocs.documents.length === 0) {
          return res.json({ ok: false, message: 'No course purchase found for this payment ID' }, 404);
        }
        if (matchingDocs.documents.length > 1) {
          error(`AMBIGUOUS PAYMENT ID: Found ${matchingDocs.documents.length} purchase records matching payment ID ${paymentId}`);
          return res.json({ ok: false, message: 'Multiple purchase records match this payment ID' }, 409);
        }

        const targetPurchaseDoc = matchingDocs.documents[0];
        const purchaseId = targetPurchaseDoc.$id;

        // 1. Two-phase Refund Claim creation in refund_claims collection (same-refund deduplication)
        const claimId = stableId(`refund:${refundId}`);
        const claimData = {
          refundId,
          paymentId,
          purchaseId,
          amountPaise: incrementalRefundPaise,
          currency,
          status: 'claimed',
          claimedAt: now,
          committedAt: null,
          lastError: ''
        };

        try {
          await databases.createDocument(databaseId, 'refund_claims', claimId, claimData);
        } catch (claimErr) {
          if (claimErr.code === 409) {
            const conflictRes = await handleRefundConflict(
              databases, databaseId, claimId, paymentId, refundId, purchaseId, incrementalRefundPaise, currency, res
            );
            if (conflictRes.action !== 'RESUME') {
              return conflictRes.res;
            }
            // Processing resumed for interrupted 'claimed' refund!
          } else {
            error(`FAIL CLOSED in refund webhook: Claim creation error ${claimErr.code}: ${claimErr.message}`);
            return res.json({ ok: false, message: 'Refund claim service unavailable' }, 503);
          }
        }

        // 2. Per-Payment Atomic Serialization Lock with Random Owner Token & Safe Stale Lock Takeover
        const ownerToken = stableId(`${paymentId}:${refundId}:${Math.random()}:${Date.now()}`);
        const paymentLockId = stableId(`lock:payment:${paymentId}`);
        let lockAcquired = false;

        try {
          await databases.createDocument(databaseId, 'refund_claims', paymentLockId, {
            refundId: `lock:${paymentId}`,
            paymentId,
            purchaseId,
            amountPaise: 0,
            currency,
            status: 'locked',
            claimedAt: now,
            committedAt: null,
            lastError: ownerToken
          });
          lockAcquired = true;
        } catch (lockErr) {
          if (lockErr.code === 409) {
            try {
              const existingLock = await databases.getDocument(databaseId, 'refund_claims', paymentLockId);
              const lockAgeMs = Date.now() - new Date(existingLock.claimedAt || 0).getTime();

              if (lockAgeMs > LOCK_TTL_MS) {
                error(`STALE LOCK DETECTED: Payment lock ${paymentLockId} is ${lockAgeMs}ms old (> ${LOCK_TTL_MS}ms). Attempting atomic takeover...`);
                // Atomic Takeover Step 1: Delete stale lock document
                try {
                  await databases.deleteDocument(databaseId, 'refund_claims', paymentLockId);
                } catch (_) {}

                // Atomic Takeover Step 2: Re-create lock with our unique ownerToken
                try {
                  await databases.createDocument(databaseId, 'refund_claims', paymentLockId, {
                    refundId: `lock:${paymentId}`,
                    paymentId,
                    purchaseId,
                    amountPaise: 0,
                    currency,
                    status: 'locked',
                    claimedAt: now,
                    committedAt: null,
                    lastError: ownerToken
                  });
                  lockAcquired = true;
                  error(`STALE LOCK TAKEOVER WON: Payment lock ${paymentLockId} acquired by owner ${ownerToken}`);
                } catch (_) {
                  error(`STALE LOCK TAKEOVER LOST: Another worker acquired payment lock ${paymentLockId}`);
                  return res.json({ ok: false, message: 'Payment ledger update in progress; retry' }, 503);
                }
              } else {
                error(`CONCURRENT REFUND CONFLICT for payment ${paymentId} (lock age: ${lockAgeMs}ms). Returning 503 for Razorpay retry.`);
                return res.json({ ok: false, message: 'Payment ledger update in progress; retry' }, 503);
              }
            } catch (fetchLockErr) {
              error(`Failed to inspect payment lock: ${fetchLockErr.message}`);
              return res.json({ ok: false, message: 'Refund lock service unavailable' }, 503);
            }
          } else {
            error(`FAIL CLOSED in refund lock creation ${lockErr.code}: ${lockErr.message}`);
            return res.json({ ok: false, message: 'Refund lock service unavailable' }, 503);
          }
        }

        try {
          // 3. Authoritative Total Refund Calculation from Razorpay (FAIL CLOSED if unavailable)
          const paymentEntity = payload.payload?.payment?.entity || {};
          let authoritativeRefundPaise = Number(paymentEntity.amount_refunded || 0);

          if (authoritativeRefundPaise === 0) {
            const razorpaySecret = process.env.RAZORPAY_KEY_SECRET;
            const razorpayKeyId = process.env.RAZORPAY_KEY_ID;
            if (razorpaySecret && razorpayKeyId) {
              try {
                const authHeader = 'Basic ' + Buffer.from(`${razorpayKeyId}:${razorpaySecret}`).toString('base64');
                const paymentRes = await fetchImpl(`https://api.razorpay.com/v1/payments/${paymentId}`, {
                  headers: { 'Authorization': authHeader }
                });
                if (paymentRes.ok) {
                  const fetchedPayment = await paymentRes.json();
                  authoritativeRefundPaise = Number(fetchedPayment.amount_refunded || 0);
                }
              } catch (fetchErr) {
                error(`Authoritative payment fetch exception: ${fetchErr.message}`);
              }
            }
          }

          if (authoritativeRefundPaise <= 0) {
            error(`Authoritative refund total for payment ${paymentId} could not be determined. Failing closed.`);
            return res.json({ ok: false, message: 'Authoritative payment refund state unavailable' }, 503);
          }

          // 4. Update course_purchases ledger using authoritative total with re-fetch lock
          let latestDoc = targetPurchaseDoc;
          try {
            latestDoc = await databases.getDocument(databaseId, 'course_purchases', purchaseId);
          } catch (_) {}

          const expectedPaise = Math.round((latestDoc.expectedAmount || 0) * 100);
          const previousRefundedPaise = Number(latestDoc.refundedAmountPaise || 0);

          // Monotonic non-decreasing calculation
          const finalRefundedPaise = Math.max(previousRefundedPaise, authoritativeRefundPaise);
          const isFullyRefunded = finalRefundedPaise >= expectedPaise || expectedPaise === 0;

          await databases.updateDocument(databaseId, 'course_purchases', latestDoc.$id, {
            status: isFullyRefunded ? 'refunded' : 'verified',
            refundStatus: isFullyRefunded ? 'fully_refunded' : 'partially_refunded',
            refundedAmountPaise: finalRefundedPaise
          });

          // 5. Mark refund claim as committed after ledger update succeeds
          try {
            await databases.updateDocument(databaseId, 'refund_claims', claimId, {
              status: 'committed',
              committedAt: now
            });
          } catch (commitErr) {
            error(`Failed to commit refund claim ${claimId}: ${commitErr.message}`);
            return res.json({ ok: false, message: 'Failed to commit refund claim' }, 503);
          }

          return res.json({ ok: true, message: `Webhook refund.processed processed successfully` });

        } finally {
          if (lockAcquired) {
            try {
              const currentLock = await databases.getDocument(databaseId, 'refund_claims', paymentLockId);
              if (currentLock.lastError === ownerToken) {
                await databases.deleteDocument(databaseId, 'refund_claims', paymentLockId);
              } else {
                error(`LOCK RELEASE SKIPPED: Lock ${paymentLockId} owned by ${currentLock.lastError}, not ${ownerToken}`);
              }
            } catch (_) {}
          }
        }

      } else if (event === 'refund.failed') {
        const refund = payload.payload?.refund?.entity || {};
        const refundId = String(refund.id || '').trim();
        error(`Webhook refund.failed received for refund ${refundId}`);
        return res.json({ ok: true, message: `Refund ${refundId} failed; recorded without mutating entitlement` });

      } else if (event.startsWith('payment.dispute.')) {
        const dispute = payload.payload?.dispute?.entity || {};
        const paymentId = String(dispute.payment_id || '').trim();
        const disputeStatus = String(dispute.status || '').trim();

        if (paymentId) {
          const matchingDocs = await databases.listDocuments(databaseId, 'course_purchases', [
            Query.equal('providerPaymentId', paymentId),
            Query.limit(5)
          ]);

          if (matchingDocs.documents.length > 1) {
            error(`AMBIGUOUS PAYMENT ID: Found ${matchingDocs.documents.length} purchase records matching payment ID ${paymentId} during dispute`);
            return res.json({ ok: false, message: 'Multiple purchase records match this payment ID' }, 409);
          }

          let newStatus = 'disputed';
          if (event === 'payment.dispute.won' || (event === 'payment.dispute.closed' && disputeStatus === 'won')) {
            newStatus = 'verified';
          }

          for (const doc of matchingDocs.documents) {
            const expectedPaise = Math.round((doc.expectedAmount || 0) * 100);
            const isFullyRefunded = doc.refundStatus === 'fully_refunded' ||
              (doc.status === 'refunded') ||
              (doc.refundedAmountPaise && doc.refundedAmountPaise >= expectedPaise && expectedPaise > 0);

            let targetStatus = newStatus;
            if (newStatus === 'verified' && isFullyRefunded) {
              targetStatus = 'refunded';
            }

            await databases.updateDocument(databaseId, 'course_purchases', doc.$id, {
              status: targetStatus
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

async function handleRefundConflict(databases, databaseId, claimId, paymentId, refundId, purchaseId, amountPaise, currency, res) {
  try {
    const existingClaim = await databases.getDocument(databaseId, 'refund_claims', claimId);

    // Validate ownership metadata AND purchaseId!
    if (existingClaim.paymentId !== paymentId ||
        existingClaim.refundId !== refundId ||
        existingClaim.purchaseId !== purchaseId ||
        existingClaim.amountPaise !== amountPaise ||
        existingClaim.currency !== currency) {
      return {
        action: 'REPLAY',
        res: res.json({ ok: false, message: 'Refund claim ownership mismatch' }, 409)
      };
    }

    if (existingClaim.status === 'committed') {
      return {
        action: 'DONE',
        res: res.json({ ok: true, message: `Refund ${refundId} already processed (committed)` })
      };
    }

    return { action: 'RESUME', existingClaim };
  } catch (err) {
    return {
      action: 'ERROR',
      res: res.json({ ok: false, message: 'Failed to inspect existing refund claim' }, 503)
    };
  }
}

export default async (context) => createRazorpayWebhookHandler()(context);
