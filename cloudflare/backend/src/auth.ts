import type { Context, MiddlewareHandler } from 'hono';

// Identity for Worker requests comes only from an Appwrite JWT that Appwrite
// itself vouches for. Client-supplied user ids (headers, query, body) are
// never trusted.

type RateLimit = { limit(options: { key: string }): Promise<{ success: boolean }> };

export type AuthEnv = {
  APPWRITE_ENDPOINT: string;
  APPWRITE_PROJECT_ID: string;
  ADMIN_TEAM_ID?: string;
  CRON_SECRET?: string;
  AI_USER_LIMITER?: RateLimit;
  AI_IP_LIMITER?: RateLimit;
};

export type AuthVariables = {
  userId: string;
  jwt: string;
};

type AuthContext = Context<{ Bindings: AuthEnv; Variables: AuthVariables }>;

type Verification =
  | { status: 'ok'; userId: string }
  | { status: 'invalid' }
  | { status: 'unavailable' };

const VERIFY_TTL_MS = 60_000;
const MAX_CACHE_ENTRIES = 5_000;

// Per-isolate caches keyed by a hash of the JWT, so a verified token is not
// re-checked against Appwrite on every request.
const userCache = new Map<string, { userId: string; expiresAt: number }>();
const adminCache = new Map<string, { isAdmin: boolean; expiresAt: number }>();

function remember<T extends { expiresAt: number }>(cache: Map<string, T>, key: string, value: T) {
  if (cache.size >= MAX_CACHE_ENTRIES) {
    const oldest = cache.keys().next().value;
    if (oldest !== undefined) cache.delete(oldest);
  }
  cache.set(key, value);
}

async function sha256(value: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(value));
  return Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, '0')).join('');
}

export function timingSafeEqualStr(a: string, b: string): boolean {
  const enc = new TextEncoder();
  const bufA = enc.encode(a);
  const bufB = enc.encode(b);
  if (bufA.length !== bufB.length) return false;
  let diff = 0;
  for (let i = 0; i < bufA.length; i++) diff |= bufA[i] ^ bufB[i];
  return diff === 0;
}

export function extractJwt(c: AuthContext): string {
  const authHeader = c.req.header('authorization') || '';
  const match = authHeader.match(/^Bearer\s+(.+)$/i);
  if (match) return match[1].trim();
  return (c.req.header('x-appwrite-jwt') || '').trim();
}

function appwriteHeaders(env: AuthEnv, jwt: string): Record<string, string> {
  return {
    'X-Appwrite-Project': env.APPWRITE_PROJECT_ID,
    'X-Appwrite-JWT': jwt,
    Accept: 'application/json',
  };
}

export async function appwriteGet(env: AuthEnv, jwt: string, path: string): Promise<Response> {
  const endpoint = env.APPWRITE_ENDPOINT.replace(/\/+$/, '');
  return fetch(`${endpoint}${path}`, { headers: appwriteHeaders(env, jwt) });
}

async function verifyJwt(env: AuthEnv, jwt: string): Promise<Verification> {
  if (!env.APPWRITE_ENDPOINT || !env.APPWRITE_PROJECT_ID) return { status: 'unavailable' };

  const key = await sha256(jwt);
  const cached = userCache.get(key);
  if (cached && cached.expiresAt > Date.now()) return { status: 'ok', userId: cached.userId };

  let res: Response;
  try {
    res = await appwriteGet(env, jwt, '/account');
  } catch (_) {
    return { status: 'unavailable' };
  }
  if (res.status === 401 || res.status === 403) return { status: 'invalid' };
  if (!res.ok) return { status: 'unavailable' };

  const account: any = await res.json().catch(() => null);
  const userId = typeof account?.$id === 'string' ? account.$id : '';
  if (!userId) return { status: 'invalid' };

  remember(userCache, key, { userId, expiresAt: Date.now() + VERIFY_TTL_MS });
  return { status: 'ok', userId };
}

