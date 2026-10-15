// node --test scripts/import_appwrite_user_data.test.mjs   (from cloudflare/backend)
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { spawn, spawnSync } from 'node:child_process';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  appwriteClient, appwritePseudonymousId, CONFLICT_SQL, d1DeletionRequestId, dedupeReviewStates,
  encryptAppwriteUserId, insertSql, makeDeletionGuard, mapAnalyticsEvent, mapBakhedProgress, mapCoursePurchase,
  mapMistakeReviewSession, mapRewardEvent, mapReviewState, mapUserBadge, mapUserMistake, mapWaitlistEntry,
  parseArgs, redactSample, reviewRowIdFor, sqlValue, stableId, statementsFor,
} from './import_appwrite_user_data.mjs';

const BACKEND = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const SCRIPT = join(BACKEND, 'scripts', 'import_appwrite_user_data.mjs');
const WRANGLER = join(BACKEND, 'node_modules', '.bin', 'wrangler');
const NOW = Date.now();
const daysAgo = (n) => new Date(NOW - n * 86_400_000).toISOString();

const state = (itemId, extra = {}) => JSON.stringify({ itemId, itemType: 'word', nextReviewAt: '2026-01-02T00:00:00.000Z', ...extra });

// ------------------------------------------------------------ unit tests

test('sqlValue escapes quotes, NUL bytes, null, booleans and numbers', () => {
  assert.equal(sqlValue("O'Brien'); DROP TABLE x;--"), "'O''Brien''); DROP TABLE x;--'");
  assert.equal(sqlValue('a\u0000b'), "'ab'");
  assert.equal(sqlValue(null), 'NULL');
  assert.equal(sqlValue(undefined), 'NULL');
  assert.equal(sqlValue(true), '1');
  assert.equal(sqlValue(42), '42');
  assert.equal(sqlValue(Number.NaN), 'NULL');
  assert.throws(() => insertSql('t; drop', { a: 1 }));
  assert.throws(() => insertSql('t', { 'a)': 1 }));
});

test('ids match the Worker conventions', () => {
  assert.match(reviewRowIdFor('u1', 'w1'), /^r_[a-f0-9]{31}$/);
  assert.equal(stableId('x').length, 32);
  assert.equal(d1DeletionRequestId('u1'), `del_${stableId('deletion:u1')}`);
});

test('review_states: legacy id rewritten to hashed id, newest kept', () => {
  const legacy = mapReviewState({
    $id: 'userA__w1', $updatedAt: '2025-03-01T00:00:00.000+00:00', userId: 'userA', itemId: 'w1', itemType: 'word',
    stateJson: state('w1', { lastReviewedAt: '2025-03-01T00:00:00.000Z' }), nextReviewAt: '2026-01-02T00:00:00.000Z',
    lastReviewedAt: '2025-03-01T00:00:00.000Z', schemaVersion: 3,
  });
  const hashed = mapReviewState({
    $id: reviewRowIdFor('userA', 'w1'), $updatedAt: '2025-02-01T00:00:00.000+00:00', userId: 'userA', itemId: 'w1',
    itemType: 'word', stateJson: state('w1', { lastReviewedAt: '2025-02-01T00:00:00.000Z' }),
    nextReviewAt: '2026-01-02T00:00:00.000Z', lastReviewedAt: '2025-02-01T00:00:00.000Z',
  });
  assert.equal(legacy.legacy, true);
  assert.equal(hashed.legacy, false);
  assert.equal(legacy.id, reviewRowIdFor('userA', 'w1'));
  assert.equal(legacy.rows[0].row.updated_at, '2025-03-01T00:00:00.000Z');
  const { kept, dropped } = dedupeReviewStates([hashed, legacy]);
  assert.equal(dropped, 1);
  assert.equal(kept[0], legacy);
  // Ties go to the hashed row.
  const tie = mapReviewState({ ...{ $id: 'userA__w1', $updatedAt: '2025-02-01T00:00:00.000Z' }, userId: 'userA', itemId: 'w1', itemType: 'word', stateJson: state('w1', { lastReviewedAt: '2025-02-01T00:00:00.000Z' }), nextReviewAt: '2026-01-02T00:00:00.000Z', lastReviewedAt: '2025-02-01T00:00:00.000Z' });
  assert.equal(dedupeReviewStates([tie, hashed]).kept[0], hashed);
});

