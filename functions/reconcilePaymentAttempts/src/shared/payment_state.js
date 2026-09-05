// Canonical source. Sync into function packages with sync_shared_modules.mjs.
// Every entitlement write uses an optimistic transaction; never fall back to
// a read followed by an unconditional update when transactions are unavailable.
export class PaymentStateConflict extends Error {
  constructor(message = 'Purchase state changed; refresh and retry.') {
    super(message);
    this.code = 409;
  }
}

function fullyRefunded(doc) {
  const expected = Math.round(Number(doc.expectedAmount) * 100);
  return doc.status === 'refunded' || doc.refundStatus === 'fully_refunded' ||
    (expected > 0 && Number(doc.refundedAmountPaise || 0) >= expected);
}

export function assertCaptureAllowed(doc) {
  if (!['created', 'failed', 'verified'].includes(doc.status) || fullyRefunded(doc)) {
    throw new PaymentStateConflict('This purchase cannot be verified in its current state.');
  }
}

function assertBinding(current, expected) {
  for (const key of ['userId', 'categoryId', 'providerOrderId', 'providerPaymentId']) {
    if (expected?.[key] && current[key] !== expected[key] &&
        (key !== 'providerPaymentId' || current[key])) {
      throw new PaymentStateConflict('Purchase ownership or payment binding changed.');
    }
  }
}

function nextState(current, data, event) {
  if (event === 'payment.failed') {
    return ['created', 'failed'].includes(current.status) ? data : null;
  }
  if (event === 'refund.processed') {
    const total = Math.max(Number(current.refundedAmountPaise || 0), Number(data.refundedAmountPaise));
    const epoch = Number(data.refundEpoch);
    if (!Number.isSafeInteger(total) || total <= 0 || !Number.isSafeInteger(epoch) ||
        epoch < Number(current.refundEpoch || 0)) throw new PaymentStateConflict();
    const expected = Math.round(Number(current.expectedAmount) * 100);
    const full = fullyRefunded(current) || !(expected > 0) || total >= expected;
    return { ...data, refundedAmountPaise: total,
      status: full ? 'refunded' : current.status,
      refundStatus: full ? 'fully_refunded' : 'partially_refunded' };
  }
  if (event === 'admin.refund') {
    if (fullyRefunded(current)) return { ...current, status: 'refunded', refundStatus: 'fully_refunded' };
    const expected = Math.round(Number(current.expectedAmount || 0) * 100);
    const total = Math.max(Number(current.refundedAmountPaise || 0), Number(data.refundedAmountPaise || expected));
    const epoch = Number(data.refundEpoch || (Number(current.refundEpoch || 0) + 1));
    return {
      ...data,
      refundedAmountPaise: total,
      refundEpoch: epoch,
      status: 'refunded',
      refundStatus: 'fully_refunded',
    };
  }
  if (event?.startsWith('payment.dispute.')) {
    if (fullyRefunded(current)) return { ...data, status: 'refunded' };
    if (current.status === 'revoked') return null;
    // Webhook delivery order does not establish dispute identity or finality.
    // Until server-authoritative reconciliation is available, a won/closed
    // notification must not restore access over a newer dispute. Legitimate
    // wins also require reconciliation; this is deliberately conservative.
    if (data.status === 'verified') return null;
    if (data.status !== 'disputed') throw new PaymentStateConflict();
    return data;
  }
  if (event === 'reconcile.dispute') {
    if (fullyRefunded(current)) return { ...data, status: 'refunded', refundStatus: 'fully_refunded' };
    if (current.status === 'revoked' && data.status !== 'revoked') return null;
    // Server-authoritative dispute reconciliation restores access if won,
    // revokes entitlement if lost, and maintains disputed if pending.
    if (data.status === 'verified' || data.status === 'revoked' || data.status === 'disputed') {
      return data;
    }
    throw new PaymentStateConflict(`Unexpected dispute reconciliation status: ${data.status}`);
  }
  assertCaptureAllowed(current);
  if (data.status !== 'verified' || !data.providerPaymentId ||
      !['created', 'failed', 'verified'].includes(current.status)) throw new PaymentStateConflict();
  if (current.status === 'verified' && current.providerPaymentId !== data.providerPaymentId) {
    throw new PaymentStateConflict('A different payment already verified this purchase.');
  }
  if (data.expectedAmount !== undefined && data.expectedAmount !== current.expectedAmount) {
    throw new PaymentStateConflict('Purchase price changed.');
  }
  if (current.currency !== 'INR' || (data.currency && data.currency !== 'INR')) {
    throw new PaymentStateConflict('Purchase currency mismatch.');
  }
  return data;
}

