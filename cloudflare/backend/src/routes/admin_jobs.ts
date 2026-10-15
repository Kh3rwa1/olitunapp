import type { App } from '../env';
import { aggregateAnalytics, cleanupAnalytics } from '../lib/maintenance';
import { reconcileDeletions } from './account';

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
      const rollup = await aggregateAnalytics(c.env.DB, dateKey);
      return c.json({ ok: true, rollup });
    } catch (err: any) {
      return c.json({ ok: false, message: err.message || 'Aggregation failed' }, 500);
    }
  });

  // 29. Cleanup Analytics Events (replaces Appwrite cleanupAnalyticsEvents function)
  app.post('/api/v1/analytics/cleanup', async (c) => {
    try {
      const { deletedEvents, cutoffDate } = await cleanupAnalytics(c.env.DB);
      return c.json({ ok: true, deletedEvents, cutoffDate });
    } catch (err: any) {
      return c.json({ ok: false, message: err.message || 'Cleanup failed' }, 500);
    }
  });

  // 30. Reconcile Orphaned Deletions (replaces Appwrite reconcileOrphanedDeletions function)
  // Re-runs interrupted requests (see reconcileDeletions): the full deletion
  // when the server key is configured, otherwise only the data purge, so a
  // request is never marked completed while the login exists.
  app.post('/api/v1/admin/deletions/reconcile', async (c) => {
    try {
      const { completed, failed } = await reconcileDeletions(c.env, { staleMs: 10 * 60 * 1000 });
      return c.json({ ok: true, completedCount: completed, failedCount: failed });
    } catch (err: any) {
      return c.json({ ok: false, message: err.message || 'Deletion reconciliation failed' }, 500);
    }
  });
}
