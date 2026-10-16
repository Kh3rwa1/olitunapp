// Sarvam Document AI (Sarvam Vision) OCR for AI Studio "Scan".
//
// Flow: POST /doc-ai/v1/job/digitise (multipart file + language), poll
// GET /doc-ai/v1/job/{id}/status until terminal, then
// GET /doc-ai/v1/job/{id}/results?format=html, whose text is in
// documents[].pages[].content. Digitise jobs produce HTML by default and
// Sarvam refuses other formats for them ("job produced html, cannot serve
// md"), so the HTML is converted to plain text here.
//
// A one-page scan usually finishes in seconds, so the start request waits
// for it and returns the text directly. If Sarvam is still working when the
// wait ends, the app gets a job token and polls (action ocrStatus). Sarvam
// job ids ("20260707_<uuid>", 45 chars) exceed the app's 36-char job id
// limit, so the token packs the id into 27 base64url chars plus an 8-char
// HMAC tag that binds it to the signed-in user.

const ORIGIN = 'https://api.sarvam.ai';
const TERMINAL = new Set(['completed', 'partially_completed', 'failed', 'rejected']);
const SUCCESS = new Set(['completed', 'partially_completed']);

export const OCR_FILE_TYPES: Record<string, string> = {
  pdf: 'application/pdf',
  png: 'image/png',
  jpg: 'image/jpeg',
  jpeg: 'image/jpeg',
};

export class OcrError extends Error {
  constructor(public code: string, public status: number, message: string) {
    super(message);
  }
}

export type OcrJob = { jobId: string; status: string; text?: string };

type Deps = {
  apiKey: string;
  secret: string;
  userId: string;
  fetchImpl?: typeof fetch;
  sleep?: (ms: number) => Promise<void>;
  /** Total time the start request waits for the job, in ms. */
  waitMs?: number;
  pollMs?: number;
};

async function sarvam(deps: Deps, path: string, init: RequestInit = {}, raw = false): Promise<any> {
  let res: Response;
  try {
    res = await (deps.fetchImpl ?? fetch)(`${ORIGIN}${path}`, {
      ...init,
      // Workers only accept 'follow' or 'manual'; 'error' throws before the
      // request is sent. 'manual' plus the ok check rejects any redirect.
      redirect: 'manual',
      headers: { 'api-subscription-key': deps.apiKey, ...(init.headers || {}) },
    });
  } catch (err) {
    console.error(`Sarvam OCR ${path.split('?')[0]} fetch failed: ${String(err)}`);
    throw new OcrError('PROVIDER_UNAVAILABLE', 502, 'Sarvam could not be reached.');
  }
  if (!res.ok) {
    // Never log the key; status and Sarvam's own message are enough to debug.
    const detail = (await res.clone().text().catch(() => '')).slice(0, 500);
    console.error(`Sarvam OCR ${path.split('?')[0]} -> ${res.status}: ${detail}`);
  }
  if (res.status === 400 || res.status === 413 || res.status === 422) {
    throw new OcrError('INVALID_FILE', 400, `Sarvam rejected the document (${res.status}).`);
  }
  if (res.status === 429) {
    throw new OcrError('RATE_LIMITED', 429, 'Sarvam rate limit reached.');
  }
  if (!res.ok) {
    throw new OcrError('PROVIDER_UNAVAILABLE', 502, `Sarvam request failed (${res.status}).`);
  }
  if (raw) return res.text();
  try {
    return await res.json();
  } catch {
    console.error(`Sarvam OCR ${path.split('?')[0]} -> ${res.status}: unreadable JSON`);
    throw new OcrError('PROVIDER_UNAVAILABLE', 502, 'Sarvam returned an unreadable response.');
  }
}

/** Removes markup by skipping each '<' through its next '>' (no regex). */
export function stripTags(value: string): string {
  let out = '';
  let i = 0;
  while (i < value.length) {
    const open = value.indexOf('<', i);
    if (open === -1) return out + value.slice(i);
    const close = value.indexOf('>', open + 1);
    if (close === -1) return out + value.slice(i);
    out += value.slice(i, open);
    i = close + 1;
  }
  return out;
}

const ENTITIES: Record<string, string> = { amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", nbsp: ' ' };

/** Decodes the HTML entities Sarvam may emit (named basics and numeric). */
export function decodeEntities(value: string): string {
  return value.replace(/&(#x[0-9a-f]+|#\d+|[a-z]+);/gi, (match, body: string) => {
    if (body[0] === '#') {
      const code = body[1] === 'x' || body[1] === 'X' ? parseInt(body.slice(2), 16) : parseInt(body.slice(1), 10);
      return Number.isFinite(code) && code > 0 && code <= 0x10ffff ? String.fromCodePoint(code) : match;
    }
    return ENTITIES[body.toLowerCase()] ?? match;
  });
}

/** Page HTML to plain text: line and block breaks kept, tags dropped. */
export function htmlToText(html: string): string {
  const withBreaks = html
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<\/(p|div|h[1-6]|li|tr|table|section|article|blockquote|pre)\s*>/gi, '\n')
    .replace(/<\/t[dh]\s*>/gi, ' ');
  return decodeEntities(stripTags(withBreaks));
}