// Request-scoped adapter: preserve each handler's gateway/signature/claim logic,
// but require every course_purchases update to pass the same transaction gate.
// Reads retain order/payment binding so a late refund cannot affect a repurchase.
export function withPaymentStateGuard(databases, { event = 'capture' } = {}) {
  const observed = new Map();
  const capture = ['capture', 'payment.captured', 'order.paid'].includes(event);
  const remember = doc => {
    if (doc?.$id && !observed.has(doc.$id)) observed.set(doc.$id, { ...doc });
    return doc;
  };
  return new Proxy(databases, {
    get(target, prop) {
      if (prop === 'getDocument') return async (...args) => {
        const col = typeof args[0] === 'object' ? args[0].collectionId : args[1];
        const doc = await target.getDocument(...args);
        if (col === 'course_purchases') {
          if (capture) assertCaptureAllowed(doc);
          remember(doc);
        }
        return doc;
      };
      if (prop === 'listDocuments') return async (...args) => {
        const col = typeof args[0] === 'object' ? args[0].collectionId : args[1];
        const result = await target.listDocuments(...args);
        if (col === 'course_purchases') result.documents.forEach(remember);
        return result;
      };
      if (prop === 'createDocument') return async (...args) => {
        const col = typeof args[0] === 'object' ? args[0].collectionId : args[1];
        const data = typeof args[0] === 'object' ? args[0].data : args[3];
        if (col === 'course_purchases' && data?.status === 'verified') {
          throw new PaymentStateConflict('Missing purchase ledger requires manual reconciliation.');
        }
        return target.createDocument(...args);
      };
      if (prop === 'updateDocument') return async (...args) => {
        const options = typeof args[0] === 'object' ? args[0] : {
          databaseId: args[0], collectionId: args[1], documentId: args[2],
          data: args[3], permissions: args[4],
        };
        if (options.collectionId !== 'course_purchases') return target.updateDocument(...args);
        if (typeof target.createTransaction !== 'function' || typeof target.updateTransaction !== 'function') {
          throw Object.assign(new Error('Payment transactions are unavailable.'), { code: 503 });
        }
        const transaction = await target.createTransaction({ ttl: 15 });
        let committed = false;
        try {
          const address = { databaseId: options.databaseId, collectionId: options.collectionId,
            documentId: options.documentId, transactionId: transaction.$id };
          const current = await target.getDocument(address);
          assertBinding(current, observed.get(options.documentId));
          assertBinding(current, options.data);
          const data = nextState(current, options.data, event);
          if (!data) return current;
          const result = await target.updateDocument({ ...address, data,
            ...(options.permissions ? { permissions: options.permissions } : {}) });
          await target.updateTransaction({ transactionId: transaction.$id, commit: true });
          committed = true;
          return result;
        } finally {
          if (!committed) {
            try { await target.updateTransaction({ transactionId: transaction.$id, rollback: true }); }
            catch { /* Preserve the original failure; expiry also closes a transaction. */ }
          }
        }
      };
      const value = target[prop];
      return typeof value === 'function' ? value.bind(target) : value;
    },
  });
}
