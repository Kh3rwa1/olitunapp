import type { Context } from 'hono';
import type { App, AppEnv } from '../env';

// Admin media storage in R2 (ASSETS), replacing Appwrite Storage.
//
// Objects live at `<bucket>/<fileId>`. Public buckets are served by
// GET/HEAD /api/v1/assets/<bucket>/<fileId> (serveAsset below). paid_media
// is private: it is only ever streamed through the signed URLs minted by
// routes/paid_media.ts, never through /api/v1/assets.
//
// All /api/v1/admin/* routes are behind requireAdmin (index.ts).

type Ctx = Context<AppEnv>;

type BucketRule = { maxBytes: number; types: readonly string[]; isPublic: boolean };

const MB = 1024 * 1024;
const AUDIO = ['audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/x-wav', 'audio/wave', 'audio/ogg', 'audio/aac', 'audio/mp4', 'audio/x-m4a', 'audio/webm'];
const RASTER = ['image/png', 'image/jpeg', 'image/gif', 'image/webp'];
const VIDEO = ['video/mp4', 'video/webm', 'video/quicktime', 'video/x-m4v'];

// Bucket ids exactly as the Flutter client uses them (upload_service.dart,
// media_uploader.dart, authorized_media.dart, remote avatars).
export const MEDIA_BUCKETS: Record<string, BucketRule> = {
  audio: { maxBytes: 25 * MB, types: AUDIO, isPublic: true },
  images: { maxBytes: 25 * MB, types: [...RASTER, 'image/svg+xml'], isPublic: true },
  animations: { maxBytes: 10 * MB, types: ['application/json'], isPublic: true },
  avatars: { maxBytes: 5 * MB, types: ['application/json'], isPublic: true },
  videos: { maxBytes: 95 * MB, types: VIDEO, isPublic: true },
  cover_videos: { maxBytes: 95 * MB, types: VIDEO, isPublic: true },
  // Rendered in a lesson iframe; always served with a sandboxing CSP.
  html: { maxBytes: 5 * MB, types: ['text/html'], isPublic: true },
  paid_media: { maxBytes: 95 * MB, types: [...AUDIO, ...VIDEO, ...RASTER], isPublic: false },
};

// R2 prefixes that must never be readable through the public assets route.
const PRIVATE_PREFIXES = ['paid_media/', 'backups/'];

export const FILE_ID_PATTERN = /^[a-zA-Z0-9_-][a-zA-Z0-9._-]{0,63}$/;

// D1 tables whose rows may hold media references (URLs or bare file ids).
// [table, id column, column scanned]
const REFERENCE_TABLES: ReadonlyArray<readonly [string, string, string]> = [
  ['categories', 'id', 'raw_json'],
  ['letters', 'id', 'raw_json'],
  ['numbers', 'id', 'raw_json'],
  ['words', 'id', 'raw_json'],
  ['sentences', 'id', 'raw_json'],
  ['lessons', 'id', 'raw_json'],
  ['rhymes', 'id', 'raw_json'],
  ['banners', 'id', 'raw_json'],
  ['quizzes', 'id', 'raw_json'],
  ['app_settings', 'setting_key', 'raw_json'],
  ['gamification_content', 'id', 'raw_json'],
  ['bakhed_content', 'bakhed_id', 'raw_json'],
  ['content_audio_tracks', 'id', 'raw_json'],
  ['story_segments', 'id', 'raw_json'],
  ['audio_tracks', 'id', 'audio_url'],
];

export function normalizeContentType(raw: string | undefined | null): string {
  return String(raw || '').split(';')[0].trim().toLowerCase();
}

function objectKey(bucket: string, fileId: string): string {
  return `${bucket}/${fileId}`;
}

function sanitizeName(raw: string | undefined): string {
  return String(raw || '').replace(/[^a-zA-Z0-9._-]/g, '_').slice(0, 128);
}

function err(c: Ctx, status: 400 | 404 | 409 | 411 | 413 | 415 | 500, error: string, message: string) {
  return c.json({ ok: false, error, message }, status);
}