test('review_states: invalid rows are skipped', () => {
  const base = { $id: 'x', userId: 'userA', itemId: 'w1', itemType: 'word', stateJson: state('w1'), nextReviewAt: '2026-01-02T00:00:00Z' };
  assert.equal(mapReviewState({ ...base, itemType: 'letter' }).skip, 'invalid_item_type');
  assert.equal(mapReviewState({ ...base, stateJson: '[1]' }).skip, 'invalid_state_json');
  assert.equal(mapReviewState({ ...base, stateJson: '{bad' }).skip, 'invalid_state_json');
  assert.equal(mapReviewState({ ...base, stateJson: JSON.stringify({ pad: 'x'.repeat(9000) }) }).skip, 'state_too_large');
  assert.equal(mapReviewState({ ...base, userId: 'bad id!' }).skip, 'invalid_user');
  assert.equal(mapReviewState({ ...base, itemId: 'i'.repeat(121) }).skip, 'invalid_item');
  assert.equal(mapReviewState({ ...base, nextReviewAt: 'never', stateJson: '{}' }).skip, 'invalid_next_review_at');
});

test('user_mistakes / sessions / bakhed / badges / rewards mapping', () => {
  const m = mapUserMistake({ userId: 'userA', quizId: 'q1', questionIndex: 2, wrongAnswer: 'a'.repeat(5000), correctAnswer: 'b', questionSnapshot: '{"q":1}', timesMissed: 3, isMastered: false, masteredAt: '', lastMissedAt: '2025-01-01T00:00:00Z', lastReviewedAt: '' });
  const row = m.rows[0].row;
  assert.equal(m.id, stableId('userA:q1:q1_2'));
  assert.equal(row.question_id, 'q1_2');
  assert.equal(row.wrong_answer.length, 2048);
  assert.equal(row.times_missed, 3);
  assert.equal(row.mastered_at, '');
  assert.equal(row.last_missed_at, '2025-01-01T00:00:00.000Z');

  const s = mapMistakeReviewSession({ $id: 'sess1', sessionId: 'abc123', userId: 'userA', questionIds: '["q1:a","q2:b"]', score: 9, total: 2, completedAt: '2025-01-01T00:00:00Z' });
  assert.deepEqual(s.rows[0].row, { session_id: 'abc123', user_id: 'userA', question_ids: '["q1:a","q2:b"]', score: 2, total: 2, completed_at: '2025-01-01T00:00:00.000Z' });

  const b = mapBakhedProgress({ userId: 'userA', bakhedId: 'bk1', listenedPercent: 150, completed80Percent: false, lastPositionMs: 5, updatedAt: '2025-01-01T00:00:00Z' });
  assert.equal(b.id, stableId('userA:bk1'));
  assert.equal(b.rows[0].row.listened_percent, 100);
  assert.equal(b.rows[0].row.completed_80_percent, 1);
  assert.equal(b.rows[0].row.completed_at, '2025-01-01T00:00:00.000Z');

  const ub = mapUserBadge({ userId: 'userA', badgeId: 'first_steps', progress: 3, target: 5, isUnlocked: false });
  assert.equal(ub.id, stableId('userA:first_steps'));
  assert.equal(ub.rows[0].row.is_unlocked, 0);

  const r = mapRewardEvent({ $id: 'doc1', rewardEventId: 'rw_1', userId: 'userA', sourceType: 'lesson', sourceId: 'l1', starsAwarded: 5, createdAt: '2025-01-01T00:00:00Z' });
  assert.equal(r.id, 'rw_1');
  assert.equal(mapRewardEvent({ $id: 'bad id', userId: 'userA' }).skip, 'invalid_id');
});

