import { stableId, type Bindings } from '../env';
import { auditStatement, changeStatements } from './admin_common';
import {
  BACKUP_TABLES,
  BackupError,
  backupKey,
  createBackup,
  FILE_ID_PATTERN,
  readBackup,
  safetyFileId,
  type BackupPayload,
} from './admin_backup';

// Resumable content restore from an R2 backup (port of
// the former Appwrite admin-maintenance resumable restore to D1).
//
// - dryRun validates the backup and reports counts without writing.
// - A real restore first takes a deterministic safety backup, then replaces
//   each table in chunks. Every chunk commits in one D1 batch together with
//   its checkpoint, fenced on the journal sequence number, so two requests
//   resuming the same restore can never both apply a chunk.
// - Only one restore may be unfinished at a time (journal row 'active').
// - rollback_restore restores the safety backup recorded for a restore.

const ACTIVE_ID = 'active';
const CHUNK_ROWS = 400;
const MAX_BOUND_PARAMS = 100;
const FENCE_PARAMS = 2;
const REQUEST_BUDGET_MS = 10_000;
const REQUEST_STATEMENT_BUDGET = 400;

type RestoreState = {
  version: 1;
  seq: number;
  jobId: string;
  fileId: string;
  digest: string;
  safetyFileId: string;
  phase: 'prepare' | 'restoring' | 'complete';
  tableIndex: number;
  offset: number;
  backup: { fileId: string } | null;
  deleted: Record<string, number>;
  restored: Record<string, number>;
  actorUserId: string;
  createdAt: string;
  completedAt?: string;
};

const FENCE_SQL =
  "EXISTS (SELECT 1 FROM admin_restore_jobs WHERE id = 'active' AND job_id = ? AND json_extract(state_json, '$.seq') = ?)";

function historyId(jobId: string): string {
  return `job:${jobId}`;
}

function conflict(message: string): BackupError {
  return new BackupError(message, 409);
}

function parseState(row: any): RestoreState {
  let state: any;
  try {
    state = JSON.parse(row.state_json);
  } catch (_) {
    throw conflict('Restore journal is unreadable; do not restart the restore.');
  }
  if (!state || state.version !== 1 || typeof state.jobId !== 'string' || !Number.isInteger(state.seq)) {
    throw conflict('Restore journal is invalid; manual investigation is required.');
  }
  return state as RestoreState;
}

async function readJournal(db: D1Database, id: string): Promise<RestoreState | null> {
  const row = await db.prepare('SELECT state_json FROM admin_restore_jobs WHERE id = ?').bind(id).first();
  return row ? parseState(row) : null;
}

function journalWrite(db: D1Database, id: string, state: RestoreState, now: string, expectedSeq: number) {
  return db
    .prepare(
      `UPDATE admin_restore_jobs SET state_json = ?, phase = ?, updated_at = ?
       WHERE id = ? AND job_id = ? AND json_extract(state_json, '$.seq') = ?`
    )
    .bind(JSON.stringify(state), state.phase, now, id, state.jobId, expectedSeq);
}

async function tableColumns(db: D1Database): Promise<Record<string, string[]>> {
  const results = await db.batch(BACKUP_TABLES.map((t) => db.prepare(`PRAGMA table_info(${t})`)));
  const map: Record<string, string[]> = {};
  BACKUP_TABLES.forEach((t, i) => {
    map[t] = (results[i].results || []).map((r: any) => String(r.name));
  });
  return map;
}

function sqlValue(value: unknown): string | number | null {
  if (value === null || value === undefined) return null;
  if (typeof value === 'number' || typeof value === 'string') return value;
  if (typeof value === 'boolean') return value ? 1 : 0;
  return JSON.stringify(value);
}

