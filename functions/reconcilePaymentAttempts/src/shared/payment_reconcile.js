import { createHash } from 'crypto';
import { Query } from 'node-appwrite';

/**
 * SOURCE OF TRUTH for this shared module.
 *
 * Appwrite function runtimes package only each function's own directory, so
 * cross-function imports fail at runtime. scripts/sync_shared_modules.mjs
 * copies this file into every consumer listed in functions/_shared/manifest.json;
 * npm test fails if any synced copy drifts. Edit HERE, never the synced copies.
 */

function stableId(value) {
  return createHash('sha256').update(value).digest('hex').slice(0, 32);
}

/**
 * Reconciles stuck payment_attempts records.
 *
 * Checks payment_attempts in 'reconciliation_required' or stuck 'in_progress' status.
 * Queries Razorpay status via API if providerOrderId exists.
 * For paid orders, verifies the captured payment amount against the attempt's
 * expected price (paise) before writing the canonical course_purchases ledger
 * row (same stableId(`${userId}:${categoryId}`) key, schema, and document
 * permissions as createRazorpayOrder/verifyCoursePurchase/razorpayWebhook).
 * The ledger row is written BEFORE the attempt is marked verified, so a crash
 * between the two writes leaves the attempt retryable instead of granting
 * access with no ledger record.
 */
