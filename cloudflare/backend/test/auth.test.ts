import { describe, expect, it } from 'vitest';
import { call, callJson, env, makeUser, outbound, uid } from './helpers';

// [method, path] for every route that must require a signed-in user.
const USER_ROUTES: Array<[string, string]> = [
  ['GET', '/api/v1/review/states'],
  ['POST', '/api/v1/review/mutate'],
  ['POST', '/api/v1/payments/order'],
  ['POST', '/api/v1/payments/verify'],
  ['GET', '/api/v1/payments/entitlements'],
  ['POST', '/api/v1/payments/entitlements/sync'],
  ['GET', '/api/v1/mistakes'],
  ['POST', '/api/v1/mistakes/record'],
  ['POST', '/api/v1/mistakes/master'],
  ['POST', '/api/v1/mistakes/review/complete'],
  ['POST', '/api/v1/bakhed/progress'],
  ['GET', '/api/v1/gamification/summary'],
  ['POST', '/api/v1/user/delete'],
  ['GET', '/api/v1/waitlist/mine'],
  ['POST', '/api/v1/translate'],
  ['POST', '/api/v1/voice/synthesize'],
  ['POST', '/api/v1/audio/generate'],
  ['POST', '/api/v1/studio/transcribe'],
  ['POST', '/api/v1/studio/process'],
];

// One representative route per admin module.
const ADMIN_ROUTES: Array<[string, string]> = [
  ['GET', '/api/v1/admin/audit'],
  ['GET', '/api/v1/admin/content/categories'],
  ['PUT', '/api/v1/admin/content/categories/cat_x'],
  ['GET', '/api/v1/admin/settings'],
  ['GET', '/api/v1/admin/cms/rows/badges'],
  ['GET', '/api/v1/admin/cms/bakhed'],
  ['GET', '/api/v1/admin/media/references?fileId=abc'],
  ['PUT', '/api/v1/admin/media/images/abc'],
  ['GET', '/api/v1/admin/purchases'],
  ['POST', '/api/v1/admin/purchases/refund'],
  ['POST', '/api/v1/admin/maintenance'],
  ['POST', '/api/v1/admin/backup'],
  ['GET', '/api/v1/admin/backups'],
  ['POST', '/api/v1/admin/access'],
  ['GET', '/api/v1/admin/review/queue'],
  ['POST', '/api/v1/admin/review/state'],
  ['GET', '/api/v1/admin/dashboard/activity'],
  ['GET', '/api/v1/admin/analytics/snapshot'],
  ['GET', '/api/v1/admin/health/schema'],
  ['GET', '/api/v1/admin/waitlist'],
  ['POST', '/api/v1/admin/deletions/reconcile'],
  ['POST', '/api/v1/analytics/aggregate'],
  ['POST', '/api/v1/analytics/cleanup'],
  ['POST', '/api/v1/payments/reconcile'],
];

const withBody = (method: string) => (method === 'GET' ? {} : { json: {} });

