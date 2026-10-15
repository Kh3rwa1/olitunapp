import { stableId, type App, type Bindings } from '../env';
import { adminUserId, clampInt } from './admin_common';

// Admin purchases & refunds over the D1 purchase ledger (replaces direct
// Appwrite reads of course_purchases and the admin-maintenance
// `record_refund` action).
//
// Refund semantics follow the former Appwrite admin-maintenance function
// (executeAdminRefund, `admin.refund` payment state; now removed):
// - a durable operationKey is required; the claim id is derived from it, so
//   retries converge on one operation and reusing a key with different
//   parameters is a 409 "Idempotency conflict";
// - amountPaise is the CUMULATIVE refunded total (max-floor: the stored
//   total never decreases); the purchase becomes `refunded` (entitlement
//   revoked) once the total reaches the paid amount;
// - only verified/completed, disputed or failed purchases can be refunded.
// Unlike Appwrite, the ledger update, claim and audit row commit in a single
// D1 batch (one transaction), so there are no partially recorded refunds.

const PAGE_SIZE_DEFAULT = 50;
const PAGE_SIZE_MAX = 200;
const EXPORT_PAGE_MAX = 1000;
const REFUNDABLE_STATUSES = new Set(['verified', 'completed', 'disputed', 'failed']);
const FILTERS = new Set(['all', 'razorpay', 'review', 'refunded']);

type PurchaseRow = {
  id: string;
  user_id: string;
  category_id: string;
  course_id: string | null;
  amount_in_cents: number | null;
  currency: string | null;
  status: string | null;
  order_id: string | null;
  payment_id: string | null;
  created_at: string;
  refund_order_id?: string | null;
  refund_status?: string | null;
  refunded_amount_paise?: number | null;
  refund_epoch?: number | null;
  last_refund_claim_id?: string | null;
};

const SELECT_PURCHASE = `SELECT p.id, p.user_id, p.category_id, p.course_id, p.amount_in_cents, p.currency, p.status,
  p.order_id, p.payment_id, p.created_at, r.order_id AS refund_order_id, r.refund_status,
  r.refunded_amount_paise, r.refund_epoch, r.last_refund_claim_id
  FROM course_purchases p LEFT JOIN purchase_refunds r ON r.purchase_id = p.id`;

function hasGatewayIds(row: PurchaseRow): boolean {
  return Boolean((row.order_id || '').trim() || (row.payment_id || '').trim());
}

// Refund bookkeeping applies only to the order it was recorded against.
function refundState(row: PurchaseRow) {
  const applies = row.refund_status != null && (row.refund_order_id || '') === (row.order_id || '');
  return {
    refundStatus: applies ? row.refund_status || null : null,
    refundedAmountPaise: applies ? Number(row.refunded_amount_paise || 0) : 0,
    // The epoch stays monotonic across repurchases; it fences writers.
    refundEpoch: Number(row.refund_epoch || 0),
    rowExists: row.refund_status != null,
  };
}

// Admin projection in the shape PurchaseModel.fromJson reads. D1 stores
// captured Razorpay purchases as `completed`; the admin UI calls that
// `verified` (the Appwrite name), and `rawStatus` keeps the stored value.
export function toAdminPurchase(row: PurchaseRow) {
  const paise = Number(row.amount_in_cents || 0);
  const refund = refundState(row);
  const provider = hasGatewayIds(row) ? 'razorpay' : 'manual';
  const status = row.status === 'completed' ? 'verified' : row.status || 'pending';
  return {
    id: row.id,
    $id: row.id,
    userId: row.user_id,
    categoryId: row.category_id,
    courseId: row.course_id || row.category_id,
    provider,
    unlockMethod: provider,
    paidAmount: Math.floor(paise / 100),
    amountPaise: paise,
    currency: row.currency || 'INR',
    providerOrderId: row.order_id || null,
    providerPaymentId: row.payment_id || null,
    status,
    rawStatus: row.status,
    refundStatus: refund.refundStatus,
    refundedAmountPaise: refund.refundedAmountPaise,
    createdAt: row.created_at,
    purchasedAt: row.created_at,
  };
}

