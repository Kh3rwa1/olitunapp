import type { App } from '../env';
import { ANONYMIZED_USER_ID, deleteUserAccount } from './account';

export function registerAdminJobRoutes(app: App): void {
  // 27. Manage Admin Access & Audit (replaces Appwrite manageAdminAccess function)
  app.get('/api/v1/admin/audit', async (c) => {
    try {
      const logs: any = await c.env.DB.prepare(
        'SELECT id, admin_user_id, action, target_id, details_json, timestamp FROM admin_audit_logs ORDER BY timestamp DESC LIMIT 100'
      ).all().catch(() => ({ results: [] }));

      return c.json({ ok: true, logs: logs.results || [] });
    } catch (err: any) {
      return c.json({ ok: false, message: err.message || 'Unable to load audit logs' }, 500);
    }
  });

  // 28. Aggregate Learning Analytics (replaces Appwrite aggregateLearningAnalytics function)
  app.post('/api/v1/analytics/aggregate', async (c) => {
    try {
      const body = await c.req.json().catch(() => ({}));
      const dateKey = String(body.dateKey || new Date().toISOString().slice(0, 10)).trim();

      const events: any = await c.env.DB.prepare(
        'SELECT user_id, event_name FROM learning_analytics_events WHERE date_key = ?'
      ).bind(dateKey).all().catch(() => ({ results: [] }));

      const uniqueUsers = new Set<string>();
      const counts: Record<string, number> = {};

      for (const row of events.results || []) {
        if (row.user_id) uniqueUsers.add(row.user_id);
        counts[row.event_name] = (counts[row.event_name] || 0) + 1;
      }

      const rollupId = `rollup_${dateKey}`;
      const now = new Date().toISOString();

      await c.env.DB.prepare(
        'INSERT OR REPLACE INTO learning_analytics_daily_rollups (id, date_key, total_events, unique_users, event_counts_json, created_at) VALUES (?, ?, ?, ?, ?, ?)'
      ).bind(rollupId, dateKey, (events.results || []).length, uniqueUsers.size, JSON.stringify(counts), now).run();

      return c.json({
        ok: true,
        rollup: {
          dateKey,
          totalEvents: (events.results || []).length,
          uniqueUsers: uniqueUsers.size,
          counts,
        }
      });
    } catch (err: any) {
      return c.json({ ok: false, message: err.message || 'Aggregation failed' }, 500);
    }
  });

  // 29. Cleanup Analytics Events (replaces Appwrite cleanupAnalyticsEvents function)
  app.post('/api/v1/analytics/cleanup', async (c) => {
    try {
      const ninetyDaysAgo = new Date(Date.now() - 90 * 86400 * 1000).toISOString().slice(0, 10);
      const [result]: any[] = await c.env.DB.batch([
        c.env.DB.prepare('DELETE FROM learning_analytics_events WHERE date_key < ?').bind(ninetyDaysAgo),
        c.env.DB.prepare('DELETE FROM learning_analytics_event_details WHERE date_key < ?').bind(ninetyDaysAgo),
      ]);

      return c.json({ ok: true, deletedEvents: result.meta?.changes || 0, cutoffDate: ninetyDaysAgo });
    } catch (err: any) {
      return c.json({ ok: false, message: err.message || 'Cleanup failed' }, 500);
    }
  });

  // 30. Reconcile Orphaned Deletions (replaces Appwrite reconcileOrphanedDeletions function)
  // Re-runs the full deletion (data + Appwrite login) for requests that were
  // interrupted, so a request is never marked completed while the login exists.
  app.post('/api/v1/admin/deletions/reconcile', async (c) => {
    try {
      const staleBefore = new Date(Date.now() - 10 * 60 * 1000).toISOString();
      const pending = await c.env.DB.prepare(
        "SELECT id, user_id FROM deletion_requests WHERE status IN ('pending', 'in_progress', 'cleanup_failed', 'cleanup_complete') AND updated_at < ? AND user_id != ? LIMIT 20"
      ).bind(staleBefore, ANONYMIZED_USER_ID).all<{ id: string; user_id: string }>();

      let completed = 0;
      let failed = 0;
      for (const req of pending.results || []) {
        if (!req.user_id) continue;
        const outcome = await deleteUserAccount(c.env, req.user_id);
        if (outcome.status === 200) completed++;
        else failed++;
      }

      return c.json({ ok: true, completedCount: completed, failedCount: failed });
    } catch (err: any) {
      return c.json({ ok: false, message: err.message || 'Deletion reconciliation failed' }, 500);
    }
  });
}
