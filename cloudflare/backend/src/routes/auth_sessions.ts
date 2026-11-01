import { requireUser } from '../auth';
import type { App, Bindings } from '../env';
import { newUserId, randomDigits, randomToken, sha256Hex, signState, verifyState } from '../lib/worker_tokens';
import {
  AuthError,
  findOrCreateUserByEmail,
  getActiveUserByEmail,
  getUser,
  insertUser,
  issueSession,
  mergeUserData,
  normalizeEmail,
  refreshSession,
  revokeSession,
  toPublicUser,
  type AuthUserRow,
} from '../lib/worker_users';

// Worker-owned sign-in: guest, email code, Google OAuth, and a one-time
// migration of an existing Appwrite session. Every route answers with the
// same session envelope (see issueSession) so the app has one code path.
//
// Replaces Appwrite Auth for the app after the Appwrite org went read-only
// (every Appwrite write, including session creation, returns 402).

const EMAIL_CODE_TTL_MS = 15 * 60_000;
const EMAIL_RESEND_GAP_MS = 45_000;
const EMAIL_SENDS_PER_WINDOW = 5;
const EMAIL_WINDOW_MS = 60 * 60_000;
const EMAIL_MAX_ATTEMPTS = 5;
const LOGIN_CODE_TTL_MS = 2 * 60_000;
const OAUTH_STATE_TTL_MS = 10 * 60_000;
const MAX_PREFS_BYTES = 64 * 1024;
const MAX_NAME_LENGTH = 128;

type OAuthState = { p: 'android' | 'web'; r: string; e: number; n: string };

const nowIso = () => new Date().toISOString();

function secretOf(env: Bindings): string {
  const secret = env.AUTH_SECRET || '';
  if (secret.length < 32) throw new AuthError('AUTH_NOT_CONFIGURED', 503);
  return secret;
}

function fail(c: any, err: unknown) {
  if (err instanceof AuthError) {
    return c.json({ ok: false, error: err.code, message: messageFor(err.code) }, err.status);
  }
  console.error('auth route failed', err instanceof Error ? err.message : String(err));
  return c.json({ ok: false, error: 'AUTH_FAILED', message: messageFor('AUTH_FAILED') }, 500);
}

function messageFor(code: string): string {
  switch (code) {
    case 'INVALID_EMAIL':
      return 'Please enter a valid email address.';
    case 'INVALID_CODE':
      return 'That code is not right. Please check it and try again.';
    case 'CODE_EXPIRED':
      return 'That code has expired. Please ask for a new one.';
    case 'TOO_MANY_ATTEMPTS':
      return 'Too many wrong codes. Please ask for a new one.';
    case 'RATE_LIMITED':
      return 'Please wait a minute and try again.';
    case 'EMAIL_UNAVAILABLE':
      return 'Email sign-in is not available right now. Please continue with Google.';
    case 'GOOGLE_UNAVAILABLE':
      return 'Google sign-in is not available right now. Please use email.';
    case 'ACCOUNT_DELETED':
      return 'This account was deleted.';
    case 'INVALID_REFRESH_TOKEN':
    case 'SESSION_EXPIRED':
    case 'INVALID_LOGIN_CODE':
    case 'INVALID_APPWRITE_SESSION':
      return 'Your session has ended. Please sign in again.';
    case 'AUTH_NOT_CONFIGURED':
      return 'Sign-in is being set up. Please try again soon.';
    default:
      return 'Sign-in failed. Please try again.';
  }
}

async function readJson(c: any): Promise<any> {
  return c.req.json().catch(() => ({}));
}

async function limitByIp(c: any, scope: string): Promise<void> {
  const limiter = (c.env as Bindings).AUTH_LIMITER;
  if (!limiter) return;
  const ip = c.req.header('cf-connecting-ip') || 'unknown';
  const { success } = await limiter.limit({ key: `${scope}:${ip}` });
  if (!success) throw new AuthError('RATE_LIMITED', 429);
}

// ─── Email code ──────────────────────────────────────────────────────────

type EmailCodeRow = {
  email: string;
  code_hash: string;
  attempts: number;
  sends: number;
  window_started_at: string;
  last_sent_at: string;
  expires_at: string;
};

const codeHash = (secret: string, email: string, code: string) => sha256Hex(`email-code:${email}:${code}:${secret}`);