/** The <body> of a full HTML document (drops <head>, styles and scripts). */
export function htmlBody(html: string): string {
  const open = html.search(/<body[\s>]/i);
  const close = html.search(/<\/body\s*>/i);
  const body = open >= 0 ? html.slice(html.indexOf('>', open) + 1, close > open ? close : undefined) : html;
  return dropBlocks(body, ['script', 'style']);
}

/**
 * Removes whole <script>/<style> elements with a scanner rather than a
 * regex (regex removal can leave fragments that re-form a tag). Each pass
 * cuts from the opening tag through its closing tag, or to the end when it
 * is unterminated, so no opening tag survives.
 */
export function dropBlocks(html: string, names: string[]): string {
  let out = html;
  for (;;) {
    const lower = out.toLowerCase();
    let start = -1;
    let name = '';
    for (const n of names) {
      const at = lower.indexOf(`<${n}`);
      if (at !== -1 && (start === -1 || at < start)) {
        start = at;
        name = n;
      }
    }
    if (start === -1) return out;
    const closeAt = lower.indexOf(`</${name}`, start);
    const end = closeAt === -1 ? out.length : (lower.indexOf('>', closeAt) + 1 || out.length);
    out = out.slice(0, start) + out.slice(end);
  }
}

/** Plain text from a digitise result: pages in order, markup removed. */
export function resultText(result: any): string {
  const documents = Array.isArray(result?.documents) ? result.documents : [];
  const pages = documents.flatMap((doc: any) => (Array.isArray(doc?.pages) ? doc.pages : []));
  const text = pages
    .map((page: any) => {
      if (typeof page?.content === 'string') return page.content;
      const blocks = Array.isArray(page?.blocks) ? page.blocks : [];
      return blocks
        .map((block: any) => (typeof block?.text === 'string' ? block.text : ''))
        .filter(Boolean)
        .join('\n');
    })
    .map((content: string) =>
      htmlToText(content)
        .split('\n')
        // Heading markers and emphasis are layout, not text.
        .map((line) => line.replace(/^\s{0,3}#{1,6}\s+/, '').replace(/\*\*|__/g, '').trimEnd())
        .join('\n')
        .replace(/\n{3,}/g, '\n\n')
        .trim(),
    )
    .filter(Boolean)
    .join('\n\n');
  return text.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F]/g, '');
}

// ---- Job token -----------------------------------------------------------

const SARVAM_ID = /^(\d{8})_([0-9a-f]{8})-([0-9a-f]{4})-([0-9a-f]{4})-([0-9a-f]{4})-([0-9a-f]{12})$/;

function b64url(bytes: Uint8Array): string {
  let binary = '';
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function fromB64url(value: string): Uint8Array {
  const binary = atob(value.replace(/-/g, '+').replace(/_/g, '/'));
  return Uint8Array.from(binary, (ch) => ch.charCodeAt(0));
}

async function tag(secret: string, sarvamId: string, userId: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const mac = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(`olitun-ocr-v1\n${sarvamId}\n${userId}`));
  return b64url(new Uint8Array(mac).slice(0, 6)); // 8 chars
}

/** Sarvam ids we will pass back into a URL path. */
const SAFE_ID = /^[A-Za-z0-9._:-]{1,128}$/;

/**
 * A pollable id for the app (max 36 chars), or null when the Sarvam id is
 * too long to carry; then the start request waits for the result instead.
 * "o" = compact form of the documented "YYYYMMDD_<uuid>" id,
 * "g" = any id of at most 20 bytes, base64url-encoded.
 */
export async function encodeJobToken(sarvamId: string, userId: string, secret: string): Promise<string | null> {
  const mac = await tag(secret, sarvamId, userId);
  const m = SARVAM_ID.exec(sarvamId);
  if (m) {
    const hex = m.slice(1).join(''); // 8 date digits + 32 uuid hex = 40 hex chars
    const bytes = Uint8Array.from(hex.match(/../g)!, (h) => parseInt(h, 16));
    return `o${b64url(bytes)}${mac}`; // 1 + 27 + 8 = 36
  }
  const raw = new TextEncoder().encode(sarvamId);
  if (raw.length <= 20) return `g${b64url(raw)}${mac}`; // <= 1 + 27 + 8
  return null;
}

