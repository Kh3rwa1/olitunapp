import { requireUser } from '../auth';
import { getRequestUserId, stableId, type App, type Bindings } from '../env';

// Account deletion (replaces the Appwrite delete-account function). Mirrors
// functions/_shared/delete_account_core.js: purge every per-user D1 row and
// R2 object, anonymise financial records, verify nothing is left, then delete
// the Appwrite login. Success is reported only after both halves succeed, and
// every step is safe to repeat.

export const ANONYMIZED_USER_ID = 'anonymized_deleted_user';

// Statutory financial records are kept but detached from the person.
const ANONYMIZE_TABLES = ['course_purchases', 'payment_orders'];
// Bookkeeping for this flow; anonymised on completion, never purged.
const BOOKKEEPING_TABLE = 'deletion_requests';
// Tables that must exist; deletion fails closed if discovery misses them.
const REQUIRED_PURGE_TABLES = [
  'user_mistakes',
  'mistake_review_sessions',
  'bakhed_listening_progress',
  'user_badges',
  'reward_events',
  'learning_analytics_events',
  'learning_analytics_event_details',
  'binti_waitlist',
];
// Per-user R2 prefixes (user uploads, generated media).
const userR2Prefixes = (userId: string) => [`users/${userId}/`];
const MAX_R2_PAGES = 50;

type Outcome = { status: number; body: Record<string, unknown> };

class DeletionError extends Error {
  constructor(readonly code: string, readonly status = 500) {
    super(code);
  }
}

const SAFE_IDENT = /^[A-Za-z_][A-Za-z0-9_]*$/;

/**
 * Every table with a `user_id` column, so per-user tables added later by
 * other features are purged without editing this list.
 */
async function discoverUserTables(db: D1Database): Promise<string[]> {
  const tables = await db.prepare(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE '_cf_%' AND name NOT LIKE 'd1_%'"
  ).all<{ name: string }>();
  const names = (tables.results || []).map((r) => r.name).filter((n) => SAFE_IDENT.test(n));
  const infos = await db.batch(names.map((n) => db.prepare(`PRAGMA table_info("${n}")`)));
  return names.filter((_, i) => (infos[i].results as any[]).some((col) => col?.name === 'user_id'));
}

async function purgeR2(bucket: R2Bucket, userId: string): Promise<void> {
  for (const prefix of userR2Prefixes(userId)) {
    let cursor: string | undefined;
    for (let page = 0; ; page++) {
      if (page >= MAX_R2_PAGES) throw new DeletionError('ITERATION_LIMIT_EXCEEDED');
      const listed = await bucket.list({ prefix, cursor, limit: 1000 });
      const keys = listed.objects.map((o) => o.key);
      if (keys.length > 0) await bucket.delete(keys);
      if (!listed.truncated) break;
      cursor = listed.cursor;
    }
    const left = await bucket.list({ prefix, limit: 1 });
    if (left.objects.length > 0) throw new DeletionError('VERIFICATION_FAILED');
  }
}

async function deleteAppwriteUser(env: Bindings, userId: string): Promise<void> {
  const endpoint = env.APPWRITE_ENDPOINT.replace(/\/+$/, '');
  let res: Response;
  try {
    res = await fetch(`${endpoint}/users/${encodeURIComponent(userId)}`, {
      method: 'DELETE',
      headers: {
        'X-Appwrite-Project': env.APPWRITE_PROJECT_ID,
        'X-Appwrite-Key': env.APPWRITE_API_KEY || '',
        Accept: 'application/json',
      },
    });
  } catch (_) {
    throw new DeletionError('AUTH_DELETE_FAILED', 502);
  }
  if (res.ok) return;
  if (res.status === 404) {
    // Only an explicit "user not found" proves the login is gone; a 404 for
    // a wrong project or endpoint must not count as success.
    const data: any = await res.json().catch(() => null);
    if (data?.type === 'user_not_found') return;
  }
  throw new DeletionError('AUTH_DELETE_FAILED', 502);
}

async function setRequestState(db: D1Database, requestId: string, status: string, lastError: string | null) {
  await db.prepare('UPDATE deletion_requests SET status = ?, last_error = ?, updated_at = ? WHERE id = ?')
    .bind(status, lastError, new Date().toISOString(), requestId).run();
}

/**
 * Runs the full deletion for [userId]. Used by the user route and by the
 * admin reconcile job for interrupted requests.
 */
