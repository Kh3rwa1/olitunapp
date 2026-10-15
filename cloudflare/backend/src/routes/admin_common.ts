import { getRequestUserId } from '../env';

// Shared helpers for the admin route modules. Every /api/v1/admin/* route is
// already behind requireAdmin (index.ts), so the caller id here is a verified
// admin-team member.

export function adminUserId(c: any): string {
  return getRequestUserId(c);
}

// Audit row for an admin mutation, returned as a statement so it can commit
// in the same D1 batch as the change it describes.
export function auditStatement(
  db: D1Database,
  entry: { id?: string; actor: string; action: string; targetId: string; details: unknown; at?: string },
): D1PreparedStatement {
  return db
    .prepare(
      'INSERT INTO admin_audit_logs (id, admin_user_id, action, target_id, details_json, timestamp) VALUES (?, ?, ?, ?, ?, ?)'
    )
    .bind(
      entry.id || crypto.randomUUID(),
      entry.actor,
      entry.action,
      entry.targetId,
      JSON.stringify(entry.details ?? {}),
      entry.at || new Date().toISOString(),
    );
}

export async function readJsonBody(c: any): Promise<Record<string, any> | null> {
  const body = await c.req.json().catch(() => null);
  if (!body || typeof body !== 'object' || Array.isArray(body)) return null;
  return body;
}

// Appends one change-feed row per table so polling clients refetch. Bulk
// operations (restore, wipe) use row_id '*'.
export function changeStatements(db: D1Database, tables: string[], rowId: string, op: string): D1PreparedStatement[] {
  const at = new Date().toISOString();
  return tables.map((table) =>
    db.prepare('INSERT INTO content_changes (table_name, row_id, op, changed_at) VALUES (?, ?, ?, ?)').bind(table, rowId, op, at),
  );
}

export function clampInt(value: unknown, fallback: number, min: number, max: number): number {
  const n = Number(value);
  if (!Number.isInteger(n)) return fallback;
  return Math.min(Math.max(n, min), max);
}
