// A checkout must never unconditionally replace another order or an entitlement.
// First purchases use atomic document creation; only a refunded purchase can be
// replaced, and that transition requires Appwrite's optimistic transaction API.
export class CheckoutConflict extends Error {
  constructor(message = 'Purchase state changed. Please refresh and retry.') {
    super(message);
    this.code = 409;
  }
}

export function isPayablePurchase(purchase) {
  return ['created', 'failed'].includes(purchase?.status) &&
    typeof purchase.providerOrderId === 'string' &&
    purchase.providerOrderId.length > 0 &&
    Number.isSafeInteger(purchase.expectedAmount) &&
    purchase.expectedAmount > 0 && purchase.currency === 'INR';
}

export async function publishPendingPurchase({
  databases, databaseId, purchaseId, data, permissions,
}) {
  // The unique user/category document ID elects the canonical order even when
  // different devices submit different client idempotency keys concurrently.
  try {
    return await databases.createDocument(
      databaseId, 'course_purchases', purchaseId, data, permissions,
    );
  } catch (err) {
    if (err.code !== 409) throw err;
  }

  const current = await databases.getDocument(databaseId, 'course_purchases', purchaseId);
  if (current.userId !== data.userId || current.categoryId !== data.categoryId) {
    throw new CheckoutConflict('Purchase ownership does not match the checkout.');
  }
  if (current.status === 'verified' || isPayablePurchase(current)) return current;
  if (current.status !== 'refunded' || current.providerOrderId === data.providerOrderId) {
    throw new CheckoutConflict();
  }

  // Do not revive the refunded order on an old idempotency-key retry.
  // Repurchase is the only replacement path. Never fall back to a plain update
  // if transactions are unsupported or unavailable in the deployment.
  const transaction = await databases.createTransaction({ ttl: 15 });
  let committed = false;
  try {
    const latest = await databases.getDocument({
      databaseId, collectionId: 'course_purchases', documentId: purchaseId,
      transactionId: transaction.$id,
    });
    if (latest.userId !== data.userId || latest.categoryId !== data.categoryId) {
      throw new CheckoutConflict();
    }
    if (latest.status === 'verified' || isPayablePurchase(latest)) return latest;
    if (latest.status !== 'refunded' || latest.providerOrderId !== current.providerOrderId) {
      throw new CheckoutConflict();
    }
    const next = await databases.updateDocument({
      databaseId, collectionId: 'course_purchases', documentId: purchaseId,
      data: { ...data, refundedAmountPaise: 0, refundStatus: '' },
      permissions, transactionId: transaction.$id,
    });
    await databases.updateTransaction({ transactionId: transaction.$id, commit: true });
    committed = true;
    return next;
  } finally {
    if (!committed) {
      try {
        await databases.updateTransaction({ transactionId: transaction.$id, rollback: true });
      } catch {
        // Preserve the original failure; an expired transaction is already closed.
      }
    }
  }
}
