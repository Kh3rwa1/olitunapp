import { describe, expect, it } from 'vitest';
import { ANONYMIZED_USER_ID } from '../src/routes/account';
import { callJson, env, grantPurchase, insertCategory, makeUser, outbound, uid } from './helpers';

type User = { id: string; jwt: string };

// Gives [user] rows in several per-user tables, an R2 upload and a purchase.
async function seedUserData(user: User) {
  await callJson('/api/v1/mistakes/record', { as: user, json: { quizId: uid('quiz'), questionIndex: 0, wrongAnswer: 'a', correctAnswer: 'b' } });
  const itemId = uid('word');
  await callJson('/api/v1/review/mutate', {
    as: user,
    json: { action: 'applyRecall', operationId: uid('op'), itemId, itemType: 'word', exerciseType: 'typing', correct: true, occurredAt: '2026-10-01T00:00:00Z', deviceId: 'd1' },
  });
  await env.DB.prepare(
    "INSERT INTO binti_waitlist (id, user_id, full_name, phone_number, ceremony_type, city, state, submitted_at, status) VALUES (?, ?, 'Sona Murmu', '9000000000', 'binti', 'Dumka', 'Jharkhand', ?, 'new')"
  ).bind(uid('wl'), user.id, new Date().toISOString()).run();
  await grantPurchase(user.id, await insertCategory({ unlockMode: 'paid', priceInr: 99 }));
  await env.ASSETS.put(`users/${user.id}/avatar.png`, 'x');
}

async function count(table: string, userId: string): Promise<number> {
  const row = await env.DB.prepare(`SELECT COUNT(*) AS n FROM ${table} WHERE user_id = ?`).bind(userId).first<any>();
  return row.n;
}

const PURGED = ['user_mistakes', 'review_states', 'review_operations', 'binti_waitlist'];

describe('POST /user/delete', () => {
  it("purges the caller's rows and uploads, keeps other users' data", async () => {
    const leaving = makeUser();
    const staying = makeUser();
    await seedUserData(leaving);
    await seedUserData(staying);
    for (const table of PURGED) expect(await count(table, leaving.id), table).toBeGreaterThan(0);

    const { status, body } = await callJson('/api/v1/user/delete', { method: 'POST', as: leaving });
    expect(status).toBe(200);
    expect(body.ok).toBe(true);

    for (const table of PURGED) {
      expect(await count(table, leaving.id), table).toBe(0);
      expect(await count(table, staying.id), table).toBeGreaterThan(0);
    }
    // Financial records stay, detached from the person.
    expect(await count('course_purchases', leaving.id)).toBe(0);
    expect(await count('course_purchases', ANONYMIZED_USER_ID)).toBeGreaterThan(0);
    expect(await count('course_purchases', staying.id)).toBe(1);

    expect(await env.ASSETS.head(`users/${leaving.id}/avatar.png`)).toBeNull();
    expect(await env.ASSETS.head(`users/${staying.id}/avatar.png`)).not.toBeNull();
  });

  it('blocks the login with the user JWT when no server key is configured', async () => {
    const user = makeUser();
    const { status, body } = await callJson('/api/v1/user/delete', { method: 'POST', as: user, env: { APPWRITE_API_KEY: undefined } });
    expect(status).toBe(200);
    expect(body).toMatchObject({ loginBlocked: true, authDeleted: false });
    const block = outbound.callsTo('/account/status');
    expect(block).toHaveLength(1);
    expect(block[0].method).toBe('PATCH');
    expect(block[0].headers.get('x-appwrite-jwt')).toBe(user.jwt);
    expect(outbound.callsTo('/users/')).toHaveLength(0);
  });

  it('hard-deletes the login when a server key is configured', async () => {
    const user = makeUser();
    const { body } = await callJson('/api/v1/user/delete', { method: 'POST', as: user, env: { APPWRITE_API_KEY: 'server-key' } });
    expect(body).toMatchObject({ ok: true, authDeleted: true, loginBlocked: false });
    const del = outbound.callsTo(`/users/${user.id}`);
    expect(del).toHaveLength(1);
    expect(del[0].headers.get('x-appwrite-key')).toBe('server-key');
    expect(outbound.callsTo('/account/status')).toHaveLength(0);
    const request = await env.DB.prepare("SELECT status, user_id FROM deletion_requests WHERE status = 'completed' AND user_id = ?").bind(ANONYMIZED_USER_ID).all();
    expect(request.results.length).toBeGreaterThan(0);
  });

  it('falls back to blocking when the server key lacks users.write', async () => {
    const user = makeUser();
    outbound.deleteUser = () => new Response(JSON.stringify({ type: 'general_unauthorized_scope' }), { status: 401 });
    const { body } = await callJson('/api/v1/user/delete', { method: 'POST', as: user, env: { APPWRITE_API_KEY: 'weak-key' } });
    expect(body.loginBlocked).toBe(true);
    expect(outbound.callsTo('/account/status')).toHaveLength(1);
  });

  it('reports failure and records it when the login cannot be removed', async () => {
    const user = makeUser();
    outbound.deleteUser = () => new Response(JSON.stringify({ type: 'general_server_error' }), { status: 500 });
    const { status, body } = await callJson('/api/v1/user/delete', { method: 'POST', as: user, env: { APPWRITE_API_KEY: 'server-key' } });
    expect(status).toBe(502);
    expect(body.ok).toBe(false);
    const row = await env.DB.prepare('SELECT status, last_error FROM deletion_requests WHERE user_id = ?').bind(user.id).first<any>();
    expect(row).toMatchObject({ status: 'cleanup_failed', last_error: 'AUTH_DELETE_FAILED' });
  });
});
