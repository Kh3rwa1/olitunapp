import { getRequestUserId, type App } from '../env';

// Admin CMS writes for curriculum content and app settings (replaces direct
// Appwrite TablesDB writes from the admin app). Admin-team membership is
// enforced by the /api/v1/admin/* middleware in index.ts.
//
// Every row keeps the full Appwrite-style document in raw_json plus the
// indexed columns, mapped exactly like seed.js, so the learner read routes
// in index.ts (/api/v1/letters, /api/v1/lessons/authorize, ...) serve admin
// edits unchanged. Each mutation writes an admin_audit_logs row and a
// content_changes row in the same batch as the content write.

const MAX_BODY_BYTES = 256 * 1024;
const MAX_ADMIN_LIST_ROWS = 5000;
const MAX_CHANGES = 500;
// Letters (Ol Chiki too: bundled seeds use them), digits and `_.:-` only;
// slashes, whitespace and control characters are refused.
const ROW_ID_PATTERN = /^[\p{L}\p{N}_.:-]{1,128}$/u;
const SETTING_KEY_PATTERN = /^[A-Za-z0-9_.-]{1,128}$/;

type Doc = Record<string, any>;
type ContentTable = {
  columns: string[];
  values: (doc: Doc) => unknown[];
  orderBy: string;
};

function text(value: unknown): string | null {
  if (value === null || value === undefined) return null;
  if (typeof value === 'string') return value;
  if (typeof value === 'object') return JSON.stringify(value);
  return String(value);
}

function int(...candidates: unknown[]): number {
  for (const value of candidates) {
    if (value === null || value === undefined) continue;
    const n = Number(value);
    return Number.isFinite(n) ? Math.trunc(n) : 0;
  }
  return 0;
}

// Column mapping mirrors seed.js; `id` is always the first column and
// `raw_json` the last.
export const CONTENT_TABLES: Record<string, ContentTable> = {
  categories: {
    columns: ['title_ol_chiki', 'title_latin', 'icon_name', 'gradient_preset', 'order_index', 'is_active', 'unlock_mode'],
    values: (d) => [text(d.titleOlChiki), text(d.titleLatin), text(d.iconName), text(d.gradientPreset),
      int(d.orderIndex, d.order), d.isActive ? 1 : 0, text(d.unlockMode) || 'free'],
    orderBy: 'order_index',
  },
  letters: {
    columns: ['letter_ol_chiki', 'letter_latin', 'audio_url', 'order_index'],
    values: (d) => [text(d.letterOlChiki || d.olChiki), text(d.letterLatin || d.latin), text(d.audioUrl), int(d.orderIndex)],
    orderBy: 'order_index',
  },
  numbers: {
    columns: ['number_ol_chiki', 'number_latin', 'val', 'audio_url'],
    values: (d) => [text(d.numberOlChiki || d.olChiki), text(d.numberLatin || d.latin), int(d.value, d.val), text(d.audioUrl)],
    orderBy: 'val',
  },
  words: {
    columns: ['word_ol_chiki', 'word_latin', 'meaning', 'category', 'audio_url', 'order_index'],
    values: (d) => [text(d.wordOlChiki), text(d.wordLatin), text(d.meaning), text(d.category), text(d.audioUrl),
      int(d.orderIndex, d.order)],
    orderBy: 'order_index',
  },
  sentences: {
    columns: ['sentence_ol_chiki', 'sentence_latin', 'translation', 'category', 'audio_url', 'order_index'],
    values: (d) => [text(d.sentenceOlChiki || d.santaliOlChiki), text(d.sentenceLatin || d.santaliLatin),
      text(d.translation || d.englishMeaning), text(d.category), text(d.audioUrl), int(d.orderIndex)],
    orderBy: 'order_index',
  },
  lessons: {
    columns: ['category_id', 'title_ol_chiki', 'title_latin', 'lesson_type', 'order_index'],
    values: (d) => [text(d.categoryId || d.category), text(d.titleOlChiki), text(d.titleLatin),
      text(d.type || d.lessonType), int(d.orderIndex, d.order)],
    orderBy: 'order_index',
  },
  rhymes: {
    columns: ['title_ol_chiki', 'title_latin', 'content_ol_chiki', 'content_latin', 'audio_url', 'thumbnail_url',
      'category', 'is_premium', 'order_index'],
    values: (d) => [text(d.titleOlChiki), text(d.titleLatin), text(d.contentOlChiki), text(d.contentLatin),
      text(d.audioUrl), text(d.thumbnailUrl), text(d.category), d.isPremium ? 1 : 0, int(d.orderIndex, d.order)],
    orderBy: 'order_index',
  },
  banners: {
    columns: ['title', 'order_index', 'is_active'],
    values: (d) => [text(d.title), int(d.orderIndex, d.order), d.isActive !== false ? 1 : 0],
    orderBy: 'order_index',
  },
  quizzes: {
    columns: ['category_id', 'level', 'order_index', 'is_active'],
    values: (d) => [text(d.categoryId || d.category), text(d.level) || 'beginner', int(d.orderIndex, d.order),
      d.isActive !== false ? 1 : 0],
    orderBy: 'order_index',
  },
};

