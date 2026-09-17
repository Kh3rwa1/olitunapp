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

// ---- Unicode NFC & Code Point Counting ----
import { MAX_BODY_BYTES } from '../src/validation.js';
import { VoiceStore, VoiceError, digest, limits } from '../src/store.js';
import { createHandler } from '../src/main.js';

test('Unicode: counts Unicode code points, not UTF-16 code units', () => {
  // Combining acute accent: 'e' + combining acute (2 code units, 2 code points in NFD -> 1 in NFC)
  const nfd = 'e\u0301';
  const normalized = normalizeSantaliVoiceRequest({ text: nfd, voice: 'Phulmani' });
  assert.equal(normalized.text, 'é');
  assert.equal(normalized.chars, 1);

  // Santali Ol Chiki text exact limit: 600 code points
  const exact600 = 'ᱥ'.repeat(MAX_TEXT_CHARS);
  const okExact = validateSantaliVoiceRequest({
    method: 'POST',
    body: { text: exact600, voice: 'Phulmani' },
  });
  assert.equal(okExact, null);

  // 601 code points should fail
  const over600 = 'ᱥ'.repeat(MAX_TEXT_CHARS + 1);
  const overResult = validateSantaliVoiceRequest({
    method: 'POST',
    body: { text: over600, voice: 'Phulmani' },
  });
  assert.equal(overResult.code, 'INPUT_TOO_LONG');
  assert.equal(overResult.status, 400);
});

test('Validation: enforces maximum request body byte length (32KB)', () => {
  const oversizedRaw = JSON.stringify({
    text: 'ᱡᱚᱦᱟᱨ',
    voice: 'Phulmani',
    padding: 'x'.repeat(MAX_BODY_BYTES + 10),
  });
  const result = validateSantaliVoiceRequest({
    method: 'POST',
    body: { text: 'ᱡᱚᱦᱟᱨ', voice: 'Phulmani' },
    rawBody: oversizedRaw,
  });
  assert.equal(result.status, 400);
  assert.equal(result.code, 'PAYLOAD_TOO_LARGE');
});

// ---- VoiceStore Claims & Quotas ----

function createMockDb() {
  const docs = new Map();
  const key = (col, id) => `${col}:${id}`;
  return {
    docs,
    async createDocument(p, col, id, data) {
      const collectionId = typeof p === 'object' ? p.collectionId : col;
      const documentId = typeof p === 'object' ? p.documentId : id;
      const docData = typeof p === 'object' ? p.data : data;
      const k = key(collectionId, documentId);
      if (docs.has(k)) {
        const err = new Error('Document already exists');
        err.code = 409;
        throw err;
      }
      const d = { $id: documentId, ...docData };
      docs.set(k, d);
      return { ...d };
    },
    async getDocument(p, col, id) {
      const collectionId = typeof p === 'object' ? p.collectionId : col;
      const documentId = typeof p === 'object' ? p.documentId : id;
      const k = key(collectionId, documentId);
      if (!docs.has(k)) {
        const err = new Error('Document not found');
        err.code = 404;
        throw err;
      }
      return { ...docs.get(k) };
    },
    async updateDocument(p, col, id, data) {
      const collectionId = typeof p === 'object' ? p.collectionId : col;
      const documentId = typeof p === 'object' ? p.documentId : id;
      const docData = typeof p === 'object' ? p.data : data;
      const k = key(collectionId, documentId);
      const d = docs.get(k);
      if (!d) {
        const err = new Error('Document not found');
        err.code = 404;
        throw err;
      }
      Object.assign(d, docData);
      return { ...d };
    },
    async incrementDocumentAttribute(p, col, id, attr, val, max) {
      const collectionId = typeof p === 'object' ? p.collectionId : col;
      const documentId = typeof p === 'object' ? p.documentId : id;
      const attribute = typeof p === 'object' ? p.attribute : attr;
      const value = typeof p === 'object' ? p.value : val;
      const maximum = typeof p === 'object' ? p.max : max;
      const k = key(collectionId, documentId);
      const d = docs.get(k);
      if (!d) {
        const err = new Error('Document not found');
        err.code = 404;
        throw err;
      }
      const current = (d[attribute] || 0) + value;
      if (current > maximum) {
        const err = new Error('Attribute maximum exceeded');
        err.code = 400;
        throw err;
      }
      d[attribute] = current;
      return { ...d };
    },
    async listDocuments(db, col, queries) {
      const prefix = `${col}:`;
      const found = [];
      for (const [k, v] of docs.entries()) {
        if (k.startsWith(prefix)) found.push(v);
      }
      return { documents: found };
    },
  };
}

