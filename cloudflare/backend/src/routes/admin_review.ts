import type { App } from '../env';
import { adminUserId, auditStatement, readJsonBody } from './admin_common';

// Admin review queue over the learner-facing content tables
// (content_audio_tracks / content_localizations, served by
// routes/learner_content.ts). Port of the Appwrite `reviewContent`
// function: same actions, filters, `{success, data}` envelope and policy
// (audio is approvable only with an audioUrl and either a human recording or
// completed generation). A decision updates the review_status column and the
// stored document (raw_json) together.

export const REVIEW_ACTIONS = new Set([
  'list_audio',
  'approve_audio',
  'reject_audio',
  'list_localized',
  'approve_localized',
  'reject_localized',
]);
const MAX_BATCH_IDS = 50;
const MAX_PAGE_LIMIT = 100;
const DEFAULT_PAGE_LIMIT = 25;
const REVIEW_FILTERS = new Set(['needsReview', 'approved', 'rejected', 'draft', 'generated']);
const GENERATION_FILTERS = new Set(['notRequested', 'queued', 'processing', 'completed', 'failed']);

type Kind = 'audio' | 'localized';
const TABLES: Record<Kind, string> = { audio: 'content_audio_tracks', localized: 'content_localizations' };
const ORDER: Record<Kind, string> = { audio: 'created_at DESC, id ASC', localized: 'content_id ASC, language_code ASC, id ASC' };

type Outcome = { status: number; body: Record<string, unknown> };
const ok = (data: Record<string, unknown>): Outcome => ({ status: 200, body: { success: true, ok: true, data } });
const err = (status: number, message: string, code = 'INVALID_INPUT'): Outcome => ({
  status,
  body: { success: false, ok: false, error: code, message },
});

function text(value: unknown, max: number): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed ? trimmed.slice(0, max) : null;
}

function parseDoc(raw: string): Record<string, any> | null {
  try {
    const doc = JSON.parse(raw);
    return doc && typeof doc === 'object' && !Array.isArray(doc) ? doc : null;
  } catch (_) {
    return null;
  }
}

export function canApproveAudioTrack(doc: Record<string, any> | null): boolean {
  if (!doc) return false;
  if (typeof doc.audioUrl !== 'string' || doc.audioUrl.trim().length === 0) return false;
  if (doc.isHumanRecorded === true) return true;
  return doc.generationStatus === 'completed';
}

function toAudioRow(id: string, doc: Record<string, any>) {
  return {
    id,
    contentKind: doc.contentKind, contentId: doc.contentId, segmentId: doc.segmentId,
    languageCode: doc.languageCode, trackType: doc.trackType, audioUrl: doc.audioUrl,
    storageFileId: doc.storageFileId, provider: doc.provider, model: doc.model, voiceId: doc.voiceId,
    isHumanRecorded: doc.isHumanRecorded === true, generationStatus: doc.generationStatus,
    reviewStatus: doc.reviewStatus, errorMessage: doc.errorMessage, reviewedBy: doc.reviewedBy,
    reviewedAt: doc.reviewedAt, updatedAt: doc.updatedAt, createdAt: doc.createdAt,
  };
}

function toLocalizedRow(id: string, doc: Record<string, any>) {
  return {
    id,
    contentKind: doc.contentKind, contentId: doc.contentId, languageCode: doc.languageCode,
    meaning: doc.meaning, explanation: doc.explanation, hint: doc.hint, grammarNote: doc.grammarNote,
    exampleTranslation: doc.exampleTranslation, pronunciationGuide: doc.pronunciationGuide,
    reviewStatus: doc.reviewStatus, reviewedBy: doc.reviewedBy, reviewedAt: doc.reviewedAt, version: doc.version,
  };
}