function fail(c: any, status: number, error: string, message: string) {
  return c.json({ ok: false, error, message }, status);
}

function noStore(c: any, data: unknown) {
  return c.json(data, 200, { 'Cache-Control': 'no-store' });
}

function parseDoc(raw: unknown): Doc | null {
  try {
    const parsed = JSON.parse(String(raw ?? ''));
    return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? parsed : null;
  } catch (_) {
    return null;
  }
}

// Reads a JSON object body of at most MAX_BODY_BYTES.
async function readBody(c: any): Promise<{ doc: Doc; bytes: number } | { status: number; message: string }> {
  const declared = Number(c.req.header('content-length') || 0);
  if (declared > MAX_BODY_BYTES) return { status: 413, message: `Body exceeds ${MAX_BODY_BYTES} bytes` };
  const raw = await c.req.text().catch(() => '');
  const bytes = new TextEncoder().encode(raw).length;
  if (bytes > MAX_BODY_BYTES) return { status: 413, message: `Body exceeds ${MAX_BODY_BYTES} bytes` };
  const doc = parseDoc(raw);
  if (!doc) return { status: 400, message: 'Body must be a JSON object' };
  return { doc, bytes };
}

function auditStatement(c: any, action: string, target: string, details: Doc) {
  return c.env.DB.prepare(
    'INSERT INTO admin_audit_logs (id, admin_user_id, action, target_id, details_json, timestamp) VALUES (?, ?, ?, ?, ?, ?)'
  ).bind(crypto.randomUUID(), getRequestUserId(c), action, target, JSON.stringify(details), new Date().toISOString());
}

function changeStatement(c: any, table: string, rowId: string, op: 'upsert' | 'delete') {
  return c.env.DB.prepare(
    'INSERT INTO content_changes (table_name, row_id, op, changed_at) VALUES (?, ?, ?, ?) RETURNING seq'
  ).bind(table, rowId, op, new Date().toISOString());
}

function seqOf(result: any): number | null {
  const seq = result?.results?.[0]?.seq;
  return typeof seq === 'number' ? seq : null;
}

function resolveTable(c: any): { name: string; spec: ContentTable } | null {
  const name = String(c.req.param('table') || '');
  const spec = Object.prototype.hasOwnProperty.call(CONTENT_TABLES, name) ? CONTENT_TABLES[name] : undefined;
  return spec ? { name, spec } : null;
}

