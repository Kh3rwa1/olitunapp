import assert from 'node:assert/strict';
import test from 'node:test';
import {
  ALLOWED_SPEAKERS,
  clampPace,
  createContentHash,
  extractCleanSpeechPrompt,
  MAX_TEXT_CHARS,
  validateGenerateAudioRequest,
} from '../src/validation.js';
import { synthesizeSpeech } from '../src/sarvam_client.js';
import {
  findExistingTrack,
  generateTrack,
  parseBody,
  requireConfig,
  userIsAdmin,
} from '../src/main.js';

// ---- Validation ----

test('Validation: rejects non-POST methods', () => {
  const result = validateGenerateAudioRequest({ method: 'GET', body: {} });
  assert.equal(result.status, 405);
  assert.equal(result.code, 'METHOD_NOT_ALLOWED');
});

test('Validation: rejects missing required fields', () => {
  const result = validateGenerateAudioRequest({ method: 'POST', body: {} });
  assert.equal(result.status, 400);
  assert.match(result.message, /contentKind/);
});

test('Validation: rejects unsupported content kinds', () => {
  const result = validateGenerateAudioRequest({
    method: 'POST',
    body: {
      contentKind: 'quiz',
      contentId: 'quiz_1',
      languageCode: 'hi',
      trackType: 'explanation',
      text: 'नमस्ते',
    },
  });
  assert.equal(result.status, 400);
  assert.equal(result.code, 'UNSUPPORTED_CONTENT_KIND');
});

test('Validation: NEVER allows Santali (target) synthesis', () => {
  const result = validateGenerateAudioRequest({
    method: 'POST',
    body: {
      contentKind: 'word',
      contentId: 'word_1',
      languageCode: 'sat',
      trackType: 'explanation',
      text: 'ᱢᱟᱲᱟ',
    },
  });
  assert.equal(result.status, 400);
  assert.equal(result.code, 'TARGET_LANGUAGE_FORBIDDEN');
  assert.match(result.message, /human-recorded/);
});

test('Validation: rejects target track types (synthetic Santali forbidden)', () => {
  for (const trackType of ['targetNormal', 'targetSlow', 'targetSyllable', 'storyNarration']) {
    const result = validateGenerateAudioRequest({
      method: 'POST',
      body: {
        contentKind: 'word',
        contentId: 'word_1',
        languageCode: 'hi',
        trackType,
        text: 'नमस्ते',
      },
    });
    assert.equal(result.status, 400);
    assert.equal(result.code, 'TARGET_TRACK_FORBIDDEN');
  }
});

test('Validation: rejects unsupported teaching languages', () => {
  const result = validateGenerateAudioRequest({
    method: 'POST',
    body: {
      contentKind: 'word',
      contentId: 'word_1',
      languageCode: 'ta',
      trackType: 'translation',
      text: 'vanakkam',
    },
  });
  assert.equal(result.status, 400);
  assert.equal(result.code, 'UNSUPPORTED_LANGUAGE');
});

test('Validation: accepts a valid teaching-language generation request', () => {
  const result = validateGenerateAudioRequest({
    method: 'POST',
    body: {
      contentKind: 'word',
      contentId: 'word_1',
      languageCode: 'hi',
      trackType: 'explanation',
      text: 'यह एक शब्द है',
      speaker: 'aditi',
    },
  });
  assert.equal(result, null);
});

test('Validation: rejects unsupported speakers', () => {
  const result = validateGenerateAudioRequest({
    method: 'POST',
    body: {
      contentKind: 'word',
      contentId: 'word_1',
      languageCode: 'hi',
      trackType: 'explanation',
      text: 'नमस्ते',
      speaker: 'evil-clone',
    },
  });
  assert.equal(result.status, 400);
  assert.equal(result.code, 'UNSUPPORTED_SPEAKER');
  assert.ok(ALLOWED_SPEAKERS.has('shubh'));
  assert.ok(!ALLOWED_SPEAKERS.has('sat'));
});

test('Validation: rejects text that cleans to nothing', () => {
  const result = validateGenerateAudioRequest({
    method: 'POST',
    body: {
      contentKind: 'word',
      contentId: 'word_1',
      languageCode: 'hi',
      trackType: 'explanation',
      text: '   [ ]  ',
    },
  });
  assert.equal(result.status, 400);
  assert.equal(result.code, 'INVALID_INPUT');
});

