import assert from 'node:assert/strict';
import test from 'node:test';
import {
  ALLOWED_LANGS,
  ALLOWED_STYLES,
  ALLOWED_VOICES,
  DEFAULT_LANG,
  DEFAULT_VOICE,
  MAX_TEXT_CHARS,
  createTtsCacheKey,
  normalizeSantaliVoiceRequest,
  validateSantaliVoiceRequest,
} from '../src/validation.js';
import { shouldDisableKey, synthesizeWithKey } from '../src/bodhan_client.js';
import { synthesizeWithRotation } from '../src/key_rotation.js';

// ---- Validation ----

test('Validation: rejects non-POST methods', () => {
  const result = validateSantaliVoiceRequest({ method: 'GET', body: {} });
  assert.equal(result.status, 405);
});

test('Validation: rejects empty text', () => {
  const result = validateSantaliVoiceRequest({
    method: 'POST',
    body: { text: '   ', voice: 'Phulmani', lang: 'sat' },
  });
  assert.equal(result.status, 400);
  assert.equal(result.code, 'INVALID_INPUT');
});

test('Validation: rejects over-long text', () => {
  const result = validateSantaliVoiceRequest({
    method: 'POST',
    body: { text: 'ᱟ'.repeat(MAX_TEXT_CHARS + 1), voice: 'Phulmani' },
  });
  assert.equal(result.status, 400);
  assert.equal(result.code, 'INPUT_TOO_LONG');
});

test('Validation: rejects unknown voice and style, accepts Santali defaults', () => {
  assert.ok(ALLOWED_VOICES.has('Phulmani'));
  assert.ok(ALLOWED_VOICES.has('Sibu'));
  assert.equal(ALLOWED_VOICES.size, 2);
  assert.equal(DEFAULT_VOICE, 'Phulmani');
  assert.equal(DEFAULT_LANG, 'sat');
  assert.ok(ALLOWED_LANGS.has('sat'));
  assert.ok(ALLOWED_STYLES.has('news'));

  const badVoice = validateSantaliVoiceRequest({
    method: 'POST',
    body: { text: 'ᱡᱚᱦᱟᱨ', voice: 'Nobody' },
  });
  assert.equal(badVoice.code, 'UNSUPPORTED_VOICE');

  // Non-Santali Bodhan voices are rejected too — Santali-only product.
  const nonSantaliVoice = validateSantaliVoiceRequest({
    method: 'POST',
    body: { text: 'ᱡᱚᱦᱟᱨ', voice: 'Kavya' },
  });
  assert.equal(nonSantaliVoice.code, 'UNSUPPORTED_VOICE');

  const badStyle = validateSantaliVoiceRequest({
    method: 'POST',
    body: { text: 'ᱡᱚᱦᱟᱨ', voice: 'Phulmani', style: 'opera' },
  });
  assert.equal(badStyle.code, 'UNSUPPORTED_STYLE');

  const okNeutral = validateSantaliVoiceRequest({
    method: 'POST',
    body: { text: 'ᱟᱢᱟᱜ ᱧᱩᱛᱩᱢ ᱫᱚ ᱪᱮᱫ ᱠᱟᱱᱟ?', voice: 'Phulmani' },
  });
  assert.equal(okNeutral, null);
});

test('normalize: applies Santali defaults and trims style', () => {
  const n = normalizeSantaliVoiceRequest({ text: ' ᱡᱚᱦᱟᱨ ', voice: '', lang: '', style: ' news ' });
  assert.equal(n.text, 'ᱡᱚᱦᱟᱨ');
  assert.equal(n.voice, 'Phulmani');
  assert.equal(n.lang, 'sat');
  assert.equal(n.style, 'news');
});

test('cache key: stable for identical inputs, distinct across voice/style', () => {
  const a = createTtsCacheKey({ text: 'ᱡᱚᱦᱟᱨ', voice: 'Phulmani', lang: 'sat', style: '' });
  const b = createTtsCacheKey({ text: 'ᱡᱚᱦᱟᱨ', voice: 'Phulmani', lang: 'sat', style: '' });
  const c = createTtsCacheKey({ text: 'ᱡᱚᱦᱟᱨ', voice: 'Sibu', lang: 'sat', style: '' });
  const d = createTtsCacheKey({ text: 'ᱡᱚᱦᱟᱨ', voice: 'Phulmani', lang: 'sat', style: 'news' });
  assert.equal(a, b);
  assert.notEqual(a, c);
  assert.notEqual(a, d);
});

// ---- Bodhan client classification ----

function fakeFetch(status, body, contentType = 'audio/wav') {
  return async () => ({
    ok: status >= 200 && status < 300,
    status,
    headers: { get: () => contentType },
    arrayBuffer: async () => Buffer.from(typeof body === 'string' ? body : 'wav-bytes'),
    text: async () => (typeof body === 'string' ? body : ''),
  });
}

