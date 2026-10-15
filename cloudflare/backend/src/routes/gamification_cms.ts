import type { App } from '../env';
import { getRequestUserId } from '../env';
import {
  BAKHED_CHILD_COLLECTIONS,
  CMS_COLLECTIONS,
  ID_PATTERN,
  MAX_ROW_BYTES,
  mergeAndValidate,
  rowColumns,
} from './cms_specs';
import { importLegacyIfEmpty } from './cms_legacy';

// Gamification + Bakhed CMS on D1 (replaces the Appwrite collections
// bravo_messages, badges, mission_templates, reward_messages,
// quiz_feedback_messages, gamification_config, bakhed_lyrics,
// bakhed_vocabulary, bakhed_cultural_notes and the admin_audit_logs writes).
//
// Admin routes live under /api/v1/admin/cms/* (admin team enforced by the
// /api/v1/admin/* middleware in index.ts). Learner routes build the same
// response shapes the app has always parsed from cms_rows, falling back per
// collection to the legacy D1 blob and then to the built-in defaults.

const NO_STORE = { 'Cache-Control': 'no-store, private' };
const LEARNER_CACHE = { 'Cache-Control': 'public, max-age=300, stale-while-revalidate=600' };
const ADMIN_LIST_LIMIT = 2000;
const READ_ONLY_LIMIT = 200;

// gamification/content response key -> cms_rows collection.
const GAMIFICATION_KEYS = {
  bravoMessages: 'bravo_messages',
  badges: 'badges',
  missionTemplates: 'mission_templates',
  rewardMessages: 'reward_messages',
  quizFeedbackMessages: 'quiz_feedback_messages',
} as const;

// bakhed/content response key -> cms_rows collection.
const BAKHED_KEYS = {
  lyrics: 'bakhed_lyrics',
  vocabulary: 'bakhed_vocabulary',
  culturalNotes: 'bakhed_cultural_notes',
} as const;

// Read-only admin views over existing D1 tables (fixed SQL per name).
const READ_ONLY_VIEWS: Record<string, { sql: string; map: (row: any) => Record<string, unknown> }> = {
  admin_audit_logs: {
    sql: 'SELECT id, admin_user_id, action, target_id, details_json, timestamp FROM admin_audit_logs ORDER BY timestamp DESC LIMIT ?',
    map: (row) => {
      const details = parseJson(row.details_json) || {};
      return {
        id: row.id,
        action: row.action,
        targetId: row.target_id || '',
        targetType: typeof details.collection === 'string' ? details.collection : '',
        adminUserId: row.admin_user_id,
        metadata: row.details_json || '',
        success: true,
        createdAt: row.timestamp,
      };
    },
  },
  learning_analytics_events: {
    sql: 'SELECT id, event_name, date_key, source_id, occurred_at FROM learning_analytics_events ORDER BY occurred_at DESC LIMIT ?',
    map: (row) => ({
      id: row.id,
      eventId: row.id,
      eventName: row.event_name,
      dateKey: row.date_key,
      sourceId: row.source_id || '',
      occurredAt: row.occurred_at || '',
    }),
  },
  learning_analytics_daily_rollups: {
    sql: 'SELECT id, date_key, total_events, unique_users, event_counts_json, created_at FROM learning_analytics_daily_rollups ORDER BY date_key DESC LIMIT ?',
    map: (row) => ({
      id: row.id,
      rollupId: row.id,
      dateKey: row.date_key,
      totalEvents: row.total_events,
      uniqueUsers: row.unique_users,
      eventCounts: row.event_counts_json,
      createdAt: row.created_at,
    }),
  },
};

