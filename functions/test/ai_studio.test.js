import test from 'node:test';
import assert from 'node:assert/strict';
import { authenticate, privateInput, execute, createHandler } from '../aiStudio/src/main.js';
import { validateBody, wavDuration, MAX_BYTES } from '../aiStudio/src/validation.js';
import { Store, limits, JOBS } from '../aiStudio/src/store.js';
import { Sarvam } from '../aiStudio/src/sarvam.js';
const secret = 'unit-test-hmac-secret-not-production';
const env = { APPWRITE_ENDPOINT: 'https://appwrite.example/v1', APPWRITE_PROJECT_ID: 'test', APPWRITE_API_KEY: 'unit-key', SARVAM_API_KEY: 'unit-provider-key', AI_STUDIO_HMAC_SECRET: secret, AI_STUDIO_ENABLED: 'true' };
const cfg = { endpoint: env.APPWRITE_ENDPOINT, projectId: 'test' };
function fakeDb() {
  const docs = new Map();
  const key = p => `${p.collectionId}:${p.documentId}`;
  return { docs,
    async createDocument(p) { if (docs.has(key(p))) throw { code: 409 }; const d = { $id: p.documentId, ...p.data }; docs.set(key(p), d); return { ...d }; },
    async getDocument(p) { if (!docs.has(key(p))) throw { code: 404 }; return { ...docs.get(key(p)) }; },
    async updateDocument(p) { const d = docs.get(key(p)); if (!d) throw { code: 404 }; Object.assign(d, p.data); return { ...d }; },
    async incrementDocumentAttribute(p) { const d = docs.get(key(p)); if (d.used + p.value > p.max) throw { code: 400 }; d.used += p.value; return { ...d }; },
  };
}
function setup(provider = {}) {
  const db = fakeDb(), store = new Store(db, 'test', secret, () => new Date('2026-09-17T12:00:00Z'));
  return { db, store, provider, secret, userId: 'u1', policy: limits({}), body: { action: 'translate', text: 'hello', language: 'hi-IN' } };
}
function wav(seconds = 1) {
  const b = Buffer.alloc(44 + seconds * 32000); b.write('RIFF'); b.writeUInt32LE(b.length - 8, 4); b.write('WAVEfmt ', 8); b.writeUInt32LE(16, 16); b.writeUInt16LE(1, 20); b.writeUInt16LE(1, 22); b.writeUInt32LE(16000, 24); b.writeUInt32LE(32000, 28); b.writeUInt16LE(2, 32); b.writeUInt16LE(16, 34); b.write('data', 36); b.writeUInt32LE(b.length - 44, 40); return b;
}
const json = data => new Response(JSON.stringify(data), { status: 200 });

test('validated JWT identity ignores caller identity headers', async () => {
  await assert.rejects(authenticate({ headers: { 'x-appwrite-user-id': 'u1' } }, cfg), { code: 'UNAUTHENTICATED' });
  const identity = await authenticate({ headers: { authorization: 'Bearer test-jwt', 'x-appwrite-user-id': 'other' } }, cfg, () => ({ get: async () => ({ $id: 'u1' }) }));
  assert.equal(identity.userId, 'u1');
  await assert.rejects(authenticate({ headers: { 'x-appwrite-user-jwt': 'bad' } }, cfg, () => ({ get: async () => { throw new Error('secret'); } })), { code: 'UNAUTHENTICATED' });
});
test('strict action language and text validation', () => {
  for (const language of ['hi-IN', 'bn-IN', 'as-IN', 'od-IN']) assert.equal(validateBody({ action: 'translate', language, text: 'x'.repeat(2000) }).language, language);
  for (const body of [{ action: 'translate', language: 'sat-IN', text: 'hello' }, { action: 'translate', language: 'hi-IN', text: 'x'.repeat(2001) }, { action: 'ocrStart', fileId: 'f', language: 'hi-IN', url: 'https://example.test' }]) assert.throws(() => validateBody(body));
});
test('PCM duration is bounded using actual frames and consistent headers', () => {
  assert.equal(wavDuration(wav(30)), 30);
  assert.throws(() => wavDuration(wav(31)), { code: 'INVALID_AUDIO' });
  const b = wav(); b.writeUInt32LE(999999, 28); assert.throws(() => wavDuration(b));
  assert.throws(() => wavDuration(Buffer.from('not audio')));
});
test('private inputs enforce private bucket and owner-only permissions', async () => {
  const bytes = wav();
  const bucket = { fileSecurity: true, enabled: true, maximumFileSize: MAX_BYTES, $permissions: ['create("users")'] };
  const file = { $permissions: ['read("user:u1")', 'delete("user:u1")'], sizeOriginal: bytes.length, chunksUploaded: 1, chunksTotal: 1 };
  const deps = { userId: 'u1', fileId: 'f', storage: { getBucket: async () => bucket }, userStorage: { getFile: async () => file, getFileDownload: async () => bytes } };
  assert.equal((await privateInput(deps)).length, bytes.length);
  file.$permissions.push('read("users")'); await assert.rejects(privateInput(deps), { code: 'FILE_NOT_OWNED' });
  file.$permissions.pop(); bucket.$permissions.push('read("any")'); await assert.rejects(privateInput(deps), { code: 'STORAGE_UNAVAILABLE' });
});

