import { stableId, type Bindings } from '../env';
import { auditStatement } from './admin_common';

// Content backups in R2 (`backups/<fileId>.json`). A backup is a JSON
// snapshot of every learner content table, row by row with all columns, so
// a restore can rebuild the tables exactly.

// Fixed allow-list; table names are never taken from input.
export const BACKUP_TABLES = [
  'categories',
  'lessons',
  'letters',
  'numbers',
  'words',
  'sentences',
  'quizzes',
  'rhymes',
  'banners',
] as const;

// The tables wipe_content clears (the Appwrite admin-maintenance set, which
// the app's seeder repopulates).
export const WIPE_TABLES = ['quizzes', 'sentences', 'words', 'numbers', 'letters', 'lessons', 'categories'] as const;

export const BACKUP_SCHEMA_VERSION = 1;
export const BACKUP_KIND = 'olitun-d1-content-backup';
// Same shape the admin client validates before sending a file id.
export const FILE_ID_PATTERN = /^[a-zA-Z0-9][a-zA-Z0-9._-]{0,35}$/;

export type BackupPayload = {
  schemaVersion: number;
  kind: string;
  createdAt: string;
  actorUserId: string;
  tables: Record<string, Record<string, unknown>[]>;
  counts: Record<string, number>;
};

export type BackupInfo = {
  fileId: string;
  key: string;
  bucket: 'r2';
  fileName: string;
  createdAt: string;
  counts: Record<string, number>;
  bytes: number;
};

export function backupKey(fileId: string): string {
  return `backups/${fileId}.json`;
}

export function newBackupFileId(now: Date): string {
  const stamp = now.toISOString().replace(/[-:.]/g, '');
  const suffix = Array.from(crypto.getRandomValues(new Uint8Array(3)))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
  return `b${stamp}-${suffix}`;
}

// Deterministic id for the safety backup a restore takes before changing
// anything, so a retried restore reuses it instead of re-snapshotting a
// partially restored database.
export async function safetyFileId(jobId: string): Promise<string> {
  return `s${(await stableId(`restore-safety:${jobId}`)).slice(0, 30)}`;
}

export async function buildBackupPayload(db: D1Database, actorUserId: string, createdAt: string): Promise<BackupPayload> {
  const results = await db.batch(BACKUP_TABLES.map((table) => db.prepare(`SELECT * FROM ${table} ORDER BY rowid`)));
  const tables: Record<string, Record<string, unknown>[]> = {};
  const counts: Record<string, number> = {};
  BACKUP_TABLES.forEach((table, i) => {
    const rows = (results[i].results || []) as Record<string, unknown>[];
    tables[table] = rows;
    counts[table] = rows.length;
  });
  return { schemaVersion: BACKUP_SCHEMA_VERSION, kind: BACKUP_KIND, createdAt, actorUserId, tables, counts };
}

// Writes a backup and its audit row. R2 or D1 failures propagate: a backup
// that was not stored must never be reported as created.
export async function createBackup(
  env: Bindings,
  actorUserId: string,
  options: { fileId?: string; reason: string },
): Promise<BackupInfo> {
  const createdAt = new Date().toISOString();
  const fileId = options.fileId || newBackupFileId(new Date(createdAt));
  const payload = await buildBackupPayload(env.DB, actorUserId, createdAt);
  const text = JSON.stringify(payload);
  const key = backupKey(fileId);
  const stored = await env.ASSETS.put(key, text, {
    httpMetadata: { contentType: 'application/json' },
    customMetadata: { kind: BACKUP_KIND, actorUserId, reason: options.reason },
  });
  if (!stored) throw new Error('Backup upload was not stored.');
  await auditStatement(env.DB, {
    actor: actorUserId,
    action: 'content_backup_created',
    targetId: fileId,
    details: { key, counts: payload.counts, reason: options.reason, bytes: text.length },
    at: createdAt,
  }).run();
  return { fileId, key, bucket: 'r2', fileName: key, createdAt, counts: payload.counts, bytes: text.length };
}

export class BackupError extends Error {
  constructor(message: string, readonly status: number) {
    super(message);
  }
}

export async function readBackup(env: Bindings, fileId: string): Promise<{ payload: BackupPayload; digest: string }> {
  if (!FILE_ID_PATTERN.test(fileId)) throw new BackupError('Invalid backup file ID.', 400);
  const object = await env.ASSETS.get(backupKey(fileId));
  if (!object) throw new BackupError(`Backup ${fileId} not found.`, 404);
  const bytes = await object.arrayBuffer();
  const digestBytes = await crypto.subtle.digest('SHA-256', bytes);
  const digest = Array.from(new Uint8Array(digestBytes)).map((b) => b.toString(16).padStart(2, '0')).join('');
  let payload: any;
  try {
    payload = JSON.parse(new TextDecoder().decode(bytes));
  } catch (_) {
    throw new BackupError('Invalid restore backup: file is not valid JSON.', 400);
  }
  validateBackupPayload(payload);
  return { payload, digest };
}

export function validateBackupPayload(payload: any): asserts payload is BackupPayload {
  if (!payload || typeof payload !== 'object' || payload.kind !== BACKUP_KIND || payload.schemaVersion !== BACKUP_SCHEMA_VERSION) {
    throw new BackupError('Invalid restore backup: unsupported backup format.', 400);
  }
  if (!payload.tables || typeof payload.tables !== 'object') {
    throw new BackupError('Invalid restore backup: missing tables.', 400);
  }
  for (const table of Object.keys(payload.tables)) {
    if (!(BACKUP_TABLES as readonly string[]).includes(table)) {
      throw new BackupError(`Invalid restore backup: unexpected table ${table}.`, 400);
    }
  }
  for (const table of BACKUP_TABLES) {
    const rows = payload.tables[table];
    if (!Array.isArray(rows)) throw new BackupError(`Invalid restore backup: table ${table} is missing.`, 400);
    for (const row of rows) {
      if (!row || typeof row !== 'object' || Array.isArray(row) || typeof row.raw_json !== 'string') {
        throw new BackupError(`Invalid restore backup: malformed row in ${table}.`, 400);
      }
      if (typeof row.id !== 'string' || row.id.length === 0) {
        throw new BackupError(`Invalid restore backup: row without id in ${table}.`, 400);
      }
    }
  }
}
