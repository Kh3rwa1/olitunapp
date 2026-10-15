import { requireUser } from '../auth';
import { getRequestUserId, stableId, type App, type Bindings } from '../env';

// Account deletion (replaces the Appwrite delete-account function). Mirrors
// the former Appwrite delete_account_core (now removed): purge every per-user D1 row and
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

// Deletes the Appwrite login with the server key. Returns false when the key
// is missing or lacks the users.write scope, so the caller can fall back to
// blocking the account with the user's own session.
async function deleteAppwriteUser(env: Bindings, userId: string): Promise<boolean> {
  if (!env.APPWRITE_API_KEY) return false;
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
  if (res.ok) return true;
  const data: any = await res.json().catch(() => null);
  // Only an explicit "user not found" proves the login is gone; a 404 for
  // a wrong project or endpoint must not count as success.
  if (res.status === 404 && data?.type === 'user_not_found') return true;
  if (res.status === 401 && data?.type === 'general_unauthorized_scope') return false;
  throw new DeletionError('AUTH_DELETE_FAILED', 502);
}

// Permanently blocks the login using the user's own session (Appwrite
// account status API). Needs no server key; the user record remains in
// Appwrite until a server-side hard delete, but can never sign in again.
async function blockAppwriteUser(env: Bindings, jwt: string): Promise<void> {
  const endpoint = env.APPWRITE_ENDPOINT.replace(/\/+$/, '');
  let res: Response;
  try {
    res = await fetch(`${endpoint}/account/status`, {
      method: 'PATCH',
      headers: {
        'X-Appwrite-Project': env.APPWRITE_PROJECT_ID,
        'X-Appwrite-JWT': jwt,
        Accept: 'application/json',
      },
    });
  } catch (_) {
    throw new DeletionError('AUTH_BLOCK_FAILED', 502);
  }
  if (!res.ok) throw new DeletionError('AUTH_BLOCK_FAILED', 502);
}

async function setRequestState(db: D1Database, requestId: string, status: string, lastError: string | null) {
  await db.prepare('UPDATE deletion_requests SET status = ?, last_error = ?, updated_at = ? WHERE id = ?')
    .bind(status, lastError, new Date().toISOString(), requestId).run();
}

const deletionRequestId = async (userId: string) => `del_${await stableId(`deletion:${userId}`)}`;

// The real id is kept only while the request is open (so an interrupted run
// can be resumed) and anonymised on completion.
async function openRequest(db: D1Database, requestId: string, userId: string): Promise<void> {
  const now = new Date().toISOString();
  await db.prepare(
    `INSERT INTO deletion_requests (id, user_id, status, last_error, created_at, updated_at)
     VALUES (?, ?, 'in_progress', NULL, ?, ?)
     ON CONFLICT(id) DO UPDATE SET user_id = excluded.user_id, status = 'in_progress', last_error = NULL, updated_at = excluded.updated_at`
  ).bind(requestId, userId, now, now).run();
}

/**
 * Purges every per-user R2 object and D1 row (financial records are
 * anonymised), then verifies nothing is left. Throws DeletionError on any
 * failure. Safe to repeat; does not touch the Appwrite login.
 */
async function purgeUserData(env: Bindings, userId: string): Promise<void> {
  const db = env.DB;
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
}

/**
 * Re-runs only the data purge for an open request, for callers with neither
 * a user session nor the server key. On success the request is left at
 * `cleanup_complete` (data gone, login still present) so it is never
 * reported as completed; a later run with the server key finishes it.
 */
async function purgeUserDataForRequest(env: Bindings, userId: string): Promise<boolean> {
  const db = env.DB;
  const requestId = await deletionRequestId(userId);
  try {
    await openRequest(db, requestId, userId);
    await purgeUserData(env, userId);
    await setRequestState(db, requestId, 'cleanup_complete', null);
    return true;
  } catch (err: any) {
    const code = err instanceof DeletionError ? err.code : 'DOCUMENT_DELETE_FAILED';
    console.error(`account deletion purge failed: ${code}`);
    await setRequestState(db, requestId, 'cleanup_failed', code).catch(() => {});
    return false;
  }
}

export type DeletionReconcileResult = { scanned: number; completed: number; purged: number; failed: number };

/**
 * Resumes interrupted deletion requests not updated for [staleMs]. With the
 * Appwrite server key the full deletion (data + login) is re-run; without it
 * only the data purge is, and `cleanup_complete` requests (data already
 * gone, login pending) are left alone since nothing more can be done.
 */