// Multi-row INSERT OR REPLACE statements for one chunk, each fenced on the
// checkpoint this batch writes.
export function chunkStatements(
  db: D1Database,
  table: string,
  tableCols: string[],
  rows: Record<string, unknown>[],
  fence: [string, number],
): D1PreparedStatement[] {
  if (rows.length === 0) return [];
  const present = new Set<string>();
  for (const row of rows) for (const key of Object.keys(row)) present.add(key);
  const cols = tableCols.filter((col) => present.has(col));
  if (!cols.includes('id') || !cols.includes('raw_json')) {
    throw new BackupError(`Invalid restore backup: ${table} rows lack id/raw_json.`, 400);
  }
  const perStatement = Math.max(1, Math.floor((MAX_BOUND_PARAMS - FENCE_PARAMS) / cols.length));
  const statements: D1PreparedStatement[] = [];
  for (let i = 0; i < rows.length; i += perStatement) {
    const slice = rows.slice(i, i + perStatement);
    const tuple = `(${cols.map(() => '?').join(', ')})`;
    const sql = `INSERT OR REPLACE INTO ${table} (${cols.join(', ')}) SELECT * FROM (VALUES ${slice.map(() => tuple).join(', ')}) WHERE ${FENCE_SQL}`;
    const binds: unknown[] = [];
    for (const row of slice) for (const col of cols) binds.push(sqlValue(row[col]));
    binds.push(fence[0], fence[1]);
    statements.push(db.prepare(sql).bind(...binds));
  }
  return statements;
}

export type RestoreResult = Record<string, unknown> & { complete: boolean };

function report(state: RestoreState, extra: Record<string, unknown> = {}): RestoreResult {
  return {
    complete: state.phase === 'complete',
    jobId: state.jobId,
    fileId: state.fileId,
    phase: state.phase,
    tableIndex: state.tableIndex,
    offset: state.offset,
    backup: state.backup,
    restored: state.restored,
    deleted: state.deleted,
    ...extra,
  };
}

async function startOrResume(
  env: Bindings,
  jobId: string,
  fileId: string,
  digest: string,
  actorUserId: string,
): Promise<RestoreState> {
  const db = env.DB;
  const expectedSafety = await safetyFileId(jobId);
  const history = await readJournal(db, historyId(jobId));
  const active = await readJournal(db, ACTIVE_ID);
  if (history) {
    if (history.fileId !== fileId || history.digest !== digest || history.safetyFileId !== expectedSafety) {
      throw conflict('Another restore or a changed backup owns the checkpoint. Resume the original operation.');
    }
    if (active?.jobId === jobId) return active;
    if (history.phase === 'complete') return history;
    throw conflict('This operation already ended or lost its active fence. Use a new restore ID only for a new restore.');
  }
  if (active && active.phase !== 'complete') {
    throw conflict(`Restore ${active.jobId} is unfinished. Resume backup ${active.fileId} first.`);
  }
  const now = new Date().toISOString();
  const fresh: RestoreState = {
    version: 1, seq: 0, jobId, fileId, digest, safetyFileId: expectedSafety,
    phase: 'prepare', tableIndex: 0, offset: 0, backup: null,
    deleted: {}, restored: {}, actorUserId, createdAt: now,
  };
  const json = JSON.stringify(fresh);
  await db.batch([
    db.prepare(
      `INSERT INTO admin_restore_jobs (id, job_id, file_id, phase, state_json, actor_user_id, updated_at)
       VALUES ('active', ?, ?, 'prepare', ?, ?, ?)
       ON CONFLICT(id) DO UPDATE SET job_id = excluded.job_id, file_id = excluded.file_id, phase = excluded.phase,
         state_json = excluded.state_json, actor_user_id = excluded.actor_user_id, updated_at = excluded.updated_at
       WHERE admin_restore_jobs.phase = 'complete'`
    ).bind(jobId, fileId, json, actorUserId, now),
    db.prepare(
      `INSERT INTO admin_restore_jobs (id, job_id, file_id, phase, state_json, actor_user_id, updated_at)
       SELECT ?, ?, ?, 'prepare', ?, ?, ? WHERE ${FENCE_SQL}`
    ).bind(historyId(jobId), jobId, fileId, json, actorUserId, now, jobId, 0),
  ]);
  const claimed = await readJournal(db, ACTIVE_ID);
  if (claimed?.jobId !== jobId) throw conflict('Another restore started at the same time. Resume that restore first.');
  return claimed;
}

