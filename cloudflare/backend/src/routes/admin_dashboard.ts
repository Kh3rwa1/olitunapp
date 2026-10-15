import type { App } from '../env';

// Read-only admin dashboards over D1 (replaces direct Appwrite reads by the
// admin dashboard, analytics screen and gamification ops views).

const ACTIVITY_TABLES = ['lessons', 'categories', 'words', 'letters', 'numbers', 'banners'] as const;
const ACTIVITY_LIMIT = 50;
// Fields the dashboard's activity feed renders; everything else in a
// document (lesson blocks, quiz questions) stays on the server.
const ACTIVITY_FIELDS = [
  '$createdAt', '$updatedAt', 'createdAt', 'updatedAt', 'titleLatin', 'titleOlChiki', 'wordLatin', 'wordOlChiki',
  'meaning', 'transliterationLatin', 'charOlChiki', 'value', 'nameLatin', 'numeral', 'title', 'subtitle',
];
const MAX_RANGE_DAYS = 366;
const MAX_ACTOR_DAYS = 50_000;
const DATE_KEY = /^\d{4}-\d{2}-\d{2}$/;

// D1 tables the gamification/analytics features depend on.
export const SCHEMA_TABLES = [
  'badges', 'user_badges', 'gamification_content', 'admin_audit_logs', 'learning_analytics_events',
  'learning_analytics_event_details', 'learning_analytics_daily_rollups', 'reward_events', 'user_mistakes',
  'mistake_review_sessions', 'bakhed_content', 'bakhed_listening_progress', 'course_purchases', 'payment_orders',
  'purchase_refunds', 'refund_claims', 'admin_restore_jobs', 'content_changes',
];

function pickActivity(id: string, raw: string): Record<string, unknown> | null {
  let doc: any;
  try {
    doc = JSON.parse(raw);
  } catch (_) {
    return null;
  }
  if (!doc || typeof doc !== 'object') return null;
  const out: Record<string, unknown> = { id, $id: id };
  for (const field of ACTIVITY_FIELDS) if (doc[field] !== undefined) out[field] = doc[field];
  return out;
}

function countOf(result: D1Result): number {
  return Number((result.results?.[0] as any)?.n || 0);
}

function bakhedCounts(rows: any[]) {
  let lyrics = 0;
  let vocabulary = 0;
  let publishedNotes = 0;
  for (const row of rows) {
    let doc: any;
    try {
      doc = JSON.parse(row.raw_json);
    } catch (_) {
      continue;
    }
    if (Array.isArray(doc?.lyrics)) lyrics += doc.lyrics.length;
    if (Array.isArray(doc?.vocabulary)) vocabulary += doc.vocabulary.length;
    if (Array.isArray(doc?.culturalNotes)) publishedNotes += doc.culturalNotes.filter((n: any) => n?.isPublished === true).length;
  }
  return { lyrics, vocabulary, publishedNotes };
}

