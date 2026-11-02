import {
  ACCESS_TOKEN_TTL_SECONDS,
  newUserId,
  randomToken,
  sha256Hex,
  signAccessToken,
} from './worker_tokens';

// D1-backed users and sessions for Worker-owned sign-in.

export const REFRESH_TOKEN_TTL_DAYS = 365;

export type AuthUserRow = {
  id: string;
  email: string | null;
  name: string;
  email_verified: number;
  is_guest: number;
  source: string;
  status: string;
  created_at: string;
  updated_at: string;
};

export type PublicUser = {
  id: string;
  email: string;
  name: string;
  emailVerified: boolean;
  isGuest: boolean;
  createdAt: string;
  updatedAt: string;
};

export type IssuedSession = {
  accessToken: string;
  accessTokenExpiresAt: string;
  refreshToken: string;
  user: PublicUser;
};

export class AuthError extends Error {
  constructor(readonly code: string, readonly status: 400 | 401 | 403 | 404 | 409 | 429 | 500 | 502 | 503) {
    super(code);
  }
}

const nowIso = () => new Date().toISOString();

export function normalizeEmail(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const email = value.trim().toLowerCase();
  if (email.length < 3 || email.length > 254) return null;
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return null;
  return email;
}

export function toPublicUser(row: AuthUserRow): PublicUser {
  return {
    id: row.id,
    email: row.email || '',
    name: row.name || '',
    emailVerified: row.email_verified === 1,
    isGuest: row.is_guest === 1,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export async function getUser(db: D1Database, id: string): Promise<AuthUserRow | null> {
  return db.prepare('SELECT * FROM auth_users WHERE id = ?').bind(id).first<AuthUserRow>();
}

export async function getActiveUserByEmail(db: D1Database, email: string): Promise<AuthUserRow | null> {
  return db
    .prepare("SELECT * FROM auth_users WHERE email = ? AND status = 'active'")
    .bind(email)
    .first<AuthUserRow>();
}

export async function insertUser(
  db: D1Database,
  user: { id: string; email: string | null; name: string; emailVerified: boolean; isGuest: boolean; source: string },
): Promise<AuthUserRow> {
  const now = nowIso();
  await db
    .prepare(
      `INSERT INTO auth_users (id, email, name, email_verified, is_guest, source, status, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, 'active', ?, ?)`,
    )
    .bind(user.id, user.email, user.name, user.emailVerified ? 1 : 0, user.isGuest ? 1 : 0, user.source, now, now)
    .run();
  const row = await getUser(db, user.id);
  if (!row) throw new AuthError('USER_CREATE_FAILED', 500);
  return row;
}

const SAFE_IDENT = /^[A-Za-z_][A-Za-z0-9_]*$/;

/**
 * Moves every `user_id` row from [fromId] to [toId] (the same discovery the
 * account-deletion purge uses). Rows that would collide with one the target
 * already has are dropped, so the target's own data wins.
 */
export async function mergeUserData(db: D1Database, fromId: string, toId: string): Promise<void> {
  if (fromId === toId) return;
  const tables = await db
    .prepare(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE '_cf_%' AND name NOT LIKE 'd1_%'",
    )
    .all<{ name: string }>();
  const names = (tables.results || []).map((r) => r.name).filter((n) => SAFE_IDENT.test(n));
  const infos = await db.batch(names.map((n) => db.prepare(`PRAGMA table_info("${n}")`)));
  // Sessions stay with their own id, and a pending deletion request must
  // never be carried onto another account.
  const skip = new Set(['auth_sessions', 'deletion_requests']);
  const userTables = names.filter(
    (n, i) => !skip.has(n) && (infos[i].results as any[]).some((col) => col?.name === 'user_id'),
  );
  await db.batch([
    ...userTables.map((t) => db.prepare(`UPDATE OR IGNORE "${t}" SET user_id = ? WHERE user_id = ?`).bind(toId, fromId)),
    ...userTables.map((t) => db.prepare(`DELETE FROM "${t}" WHERE user_id = ?`).bind(fromId)),
  ]);
}

/** The user's old Appwrite account, found by email with a server key. */
export type LegacyAppwriteUser = { id: string; name: string; admin?: boolean };

/**
 * The account for a verified email address: the active row holding it, else
 * the user's old Appwrite account (looked up when a server key is
 * configured), else a new account.
 */
export async function findOrCreateUserByEmail(
  db: D1Database,
  opts: {
    email: string;
    name?: string;
    source: 'google' | 'email';
    lookupAppwriteId?: (email: string) => Promise<LegacyAppwriteUser | null>;
  },
): Promise<AuthUserRow> {
  const existing = await getActiveUserByEmail(db, opts.email);
  if (existing) {
    const updates: string[] = [];
    const binds: unknown[] = [];
    if (existing.email_verified !== 1) updates.push('email_verified = 1');
    if (!existing.name && opts.name) {
      updates.push('name = ?');
      binds.push(opts.name);
    }
    if (updates.length === 0) return existing;
    await db
      .prepare(`UPDATE auth_users SET ${updates.join(', ')}, updated_at = ? WHERE id = ?`)
      .bind(...binds, nowIso(), existing.id)
      .run();
    return (await getUser(db, existing.id)) || existing;
  }

  const legacy = opts.lookupAppwriteId ? await opts.lookupAppwriteId(opts.email).catch(() => null) : null;
  if (legacy) {
    const row = await getUser(db, legacy.id);
    if (!row) {
      const user = await insertUser(db, {
        id: legacy.id,
        email: opts.email,
        name: legacy.name || opts.name || '',
        emailVerified: true,
        isGuest: false,
        source: 'appwrite',
      });
      // Same as /appwrite/migrate: an Appwrite admin stays an admin.
      if (legacy.admin) await grantWorkerAdmin(db, user.id);
      return user;
    }
    // A deleted (tombstoned) old account is never revived: fall through.
  }

  return insertUser(db, {
    id: newUserId(),
    email: opts.email,
    name: opts.name || '',
    emailVerified: true,
    isGuest: false,
    source: opts.source,
  });
}

export async function issueSession(db: D1Database, secret: string, user: AuthUserRow): Promise<IssuedSession> {
  if (user.status !== 'active') throw new AuthError('ACCOUNT_DELETED', 403);
  const sessionId = randomToken(12);
  const refreshToken = `${sessionId}.${randomToken(32)}`;
  const now = new Date();
  const expires = new Date(now.getTime() + REFRESH_TOKEN_TTL_DAYS * 86_400_000);
  await db
    .prepare(
      `INSERT INTO auth_sessions (id, user_id, refresh_hash, created_at, last_used_at, expires_at, revoked_at)
       VALUES (?, ?, ?, ?, ?, ?, NULL)`,
    )
    .bind(sessionId, user.id, await sha256Hex(refreshToken), now.toISOString(), now.toISOString(), expires.toISOString())
    .run();
  return { ...(await mintAccessToken(secret, user.id, sessionId)), refreshToken, user: toPublicUser(user) };
}

async function mintAccessToken(secret: string, userId: string, sessionId: string) {
  const iat = Math.floor(Date.now() / 1000);
  const exp = iat + ACCESS_TOKEN_TTL_SECONDS;
  const accessToken = await signAccessToken(secret, { sub: userId, sid: sessionId, iat, exp });
  return { accessToken, accessTokenExpiresAt: new Date(exp * 1000).toISOString() };
}

type SessionRow = {
  id: string;
  user_id: string;
  refresh_hash: string;
  expires_at: string;
  revoked_at: string | null;
};

/**
 * New access token for a refresh token. The refresh token itself is not
 * rotated (a lost response on a flaky network must not sign the user out);
 * its expiry slides forward instead.
 */
export async function refreshSession(db: D1Database, secret: string, refreshToken: string): Promise<IssuedSession> {
  const [sessionId] = refreshToken.split('.');
  if (!sessionId) throw new AuthError('INVALID_REFRESH_TOKEN', 401);
  const session = await db.prepare('SELECT * FROM auth_sessions WHERE id = ?').bind(sessionId).first<SessionRow>();
  if (!session || session.revoked_at || session.refresh_hash !== (await sha256Hex(refreshToken))) {
    throw new AuthError('INVALID_REFRESH_TOKEN', 401);
  }
  if (new Date(session.expires_at).getTime() <= Date.now()) throw new AuthError('SESSION_EXPIRED', 401);
  const user = await getUser(db, session.user_id);
  if (!user || user.status !== 'active') throw new AuthError('INVALID_REFRESH_TOKEN', 401);

  const now = new Date();
  const expires = new Date(now.getTime() + REFRESH_TOKEN_TTL_DAYS * 86_400_000);
  await db
    .prepare('UPDATE auth_sessions SET last_used_at = ?, expires_at = ? WHERE id = ?')
    .bind(now.toISOString(), expires.toISOString(), session.id)
    .run();
  return { ...(await mintAccessToken(secret, user.id, session.id)), refreshToken, user: toPublicUser(user) };
}

export async function revokeSession(db: D1Database, sessionId: string): Promise<void> {
  await db
    .prepare('UPDATE auth_sessions SET revoked_at = ? WHERE id = ? AND revoked_at IS NULL')
    .bind(nowIso(), sessionId)
    .run();
}

/** Whether the session behind a verified access token is still live. */
export async function isSessionLive(db: D1Database, userId: string, sessionId: string): Promise<boolean> {
  const row = await db
    .prepare(
      `SELECT s.revoked_at AS revoked_at, s.expires_at AS expires_at, u.status AS status
       FROM auth_sessions s JOIN auth_users u ON u.id = s.user_id
       WHERE s.id = ? AND s.user_id = ?`,
    )
    .bind(sessionId, userId)
    .first<{ revoked_at: string | null; expires_at: string; status: string }>();
  if (!row || row.revoked_at || row.status !== 'active') return false;
  return new Date(row.expires_at).getTime() > Date.now();
}

export async function grantWorkerAdmin(db: D1Database, userId: string): Promise<void> {
  await db.prepare('INSERT OR IGNORE INTO auth_admins (user_id, created_at) VALUES (?, ?)').bind(userId, nowIso()).run();
}

export async function isWorkerAdmin(db: D1Database, userId: string, adminEmails: string | undefined): Promise<boolean> {
  const listed = await db.prepare('SELECT 1 AS ok FROM auth_admins WHERE user_id = ?').bind(userId).first();
  if (listed) return true;
  const allow = (adminEmails || '')
    .split(',')
    .map((e) => e.trim().toLowerCase())
    .filter(Boolean);
  if (allow.length === 0) return false;
  const user = await getUser(db, userId);
  return Boolean(user && user.status === 'active' && user.email && user.email_verified === 1 && allow.includes(user.email));
}

/**
 * Closes a Worker login for account deletion: every session is revoked and
 * the row becomes a tombstone with its personal fields cleared.
 */
export async function tombstoneUser(db: D1Database, userId: string): Promise<void> {
  const now = nowIso();
  await db.batch([
    db.prepare('UPDATE auth_sessions SET revoked_at = ? WHERE user_id = ? AND revoked_at IS NULL').bind(now, userId),
    db
      .prepare(
        `INSERT INTO auth_users (id, email, name, email_verified, is_guest, source, status, created_at, updated_at)
         VALUES (?, NULL, '', 0, 0, 'deleted', 'deleted', ?, ?)
         ON CONFLICT(id) DO UPDATE SET email = NULL, name = '', status = 'deleted', updated_at = excluded.updated_at`,
      )
      .bind(userId, now, now),
  ]);
}