// Runs (or resumes) a restore for up to one request budget.
export async function runRestore(
  env: Bindings,
  params: { fileId: string; jobId: string; actorUserId: string; dryRun: boolean; action: string },
): Promise<RestoreResult> {
  const { payload, digest } = await readBackup(env, params.fileId);
  const plan = BACKUP_TABLES.map((table) => ({ table, rows: payload.tables[table] }));
  if (params.dryRun) {
    const counts = Object.fromEntries(plan.map((p) => [p.table, p.rows.length]));
    return {
      complete: true, dryRun: true, jobId: params.jobId, fileId: params.fileId, digest,
      totalDocuments: plan.reduce((sum, p) => sum + p.rows.length, 0),
      collectionCounts: counts,
      message: 'Dry run validation succeeded. Backup is valid and compatible with the content tables.',
    };
  }

  const db = env.DB;
  let state = await startOrResume(env, params.jobId, params.fileId, digest, params.actorUserId);
  const columns = await tableColumns(db);
  const deadline = Date.now() + REQUEST_BUDGET_MS;
  let statementsUsed = 0;

  while (state.phase !== 'complete' && Date.now() < deadline && statementsUsed < REQUEST_STATEMENT_BUDGET) {
    const next: RestoreState = { ...state, seq: state.seq + 1, deleted: { ...state.deleted }, restored: { ...state.restored } };
    const fence: [string, number] = [state.jobId, next.seq];
    const now = new Date().toISOString();
    const data: D1PreparedStatement[] = [];

    if (state.phase === 'prepare') {
      const existing = await env.ASSETS.head(backupKey(state.safetyFileId));
      if (!existing) {
        await createBackup(env, params.actorUserId, { fileId: state.safetyFileId, reason: `restore-safety:${state.jobId}` });
      }
      next.backup = { fileId: state.safetyFileId };
      next.phase = 'restoring';
    } else if (state.tableIndex >= plan.length) {
      next.phase = 'complete';
      next.completedAt = now;
      data.push(
        ...changeStatements(db, [...BACKUP_TABLES], '*', 'restore'),
        auditStatement(db, {
          actor: params.actorUserId,
          action: params.action === 'rollback_restore' ? 'content_rollback_completed' : 'content_restore_completed',
          targetId: state.jobId,
          details: { fileId: state.fileId, safetyFileId: state.safetyFileId, restored: next.restored, deleted: next.deleted },
          at: now,
        }),
      );
    } else {
      const { table, rows } = plan[state.tableIndex];
      if (state.offset === 0) {
        const count: any = await db.prepare(`SELECT count(*) AS n FROM ${table}`).first();
        data.push(db.prepare(`DELETE FROM ${table} WHERE ${FENCE_SQL}`).bind(...fence));
        next.deleted[table] = Number(count?.n || 0);
      }
      const chunk = rows.slice(state.offset, state.offset + CHUNK_ROWS);
      data.push(...chunkStatements(db, table, columns[table] || [], chunk, fence));
      next.restored[table] = (state.restored[table] || 0) + chunk.length;
      next.offset = state.offset + chunk.length;
      if (next.offset >= rows.length) {
        next.tableIndex = state.tableIndex + 1;
        next.offset = 0;
      }
    }

    const results = await db.batch([
      journalWrite(db, ACTIVE_ID, next, now, state.seq),
      ...data,
      db.prepare(
        `UPDATE admin_restore_jobs SET state_json = ?, phase = ?, updated_at = ? WHERE id = ? AND ${FENCE_SQL}`
      ).bind(JSON.stringify(next), next.phase, now, historyId(state.jobId), ...fence),
    ]);
    statementsUsed += data.length + 2;
    if (!results[0].meta?.changes) {
      throw conflict('The restore checkpoint moved; another request is resuming this restore. Retry to resume.');
    }
    state = next;
  }
  return report(state, {
    message: state.phase === 'complete' ? 'Restore completed.' : 'Restore checkpoint saved; resume the same operation.',
  });
}

export async function rollbackJobId(restoreId: string): Promise<string> {
  return `rb-${(await stableId(`rollback:${restoreId}`)).slice(0, 30)}`;
}

export async function runRollback(env: Bindings, restoreId: string, actorUserId: string): Promise<RestoreResult> {
  if (!FILE_ID_PATTERN.test(restoreId)) throw new BackupError('Missing or invalid restore operation ID for rollback.', 400);
  const original = await readJournal(env.DB, historyId(restoreId));
  if (!original) throw new BackupError(`No restore record found for operation ${restoreId}.`, 404);
  if (!original.backup || !(await env.ASSETS.head(backupKey(original.safetyFileId)))) {
    throw conflict('This restore had not changed any content yet (no safety backup); nothing to roll back.');
  }
  const jobId = await rollbackJobId(restoreId);
  const result = await runRestore(env, {
    fileId: original.safetyFileId, jobId, actorUserId, dryRun: false, action: 'rollback_restore',
  });
  return { ...result, rollbackOf: restoreId };
}

export type { BackupPayload };
