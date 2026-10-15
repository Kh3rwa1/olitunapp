import { appwriteGet, type AuthEnv } from './auth';

// Appwrite `course_purchases` is the only source of truth for paid access.
// Rows there are written exclusively by the verifyCoursePurchase and
// razorpayWebhook Appwrite Functions after Razorpay signature checks. D1's
// course_purchases table is a mirror for analytics; nothing here reads it to
// make an access decision.

const DATABASE_ID = 'olitun_db';
const TABLE_ID = 'course_purchases';
const CACHE_TTL_MS = 60_000;

const cache = new Map<string, { categoryIds: string[]; expiresAt: number }>();

// Same JSON shape the Appwrite SDKs' Query helpers serialize to.
function query(method: string, attribute: string, values: unknown[]): string {
  const q = attribute ? { method, attribute, values } : { method, values };
  return `queries[]=${encodeURIComponent(JSON.stringify(q))}`;
}

function categoryIdOf(row: any): string {
  const raw = row?.categoryId;
  if (typeof raw === 'string') return raw.trim();
  if (raw && typeof raw === 'object') return String(raw.$id || raw.id || '').trim();
  return '';
}

/**
 * Category ids the user has a verified purchase for, read from Appwrite with
 * the caller's own JWT (row permissions limit it to their purchases). Returns
 * null when Appwrite cannot answer, so callers can fail with 503 instead of
 * silently locking or unlocking content.
 */
export async function fetchVerifiedEntitlements(
  env: AuthEnv,
  jwt: string,
  userId: string,
): Promise<string[] | null> {
  const cached = cache.get(userId);
  if (cached && cached.expiresAt > Date.now()) return cached.categoryIds;

  const ids = new Set<string>();
  const pageSize = 100;
  let offset = 0;
  try {
    for (;;) {
      const path =
        `/tablesdb/${DATABASE_ID}/tables/${TABLE_ID}/rows?` +
        [
          query('equal', 'userId', [userId]),
          query('equal', 'status', ['verified']),
          query('limit', '', [pageSize]),
          query('offset', '', [offset]),
        ].join('&');
      const res = await appwriteGet(env, jwt, path);
      if (!res.ok) return null;
      const data: any = await res.json().catch(() => null);
      const rows: any[] = Array.isArray(data?.rows) ? data.rows : [];
      for (const row of rows) {
        // Defense in depth: never trust a row that isn't the caller's.
        if (row?.userId !== userId) continue;
        const id = categoryIdOf(row);
        if (id) ids.add(id);
      }
      offset += rows.length;
      if (rows.length < pageSize || offset >= Number(data?.total || 0)) break;
    }
  } catch (_) {
    return null;
  }

  const categoryIds = Array.from(ids);
  cache.set(userId, { categoryIds, expiresAt: Date.now() + CACHE_TTL_MS });
  return categoryIds;
}

/** Replaces the user's D1 mirror rows with the Appwrite-verified set. */
export async function mirrorEntitlementsToD1(
  db: D1Database,
  userId: string,
  categoryIds: string[],
  stableId: (value: string) => Promise<string>,
): Promise<void> {
  const now = new Date().toISOString();
  const statements = [db.prepare('DELETE FROM course_purchases WHERE user_id = ?').bind(userId)];
  for (const categoryId of categoryIds) {
    const purchaseId = await stableId(`purch:${userId}:${categoryId}`);
    statements.push(
      db.prepare(
        'INSERT OR REPLACE INTO course_purchases (id, user_id, category_id, course_id, amount_in_cents, currency, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
      ).bind(purchaseId, userId, categoryId, categoryId, 0, 'INR', 'completed', now),
    );
  }
  await db.batch(statements);
}