async function listQueue(db: D1Database, kind: Kind, body: Record<string, any>): Promise<Outcome> {
  const limitRaw = Number(body.limit);
  const limit = Number.isInteger(limitRaw) && limitRaw > 0 ? Math.min(limitRaw, MAX_PAGE_LIMIT) : DEFAULT_PAGE_LIMIT;
  let offset = 0;
  if (body.offset !== undefined) {
    const raw = Number(body.offset);
    if (!Number.isInteger(raw) || raw < 0 || raw > 100000) return err(400, 'offset must be a non-negative integer.');
    offset = raw;
  }
  let reviewStatus = 'needsReview';
  if (body.reviewStatus !== undefined && body.reviewStatus !== null && body.reviewStatus !== '') {
    if (!REVIEW_FILTERS.has(body.reviewStatus)) return err(400, 'Unsupported reviewStatus filter.');
    reviewStatus = body.reviewStatus;
  }
  const where = ['review_status = ?'];
  const binds: unknown[] = [reviewStatus];
  const languageCode = text(body.languageCode, 10)?.toLowerCase();
  if (languageCode) {
    where.push('language_code = ?');
    binds.push(languageCode);
  }
  const contentKind = text(body.contentKind, 30);
  if (contentKind) {
    where.push('content_kind = ?');
    binds.push(contentKind);
  }
  if (kind === 'audio' && body.generationStatus !== undefined && body.generationStatus !== null && body.generationStatus !== '') {
    if (!GENERATION_FILTERS.has(body.generationStatus)) return err(400, 'Unsupported generationStatus filter.');
    where.push("json_extract(raw_json, '$.generationStatus') = ?");
    binds.push(body.generationStatus);
  }
  const table = TABLES[kind];
  const clause = where.join(' AND ');
  const [count, page] = await db.batch([
    db.prepare(`SELECT count(*) AS n FROM ${table} WHERE ${clause}`).bind(...binds),
    db.prepare(`SELECT id, raw_json FROM ${table} WHERE ${clause} ORDER BY ${ORDER[kind]} LIMIT ? OFFSET ?`).bind(...binds, limit, offset),
  ]);
  const documents = (page.results || [])
    .map((row: any) => {
      const doc = parseDoc(row.raw_json);
      if (!doc) return null;
      return kind === 'audio' ? toAudioRow(row.id, doc) : toLocalizedRow(row.id, doc);
    })
    .filter((row) => row !== null);
  return ok({ kind, total: Number((count.results?.[0] as any)?.n || 0), documents });
}

export async function applyDecisions(
  db: D1Database,
  kind: Kind,
  ids: string[],
  decision: 'approved' | 'rejected',
  reviewedBy: string,
): Promise<Outcome> {
  const table = TABLES[kind];
  const now = new Date().toISOString();
  const rows = await db
    .prepare(`SELECT id, raw_json FROM ${table} WHERE id IN (${ids.map(() => '?').join(', ')})`)
    .bind(...ids)
    .all();
  const byId = new Map<string, string>((rows.results || []).map((r: any) => [String(r.id), String(r.raw_json)]));

  const results: Record<string, unknown>[] = [];
  const updates: { id: string; index: number }[] = [];
  const statements: D1PreparedStatement[] = [];
  for (const id of ids) {
    const raw = byId.get(id);
    const doc = raw === undefined ? null : parseDoc(raw);
    if (raw === undefined || !doc) {
      results.push({ id, ok: false, reason: 'NOT_FOUND' });
      continue;
    }
    if (kind === 'audio' && decision === 'approved' && !canApproveAudioTrack(doc)) {
      results.push({ id, ok: false, reason: 'TRACK_NOT_APPROVABLE' });
      continue;
    }
    const next = { ...doc, reviewStatus: decision, reviewedBy, reviewedAt: now, updatedAt: now };
    // Guarded on the document we validated, so a concurrent edit is
    // reported instead of overwritten.
    statements.push(
      db.prepare(`UPDATE ${table} SET review_status = ?, raw_json = ? WHERE id = ? AND raw_json = ?`)
        .bind(decision, JSON.stringify(next), id, raw),
    );
    updates.push({ id, index: results.length });
    results.push({ id, ok: true, reviewStatus: decision, reviewedAt: now });
  }

  if (statements.length > 0) {
    statements.push(
      auditStatement(db, {
        actor: reviewedBy,
        action: `review_${kind}_${decision}`,
        targetId: updates.map((u) => u.id).join(',').slice(0, 2000),
        details: { table, decision, ids: updates.map((u) => u.id) },
        at: now,
      }),
    );
    const outcomes = await db.batch(statements);
    updates.forEach((u, i) => {
      if (!outcomes[i].meta?.changes) results[u.index] = { id: u.id, ok: false, reason: 'CONFLICT' };
    });
  }
  const updated = results.filter((r) => r.ok === true).length;
  return ok({ decision, reviewedBy, requested: ids.length, updated, failed: results.length - updated, results });
}