export async function decodeJobToken(token: string, userId: string, secret: string): Promise<string> {
  const bad = () => new OcrError('INVALID_JOB', 400, 'Invalid job.');
  if (!/^[og][A-Za-z0-9_-]{9,35}$/.test(token)) throw bad();
  const body = token.slice(1, -8);
  let sarvamId: string;
  try {
    const bytes = fromB64url(body);
    if (token[0] === 'o') {
      const hex = Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('');
      if (hex.length !== 40) throw bad();
      const u = hex.slice(8);
      sarvamId = `${hex.slice(0, 8)}_${u.slice(0, 8)}-${u.slice(8, 12)}-${u.slice(12, 16)}-${u.slice(16, 20)}-${u.slice(20)}`;
    } else {
      sarvamId = new TextDecoder('utf-8', { fatal: true, ignoreBOM: false }).decode(bytes);
    }
  } catch {
    throw bad();
  }
  if (!SAFE_ID.test(sarvamId)) throw bad();
  if ((await tag(secret, sarvamId, userId)) !== token.slice(-8)) {
    throw new OcrError('INVALID_JOB', 403, 'This job belongs to another account.');
  }
  return sarvamId;
}

// ---- Job flow --------------------------------------------------------------

async function check(deps: Deps, sarvamId: string): Promise<{ status: string; text?: string }> {
  const path = `/doc-ai/v1/job/${encodeURIComponent(sarvamId)}`;
  const status = await sarvam(deps, `${path}/status`);
  const state = typeof status?.status === 'string' ? status.status.toLowerCase() : '';
  if (!TERMINAL.has(state)) return { status: 'processing' };
  if (!SUCCESS.has(state)) {
    throw new OcrError('OCR_FAILED', 422, `Sarvam could not read this document (${state}).`);
  }
  // format=html returns the page HTML itself; other shapes are JSON with
  // documents[].pages[].content. Accept both.
  const body: string = await sarvam(deps, `${path}/results?format=html`, {}, true);
  let parsed: any = null;
  try {
    parsed = JSON.parse(body);
  } catch {
    // Not JSON: the HTML document itself.
  }
  const text = parsed && typeof parsed === 'object'
    ? resultText(parsed)
    : resultText({ documents: [{ pages: [{ content: htmlBody(body) }] }] });
  if (!text) {
    console.error(`Sarvam OCR results: no text (${body.length} chars): ${body.slice(0, 300)}`);
    throw new OcrError('EMPTY_RESULT', 422, 'No text was found in this document.');
  }
  return { status: state, text };
}

async function waitFor(deps: Deps, sarvamId: string, waitMs: number): Promise<{ status: string; text?: string }> {
  const sleep = deps.sleep ?? ((ms: number) => new Promise<void>((r) => setTimeout(r, ms)));
  const deadline = Date.now() + waitMs;
  const pollMs = deps.pollMs ?? 1500;
  for (;;) {
    const result = await check(deps, sarvamId);
    if (result.status !== 'processing' || Date.now() + pollMs > deadline) return result;
    await sleep(pollMs);
  }
}

function toJob(token: string | null, result: { status: string; text?: string }): OcrJob {
  if (result.text !== undefined) return { jobId: token ?? 'done', status: result.status, text: result.text };
  if (!token) throw new OcrError('OCR_TIMEOUT', 504, 'The scan took too long. Try a smaller or clearer page.');
  return { jobId: token, status: result.status };
}

export async function startOcr(
  deps: Deps,
  file: { bytes: Uint8Array; name: string },
  language: string,
): Promise<OcrJob> {
  const ext = file.name.split('.').pop()?.toLowerCase() || '';
  const mime = OCR_FILE_TYPES[ext];
  if (!mime || file.bytes.length === 0 || file.bytes.length > 10 * 1024 * 1024) {
    throw new OcrError('INVALID_FILE', 400, 'Upload a PDF, PNG or JPG up to 10 MB.');
  }
  const form = new FormData();
  form.set('file', new Blob([file.bytes], { type: mime }), `document.${ext}`);
  if (language) form.set('language', language);
  const created = await sarvam(deps, '/doc-ai/v1/job/digitise', { method: 'POST', body: form });
  const rawId = created?.job_id ?? created?.jobId ?? created?.id;
  const sarvamId = typeof rawId === 'string' ? rawId : '';
  if (!SAFE_ID.test(sarvamId)) {
    console.error(`Sarvam OCR digitise: no usable job id (keys: ${Object.keys(created ?? {}).join(',')})`);
    throw new OcrError('PROVIDER_UNAVAILABLE', 502, 'Sarvam did not confirm the job.');
  }
  const token = await encodeJobToken(sarvamId, deps.userId, deps.secret);
  // Without a pollable token, wait longer: the app allows 60 s per request.
  const waitMs = deps.waitMs ?? (token ? 40_000 : 50_000);
  return toJob(token, await waitFor(deps, sarvamId, waitMs));
}

export async function ocrStatus(deps: Deps, token: string): Promise<OcrJob> {
  const sarvamId = await decodeJobToken(token, deps.userId, deps.secret);
  return toJob(token, await check(deps, sarvamId));
}
