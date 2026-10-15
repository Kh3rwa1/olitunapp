import type { App } from '../env';

// Public content change feed polled by the apps (replaces Appwrite Realtime
// for content tables). Writers append rows to content_changes; readers ask
// for everything after the last seq they saw.
//
// NOTE: added on feat/cf-admin-tools so the polling client can be tested;
// another branch adds the same contract (and the per-row writes). Keep one
// implementation when merging.

const MAX_CHANGES = 500;

export function registerContentChangesRoutes(app: App): void {
  app.get('/api/v1/content/changes', async (c) => {
    const sinceRaw = (c.req.query('since') || '0').trim();
    const since = Number(sinceRaw);
    if (!/^\d{1,15}$/.test(sinceRaw) || !Number.isSafeInteger(since)) {
      return c.json({ ok: false, error: 'INVALID_INPUT', message: 'since must be a non-negative integer' }, 400);
    }
    try {
      const [rows, latest] = await c.env.DB.batch([
        c.env.DB.prepare(
          'SELECT seq, table_name, row_id, op, changed_at FROM content_changes WHERE seq > ? ORDER BY seq ASC LIMIT ?'
        ).bind(since, MAX_CHANGES),
        c.env.DB.prepare('SELECT COALESCE(MAX(seq), 0) AS latest FROM content_changes'),
      ]);
      return c.json(
        {
          ok: true,
          changes: rows.results || [],
          latest: Number((latest.results?.[0] as any)?.latest || 0),
        },
        200,
        { 'Cache-Control': 'public, max-age=15' },
      );
    } catch (err: any) {
      console.error(`content changes failed: ${err?.message || err}`);
      return c.json({ ok: false, error: 'QUERY_FAILED', message: 'Could not load content changes' }, 500);
    }
  });
}
