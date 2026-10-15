import type { App } from '../env';

// Public learner content reads that used to hit Appwrite directly:
// per-item audio tracks, approved localizations, story segments, and the
// remote avatar catalogue in R2. No auth: everything here is content any
// learner (signed in or not) may read. Rows are stored as the Appwrite
// document JSON (raw_json) plus the indexed columns the filters need.

const MAX_CONTENT_IDS = 100;
const MAX_ROWS = 2000;
const MAX_AVATARS = 1000;
const AVATAR_PREFIX = 'avatars/';
const CACHE_SECONDS = 300;

function cachedJson(c: any, data: unknown, maxAge = CACHE_SECONDS) {
  return c.json(data, 200, {
    'Cache-Control': `public, max-age=${maxAge}, stale-while-revalidate=600`,
  });
}

function badRequest(c: any, message: string) {
  return c.json({ ok: false, error: 'INVALID_INPUT', message }, 400);
}

function parseRow(row: any): Record<string, any> | null {
  try {
    const parsed = JSON.parse(row.raw_json);
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) return null;
    return { ...parsed, id: row.id };
  } catch (_) {
    return null;
  }
}

function contentIdsFrom(c: any): string[] {
  const ids = (c.req.queries('contentId') || [])
    .map((id: string) => id.trim())
    .filter((id: string) => id.length > 0);
  return Array.from(new Set<string>(ids));
}

// A track's audio is only exposed once it is playable for learners
// (approved, or a trusted human recording). Other rows are still listed so
// the app can show "audio unavailable" states, but without their media.
function redactUnplayable(track: Record<string, any>): Record<string, any> {
  const playable = track.reviewStatus === 'approved' || track.isHumanRecorded === true;
  if (playable) return track;
  return { ...track, audioUrl: null, storageFileId: null };
}

function safeAvatarId(name: string): string {
  return name.replace(/[^A-Za-z0-9._-]+/g, '_');
}

function encodeKeyPath(key: string): string {
  return key.split('/').map(encodeURIComponent).join('/');
}

export function registerLearnerContentRoutes(app: App): void {
  // Audio tracks for one or many items of a content kind. Mirrors the
  // Appwrite queries: contentKind + contentId (repeatable, max 100), with
  // optional trackType + languageCode filters.
  app.get('/api/v1/audio-tracks', async (c) => {
    const contentKind = (c.req.query('contentKind') || '').trim();
    const contentIds = contentIdsFrom(c);
    const trackType = (c.req.query('trackType') || '').trim();
    const languageCode = (c.req.query('languageCode') || '').trim();
    if (!contentKind || contentIds.length === 0) {
      return badRequest(c, 'contentKind and contentId are required');
    }
    if (contentIds.length > MAX_CONTENT_IDS) {
      return badRequest(c, `At most ${MAX_CONTENT_IDS} contentId values per request`);
    }
    try {
      const params: unknown[] = [contentKind, ...contentIds];
      let sql = `SELECT id, raw_json FROM content_audio_tracks WHERE content_kind = ? AND content_id IN (${contentIds.map(() => '?').join(', ')})`;
      if (trackType) {
        sql += ' AND track_type = ?';
        params.push(trackType);
      }
      if (languageCode) {
        sql += ' AND language_code = ?';
        params.push(languageCode);
      }
      sql += ` ORDER BY created_at ASC, id ASC LIMIT ${MAX_ROWS}`;
      const result = await c.env.DB.prepare(sql).bind(...params).all();
      const tracks = (result.results || [])
        .map(parseRow)
        .filter((t): t is Record<string, any> => t !== null)
        .map(redactUnplayable);
      return cachedJson(c, { ok: true, total: tracks.length, tracks });
    } catch (err: any) {
      return c.json({ ok: false, error: err.message }, 500);
    }
  });

  // Approved localizations only: drafts and rejected rows never leave D1
  // through this public route (the app only ever surfaces approved rows).
  app.get('/api/v1/localized-contents', async (c) => {
    const contentKind = (c.req.query('contentKind') || '').trim();
    const contentIds = contentIdsFrom(c);
    const languageCode = (c.req.query('languageCode') || '').trim();
    if (!contentKind || contentIds.length === 0) {
      return badRequest(c, 'contentKind and contentId are required');
    }
    if (contentIds.length > MAX_CONTENT_IDS) {
      return badRequest(c, `At most ${MAX_CONTENT_IDS} contentId values per request`);
    }
    try {
      const params: unknown[] = [contentKind, ...contentIds];
      let sql = `SELECT id, raw_json FROM content_localizations WHERE review_status = 'approved' AND content_kind = ? AND content_id IN (${contentIds.map(() => '?').join(', ')})`;
      if (languageCode) {
        sql += ' AND language_code = ?';
        params.push(languageCode);
      }
      sql += ` ORDER BY content_id ASC, language_code ASC LIMIT ${MAX_ROWS}`;
      const result = await c.env.DB.prepare(sql).bind(...params).all();
      const localizations = (result.results || [])
        .map(parseRow)
        .filter((row): row is Record<string, any> => row !== null);
      return cachedJson(c, { ok: true, total: localizations.length, localizations });
    } catch (err: any) {
      return c.json({ ok: false, error: err.message }, 500);
    }
  });

  // All segments of one story, ordered for the story player.
  app.get('/api/v1/story-segments', async (c) => {
    const storyId = (c.req.query('storyId') || '').trim();
    if (!storyId) return badRequest(c, 'storyId is required');
    try {
      const result = await c.env.DB.prepare(
        `SELECT id, raw_json FROM story_segments WHERE story_id = ? ORDER BY order_index ASC, id ASC LIMIT ${MAX_ROWS}`
      ).bind(storyId).all();
      const segments = (result.results || [])
        .map(parseRow)
        .filter((row): row is Record<string, any> => row !== null);
      return cachedJson(c, { ok: true, total: segments.length, segments });
    } catch (err: any) {
      return c.json({ ok: false, error: err.message }, 500);
    }
  });

  // Remote avatar catalogue: every object directly under avatars/ in R2.
  // Files are served by /api/v1/assets/*; `version` (the etag) changes when
  // an object is replaced so clients can re-download only what changed.
  app.get('/api/v1/avatars', async (c) => {
    try {
      const avatars: Record<string, unknown>[] = [];
      let cursor: string | undefined;
      do {
        const listing = await c.env.ASSETS.list({ prefix: AVATAR_PREFIX, cursor, limit: 1000 });
        for (const object of listing.objects) {
          const name = object.key.slice(AVATAR_PREFIX.length);
          if (!name || name.includes('/')) continue;
          avatars.push({
            id: safeAvatarId(name),
            name,
            key: object.key,
            path: `/api/v1/assets/${encodeKeyPath(object.key)}`,
            size: object.size,
            version: object.httpEtag,
            updatedAt: object.uploaded.toISOString(),
          });
          if (avatars.length >= MAX_AVATARS) break;
        }
        cursor = listing.truncated && avatars.length < MAX_AVATARS ? listing.cursor : undefined;
      } while (cursor);
      avatars.sort((a, b) => String(a.name).localeCompare(String(b.name)));
      return cachedJson(c, { ok: true, total: avatars.length, avatars });
    } catch (err: any) {
      return c.json({ ok: false, error: err.message }, 500);
    }
  });
}
