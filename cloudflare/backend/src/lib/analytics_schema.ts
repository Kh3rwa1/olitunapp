// schema.sql is applied with CREATE TABLE IF NOT EXISTS, so a column added
// to an existing table never reaches a deployed database by itself. This
// guard adds `install_id` to learning_analytics_event_details on first use
// (once per isolate) so ingest and the dashboards work on old and fresh DBs.

export const INSTALL_ID = /^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$/;

const ACTOR_SQL =
  "CASE WHEN e.user_id != '' THEN 'u:' || e.user_id " +
  "WHEN d.install_id IS NOT NULL AND d.install_id != '' THEN 'i:' || d.install_id " +
  "WHEN d.session_id IS NOT NULL THEN 's:' || d.session_id END";

/** SQL for one learner: signed-in user, else install, else session. */
export const ANALYTICS_ACTOR_SQL = ACTOR_SQL;

let ensured: Promise<void> | null = null;

/** Adds the install_id column (and its index) when a database predates it. */
export function ensureAnalyticsInstallColumn(db: D1Database): Promise<void> {
  if (!ensured) {
    ensured = addInstallColumn(db).catch((err) => {
      // Try again on the next request instead of caching a transient failure.
      ensured = null;
      throw err;
    });
  }
  return ensured;
}

/** Test hook: forget the per-isolate "already ensured" state. */
export function resetAnalyticsSchemaCache(): void {
  ensured = null;
}

async function addInstallColumn(db: D1Database): Promise<void> {
  const info = await db.prepare('PRAGMA table_info("learning_analytics_event_details")').all<{ name: string }>();
  const columns = (info.results || []).map((c) => c.name);
  if (!columns.includes('install_id')) {
    await db.prepare('ALTER TABLE learning_analytics_event_details ADD COLUMN install_id TEXT').run();
  }
  await db
    .prepare('CREATE INDEX IF NOT EXISTS idx_analytics_details_install ON learning_analytics_event_details(install_id)')
    .run();
}