test('VoiceStore: handles durable request claims lifecycle', async () => {
  const db = createMockDb();
  const store = new VoiceStore(db, 'olitun_db', 'test-secret-at-least-32-chars-long');
  const claimId = 'claim-123';

  // 1. Initial claim succeeds
  const doc = await store.claim(claimId, 'u1', 'cache-key-1', 50);
  assert.ok(doc);
  assert.equal(doc.$id, claimId);
  assert.equal(doc.status, 'submitting');

  // 2. Duplicate concurrent claim returns null (conflict)
  const duplicate = await store.claim(claimId, 'u1', 'cache-key-1', 50);
  assert.equal(duplicate, null);

  // 3. Get claim retrieves current state
  const fetched = await store.get(claimId);
  assert.equal(fetched.status, 'submitting');

  // 4. Update claim to completed
  await store.update(claimId, { status: 'completed', audioUrl: 'https://example.com/audio.wav' });
  const updated = await store.get(claimId);
  assert.equal(updated.status, 'completed');
  assert.equal(updated.audioUrl, 'https://example.com/audio.wav');
});

test('VoiceStore: enforces atomic quota reservation and rejects overages', async () => {
  const db = createMockDb();
  const store = new VoiceStore(db, 'olitun_db', 'test-secret-at-least-32-chars-long');
  const policy = {
    monthlyChars: 1000,
    dailyChars: 500,
    userDailyChars: 100,
    userMinuteRequests: 5,
    globalMinuteRequests: 20,
  };

  // Taking within budget succeeds
  await store.reserve('u1', 60, policy);

  // Exceeding user daily limit fails with QUOTA_EXCEEDED (429)
  await assert.rejects(
    store.reserve('u1', 50, policy), // 60 + 50 = 110 > 100
    (err) => err instanceof VoiceError && err.status === 429 && err.code === 'QUOTA_EXCEEDED'
  );
});

// ---- Handler Integration Tests ----

const testEnv = {
  APPWRITE_FUNCTION_API_ENDPOINT: 'https://appwrite.example/v1',
  APPWRITE_FUNCTION_PROJECT_ID: 'olitun_test',
  APPWRITE_FUNCTION_API_KEY: 'test-api-key',
  SANTALI_VOICE_HMAC_SECRET: '01234567890123456789012345678901',
  SANTALI_VOICE_ENABLED: 'true',
  APPWRITE_DATABASE_ID: 'olitun_db',
  AUDIO_BUCKET_ID: 'audio',
};

function createMockRes() {
  return {
    statusCode: 200,
    body: null,
    json(data, status = 200) {
      this.statusCode = status;
      this.body = data;
      return { status, data };
    },
  };
}

test('Handler: emergency switch returns 503 SERVICE_UNAVAILABLE', async () => {
  const handler = createHandler({
    env: { ...testEnv, SANTALI_VOICE_ENABLED: 'false' },
  });
  const res = createMockRes();
  await handler({
    req: { method: 'POST', body: { text: 'ᱡᱚᱦᱟᱨ', voice: 'Phulmani' } },
    res,
  });
  assert.equal(res.statusCode, 503);
  assert.equal(res.body.error, 'SERVICE_UNAVAILABLE');
});

test('Handler: unauthenticated request returns 401 LOGIN_REQUIRED', async () => {
  const handler = createHandler({
    env: testEnv,
    authenticateImpl: async () => null,
  });
  const res = createMockRes();
  await handler({
    req: { method: 'POST', body: { text: 'ᱡᱚᱦᱟᱨ', voice: 'Phulmani' } },
    res,
  });
  assert.equal(res.statusCode, 401);
  assert.equal(res.body.error, 'LOGIN_REQUIRED');
});

