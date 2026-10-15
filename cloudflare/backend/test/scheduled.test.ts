import { createExecutionContext, createScheduledController, waitOnExecutionContext } from 'cloudflare:test';
import { describe, expect, it } from 'vitest';
import { stableId } from '../src/env';
import worker from '../src/index';
import { ANONYMIZED_USER_ID } from '../src/routes/account';
import { CRON_DAILY, CRON_HOURLY, runCron } from '../src/scheduled';
import wrangler from '../wrangler.json';
import { callJson, env, makeUser, outbound, uid } from './helpers';

const HOUR = 3600 * 1000;
const DAY = 24 * HOUR;
const iso = (msAgo: number) => new Date(Date.now() - msAgo).toISOString();
const dayKey = (msAgo: number) => iso(msAgo).slice(0, 10);

async function fireCron(cron: string, overrides: Record<string, unknown> = {}) {
  const controller = createScheduledController({ cron, scheduledTime: Date.now() });
  const ctx = createExecutionContext();
  await worker.scheduled(controller, { ...env, ...overrides } as any, ctx);
  await waitOnExecutionContext(ctx);
}

async function insertOrder(status: string, createdMsAgo: number) {
  const orderId = uid('order');
  await env.DB.prepare(
    'INSERT INTO payment_orders (order_id, user_id, category_id, amount, currency, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
  ).bind(orderId, uid('u'), uid('cat'), 19900, 'INR', status, iso(createdMsAgo), iso(createdMsAgo)).run();
  return orderId;
}

const orderStatus = async (orderId: string) =>
  (await env.DB.prepare('SELECT status FROM payment_orders WHERE order_id = ?').bind(orderId).first<any>()).status;

async function insertEvent(dateKey: string, eventName = 'lesson_completed', userId = uid('u')) {
  const id = uid('evt');
  await env.DB.batch([
    env.DB.prepare('INSERT INTO learning_analytics_events (id, user_id, event_name, date_key, created_at) VALUES (?, ?, ?, ?, ?)')
      .bind(id, userId, eventName, dateKey, new Date().toISOString()),
    env.DB.prepare('INSERT INTO learning_analytics_event_details (event_id, user_id, date_key) VALUES (?, ?, ?)').bind(id, userId, dateKey),
  ]);
  return id;
}

async function exists(sql: string, id: string): Promise<boolean> {
  return (await env.DB.prepare(sql).bind(id).first()) !== null;
}

// A user with D1 rows and an R2 upload, plus a stale deletion request.
async function interruptedDeletion(status: string, updatedMsAgo: number) {
  const user = makeUser();
  await callJson('/api/v1/mistakes/record', { as: user, json: { quizId: uid('quiz'), questionIndex: 0, wrongAnswer: 'a', correctAnswer: 'b' } });
  await env.ASSETS.put(`users/${user.id}/avatar.png`, 'x');
  // Same id the deletion flow derives, as for a real interrupted request.
  const requestId = `del_${await stableId(`deletion:${user.id}`)}`;
  await env.DB.prepare(
    'INSERT INTO deletion_requests (id, user_id, status, last_error, created_at, updated_at) VALUES (?, ?, ?, NULL, ?, ?)'
  ).bind(requestId, user.id, status, iso(updatedMsAgo), iso(updatedMsAgo)).run();
  return user;
}

const mistakes = async (userId: string) =>
  ((await env.DB.prepare('SELECT COUNT(*) AS n FROM user_mistakes WHERE user_id = ?').bind(userId).first<any>()).n as number);

const requestRow = (userId: string) =>
  env.DB.prepare('SELECT status, last_error FROM deletion_requests WHERE user_id = ?').bind(userId).first<any>();

it('schedules every cron the handler dispatches', () => {
  expect(wrangler.triggers.crons).toEqual([CRON_HOURLY, CRON_DAILY]);
});