export async function reconcileStuckPaymentAttempts({
  databases,
  databaseId = 'olitun_db',
  fetchImpl = globalThis.fetch,
  razorpayKeyId,
  razorpayKeySecret,
  log = console.log,
  error = console.error,
}) {
  const stats = { scanned: 0, reconciled: 0, failed: 0 };

  try {
    const stuckAttempts = await databases.listDocuments(databaseId, 'payment_attempts', [
      Query.equal('status', ['reconciliation_required', 'in_progress']),
      Query.limit(50),
    ]);

    stats.scanned = stuckAttempts.documents.length;

    for (const attempt of stuckAttempts.documents) {
      try {
        if (!attempt.providerOrderId) {
          await databases.updateDocument(databaseId, 'payment_attempts', attempt.$id, {
            status: 'abandoned',
            reconciliationStatus: 'no_gateway_order',
            updatedAt: new Date().toISOString(),
          });
          stats.reconciled++;
          continue;
        }

        if (!razorpayKeyId || !razorpayKeySecret) {
          log(`Skipping gateway check for attempt ${attempt.$id}: Razorpay credentials missing`);
          continue;
        }

        const authHeader = 'Basic ' + Buffer.from(`${razorpayKeyId}:${razorpayKeySecret}`).toString('base64');
        const rzpRes = await fetchImpl(`https://api.razorpay.com/v1/orders/${attempt.providerOrderId}`, {
          method: 'GET',
          headers: { Authorization: authHeader },
        });

        if (!rzpRes.ok) {
          error(`Razorpay API check failed for order ${attempt.providerOrderId}: ${rzpRes.status}`);
          stats.failed++;
          continue;
        }

        const rzpOrder = await rzpRes.json();

        if (rzpOrder.status === 'paid') {
          const paymentsRes = await fetchImpl(
            `https://api.razorpay.com/v1/orders/${attempt.providerOrderId}/payments`,
            { method: 'GET', headers: { Authorization: authHeader } },
          );
          if (!paymentsRes.ok) {
            error(`Razorpay payments check failed for order ${attempt.providerOrderId}: ${paymentsRes.status}`);
            stats.failed++;
            continue;
          }
          const paymentsBody = await paymentsRes.json();
          const captured = (paymentsBody.items || [])
            .filter((p) => p && p.status === 'captured')
            .sort((a, b) => (a.created_at || 0) - (b.created_at || 0));
          const payment = captured[captured.length - 1];

          if (!payment) {
            error(`Order ${attempt.providerOrderId} is paid but no captured payment was found; leaving for manual review`);
            await databases.updateDocument(databaseId, 'payment_attempts', attempt.$id, {
              reconciliationStatus: 'no_captured_payment',
              updatedAt: new Date().toISOString(),
            });
            stats.failed++;
            continue;
          }

          const expectedAmountPaise = Math.round((attempt.expectedAmount || 0) * 100);
          const paidAmountPaise = Number(payment.amount || 0);
          if (paidAmountPaise !== expectedAmountPaise) {
            error(
              `Amount mismatch for attempt ${attempt.$id}: paid ${paidAmountPaise} paise, expected ${expectedAmountPaise} paise; not granting access`,
            );
            await databases.updateDocument(databaseId, 'payment_attempts', attempt.$id, {
              reconciliationStatus: 'amount_mismatch',
              updatedAt: new Date().toISOString(),
            });
            stats.failed++;
            continue;
          }

          const purchaseId = stableId(`${attempt.userId}:${attempt.categoryId}`);
          const now = new Date().toISOString();
          const adminTeamId = process.env.ADMIN_TEAM_ID || 'admins';
          const documentPermissions = [
            `read("user:${attempt.userId}")`,
            `read("team:${adminTeamId}")`,
            `update("team:${adminTeamId}")`,
            `delete("team:${adminTeamId}")`,
          ];
          const verifiedLedger = {
            userId: attempt.userId,
            categoryId: attempt.categoryId,
            provider: 'razorpay',
            providerOrderId: attempt.providerOrderId,
            providerPaymentId: payment.id,
            expectedAmount: attempt.expectedAmount,
            paidAmount: Math.round(paidAmountPaise / 100),
            currency: 'INR',
            status: 'verified',
            paidAt: now,
            verifiedAt: now,
            failureReason: '',
          };

          try {
            await databases.updateDocument(
              databaseId,
              'course_purchases',
              purchaseId,
              verifiedLedger,
              documentPermissions,
            );
          } catch (purchErr) {
            if (purchErr.code === 404) {
              await databases.createDocument(
                databaseId,
                'course_purchases',
                purchaseId,
                verifiedLedger,
                documentPermissions,
              );
            } else {
              throw purchErr;
            }
          }

          await databases.updateDocument(databaseId, 'payment_attempts', attempt.$id, {
            status: 'verified',
            reconciliationStatus: 'reconciled_paid',
            updatedAt: now,
          });

          log(`Successfully reconciled paid attempt ${attempt.$id}`);
          stats.reconciled++;
        } else {
          await databases.updateDocument(databaseId, 'payment_attempts', attempt.$id, {
            status: 'expired',
            reconciliationStatus: `reconciled_${rzpOrder.status}`,
            updatedAt: new Date().toISOString(),
          });
          stats.reconciled++;
        }
      } catch (attemptErr) {
        error(`Failed reconciling attempt ${attempt.$id}: ${attemptErr.message}`);
        stats.failed++;
      }
    }
  } catch (err) {
    error(`Reconciliation process failed: ${err.message}`);
  }

  return stats;
}

/**
 * Reconciles disputed course_purchases against Razorpay authoritative dispute state.
 *
 * Scans course_purchases where status == 'disputed'.
 * Queries Razorpay payment dispute endpoint.
 * If latest dispute is 'won' (or closed with merchant winning):
 *   Restores course_purchases status to 'verified'.
 * If latest dispute is 'lost':
 *   Revokes entitlement, course_purchases status to 'revoked'.
 * If latest dispute is 'open' or 'under_review':
 *   Preserves 'disputed' containment status.
 */
