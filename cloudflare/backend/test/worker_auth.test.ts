import { describe, expect, it } from 'vitest';
import { callJson, env, makeAppwriteSession, outbound, uid } from './helpers';

// Worker-owned sign-in (routes/auth_sessions.ts) and Worker tokens in the
// shared auth middleware.

type Sent = { to: string; subject: string; text?: string };

function fakeEmail() {
  const sent: Sent[] = [];
  return {
    sent,
    binding: {
      send: async (msg: any) => {
        sent.push({ to: msg.to, subject: msg.subject, text: msg.text });
        return { messageId: `m_${sent.length}` };
      },
    },
    lastCode(): string {
      const match = sent[sent.length - 1]?.subject.match(/^(\d{6}) /);
      if (!match) throw new Error('no code sent');
      return match[1];
    },
  };
}

const bearer = (accessToken: string) => ({ jwt: accessToken });
const email = () => `${uid('learner')}@example.com`;

async function signInByEmail(address: string, mail = fakeEmail()) {
  const start = await callJson('/api/v1/auth/email/start', { method: 'POST', json: { email: address }, env: { EMAIL: mail.binding as any } });
  expect(start.status).toBe(200);
  const verify = await callJson('/api/v1/auth/email/verify', {
    method: 'POST',
    json: { email: address, code: mail.lastCode() },
    env: { EMAIL: mail.binding as any },
  });
  expect(verify.status).toBe(200);
  return verify.body;
}

describe('auth config', () => {
  it('reports which sign-in methods are ready', async () => {
    const { body } = await callJson('/api/v1/auth/config', { env: { EMAIL: fakeEmail().binding as any } });
    expect(body).toMatchObject({ ok: true, enabled: true, guest: true, email: true, google: false });

    const off = await callJson('/api/v1/auth/config', { env: { AUTH_SECRET: '' } });
    expect(off.body).toMatchObject({ enabled: false, guest: false, email: false, google: false });
  });

  it('refuses to sign anyone in without AUTH_SECRET', async () => {
    const { status, body } = await callJson('/api/v1/auth/guest', { method: 'POST', env: { AUTH_SECRET: '' } });
    expect(status).toBe(503);
    expect(body.error).toBe('AUTH_NOT_CONFIGURED');
  });
});

describe('guest sessions', () => {
  it('issues a session the protected routes accept', async () => {
    const { status, body } = await callJson('/api/v1/auth/guest', { method: 'POST' });
    expect(status).toBe(200);
    expect(body.user).toMatchObject({ isGuest: true, email: '' });
    expect(body.user.id).toMatch(/^[a-z0-9]{20}$/);
    expect(body.refreshToken).toContain('.');

    const me = await callJson('/api/v1/auth/me', { as: bearer(body.accessToken) });
    expect(me.status).toBe(200);
    expect(me.body.user.id).toBe(body.user.id);

    const mistakes = await callJson('/api/v1/mistakes', { as: bearer(body.accessToken) });
    expect(mistakes.status).toBe(200);
  });

  it('rejects a tampered or foreign-signed token', async () => {
    const { body } = await callJson('/api/v1/auth/guest', { method: 'POST' });
    const [h, p, s] = body.accessToken.split('.');
    const flipped = `${h}.${p}.${s.slice(0, -2)}${s.endsWith('AA') ? 'BB' : 'AA'}`;
    expect((await callJson('/api/v1/auth/me', { as: bearer(flipped) })).status).toBe(401);

    const other = await callJson('/api/v1/auth/me', {
      as: bearer(body.accessToken),
      env: { AUTH_SECRET: 'a-completely-different-secret-0123456789' },
    });
    expect(other.status).toBe(401);
  });
});

describe('refresh and logout', () => {
  it('refreshes without rotating, and logout ends the session', async () => {
    const { body } = await callJson('/api/v1/auth/guest', { method: 'POST' });

    const refreshed = await callJson('/api/v1/auth/refresh', { method: 'POST', json: { refreshToken: body.refreshToken } });
    expect(refreshed.status).toBe(200);
    expect(refreshed.body.refreshToken).toBe(body.refreshToken);
    expect(refreshed.body.user.id).toBe(body.user.id);

    expect((await callJson('/api/v1/auth/logout', { method: 'POST', json: { refreshToken: body.refreshToken } })).status).toBe(200);

    const again = await callJson('/api/v1/auth/refresh', { method: 'POST', json: { refreshToken: body.refreshToken } });
    expect(again.status).toBe(401);
    // Never used before logout, so not cached: rejected at once.
    expect((await callJson('/api/v1/auth/me', { as: bearer(refreshed.body.accessToken) })).status).toBe(401);
  });

  it('rejects a refresh token with the right id but wrong secret part', async () => {
    const { body } = await callJson('/api/v1/auth/guest', { method: 'POST' });
    const [sid] = body.refreshToken.split('.');
    const { status } = await callJson('/api/v1/auth/refresh', { method: 'POST', json: { refreshToken: `${sid}.forged` } });
    expect(status).toBe(401);
  });
});