describe('hourly cron', () => {
  it('abandons created orders older than an hour, keeps fresh and paid ones', async () => {
    const stale = await insertOrder('created', 2 * HOUR);
    const fresh = await insertOrder('created', 10 * 60 * 1000);
    const paid = await insertOrder('paid', 3 * HOUR);
    await fireCron(CRON_HOURLY);
    expect(await orderStatus(stale)).toBe('abandoned');
    expect(await orderStatus(fresh)).toBe('created');
    expect(await orderStatus(paid)).toBe('paid');
  });

  it('re-runs the data purge for stale requests without marking the login removed', async () => {
    const stale = await interruptedDeletion('cleanup_failed', 2 * HOUR);
    const stuck = await interruptedDeletion('in_progress', 3 * HOUR);
    const active = await interruptedDeletion('in_progress', 5 * 60 * 1000);
    expect(await mistakes(stale.id)).toBeGreaterThan(0);

    await fireCron(CRON_HOURLY, { APPWRITE_API_KEY: undefined });

    for (const user of [stale, stuck]) {
      expect(await mistakes(user.id)).toBe(0);
      expect(await env.ASSETS.head(`users/${user.id}/avatar.png`)).toBeNull();
      // Data gone, login still present: never reported as completed.
      expect(await requestRow(user.id)).toMatchObject({ status: 'cleanup_complete', last_error: null });
    }
    // A request still in flight is left to its own run.
    expect(await mistakes(active.id)).toBeGreaterThan(0);
    expect(await requestRow(active.id)).toMatchObject({ status: 'in_progress' });
    expect(outbound.callsTo('/users/')).toHaveLength(0);
    expect(outbound.callsTo('/account/status')).toHaveLength(0);
  });

  it('finishes the deletion, login included, when the server key is configured', async () => {
    const user = await interruptedDeletion('cleanup_failed', 2 * HOUR);
    await fireCron(CRON_HOURLY, { APPWRITE_API_KEY: 'server-key' });
    expect(await mistakes(user.id)).toBe(0);
    expect(outbound.callsTo(`/users/${user.id}`)).toHaveLength(1);
    expect(await requestRow(user.id)).toBeNull();
    const done = await env.DB.prepare("SELECT COUNT(*) AS n FROM deletion_requests WHERE user_id = ? AND status = 'completed'")
      .bind(ANONYMIZED_USER_ID).first<any>();
    expect(done.n).toBeGreaterThan(0);
  });
});