describe('user routes', () => {
  it.each(USER_ROUTES)('%s %s rejects a request without a JWT', async (method, path) => {
    const { status, body } = await callJson(path, { method, ...withBody(method) });
    expect(status).toBe(401);
    expect(body.error ?? body.code).toMatch(/UNAUTHENTICATED/i);
  });

  it('rejects a JWT Appwrite does not accept', async () => {
    for (const [method, path] of USER_ROUTES.slice(0, 6)) {
      const res = await call(path, { method, as: { jwt: 'forged.jwt.value' }, ...withBody(method) });
      expect(res.status, `${method} ${path}`).toBe(401);
    }
  });

  it('accepts the JWT in the X-Appwrite-JWT header too', async () => {
    const user = makeUser();
    const { status, body } = await callJson('/api/v1/payments/entitlements', { headers: { 'x-appwrite-jwt': user.jwt } });
    expect(status).toBe(200);
    expect(body.userId).toBe(user.id);
  });

  it('answers 503 (not 401) when Appwrite is unreachable', async () => {
    const user = makeUser();
    outbound.appwriteDown = true;
    const { status, body } = await callJson('/api/v1/payments/entitlements', { as: user });
    expect(status).toBe(503);
    expect(body.error).toBe('AUTH_UNAVAILABLE');
  });

  it('ignores a spoofed x-appwrite-user-id header without a JWT', async () => {
    const victim = makeUser();
    const res = await call('/api/v1/payments/entitlements', { headers: { 'x-appwrite-user-id': victim.id } });
    expect(res.status).toBe(401);
  });

  it('takes identity from the JWT, not header or ?userId=', async () => {
    const caller = makeUser();
    const victim = makeUser();
    const { body } = await callJson(`/api/v1/payments/entitlements?userId=${victim.id}`, {
      as: caller,
      headers: { 'x-appwrite-user-id': victim.id },
    });
    expect(body.userId).toBe(caller.id);
  });

  it('ignores body userId when recording a mistake', async () => {
    const caller = makeUser();
    const victim = makeUser();
    const quizId = uid('quiz');
    const { status, body } = await callJson('/api/v1/mistakes/record', {
      as: caller,
      json: { userId: victim.id, quizId, questionIndex: 1, wrongAnswer: 'a', correctAnswer: 'b' },
    });
    expect(status).toBe(200);
    expect(body.mistake.userId).toBe(caller.id);
    const victimRows = await env.DB.prepare('SELECT COUNT(*) AS n FROM user_mistakes WHERE user_id = ?').bind(victim.id).first<any>();
    expect(victimRows.n).toBe(0);
  });

  it('rejects a review mutation that names another user', async () => {
    const caller = makeUser();
    const victim = makeUser();
    const { status, body } = await callJson('/api/v1/review/mutate', {
      as: caller,
      json: { action: 'list', userId: victim.id },
    });
    expect(status).toBe(403);
    expect(body.error).toBe('FORBIDDEN');
  });

  it('lets anonymous callers use optional-auth routes but rejects a bad JWT there', async () => {
    expect((await call('/api/v1/lessons/authorize')).status).toBe(200);
    expect((await call('/api/v1/lessons/authorize', { as: { jwt: 'forged' } })).status).toBe(401);
  });
});

describe('admin routes', () => {
  it.each(ADMIN_ROUTES)('%s %s is forbidden to a learner', async (method, path) => {
    const learner = makeUser();
    const { status, body } = await callJson(path, { method, as: learner, ...withBody(method) });
    expect(status).toBe(403);
    expect(body.error).toBe('FORBIDDEN');
  });

  it('requires a JWT before checking admin membership', async () => {
    for (const [method, path] of ADMIN_ROUTES.slice(0, 5)) {
      const res = await call(path, { method, ...withBody(method) });
      expect(res.status, `${method} ${path}`).toBe(401);
    }
  });

  it('does not treat a self-made team named "admins" as the admin team', async () => {
    const impostor = makeUser('fake-admin');
    const res = await call('/api/v1/admin/audit', { as: impostor });
    expect(res.status).toBe(403);
  });

  it('lets an admin-team member through', async () => {
    const admin = makeUser('admin');
    const { status, body } = await callJson('/api/v1/admin/audit', { as: admin });
    expect(status).toBe(200);
    expect(body.ok).toBe(true);
  });
});

describe('cron secret', () => {
  it('lets a scheduled job with the right x-cron-secret run admin jobs', async () => {
    const { status, body } = await callJson('/api/v1/payments/reconcile', {
      method: 'POST',
      headers: { 'x-cron-secret': 'test-cron-secret' },
    });
    expect(status).toBe(200);
    expect(body.ok).toBe(true);
  });

  it('rejects a wrong cron secret', async () => {
    const res = await call('/api/v1/payments/reconcile', { method: 'POST', headers: { 'x-cron-secret': 'nope' } });
    expect(res.status).toBe(401);
  });

  it('never matches an empty secret when CRON_SECRET is unset', async () => {
    const res = await call('/api/v1/payments/reconcile', {
      method: 'POST',
      headers: { 'x-cron-secret': '' },
      env: { CRON_SECRET: '' },
    });
    expect(res.status).toBe(401);
  });

  it('does not let the cron secret through on learner routes', async () => {
    const res = await call('/api/v1/payments/entitlements', { headers: { 'x-cron-secret': 'test-cron-secret' } });
    expect(res.status).toBe(401);
  });
});