describe('email codes', () => {
  it('signs in with the emailed code and returns the same account next time', async () => {
    const address = email();
    const first = await signInByEmail(address);
    expect(first.user).toMatchObject({ email: address, emailVerified: true, isGuest: false });

    const second = await signInByEmail(address.toUpperCase());
    expect(second.user.id).toBe(first.user.id);
  });

  it('rejects a wrong code and locks after five tries', async () => {
    const address = email();
    const mail = fakeEmail();
    await callJson('/api/v1/auth/email/start', { method: 'POST', json: { email: address }, env: { EMAIL: mail.binding as any } });
    const wrong = mail.lastCode() === '000000' ? '111111' : '000000';
    const errors: string[] = [];
    for (let i = 0; i < 5; i++) {
      const { body } = await callJson('/api/v1/auth/email/verify', { method: 'POST', json: { email: address, code: wrong } });
      errors.push(body.error);
    }
    expect(errors.slice(0, 4)).toEqual(['INVALID_CODE', 'INVALID_CODE', 'INVALID_CODE', 'INVALID_CODE']);
    expect(errors[4]).toBe('TOO_MANY_ATTEMPTS');
    const right = await callJson('/api/v1/auth/email/verify', { method: 'POST', json: { email: address, code: mail.lastCode() } });
    expect(right.body.error).toBe('TOO_MANY_ATTEMPTS');
  });

  it('spaces out resends and validates the address', async () => {
    const address = email();
    const mail = fakeEmail();
    const opts = { method: 'POST', json: { email: address }, env: { EMAIL: mail.binding as any } };
    expect((await callJson('/api/v1/auth/email/start', opts)).status).toBe(200);
    const again = await callJson('/api/v1/auth/email/start', opts);
    expect(again.status).toBe(429);
    expect(mail.sent).toHaveLength(1);

    const bad = await callJson('/api/v1/auth/email/start', { method: 'POST', json: { email: 'nope' }, env: { EMAIL: mail.binding as any } });
    expect(bad.body.error).toBe('INVALID_EMAIL');
  });

  it('reports EMAIL_UNAVAILABLE when sending fails, without storing a code', async () => {
    const address = email();
    const broken = { send: async () => { throw new Error('domain not onboarded'); } };
    const { status, body } = await callJson('/api/v1/auth/email/start', { method: 'POST', json: { email: address }, env: { EMAIL: broken as any } });
    expect(status).toBe(503);
    expect(body.error).toBe('EMAIL_UNAVAILABLE');
    const row = await env.DB.prepare('SELECT 1 FROM auth_email_codes WHERE email = ?').bind(address).first();
    expect(row).toBeNull();
  });
});