export async function reconcileDeletions(
  env: Bindings,
  opts: { staleMs: number; limit?: number; now?: Date },
): Promise<DeletionReconcileResult> {
  const now = opts.now || new Date();
  const staleBefore = new Date(now.getTime() - opts.staleMs).toISOString();
  const canDeleteLogin = Boolean(env.APPWRITE_API_KEY && env.APPWRITE_ENDPOINT && env.APPWRITE_PROJECT_ID);
  const statuses = canDeleteLogin
    ? ['pending', 'in_progress', 'cleanup_failed', 'cleanup_complete']
    : ['pending', 'in_progress', 'cleanup_failed'];
  const pending = await env.DB.prepare(
    `SELECT id, user_id FROM deletion_requests WHERE status IN (${statuses.map(() => '?').join(', ')}) AND updated_at < ? AND user_id != ? LIMIT ?`
  ).bind(...statuses, staleBefore, ANONYMIZED_USER_ID, opts.limit ?? 20).all<{ id: string; user_id: string }>();

  const result: DeletionReconcileResult = { scanned: 0, completed: 0, purged: 0, failed: 0 };
  for (const req of pending.results || []) {
    if (!req.user_id) continue;
    result.scanned++;
    if (canDeleteLogin) {
      const outcome = await deleteUserAccount(env, req.user_id);
      if (outcome.status === 200) result.completed++;
      else result.failed++;
    } else if (await purgeUserDataForRequest(env, req.user_id)) {
      result.purged++;
    } else {
      result.failed++;
    }
  }
  return result;
}

/**
 * Runs the full deletion for [userId]. Used by the user route and by the
 * admin reconcile job for interrupted requests.
 */
export async function deleteUserAccount(env: Bindings, userId: string, jwt = ''): Promise<Outcome> {
  // Without a server key the login can only be removed by blocking it with
  // the user's own session, which the admin reconcile job does not have.
  if (!env.APPWRITE_ENDPOINT || !env.APPWRITE_PROJECT_ID || (!env.APPWRITE_API_KEY && !jwt)) {
    return {
      status: 503,
      body: { ok: false, code: 'server_misconfiguration', message: 'Account deletion is temporarily unavailable.' },
    };
  }

  const db = env.DB;
  const requestId = await deletionRequestId(userId);
  try {
    await openRequest(db, requestId, userId);
  } catch (_) {
    return {
      status: 500,
      body: { ok: false, code: 'deletion_failed', message: 'Failed to record deletion state. Deletion aborted for safety.' },
    };
  }

  let loginBlocked = false;
  try {
    // 1-3. R2 objects, D1 rows, zero-record verification.
    await purgeUserData(env, userId);
    await setRequestState(db, requestId, 'cleanup_complete', null);

    // 4. The Appwrite login, last: hard delete, or block when the server key
    // cannot delete users.
    if (!(await deleteAppwriteUser(env, userId))) {
      if (!jwt) throw new DeletionError('AUTH_DELETE_FAILED', 503);
      await blockAppwriteUser(env, jwt);
      loginBlocked = true;
    }
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
    // A blocked login keeps its id so it can be hard-deleted later.
    await db.prepare(
      'UPDATE deletion_requests SET user_id = ?, status = ?, last_error = NULL, updated_at = ? WHERE id = ?'
    ).bind(
      loginBlocked ? userId : ANONYMIZED_USER_ID,
      loginBlocked ? 'login_blocked' : 'completed',
      new Date().toISOString(),
      requestId,
    ).run();
  } catch (_) {
    console.error('account deletion: auth deleted but final state update failed');
    return {
      status: 500,
      body: { ok: false, code: 'state_update_failed', authDeleted: true, message: 'Account deleted; final cleanup reconciliation is pending.' },
    };
  }

  return {
    status: 200,
    body: {
      ok: true,
      code: 'account_deleted',
      authDeleted: !loginBlocked,
      loginBlocked,
      message: 'Account and associated personal data deleted.',
    },
  };
}

export function registerAccountRoutes(app: App): void {
  app.post('/api/v1/user/delete', requireUser, async (c) => {
    const userId = getRequestUserId(c);
    if (!userId) return c.json({ ok: false, code: 'unauthenticated', message: 'Authentication required' }, 401);
    const outcome = await deleteUserAccount(c.env, userId, c.get('jwt'));
    return c.json(outcome.body, outcome.status as any);
  });
}