function escapeLike(value: string): string {
  return value.replace(/[\\%_]/g, (ch) => `\\${ch}`);
}

export function buildPurchaseQuery(params: { filter: string; search: string; cursor: string; limit: number }) {
  const where: string[] = [];
  const binds: unknown[] = [];
  if (params.filter === 'razorpay') {
    where.push("(COALESCE(p.order_id, '') != '' OR COALESCE(p.payment_id, '') != '')");
    where.push("p.status IN ('completed', 'verified')");
  } else if (params.filter === 'review') {
    // Review unlocks were never recorded in the D1 ledger (it only holds
    // Razorpay captures), so this filter is always empty.
    where.push('1 = 0');
  } else if (params.filter === 'refunded') {
    where.push("p.status = 'refunded'");
  }
  if (params.search) {
    where.push("p.category_id LIKE ? ESCAPE '\\'");
    binds.push(`%${escapeLike(params.search)}%`);
  }
  if (params.cursor) {
    const sep = params.cursor.indexOf('|');
    const createdAt = sep > 0 ? params.cursor.slice(0, sep) : '';
    const id = sep > 0 ? params.cursor.slice(sep + 1) : '';
    if (!createdAt || !id) throw new Error('Invalid cursor');
    where.push('(p.created_at < ? OR (p.created_at = ? AND p.id < ?))');
    binds.push(createdAt, createdAt, id);
  }
  const sql = `${SELECT_PURCHASE}${where.length ? ` WHERE ${where.join(' AND ')}` : ''} ORDER BY p.created_at DESC, p.id DESC LIMIT ?`;
  binds.push(params.limit + 1);
  return { sql, binds };
}

async function listPurchases(c: any, maxLimit: number) {
  const filter = (c.req.query('filter') || 'all').trim();
  const search = (c.req.query('search') || '').trim().slice(0, 64);
  const cursor = (c.req.query('cursor') || '').trim().slice(0, 200);
  const limit = clampInt(c.req.query('limit'), PAGE_SIZE_DEFAULT, 1, maxLimit);
  if (!FILTERS.has(filter)) {
    return c.json({ ok: false, error: 'INVALID_INPUT', message: 'Unknown purchases filter' }, 400);
  }
  let query;
  try {
    query = buildPurchaseQuery({ filter, search, cursor, limit });
  } catch (_) {
    return c.json({ ok: false, error: 'INVALID_INPUT', message: 'Invalid cursor' }, 400);
  }
  try {
    const result = await c.env.DB.prepare(query.sql).bind(...query.binds).all();
    const rows = (result.results || []) as PurchaseRow[];
    const hasMore = rows.length > limit;
    const page = rows.slice(0, limit);
    const last = page[page.length - 1];
    return c.json({
      ok: true,
      purchases: page.map(toAdminPurchase),
      hasMore,
      nextCursor: hasMore && last ? `${last.created_at}|${last.id}` : null,
    });
  } catch (err: any) {
    console.error(`admin purchases list failed: ${err?.message || err}`);
    return c.json({ ok: false, error: 'QUERY_FAILED', message: 'Failed to load purchases' }, 500);
  }
}

export type RefundOutcome = { status: number; body: Record<string, unknown> };

function refundError(status: number, message: string): RefundOutcome {
  return { status, body: { success: false, ok: false, message } };
}

function refundSuccess(payload: Record<string, unknown>): RefundOutcome {
  return { status: 200, body: { success: true, ok: true, ...payload } };
}

async function loadPurchase(db: D1Database, purchaseId: string): Promise<PurchaseRow | null> {
  return (await db.prepare(`${SELECT_PURCHASE} WHERE p.id = ?`).bind(purchaseId).first()) as PurchaseRow | null;
}

function currentSnapshot(row: PurchaseRow) {
  const refund = refundState(row);
  return {
    purchaseId: row.id,
    status: row.status,
    refundStatus: refund.refundStatus,
    refundedAmountPaise: refund.refundedAmountPaise,
    refundEpoch: refund.refundEpoch,
  };
}