test('analytics: Worker id, details split, retention and validation', () => {
  const doc = { eventId: 'ev-1', eventName: 'lesson_completed', userId: 'userA', sessionId: 's1', source: 'home', sourceId: 'l1', platform: 'android', occurredAt: daysAgo(1), metadata: '{"a":1}', eventVersion: 2 };
  const m = mapAnalyticsEvent(doc, NOW);
  assert.equal(m.id, stableId('analytics:userA:ev-1'));
  assert.equal(m.rows[0].table, 'learning_analytics_events');
  assert.equal(m.rows[1].table, 'learning_analytics_event_details');
  assert.equal(m.rows[1].row.event_version, 2);
  assert.equal(m.rows[1].row.metadata_json, '{"a":1}');
  const guest = mapAnalyticsEvent({ ...doc, userId: null }, NOW);
  assert.equal(guest.id, stableId('analytics::ev-1'));
  assert.equal(guest.rows[0].row.user_id, '');
  assert.equal(guest.userId, null);
  assert.equal(mapAnalyticsEvent({ ...doc, occurredAt: daysAgo(120) }, NOW).skip, 'expired');
  assert.equal(mapAnalyticsEvent({ ...doc, eventName: 'Bad-Name' }, NOW).skip, 'invalid_event_name');
  assert.equal(mapAnalyticsEvent({ ...doc, platform: 'x'.repeat(21) }, NOW).skip, 'invalid_event_fields');
});