function validateTarget(c: Ctx): { bucket: string; fileId: string; rule: BucketRule } | Response {
  const bucket = c.req.param('bucket') || '';
  const fileId = c.req.param('fileId') || '';
  const rule = Object.prototype.hasOwnProperty.call(MEDIA_BUCKETS, bucket) ? MEDIA_BUCKETS[bucket] : undefined;
  if (!rule) return err(c, 400, 'invalid_bucket', `Unknown bucket: ${bucket}`);
  if (!FILE_ID_PATTERN.test(fileId)) return err(c, 400, 'invalid_file_id', 'fileId must match [a-zA-Z0-9._-]{1,64}');
  return { bucket, fileId, rule };
}

async function uploadMedia(c: Ctx): Promise<Response> {
  const target = validateTarget(c);
  if (target instanceof Response) return target;
  const { bucket, fileId, rule } = target;

  const contentType = normalizeContentType(c.req.header('content-type'));
  if (!rule.types.includes(contentType)) {
    return err(c, 415, 'unsupported_media_type', `Content-Type ${contentType || '(none)'} is not allowed in ${bucket}`);
  }

  const lengthHeader = c.req.header('content-length');
  if (!lengthHeader || !/^\d+$/.test(lengthHeader)) {
    return err(c, 411, 'length_required', 'Content-Length is required');
  }
  const size = Number(lengthHeader);
  if (size <= 0) return err(c, 400, 'empty_file', 'File is empty');
  if (size > rule.maxBytes) {
    return err(c, 413, 'file_too_large', `Max size for ${bucket} is ${Math.round(rule.maxBytes / MB)}MB`);
  }
  const body = c.req.raw.body;
  if (!body) return err(c, 400, 'empty_file', 'File is empty');

  const key = objectKey(bucket, fileId);
  if (await c.env.ASSETS.head(key)) {
    return err(c, 409, 'file_exists', 'A file with this id already exists');
  }

  // Streamed straight into R2 (the runtime enforces Content-Length).
  const stored = await c.env.ASSETS.put(key, body, {
    httpMetadata: { contentType },
    customMetadata: {
      uploadedBy: c.get('userId') || '',
      originalName: sanitizeName(c.req.header('x-file-name')),
      uploadedAt: new Date().toISOString(),
    },
  });

  const url = rule.isPublic
    ? new URL(`/api/v1/assets/${bucket}/${encodeURIComponent(fileId)}`, c.req.url).toString()
    : null;
  return c.json({
    ok: true,
    bucketId: bucket,
    fileId,
    url,
    size: stored?.size ?? size,
    mimeType: contentType,
  }, 201);
}

async function deleteMedia(c: Ctx): Promise<Response> {
  const target = validateTarget(c);
  if (target instanceof Response) return target;
  const key = objectKey(target.bucket, target.fileId);
  const existing = await c.env.ASSETS.head(key);
  if (existing) await c.env.ASSETS.delete(key);
  return c.json({ ok: true, deleted: !!existing, bucketId: target.bucket, fileId: target.fileId });
}

// Is the file id mentioned anywhere in D1 content? Substring match over the
// stored JSON, so both bare ids and URLs containing the id count. Any query
// failure is a 500 and the client must then refuse to delete.
async function referenceCheck(c: Ctx): Promise<Response> {
  const fileId = c.req.query('fileId') || '';
  if (!FILE_ID_PATTERN.test(fileId)) return err(c, 400, 'invalid_file_id', 'fileId must match [a-zA-Z0-9._-]{1,64}');
  try {
    const references: { table: string; id: string }[] = [];
    for (const [table, idColumn, column] of REFERENCE_TABLES) {
      const row = await c.env.DB.prepare(
        `SELECT ${idColumn} AS id FROM ${table} WHERE instr(${column}, ?) > 0 LIMIT 1`,
      ).bind(fileId).first<{ id: string }>();
      if (row) references.push({ table, id: String(row.id) });
    }
    return c.json({ ok: true, fileId, referenced: references.length > 0, references });
  } catch (e: any) {
    return err(c, 500, 'reference_check_failed', e?.message || 'Reference check failed');
  }
}