function emailBody(code: string) {
  const text = [
    `Your Olitun sign-in code is ${code}`,
    '',
    'Enter this code in the Olitun app to sign in. It expires in 15 minutes.',
    'If you did not ask for this code, you can ignore this email.',
  ].join('\n');
  const html = `<!doctype html><html><body style="font-family:Arial,Helvetica,sans-serif;background:#f6f7f9;padding:24px;color:#111">
<div style="max-width:420px;margin:0 auto;background:#fff;border-radius:16px;padding:28px">
<p style="margin:0 0 8px;font-size:15px">Your Olitun sign-in code</p>
<p style="margin:0 0 16px;font-size:34px;font-weight:700;letter-spacing:6px">${code}</p>
<p style="margin:0 0 8px;font-size:14px;color:#444">Enter this code in the Olitun app to sign in. It expires in 15 minutes.</p>
<p style="margin:0;font-size:12px;color:#888">If you did not ask for this code, you can ignore this email.</p>
</div></body></html>`;
  return { text, html };
}

async function sendEmailCode(env: Bindings, email: string): Promise<void> {
  const secret = secretOf(env);
  if (!env.EMAIL) throw new AuthError('EMAIL_UNAVAILABLE', 503);

  const now = Date.now();
  const existing = await env.DB.prepare('SELECT * FROM auth_email_codes WHERE email = ?').bind(email).first<EmailCodeRow>();
  let sends = 1;
  let windowStart = new Date(now).toISOString();
  if (existing) {
    if (now - new Date(existing.last_sent_at).getTime() < EMAIL_RESEND_GAP_MS) throw new AuthError('RATE_LIMITED', 429);
    const inWindow = now - new Date(existing.window_started_at).getTime() < EMAIL_WINDOW_MS;
    if (inWindow) {
      if (existing.sends >= EMAIL_SENDS_PER_WINDOW) throw new AuthError('RATE_LIMITED', 429);
      sends = existing.sends + 1;
      windowStart = existing.window_started_at;
    }
  }

  const code = randomDigits(6);
  const { text, html } = emailBody(code);
  try {
    await env.EMAIL.send({
      from: { email: env.AUTH_EMAIL_FROM || 'no-reply@olitun.in', name: 'Olitun' },
      to: email,
      subject: `${code} is your Olitun sign-in code`,
      text,
      html,
    });
  } catch (err) {
    console.error('email code send failed', err instanceof Error ? err.message : String(err));
    throw new AuthError('EMAIL_UNAVAILABLE', 503);
  }

  const sentAt = new Date(now).toISOString();
  await env.DB.prepare(
    `INSERT INTO auth_email_codes (email, code_hash, attempts, sends, window_started_at, last_sent_at, expires_at)
     VALUES (?, ?, 0, ?, ?, ?, ?)
     ON CONFLICT(email) DO UPDATE SET code_hash = excluded.code_hash, attempts = 0, sends = excluded.sends,
       window_started_at = excluded.window_started_at, last_sent_at = excluded.last_sent_at, expires_at = excluded.expires_at`,
  )
    .bind(email, await codeHash(secret, email, code), sends, windowStart, sentAt, new Date(now + EMAIL_CODE_TTL_MS).toISOString())
    .run();
}

async function verifyEmailCode(env: Bindings, email: string, code: string): Promise<void> {
  const secret = secretOf(env);
  const row = await env.DB.prepare('SELECT * FROM auth_email_codes WHERE email = ?').bind(email).first<EmailCodeRow>();
  if (!row) throw new AuthError('CODE_EXPIRED', 400);
  if (new Date(row.expires_at).getTime() <= Date.now()) {
    await env.DB.prepare('DELETE FROM auth_email_codes WHERE email = ?').bind(email).run();
    throw new AuthError('CODE_EXPIRED', 400);
  }
  if (row.attempts >= EMAIL_MAX_ATTEMPTS) throw new AuthError('TOO_MANY_ATTEMPTS', 429);
  if (row.code_hash !== (await codeHash(secret, email, code))) {
    await env.DB.prepare('UPDATE auth_email_codes SET attempts = attempts + 1 WHERE email = ?').bind(email).run();
    throw new AuthError(row.attempts + 1 >= EMAIL_MAX_ATTEMPTS ? 'TOO_MANY_ATTEMPTS' : 'INVALID_CODE', 400);
  }
  await env.DB.prepare('DELETE FROM auth_email_codes WHERE email = ?').bind(email).run();
}