test('waitlist: validated like the Worker, duplicate-safe insert', () => {
  const doc = { $id: 'wl1', userId: 'userA', fullName: 'Sita Murmu', phoneNumber: '+91 98765 43210', ceremonyType: 'Wedding', city: 'Ranchi', state: 'Jharkhand', submittedAt: '2025-01-01T00:00:00Z', status: 'contacted' };
  const m = mapWaitlistEntry(doc);
  assert.equal(m.rows[0].row.ceremony_type, 'wedding');
  assert.equal(m.rows[0].row.status, 'contacted');
  assert.equal(mapWaitlistEntry({ ...doc, phoneNumber: 'abc' }).skip, 'invalid_waitlist_fields');
  assert.equal(mapWaitlistEntry({ ...doc, ceremonyType: 'party' }).skip, 'invalid_waitlist_fields');
  const fresh = mapWaitlistEntry({ ...doc, status: undefined, userId: undefined });
  assert.equal(fresh.rows[0].row.user_id, null);
  const [sql] = statementsFor(fresh);
  assert.match(sql, /WHERE NOT EXISTS \(SELECT 1 FROM binti_waitlist WHERE phone_number = '\+91 98765 43210'/);
  const redacted = redactSample(m)[0].row;
  assert.equal(redacted.full_name, '[redacted]');
  assert.equal(redacted.phone_number, '[redacted]');
  assert.notEqual(redacted.user_id, 'userA');
});

test('course_purchases: only real verified, unrefunded purchases', () => {
  const doc = { $id: 'p1', userId: 'userA', categoryId: 'cat1', provider: 'razorpay', providerOrderId: 'order_1', providerPaymentId: 'pay_1', expectedAmount: 199, paidAmount: 199, currency: 'INR', status: 'verified', verifiedAt: '2025-01-01T00:00:00Z' };
  const m = mapCoursePurchase(doc);
  assert.deepEqual(m.rows[0].row, { id: stableId('purch:userA:cat1'), user_id: 'userA', category_id: 'cat1', course_id: 'cat1', amount_in_cents: 19900, currency: 'INR', status: 'completed', order_id: 'order_1', payment_id: 'pay_1', created_at: '2025-01-01T00:00:00.000Z' });
  assert.equal(m.extraStatements.length, 0);
  assert.equal(mapCoursePurchase({ ...doc, status: 'created' }).skip, 'not_verified');
  assert.equal(mapCoursePurchase({ ...doc, status: 'refunded' }).skip, 'not_verified');
  assert.equal(mapCoursePurchase({ ...doc, refundStatus: 'fully_refunded' }).skip, 'refunded');
  assert.equal(mapCoursePurchase({ ...doc, refundedAmountPaise: 19900 }).skip, 'refunded');
  assert.equal(mapCoursePurchase({ ...doc, providerPaymentId: '' }).skip, 'no_payment_reference');
  assert.equal(mapCoursePurchase({ ...doc, paidAmount: 0, expectedAmount: 0 }).skip, 'no_amount');
  const partial = mapCoursePurchase({ ...doc, refundStatus: 'partially_refunded', refundedAmountPaise: 5000, refundEpoch: 1 });
  assert.match(partial.extraStatements[0], /^INSERT INTO purchase_refunds .* WHERE EXISTS \(SELECT 1 FROM course_purchases WHERE id = '[a-f0-9]{32}' AND order_id = 'order_1'\) ON CONFLICT\(purchase_id\) DO NOTHING;$/);
});

test('conflict SQL never lets imported data clobber newer D1 data', () => {
  assert.match(CONFLICT_SQL.review_states, /excluded\.updated_at > review_states\.updated_at/);
  assert.match(CONFLICT_SQL.review_states, /review_states\.user_id = excluded\.user_id/);
  assert.match(CONFLICT_SQL.user_mistakes, /MAX\(COALESCE\(excluded\.last_missed_at/);
  assert.match(CONFLICT_SQL.bakhed_listening_progress, /MAX\(bakhed_listening_progress\.listened_percent, excluded\.listened_percent\)/);
  for (const t of ['course_purchases', 'reward_events', 'learning_analytics_events', 'binti_waitlist', 'mistake_review_sessions']) {
    assert.match(CONFLICT_SQL[t], /DO NOTHING$/);
  }
  const sql = insertSql('reward_events', { id: "r'1", user_id: 'u' }, CONFLICT_SQL.reward_events);
  assert.equal(sql, "INSERT INTO reward_events (id, user_id) VALUES ('r''1', 'u') ON CONFLICT(id) DO NOTHING;");
});

test('deletion guard: D1 rows, Appwrite pseudonymous + encrypted ids, fail closed', () => {
  const secret = 'test-secret';
  const guard = makeDeletionGuard({
    d1Rows: [{ id: d1DeletionRequestId('goneD1'), user_id: 'anonymized_deleted_user' }, { id: 'del_x', user_id: 'blockedD1' }],
    appwriteDocs: [
      { $id: `del_${appwritePseudonymousId('openAw', secret)}`, userId: 'anonymized_deleted_user', status: 'cleanup_failed' },
      { $id: 'del_zzz', userId: 'anonymized_deleted_user', encryptedUserId: encryptAppwriteUserId('encAw', secret), status: 'in_progress' },
    ],
    secrets: [secret],
  });
  assert.equal(guard.isDeleted('goneD1'), true);
  assert.equal(guard.isDeleted('blockedD1'), true);
  assert.equal(guard.isDeleted('openAw'), true);
  assert.equal(guard.isDeleted('encAw'), true);
  assert.equal(guard.isDeleted('userA'), false);
  assert.equal(guard.isDeleted(''), false);
  assert.equal(guard.unattributedOpen, 0);
  const blind = makeDeletionGuard({ appwriteDocs: [{ $id: 'del_abc', userId: 'anonymized_deleted_user', status: 'in_progress' }, { $id: 'del_def', status: 'completed' }] });
  assert.equal(blind.unattributedOpen, 1);
});

test('parseArgs validates options', () => {
  const o = parseArgs(['key', '--dry-run', '--collections', 'review_states,user_mistakes', '--since', '2025-01-01', '--batch', '10']);
  assert.deepEqual(o.collections, ['review_states', 'user_mistakes']);
  assert.equal(o.since, '2025-01-01T00:00:00.000Z');
  assert.throws(() => parseArgs(['key', '--collections', 'users']));
  assert.throws(() => parseArgs(['key', '--batch', '0']));
  assert.throws(() => parseArgs(['key', '--persist-to', 'x']));
  assert.throws(() => parseArgs([]));
});

// ------------------------------------------------------------ mock Appwrite

const SECRET = 'mock-deletion-secret';
const OPEN_DEL_USER = 'openDelUser';

function fixtures() {
  const hashedA1 = reviewRowIdFor('userA', 'w1');
  const rs = (id, userId, itemId, at, extra = {}) => ({
    $id: id, $updatedAt: at, $createdAt: at, userId, itemId, itemType: 'word',
    stateJson: state(itemId, { lastReviewedAt: at, ...extra }), nextReviewAt: '2026-01-02T00:00:00.000Z', lastReviewedAt: at, schemaVersion: 3,
  });
  return {
    review_states: [
      rs('userA__w1', 'userA', 'w1', '2025-03-01T00:00:00.000Z', { winner: 'legacy' }),
      rs(hashedA1, 'userA', 'w1', '2025-02-01T00:00:00.000Z', { winner: 'hashed' }),
      rs(reviewRowIdFor('userA', 'w2'), 'userA', 'w2', '2025-02-01T00:00:00.000Z', { from: 'appwrite' }),
      rs(reviewRowIdFor('deadUser', 'w1'), 'deadUser', 'w1', '2025-02-01T00:00:00.000Z'),
      rs(reviewRowIdFor('ghostUser', 'w1'), 'ghostUser', 'w1', '2025-02-01T00:00:00.000Z'),
    ],
    user_mistakes: [
      { $id: stableId('userA:q1:q1_0'), userId: 'userA', quizId: 'q1', questionId: 'q1_0', questionIndex: 0, wrongAnswer: "it's", correctAnswer: 'b', questionSnapshot: '{}', timesMissed: 2, timesReviewed: 0, isMastered: false, masteredAt: '', lastMissedAt: '2025-01-05T00:00:00.000Z', lastReviewedAt: '' },
      { $id: stableId(`${OPEN_DEL_USER}:q1:q1_0`), userId: OPEN_DEL_USER, quizId: 'q1', questionId: 'q1_0', lastMissedAt: '2025-01-05T00:00:00.000Z' },
    ],
    mistake_review_sessions: [{ $id: 'sessA', sessionId: 'sessA', userId: 'userA', questionIds: '["q1:q1_0"]', score: 1, total: 1, completedAt: '2025-01-06T00:00:00.000Z' }],
    bakhed_listening_progress: [{ $id: stableId('userA:bk1'), userId: 'userA', bakhedId: 'bk1', listenedPercent: 85, completed80Percent: true, completedAt: '2025-01-07T00:00:00.000Z', lastPositionMs: 1200, updatedAt: '2025-01-07T00:00:00.000Z' }],
    user_badges: [{ $id: 'ub1', userId: 'userA', badgeId: 'first_steps', progress: 1, target: 1, isUnlocked: true, unlockedAt: '2025-01-08T00:00:00.000Z', updatedAt: '2025-01-08T00:00:00.000Z' }],
    reward_events: [{ $id: 'rw1', rewardEventId: 'rw1', userId: 'userA', sourceType: 'badge', sourceId: 'first_steps', starsAwarded: 10, badgeId: 'first_steps', reason: 'Unlocked', createdAt: '2025-01-08T00:00:00.000Z' }],
    learning_analytics_events: [
      { $id: 'ae1', $createdAt: daysAgo(2), eventId: 'ev-1', eventName: 'lesson_completed', userId: 'userA', sessionId: 's1', platform: 'android', dateKey: daysAgo(2).slice(0, 10), occurredAt: daysAgo(2), metadata: '{"x":1}' },
      { $id: 'ae2', eventId: 'ev-2', eventName: 'lesson_completed', userId: 'userA', sessionId: 's1', occurredAt: daysAgo(200) },
      { $id: 'ae3', eventId: 'ev-3', eventName: 'app_opened', userId: null, sessionId: 's2', occurredAt: daysAgo(1) },
    ],
    binti_guru_waitlist: [
      { $id: 'wl1', userId: 'userA', fullName: 'Sita Murmu', phoneNumber: '+919876543210', ceremonyType: 'wedding', city: 'Ranchi', state: 'Jharkhand', submittedAt: '2025-01-09T00:00:00.000Z', status: 'new' },
      { $id: 'wl2', fullName: 'X', phoneNumber: '1', ceremonyType: 'wedding', city: 'Ranchi', state: 'Jharkhand', submittedAt: '2025-01-09T00:00:00.000Z' },
    ],
    course_purchases: [
      { $id: 'p1', userId: 'userA', categoryId: 'cat1', provider: 'razorpay', providerOrderId: 'order_1', providerPaymentId: 'pay_1', expectedAmount: 199, paidAmount: 199, currency: 'INR', status: 'verified', verifiedAt: '2025-01-10T00:00:00.000Z' },
      { $id: 'p2', userId: 'userA', categoryId: 'cat2', provider: 'razorpay', providerOrderId: 'order_2', providerPaymentId: 'pay_2', expectedAmount: 299, paidAmount: 299, currency: 'INR', status: 'verified', verifiedAt: '2025-01-10T00:00:00.000Z' },
      { $id: 'p3', userId: 'userA', categoryId: 'cat3', provider: 'razorpay', providerOrderId: 'order_3', expectedAmount: 99, paidAmount: 0, currency: 'INR', status: 'created' },
    ],
    deletion_requests: [
      { $id: `del_${appwritePseudonymousId(OPEN_DEL_USER, SECRET)}`, userId: 'anonymized_deleted_user', pseudonymousId: appwritePseudonymousId(OPEN_DEL_USER, SECRET), encryptedUserId: encryptAppwriteUserId(OPEN_DEL_USER, SECRET), status: 'cleanup_failed' },
    ],
  };
}

function startMockAppwrite({ legacyOnly = false, data = fixtures(), users = ['userA', OPEN_DEL_USER, 'deadUser'] } = {}) {
  const seen = { keys: new Set(), paths: [] };
  const server = createServer((req, res) => {
    const url = new URL(req.url, 'http://x');
    seen.keys.add(req.headers['x-appwrite-key']);
    seen.paths.push(url.pathname);
    const send = (status, body) => { res.writeHead(status, { 'content-type': 'application/json' }); res.end(JSON.stringify(body)); };
    const um = url.pathname.match(/^\/v1\/users\/([^/]+)$/);
    if (um) {
      const id = decodeURIComponent(um[1]);
      return users.includes(id) ? send(200, { $id: id, status: true }) : send(404, { type: 'user_not_found' });
    }
    const tm = url.pathname.match(/^\/v1\/tablesdb\/olitun_db\/tables\/([^/]+)\/rows$/);
    const dm = url.pathname.match(/^\/v1\/databases\/olitun_db\/collections\/([^/]+)\/documents$/);
    if (tm && legacyOnly) return send(404, { type: 'general_route_not_found' });
    const m = tm || dm;
    if (!m) return send(404, { type: 'general_route_not_found' });
    const rows = data[decodeURIComponent(m[1])];
    if (!rows) return send(404, { type: tm ? 'table_not_found' : 'collection_not_found' });
    const queries = url.searchParams.getAll('queries[]').map((q) => JSON.parse(q));
    let list = [...rows];
    let limit = 25;
    for (const q of queries) {
      if (q.method === 'limit') limit = q.values[0];
      if (q.method === 'greaterThanEqual') list = list.filter((r) => (r[q.attribute] || '') >= q.values[0]);
    }
    for (const q of queries) {
      if (q.method === 'cursorAfter') list = list.slice(list.findIndex((r) => r.$id === q.values[0]) + 1);
    }
    list = list.slice(0, limit);
    return send(200, tm ? { total: list.length, rows: list } : { total: list.length, documents: list });
  });
  return new Promise((ok) => server.listen(0, '127.0.0.1', () => ok({ server, seen, endpoint: `http://127.0.0.1:${server.address().port}/v1` })));
}

test('appwriteClient falls back to the legacy documents API and maps 402 to a quota error', async () => {
  const { server, endpoint, seen } = await startMockAppwrite({ legacyOnly: true });
  try {
    const aw = appwriteClient({ endpoint, project: 'p', key: 'k', database: 'olitun_db' });
    const pages = [];
    for await (const items of aw.pages('reward_events')) pages.push(items);
    assert.equal(pages[0][0].$id, 'rw1');
    assert.ok(seen.paths.some((p) => p.includes('/databases/olitun_db/collections/reward_events/documents')));
    assert.equal(await aw.userStatus('userA'), 'ok');
    assert.equal(await aw.userStatus('nobody'), 'missing');
  } finally {
    server.close();
  }
  const quota = createServer((req, res) => { res.writeHead(402, { 'content-type': 'application/json' }); res.end('{"type":"limit_databases_reads_exceeded"}'); });
  await new Promise((ok) => quota.listen(0, '127.0.0.1', ok));
  try {
    const aw = appwriteClient({ endpoint: `http://127.0.0.1:${quota.address().port}/v1`, project: 'p', key: 'k', database: 'olitun_db' });
    await assert.rejects(async () => { for await (const _ of aw.pages('review_states')) { /* drain */ } }, /quota still exhausted/);
  } finally {
    quota.close();
  }
});

// ------------------------------------------------------------ end to end

function runScript(args) {
  return new Promise((ok) => {
    const child = spawn(process.execPath, [SCRIPT, ...args], { cwd: BACKEND });
    let stdout = '';
    let stderr = '';
    child.stdout.on('data', (d) => { stdout += d; });
    child.stderr.on('data', (d) => { stderr += d; });
    child.on('close', (code) => ok({ code, stdout, stderr }));
  });
}

function d1(persist, sql) {
  const res = spawnSync(WRANGLER, ['d1', 'execute', 'olitun-db', '--local', '--persist-to', persist, '--json', '--command', sql], { cwd: BACKEND, encoding: 'utf8' });
  assert.equal(res.status, 0, res.stderr);
  return JSON.parse(res.stdout.slice(res.stdout.indexOf('['))).flatMap((r) => r.results || []);
}

test('end to end: mock Appwrite -> local D1', { timeout: 300_000 }, async () => {
  const dir = mkdtempSync(join(tmpdir(), 'aw-import-e2e-'));
  const persist = join(dir, 'd1');
  const keyFile = join(dir, 'key');
  const secretFile = join(dir, 'secret');
  writeFileSync(keyFile, 'super-secret-api-key\n');
  writeFileSync(secretFile, `${SECRET}\n`);
  const { server, endpoint, seen } = await startMockAppwrite();
  try {
    const schema = spawnSync(WRANGLER, ['d1', 'execute', 'olitun-db', '--local', '--persist-to', persist, '--file', join(BACKEND, 'schema.sql')], { cwd: BACKEND, encoding: 'utf8' });
    assert.equal(schema.status, 0, schema.stderr);
    // Data the learner created on Cloudflare after the migration, plus a D1 deletion.
    const future = new Date(NOW + 60_000).toISOString();
    d1(persist, [
      `INSERT INTO deletion_requests (id, user_id, status, created_at, updated_at) VALUES ('${d1DeletionRequestId('deadUser')}', 'anonymized_deleted_user', 'completed', '${future}', '${future}')`,
      `INSERT INTO review_states (id, user_id, item_id, item_type, state_json, next_review_at, last_reviewed_at, schema_version, version, write_token, updated_at) VALUES ('${reviewRowIdFor('userA', 'w2')}', 'userA', 'w2', 'word', '{"from":"cloudflare"}', '2026-05-01T00:00:00.000Z', '${future}', 3, 4, 't', '${future}')`,
      `INSERT INTO course_purchases (id, user_id, category_id, course_id, amount_in_cents, currency, status, order_id, payment_id, created_at) VALUES ('${stableId('purch:userA:cat2')}', 'userA', 'cat2', 'cat2', 29900, 'INR', 'refunded', 'order_2', 'pay_2', '${future}')`,
    ].join('; '));

    const base = [keyFile, '--endpoint', endpoint, '--project', 'proj', '--local', '--persist-to', persist, '--deletion-secret-file', secretFile];

    // Without the deletion secret the open Appwrite request cannot be attributed: abort.
    const blind = await runScript([keyFile, '--endpoint', endpoint, '--local', '--persist-to', persist, '--dry-run']);
    assert.equal(blind.code, 2, blind.stderr);
    assert.match(blind.stderr, /cannot be attributed/);

    // Dry run: maps, samples, writes nothing.
    const dry = await runScript([...base, '--dry-run']);
    assert.equal(dry.code, 0, dry.stderr);
    const drySummary = JSON.parse(dry.stdout);
    assert.equal(drySummary.collections.review_states.read, 5);
    assert.equal(drySummary.collections.review_states.wouldWrite, 2);
    assert.equal(drySummary.collections.review_states.samples.length, 3);
    const sampleUser = drySummary.collections.review_states.samples[0][0].row.user_id;
    assert.match(sampleUser, /^u_[a-f0-9]{12}$/);
    assert.ok(!dry.stdout.includes('"userA"'), 'raw user ids must not be printed');
    assert.ok(!dry.stdout.includes('Sita Murmu'));
    assert.ok(!(dry.stdout + dry.stderr).includes('super-secret-api-key'));
    assert.equal(d1(persist, 'SELECT count(*) AS n FROM user_mistakes')[0].n, 0);

    // Real run, then a second run to prove idempotency.
    const stateFile = join(dir, 'state.json');
    for (let i = 0; i < 2; i++) {
      const res = await runScript([...base, '--state', stateFile, '--batch', '2']);
      assert.equal(res.code, 0, res.stderr + res.stdout);
      const summary = JSON.parse(res.stdout);
      if (i === 0) {
        const rs = summary.collections.review_states;
        assert.deepEqual({ read: rs.read, written: rs.written, errors: rs.errors }, { read: 5, written: 2, errors: 0 });
        assert.equal(rs.skipReasons.deletion_requested, 1);
        assert.equal(rs.skipReasons.user_missing, 1);
        assert.equal(summary.collections.user_mistakes.skipReasons.deletion_requested, 1);
        assert.equal(summary.collections.learning_analytics_events.skipReasons.expired, 1);
        assert.equal(summary.collections.binti_guru_waitlist.skipReasons.invalid_waitlist_fields, 1);
        assert.equal(summary.collections.course_purchases.skipReasons.not_verified, 1);
      } else {
        assert.equal(summary.collections.review_states.resumed, 'already_done');
      }
    }
    // A fresh run (no state file) over existing data must also be a no-op.
    const again = await runScript(base);
    assert.equal(again.code, 0, again.stderr);

    const reviews = d1(persist, 'SELECT id, user_id, item_id, state_json, updated_at, version FROM review_states ORDER BY item_id');
    assert.equal(reviews.length, 2);
    assert.equal(reviews[0].id, reviewRowIdFor('userA', 'w1'));
    assert.equal(JSON.parse(reviews[0].state_json).winner, 'legacy');
    assert.equal(reviews[0].updated_at, '2025-03-01T00:00:00.000Z');
    assert.equal(reviews[0].version, 1, 'repeat runs do not touch the row');
    assert.equal(reviews[1].state_json, '{"from":"cloudflare"}', 'newer D1 data wins');
    assert.equal(d1(persist, "SELECT count(*) AS n FROM review_states WHERE user_id IN ('deadUser','ghostUser')")[0].n, 0);

    const mistakes = d1(persist, 'SELECT user_id, wrong_answer, times_missed FROM user_mistakes');
    assert.deepEqual(mistakes, [{ user_id: 'userA', wrong_answer: "it's", times_missed: 2 }]);
    assert.equal(d1(persist, 'SELECT count(*) AS n FROM mistake_review_sessions')[0].n, 1);
    assert.deepEqual(d1(persist, 'SELECT listened_percent, completed_80_percent FROM bakhed_listening_progress'), [{ listened_percent: 85, completed_80_percent: 1 }]);
    assert.deepEqual(d1(persist, 'SELECT badge_id, is_unlocked FROM user_badges'), [{ badge_id: 'first_steps', is_unlocked: 1 }]);
    assert.equal(d1(persist, 'SELECT count(*) AS n FROM reward_events')[0].n, 1);
    const events = d1(persist, 'SELECT e.id, e.user_id, d.session_id, d.metadata_json FROM learning_analytics_events e JOIN learning_analytics_event_details d ON d.event_id = e.id ORDER BY e.user_id');
    assert.equal(events.length, 2);
    assert.deepEqual(events.map((e) => e.id), [stableId('analytics::ev-3'), stableId('analytics:userA:ev-1')]);
    assert.equal(events[1].metadata_json, '{"x":1}');
    assert.deepEqual(d1(persist, 'SELECT id, user_id, status FROM binti_waitlist'), [{ id: 'wl1', user_id: 'userA', status: 'new' }]);
    const purchases = d1(persist, 'SELECT category_id, status, amount_in_cents, order_id FROM course_purchases ORDER BY category_id');
    assert.deepEqual(purchases, [
      { category_id: 'cat1', status: 'completed', amount_in_cents: 19900, order_id: 'order_1' },
      { category_id: 'cat2', status: 'refunded', amount_in_cents: 29900, order_id: 'order_2' },
    ]);
    // Nothing for users who asked to be deleted.
    assert.equal(d1(persist, `SELECT count(*) AS n FROM user_mistakes WHERE user_id = '${OPEN_DEL_USER}'`)[0].n, 0);
    assert.deepEqual([...seen.keys], ['super-secret-api-key']);
  } finally {
    server.close();
    rmSync(dir, { recursive: true, force: true });
  }
});