test('Validation: rejects over-long text', () => {
  const result = validateGenerateAudioRequest({
    method: 'POST',
    body: {
      contentKind: 'word',
      contentId: 'word_1',
      languageCode: 'hi',
      trackType: 'explanation',
      text: 'a'.repeat(MAX_TEXT_CHARS + 10),
    },
  });
  assert.equal(result.status, 400);
  assert.equal(result.code, 'INPUT_TOO_LONG');
});

// ---- Prompt cleaning & hashing ----

test('Cleaning: strips bracket characters, quotes and dash suffixes', () => {
  // NOTE: matches the original script's behavior exactly — it removes
  // bracket/quote CHARACTERS, not their contents.
  assert.equal(extractCleanSpeechPrompt('नमस्ते (greeting)'), 'नमस्ते greeting');
  assert.equal(extractCleanSpeechPrompt('[intro] hello'), 'intro hello');
  assert.equal(extractCleanSpeechPrompt('part–suffix'), 'part');
  assert.equal(extractCleanSpeechPrompt('-leading dash'), 'leading dash');
  assert.equal(extractCleanSpeechPrompt('word - translation'), 'word');
  assert.equal(extractCleanSpeechPrompt(null), '');
});

test('Hashing: contentHash is stable and sensitive to voice params', () => {
  const base = {
    text: 'यह एक शब्द है',
    languageCode: 'hi',
    trackType: 'explanation',
    model: 'bulbul:v4',
    speaker: 'shubh',
    pace: 0.9,
  };
  const h1 = createContentHash(base);
  const h2 = createContentHash({ ...base, text: '  यह एक शब्द है  ' }); // trim-equivalent
  assert.equal(h1, h2);
  assert.match(h1, /^[a-f0-9]{64}$/);

  // Different voice params must produce a different hash
  const h3 = createContentHash({ ...base, speaker: 'aditi' });
  assert.notEqual(h1, h3);
});

test('Pace: clamped to the 0.5–2.0 Sarvam range', () => {
  assert.equal(clampPace(0.9), 0.9);
  assert.equal(clampPace(0.1), 0.5);
  assert.equal(clampPace(5), 2.0);
  assert.equal(clampPace('not-a-number'), 0.9);
});

// ---- Sarvam client ----

test('Sarvam client: returns audio buffer and used model', async () => {
  const fakeFetch = async () => ({
    ok: true,
    status: 200,
    json: async () => ({ audios: [Buffer.from('fake-wav-bytes').toString('base64')] }),
  });
  const result = await synthesizeSpeech({
    text: 'नमस्ते',
    languageTag: 'hi-IN',
    speaker: 'shubh',
    apiKey: 'test-key',
    fetchImpl: fakeFetch,
    retries: 0,
  });
  assert.ok(Buffer.isBuffer(result.audio));
  assert.equal(result.model, 'bulbul:v4');
});

test('Sarvam client: falls back from bulbul:v4 to bulbul:v3 on 400', async () => {
  const calls = [];
  const fakeFetch = async (url, opts) => {
    const body = JSON.parse(opts.body);
    calls.push(body.model);
    if (calls.length === 1) {
      return { ok: false, status: 400, text: async () => 'v4 not enabled' };
    }
    return {
      ok: true,
      status: 200,
      json: async () => ({ audios: [Buffer.from('v3-bytes').toString('base64')] }),
    };
  };
  const result = await synthesizeSpeech({
    text: 'नमस्ते',
    apiKey: 'test-key',
    fetchImpl: fakeFetch,
    retries: 0,
  });
  assert.equal(result.model, 'bulbul:v3');
  assert.deepEqual(calls, ['bulbul:v4', 'bulbul:v3']);
});

test('Sarvam client: throws on hard upstream failure', async () => {
  const fakeFetch = async () => ({ ok: false, status: 500, text: async () => 'boom' });
  await assert.rejects(
    synthesizeSpeech({ text: 'नमस्ते', apiKey: 'k', fetchImpl: fakeFetch, retries: 0 }),
    /500/
  );
});

test('Sarvam client: throws without an API key', async () => {
  await assert.rejects(
    synthesizeSpeech({ text: 'x', apiKey: null, fetchImpl: async () => ({ ok: true }), retries: 0 }),
    /SARVAM_API_KEY/
  );
});

