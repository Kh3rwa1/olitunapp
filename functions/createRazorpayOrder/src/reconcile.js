import { Query } from 'node-appwrite';

/**
 * Reconciles stuck payment_attempts records.
 *
 * Checks payment_attempts in 'reconciliation_required' or stuck 'in_progress' status.
 * Queries Razorpay status via API if providerOrderId exists.
 * Updates attempt status and verifies purchase in course_purchases if paid.
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
          await databases.updateDocument(databaseId, 'payment_attempts', attempt.$id, {
            status: 'verified',
            reconciliationStatus: 'reconciled_paid',
            updatedAt: new Date().toISOString(),
          });

          const purchaseId = `purch_${attempt.userId}_${attempt.categoryId}`;
          try {
            await databases.updateDocument(databaseId, 'course_purchases', purchaseId, {
              status: 'verified',
              updatedAt: new Date().toISOString(),
            });
          } catch (purchErr) {
            if (purchErr.code === 404) {
              await databases.createDocument(databaseId, 'course_purchases', purchaseId, {
                userId: attempt.userId,
                categoryId: attempt.categoryId,
                provider: 'razorpay',
                providerOrderId: attempt.providerOrderId,
                amount: attempt.expectedAmount,
                currency: 'INR',
                status: 'verified',
                createdAt: new Date().toISOString(),
                updatedAt: new Date().toISOString(),
              });
            }
          }

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