const baseInput = { text: 'ᱡᱚᱦᱟᱨ', voice: 'Phulmani', lang: 'sat', style: '' };

test('bodhan client: returns audio buffer on 200 wav', async () => {
  const { audio } = await synthesizeWithKey({
    ...baseInput,
    apiKey: 'sk-test',
    fetchImpl: fakeFetch(200, Buffer.from('RIFF....')),
  });
  assert.ok(Buffer.isBuffer(audio));
});

test('bodhan client: classifies auth/credit/validation failures', async () => {
  await assert.rejects(
    synthesizeWithKey({ ...baseInput, apiKey: 'bad', fetchImpl: fakeFetch(401, 'invalid api key', 'application/json') }),
    (e) => e.reason === 'invalid_key'
  );
  await assert.rejects(
    synthesizeWithKey({ ...baseInput, apiKey: 'poor', fetchImpl: fakeFetch(402, 'insufficient credits', 'application/json') }),
    (e) => e.reason === 'credit_ended'
  );
  await assert.rejects(
    synthesizeWithKey({ ...baseInput, apiKey: 'ok', fetchImpl: fakeFetch(422, 'unknown voice', 'application/json') }),
    (e) => e.reason === 'bad_request'
  );
  await assert.rejects(
    synthesizeWithKey({ ...baseInput, apiKey: 'ok', fetchImpl: fakeFetch(429, 'slow down', 'application/json') }),
    (e) => e.reason === 'rate_limited'
  );
});

test('shouldDisableKey: only dead/exhausted keys are disabled', () => {
  assert.equal(shouldDisableKey('invalid_key'), true);
  assert.equal(shouldDisableKey('credit_ended'), true);
  assert.equal(shouldDisableKey('rate_limited'), false);
  assert.equal(shouldDisableKey('upstream_error'), false);
  assert.equal(shouldDisableKey('bad_request'), false);
});

// ---- Rotation ----

function fakeDatabases() {
  return { updates: [], async updateDocument(db, col, id, patch) { this.updates.push({ id, patch }); } };
}

test('rotation: falls over to the next key when credit ends', async () => {
  const dbs = fakeDatabases();
  const keys = [
    { $id: 'k1', key: 'sk-dead', successCount: 0, failCount: 0 },
    { $id: 'k2', key: 'sk-live', successCount: 0, failCount: 0 },
  ];
  const fetchImpl = async (url, { headers }) => {
    if (headers.Authorization === 'Bearer sk-dead') {
      return { ok: false, status: 402, headers: { get: () => 'application/json' }, text: async () => 'out of credits' };
    }
    return { ok: true, status: 200, headers: { get: () => 'audio/wav' }, arrayBuffer: async () => Buffer.from('RIFF') };
  };
  const result = await synthesizeWithRotation({
    databases: dbs,
    dbId: 'olitun_db',
    keys,
    text: 'ᱡᱚᱦᱟᱨ',
    voice: 'Phulmani',
    lang: 'sat',
    style: '',
    fetchImpl,
  });
  assert.equal(result.keyId, 'k2');
  assert.equal(result.attempts, 2);
  const disabled = dbs.updates.find((u) => u.id === 'k1');
  assert.equal(disabled.patch.isActive, false);
});

test('rotation: 422 never burns the next key', async () => {
  const dbs = fakeDatabases();
  let calls = 0;
  const fetchImpl = async () => {
    calls += 1;
    return { ok: false, status: 422, headers: { get: () => 'application/json' }, text: async () => 'unknown voice' };
  };
  await assert.rejects(
    synthesizeWithRotation({
      databases: dbs,
      dbId: 'olitun_db',
      keys: [{ $id: 'k1', key: 'sk-1' }, { $id: 'k2', key: 'sk-2' }],
      text: 'ᱡᱚᱦᱟᱨ',
      voice: 'Phulmani',
      lang: 'sat',
      style: '',
      fetchImpl,
    }),
    (e) => e.reason === 'bad_request'
  );
  assert.equal(calls, 1);
});

test('rotation: throws ALL_KEYS_EXHAUSTED when every key fails', async () => {
  const dbs = fakeDatabases();
  const fetchImpl = async () => ({
    ok: false,
    status: 500,
    headers: { get: () => 'application/json' },
    text: async () => 'boom',
  });
  await assert.rejects(
    synthesizeWithRotation({
      databases: dbs,
      dbId: 'olitun_db',
      keys: [{ $id: 'k1', key: 'sk-1' }],
      text: 'ᱡᱚᱦᱟᱨ',
      voice: 'Phulmani',
      lang: 'sat',
      style: '',
      fetchImpl,
    }),
    (e) => e.code === 'ALL_KEYS_EXHAUSTED'
  );
});