export function registerAdminDashboardRoutes(app: App): void {
  // Most recently changed rows per content table (dashboard activity feed
  // and 7-day authoring chart).
  app.get('/api/v1/admin/dashboard/activity', async (c) => {
    try {
      const db = c.env.DB;
      const order = `COALESCE(json_extract(raw_json, '$."$updatedAt"'), json_extract(raw_json, '$.updatedAt'), json_extract(raw_json, '$."$createdAt"'), '')`;
      const results = await db.batch(
        ACTIVITY_TABLES.map((t) => db.prepare(`SELECT id, raw_json FROM ${t} ORDER BY ${order} DESC LIMIT ?`).bind(ACTIVITY_LIMIT)),
      );
      const collections: Record<string, unknown[]> = {};
      ACTIVITY_TABLES.forEach((t, i) => {
        collections[t] = (results[i].results || [])
          .map((r: any) => pickActivity(String(r.id), String(r.raw_json)))
          .filter((r) => r !== null);
      });
      return c.json({ ok: true, collections });
    } catch (err: any) {
      console.error(`dashboard activity failed: ${err?.message || err}`);
      return c.json({ ok: false, message: 'Failed to load dashboard activity' }, 500);
    }
  });

  // Learning analytics for a date range: per-day/per-event rollups computed
  // from raw events (with source/platform breakdowns) plus distinct
  // actor-days for DAU/WAU/MAU and retention.
  app.get('/api/v1/admin/analytics/snapshot', async (c) => {
    const start = (c.req.query('start') || '').trim();
    const end = (c.req.query('end') || '').trim();
    if (!DATE_KEY.test(start) || !DATE_KEY.test(end) || start > end) {
      return c.json({ ok: false, message: 'start and end must be YYYY-MM-DD with start <= end' }, 400);
    }
    if ((Date.parse(end) - Date.parse(start)) / 86_400_000 > MAX_RANGE_DAYS) {
      return c.json({ ok: false, message: `Range is limited to ${MAX_RANGE_DAYS} days` }, 400);
    }
    try {
      const db = c.env.DB;
      const from = 'FROM learning_analytics_events e LEFT JOIN learning_analytics_event_details d ON d.event_id = e.id WHERE e.date_key BETWEEN ? AND ?';
      const actor = "CASE WHEN e.user_id != '' THEN 'u:' || e.user_id WHEN d.session_id IS NOT NULL THEN 's:' || d.session_id END";
      const [totals, sources, platforms, actors] = await db.batch([
        db.prepare(`SELECT e.date_key AS dateKey, e.event_name AS eventName, count(*) AS total, count(DISTINCT ${actor}) AS users ${from} GROUP BY 1, 2`).bind(start, end),
        db.prepare(`SELECT e.date_key AS dateKey, e.event_name AS eventName, COALESCE(d.source, 'app') AS k, count(*) AS n ${from} GROUP BY 1, 2, 3`).bind(start, end),
        db.prepare(`SELECT e.date_key AS dateKey, e.event_name AS eventName, COALESCE(d.platform, 'unknown') AS k, count(*) AS n ${from} GROUP BY 1, 2, 3`).bind(start, end),
        db.prepare(
          `SELECT DISTINCT e.date_key AS dateKey, NULLIF(e.user_id, '') AS userId, CASE WHEN e.user_id = '' THEN d.session_id END AS sessionId ${from} AND (e.user_id != '' OR d.session_id IS NOT NULL) LIMIT ?`
        ).bind(start, end, MAX_ACTOR_DAYS + 1),
      ]);
      const rollups = new Map<string, any>();
      for (const row of (totals.results || []) as any[]) {
        rollups.set(`${row.dateKey}|${row.eventName}`, {
          dateKey: row.dateKey, eventName: row.eventName, totalEvents: row.total, uniqueUsers: row.users,
          sourceBreakdown: {} as Record<string, number>, platformBreakdown: {} as Record<string, number>,
        });
      }
      for (const row of (sources.results || []) as any[]) {
        const r = rollups.get(`${row.dateKey}|${row.eventName}`);
        if (r) r.sourceBreakdown[row.k] = row.n;
      }
      for (const row of (platforms.results || []) as any[]) {
        const r = rollups.get(`${row.dateKey}|${row.eventName}`);
        if (r) r.platformBreakdown[row.k] = row.n;
      }
      const actorRows = (actors.results || []) as any[];
      return c.json({
        ok: true,
        start,
        end,
        rollups: [...rollups.values()].sort((a, b) => b.dateKey.localeCompare(a.dateKey)),
        events: actorRows.slice(0, MAX_ACTOR_DAYS),
        eventsTruncated: actorRows.length > MAX_ACTOR_DAYS,
      });
    } catch (err: any) {
      console.error(`analytics snapshot failed: ${err?.message || err}`);
      return c.json({ ok: false, message: 'Failed to load analytics' }, 500);
    }
  });

  // Counters for the gamification "Learning Health" ops view.
  app.get('/api/v1/admin/gamification/metrics', async (c) => {
    try {
      const db = c.env.DB;
      const today = new Date().toISOString().slice(0, 10);
      const eventCount = (name: string) =>
        db.prepare('SELECT count(*) AS n FROM learning_analytics_events WHERE event_name = ?').bind(name);
      const results = await db.batch([
        db.prepare('SELECT count(*) AS n FROM learning_analytics_events WHERE date_key = ?').bind(today),
        eventCount('lesson_completed'),
        eventCount('quiz_attempted'),
        eventCount('streak_milestone'),
        db.prepare('SELECT count(*) AS n FROM learning_analytics_daily_rollups'),
        db.prepare('SELECT count(*) AS n FROM user_badges WHERE is_unlocked = 1'),
        db.prepare('SELECT count(*) AS n FROM mistake_review_sessions'),
        db.prepare('SELECT count(*) AS n FROM user_mistakes WHERE is_mastered = 0'),
        db.prepare('SELECT count(*) AS n FROM bakhed_listening_progress WHERE completed_80_percent = 1'),
        db.prepare('SELECT raw_json FROM bakhed_content'),
      ]);
      const bakhed = bakhedCounts(results[9].results || []);
      return c.json({
        ok: true,
        metrics: {
          learningEventsToday: countOf(results[0]),
          lessonsCompleted: countOf(results[1]),
          quizAttempts: countOf(results[2]),
          streakMilestones: countOf(results[3]),
          dailyRollups: countOf(results[4]),
          unlockedBadges: countOf(results[5]),
          mistakeReviewsCompleted: countOf(results[6]),
          mistakesNeedingPractice: countOf(results[7]),
          bakhedCompletions: countOf(results[8]),
          bakhedLyricLines: bakhed.lyrics,
          bakhedVocabularyWords: bakhed.vocabulary,
          publishedCulturalNotes: bakhed.publishedNotes,
        },
      });
    } catch (err: any) {
      console.error(`gamification metrics failed: ${err?.message || err}`);
      return c.json({ ok: false, message: 'Failed to load metrics' }, 500);
    }
  });

  // Which backing D1 tables exist (maintenance "schema health").
  app.get('/api/v1/admin/health/schema', async (c) => {
    try {
      const rows = await c.env.DB.prepare(
        `SELECT name FROM sqlite_master WHERE type = 'table' AND name IN (${SCHEMA_TABLES.map(() => '?').join(', ')})`
      ).bind(...SCHEMA_TABLES).all();
      const present = new Set((rows.results || []).map((r: any) => String(r.name)));
      return c.json({ ok: true, tables: Object.fromEntries(SCHEMA_TABLES.map((t) => [t, present.has(t)])) });
    } catch (err: any) {
      console.error(`schema health failed: ${err?.message || err}`);
      return c.json({ ok: false, message: 'Failed to check schema' }, 500);
    }
  });
}
