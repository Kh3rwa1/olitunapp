// Sarvam Document AI (Sarvam Vision) OCR for AI Studio "Scan".
//
// Flow: POST /doc-ai/v1/job/digitise (multipart file + language), poll
// GET /doc-ai/v1/job/{id}/status until terminal, then
// GET /doc-ai/v1/job/{id}/results?format=md, whose text is in
// documents[].pages[].content.
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

async function sarvam(deps: Deps, path: string, init: RequestInit = {}): Promise<any> {
  let res: Response;
  try {
    res = await (deps.fetchImpl ?? fetch)(`${ORIGIN}${path}`, {
      ...init,
      redirect: 'error',
      headers: { 'api-subscription-key': deps.apiKey, ...(init.headers || {}) },
    });
  } catch {
    throw new OcrError('PROVIDER_UNAVAILABLE', 502, 'Sarvam could not be reached.');
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
  try {
    return await res.json();
  } catch {
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

/** Plain text from a digitise result: pages in order, markdown decoration removed. */
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
      stripTags(content)
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

export async function encodeJobToken(sarvamId: string, userId: string, secret: string): Promise<string> {
  const m = SARVAM_ID.exec(sarvamId);
  if (!m) throw new OcrError('PROVIDER_UNAVAILABLE', 502, 'Unexpected Sarvam job id.');
  const hex = m.slice(1).join(''); // 8 date digits + 32 uuid hex = 40 hex chars
  const bytes = Uint8Array.from(hex.match(/../g)!, (h) => parseInt(h, 16));
  return `o${b64url(bytes)}${await tag(secret, sarvamId, userId)}`; // 1 + 27 + 8 = 36
}

export async function decodeJobToken(token: string, userId: string, secret: string): Promise<string> {
  if (!/^o[A-Za-z0-9_-]{35}$/.test(token)) throw new OcrError('INVALID_JOB', 400, 'Invalid job.');
  let hex: string;
  try {
    hex = Array.from(fromB64url(token.slice(1, 28)), (b) => b.toString(16).padStart(2, '0')).join('');
  } catch {
    throw new OcrError('INVALID_JOB', 400, 'Invalid job.');
  }
  if (hex.length !== 40) throw new OcrError('INVALID_JOB', 400, 'Invalid job.');
  const u = hex.slice(8);
  const sarvamId = `${hex.slice(0, 8)}_${u.slice(0, 8)}-${u.slice(8, 12)}-${u.slice(12, 16)}-${u.slice(16, 20)}-${u.slice(20)}`;
  if ((await tag(secret, sarvamId, userId)) !== token.slice(28)) {
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
  const text = resultText(await sarvam(deps, `${path}/results?format=md`));
  if (!text) throw new OcrError('EMPTY_RESULT', 422, 'No text was found in this document.');
  return { status: state, text };
}

async function waitFor(deps: Deps, sarvamId: string): Promise<{ status: string; text?: string }> {
  const sleep = deps.sleep ?? ((ms: number) => new Promise<void>((r) => setTimeout(r, ms)));
  const deadline = Date.now() + (deps.waitMs ?? 40_000);
  const pollMs = deps.pollMs ?? 1500;
  for (;;) {
    const result = await check(deps, sarvamId);
    if (result.status !== 'processing' || Date.now() + pollMs > deadline) return result;
    await sleep(pollMs);
  }
}

async function toJob(deps: Deps, sarvamId: string, result: { status: string; text?: string }): Promise<OcrJob> {
  const jobId = await encodeJobToken(sarvamId, deps.userId, deps.secret);
  return result.text === undefined ? { jobId, status: result.status } : { jobId, status: result.status, text: result.text };
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
  const sarvamId = typeof created?.job_id === 'string' ? created.job_id : '';
  if (!SARVAM_ID.test(sarvamId)) {
    throw new OcrError('PROVIDER_UNAVAILABLE', 502, 'Sarvam did not confirm the job.');
  }
  return toJob(deps, sarvamId, await waitFor(deps, sarvamId));
}

export async function ocrStatus(deps: Deps, token: string): Promise<OcrJob> {
  const sarvamId = await decodeJobToken(token, deps.userId, deps.secret);
  return toJob(deps, sarvamId, await check(deps, sarvamId));
}