export async function recordRefund(env: Bindings, actor: string, body: Record<string, any>): Promise<RefundOutcome> {
  const purchaseId = String(body.purchaseId || '').trim().slice(0, 128);
  if (!purchaseId) return refundError(400, 'Missing purchase ID.');
  const operationKey = String(body.operationKey || body.idempotencyKey || body.externalRefundId || '').trim().slice(0, 200);
  if (!operationKey) {
    return refundError(400, 'Missing operation identity: provide operationKey (or idempotencyKey).');
  }
  const gatewayRefundId = String(body.gatewayRefundId || body.externalRefundId || '').trim().slice(0, 200);
  const reason = String(body.reason || 'Admin recorded refund').trim().slice(0, 500);

  const db = env.DB;
  const purchase = await loadPurchase(db, purchaseId);
  if (!purchase) return refundError(404, `Purchase ${purchaseId} not found.`);

  const expectedPaise = Number(purchase.amount_in_cents || 0);
  const refund = refundState(purchase);

  let amountPaise: number;
  if (body.amountPaise !== undefined && body.amountPaise !== null) {
    const raw = Number(body.amountPaise);
    if (!Number.isSafeInteger(raw) || raw <= 0) {
      return refundError(400, 'Invalid refund amount: amountPaise must be a positive integer.');
    }
    if (expectedPaise > 0 && raw > expectedPaise) {
      return refundError(400, `Refund amount (${raw} paise) exceeds purchase amount (${expectedPaise} paise).`);
    }
    amountPaise = raw;
  } else {
    amountPaise = expectedPaise;
    if (!Number.isSafeInteger(amountPaise) || amountPaise <= 0) {
      return refundError(400, 'Unable to determine refund amount from purchase.');
    }
  }

  const claimId = await stableId(`refund:${operationKey}`);
  const replay = await replayClaim(db, claimId, purchaseId, amountPaise, purchase);
  if (replay) return replay;

  const alreadyRefunded =
    purchase.status === 'refunded' ||
    refund.refundStatus === 'fully_refunded' ||
    (expectedPaise > 0 && refund.refundedAmountPaise >= expectedPaise);
  if (alreadyRefunded) return refundSuccess({ alreadyRefunded: true, ...currentSnapshot(purchase) });

  const status = purchase.status || '';
  if (!REFUNDABLE_STATUSES.has(status)) {
    return refundError(409, `Cannot refund purchase in status '${status}'.`);
  }

  const target = Math.max(refund.refundedAmountPaise, amountPaise);
  const full = !(expectedPaise > 0) || target >= expectedPaise;
  const refundStatus = full ? 'fully_refunded' : 'partially_refunded';
  const nextStatus = full ? 'refunded' : status;
  const epoch = refund.refundEpoch + 1;
  const now = new Date().toISOString();
  const orderId = purchase.order_id || '';
  const pointerIsOurs =
    'EXISTS (SELECT 1 FROM purchase_refunds WHERE purchase_id = ? AND last_refund_claim_id = ? AND refund_epoch = ?)';

  const statements: D1PreparedStatement[] = [
    // Fenced on the epoch read above and the purchase status validated
    // above: a concurrent writer makes this a no-op, and the conditional
    // statements below then write nothing either.
    db.prepare(
      `INSERT INTO purchase_refunds (purchase_id, order_id, refund_status, refunded_amount_paise, refund_epoch, last_refund_claim_id, updated_at)
       SELECT ?, ?, ?, ?, ?, ?, ? WHERE EXISTS (SELECT 1 FROM course_purchases WHERE id = ? AND status = ?)
       ON CONFLICT(purchase_id) DO UPDATE SET order_id = excluded.order_id, refund_status = excluded.refund_status,
         refunded_amount_paise = excluded.refunded_amount_paise, refund_epoch = excluded.refund_epoch,
         last_refund_claim_id = excluded.last_refund_claim_id, updated_at = excluded.updated_at
       WHERE purchase_refunds.refund_epoch = ?`
    ).bind(purchaseId, orderId, refundStatus, target, epoch, claimId, now, purchaseId, status, refund.refundEpoch),
  ];
  if (full) {
    statements.push(
      db.prepare(`UPDATE course_purchases SET status = 'refunded' WHERE id = ? AND status = ? AND ${pointerIsOurs}`)
        .bind(purchaseId, status, purchaseId, claimId, epoch),
    );
  }
  statements.push(
    db.prepare(
      `INSERT INTO refund_claims (id, operation_key, refund_ref, purchase_id, amount_paise, currency, status, actor_user_id, reason, claimed_at)
       SELECT ?, ?, ?, ?, ?, ?, 'committed', ?, ?, ? WHERE ${pointerIsOurs}`
    ).bind(claimId, operationKey, gatewayRefundId || operationKey, purchaseId, amountPaise, purchase.currency || 'INR', actor, reason, now, purchaseId, claimId, epoch),
    db.prepare(
      `INSERT INTO admin_audit_logs (id, admin_user_id, action, target_id, details_json, timestamp)
       SELECT ?, ?, 'refund_recorded', ?, ?, ? WHERE EXISTS (SELECT 1 FROM refund_claims WHERE id = ?)`
    ).bind(
      await stableId(`audit:${claimId}`), actor, purchaseId,
      JSON.stringify({
        userId: purchase.user_id, categoryId: purchase.category_id, operationKey,
        externalRefundId: gatewayRefundId || operationKey, reason, refundAmountPaise: amountPaise,
        totalRefundedPaise: target, previousStatus: status, newStatus: nextStatus, refundStatus, refundEpoch: epoch,
      }),
      now, claimId,
    ),
  );

  try {
    await db.batch(statements);
  } catch (err: any) {
    const message = String(err?.message || err);
    if (!/UNIQUE|constraint/i.test(message)) throw err;
    // Same key raced us (claim id) or the gateway refund is already
    // recorded under another operation (refund_ref).
    const raced = await replayClaim(db, claimId, purchaseId, amountPaise, (await loadPurchase(db, purchaseId)) || purchase);
    if (raced) return raced;
    return refundError(409, 'This gateway refund was already recorded under a different operation. Retry with the original operation key.');
  }

  const claim = await db.prepare('SELECT id FROM refund_claims WHERE id = ?').bind(claimId).first();
  if (!claim) return refundError(409, 'Purchase state changed; refresh and retry.');
  return refundSuccess({
    alreadyRefunded: false,
    purchaseId,
    status: nextStatus,
    refundStatus,
    refundedAmountPaise: target,
    refundEpoch: epoch,
  });
}