// ---- Main handler helpers ----

test('Helpers: parseBody tolerates objects, JSON strings and garbage', () => {
  assert.deepEqual(parseBody({ a: 1 }), { a: 1 });
  assert.deepEqual(parseBody('{"a":1}'), { a: 1 });
  assert.equal(parseBody('not json'), null);
  assert.equal(parseBody(null), null);
});

test('Helpers: requireConfig reports every missing secret', () => {
  const config = requireConfig({});
  assert.ok(config.missing.includes('SARVAM_API_KEY'));
  assert.ok(config.missing.includes('APPWRITE_FUNCTION_API_KEY'));
  const full = requireConfig({
    APPWRITE_FUNCTION_API_ENDPOINT: 'https://sgp.cloud.appwrite.io/v1',
    APPWRITE_FUNCTION_PROJECT_ID: 'proj',
    APPWRITE_FUNCTION_API_KEY: 'key',
    SARVAM_API_KEY: 'sarvam',
  });
  assert.equal(full.sarvamApiKey, 'sarvam');
  assert.equal(full.missing, undefined);
});

test('Helpers: userIsAdmin checks team membership and fails closed', async () => {
  const users = {
    async listMemberships(userId) {
      if (userId === 'admin_user') {
        return { memberships: [{ teamId: 'admins' }] };
      }
      if (userId === 'other_user') {
        return { memberships: [{ teamId: 'editors' }] };
      }
      throw new Error('user not found');
    },
  };
  assert.equal(await userIsAdmin(users, 'admin_user'), true);
  assert.equal(await userIsAdmin(users, 'other_user'), false);
  assert.equal(await userIsAdmin(users, 'missing_user'), false); // fails closed
  assert.equal(await userIsAdmin(users, null), false);
});

// ---- Track store & generation pipeline ----

function makeFakeDatabases() {
  const store = new Map();
  return {
    store,
    async listDocuments(dbId, collectionId, queries) {
      // Very small query interpreter: node-appwrite Query methods return
      // JSON STRINGS (not objects), so parse each one and keep only
      // the `equal` filters.
      const docs = [...store.values()].filter((d) => d.__collection === collectionId);
      const wanted = {};
      for (const q of queries) {
        const parsed = JSON.parse(q);
        if (parsed.method === 'equal') {
          wanted[parsed.attribute] = parsed.values[0];
        }
      }
      const matched = docs.filter((d) =>
        Object.entries(wanted).every(([k, v]) => d[k] === v)
      );
      return { documents: matched.slice(0, 1) };
    },
    async createDocument(dbId, collectionId, id, data) {
      const doc = { $id: id, ...data, __collection: collectionId };
      store.set(id, doc);
      return doc;
    },
    async updateDocument(dbId, collectionId, id, data) {
      const existing = store.get(id);
      if (!existing) throw new Error('not found');
      Object.assign(existing, data);
      return existing;
    },
  };
}

function makeFakeStorage() {
  const files = [];
  return {
    files,
    async createFile(bucketId, fileId, file) {
      const record = { $id: fileId, bucketId };
      files.push(record);
      return record;
    },
  };
}

const OK_FETCH = async () => ({
  ok: true,
  status: 200,
  json: async () => ({ audios: [Buffer.from('wav-bytes').toString('base64')] }),
});

const BASE_REQUEST = {
  contentKind: 'word',
  contentId: 'word_42',
  languageCode: 'hi',
  trackType: 'explanation',
  text: 'यह एक शब्द है',
};