const GAMIFICATION_FALLBACK = {
  bravoMessages: [
    {
      messageId: 'fallback_lesson_completed',
      trigger: 'lesson_completed',
      title: 'Nice learning step',
      body: 'You gave Santali practice real attention today.',
      language: 'en',
      scriptMode: 'both',
      learnerLevel: 'all',
      weight: 1,
      status: 'published',
      isActive: true,
    },
    {
      messageId: 'fallback_mistake_mastered',
      trigger: 'mistake_mastered',
      title: 'Second chance, stronger memory',
      body: 'Mistakes are just lessons asking for a second chance.',
      language: 'en',
      scriptMode: 'both',
      learnerLevel: 'all',
      weight: 1,
      status: 'published',
      isActive: true,
    },
  ],
  badges: [
    {
      badgeId: 'first_lesson',
      name: 'First Lesson',
      description: 'Complete your first Santali learning step.',
      category: 'learning',
      icon: '🏆',
      target: 1,
      rewardStars: 10,
      status: 'published',
      isActive: true,
    },
  ],
  missionTemplates: [],
  rewardMessages: [],
  quizFeedbackMessages: [],
  config: {},
};

function parseJson(text: unknown): any {
  if (typeof text !== 'string' || text === '') return null;
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

function toRow(raw: unknown, id: string): Record<string, unknown> {
  const doc = parseJson(raw);
  return { ...(doc && typeof doc === 'object' ? doc : {}), id };
}

function auditStatement(db: D1Database, adminId: string, action: string, targetId: string, details: Record<string, unknown>) {
  return db.prepare(
    'INSERT INTO admin_audit_logs (id, admin_user_id, action, target_id, details_json, timestamp) VALUES (?, ?, ?, ?, ?, ?)'
  ).bind(crypto.randomUUID(), adminId, action, targetId, JSON.stringify(details), new Date().toISOString());
}

// Keeps the relational `badges` table (read by /api/v1/gamification/summary)
// in step with the CMS badge rows.
function badgeSyncStatement(db: D1Database, id: string, doc: Record<string, any>, live: boolean) {
  return db.prepare(
    `INSERT INTO badges (badge_id, name, description, category, icon, reward_stars, target, sort_order, is_active, status)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT(badge_id) DO UPDATE SET name = excluded.name, description = excluded.description,
       category = excluded.category, icon = excluded.icon, reward_stars = excluded.reward_stars,
       target = excluded.target, sort_order = excluded.sort_order, is_active = excluded.is_active,
       status = excluded.status`
  ).bind(
    id,
    doc.name,
    doc.description ?? null,
    doc.category ?? 'learning',
    doc.icon ?? '🏆',
    typeof doc.rewardStars === 'number' ? doc.rewardStars : 10,
    typeof doc.target === 'number' ? doc.target : 1,
    typeof doc.sortOrder === 'number' ? doc.sortOrder : 0,
    live ? 1 : 0,
    typeof doc.status === 'string' ? doc.status : 'published',
  );
}

async function readBody(c: any): Promise<Record<string, any> | null> {
  const text = await c.req.text().catch(() => '');
  if (!text || text.length > MAX_ROW_BYTES * 2) return null;
  const body = parseJson(text);
  return body && typeof body === 'object' && !Array.isArray(body) ? body : null;
}

function serverError(c: any, label: string, err: any) {
  console.error(`${label}: ${err?.message || err}`);
  return c.json({ ok: false, message: `${label} failed` }, 500, NO_STORE);
}

// Learner filter: drafts, archived and inactive rows never reach the app.
const LIVE = "status = 'published' AND is_active = 1";

export function registerGamificationCmsRoutes(app: App): void {
  // ---- Admin: generic CMS rows -----------------------------------------

  app.get('/api/v1/admin/cms/rows/:collection', async (c) => {
    const collection = c.req.param('collection');
    const view = READ_ONLY_VIEWS[collection];
    try {
      if (view) {
        const result: any = await c.env.DB.prepare(view.sql).bind(READ_ONLY_LIMIT).all();
        return c.json({ ok: true, collection, rows: (result.results || []).map(view.map) }, 200, NO_STORE);
      }
      const spec = CMS_COLLECTIONS[collection];
      if (!spec) return c.json({ ok: false, message: 'Unknown collection' }, 400, NO_STORE);
      const bakhedId = (c.req.query('bakhedId') || '').trim();
      if (bakhedId && (!spec.bakhedChild || !ID_PATTERN.test(bakhedId))) {
        return c.json({ ok: false, message: 'Invalid bakhedId filter' }, 400, NO_STORE);
      }
      await importLegacyIfEmpty(c.env.DB, collection, bakhedId, getRequestUserId(c));
      const stmt = bakhedId
        ? c.env.DB.prepare(
          'SELECT id, raw_json FROM cms_rows WHERE collection = ? AND parent_id = ? ORDER BY order_index ASC, id ASC LIMIT ?'
        ).bind(collection, bakhedId, ADMIN_LIST_LIMIT)
        : c.env.DB.prepare(
          'SELECT id, raw_json FROM cms_rows WHERE collection = ? ORDER BY order_index ASC, id ASC LIMIT ?'
        ).bind(collection, ADMIN_LIST_LIMIT);
      const result: any = await stmt.all();
      const rows = (result.results || []).map((r: any) => toRow(r.raw_json, r.id));
      return c.json({ ok: true, collection, rows }, 200, NO_STORE);
    } catch (err: any) {
      return serverError(c, 'CMS list', err);
    }
  });

  // Body: { data: {...fields}, createOnly?: boolean }. Absent fields keep
  // their stored value; null clears an optional field.
  app.put('/api/v1/admin/cms/rows/:collection/:id', async (c) => {
    const collection = c.req.param('collection');
    const id = c.req.param('id');
    const spec = CMS_COLLECTIONS[collection];
    if (!spec) return c.json({ ok: false, message: 'Unknown collection' }, 400, NO_STORE);
    if (!ID_PATTERN.test(id)) return c.json({ ok: false, message: 'Invalid id' }, 400, NO_STORE);
    const body = await readBody(c);
    const patch = body?.data;
    if (!patch || typeof patch !== 'object' || Array.isArray(patch)) {
      return c.json({ ok: false, message: 'Body must be {"data": {...}}' }, 400, NO_STORE);
    }

    try {
      const db = c.env.DB;
      const existingRow: any = await db.prepare(
        'SELECT raw_json FROM cms_rows WHERE collection = ? AND id = ?'
      ).bind(collection, id).first();
      if (existingRow && body?.createOnly === true) {
        return c.json({ ok: false, message: 'Row already exists' }, 409, NO_STORE);
      }
      const now = new Date().toISOString();
      const existing = existingRow ? parseJson(existingRow.raw_json) : null;
      const validation = mergeAndValidate(spec, id, existing, patch);
      if (!validation.ok) {
        return c.json({ ok: false, message: 'Invalid row', errors: validation.errors }, 400, NO_STORE);
      }
      const doc = validation.doc;
      const adminId = getRequestUserId(c);
      doc.updatedAt = now;
      doc.updatedBy = adminId.slice(0, 100);
      if (!existing && doc.createdAt === undefined) doc.createdAt = now;
      const cols = rowColumns(collection, spec, doc);

      const statements = [
        db.prepare(
          `INSERT INTO cms_rows (collection, id, parent_id, order_index, status, is_active, raw_json, updated_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)
           ON CONFLICT(collection, id) DO UPDATE SET parent_id = excluded.parent_id,
             order_index = excluded.order_index, status = excluded.status,
             is_active = excluded.is_active, raw_json = excluded.raw_json, updated_at = excluded.updated_at`
        ).bind(collection, id, cols.parentId, cols.orderIndex, cols.status, cols.isActive, JSON.stringify(doc), now),
        auditStatement(db, adminId, existing ? `${collection}_updated` : `${collection}_created`, id, {
          collection,
          fields: Object.keys(patch).filter((k) => k !== 'id' && !k.startsWith('$')),
        }),
      ];
      if (collection === 'badges') {
        statements.push(badgeSyncStatement(db, id, doc, cols.status === 'published' && cols.isActive === 1));
      }
      await db.batch(statements);
      return c.json({ ok: true, collection, created: !existing, row: { ...doc, id } }, existing ? 200 : 201, NO_STORE);
    } catch (err: any) {
      return serverError(c, 'CMS upsert', err);
    }
  });

  app.delete('/api/v1/admin/cms/rows/:collection/:id', async (c) => {
    const collection = c.req.param('collection');
    const id = c.req.param('id');
    if (!CMS_COLLECTIONS[collection]) return c.json({ ok: false, message: 'Unknown collection' }, 400, NO_STORE);
    if (!ID_PATTERN.test(id)) return c.json({ ok: false, message: 'Invalid id' }, 400, NO_STORE);
    try {
      const db = c.env.DB;
      const existing = await db.prepare('SELECT id FROM cms_rows WHERE collection = ? AND id = ?').bind(collection, id).first();
      if (!existing) return c.json({ ok: false, message: 'Row not found' }, 404, NO_STORE);
      const statements = [
        db.prepare('DELETE FROM cms_rows WHERE collection = ? AND id = ?').bind(collection, id),
        auditStatement(db, getRequestUserId(c), `${collection}_deleted`, id, { collection }),
      ];
      if (collection === 'badges') {
        statements.push(db.prepare('DELETE FROM badges WHERE badge_id = ?').bind(id));
      }
      await db.batch(statements);
      return c.json({ ok: true, collection, id }, 200, NO_STORE);
    } catch (err: any) {
      return serverError(c, 'CMS delete', err);
    }
  });

  // ---- Admin: Bakhed parents (rows of the D1 `rhymes` table) -----------

  app.get('/api/v1/admin/cms/bakhed', async (c) => {
    try {
      const result: any = await c.env.DB.prepare(
        'SELECT id, raw_json FROM rhymes ORDER BY order_index ASC, id ASC LIMIT ?'
      ).bind(ADMIN_LIST_LIMIT).all();
      const items = (result.results || []).map((r: any) => toRow(r.raw_json, r.id));
      return c.json({ ok: true, items }, 200, NO_STORE);
    } catch (err: any) {
      return serverError(c, 'Bakhed list', err);
    }
  });

  app.get('/api/v1/admin/cms/bakhed/:id', async (c) => {
    const id = c.req.param('id');
    if (!ID_PATTERN.test(id)) return c.json({ ok: false, message: 'Invalid id' }, 400, NO_STORE);
    try {
      const row: any = await c.env.DB.prepare('SELECT id, raw_json FROM rhymes WHERE id = ?').bind(id).first();
      if (!row) return c.json({ ok: false, message: 'Bakhed not found' }, 404, NO_STORE);
      return c.json({ ok: true, item: toRow(row.raw_json, row.id) }, 200, NO_STORE);
    } catch (err: any) {
      return serverError(c, 'Bakhed get', err);
    }
  });

  // Body: { data: {...rhyme attributes} } merged into the stored document.
  app.put('/api/v1/admin/cms/bakhed/:id', async (c) => {
    const id = c.req.param('id');
    if (!ID_PATTERN.test(id)) return c.json({ ok: false, message: 'Invalid id' }, 400, NO_STORE);
    const body = await readBody(c);
    const patch = body?.data;
    if (!patch || typeof patch !== 'object' || Array.isArray(patch)) {
      return c.json({ ok: false, message: 'Body must be {"data": {...}}' }, 400, NO_STORE);
    }
    const doc: Record<string, any> = {};
    try {
      const db = c.env.DB;
      const existingRow: any = await db.prepare('SELECT raw_json FROM rhymes WHERE id = ?').bind(id).first();
      Object.assign(doc, parseJson(existingRow?.raw_json) || {});
      for (const [key, value] of Object.entries(patch)) {
        if (key === 'id' || key.startsWith('$')) continue;
        if (value === null) delete doc[key];
        else doc[key] = value;
      }
      const errors: string[] = [];
      for (const key of ['titleLatin', 'titleOlChiki']) {
        if (doc[key] !== undefined && typeof doc[key] !== 'string') errors.push(`${key} must be a string.`);
      }
      if (typeof doc.titleLatin !== 'string' || doc.titleLatin.trim() === '') errors.push('titleLatin is required.');
      if (doc.isPremium !== undefined && typeof doc.isPremium !== 'boolean') errors.push('isPremium must be true or false.');
      const updatedAt = typeof doc.updatedAt === 'string' && !Number.isNaN(Date.parse(doc.updatedAt))
        ? doc.updatedAt
        : new Date().toISOString();
      doc.updatedAt = updatedAt;
      doc.id = id;
      const rawJson = JSON.stringify(doc);
      if (rawJson.length > MAX_ROW_BYTES * 4) errors.push('Bakhed document is too large.');
      if (errors.length > 0) return c.json({ ok: false, message: 'Invalid bakhed', errors }, 400, NO_STORE);

      const order = typeof doc.orderIndex === 'number' ? doc.orderIndex : typeof doc.order === 'number' ? doc.order : 0;
      const text = (v: unknown) => (typeof v === 'string' ? v : null);
      await db.batch([
        db.prepare(
          `INSERT INTO rhymes (id, title_ol_chiki, title_latin, content_ol_chiki, content_latin, audio_url, thumbnail_url, category, is_premium, order_index, raw_json)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
           ON CONFLICT(id) DO UPDATE SET title_ol_chiki = excluded.title_ol_chiki, title_latin = excluded.title_latin,
             content_ol_chiki = excluded.content_ol_chiki, content_latin = excluded.content_latin,
             audio_url = excluded.audio_url, thumbnail_url = excluded.thumbnail_url, category = excluded.category,
             is_premium = excluded.is_premium, order_index = excluded.order_index, raw_json = excluded.raw_json`
        ).bind(
          id, text(doc.titleOlChiki), text(doc.titleLatin), text(doc.contentOlChiki), text(doc.contentLatin),
          text(doc.audioUrl), text(doc.thumbnailUrl), text(doc.category), doc.isPremium === true ? 1 : 0, order, rawJson,
        ),
        auditStatement(db, getRequestUserId(c), existingRow ? 'bakhed_updated' : 'bakhed_created', id, {
          collection: 'rhymes',
          fields: Object.keys(patch),
        }),
      ]);
      return c.json({ ok: true, created: !existingRow, item: doc }, existingRow ? 200 : 201, NO_STORE);
    } catch (err: any) {
      return serverError(c, 'Bakhed upsert', err);
    }
  });

  // Cascade delete: lyrics, vocabulary and cultural notes of the Bakhed, its
  // legacy content blob, then the parent rhyme, in one D1 batch.
  app.delete('/api/v1/admin/cms/bakhed/:id', async (c) => {
    const id = c.req.param('id');
    if (!ID_PATTERN.test(id)) return c.json({ ok: false, message: 'Invalid id' }, 400, NO_STORE);
    try {
      const db = c.env.DB;
      const parent: any = await db.prepare('SELECT raw_json FROM rhymes WHERE id = ?').bind(id).first();
      const counts: any = await db.prepare(
        `SELECT collection, COUNT(*) AS n FROM cms_rows WHERE parent_id = ? AND collection IN (?, ?, ?) GROUP BY collection`
      ).bind(id, ...BAKHED_CHILD_COLLECTIONS).all();
      const deleted: Record<string, number> = {};
      for (const name of BAKHED_CHILD_COLLECTIONS) deleted[name] = 0;
      for (const row of counts.results || []) deleted[row.collection] = row.n;
      if (!parent && Object.values(deleted).every((n) => n === 0)) {
        return c.json({ ok: false, message: 'Bakhed not found' }, 404, NO_STORE);
      }
      const audioFileId = parseJson(parent?.raw_json)?.audioFileId;
      await db.batch([
        db.prepare('DELETE FROM cms_rows WHERE parent_id = ? AND collection IN (?, ?, ?)').bind(id, ...BAKHED_CHILD_COLLECTIONS),
        db.prepare('DELETE FROM bakhed_content WHERE bakhed_id = ?').bind(id),
        db.prepare('DELETE FROM rhymes WHERE id = ?').bind(id),
        auditStatement(db, getRequestUserId(c), 'bakhed_deleted', id, { collection: 'rhymes', cascade: deleted }),
      ]);
      return c.json({
        ok: true,
        id,
        deleted: { rhymes: parent ? 1 : 0, ...deleted },
        audioFileId: typeof audioFileId === 'string' ? audioFileId : '',
      }, 200, NO_STORE);
    } catch (err: any) {
      return serverError(c, 'Bakhed delete', err);
    }
  });

  // ---- Learner: content built from cms_rows ----------------------------

  app.get('/api/v1/gamification/content', async (c) => {
    const db = c.env.DB;
    const cmsCollections = [...Object.values(GAMIFICATION_KEYS), 'gamification_config'];
    const present = new Set<string>();
    const live: Record<string, Record<string, unknown>[]> = {};
    try {
      const placeholders = cmsCollections.map(() => '?').join(', ');
      const result: any = await db.prepare(
        `SELECT collection, id, status, is_active, raw_json FROM cms_rows WHERE collection IN (${placeholders})
         ORDER BY collection, order_index ASC, id ASC`
      ).bind(...cmsCollections).all();
      for (const row of result.results || []) {
        present.add(row.collection);
        if (row.status !== 'published' || row.is_active !== 1) continue;
        (live[row.collection] ||= []).push(toRow(row.raw_json, row.id));
      }
    } catch (err: any) {
      // cms_rows missing or unreadable: serve the legacy sources below.
      console.error(`gamification content cms read failed: ${err?.message || err}`);
    }

    let blob: any = null;
    if (cmsCollections.some((name) => !present.has(name))) {
      try {
        const row: any = await db.prepare('SELECT raw_json FROM gamification_content WHERE id = ?').bind('default').first();
        blob = parseJson(row?.raw_json);
      } catch (err: any) {
        console.error(`gamification content blob read failed: ${err?.message || err}`);
      }
    }

    const source = blob && typeof blob === 'object' ? blob : GAMIFICATION_FALLBACK;
    const payload: Record<string, unknown> = { ...(blob && typeof blob === 'object' ? blob : {}), ok: true };
    for (const [key, collection] of Object.entries(GAMIFICATION_KEYS)) {
      payload[key] = present.has(collection)
        ? live[collection] || []
        : Array.isArray(source[key]) ? source[key] : (GAMIFICATION_FALLBACK as any)[key];
    }
    if (present.has('gamification_config')) {
      const configs = live.gamification_config || [];
      const chosen = configs.find((row) => row.id === 'default') || configs[0] || {};
      const { id: _id, updatedBy: _by, ...config } = chosen;
      payload.config = config;
    } else {
      payload.config = source.config && typeof source.config === 'object' ? source.config : {};
    }
    return c.json(payload, 200, LEARNER_CACHE);
  });

  app.get('/api/v1/bakhed/content', async (c) => {
    const id = (c.req.query('id') || c.req.query('bakhedId') || '').trim();
    if (!id) return c.json({ ok: false, error: 'Bakhed ID is required' }, 400);
    if (id.length > 128) return c.json({ ok: false, error: 'Invalid Bakhed ID' }, 400);
    const db = c.env.DB;
    const present = new Set<string>();
    const live: Record<string, Record<string, unknown>[]> = {};
    try {
      const result: any = await db.prepare(
        `SELECT collection, id, status, is_active, raw_json FROM cms_rows WHERE parent_id = ? AND collection IN (?, ?, ?)
         ORDER BY collection, order_index ASC, id ASC`
      ).bind(id, ...BAKHED_CHILD_COLLECTIONS).all();
      for (const row of result.results || []) {
        present.add(row.collection);
        if (row.status !== 'published' || row.is_active !== 1) continue;
        (live[row.collection] ||= []).push(toRow(row.raw_json, row.id));
      }
    } catch (err: any) {
      console.error(`bakhed content cms read failed: ${err?.message || err}`);
    }

    let blob: any = null;
    if (BAKHED_CHILD_COLLECTIONS.some((name) => !present.has(name))) {
      try {
        const row: any = await db.prepare('SELECT raw_json FROM bakhed_content WHERE bakhed_id = ?').bind(id).first();
        blob = parseJson(row?.raw_json);
      } catch (err: any) {
        console.error(`bakhed content blob read failed: ${err?.message || err}`);
      }
    }

    const payload: Record<string, unknown> = { ...(blob && typeof blob === 'object' ? blob : {}), ok: true, bakhedId: id };
    for (const [key, collection] of Object.entries(BAKHED_KEYS)) {
      payload[key] = present.has(collection)
        ? live[collection] || []
        : blob && Array.isArray(blob[key]) ? blob[key] : [];
    }
    return c.json(payload, 200, LEARNER_CACHE);
  });
}