export async function handleReviewAction(db: D1Database, actor: string, body: Record<string, any>): Promise<Outcome> {
  const action = text(body.action, 40) || '';
  if (!REVIEW_ACTIONS.has(action)) return err(400, 'Unsupported review action.', 'UNSUPPORTED_ACTION');
  const kind: Kind = action.endsWith('_audio') ? 'audio' : 'localized';
  if (action.startsWith('list_')) return listQueue(db, kind, body);

  const ids = Array.isArray(body.ids)
    ? [...new Set(body.ids.map((id: unknown) => text(id, 100)).filter((id: string | null): id is string => Boolean(id)))]
    : [];
  if (ids.length === 0 || ids.length > MAX_BATCH_IDS || (Array.isArray(body.ids) && body.ids.length > MAX_BATCH_IDS)) {
    return err(400, `ids must be a non-empty list of at most ${MAX_BATCH_IDS} document ids.`);
  }
  return applyDecisions(db, kind, ids as string[], action.startsWith('approve_') ? 'approved' : 'rejected', actor);
}

export function registerAdminReviewRoutes(app: App): void {
  // reviewContent contract: POST {action, ...} -> {success, data}.
  app.post('/api/v1/admin/review/queue', async (c) => {
    const body = await readJsonBody(c);
    if (!body) return c.json({ success: false, ok: false, error: 'INVALID_INPUT', message: 'Invalid JSON body.' }, 400);
    try {
      const outcome = await handleReviewAction(c.env.DB, adminUserId(c), body);
      return c.json(outcome.body, outcome.status as any);
    } catch (e: any) {
      console.error(`review ${String(body.action)} failed: ${e?.message || e}`);
      return c.json({ success: false, ok: false, error: 'REVIEW_ERROR', message: 'Review request failed.' }, 500);
    }
  });

  // Summary of both queues (first page of items awaiting review).
  app.get('/api/v1/admin/review/queue', async (c) => {
    try {
      const [audio, localized] = await Promise.all([
        listQueue(c.env.DB, 'audio', { limit: 50 }),
        listQueue(c.env.DB, 'localized', { limit: 50 }),
      ]);
      const a = audio.body.data as any;
      const l = localized.body.data as any;
      return c.json({
        ok: true,
        queue: { audioTracks: a.documents, localizedContents: l.documents, audioTotal: a.total, localizedTotal: l.total },
      });
    } catch (e: any) {
      console.error(`review queue failed: ${e?.message || e}`);
      return c.json({ ok: false, message: 'Unable to load review queue' }, 500);
    }
  });

  // Single-item decision: {targetType: 'audio'|'localized', targetId, action: 'approve'|'reject'}.
  app.post('/api/v1/admin/review/state', async (c) => {
    const body = await readJsonBody(c);
    const targetType = String(body?.targetType || '').toLowerCase();
    const targetId = text(body?.targetId, 100);
    const action = String(body?.action || '').toLowerCase();
    if (!targetId || !['audio', 'localized'].includes(targetType) || !['approve', 'reject'].includes(action)) {
      return c.json({ ok: false, message: 'targetType (audio|localized), targetId and action (approve|reject) are required' }, 400);
    }
    try {
      const outcome = await applyDecisions(
        c.env.DB, targetType as Kind, [targetId], action === 'approve' ? 'approved' : 'rejected', adminUserId(c),
      );
      const result = ((outcome.body.data as any).results || [])[0] || {};
      if (!result.ok) {
        const status = result.reason === 'NOT_FOUND' ? 404 : 409;
        return c.json({ ok: false, targetId, reason: result.reason, message: `Review update failed: ${result.reason}` }, status);
      }
      return c.json({ ok: true, targetId, status: result.reviewStatus, reviewedAt: result.reviewedAt });
    } catch (e: any) {
      console.error(`review state failed: ${e?.message || e}`);
      return c.json({ ok: false, message: 'Failed to update review state' }, 500);
    }
  });
}
