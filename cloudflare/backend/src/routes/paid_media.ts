import type { Context } from 'hono';
import { timingSafeEqualStr } from '../auth';
import type { App, AppEnv } from '../env';

// Paid lesson media lives in R2 (ASSETS) under `paid_media/<fileId>`.
// /api/v1/lessons/authorize (action get_media) checks entitlement and the
// lesson <-> file association, then returns a short-lived URL to the
// streaming route below, signed with MEDIA_SIGNING_SECRET. File bytes are
// never sent through the authorize call.

export const PAID_MEDIA_BUCKET_ID = 'paid_media';
export const MEDIA_PROTOCOL_VERSION = 3;
export const MEDIA_TRANSPORT = 'edge-signed-url';
export const MEDIA_TTL_SECONDS = 5 * 60;
const CLOCK_SKEW_SECONDS = 30;
const MEDIA_HEADERS = { 'Cache-Control': 'no-store, private', Pragma: 'no-cache' };
const ID_PATTERN = /^[a-zA-Z0-9._-]{1,64}$/;
const UID_PATTERN = /^[a-zA-Z0-9._:-]{1,128}$/;

type Ctx = Context<AppEnv>;

function text(value: unknown, max = 64): string {
  return String(value ?? '').trim().slice(0, max);
}

function r2Key(fileId: string): string {
  return `${PAID_MEDIA_BUCKET_ID}/${fileId}`;
}

/**
 * Port of extractAuthorizedLessonMedia from the Appwrite getAuthorizedLesson
 * function: every (fileId -> buckets) reference found in the lesson document.
 */
