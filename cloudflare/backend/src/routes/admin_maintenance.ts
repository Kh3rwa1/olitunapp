import { stableId, type App, type Bindings } from '../env';
import { adminUserId, auditStatement, changeStatements, readJsonBody } from './admin_common';
import { BACKUP_TABLES, BackupError, createBackup, FILE_ID_PATTERN, WIPE_TABLES } from './admin_backup';
import { runRestore, runRollback } from './admin_restore';
import { recordRefund } from './admin_purchases';

// POST /api/v1/admin/maintenance — the Worker port of the Appwrite
// `admin-maintenance` function. Every action is explicit; an unknown or
// missing action is a 400, never a fake success. Responses keep the
// function's `success` envelope (the admin client parses it) plus `ok`.

export const WIPE_CONFIRMATION = 'WIPE ALL';
export const RESTORE_CONFIRMATION = 'RESTORE CONTENT';

type Outcome = { status: number; body: Record<string, unknown> };

function done(body: Record<string, unknown>, status = 200): Outcome {
  return { status, body: { success: true, ok: true, ...body } };
}

function fail(status: number, message: string): Outcome {
  return { status, body: { success: false, ok: false, message } };
}

async function healthReport(env: Bindings): Promise<Outcome> {
  const results = await env.DB.batch(BACKUP_TABLES.map((t) => env.DB.prepare(`SELECT count(*) AS n FROM ${t}`)));
  const database: Record<string, number> = {};
  BACKUP_TABLES.forEach((t, i) => {
    database[t] = Number((results[i].results?.[0] as any)?.n || 0);
  });
  const active: any = await env.DB.prepare("SELECT job_id, file_id, phase FROM admin_restore_jobs WHERE id = 'active'").first();
  return done({
    status: 'operational',
    database,
    activeRestore: active && active.phase !== 'complete' ? { jobId: active.job_id, fileId: active.file_id, phase: active.phase } : null,
  });
}

async function purgeCaches(env: Bindings, actor: string): Promise<Outcome> {
  const results = await env.DB.batch([
    env.DB.prepare('DELETE FROM translation_cache'),
    env.DB.prepare('DELETE FROM leaderboard_cache'),
    auditStatement(env.DB, { actor, action: 'caches_purged', targetId: 'translation_cache,leaderboard_cache', details: {} }),
  ]);
  return done({
    message: 'Edge caches purged',
    purged: { translation_cache: results[0].meta?.changes || 0, leaderboard_cache: results[1].meta?.changes || 0 },
  });
}

// Tells every polling app to refetch content (e.g. after a manual fix or a
// restore whose change notifications need repeating).
async function contentCacheClear(env: Bindings, actor: string): Promise<Outcome> {
  await env.DB.batch([
    ...changeStatements(env.DB, [...BACKUP_TABLES], '*', 'refresh'),
    auditStatement(env.DB, { actor, action: 'content_cache_cleared', targetId: '*', details: { tables: BACKUP_TABLES } }),
  ]);
  return done({ message: 'Content refresh broadcast to apps.', tables: BACKUP_TABLES });
}

async function wipeContent(env: Bindings, actor: string, body: Record<string, any>): Promise<Outcome> {
  if (body.confirmation !== WIPE_CONFIRMATION) {
    return fail(400, 'Invalid confirmation phrase.');
  }
  const active: any = await env.DB.prepare("SELECT job_id, phase FROM admin_restore_jobs WHERE id = 'active'").first();
  if (active && active.phase !== 'complete') {
    return fail(409, `Restore ${active.job_id} is unfinished. Resume it before wiping content.`);
  }
  // The backup must be stored before anything is deleted.
  const backup = await createBackup(env, actor, { reason: 'wipe_content' });
  const db = env.DB;
  const results = await db.batch([
    ...WIPE_TABLES.map((t) => db.prepare(`DELETE FROM ${t}`)),
    ...changeStatements(db, [...WIPE_TABLES], '*', 'wipe'),
    auditStatement(db, { actor, action: 'content_wiped', targetId: backup.fileId, details: { tables: WIPE_TABLES, backup: backup.key } }),
  ]);
  const deleted: Record<string, number> = {};
  WIPE_TABLES.forEach((t, i) => {
    deleted[t] = results[i].meta?.changes || 0;
  });
  return done({ backup, deleted });
}