export async function reconcileDisputedPurchases({
  databases,
  databaseId = 'olitun_db',
  fetchImpl = globalThis.fetch,
  razorpayKeyId,
  razorpayKeySecret,
  log = console.log,
  error = console.error,
}) {
  const stats = { scanned: 0, won: 0, lost: 0, pending: 0, failed: 0 };

  try {
    const disputedPurchases = await databases.listDocuments(databaseId, 'course_purchases', [
      Query.equal('status', 'disputed'),
      Query.limit(50),
    ]);

    stats.scanned = disputedPurchases.documents.length;

    if (stats.scanned === 0) {
      return stats;
    }

    if (!razorpayKeyId || !razorpayKeySecret) {
      log('Skipping dispute reconciliation: Razorpay credentials missing');
      return stats;
    }

    const authHeader = 'Basic ' + Buffer.from(`${razorpayKeyId}:${razorpayKeySecret}`).toString('base64');

    for (const purchase of disputedPurchases.documents) {
      try {
        if (!purchase.providerPaymentId) {
          log(`Skipping purchase ${purchase.$id}: missing providerPaymentId`);
          continue;
        }

        // 1. Fetch disputes for payment from Razorpay API
        const disputesRes = await fetchImpl(
          `https://api.razorpay.com/v1/payments/${purchase.providerPaymentId}/disputes`,
          { method: 'GET', headers: { Authorization: authHeader } },
        );

        let latestDispute = null;

        if (disputesRes.ok) {
          const body = await disputesRes.json();
          const items = (body.items || []).sort(
            (a, b) => (b.created_at || 0) - (a.created_at || 0),
          );
          if (items.length > 0) {
            latestDispute = items[0];
          }
        } else if (disputesRes.status !== 404) {
          error(`Razorpay disputes check failed for payment ${purchase.providerPaymentId}: ${disputesRes.status}`);
          stats.failed++;
          continue;
        }

        // 2. If no dispute record in dispute endpoint, check payment entity directly
        if (!latestDispute) {
          const paymentRes = await fetchImpl(
            `https://api.razorpay.com/v1/payments/${purchase.providerPaymentId}`,
            { method: 'GET', headers: { Authorization: authHeader } },
          );

          if (!paymentRes.ok) {
            error(`Razorpay payment fetch failed for payment ${purchase.providerPaymentId}: ${paymentRes.status}`);
            stats.failed++;
            continue;
          }

          const paymentBody = await paymentRes.json();
          // If payment is captured and not disputed or refunded, dispute was cleared
          if (paymentBody.status === 'captured' && !paymentBody.disputed && Number(paymentBody.amount_refunded || 0) === 0) {
            latestDispute = { status: 'won' };
          } else if (Number(paymentBody.amount_refunded || 0) > 0 || paymentBody.status === 'refunded') {
            latestDispute = { status: 'lost' };
          } else {
            latestDispute = { status: 'under_review' };
          }
        }

        const disputeStatus = String(latestDispute.status || '').toLowerCase();

        if (disputeStatus === 'won' || (disputeStatus === 'closed' && latestDispute.reason_code !== 'lost')) {
          // Entitlement recovered
          await databases.updateDocument(
            databaseId,
            'course_purchases',
            purchase.$id,
            { status: 'verified' },
          );
          log(`Dispute WON for purchase ${purchase.$id} (payment: ${purchase.providerPaymentId}). Entitlement restored.`);
          stats.won++;
        } else if (disputeStatus === 'lost') {
          // Entitlement revoked
          await databases.updateDocument(
            databaseId,
            'course_purchases',
            purchase.$id,
            { status: 'revoked' },
          );
          log(`Dispute LOST for purchase ${purchase.$id} (payment: ${purchase.providerPaymentId}). Entitlement revoked.`);
          stats.lost++;
        } else {
          // Still active dispute: open, under_review, action_required
          log(`Dispute still active (${disputeStatus}) for purchase ${purchase.$id}. Keeping disputed status.`);
          stats.pending++;
        }
      } catch (err) {
        error(`Failed reconciling dispute for purchase ${purchase.$id}: ${err.message}`);
        stats.failed++;
      }
    }
  } catch (err) {
    error(`Dispute reconciliation process failed: ${err.message}`);
  }

  return stats;
}
