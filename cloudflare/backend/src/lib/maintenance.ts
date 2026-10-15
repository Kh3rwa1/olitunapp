// Maintenance jobs shared by the admin HTTP routes and the Cron Trigger
// handler (src/scheduled.ts). Each takes the D1 handle plus an explicit
// clock so tests and both callers run the same code.

const DAY_MS = 86400 * 1000;

export const ANALYTICS_RETENTION_DAYS = 90;
export const PAYMENT_ORDER_STALE_MS = 3600 * 1000;
// Cache retention. Rows are only a lookup shortcut and are rebuilt on demand.
export const CACHE_RETENTION_DAYS = {
  leaderboard: 30, // leaderboard_cache.updated_at (epoch ms)
  tts: 180, // tts_cache.created_at (ISO); R2 audio is keyed by content and kept
  translation: 180, // translation_cache.created_at (epoch ms)
} as const;

export type AnalyticsRollup = { dateKey: string; totalEvents: number; uniqueUsers: number; counts: Record<string, number> };

/** Rolls up learning_analytics_events for one UTC day (YYYY-MM-DD). */
export async function aggregateAnalytics(db: D1Database, dateKey: string, now = new Date()): Promise<AnalyticsRollup> {
  const events: any = await db.prepare(
    'SELECT user_id, event_name FROM learning_analytics_events WHERE date_key = ?'
  ).bind(dateKey).all().catch(() => ({ results: [] }));

  const uniqueUsers = new Set<string>();
  const counts: Record<string, number> = {};
  for (const row of events.results || []) {
    if (row.user_id) uniqueUsers.add(row.user_id);
    counts[row.event_name] = (counts[row.event_name] || 0) + 1;
  }
  const totalEvents = (events.results || []).length;

  await db.prepare(
    'INSERT OR REPLACE INTO learning_analytics_daily_rollups (id, date_key, total_events, unique_users, event_counts_json, created_at) VALUES (?, ?, ?, ?, ?, ?)'
  ).bind(`rollup_${dateKey}`, dateKey, totalEvents, uniqueUsers.size, JSON.stringify(counts), now.toISOString()).run();

  return { dateKey, totalEvents, uniqueUsers: uniqueUsers.size, counts };
}

/** Deletes analytics events (and their details) older than the retention window. */
export async function cleanupAnalytics(db: D1Database, now = new Date(), retentionDays = ANALYTICS_RETENTION_DAYS) {
  const cutoffDate = new Date(now.getTime() - retentionDays * DAY_MS).toISOString().slice(0, 10);
  const [events, details] = await db.batch([
    db.prepare('DELETE FROM learning_analytics_events WHERE date_key < ?').bind(cutoffDate),
    db.prepare('DELETE FROM learning_analytics_event_details WHERE date_key < ?').bind(cutoffDate),
  ]);
  return { cutoffDate, deletedEvents: events.meta?.changes || 0, deletedDetails: details.meta?.changes || 0 };
}

/** Marks payment orders still `created` after [staleMs] as abandoned. */
export async function reconcilePaymentOrders(db: D1Database, now = new Date(), staleMs = PAYMENT_ORDER_STALE_MS) {
  const staleBefore = new Date(now.getTime() - staleMs).toISOString();
  const expired: any = await db.prepare(
    "SELECT order_id FROM payment_orders WHERE status = 'created' AND created_at < ? LIMIT 50"
  ).bind(staleBefore).all().catch(() => ({ results: [] }));

  const ids: string[] = (expired.results || []).map((o: any) => o.order_id);
  if (ids.length === 0) return { reconciledCount: 0 };
  // The status guard keeps an order verified since the SELECT from being clobbered.
  const results = await db.batch(ids.map((orderId) =>
    db.prepare("UPDATE payment_orders SET status = 'abandoned', updated_at = ? WHERE order_id = ? AND status = 'created'")
      .bind(now.toISOString(), orderId)
  ));
  return { reconciledCount: results.reduce((n, r) => n + (r.meta?.changes || 0), 0) };
}

/** Deletes cache rows past their retention window. Never touches R2 objects. */
export async function expireCaches(db: D1Database, now = new Date(), retention = CACHE_RETENTION_DAYS) {
  const cutoffMs = (days: number) => now.getTime() - days * DAY_MS;
  const [leaderboard, tts, translation] = await db.batch([
    db.prepare('DELETE FROM leaderboard_cache WHERE updated_at < ?').bind(cutoffMs(retention.leaderboard)),
    db.prepare('DELETE FROM tts_cache WHERE created_at < ?').bind(new Date(cutoffMs(retention.tts)).toISOString()),
    db.prepare('DELETE FROM translation_cache WHERE created_at < ?').bind(cutoffMs(retention.translation)),
  ]);
  return {
    leaderboard: leaderboard.meta?.changes || 0,
    tts: tts.meta?.changes || 0,
    translation: translation.meta?.changes || 0,
  };
}

/** The UTC calendar day before [now], as YYYY-MM-DD. */
export function previousUtcDay(now = new Date()): string {
  return new Date(now.getTime() - DAY_MS).toISOString().slice(0, 10);
}
