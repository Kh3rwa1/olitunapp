import { createExecutionContext, waitOnExecutionContext } from 'cloudflare:test';
import { env } from 'cloudflare:workers';
import app from '../src/index';

export { env };

export const ORIGIN = 'https://api.olitun.test';

// ---------------------------------------------------------------------------
// Fake identities. Each test creates its own users so tests never share rows
// (and never share the auth module's per-isolate verification cache).
// ---------------------------------------------------------------------------

type FakeUser = { id: string; jwt: string; teams: Array<{ $id: string; name: string }> };
const usersByJwt = new Map<string, FakeUser>();

export function makeUser(kind: 'learner' | 'admin' | 'fake-admin' = 'learner'): FakeUser {
  const id = `${kind === 'learner' ? 'u' : 'a'}_${crypto.randomUUID().replace(/-/g, '').slice(0, 12)}`;
  const teams =
    kind === 'admin'
      ? [{ $id: 'admins', name: 'Admins' }]
      : kind === 'fake-admin'
        ? [{ $id: 'team_self_made', name: 'admins' }]
        : [];
  const user = { id, jwt: `jwt.${id}.${crypto.randomUUID()}`, teams };
  usersByJwt.set(user.jwt, user);
  return user;
}

// ---------------------------------------------------------------------------
// Outbound fetch mock for Appwrite, Razorpay and Bodhan. Anything else fails
// the request loudly so a test can never reach the real internet.
// ---------------------------------------------------------------------------

export type OutboundCall = { method: string; url: string; headers: Headers; body: string };

export type RazorpayPayment = { id: string; order_id: string; amount: number; currency: string; status: string };

export const outbound = {
  calls: [] as OutboundCall[],
  appwriteDown: false,
  razorpayPayments: new Map<string, RazorpayPayment>(),
  razorpayOrderCounter: 0,
  // Bodhan reply per API key; default is a valid WAV-sized body.
  bodhan: (_key: string): Response => new Response(new Uint8Array(512), { status: 200 }),
  // Appwrite DELETE /users/:id reply (server-key hard delete).
  deleteUser: (): Response => new Response(null, { status: 204 }),
  reset() {
    this.calls = [];
    this.appwriteDown = false;
    this.razorpayPayments = new Map();
    this.bodhan = () => new Response(new Uint8Array(512), { status: 200 });
    this.deleteUser = () => new Response(null, { status: 204 });
  },
  callsTo(fragment: string): OutboundCall[] {
    return this.calls.filter((c) => c.url.includes(fragment));
  },
};

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), { status, headers: { 'content-type': 'application/json' } });

async function route(call: OutboundCall): Promise<Response> {
  const url = new URL(call.url);

  if (url.host === 'appwrite.test') {
    if (outbound.appwriteDown) throw new TypeError('network error');
    const jwt = call.headers.get('x-appwrite-jwt') || '';
    const user = usersByJwt.get(jwt);
    const path = url.pathname.replace(/^\/v1/, '');
    if (path === '/account' && call.method === 'GET') {
      return user ? json({ $id: user.id, name: 'Test Learner' }) : json({ type: 'user_jwt_invalid' }, 401);
    }
    if (path === '/teams' && call.method === 'GET') {
      return user ? json({ total: user.teams.length, teams: user.teams }) : json({ type: 'user_jwt_invalid' }, 401);
    }
    if (path === '/account/status' && call.method === 'PATCH') {
      return user ? json({ $id: user.id, status: false }) : json({ type: 'user_jwt_invalid' }, 401);
    }
    if (path.startsWith('/users/') && call.method === 'DELETE') {
      return outbound.deleteUser();
    }
  }

  if (url.host === 'razorpay.test') {
    if (url.pathname === '/v1/orders' && call.method === 'POST') {
      const body = JSON.parse(call.body || '{}');
      outbound.razorpayOrderCounter += 1;
      return json({
        id: `order_${Date.now().toString(36)}${outbound.razorpayOrderCounter}`,
        amount: body.amount,
        currency: body.currency,
        receipt: body.receipt,
        status: 'created',
      });
    }
    const pay = url.pathname.match(/^\/v1\/payments\/([^/]+)$/);
    if (pay && call.method === 'GET') {
      const payment = outbound.razorpayPayments.get(decodeURIComponent(pay[1]));
      return payment ? json(payment) : json({ error: { code: 'BAD_REQUEST_ERROR' } }, 400);
    }
  }

  if (url.host === 'bodhan.test' && url.pathname === '/v1/audio/speech') {
    const key = (call.headers.get('authorization') || '').replace(/^Bearer\s+/i, '');
    return outbound.bodhan(key);
  }

  throw new Error(`Unmocked outbound fetch: ${call.method} ${call.url}`);
}