// ─── Appwrite lookups (reads still work while the org is read-only) ──────

function appwriteBase(env: Bindings): string {
  return (env.APPWRITE_ENDPOINT || '').replace(/\/+$/, '');
}

/** The user's old Appwrite id for an email; needs a users.read server key. */
async function lookupAppwriteUser(env: Bindings, email: string): Promise<{ id: string; name: string } | null> {
  if (!env.APPWRITE_API_KEY || !env.APPWRITE_ENDPOINT || !env.APPWRITE_PROJECT_ID) return null;
  const query = JSON.stringify({ method: 'equal', attribute: 'email', values: [email] });
  const res = await fetch(`${appwriteBase(env)}/users?queries[]=${encodeURIComponent(query)}`, {
    headers: {
      'X-Appwrite-Project': env.APPWRITE_PROJECT_ID,
      'X-Appwrite-Key': env.APPWRITE_API_KEY,
      Accept: 'application/json',
    },
  });
  if (!res.ok) return null;
  const data: any = await res.json().catch(() => null);
  const user = Array.isArray(data?.users) ? data.users.find((u: any) => normalizeEmail(u?.email) === email) : null;
  return user && typeof user.$id === 'string' ? { id: user.$id, name: String(user.name || '') } : null;
}

function appwriteSessionHeaders(env: Bindings, credential: { session?: string; jwt?: string }): Record<string, string> {
  const headers: Record<string, string> = {
    'X-Appwrite-Project': env.APPWRITE_PROJECT_ID,
    Accept: 'application/json',
  };
  if (credential.jwt) headers['X-Appwrite-JWT'] = credential.jwt;
  if (credential.session) {
    const name = `a_session_${env.APPWRITE_PROJECT_ID}`;
    headers.Cookie = `${name}=${credential.session}; ${name}_legacy=${credential.session}`;
    headers['X-Fallback-Cookies'] = JSON.stringify({ [name]: credential.session });
  }
  return headers;
}

async function appwriteRead(env: Bindings, headers: Record<string, string>, path: string): Promise<Response> {
  return fetch(`${appwriteBase(env)}${path}`, { headers });
}

// ─── Google OAuth ────────────────────────────────────────────────────────

function allowedWebReturn(env: Bindings, value: string): string | null {
  let url: URL;
  try {
    url = new URL(value);
  } catch (_) {
    return null;
  }
  const origins = (env.AUTH_WEB_ORIGINS || 'https://olitun.in,https://www.olitun.in')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);
  const local = url.protocol === 'http:' && (url.hostname === 'localhost' || url.hostname === '127.0.0.1');
  return origins.includes(url.origin) || local ? url.toString() : null;
}

function appCallbackScheme(env: Bindings): string {
  return env.APP_CALLBACK_SCHEME || `appwrite-callback-${env.APPWRITE_PROJECT_ID}`;
}

function callbackTarget(env: Bindings, state: OAuthState | null, params: Record<string, string>): string {
  if (state?.p === 'web') {
    const url = new URL(state.r);
    for (const [k, v] of Object.entries(params)) url.searchParams.set(k, v);
    return url.toString();
  }
  const query = new URLSearchParams(params).toString();
  return `${appCallbackScheme(env)}://auth?${query}`;
}

function googleRedirectUri(c: any): string {
  const env = c.env as Bindings;
  const origin = env.AUTH_PUBLIC_ORIGIN || new URL(c.req.url).origin;
  return `${origin.replace(/\/+$/, '')}/api/v1/auth/google/callback`;
}

function decodeJwtPayload(token: string): any {
  const [, payload] = token.split('.');
  if (!payload) return null;
  try {
    const json = atob(payload.replace(/-/g, '+').replace(/_/g, '/').padEnd(Math.ceil(payload.length / 4) * 4, '='));
    return JSON.parse(new TextDecoder().decode(Uint8Array.from(json, (ch) => ch.charCodeAt(0))));
  } catch (_) {
    return null;
  }
}