async function replayClaim(
  db: D1Database,
  claimId: string,
  purchaseId: string,
  amountPaise: number,
  purchase: PurchaseRow,
): Promise<RefundOutcome | null> {
  const claim: any = await db.prepare('SELECT purchase_id, amount_paise FROM refund_claims WHERE id = ?').bind(claimId).first();
  if (!claim) return null;
  if (claim.purchase_id !== purchaseId || Number(claim.amount_paise) !== amountPaise) {
    return refundError(409, 'Idempotency conflict: operation key was already used with different refund parameters.');
  }
  return refundSuccess({ alreadyRefunded: true, ...currentSnapshot(purchase) });
}

export function registerAdminPurchaseRoutes(app: App): void {
  app.get('/api/v1/admin/purchases', (c) => listPurchases(c, PAGE_SIZE_MAX));
  // Same filters as the list, with larger pages for CSV export.
  app.get('/api/v1/admin/purchases/export', (c) => listPurchases(c, EXPORT_PAGE_MAX));

  app.post('/api/v1/admin/purchases/refund', async (c) => {
    const body = await c.req.json().catch(() => null);
    if (!body || typeof body !== 'object') {
      return c.json({ success: false, ok: false, message: 'Invalid JSON body.' }, 400);
    }
    try {
      const outcome = await recordRefund(c.env, adminUserId(c), body);
      return c.json(outcome.body, outcome.status as any);
    } catch (err: any) {
      console.error(`record_refund failed: ${err?.message || err}`);
      return c.json({ success: false, ok: false, message: 'Refund recording failed.' }, 500);
    }
  });
}