async function restoreContent(env: Bindings, actor: string, body: Record<string, any>): Promise<Outcome> {
  const fileId = String(body.fileId || '').trim();
  if (!fileId) return fail(400, 'Missing backup file ID.');
  if (!FILE_ID_PATTERN.test(fileId)) return fail(400, 'Invalid backup file ID.');
  const requested = body.restoreId === undefined || body.restoreId === null ? '' : String(body.restoreId).trim();
  if (requested && !FILE_ID_PATTERN.test(requested)) return fail(400, 'Invalid restore operation ID.');
  const dryRun = body.dryRun === true;
  if (!dryRun && body.confirmation !== RESTORE_CONFIRMATION) {
    return fail(400, `Restoring replaces live content; send confirmation "${RESTORE_CONFIRMATION}" (or dryRun: true to validate).`);
  }
  const jobId = requested || (await stableId(`restore:${fileId}`)).slice(0, 32);
  const result = await runRestore(env, { fileId, jobId, actorUserId: actor, dryRun, action: 'restore_content' });
  return done(result, result.complete ? 200 : 202);
}

async function rollbackRestore(env: Bindings, actor: string, body: Record<string, any>): Promise<Outcome> {
  const restoreId = String(body.restoreId || '').trim();
  if (!restoreId) return fail(400, 'Missing restore operation ID for rollback.');
  const result = await runRollback(env, restoreId, actor);
  return done(
    { ...result, message: result.complete ? 'Rollback completed.' : 'Rollback checkpoint saved; resume the same operation.' },
    result.complete ? 200 : 202,
  );
}

export async function runMaintenanceAction(env: Bindings, actor: string, body: Record<string, any>): Promise<Outcome> {
  const action = typeof body.action === 'string' ? body.action.trim() : '';
  switch (action) {
    case 'status':
    case 'health':
      return healthReport(env);
    case 'purge_cache':
      return purgeCaches(env, actor);
    case 'restore_cache_clear':
      return contentCacheClear(env, actor);
    case 'backup_content':
      return done({ backup: await createBackup(env, actor, { reason: 'backup_content' }) });
    case 'wipe_content':
      return wipeContent(env, actor, body);
    case 'restore_content':
      return restoreContent(env, actor, body);
    case 'rollback_restore':
      return rollbackRestore(env, actor, body);
    case 'record_refund': {
      const outcome = await recordRefund(env, actor, body);
      return { status: outcome.status, body: outcome.body };
    }
    default:
      return fail(400, 'Unsupported admin maintenance action.');
  }
}

export function registerAdminMaintenanceRoutes(app: App): void {
  app.post('/api/v1/admin/maintenance', async (c) => {
    const body = await readJsonBody(c);
    if (!body) return c.json({ success: false, ok: false, message: 'Invalid JSON body.' }, 400);
    try {
      const outcome = await runMaintenanceAction(c.env, adminUserId(c), body);
      return c.json(outcome.body, outcome.status as any);
    } catch (err: any) {
      if (err instanceof BackupError) {
        return c.json({ success: false, ok: false, message: err.message }, err.status as any);
      }
      console.error(`admin maintenance ${String(body.action)} failed: ${err?.message || err}`);
      return c.json({ success: false, ok: false, message: 'Admin maintenance failed.' }, 500);
    }
  });

  // Legacy `backupCollections` route: same backup as backup_content.
  app.post('/api/v1/admin/backup', async (c) => {
    try {
      const backup = await createBackup(c.env, adminUserId(c), { reason: 'backupCollections' });
      return c.json({ success: true, ok: true, backup, backupKey: backup.key, counts: backup.counts });
    } catch (err: any) {
      console.error(`admin backup failed: ${err?.message || err}`);
      return c.json({ success: false, ok: false, message: 'Backup failed.' }, 500);
    }
  });

  // Backups available for restore, newest first.
  app.get('/api/v1/admin/backups', async (c) => {
    try {
      const listing = await c.env.ASSETS.list({ prefix: 'backups/', limit: 1000 });
      const backups = listing.objects
        .map((o) => ({ fileId: o.key.slice('backups/'.length).replace(/\.json$/, ''), key: o.key, bytes: o.size, uploadedAt: o.uploaded.toISOString() }))
        .filter((b) => FILE_ID_PATTERN.test(b.fileId))
        .sort((a, b) => b.uploadedAt.localeCompare(a.uploadedAt));
      return c.json({ ok: true, backups, truncated: listing.truncated });
    } catch (err: any) {
      console.error(`admin backups list failed: ${err?.message || err}`);
      return c.json({ ok: false, message: 'Failed to list backups' }, 500);
    }
  });
}