export function extractAuthorizedLessonMedia(
  lesson: any,
  defaultBucketId = PAID_MEDIA_BUCKET_ID,
): Map<string, Set<string>> {
  const authorized = new Map<string, Set<string>>();

  const addRef = (fileId: unknown, bucketId?: unknown) => {
    const f = text(fileId);
    const b = text(bucketId || defaultBucketId);
    if (!f || !b) return;
    if (!authorized.has(f)) authorized.set(f, new Set());
    authorized.get(f)!.add(b);
  };

  const parseStringRef = (str: string) => {
    const trimmed = str.trim();
    if (!trimmed) return;
    const urlMatch = trimmed.match(/(?:^|\/)storage\/buckets\/([a-zA-Z0-9._-]+)\/files\/([a-zA-Z0-9._-]+)/);
    if (urlMatch) {
      addRef(urlMatch[2], urlMatch[1]);
      return;
    }
    const uriMatch = trimmed.match(/^(?:appwrite-storage:\/\/|appwrite-file:)([a-zA-Z0-9._-]+)[/:]([a-zA-Z0-9._-]+)(?:\?.*)?$/);
    if (uriMatch) addRef(uriMatch[2], uriMatch[1]);
  };

  const scanValue = (val: any, depth = 0): void => {
    if (!val || depth > 8) return;
    if (typeof val === 'string') {
      parseStringRef(val);
      const trimmed = val.trim();
      if ((trimmed.startsWith('{') && trimmed.endsWith('}')) || (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
        try {
          scanValue(JSON.parse(trimmed), depth + 1);
        } catch (_) {}
      }
      return;
    }
    if (Array.isArray(val)) {
      for (const item of val) scanValue(item, depth + 1);
      return;
    }
    if (typeof val === 'object') {
      if (val.fileId || val.mediaFileId) addRef(val.fileId || val.mediaFileId, val.bucketId);
      for (const key of Object.keys(val)) scanValue(val[key], depth + 1);
    }
  };

  for (const field of [
    'thumbnailUrl', 'heroMediaUrl', 'heroPosterUrl', 'audioUrl', 'hero_media',
    'mediaFileId', 'mediaFileIds', 'mediaFiles', 'data', 'blocks',
  ]) {
    scanValue(lesson?.[field]);
  }
  return authorized;
}

function base64Url(bytes: ArrayBuffer): string {
  let binary = '';
  for (const b of new Uint8Array(bytes)) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

async function signMedia(secret: string, fileId: string, exp: number, uid: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const message = `olitun-media-v${MEDIA_PROTOCOL_VERSION}\n${fileId}\n${exp}\n${uid}`;
  return base64Url(await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(message)));
}

/**
 * The get_media branch of /api/v1/lessons/authorize. Called only after the
 * caller's entitlement to the lesson has been decided from D1.
 */
export async function issuePaidMediaLease(
  c: Ctx,
  opts: { lesson: any; unlocked: boolean; userId: string; body: any },
): Promise<Response> {
  const { lesson, unlocked, userId, body } = opts;
  if (!unlocked) {
    return c.json({ ok: false, locked: true, error: 'access_denied', reason: 'purchase_required' }, 403, MEDIA_HEADERS);
  }

  const fileId = text(body?.fileId);
  if (!ID_PATTERN.test(fileId)) {
    return c.json({ ok: false, error: 'invalid_file', message: 'Missing or invalid fileId' }, 400, MEDIA_HEADERS);
  }
  const requestedBucketId = text(body?.bucketId) || PAID_MEDIA_BUCKET_ID;
  const permittedBuckets = extractAuthorizedLessonMedia(lesson).get(fileId);
  if (!permittedBuckets) {
    return c.json({ ok: false, error: 'media_not_associated', message: 'Requested file is not associated with this lesson' }, 403, MEDIA_HEADERS);
  }
  if (!permittedBuckets.has(requestedBucketId)) {
    return c.json({ ok: false, error: 'bucket_mismatch', message: 'File is not associated with the requested bucket' }, 403, MEDIA_HEADERS);
  }
  if (requestedBucketId !== PAID_MEDIA_BUCKET_ID) {
    return c.json({ ok: false, error: 'bucket_not_permitted', message: 'Requested bucket is not a private media bucket' }, 403, MEDIA_HEADERS);
  }
  // Old clients fail explicitly; never fall back to another transport.
  if (body?.protocolVersion !== MEDIA_PROTOCOL_VERSION) {
    return c.json({ ok: false, error: 'media_client_upgrade_required' }, 426, MEDIA_HEADERS);
  }

  const secret = c.env.MEDIA_SIGNING_SECRET;
  if (!secret) {
    return c.json({ ok: false, error: 'media_not_configured' }, 503, MEDIA_HEADERS);
  }

  // Metadata only; the bytes are served by the streaming route.
  const object = await c.env.ASSETS.head(r2Key(fileId));
  if (!object) {
    return c.json({ ok: false, error: 'media_not_found' }, 404, MEDIA_HEADERS);
  }

  const uid = userId || 'anonymous';
  const exp = Math.floor(Date.now() / 1000) + MEDIA_TTL_SECONDS;
  const sig = await signMedia(secret, fileId, exp, uid);
  // Same origin the client called, so it can pin the host it trusts.
  const url = new URL(`/api/v1/media/paid/${encodeURIComponent(fileId)}`, c.req.url);
  url.search = new URLSearchParams({ exp: String(exp), uid, sig }).toString();

  return c.json({
    ok: true,
    protocolVersion: MEDIA_PROTOCOL_VERSION,
    transport: MEDIA_TRANSPORT,
    bucketId: PAID_MEDIA_BUCKET_ID,
    fileId,
    url: url.toString(),
    expiresAt: new Date(exp * 1000).toISOString(),
    mimeType: object.httpMetadata?.contentType || null,
    size: object.size,
  }, 200, MEDIA_HEADERS);
}

type ByteRange = { offset: number; length: number };

// Single byte range only (what audio/video players send). Returns null when
// absent or unparseable (serve the whole file) and 'unsatisfiable' for 416.
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

async function servePaidMedia(c: Ctx): Promise<Response> {
  const secret = c.env.MEDIA_SIGNING_SECRET;
  if (!secret) return c.json({ ok: false, error: 'media_not_configured' }, 503, MEDIA_HEADERS);

  const fileId = c.req.param('fileId') || '';
  const expRaw = c.req.query('exp') || '';
  const uid = c.req.query('uid') || '';
  const sig = c.req.query('sig') || '';
  const now = Math.floor(Date.now() / 1000);
  const exp = /^\d{1,12}$/.test(expRaw) ? Number(expRaw) : 0;

  const forbidden = () => c.json({ ok: false, error: 'media_access_denied' }, 403, MEDIA_HEADERS);
  if (!ID_PATTERN.test(fileId) || !UID_PATTERN.test(uid) || !sig) return forbidden();
  // Expired, or further out than any lease we issue (bounded lifetime).
  if (exp <= now || exp > now + MEDIA_TTL_SECONDS + CLOCK_SKEW_SECONDS) return forbidden();
  const expected = await signMedia(secret, fileId, exp, uid);
  if (!timingSafeEqualStr(sig, expected)) return forbidden();

  const key = r2Key(fileId);
  const meta = await c.env.ASSETS.head(key);
  if (!meta) return c.json({ ok: false, error: 'media_not_found' }, 404, MEDIA_HEADERS);

  const headers = new Headers({
    'Content-Type': meta.httpMetadata?.contentType || 'application/octet-stream',
    'Accept-Ranges': 'bytes',
    'Cache-Control': 'private, max-age=0, no-transform',
    'X-Content-Type-Options': 'nosniff',
    ETag: meta.httpEtag,
  });

  const range = parseRange(c.req.header('range'), meta.size);
  if (range === 'unsatisfiable') {
    headers.set('Content-Range', `bytes */${meta.size}`);
    return new Response(null, { status: 416, headers });
  }

  const status = range ? 206 : 200;
  const length = range ? range.length : meta.size;
  headers.set('Content-Length', String(length));
  if (range) headers.set('Content-Range', `bytes ${range.offset}-${range.offset + range.length - 1}/${meta.size}`);

  if (c.req.method === 'HEAD') return new Response(null, { status, headers });

  const object = await c.env.ASSETS.get(key, range ? { range } : undefined);
  if (!object) return c.json({ ok: false, error: 'media_not_found' }, 404, MEDIA_HEADERS);
  return new Response(object.body, { status, headers });
}

export function registerPaidMediaRoutes(app: App): void {
  // No JWT middleware: media players cannot attach one. Access is the HMAC
  // signature minted by /api/v1/lessons/authorize for an entitled caller.
  app.on(['GET', 'HEAD'], '/api/v1/media/paid/:fileId', servePaidMedia);
}
