import { describe, expect, it } from 'vitest';
import {
  OcrError,
  decodeJobToken,
  encodeJobToken,
  ocrStatus,
  resultText,
  startOcr,
} from '../src/lib/sarvam_ocr';
import { callJson, makeUser } from './helpers';

const JOB = '20261015_6eb74174-e2c3-490d-afe5-d2e7e9e2b6c7';
const SECRET = 'test-secret';
const POEM = 'ᱡᱟᱦᱮᱸ ᱥᱮᱨᱮᱧ\nᱥᱟᱱᱛᱟᱲᱤ ᱯᱟᱹᱨᱥᱤ';

type Step = { status: number; body: unknown };

/** Sarvam stand-in: answers each path from a queue, records requests. */
function sarvam(routes: Record<string, Step[]>) {
  const calls: { method: string; path: string; key: string | null; form?: FormData }[] = [];
  const fetchImpl = (async (input: any, init: any = {}) => {
    const url = new URL(String(input));
    const path = url.pathname + url.search;
    calls.push({
      method: init.method || 'GET',
      path,
      key: new Headers(init.headers).get('api-subscription-key'),
      form: init.body instanceof FormData ? init.body : undefined,
    });
    const queue = routes[path];
    if (!queue?.length) throw new Error(`unexpected Sarvam call ${path}`);
    const step = queue.length > 1 ? queue.shift()! : queue[0];
    return new Response(JSON.stringify(step.body), { status: step.status });
  }) as typeof fetch;
  return { calls, fetchImpl };
}

const deps = (fetchImpl: typeof fetch, userId = 'user_1') => ({
  apiKey: 'sk_test',
  secret: SECRET,
  userId,
  fetchImpl,
  sleep: async () => {},
  waitMs: 10_000,
  pollMs: 1,
});

const file = { bytes: new Uint8Array([0xff, 0xd8, 0xff, 0xe0]), name: 'poem.jpeg' };
const status = (s: string): Step => ({ status: 200, body: { job_id: JOB, status: s } });
const results: Step = {
  status: 200,
  body: { job_id: JOB, status: 'completed', documents: [{ pages: [{ content: `# ᱡᱟᱦᱮᱸ ᱥᱮᱨᱮᱧ\n\n\n**ᱥᱟᱱᱛᱟᱲᱤ** ᱯᱟᱹᱨᱥᱤ` }] }] },
};