// A plain function rather than vi.spyOn: the spy re-observes rejected
// promises (simulated network failures) and reports them as unhandled.
const realFetch = globalThis.fetch;

export function restoreFetch() {
  globalThis.fetch = realFetch;
}

export function installFetchMock() {
  outbound.reset();
  globalThis.fetch = (async (input: any, init?: any) => {
    const request = new Request(input, init);
    const call: OutboundCall = {
      method: request.method,
      url: request.url,
      headers: request.headers,
      body: request.method === 'GET' || request.method === 'HEAD' ? '' : await request.clone().text(),
    };
    outbound.calls.push(call);
    return await route(call);
  }) as typeof fetch;
}

// ---------------------------------------------------------------------------
// Requests straight into the Hono app with the test bindings.
// ---------------------------------------------------------------------------

type CallInit = Omit<RequestInit, 'body'> & {
  as?: { jwt: string } | null;
  json?: unknown;
  body?: BodyInit | null;
  env?: Partial<Cloudflare.Env> & Record<string, unknown>;
};

export async function call(path: string, init: CallInit = {}): Promise<Response> {
  const { as, json: jsonBody, env: overrides, ...rest } = init;
  const headers = new Headers(rest.headers);
  if (as) headers.set('Authorization', `Bearer ${as.jwt}`);
  let body = rest.body;
  if (jsonBody !== undefined) {
    body = JSON.stringify(jsonBody);
    if (!headers.has('content-type')) headers.set('content-type', 'application/json');
  }
  const method = rest.method || (body !== undefined && body !== null ? 'POST' : 'GET');
  const request = new Request(`${ORIGIN}${path}`, { ...rest, method, headers, body });
  const ctx = createExecutionContext();
  const res = await app.fetch(request, { ...env, ...(overrides || {}) } as any, ctx);
  await waitOnExecutionContext(ctx);
  return res;
}

export async function callJson<T = any>(path: string, init: CallInit = {}): Promise<{ status: number; body: T; res: Response }> {
  const res = await call(path, init);
  const text = await res.text();
  let body: any = text;
  try {
    body = JSON.parse(text);
  } catch (_) {}
  return { status: res.status, body, res };
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

export const uid = (prefix: string) => `${prefix}_${crypto.randomUUID().replace(/-/g, '').slice(0, 10)}`;

export async function hmacHex(secret: string, payload: string): Promise<string> {
  const key = await crypto.subtle.importKey('raw', new TextEncoder().encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(payload));
  return Array.from(new Uint8Array(sig)).map((b) => b.toString(16).padStart(2, '0')).join('');
}

export async function insertCategory(opts: { id?: string; unlockMode?: 'free' | 'paid'; priceInr?: number | null; isActive?: boolean } = {}) {
  const id = opts.id || uid('cat');
  const unlockMode = opts.unlockMode || 'free';
  const raw: Record<string, unknown> = { id, titleLatin: `Category ${id}`, unlockMode, isActive: opts.isActive !== false };
  if (opts.priceInr !== undefined && opts.priceInr !== null) raw.priceInr = opts.priceInr;
  await env.DB.prepare(
    'INSERT INTO categories (id, title_ol_chiki, title_latin, icon_name, gradient_preset, order_index, is_active, unlock_mode, raw_json) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
  ).bind(id, '', raw.titleLatin, '', '', 0, opts.isActive === false ? 0 : 1, unlockMode, JSON.stringify(raw)).run();
  return id;
}

export async function insertLesson(categoryId: string, doc: Record<string, unknown> = {}) {
  const id = (doc.id as string) || uid('lesson');
  const raw = { id, categoryId, titleLatin: `Lesson ${id}`, blocks: [{ type: 'text', text: 'secret paid body' }], ...doc };
  await env.DB.prepare(
    'INSERT INTO lessons (id, category_id, title_ol_chiki, title_latin, lesson_type, order_index, raw_json) VALUES (?, ?, ?, ?, ?, ?, ?)'
  ).bind(id, categoryId, '', raw.titleLatin, 'reading', 0, JSON.stringify(raw)).run();
  return id;
}

export async function grantPurchase(userId: string, categoryId: string, status = 'completed') {
  await env.DB.prepare(
    'INSERT INTO course_purchases (id, user_id, category_id, course_id, amount_in_cents, currency, status, order_id, payment_id, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
  ).bind(uid('purch'), userId, categoryId, categoryId, 19900, 'INR', status, uid('order'), uid('pay'), new Date().toISOString()).run();
}