test('Pipeline: generates a track, uploads audio, never auto-approves', async () => {
  const databases = makeFakeDatabases();
  const storage = makeFakeStorage();
  const result = await generateTrack({
    databases,
    storage,
    sarvamApiKey: 'test',
    fetchImpl: OK_FETCH,
    ...BASE_REQUEST,
    audioUrlBuilder: (fileId) => `https://example.test/audio/${fileId}`,
  });

  assert.equal(result.status, 200);
  assert.equal(result.payload.success, true);
  assert.equal(result.payload.data.cached, false);
  assert.equal(result.payload.data.generationStatus, 'completed');
  assert.equal(result.payload.data.reviewStatus, 'needsReview'); // never auto-approved

  const doc = [...databases.store.values()][0];
  assert.equal(doc.provider, 'sarvam');
  assert.equal(doc.isHumanRecorded, false);
  assert.equal(doc.segmentId, '-');
  assert.equal(doc.generationStatus, 'completed');
  assert.equal(doc.reviewStatus, 'needsReview');
  assert.equal(doc.storageFileId, storage.files[0].$id);
  assert.match(doc.audioUrl, /example\.test\/audio\//);
});

test('Pipeline: is idempotent — replays return the existing row untouched', async () => {
  const databases = makeFakeDatabases();
  const storage = makeFakeStorage();

  const first = await generateTrack({
    databases,
    storage,
    sarvamApiKey: 'test',
    fetchImpl: OK_FETCH,
    ...BASE_REQUEST,
    audioUrlBuilder: (fileId) => `https://example.test/audio/${fileId}`,
  });
  const fetchCalls = [];
  const trackingFetch = async (...args) => {
    fetchCalls.push(1);
    return OK_FETCH(...args);
  };

  const second = await generateTrack({
    databases,
    storage,
    sarvamApiKey: 'test',
    fetchImpl: trackingFetch,
    ...BASE_REQUEST,
    audioUrlBuilder: (fileId) => `https://example.test/audio/${fileId}`,
  });

  assert.equal(second.payload.data.cached, true);
  assert.equal(second.payload.data.trackId, first.payload.data.trackId);
  assert.equal(fetchCalls.length, 0); // no second Sarvam call
  assert.equal(databases.store.size, 1); // no duplicate row
  assert.equal(storage.files.length, 1); // no duplicate file
});

test('Pipeline: different text creates a new row (hash differs)', async () => {
  const databases = makeFakeDatabases();
  const storage = makeFakeStorage();
  await generateTrack({
    databases,
    storage,
    sarvamApiKey: 'test',
    fetchImpl: OK_FETCH,
    ...BASE_REQUEST,
    audioUrlBuilder: (f) => `https://example.test/audio/${f}`,
  });
  const second = await generateTrack({
    databases,
    storage,
    sarvamApiKey: 'test',
    fetchImpl: OK_FETCH,
    ...BASE_REQUEST,
    text: 'यह एक वाक्य है',
    audioUrlBuilder: (f) => `https://example.test/audio/${f}`,
  });
  assert.equal(second.payload.data.cached, false);
  assert.equal(databases.store.size, 2);
});

test('Pipeline: upstream failure marks the row failed with redacted message', async () => {
  const databases = makeFakeDatabases();
  const storage = makeFakeStorage();
  const failingFetch = async () => ({
    ok: false,
    status: 500,
    text: async () => 'secret api-subscription-key=ABC123 boom',
  });

  const result = await generateTrack({
    databases,
    storage,
    sarvamApiKey: 'test',
    fetchImpl: failingFetch,
    ...BASE_REQUEST,
  });

  assert.equal(result.status, 502);
  assert.equal(result.payload.success, false);
  assert.equal(result.payload.error, 'GENERATION_FAILED');

  const doc = [...databases.store.values()][0];
  assert.equal(doc.generationStatus, 'failed');
  assert.ok(doc.errorMessage.includes('[redacted]'));
  assert.ok(!doc.errorMessage.includes('ABC123')); // secret redacted
});

test('findExistingTrack: matches on the full composite key', async () => {
  const databases = makeFakeDatabases();
  databases.store.set('t1', {
    $id: 't1',
    __collection: 'audio_tracks',
    contentKind: 'word',
    contentId: 'word_42',
    segmentId: '-',
    languageCode: 'hi',
    trackType: 'explanation',
    contentHash: 'hash_a',
    generationStatus: 'completed',
    reviewStatus: 'needsReview',
  });

  const found = await findExistingTrack(databases, {
    contentKind: 'word',
    contentId: 'word_42',
    segmentId: '-',
    languageCode: 'hi',
    trackType: 'explanation',
    contentHash: 'hash_a',
  });
  assert.equal(found.$id, 't1');

  const notFound = await findExistingTrack(databases, {
    contentKind: 'word',
    contentId: 'word_42',
    segmentId: '-',
    languageCode: 'hi',
    trackType: 'explanation',
    contentHash: 'hash_b',
  });
  assert.equal(notFound, null);
});