export async function deleteUserAccount(env: Bindings, userId: string): Promise<Outcome> {
  if (!env.APPWRITE_API_KEY || !env.APPWRITE_ENDPOINT || !env.APPWRITE_PROJECT_ID) {
    return {
      status: 503,
      body: { ok: false, code: 'server_misconfiguration', message: 'Account deletion is temporarily unavailable.' },
    };
  }

  const db = env.DB;
  const requestId = `del_${await stableId(`deletion:${userId}`)}`;
  const now = new Date().toISOString();

  try {
    // The real id is kept only while the request is open (so an interrupted
    // run can be resumed) and anonymised on completion.
    await db.prepare(
      `INSERT INTO deletion_requests (id, user_id, status, last_error, created_at, updated_at)
       VALUES (?, ?, 'in_progress', NULL, ?, ?)
       ON CONFLICT(id) DO UPDATE SET user_id = excluded.user_id, status = 'in_progress', last_error = NULL, updated_at = excluded.updated_at`
    ).bind(requestId, userId, now, now).run();
  } catch (_) {
    return {
      status: 500,
      body: { ok: false, code: 'deletion_failed', message: 'Failed to record deletion state. Deletion aborted for safety.' },
    };
  }

  try {
    // 1. R2 objects under per-user prefixes.
    await purgeR2(env.ASSETS, userId);

    // 2. D1 rows, atomically.
    const discovered = await discoverUserTables(db);
    const missing = REQUIRED_PURGE_TABLES.filter((t) => !discovered.includes(t));
    if (missing.length > 0) throw new DeletionError('COLLECTION_QUERY_FAILED');

    const purge = discovered.filter((t) => t !== BOOKKEEPING_TABLE && !ANONYMIZE_TABLES.includes(t));
    const anonymize = discovered.filter((t) => ANONYMIZE_TABLES.includes(t));
    await db.batch([
      ...purge.map((t) => db.prepare(`DELETE FROM "${t}" WHERE user_id = ?`).bind(userId)),
      ...anonymize.map((t) => db.prepare(`UPDATE "${t}" SET user_id = ? WHERE user_id = ?`).bind(ANONYMIZED_USER_ID, userId)),
    ]);

    // 3. Zero-record verification before the login is removed.
    const checks = await db.batch(
      [...purge, ...anonymize].map((t) => db.prepare(`SELECT COUNT(*) AS n FROM "${t}" WHERE user_id = ?`).bind(userId))
    );
    if (checks.some((r) => Number((r.results?.[0] as any)?.n || 0) > 0)) {
      throw new DeletionError('VERIFICATION_FAILED');
    }
    await setRequestState(db, requestId, 'cleanup_complete', null);

    // 4. The Appwrite login, last.
    await deleteAppwriteUser(env, userId);
  } catch (err: any) {
    const code = err instanceof DeletionError ? err.code : 'DOCUMENT_DELETE_FAILED';
    const status = err instanceof DeletionError ? err.status : 500;
    console.error(`account deletion failed: ${code}`);
    await setRequestState(db, requestId, 'cleanup_failed', code).catch(() => {
      console.error('account deletion: could not record failure state');
    });
    return {
      status,
      body: { ok: false, code: 'deletion_failed', message: 'Account deletion failed. Please try again.' },
    };
  }

  try {
    await db.prepare(
      "UPDATE deletion_requests SET user_id = ?, status = 'completed', last_error = NULL, updated_at = ? WHERE id = ?"
    ).bind(ANONYMIZED_USER_ID, new Date().toISOString(), requestId).run();
  } catch (_) {
    console.error('account deletion: auth deleted but final state update failed');
    return {
      status: 500,
      body: { ok: false, code: 'state_update_failed', authDeleted: true, message: 'Account deleted; final cleanup reconciliation is pending.' },
    };
  }

  return {
    status: 200,
    body: { ok: true, code: 'account_deleted', authDeleted: true, message: 'Account and associated personal data deleted.' },
  };
}

export function registerAccountRoutes(app: App): void {
  app.post('/api/v1/user/delete', requireUser, async (c) => {
    const userId = getRequestUserId(c);
    if (!userId) return c.json({ ok: false, code: 'unauthenticated', message: 'Authentication required' }, 401);
    const outcome = await deleteUserAccount(c.env, userId);
    return c.json(outcome.body, outcome.status as any);
  });
}