describe('Sarvam OCR', () => {
  it('starts a digitise job, waits for it and returns the page text', async () => {
    const api = sarvam({
      '/doc-ai/v1/job/digitise': [{ status: 201, body: { job_id: JOB, status: 'pending', run_id: 'r1' } }],
      [`/doc-ai/v1/job/${JOB}/status`]: [status('running'), status('completed')],
      [`/doc-ai/v1/job/${JOB}/results?format=md`]: [results],
    });

    const job = await startOcr(deps(api.fetchImpl), file, 'sat-IN');

    expect(job.status).toBe('completed');
    expect(job.text).toBe('ᱡᱟᱦᱮᱸ ᱥᱮᱨᱮᱧ\n\nᱥᱟᱱᱛᱟᱲᱤ ᱯᱟᱹᱨᱥᱤ');
    expect(job.jobId).toMatch(/^[a-zA-Z0-9][a-zA-Z0-9._-]{0,35}$/); // the app's job id rule
    const start = api.calls[0];
    expect(start.method).toBe('POST');
    expect(start.key).toBe('sk_test');
    expect(start.form?.get('language')).toBe('sat-IN');
    expect((start.form?.get('file') as File).type).toBe('image/jpeg');
  });

  it('hands back a pollable token when the job outlasts the wait', async () => {
    const api = sarvam({
      '/doc-ai/v1/job/digitise': [{ status: 201, body: { job_id: JOB, status: 'pending' } }],
      [`/doc-ai/v1/job/${JOB}/status`]: [status('running')],
    });
    const job = await startOcr({ ...deps(api.fetchImpl), waitMs: 0 }, file, 'sat-IN');
    expect(job).toEqual({ jobId: expect.any(String), status: 'processing' });

    const later = sarvam({
      [`/doc-ai/v1/job/${JOB}/status`]: [status('completed')],
      [`/doc-ai/v1/job/${JOB}/results?format=md`]: [results],
    });
    const done = await ocrStatus(deps(later.fetchImpl), job.jobId);
    expect(done.text).toContain('ᱥᱟᱱᱛᱟᱲᱤ');
  });

  it('job tokens round-trip and are bound to the user', async () => {
    const token = await encodeJobToken(JOB, 'user_1', SECRET);
    expect(token).toHaveLength(36);
    await expect(decodeJobToken(token, 'user_1', SECRET)).resolves.toBe(JOB);
    await expect(decodeJobToken(token, 'user_2', SECRET)).rejects.toMatchObject({ code: 'INVALID_JOB' });
    await expect(decodeJobToken('ocr_fake', 'user_1', SECRET)).rejects.toMatchObject({ code: 'INVALID_JOB' });
  });

  it('reports failed jobs and empty pages instead of inventing text', async () => {
    const failed = sarvam({
      '/doc-ai/v1/job/digitise': [{ status: 201, body: { job_id: JOB, status: 'pending' } }],
      [`/doc-ai/v1/job/${JOB}/status`]: [status('failed')],
    });
    await expect(startOcr(deps(failed.fetchImpl), file, 'sat-IN')).rejects.toMatchObject({ code: 'OCR_FAILED' });

    const empty = sarvam({
      '/doc-ai/v1/job/digitise': [{ status: 201, body: { job_id: JOB, status: 'pending' } }],
      [`/doc-ai/v1/job/${JOB}/status`]: [status('completed')],
      [`/doc-ai/v1/job/${JOB}/results?format=md`]: [{ status: 200, body: { documents: [{ pages: [{ content: '' }] }] } }],
    });
    await expect(startOcr(deps(empty.fetchImpl), file, 'sat-IN')).rejects.toMatchObject({ code: 'EMPTY_RESULT' });
  });

  it('rejects unsupported files before calling Sarvam', async () => {
    const api = sarvam({});
    for (const bad of [{ ...file, name: 'poem.gif' }, { ...file, bytes: new Uint8Array() }]) {
      await expect(startOcr(deps(api.fetchImpl), bad, 'sat-IN')).rejects.toBeInstanceOf(OcrError);
    }
    expect(api.calls).toHaveLength(0);
  });

  it('maps Sarvam errors to app error codes', async () => {
    for (const [httpStatus, code] of [[422, 'INVALID_FILE'], [429, 'RATE_LIMITED'], [500, 'PROVIDER_UNAVAILABLE']] as const) {
      const api = sarvam({ '/doc-ai/v1/job/digitise': [{ status: httpStatus, body: {} }] });
      await expect(startOcr(deps(api.fetchImpl), file, 'sat-IN')).rejects.toMatchObject({ code });
    }
  });

  it('strips markup from page content and keeps page order', () => {
    expect(
      resultText({ documents: [{ pages: [{ content: '<p>ᱢᱤᱫ</p>' }, { content: '## ᱵᱟᱨ' }] }] }),
    ).toBe('ᱢᱤᱫ\n\nᱵᱟᱨ');
  });
});

describe('/api/v1/studio/process OCR', () => {
  it('no longer returns canned text without a provider', async () => {
    const user = makeUser();
    const res = await callJson('/api/v1/studio/process', {
      as: user,
      json: { action: 'ocrStart', language: 'sat-IN', fileBase64: 'AAAA', fileName: 'a.png' },
      env: { SARVAM_API_KEY: '' },
    });
    expect(res.status).toBe(503);
    expect(JSON.stringify(res.body)).not.toContain(POEM);
    expect(res.body.data).toBeUndefined();
  });
});