test('concurrent identical paid requests submit once; success replay is cached', async () => {
  let calls = 0; const deps = setup({ translate: async () => { calls++; return 'ᱡᱚᱦᱟᱨ'; } });
  const outcomes = await Promise.allSettled(Array.from({ length: 10 }, () => execute(deps)));
  assert.equal(calls, 1); assert.ok(outcomes.some(o => o.status === 'fulfilled'));
  const result = await execute(deps); assert.equal(result.cached, true); assert.equal(result.text, 'ᱡᱚᱦᱟᱨ');
});
test('paid failures are never retried or refunded', async () => {
  let calls = 0; const deps = setup({ translate: async () => { calls++; throw new Error('provider secret'); } });
  await assert.rejects(execute(deps)); await assert.rejects(execute(deps), { code: 'REQUEST_NOT_REPLAYABLE' }); assert.equal(calls, 1);
});
test('atomic monthly and daily limits stop parallel reservations', async () => {
  const { store, db } = setup();
  const results = await Promise.allSettled(Array.from({ length: 20 }, () => store.reserve('u1', 200, { monthly: 1000, daily: 1000, userDaily: 1000 })));
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 5);
  assert.ok([...db.docs.values()].every(d => d.used <= 1000));
});
test('quota backend failure prevents any paid request', async () => {
  let calls = 0; const deps = setup({ translate: async () => { calls++; return 'x'; } });
  deps.store.reserve = async () => { throw new Error('database unavailable'); };
  await assert.rejects(execute(deps)); assert.equal(calls, 0);
});
test('OCR maps local jobs to owners and returns partial text', async () => {
  const deps = setup({ ocrStart: async () => 'provider-job', ocrStatus: async () => ({ status: 'partially_completed', text: 'page one' }) });
  const body = { action: 'ocrStart', language: 'sat-IN', fileId: 'f' };
  const started = await execute({ ...deps, body, input: async () => Buffer.from('%PDF-sample'), now: () => 1000 });
  assert.equal(started.status, 'processing'); assert.notEqual(started.jobId, 'provider-job');
  const poll = { ...deps, body: { action: 'ocrStatus', jobId: started.jobId }, now: () => 20000 };
  await assert.rejects(execute({ ...poll, userId: 'u2' }), { code: 'JOB_NOT_FOUND' });
  assert.equal((await execute(poll)).text, 'page one'); assert.equal((await execute(poll)).status, 'partially_completed');
});
test('REST requests use fixed endpoints, required model and confirmed response fields', async () => {
  const requests = []; const provider = new Sarvam('unit-secret', async (url, options) => { requests.push({ url, options }); return json({ translated_text: 'ᱡᱚᱦᱟᱨ', transcript: 'hello' }); });
  assert.equal(await provider.translate('नमस्ते', 'hi-IN'), 'ᱡᱚᱦᱟᱨ');
  assert.deepEqual(JSON.parse(requests[0].options.body), { input: 'नमस्ते', source_language_code: 'hi-IN', target_language_code: 'sat-IN', model: 'sarvam-translate:v1', mode: 'formal' });
  assert.equal(requests[0].url, 'https://api.sarvam.ai/translate'); assert.equal(requests[0].options.redirect, 'error');
  assert.equal(await provider.transcribe(wav(), 'sat-IN'), 'hello'); assert.equal(requests[1].options.body.get('mode'), 'transcribe'); assert.equal(requests[1].options.body.get('language_code'), 'sat-IN');
});
test('OCR REST uses md output and documents/pages/blocks results, including partial completion', async () => {
  const requests = []; const responses = [{ job_id: 'provider-job', status: 'pending' }, { job_id: 'provider-job', status: 'partially_completed' }, { type: 'digitise', job_id: 'provider-job', status: 'partially_completed', documents: [{ filename: 'input.pdf', page_count: 1, status: 'completed', pages: [{ page_num: 1, blocks: [{ block_id: 'p1-b1', text: '<b>plain</b> text', layout_tag: 'paragraph', reading_order: 1 }] }] }] }];
  const provider = new Sarvam('unit-secret', async (url, options) => { requests.push({ url, options }); return json(responses.shift()); });
  await provider.ocrStart(Buffer.from('%PDF-test'), 'sat-IN', { mime: 'application/pdf', name: 'input.pdf' });
  assert.equal(requests[0].options.body.get('output_format'), 'md'); assert.equal(requests[0].options.body.get('language'), 'sat-IN');
  assert.deepEqual(await provider.ocrStatus('provider-job'), { status: 'partially_completed', text: 'plain text' });
  assert.ok(requests[2].url.endsWith('/provider-job/results?format=json'));
});
test('provider errors do not leak input or secrets and are not retried', async () => {
  let calls = 0; const provider = new Sarvam('unit-secret', async () => { calls++; return new Response('secret input', { status: 429 }); });
  await assert.rejects(provider.translate('private input', 'hi-IN'), e => !e.message.includes('secret') && e.code === 'PROVIDER_UNAVAILABLE'); assert.equal(calls, 1);
});
test('handler returns stable envelopes and suppresses unexpected exception detail', async () => {
  const deps = setup({ translate: async () => { throw new Error('secret'); } });
  const handler = createHandler({ env, authenticateImpl: async () => ({ userId: 'u1' }), services: () => deps });
  const result = await handler({ req: { method: 'POST', body: deps.body }, res: { json: (body, status) => ({ body, status }) } });
  assert.equal(result.status, 503); assert.equal(result.body.success, false); assert.ok(!JSON.stringify(result).includes('secret'));
});