/** Verified Google identity for an authorization code. */
async function exchangeGoogleCode(c: any, code: string): Promise<{ email: string; name: string }> {
  const env = c.env as Bindings;
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded', Accept: 'application/json' },
    body: new URLSearchParams({
      code,
      client_id: env.GOOGLE_CLIENT_ID || '',
      client_secret: env.GOOGLE_CLIENT_SECRET || '',
      redirect_uri: googleRedirectUri(c),
      grant_type: 'authorization_code',
    }).toString(),
  });
  if (!res.ok) throw new AuthError('GOOGLE_EXCHANGE_FAILED', 502);
  const data: any = await res.json().catch(() => null);
  // The id_token came straight from Google's token endpoint over TLS, so
  // its claims are trusted without a signature check (OIDC Core 3.1.3.7);
  // issuer, audience and expiry are still checked.
  const claims = decodeJwtPayload(String(data?.id_token || ''));
  const issOk = claims?.iss === 'https://accounts.google.com' || claims?.iss === 'accounts.google.com';
  const audOk = claims?.aud === env.GOOGLE_CLIENT_ID;
  const fresh = typeof claims?.exp === 'number' && claims.exp * 1000 > Date.now();
  const email = normalizeEmail(claims?.email);
  if (!issOk || !audOk || !fresh || !email || claims?.email_verified !== true) {
    throw new AuthError('GOOGLE_EXCHANGE_FAILED', 502);
  }
  return { email, name: typeof claims?.name === 'string' ? claims.name.slice(0, MAX_NAME_LENGTH) : '' };
}

// ─── Routes ──────────────────────────────────────────────────────────────