describe('Google sign-in', () => {
  const google = { GOOGLE_CLIENT_ID: 'gid.apps.googleusercontent.com', GOOGLE_CLIENT_SECRET: 'gsecret' };

  function idToken(claims: Record<string, unknown>) {
    const enc = (v: unknown) => btoa(JSON.stringify(v)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
    return `${enc({ alg: 'RS256' })}.${enc(claims)}.sig`;
  }

  it('round-trips start → callback → exchange for the Android app', async () => {
    const start = await callJson('/api/v1/auth/google/start?platform=android', { env: google, redirect: 'manual' });
    expect(start.status).toBe(302);
    const consent = new URL(start.res.headers.get('location')!);
    expect(consent.host).toBe('accounts.google.com');
    expect(consent.searchParams.get('redirect_uri')).toBe('https://api.olitun.test/api/v1/auth/google/callback');

    const address = email();
    outbound.googleToken = (form) => {
      expect(form.get('client_secret')).toBe('gsecret');
      return new Response(JSON.stringify({
        id_token: idToken({ iss: 'https://accounts.google.com', aud: google.GOOGLE_CLIENT_ID, exp: Math.floor(Date.now() / 1000) + 600, email: address, email_verified: true, name: 'Sona' }),
      }));
    };
    const state = encodeURIComponent(consent.searchParams.get('state')!);
    const cb = await callJson(`/api/v1/auth/google/callback?code=abc&state=${state}`, { env: google, redirect: 'manual' });
    expect(cb.status).toBe(302);
    const back = new URL(cb.res.headers.get('location')!);
    expect(back.protocol).toBe('appwrite-callback-test-project:');
    const code = back.searchParams.get('olitun_code')!;
    expect(code).toBeTruthy();

    const ex = await callJson('/api/v1/auth/exchange', { method: 'POST', json: { code } });
    expect(ex.status).toBe(200);
    expect(ex.body.user).toMatchObject({ email: address, name: 'Sona', isGuest: false });
    // Single use.
    expect((await callJson('/api/v1/auth/exchange', { method: 'POST', json: { code } })).status).toBe(401);
  });

  it('sends the web app back to an allowed origin only', async () => {
    const bad = await callJson(`/api/v1/auth/google/start?platform=web&return=${encodeURIComponent('https://evil.example/')}`, { env: google, redirect: 'manual' });
    expect(bad.status).toBe(400);
    const ok = await callJson(`/api/v1/auth/google/start?platform=web&return=${encodeURIComponent('https://olitun.in/')}`, { env: google, redirect: 'manual' });
    expect(ok.status).toBe(302);
  });

  it('rejects a forged state and an unverified Google email', async () => {
    const forged = await callJson('/api/v1/auth/google/callback?code=abc&state=xyz.abc', { env: google, redirect: 'manual' });
    expect(new URL(forged.res.headers.get('location')!).searchParams.get('error')).toBe('OAUTH_STATE_INVALID');

    const start = await callJson('/api/v1/auth/google/start?platform=android', { env: google, redirect: 'manual' });
    const state = encodeURIComponent(new URL(start.res.headers.get('location')!).searchParams.get('state')!);
    outbound.googleToken = () => new Response(JSON.stringify({
      id_token: idToken({ iss: 'https://accounts.google.com', aud: google.GOOGLE_CLIENT_ID, exp: Math.floor(Date.now() / 1000) + 600, email: email(), email_verified: false }),
    }));
    const cb = await callJson(`/api/v1/auth/google/callback?code=abc&state=${state}`, { env: google, redirect: 'manual' });
    expect(new URL(cb.res.headers.get('location')!).searchParams.get('error')).toBe('GOOGLE_EXCHANGE_FAILED');
  });

  it('tells the app when Google is not configured', async () => {
    const res = await callJson('/api/v1/auth/google/start?platform=android', { redirect: 'manual' });
    expect(new URL(res.res.headers.get('location')!).searchParams.get('error')).toBe('GOOGLE_UNAVAILABLE');
  });
});

describe('Appwrite session migration', () => {
  it('keeps the Appwrite id and copies prefs once', async () => {
    const address = email();
    const legacy = makeAppwriteSession({ email: address, name: 'Old User', prefs: { xp: 120, streak: 4 } });
    const { status, body } = await callJson('/api/v1/auth/appwrite/migrate', { method: 'POST', json: { session: legacy.session } });
    expect(status).toBe(200);
    expect(body.user).toMatchObject({ id: legacy.id, email: address, name: 'Old User', isGuest: false });

    const prefs = await callJson('/api/v1/auth/prefs', { as: bearer(body.accessToken) });
    expect(prefs.body.prefs).toEqual({ xp: 120, streak: 4 });

    // Later sign-ins by email land on the same id.
    const byEmail = await signInByEmail(address);
    expect(byEmail.user.id).toBe(legacy.id);
  });

  it('migrates anonymous Appwrite users as guests', async () => {
    const legacy = makeAppwriteSession({ email: '' });
    const { body } = await callJson('/api/v1/auth/appwrite/migrate', { method: 'POST', json: { session: legacy.session } });
    expect(body.user).toMatchObject({ id: legacy.id, isGuest: true });
  });

  it('rejects an unknown session', async () => {
    const { status, body } = await callJson('/api/v1/auth/appwrite/migrate', { method: 'POST', json: { session: 'sess_unknown' } });
    expect(status).toBe(401);
    expect(body.error).toBe('INVALID_APPWRITE_SESSION');
  });

  it('merges a newer email account into the Appwrite id', async () => {
    const address = email();
    const fresh = await signInByEmail(address);
    const mistakeId = uid('m');
    await env.DB.prepare("INSERT INTO user_mistakes (id, user_id, quiz_id, question_id) VALUES (?, ?, 'quiz_1', 'q_1')")
      .bind(mistakeId, fresh.user.id)
      .run();

    const legacy = makeAppwriteSession({ email: address });
    const { body } = await callJson('/api/v1/auth/appwrite/migrate', { method: 'POST', json: { session: legacy.session } });
    expect(body.user.id).toBe(legacy.id);

    const moved = await env.DB.prepare('SELECT user_id FROM user_mistakes WHERE id = ?').bind(mistakeId).first<any>();
    expect(moved.user_id).toBe(legacy.id);
    const old = await env.DB.prepare('SELECT status, email FROM auth_users WHERE id = ?').bind(fresh.user.id).first<any>();
    expect(old).toMatchObject({ status: 'merged', email: null });
    expect((await callJson('/api/v1/auth/me', { as: bearer(fresh.accessToken) })).status).toBe(401);
    const again = await signInByEmail(address);
    expect(again.user.id).toBe(legacy.id);
  });

  it('carries Appwrite admins over to Worker sessions', async () => {
    const admin = makeAppwriteSession({ email: email(), admin: true });
    const { body } = await callJson('/api/v1/auth/appwrite/migrate', { method: 'POST', json: { session: admin.session } });
    expect((await callJson('/api/v1/admin/audit', { as: bearer(body.accessToken) })).status).toBe(200);
    expect((await callJson('/api/v1/auth/me', { as: bearer(body.accessToken) })).body.isAdmin).toBe(true);

    const learner = await callJson('/api/v1/auth/guest', { method: 'POST' });
    expect((await callJson('/api/v1/admin/audit', { as: bearer(learner.body.accessToken) })).status).toBe(403);
    expect((await callJson('/api/v1/auth/me', { as: bearer(learner.body.accessToken) })).body.isAdmin).toBe(false);
  });
});

describe('profile and prefs', () => {
  it('updates the display name and replaces prefs', async () => {
    const { body } = await callJson('/api/v1/auth/guest', { method: 'POST' });
    const as = bearer(body.accessToken);
    const named = await callJson('/api/v1/auth/me', { method: 'PATCH', as, json: { name: 'Mani' } });
    expect(named.body.user.name).toBe('Mani');

    await callJson('/api/v1/auth/prefs', { method: 'PUT', as, json: { prefs: { a: 1, b: 2 } } });
    await callJson('/api/v1/auth/prefs', { method: 'PUT', as, json: { prefs: { b: 3 } } });
    expect((await callJson('/api/v1/auth/prefs', { as })).body.prefs).toEqual({ b: 3 });

    const big = await callJson('/api/v1/auth/prefs', { method: 'PUT', as, json: { prefs: { blob: 'x'.repeat(70_000) } } });
    expect(big.status).toBe(413);
  });
});

describe('account deletion with a Worker session', () => {
  it('purges data, closes the login, and blocks re-migration', async () => {
    const legacy = makeAppwriteSession({ email: email(), prefs: { xp: 9 } });
    const { body } = await callJson('/api/v1/auth/appwrite/migrate', { method: 'POST', json: { session: legacy.session } });
    const as = bearer(body.accessToken);

    const del = await callJson('/api/v1/user/delete', { method: 'POST', as, env: { APPWRITE_API_KEY: undefined } });
    expect(del.status).toBe(200);
    expect(del.body.ok).toBe(true);

    const row = await env.DB.prepare('SELECT status, email FROM auth_users WHERE id = ?').bind(legacy.id).first<any>();
    expect(row).toMatchObject({ status: 'deleted', email: null });
    const prefs = await env.DB.prepare('SELECT 1 FROM user_prefs WHERE user_id = ?').bind(legacy.id).first();
    expect(prefs).toBeNull();

    expect((await callJson('/api/v1/auth/refresh', { method: 'POST', json: { refreshToken: body.refreshToken } })).status).toBe(401);
    const again = await callJson('/api/v1/auth/appwrite/migrate', { method: 'POST', json: { session: legacy.session } });
    expect(again.status).toBe(403);
    expect(again.body.error).toBe('ACCOUNT_DELETED');
  });
});