type ByteRange = { offset: number; length: number };

function parseRange(header: string | undefined, size: number): ByteRange | null | 'unsatisfiable' {
  if (!header) return null;
  const match = header.trim().match(/^bytes=(\d*)-(\d*)$/);
  if (!match || (!match[1] && !match[2])) return null;
  if (!match[1]) {
    const suffix = Number(match[2]);
    if (suffix === 0 || size === 0) return 'unsatisfiable';
    const length = Math.min(suffix, size);
    return { offset: size - length, length };
  }
  const start = Number(match[1]);
  if (start >= size) return 'unsatisfiable';
  const end = match[2] ? Math.min(Number(match[2]), size - 1) : size - 1;
  if (end < start) return 'unsatisfiable';
  return { offset: start, length: end - start + 1 };
}

// Active content (HTML, SVG) must not run with the API origin's privileges:
// the Worker also proxies the web app, so it would see the learner's session.
function sandboxPolicy(contentType: string): string | null {
  if (contentType === 'text/html') {
    return "sandbox allow-scripts allow-popups allow-forms; default-src * data: blob: 'unsafe-inline' 'unsafe-eval'";
  }
  if (contentType === 'image/svg+xml') {
    return "sandbox; default-src 'none'; style-src 'unsafe-inline'; img-src data:";
  }
  return null;
}

/**
 * Public GET/HEAD /api/v1/assets/<key>: R2 objects by key, with single-range
 * support for audio/video seeking. Private prefixes are never served here.
 */
export async function serveAsset(c: Ctx): Promise<Response> {
  try {
    const key = c.req.path.replace('/api/v1/assets/', '');
    if (!key || PRIVATE_PREFIXES.some((p) => key.startsWith(p))) {
      return c.text('Asset Not Found', 404);
    }

    const meta = await c.env.ASSETS.head(key);
    if (!meta) return c.text('Asset Not Found', 404);

    const contentType = normalizeContentType(meta.httpMetadata?.contentType) || 'application/octet-stream';
    const headers = new Headers();
    meta.writeHttpMetadata(headers);
    headers.set('Content-Type', meta.httpMetadata?.contentType || contentType);
    headers.set('ETag', meta.httpEtag);
    headers.set('Accept-Ranges', 'bytes');
    headers.set('Cache-Control', 'public, max-age=31536000, immutable');
    headers.set('X-Content-Type-Options', 'nosniff');
    headers.set('Cross-Origin-Resource-Policy', 'cross-origin');
    const csp = sandboxPolicy(contentType);
    if (csp) headers.set('Content-Security-Policy', csp);

    if (c.req.header('if-none-match') === meta.httpEtag) {
      return new Response(null, { status: 304, headers });
    }

    const range = parseRange(c.req.header('range'), meta.size);
    if (range === 'unsatisfiable') {
      headers.set('Content-Range', `bytes */${meta.size}`);
      return new Response(null, { status: 416, headers });
    }
    const status = range ? 206 : 200;
    headers.set('Content-Length', String(range ? range.length : meta.size));
    if (range) headers.set('Content-Range', `bytes ${range.offset}-${range.offset + range.length - 1}/${meta.size}`);

    if (c.req.method === 'HEAD') return new Response(null, { status, headers });

    const object = await c.env.ASSETS.get(key, range ? { range } : undefined);
    if (!object) return c.text('Asset Not Found', 404);
    return new Response(object.body, { status, headers });
  } catch (e: any) {
    return c.json({ ok: false, error: e?.message || 'asset_error' }, 500);
  }
}

export function registerMediaRoutes(app: App): void {
  // requireAdmin is applied to /api/v1/admin/* in index.ts.
  app.get('/api/v1/admin/media/references', referenceCheck);
  app.put('/api/v1/admin/media/:bucket/:fileId', uploadMedia);
  app.delete('/api/v1/admin/media/:bucket/:fileId', deleteMedia);
}