export function registerAuthSessionRoutes(app: App): void {
  // Which sign-in methods this deployment can serve, so the app can hide
  // the ones that are not set up yet.
  app.get('/api/v1/auth/config', (c) => {
    const env = c.env;
    const ready = (env.AUTH_SECRET || '').length >= 32;
    return c.json({
      ok: true,
      enabled: ready,
      guest: ready,
      email: ready && Boolean(env.EMAIL) && env.AUTH_EMAIL_ENABLED !== 'false',
      google: ready && Boolean(env.GOOGLE_CLIENT_ID && env.GOOGLE_CLIENT_SECRET),
    });
  });

  app.post('/api/v1/auth/guest', async (c) => {
    try {
      const secret = secretOf(c.env);
      await limitByIp(c, 'guest');
      const user = await insertUser(c.env.DB, {
        id: newUserId(),
        email: null,
        name: '',
        emailVerified: false,
        isGuest: true,
        source: 'guest',
      });
      return c.json({ ok: true, ...(await issueSession(c.env.DB, secret, user)) });
    } catch (err) {
      return fail(c, err);
    }
  });

  app.post('/api/v1/auth/email/start', async (c) => {
    try {
      secretOf(c.env);
      await limitByIp(c, 'email');
      const body = await readJson(c);
      const email = normalizeEmail(body?.email);
      if (!email) throw new AuthError('INVALID_EMAIL', 400);
      if (c.env.AUTH_EMAIL_ENABLED === 'false') throw new AuthError('EMAIL_UNAVAILABLE', 503);
      await sendEmailCode(c.env, email);
      return c.json({ ok: true, email });
    } catch (err) {
      return fail(c, err);
    }
  });

  app.post('/api/v1/auth/email/verify', async (c) => {
    try {
      const secret = secretOf(c.env);
      await limitByIp(c, 'verify');
      const body = await readJson(c);
      const email = normalizeEmail(body?.email);
      const code = typeof body?.code === 'string' ? body.code.replace(/\s+/g, '') : '';
      if (!email) throw new AuthError('INVALID_EMAIL', 400);
      if (!/^\d{6}$/.test(code)) throw new AuthError('INVALID_CODE', 400);
      await verifyEmailCode(c.env, email, code);
      const user = await findOrCreateUserByEmail(c.env.DB, {
        email,
        source: 'email',
        lookupAppwriteId: (e) => lookupAppwriteUser(c.env, e),
      });
      return c.json({ ok: true, ...(await issueSession(c.env.DB, secret, user)) });
    } catch (err) {
      return fail(c, err);
    }
  });

  app.get('/api/v1/auth/google/start', async (c) => {
    const env = c.env;
    const platform = c.req.query('platform') === 'web' ? 'web' : 'android';
    const ret = platform === 'web' ? allowedWebReturn(env, c.req.query('return') || '') : '';
    if (platform === 'web' && !ret) return c.json({ ok: false, error: 'INVALID_RETURN_URL' }, 400);
    let secret: string;
    try {
      secret = secretOf(env);
    } catch (_) {
      return c.redirect(callbackTarget(env, { p: platform, r: ret || '', e: 0, n: '' }, { error: 'AUTH_NOT_CONFIGURED' }));
    }
    if (!env.GOOGLE_CLIENT_ID || !env.GOOGLE_CLIENT_SECRET) {
      return c.redirect(callbackTarget(env, { p: platform, r: ret || '', e: 0, n: '' }, { error: 'GOOGLE_UNAVAILABLE' }));
    }
    const state = await signState(secret, { p: platform, r: ret || '', e: Date.now() + OAUTH_STATE_TTL_MS, n: randomToken(12) });
    const url = new URL('https://accounts.google.com/o/oauth2/v2/auth');
    url.searchParams.set('client_id', env.GOOGLE_CLIENT_ID);
    url.searchParams.set('redirect_uri', googleRedirectUri(c));
    url.searchParams.set('response_type', 'code');
    url.searchParams.set('scope', 'openid email profile');
    url.searchParams.set('state', state);
    url.searchParams.set('prompt', 'select_account');
    return c.redirect(url.toString());
  });

  app.get('/api/v1/auth/google/callback', async (c) => {
    const env = c.env;
    let state: OAuthState | null = null;
    try {
      const secret = secretOf(env);
      state = await verifyState<OAuthState>(secret, c.req.query('state') || '');
      if (!state || typeof state.e !== 'number' || state.e < Date.now()) {
        state = state && state.p ? state : null;
        throw new AuthError('OAUTH_STATE_INVALID', 400);
      }
      if (c.req.query('error')) throw new AuthError('GOOGLE_CANCELLED', 400);
      const code = c.req.query('code') || '';
      if (!code) throw new AuthError('GOOGLE_EXCHANGE_FAILED', 400);
      const identity = await exchangeGoogleCode(c, code);
      const user = await findOrCreateUserByEmail(env.DB, {
        email: identity.email,
        name: identity.name,
        source: 'google',
        lookupAppwriteId: (e) => lookupAppwriteUser(env, e),
      });
      if (user.status !== 'active') throw new AuthError('ACCOUNT_DELETED', 403);
      const loginCode = randomToken(32);
      await env.DB.prepare('INSERT INTO auth_login_codes (code_hash, user_id, expires_at) VALUES (?, ?, ?)')
        .bind(await sha256Hex(loginCode), user.id, new Date(Date.now() + LOGIN_CODE_TTL_MS).toISOString())
        .run();
      return c.redirect(callbackTarget(env, state, { olitun_code: loginCode }));
    } catch (err) {
      const code = err instanceof AuthError ? err.code : 'AUTH_FAILED';
      if (!(err instanceof AuthError)) console.error('google callback failed', err instanceof Error ? err.message : String(err));
      return c.redirect(callbackTarget(env, state, { error: code }));
    }
  });

  app.post('/api/v1/auth/exchange', async (c) => {
    try {
      const secret = secretOf(c.env);
      await limitByIp(c, 'exchange');
      const body = await readJson(c);
      const code = typeof body?.code === 'string' ? body.code : '';
      if (!code) throw new AuthError('INVALID_LOGIN_CODE', 400);
      const hash = await sha256Hex(code);
      // Single use: the delete decides which request wins.
      const row = await c.env.DB.prepare('DELETE FROM auth_login_codes WHERE code_hash = ? RETURNING user_id, expires_at')
        .bind(hash)
        .first<{ user_id: string; expires_at: string }>();
      if (!row || new Date(row.expires_at).getTime() <= Date.now()) throw new AuthError('INVALID_LOGIN_CODE', 401);
      const user = await getUser(c.env.DB, row.user_id);
      if (!user) throw new AuthError('INVALID_LOGIN_CODE', 401);
      return c.json({ ok: true, ...(await issueSession(c.env.DB, secret, user)) });
    } catch (err) {
      return fail(c, err);
    }
  });

  // One-time move of a device that is still signed in to Appwrite. The
  // Appwrite session is checked with a read (allowed in read-only mode), so
  // the user keeps their Appwrite $id and all data stored under it.
  app.post('/api/v1/auth/appwrite/migrate', async (c) => {
    try {
      const secret = secretOf(c.env);
      await limitByIp(c, 'migrate');
      const body = await readJson(c);
      const session = typeof body?.session === 'string' ? body.session.trim() : '';
      const jwt = typeof body?.jwt === 'string' ? body.jwt.trim() : '';
      if ((!session && !jwt) || session.length > 4096 || jwt.length > 4096) {
        throw new AuthError('INVALID_APPWRITE_SESSION', 400);
      }
      if (!c.env.APPWRITE_ENDPOINT || !c.env.APPWRITE_PROJECT_ID) throw new AuthError('AUTH_NOT_CONFIGURED', 503);

      const headers = appwriteSessionHeaders(c.env, { session, jwt });
      let res: Response;
      try {
        res = await appwriteRead(c.env, headers, '/account');
      } catch (_) {
        throw new AuthError('APPWRITE_UNAVAILABLE', 503);
      }
      if (res.status === 401 || res.status === 403) throw new AuthError('INVALID_APPWRITE_SESSION', 401);
      if (!res.ok) throw new AuthError('APPWRITE_UNAVAILABLE', 503);
      const account: any = await res.json().catch(() => null);
      const appwriteId = typeof account?.$id === 'string' ? account.$id : '';
      if (!appwriteId) throw new AuthError('INVALID_APPWRITE_SESSION', 401);
      if (account?.status === false) throw new AuthError('ACCOUNT_DELETED', 403);

      const db = c.env.DB;
      let user = await getUser(db, appwriteId);
      if (user && user.status !== 'active') throw new AuthError('ACCOUNT_DELETED', 403);
      if (!user) {
        const email = normalizeEmail(account?.email);
        if (email) {
          // The same person may already have signed in fresh on another
          // device. The Appwrite id holds their history, so it wins: the
          // newer account's rows move over and it gives up the email.
          const other = await getActiveUserByEmail(db, email);
          if (other && other.id !== appwriteId) {
            await mergeUserData(db, other.id, appwriteId);
            await db.prepare("UPDATE auth_users SET email = NULL, status = 'merged', updated_at = ? WHERE id = ?")
              .bind(nowIso(), other.id)
              .run();
          }
        }
        user = await insertUser(db, {
          id: appwriteId,
          email,
          name: typeof account?.name === 'string' ? account.name.slice(0, MAX_NAME_LENGTH) : '',
          emailVerified: account?.emailVerification === true || Boolean(email),
          isGuest: !email,
          source: 'appwrite',
        });
      }

      await copyAppwritePrefs(c.env, headers, appwriteId);
      await copyAppwriteAdmin(c.env, headers, appwriteId);
      return c.json({ ok: true, migrated: true, ...(await issueSession(db, secret, user as AuthUserRow)) });
    } catch (err) {
      return fail(c, err);
    }
  });

  app.post('/api/v1/auth/refresh', async (c) => {
    try {
      const secret = secretOf(c.env);
      const body = await readJson(c);
      const token = typeof body?.refreshToken === 'string' ? body.refreshToken : '';
      if (!token) throw new AuthError('INVALID_REFRESH_TOKEN', 401);
      return c.json({ ok: true, ...(await refreshSession(c.env.DB, secret, token)) });
    } catch (err) {
      return fail(c, err);
    }
  });

  app.post('/api/v1/auth/logout', async (c) => {
    try {
      const body = await readJson(c);
      const token = typeof body?.refreshToken === 'string' ? body.refreshToken : '';
      const [sessionId] = token.split('.');
      if (sessionId) {
        const row = await c.env.DB.prepare('SELECT refresh_hash FROM auth_sessions WHERE id = ?')
          .bind(sessionId)
          .first<{ refresh_hash: string }>();
        if (row && row.refresh_hash === (await sha256Hex(token))) await revokeSession(c.env.DB, sessionId);
      }
      return c.json({ ok: true });
    } catch (err) {
      return fail(c, err);
    }
  });

  app.get('/api/v1/auth/me', requireUser, async (c) => {
    const user = await getUser(c.env.DB, c.get('userId'));
    if (!user || user.status !== 'active') return c.json({ ok: false, error: 'UNAUTHENTICATED' }, 401);
    return c.json({ ok: true, user: toPublicUser(user) });
  });

  app.patch('/api/v1/auth/me', requireUser, async (c) => {
    const body = await readJson(c);
    const name = typeof body?.name === 'string' ? body.name.trim() : null;
    if (name === null || name.length > MAX_NAME_LENGTH) {
      return c.json({ ok: false, error: 'INVALID_NAME', message: 'Please enter a shorter name.' }, 400);
    }
    const userId = c.get('userId');
    await c.env.DB.prepare("UPDATE auth_users SET name = ?, updated_at = ? WHERE id = ? AND status = 'active'")
      .bind(name, nowIso(), userId)
      .run();
    const user = await getUser(c.env.DB, userId);
    if (!user || user.status !== 'active') return c.json({ ok: false, error: 'UNAUTHENTICATED' }, 401);
    return c.json({ ok: true, user: toPublicUser(user) });
  });

  app.get('/api/v1/auth/prefs', requireUser, async (c) => {
    const row = await c.env.DB.prepare('SELECT prefs, updated_at FROM user_prefs WHERE user_id = ?')
      .bind(c.get('userId'))
      .first<{ prefs: string; updated_at: string }>();
    let prefs: Record<string, unknown> = {};
    try {
      prefs = row ? JSON.parse(row.prefs) : {};
    } catch (_) {
      prefs = {};
    }
    return c.json({ ok: true, prefs, updatedAt: row?.updated_at || null });
  });

  app.put('/api/v1/auth/prefs', requireUser, async (c) => {
    const body = await readJson(c);
    const prefs = body?.prefs;
    if (!prefs || typeof prefs !== 'object' || Array.isArray(prefs)) {
      return c.json({ ok: false, error: 'INVALID_PREFS' }, 400);
    }
    const json = JSON.stringify(prefs);
    if (new TextEncoder().encode(json).length > MAX_PREFS_BYTES) {
      return c.json({ ok: false, error: 'PREFS_TOO_LARGE' }, 413);
    }
    const now = nowIso();
    await c.env.DB.prepare(
      `INSERT INTO user_prefs (user_id, prefs, updated_at) VALUES (?, ?, ?)
       ON CONFLICT(user_id) DO UPDATE SET prefs = excluded.prefs, updated_at = excluded.updated_at`,
    )
      .bind(c.get('userId'), json, now)
      .run();
    return c.json({ ok: true, prefs, updatedAt: now });
  });
}

