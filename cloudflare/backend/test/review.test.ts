import { describe, expect, it } from 'vitest';
import { rowIdFor } from '../src/routes/review';
import { callJson, env, makeUser, uid } from './helpers';

type User = { id: string; jwt: string };

const mutate = (user: User, body: Record<string, unknown>) => callJson('/api/v1/review/mutate', { as: user, json: body });
const list = async (user: User, query = '') => (await callJson(`/api/v1/review/states${query}`, { as: user })).body;

function upsertBody(itemId: string, nextReviewAt = '2026-11-01T00:00:00.000Z') {
  return {
    action: 'upsert',
    itemId,
    itemType: 'word',
    nextReviewAt,
    stateJson: JSON.stringify({ itemId, itemType: 'word', nextReviewAt, successfulRecalls: 3 }),
  };
}

function recallBody(itemId: string, operationId: string, correct = true) {
  return {
    action: 'applyRecall',
    operationId,
    itemId,
    itemType: 'word',
    exerciseType: 'recognition',
    correct,
    occurredAt: '2026-10-15T10:00:00.000Z',
    deviceId: 'device-1',
    localSequence: 1,
  };
}

async function storedState(user: User, itemId: string) {
  const row = await env.DB.prepare('SELECT state_json FROM review_states WHERE id = ?').bind(await rowIdFor(user.id, itemId)).first<any>();
  return row ? JSON.parse(row.state_json) : null;
}

describe('review sync', () => {
  it('upserts a state and lists it back for the owner', async () => {
    const user = makeUser();
    const itemId = uid('word');
    const res = await mutate(user, upsertBody(itemId));
    expect(res.status).toBe(200);
    expect(res.body.rowId).toBe(await rowIdFor(user.id, itemId));
    const page = await list(user);
    expect(page.rows).toHaveLength(1);
    expect(page.rows[0]).toMatchObject({ itemId, userId: user.id, nextReviewAt: '2026-11-01T00:00:00.000Z' });
  });

  it('overwrites on a second upsert (last write wins)', async () => {
    const user = makeUser();
    const itemId = uid('word');
    await mutate(user, upsertBody(itemId, '2026-11-01T00:00:00.000Z'));
    await mutate(user, upsertBody(itemId, '2026-12-01T00:00:00.000Z'));
    const page = await list(user);
    expect(page.rows).toHaveLength(1);
    expect(page.rows[0].nextReviewAt).toBe('2026-12-01T00:00:00.000Z');
  });

  it('rejects an upsert whose snapshot disagrees with the request', async () => {
    const user = makeUser();
    const body = upsertBody(uid('word'));
    const { status } = await mutate(user, { ...body, stateJson: JSON.stringify({ itemId: 'other', itemType: 'word', nextReviewAt: body.nextReviewAt }) });
    expect(status).toBe(400);
  });

  it('applies a recall once and reports duplicate:true on replay', async () => {
    const user = makeUser();
    const itemId = uid('word');
    const op = uid('op');
    const first = await mutate(user, recallBody(itemId, op));
    expect(first.status).toBe(200);
    expect(first.body.duplicate).toBe(false);

    const replay = await mutate(user, recallBody(itemId, op));
    expect(replay.status).toBe(200);
    expect(replay.body.duplicate).toBe(true);

    const state = await storedState(user, itemId);
    expect(state.successfulRecalls).toBe(1);
    expect(state.recentOperationIds).toEqual([op]);
  });

  it('accumulates distinct recalls as deltas', async () => {
    const user = makeUser();
    const itemId = uid('word');
    await mutate(user, recallBody(itemId, uid('op'), true));
    await mutate(user, recallBody(itemId, uid('op'), false));
    await mutate(user, { ...recallBody(itemId, uid('op'), true), exerciseType: 'typing' });
    const state = await storedState(user, itemId);
    expect(state).toMatchObject({ successfulRecalls: 3, failedRecalls: 1, typingSuccesses: 1 });
  });

  it('deletes a state and treats a repeat delete as success', async () => {
    const user = makeUser();
    const itemId = uid('word');
    await mutate(user, upsertBody(itemId));
    expect((await mutate(user, { action: 'delete', itemId })).body.deleted).toBe(true);
    expect((await list(user)).rows).toHaveLength(0);
    expect((await mutate(user, { action: 'delete', itemId })).status).toBe(200);
  });

  it("keeps users' states isolated", async () => {
    const alice = makeUser();
    const bob = makeUser();
    const itemId = uid('word');
    const op = uid('op');
    await mutate(alice, upsertBody(itemId));
    await mutate(alice, recallBody(itemId, op));

    expect((await list(bob)).rows).toHaveLength(0);
    // Same item and operation ids from another user are a separate row.
    const bobRecall = await mutate(bob, recallBody(itemId, op));
    expect(bobRecall.body.duplicate).toBe(false);
    expect(bobRecall.body.rowId).not.toBe(await rowIdFor(alice.id, itemId));
    await mutate(bob, { action: 'delete', itemId });

    const aliceState = await storedState(alice, itemId);
    expect(aliceState).not.toBeNull();
    expect(aliceState.successfulRecalls).toBe(4);
  });

  it('pages with a cursor', async () => {
    const user = makeUser();
    for (let i = 0; i < 5; i++) await mutate(user, upsertBody(uid('word')));
    const first = await list(user, '?limit=2');
    expect(first.rows).toHaveLength(2);
    expect(first.hasMore).toBe(true);
    const second = await list(user, `?limit=2&cursor=${first.nextCursor}`);
    const third = await list(user, `?limit=2&cursor=${second.nextCursor}`);
    const ids = [...first.rows, ...second.rows, ...third.rows].map((r: any) => r.$id);
    expect(new Set(ids).size).toBe(5);
    expect(third.rows).toHaveLength(1);
    expect(third.hasMore).toBe(false);
  });

  it('rejects a malformed cursor, bad limit and unknown action', async () => {
    const user = makeUser();
    expect((await callJson('/api/v1/review/states?cursor=x%27--', { as: user })).status).toBe(400);
    expect((await callJson('/api/v1/review/states?limit=0', { as: user })).status).toBe(400);
    expect((await mutate(user, { action: 'drop' })).status).toBe(400);
  });
});