export function registerAdminContentRoutes(app: App): void {
  // Full admin list (inactive rows included), never cached.
  app.get('/api/v1/admin/content/:table', async (c) => {
    const table = resolveTable(c);
    if (!table) return fail(c, 400, 'INVALID_TABLE', 'Unknown content table');
    try {
      const rows: any = await c.env.DB.prepare(
        `SELECT id, raw_json FROM ${table.name} ORDER BY ${table.spec.orderBy} ASC, id ASC LIMIT ?`
      ).bind(MAX_ADMIN_LIST_ROWS).all();
      const items = (rows.results || []).map((r: any) => ({ ...(parseDoc(r.raw_json) || {}), id: r.id }));
      return noStore(c, { ok: true, table: table.name, total: items.length, items });
    } catch (err: any) {
      console.error(`admin content list ${table.name} failed: ${err?.message || err}`);
      return fail(c, 500, 'DB_ERROR', 'Failed to list content');
    }
  });

  app.get('/api/v1/admin/content/:table/:id', async (c) => {
    const table = resolveTable(c);
    if (!table) return fail(c, 400, 'INVALID_TABLE', 'Unknown content table');
    const id = c.req.param('id');
    if (!ROW_ID_PATTERN.test(id)) return fail(c, 400, 'INVALID_ID', 'Invalid row id');
    try {
      const row: any = await c.env.DB.prepare(`SELECT id, raw_json FROM ${table.name} WHERE id = ?`).bind(id).first();
      if (!row) return fail(c, 404, 'NOT_FOUND', 'Row not found');
      return noStore(c, { ok: true, table: table.name, item: { ...(parseDoc(row.raw_json) || {}), id: row.id } });
    } catch (err: any) {
      console.error(`admin content get ${table.name} failed: ${err?.message || err}`);
      return fail(c, 500, 'DB_ERROR', 'Failed to load content');
    }
  });

  // Upsert. Like Appwrite's updateRow, fields are merged onto the stored
  // document so attributes the admin client does not model are preserved.
  app.put('/api/v1/admin/content/:table/:id', async (c) => {
    const table = resolveTable(c);
    if (!table) return fail(c, 400, 'INVALID_TABLE', 'Unknown content table');
    const id = c.req.param('id');
    if (!ROW_ID_PATTERN.test(id)) return fail(c, 400, 'INVALID_ID', 'Invalid row id');
    const body = await readBody(c);
    if ('status' in body) return fail(c, body.status, 'INVALID_BODY', body.message);
    if (body.doc.id !== undefined && body.doc.id !== null && String(body.doc.id) !== id) {
      return fail(c, 400, 'ID_MISMATCH', 'Body id does not match the URL id');
    }

    try {
      const existing: any = await c.env.DB.prepare(`SELECT raw_json FROM ${table.name} WHERE id = ?`).bind(id).first();
      const incoming: Doc = {};
      for (const [key, value] of Object.entries(body.doc)) {
        if (!key.startsWith('$')) incoming[key] = value;
      }
      const doc: Doc = { ...(existing ? parseDoc(existing.raw_json) || {} : {}), ...incoming, id };
      const rawJson = JSON.stringify(doc);
      if (new TextEncoder().encode(rawJson).length > MAX_BODY_BYTES) {
        return fail(c, 413, 'INVALID_BODY', `Document exceeds ${MAX_BODY_BYTES} bytes`);
      }
      const columns = ['id', ...table.spec.columns, 'raw_json'];
      const values = [id, ...table.spec.values(doc), rawJson];
      const op = existing ? 'update' : 'create';
      const results = await c.env.DB.batch([
        c.env.DB.prepare(
          `INSERT OR REPLACE INTO ${table.name} (${columns.join(', ')}) VALUES (${columns.map(() => '?').join(', ')})`
        ).bind(...values),
        auditStatement(c, `content.${op}`, `${table.name}/${id}`, { table: table.name, id, op, bytes: body.bytes }),
        changeStatement(c, table.name, id, 'upsert'),
      ]);
      return c.json({ ok: true, table: table.name, id, created: !existing, item: doc, seq: seqOf(results[2]) });
    } catch (err: any) {
      console.error(`admin content upsert ${table.name}/${id} failed: ${err?.message || err}`);
      return fail(c, 500, 'DB_ERROR', 'Failed to save content');
    }
  });

  app.delete('/api/v1/admin/content/:table/:id', async (c) => {
    const table = resolveTable(c);
    if (!table) return fail(c, 400, 'INVALID_TABLE', 'Unknown content table');
    const id = c.req.param('id');
    if (!ROW_ID_PATTERN.test(id)) return fail(c, 400, 'INVALID_ID', 'Invalid row id');
    try {
      const existing = await c.env.DB.prepare(`SELECT id FROM ${table.name} WHERE id = ?`).bind(id).first();
      if (!existing) return fail(c, 404, 'NOT_FOUND', 'Row not found');
      const results = await c.env.DB.batch([
        c.env.DB.prepare(`DELETE FROM ${table.name} WHERE id = ?`).bind(id),
        auditStatement(c, 'content.delete', `${table.name}/${id}`, { table: table.name, id, op: 'delete' }),
        changeStatement(c, table.name, id, 'delete'),
      ]);
      return c.json({ ok: true, table: table.name, id, deleted: true, seq: seqOf(results[2]) });
    } catch (err: any) {
      console.error(`admin content delete ${table.name}/${id} failed: ${err?.message || err}`);
      return fail(c, 500, 'DB_ERROR', 'Failed to delete content');
    }
  });

  // App settings, stored the way /api/v1/settings reads them.
  app.get('/api/v1/admin/settings', async (c) => {
    try {
      const rows: any = await c.env.DB.prepare(
        'SELECT setting_key, setting_value, raw_json FROM app_settings ORDER BY setting_key ASC'
      ).all();
      const settings: Record<string, string> = {};
      const documents: Doc[] = [];
      for (const r of rows.results || []) {
        const doc = parseDoc(r.raw_json) || {};
        const value = doc.settingValue !== undefined ? doc.settingValue : r.setting_value;
        settings[r.setting_key] = value;
        documents.push({ ...doc, id: r.setting_key, settingKey: r.setting_key, settingValue: value });
      }
      return noStore(c, { ok: true, settings, documents });
    } catch (err: any) {
      console.error(`admin settings list failed: ${err?.message || err}`);
      return fail(c, 500, 'DB_ERROR', 'Failed to load settings');
    }
  });

  app.put('/api/v1/admin/settings/:key', async (c) => {
    const key = c.req.param('key');
    if (!SETTING_KEY_PATTERN.test(key)) return fail(c, 400, 'INVALID_KEY', 'Invalid setting key');
    const body = await readBody(c);
    if ('status' in body) return fail(c, body.status, 'INVALID_BODY', body.message);
    const value = body.doc.settingValue;
    if (typeof value !== 'string') {
      return fail(c, 400, 'INVALID_BODY', 'settingValue must be a string');
    }
    try {
      const existing: any = await c.env.DB.prepare('SELECT raw_json FROM app_settings WHERE setting_key = ?').bind(key).first();
      const doc = { ...(existing ? parseDoc(existing.raw_json) || {} : {}), id: key, settingKey: key, settingValue: value };
      const op = existing ? 'update' : 'create';
      const results = await c.env.DB.batch([
        c.env.DB.prepare('INSERT OR REPLACE INTO app_settings (setting_key, setting_value, raw_json) VALUES (?, ?, ?)')
          .bind(key, value, JSON.stringify(doc)),
        auditStatement(c, `settings.${op}`, `app_settings/${key}`, { table: 'app_settings', id: key, op, bytes: body.bytes }),
        changeStatement(c, 'app_settings', key, 'upsert'),
      ]);
      return c.json({ ok: true, key, created: !existing, item: doc, seq: seqOf(results[2]) });
    } catch (err: any) {
      console.error(`admin settings upsert ${key} failed: ${err?.message || err}`);
      return fail(c, 500, 'DB_ERROR', 'Failed to save setting');
    }
  });

  app.delete('/api/v1/admin/settings/:key', async (c) => {
    const key = c.req.param('key');
    if (!SETTING_KEY_PATTERN.test(key)) return fail(c, 400, 'INVALID_KEY', 'Invalid setting key');
    try {
      const existing = await c.env.DB.prepare('SELECT setting_key FROM app_settings WHERE setting_key = ?').bind(key).first();
      if (!existing) return fail(c, 404, 'NOT_FOUND', 'Setting not found');
      const results = await c.env.DB.batch([
        c.env.DB.prepare('DELETE FROM app_settings WHERE setting_key = ?').bind(key),
        auditStatement(c, 'settings.delete', `app_settings/${key}`, { table: 'app_settings', id: key, op: 'delete' }),
        changeStatement(c, 'app_settings', key, 'delete'),
      ]);
      return c.json({ ok: true, key, deleted: true, seq: seqOf(results[2]) });
    } catch (err: any) {
      console.error(`admin settings delete ${key} failed: ${err?.message || err}`);
      return fail(c, 500, 'DB_ERROR', 'Failed to delete setting');
    }
  });

  // Public content change feed: which rows changed after `since`, oldest
  // first. Carries only table/id/op, never content.
  app.get('/api/v1/content/changes', async (c) => {
    const sinceRaw = c.req.query('since') ?? '0';
    if (!/^\d{1,15}$/.test(sinceRaw)) return fail(c, 400, 'INVALID_INPUT', 'since must be a non-negative integer');
    const since = Number(sinceRaw);
    try {
      const [rows, latestRow]: any[] = await c.env.DB.batch([
        c.env.DB.prepare(
          'SELECT seq, table_name, row_id, op, changed_at FROM content_changes WHERE seq > ? ORDER BY seq ASC LIMIT ?'
        ).bind(since, MAX_CHANGES + 1),
        c.env.DB.prepare('SELECT COALESCE(MAX(seq), 0) AS latest FROM content_changes'),
      ]);
      const results = rows.results || [];
      const changes = results.slice(0, MAX_CHANGES).map((r: any) => ({
        seq: r.seq,
        table: r.table_name,
        id: r.row_id,
        op: r.op,
        changedAt: r.changed_at,
      }));
      const latest = Number(latestRow.results?.[0]?.latest ?? 0);
      return c.json({ ok: true, changes, latest, hasMore: results.length > MAX_CHANGES }, 200, {
        'Cache-Control': 'public, max-age=10',
      });
    } catch (err: any) {
      console.error(`content changes failed: ${err?.message || err}`);
      return fail(c, 500, 'DB_ERROR', 'Failed to load content changes');
    }
  });
}