/** Copies Appwrite account prefs once, when D1 has none for the user yet. */
async function copyAppwritePrefs(env: Bindings, headers: Record<string, string>, userId: string): Promise<void> {
  try {
    const has = await env.DB.prepare('SELECT 1 AS ok FROM user_prefs WHERE user_id = ?').bind(userId).first();
    if (has) return;
    const res = await appwriteRead(env, headers, '/account/prefs');
    if (!res.ok) return;
    const prefs: any = await res.json().catch(() => null);
    if (!prefs || typeof prefs !== 'object' || Array.isArray(prefs)) return;
    const json = JSON.stringify(prefs);
    if (new TextEncoder().encode(json).length > MAX_PREFS_BYTES) return;
    await env.DB.prepare('INSERT OR IGNORE INTO user_prefs (user_id, prefs, updated_at) VALUES (?, ?, ?)')
      .bind(userId, json, nowIso())
      .run();
  } catch (err) {
    console.error('appwrite prefs copy failed', err instanceof Error ? err.message : String(err));
  }
}

/** Members of the Appwrite admins team stay admins on Worker sessions. */
async function copyAppwriteAdmin(env: Bindings, headers: Record<string, string>, userId: string): Promise<void> {
  try {
    const res = await appwriteRead(env, headers, '/teams');
    if (!res.ok) return;
    const data: any = await res.json().catch(() => null);
    const teams: any[] = Array.isArray(data?.teams) ? data.teams : [];
    const adminTeamId = env.ADMIN_TEAM_ID || 'admins';
    if (!teams.some((t) => t?.$id === adminTeamId)) return;
    await env.DB.prepare('INSERT OR IGNORE INTO auth_admins (user_id, created_at) VALUES (?, ?)')
      .bind(userId, nowIso())
      .run();
  } catch (err) {
    console.error('appwrite admin copy failed', err instanceof Error ? err.message : String(err));
  }
}