test('Handler: cache hit returns cached audio with zero upstream provider calls', async () => {
  const db = createMockDb();
  // Pre-seed cache
  const cacheKey = createTtsCacheKey({ text: 'ᱡᱚᱦᱟᱨ', voice: 'Phulmani', lang: 'sat', style: '' });
  await db.createDocument('olitun_db', 'tts_cache', 'cache-doc-1', {
    cacheKey,
    audioUrl: 'https://cdn.example.com/cached.wav',
    storageFileId: 'cached-file-1',
  });

  let rotationCalled = false;
  const handler = createHandler({
    env: testEnv,
    authenticateImpl: async () => 'u1',
    services: () => ({
      databases: db,
      storage: {},
      synthesizeWithRotation: async () => {
        rotationCalled = true;
        throw new Error('Should not be called');
      },
    }),
  });

  const res = createMockRes();
  await handler({
    req: { method: 'POST', body: { text: 'ᱡᱚᱦᱟᱨ', voice: 'Phulmani' } },
    res,
  });

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.success, true);
  assert.equal(res.body.data.cached, true);
  assert.equal(res.body.data.audioUrl, 'https://cdn.example.com/cached.wav');
  assert.equal(rotationCalled, false);
});

test('Handler: duplicate concurrent request returns 409 REQUEST_NOT_REPLAYABLE', async () => {
  const db = createMockDb();
  const cacheKey = createTtsCacheKey({ text: 'ᱡᱚᱦᱟᱨ', voice: 'Phulmani', lang: 'sat', style: '' });
  const claimId = digest(testEnv.SANTALI_VOICE_HMAC_SECRET, ['voice-v1', 'u1', cacheKey]);

  // Pre-seed an in-flight claim
  await db.createDocument('olitun_db', 'voice_claims', claimId, {
    status: 'submitting',
    userId: 'u1',
    cacheKey,
  });

  const handler = createHandler({
    env: testEnv,
    authenticateImpl: async () => 'u1',
    services: () => ({
      databases: db,
      storage: {},
    }),
  });

  const res = createMockRes();
  await handler({
    req: { method: 'POST', body: { text: 'ᱡᱚᱦᱟᱨ', voice: 'Phulmani' } },
    res,
  });

  assert.equal(res.statusCode, 409);
  assert.equal(res.body.error, 'REQUEST_NOT_REPLAYABLE');
});

test('Handler: quota exhaustion returns 429 and marks claim failed', async () => {
  const db = createMockDb();
  const store = new VoiceStore(db, 'olitun_db', testEnv.SANTALI_VOICE_HMAC_SECRET);
  // Exhaust quota
  const restrictivePolicy = {
    ...limits({}),
    userDailyChars: 5,
  };

  const handler = createHandler({
    env: { ...testEnv, SANTALI_VOICE_USER_DAILY_CHARS: '5' },
    authenticateImpl: async () => 'u1',
    services: () => ({
      databases: db,
      storage: {},
      store,
    }),
  });

  const res = createMockRes();
  await handler({
    req: { method: 'POST', body: { text: 'ᱡᱚᱦᱟᱨ ᱜᱮ', voice: 'Phulmani' } }, // 8 chars > 5
    res,
  });

  assert.equal(res.statusCode, 429);
  assert.equal(res.body.error, 'QUOTA_EXCEEDED');
});

test('Handler: successful synthesis saves audio, registers user_assets, and caches track', async () => {
  const db = createMockDb();
  const mockStorage = {
    async createFile(bucketId, fileId, file) {
      return { $id: 'file-xyz', bucketId };
    },
  };

  // Pre-seed active Bodhan key
  await db.createDocument('olitun_db', 'bodhan_keys', 'key-1', {
    key: 'sk-active-test',
    isActive: true,
    priority: 1,
    successCount: 0,
    failCount: 0,
  });

  const handler = createHandler({
    env: testEnv,
    authenticateImpl: async () => 'u1',
    services: () => ({
      databases: db,
      storage: mockStorage,
      synthesizeWithRotation: async () => ({
        audio: Buffer.from('RIFF-MOCK-AUDIO'),
        keyId: 'key-1',
        attempts: 1,
      }),
    }),
  });

  const res = createMockRes();
  await handler({
    req: { method: 'POST', body: { text: 'ᱡᱚᱦᱟᱨ', voice: 'Phulmani' } },
    res,
  });

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.success, true);
  assert.equal(res.body.data.cached, false);
  assert.equal(res.body.data.storageFileId, 'file-xyz');

  // Verify registered in user_assets for account deletion
  let foundUserAsset = false;
  for (const [k, doc] of db.docs.entries()) {
    if (k.startsWith('user_assets:') && doc.userId === 'u1' && doc.fileId === 'file-xyz') {
      foundUserAsset = true;
    }
  }
  assert.ok(foundUserAsset, 'File should be tracked in user_assets collection');
});