async function isAdminJwt(env: AuthEnv, jwt: string): Promise<boolean | null> {
  const key = await sha256(`admin:${jwt}`);
  const cached = adminCache.get(key);
  if (cached && cached.expiresAt > Date.now()) return cached.isAdmin;

  let res: Response;
  try {
    res = await appwriteGet(env, jwt, '/teams');
  } catch (_) {
    return null;
  }
  if (!res.ok) return res.status === 401 || res.status === 403 ? false : null;

  // Match the immutable team id only, never the team name: any user who can
  // create teams could otherwise name one "admins".
  const adminTeamId = env.ADMIN_TEAM_ID || 'admins';
  const data: any = await res.json().catch(() => null);
  const teams: any[] = Array.isArray(data?.teams) ? data.teams : [];
  const isAdmin = teams.some((t) => t?.$id === adminTeamId);

  remember(adminCache, key, { isAdmin, expiresAt: Date.now() + VERIFY_TTL_MS });
  return isAdmin;
}

function unauthenticated(c: AuthContext) {
  return c.json({ ok: false, error: 'UNAUTHENTICATED', message: 'Unauthenticated' }, 401);
}

// 503 (not 401) when Appwrite cannot be reached, so clients fall back to the
// Appwrite Functions path instead of treating the user as signed out.
function authUnavailable(c: AuthContext) {
  return c.json({ ok: false, error: 'AUTH_UNAVAILABLE', message: 'Authentication service unavailable' }, 503);
}

async function authenticate(c: AuthContext, required: boolean): Promise<Response | null> {
  const jwt = extractJwt(c);
  if (!jwt) {
    if (required) return unauthenticated(c);
    c.set('userId', '');
    c.set('jwt', '');
    return null;
  }

  const result = await verifyJwt(c.env, jwt);
  if (result.status === 'unavailable') return authUnavailable(c);
  if (result.status === 'invalid') return unauthenticated(c);

  c.set('userId', result.userId);
  c.set('jwt', jwt);
  return null;
}

/** Rejects the request unless it carries a valid Appwrite JWT. */
export const requireUser: MiddlewareHandler = async (c, next) => {
  const denied = await authenticate(c as AuthContext, true);
  if (denied) return denied;
  await next();
};

/** Anonymous requests pass with an empty userId; a bad JWT is still rejected. */
export const optionalUser: MiddlewareHandler = async (c, next) => {
  const denied = await authenticate(c as AuthContext, false);
  if (denied) return denied;
  await next();
};

/**
 * Admin team members (by Appwrite JWT), or scheduled jobs presenting
 * CRON_SECRET in `x-cron-secret`.
 */
export const requireAdmin: MiddlewareHandler = async (c, next) => {
  const ctx = c as AuthContext;
  const cronSecret = ctx.env.CRON_SECRET || '';
  const presented = ctx.req.header('x-cron-secret') || '';
  if (cronSecret && presented && timingSafeEqualStr(presented, cronSecret)) {
    ctx.set('userId', 'system:cron');
    ctx.set('jwt', '');
    await next();
    return;
  }

  const denied = await authenticate(ctx, true);
  if (denied) return denied;

  const isAdmin = await isAdminJwt(ctx.env, ctx.get('jwt'));
  if (isAdmin === null) return authUnavailable(ctx);
  if (!isAdmin) return ctx.json({ ok: false, error: 'FORBIDDEN', message: 'Admin access required' }, 403);
  await next();
};

/**
 * Per-user and per-IP limits for routes that spend money on third-party AI
 * and TTS providers. Must run after requireUser.
 */
export const aiRateLimit: MiddlewareHandler = async (c, next) => {
  const ctx = c as AuthContext;
  const ip = ctx.req.header('cf-connecting-ip') || 'unknown';
  const userId = ctx.get('userId') || 'anonymous';

  const checks: Array<Promise<{ success: boolean }>> = [];
  if (ctx.env.AI_USER_LIMITER) checks.push(ctx.env.AI_USER_LIMITER.limit({ key: `user:${userId}` }));
  if (ctx.env.AI_IP_LIMITER) checks.push(ctx.env.AI_IP_LIMITER.limit({ key: `ip:${ip}` }));

  const results = await Promise.all(checks);
  if (results.some((r) => !r.success)) {
    return ctx.json({ ok: false, success: false, error: 'RATE_LIMITED', message: 'Too many requests. Please wait a minute and try again.' }, 429);
  }
  await next();
};
