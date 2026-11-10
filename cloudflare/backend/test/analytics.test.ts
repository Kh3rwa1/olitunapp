import { describe, expect, it } from 'vitest';
import { ensureAnalyticsInstallColumn, resetAnalyticsSchemaCache } from '../src/lib/analytics_schema';
import { aggregateAnalytics } from '../src/lib/maintenance';
import { callJson, env, makeUser, uid } from './helpers';

const DAY = 86400 * 1000;
// Test storage is shared within a file, so every test owns one past day
// (none used by scheduled.test.ts) and asserts only on that day.
const dayAgo = (days: number) => new Date(Date.now() - days * DAY).toISOString();
const keyOf = (iso: string) => iso.slice(0, 10);

function event(overrides: Record<string, unknown> = {}) {
  return { eventId: uid('evt'), eventName: 'app_open', occurredAt: new Date().toISOString(), ...overrides };
}

async function ingest(events: unknown[], as?: { jwt: string }) {
  return callJson('/api/v1/analytics/events', { json: { events }, as });
}

/** install_id of every stored event tagged with [sourceId] (one per test). */
async function installIds(sourceId: string): Promise<Array<string | null>> {
  const rows = await env.DB.prepare(
    'SELECT d.install_id FROM learning_analytics_events e JOIN learning_analytics_event_details d ON d.event_id = e.id WHERE e.source_id = ?'
  ).bind(sourceId).all<{ install_id: string | null }>();
  return (rows.results || []).map((r) => r.install_id);
}

describe('analytics ingest: install attribution', () => {
  it('stores installId with the event details', async () => {
    const install = uid('inst');
    const sourceId = uid('src');
    const { status, body } = await ingest([event({ sourceId, installId: install, sessionId: uid('s') })]);
    expect(status).toBe(200);
    expect(body).toMatchObject({ ok: true, accepted: 1 });
    expect(await installIds(sourceId)).toEqual([install]);
  });

  it('accepts events without an installId', async () => {
    const sourceId = uid('src');
    const { status } = await ingest([event({ sourceId })]);
    expect(status).toBe(200);
    expect(await installIds(sourceId)).toEqual([null]);
  });

  it('rejects a malformed installId', async () => {
    const sourceId = uid('src');
    const { status, body } = await ingest([event({ sourceId, installId: 'bad id with spaces!' })]);
    expect(status).toBe(400);
    expect(body.errors[0].message).toMatch(/installId/);
    expect(await installIds(sourceId)).toEqual([]);
  });

  it('adds the install_id column to a database that predates it', async () => {
    await env.DB.prepare('DROP INDEX IF EXISTS idx_analytics_details_install').run();
    await env.DB.prepare('ALTER TABLE learning_analytics_event_details DROP COLUMN install_id').run();
    resetAnalyticsSchemaCache();

    await ensureAnalyticsInstallColumn(env.DB);
    const info = await env.DB.prepare('PRAGMA table_info("learning_analytics_event_details")').all<{ name: string }>();
    expect((info.results || []).map((c) => c.name)).toContain('install_id');

    const install = uid('inst');
    const sourceId = uid('src');
    const { status } = await ingest([event({ sourceId, installId: install })]);
    expect(status).toBe(200);
    expect(await installIds(sourceId)).toEqual([install]);
  });
});

describe('analytics learners: user, else install, else session', () => {
  it('snapshot reports one actor-day per install across its sessions', async () => {
    const occurredAt = dayAgo(21);
    const day = keyOf(occurredAt);
    const admin = makeUser('admin');
    const user = makeUser();
    const install = uid('inst');
    const sessionOnly = uid('sess');
    await ingest([
      event({ occurredAt, installId: install, sessionId: uid('s') }),
      event({ occurredAt, installId: install, sessionId: uid('s') }),
    ]);
    await ingest([event({ occurredAt, sessionId: sessionOnly })]);
    await ingest([event({ occurredAt, installId: uid('inst'), sessionId: uid('s') })], user);

    const { status, body } = await callJson(`/api/v1/admin/analytics/snapshot?start=${day}&end=${day}`, { as: admin });
    expect(status).toBe(200);
    const rollup = body.rollups.find((r: any) => r.eventName === 'app_open' && r.dateKey === day);
    expect(rollup).toMatchObject({ totalEvents: 4, uniqueUsers: 3 });

    const rows = body.events as Array<{ dateKey: string; userId: string | null; installId: string | null; sessionId: string | null }>;
    expect(rows).toHaveLength(3);
    expect(rows.filter((r) => r.installId === install)).toEqual([{ dateKey: day, userId: null, installId: install, sessionId: null }]);
    expect(rows.find((r) => r.sessionId === sessionOnly)).toMatchObject({ userId: null, installId: null });
    // A signed-in user is counted by account, never by their install.
    expect(rows.filter((r) => r.userId === user.id)).toEqual([{ dateKey: day, userId: user.id, installId: null, sessionId: null }]);
  });

  it('daily rollup counts guests by install and session instead of dropping them', async () => {
    const occurredAt = dayAgo(22);
    const install = uid('inst');
    await ingest([
      event({ occurredAt, installId: install, sessionId: uid('s') }),
      event({ occurredAt, installId: install, sessionId: uid('s') }),
    ]);
    await ingest([event({ occurredAt, sessionId: uid('s') })]);
    await ingest([event({ occurredAt, eventName: 'lesson_completed' })], makeUser());

    const rollup = await aggregateAnalytics(env.DB, keyOf(occurredAt));
    expect(rollup).toMatchObject({ totalEvents: 4, uniqueUsers: 3, counts: { app_open: 3, lesson_completed: 1 } });
  });
});