describe('daily cron', () => {
  it('rolls up the previous UTC day and drops analytics older than 90 days', async () => {
    const yesterday = dayKey(DAY);
    const old = await insertEvent(dayKey(100 * DAY));
    const recent = await insertEvent(dayKey(10 * DAY));
    const learner = uid('u');
    await insertEvent(yesterday, 'lesson_completed', learner);
    await insertEvent(yesterday, 'lesson_completed', learner);
    await insertEvent(yesterday, 'quiz_started');

    await fireCron(CRON_DAILY);

    expect(await exists('SELECT 1 FROM learning_analytics_events WHERE id = ?', old)).toBe(false);
    expect(await exists('SELECT 1 FROM learning_analytics_event_details WHERE event_id = ?', old)).toBe(false);
    expect(await exists('SELECT 1 FROM learning_analytics_events WHERE id = ?', recent)).toBe(true);
    expect(await exists('SELECT 1 FROM learning_analytics_event_details WHERE event_id = ?', recent)).toBe(true);

    const rollup = await env.DB.prepare('SELECT * FROM learning_analytics_daily_rollups WHERE date_key = ?').bind(yesterday).first<any>();
    expect(rollup).toMatchObject({ total_events: 3, unique_users: 2 });
    expect(JSON.parse(rollup.event_counts_json)).toEqual({ lesson_completed: 2, quiz_started: 1 });
  });

  it('expires old cache rows and keeps fresh ones and the R2 audio', async () => {
    const now = Date.now();
    const lbOld = uid('wk');
    const lbNew = uid('wk');
    const ttsOld = uid('tts');
    const ttsNew = uid('tts');
    const trOld = uid('tr');
    const trNew = uid('tr');
    await env.ASSETS.put(`voice/${ttsOld}.wav`, 'audio');
    await env.DB.batch([
      env.DB.prepare('INSERT INTO leaderboard_cache (id, week_id, data_json, updated_at) VALUES (?, ?, ?, ?)').bind(lbOld, lbOld, '{}', now - 31 * DAY),
      env.DB.prepare('INSERT INTO leaderboard_cache (id, week_id, data_json, updated_at) VALUES (?, ?, ?, ?)').bind(lbNew, lbNew, '{}', now - DAY),
      env.DB.prepare('INSERT INTO tts_cache (cache_key, text_hash, voice_id, audio_url, created_at) VALUES (?, ?, ?, ?, ?)').bind(ttsOld, ttsOld, 'v', 'https://x/a.wav', iso(181 * DAY)),
      env.DB.prepare('INSERT INTO tts_cache (cache_key, text_hash, voice_id, audio_url, created_at) VALUES (?, ?, ?, ?, ?)').bind(ttsNew, ttsNew, 'v', 'https://x/b.wav', iso(30 * DAY)),
      env.DB.prepare("INSERT INTO translation_cache (cache_key, from_lang, to_lang, source_text, translated_text, engine, created_at) VALUES (?, 'en', 'sat', 'a', 'b', 'google', ?)").bind(trOld, now - 181 * DAY),
      env.DB.prepare("INSERT INTO translation_cache (cache_key, from_lang, to_lang, source_text, translated_text, engine, created_at) VALUES (?, 'en', 'sat', 'a', 'b', 'google', ?)").bind(trNew, now - 30 * DAY),
    ]);

    await fireCron(CRON_DAILY);

    expect(await exists('SELECT 1 FROM leaderboard_cache WHERE id = ?', lbOld)).toBe(false);
    expect(await exists('SELECT 1 FROM leaderboard_cache WHERE id = ?', lbNew)).toBe(true);
    expect(await exists('SELECT 1 FROM tts_cache WHERE cache_key = ?', ttsOld)).toBe(false);
    expect(await exists('SELECT 1 FROM tts_cache WHERE cache_key = ?', ttsNew)).toBe(true);
    expect(await exists('SELECT 1 FROM translation_cache WHERE cache_key = ?', trOld)).toBe(false);
    expect(await exists('SELECT 1 FROM translation_cache WHERE cache_key = ?', trNew)).toBe(true);
    expect(await env.ASSETS.head(`voice/${ttsOld}.wav`)).not.toBeNull();
  });

  it('keeps running the other jobs when one fails', async () => {
    const old = await insertEvent(dayKey(120 * DAY));
    // Rollup writes fail; cleanup and cache expiry must still run.
    const db = new Proxy(env.DB, {
      get(target, prop) {
        if (prop === 'prepare') {
          return (sql: string) => {
            if (sql.includes('learning_analytics_daily_rollups')) throw new Error('rollup table unavailable');
            return target.prepare(sql);
          };
        }
        const value = (target as any)[prop];
        return typeof value === 'function' ? value.bind(target) : value;
      },
    });
    const summary: any = await runCron(CRON_DAILY, { ...env, DB: db } as any);
    expect(summary['analytics.aggregate']).toMatchObject({ ok: false, error: 'rollup table unavailable' });
    expect(summary['analytics.cleanup']).toMatchObject({ ok: true });
    expect(summary['caches.expire']).toMatchObject({ ok: true });
    expect(await exists('SELECT 1 FROM learning_analytics_events WHERE id = ?', old)).toBe(false);
  });

  it('ignores an unknown schedule', async () => {
    const stale = await insertOrder('created', 5 * HOUR);
    expect(await runCron('0 0 1 1 *', env as any)).toEqual({});
    expect(await orderStatus(stale)).toBe('created');
  });
});
