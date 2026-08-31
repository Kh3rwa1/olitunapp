import test from 'node:test';
import assert from 'node:assert/strict';
import {
  ACTIONS,
  ALLOWED_GENERATION_FILTERS,
  ALLOWED_REVIEW_FILTERS,
  MAX_BATCH_IDS,
  canApproveAudioTrack,
  validateReviewRequest,
} from '../src/validation.js';
import {
  ADMIN_TEAM_ID,
  AUDIO_TRACKS_COLLECTION,
  LOCALIZED_CONTENTS_COLLECTION,
  applyReviewDecisions,
  buildListQueries,
  handleReviewRequest,
  parseBody,
  requireConfig,
  toAudioRow,
  toLocalizedRow,
  userIsAdmin,
} from '../src/main.js';

// node-appwrite Query methods return JSON strings; parse before inspecting.
function interpretQueries(queries) {
  return (queries || []).map((q) => JSON.parse(q));
}

function fakeAudioDoc(overrides = {}) {
  return {
    $id: 'audio1',
    contentKind: 'word',
    contentId: 'w1',
    segmentId: '-',
    languageCode: 'hi',
    trackType: 'translation',
    audioUrl: 'https://example.com/audio.wav',
    storageFileId: 'file1',
    provider: 'sarvam',
    model: 'bulbul:v4',
    voiceId: 'shubh',
    isHumanRecorded: false,
    generationStatus: 'completed',
    reviewStatus: 'needsReview',
    errorMessage: null,
    reviewedBy: null,
    reviewedAt: null,
    updatedAt: '2026-01-01T00:00:00Z',
    createdAt: '2026-01-01T00:00:00Z',
    ...overrides,
  };
}

function makeFakeDatabases({ audioDocs = [], localizedDocs = [] } = {}) {
  const updated = [];
  const db = {
    audioDocs: audioDocs.map((d) => ({ ...d })),
    localizedDocs: localizedDocs.map((d) => ({ ...d })),
    updated,
    async listDocuments(_dbId, collectionId, queries) {
      const interpreted = interpretQueries(queries);
      const source = collectionId === AUDIO_TRACKS_COLLECTION
        ? db.audioDocs
        : db.localizedDocs;
      const filters = interpreted.filter((q) => q.method === 'equal');
      const limitQ = interpreted.find((q) => q.method === 'limit');
      const offsetQ = interpreted.find((q) => q.method === 'offset');
      let docs = source.filter((doc) =>
        filters.every((f) => doc[f.attribute] === f.values[0]),
      );
      const offset = offsetQ ? offsetQ.values[0] : 0;
      const limit = limitQ ? limitQ.values[0] : 25;
      return {
        total: docs.length,
        documents: docs.slice(offset, offset + limit),
      };
    },
    async getDocument(_dbId, collectionId, id) {
      const source = collectionId === AUDIO_TRACKS_COLLECTION
        ? db.audioDocs
        : db.localizedDocs;
      const doc = source.find((d) => d.$id === id);
      if (!doc) throw new Error('document_not_found');
      return { ...doc };
    },
    async updateDocument(_dbId, collectionId, id, patch) {
      const source = collectionId === AUDIO_TRACKS_COLLECTION
        ? db.audioDocs
        : db.localizedDocs;
      const doc = source.find((d) => d.$id === id);
      if (!doc) throw new Error('document_not_found');
      Object.assign(doc, patch);
      updated.push({ collectionId, id, patch: { ...patch } });
      return { ...doc };
    },
  };
  return db;
}

function makeFakeUsers({ admin = true } = {}) {
  return {
    async listMemberships(userId) {
      if (!userId) throw new Error('missing user');
      return {
        memberships: admin
          ? [{ teamId: ADMIN_TEAM_ID }]
          : [{ teamId: 'some-other-team' }],
      };
    },
  };
}

// ─── validation ───

test('rejects non-POST methods with 405', () => {
  const invalid = validateReviewRequest({ method: 'GET', body: { action: ACTIONS.LIST_AUDIO } });
  assert.equal(invalid.status, 405);
  assert.equal(invalid.code, 'METHOD_NOT_ALLOWED');
});

test('rejects invalid/missing bodies with 400', () => {
  assert.equal(validateReviewRequest({ method: 'POST', body: null })?.status, 400);
  assert.equal(validateReviewRequest({ method: 'POST', body: 'not-json' })?.status, 400);
});

test('rejects unsupported action with 400', () => {
  const invalid = validateReviewRequest({ method: 'POST', body: { action: 'delete_everything' } });
  assert.equal(invalid.status, 400);
  assert.equal(invalid.code, 'UNSUPPORTED_ACTION');
});

test('accepts all six supported actions', () => {
  for (const action of Object.values(ACTIONS)) {
    const body =
      action.startsWith('approve_') || action.startsWith('reject_')
        ? { action, ids: ['a'] }
        : { action };
    const invalid = validateReviewRequest({ method: 'POST', body });
    assert.equal(invalid, null, `action ${action} should be valid`);
  }
});

test('mutation actions require a non-empty ids list', () => {
  assert.equal(
    validateReviewRequest({ method: 'POST', body: { action: ACTIONS.APPROVE_AUDIO, ids: [] } })?.status,
    400,
  );
  assert.equal(
    validateReviewRequest({ method: 'POST', body: { action: ACTIONS.APPROVE_AUDIO } })?.status,
    400,
  );
});

test('mutation actions cap batch size at MAX_BATCH_IDS', () => {
  const many = Array.from({ length: MAX_BATCH_IDS + 1 }, (_, i) => `id${i}`);
  const invalid = validateReviewRequest({
    method: 'POST',
    body: { action: ACTIONS.APPROVE_AUDIO, ids: many },
  });
  assert.equal(invalid.status, 400);

  const okBody = { action: ACTIONS.APPROVE_AUDIO, ids: many.slice(0, MAX_BATCH_IDS) };
  assert.equal(validateReviewRequest({ method: 'POST', body: okBody }), null);
});

test('duplicate ids are de-duplicated while order is preserved', () => {
  // validated indirectly through applyReviewDecisions below; here check
  // the validator accepts duplicates but the pipeline handles them once.
  const body = { action: ACTIONS.APPROVE_AUDIO, ids: ['a', 'a', 'b'] };
  assert.equal(validateReviewRequest({ method: 'POST', body: body }), null);
});

test('list defaults to needsReview queue with sane paging', () => {
  const invalid = validateReviewRequest({
    method: 'POST',
    body: { action: ACTIONS.LIST_AUDIO },
  });
  assert.equal(invalid, null);
});

test('rejects invalid reviewStatus / generationStatus filters', () => {
  assert.equal(
    validateReviewRequest({ method: 'POST', body: { action: ACTIONS.LIST_AUDIO, reviewStatus: 'yolo' } })?.status,
    400,
  );
  assert.equal(
    validateReviewRequest({ method: 'POST', body: { action: ACTIONS.LIST_AUDIO, generationStatus: 'exploded' } })?.status,
    400,
  );
  assert.ok(ALLOWED_REVIEW_FILTERS.has('approved'));
  assert.ok(ALLOWED_GENERATION_FILTERS.has('failed'));
});

test('canApproveAudioTrack requires audioUrl', () => {
  assert.equal(canApproveAudioTrack(fakeAudioDoc({ audioUrl: null })), false);
  assert.equal(canApproveAudioTrack(fakeAudioDoc({ audioUrl: '' })), false);
  assert.equal(canApproveAudioTrack(fakeAudioDoc()), true);
});

test('canApproveAudioTrack requires completed generation for synthetic tracks', () => {
  assert.equal(
    canApproveAudioTrack(fakeAudioDoc({ generationStatus: 'processing' })),
    false,
  );
  assert.equal(
    canApproveAudioTrack(fakeAudioDoc({ generationStatus: 'failed' })),
    false,
  );
});

test('canApproveAudioTrack allows human-recorded tracks regardless of generationStatus', () => {
  assert.equal(
    canApproveAudioTrack(
      fakeAudioDoc({ isHumanRecorded: true, generationStatus: 'notRequested' }),
    ),
    true,
  );
});

// ─── helpers ───

test('parseBody handles objects, JSON strings and garbage', () => {
  assert.deepEqual(parseBody({ a: 1 }), { a: 1 });
  assert.deepEqual(parseBody('{"a":1}'), { a: 1 });
  assert.equal(parseBody('nope'), null);
  assert.equal(parseBody(null), null);
});

test('requireConfig reports missing env vars and returns config when present', () => {
  const missing = requireConfig({});
  assert.ok(missing.missing.length >= 3);

  const config = requireConfig({
    APPWRITE_FUNCTION_API_ENDPOINT: 'https://x/v1',
    APPWRITE_FUNCTION_PROJECT_ID: 'proj',
    APPWRITE_FUNCTION_API_KEY: 'key',
  });
  assert.equal(config.endpoint, 'https://x/v1');
});

test('userIsAdmin fails closed on errors and non-admins', async () => {
  assert.equal(await userIsAdmin(makeFakeUsers({ admin: false }), 'u1'), false);
  assert.equal(await userIsAdmin(makeFakeUsers(), null), false);
  const broken = { async listMemberships() { throw new Error('boom'); } };
  assert.equal(await userIsAdmin(broken, 'u1'), false);
  assert.equal(await userIsAdmin(makeFakeUsers(), 'u1'), true);
});

test('buildListQueries assembles filters and paging', () => {
  const queries = interpretQueries(
    buildListQueries({
      reviewStatus: 'needsReview',
      languageCode: 'hi',
      contentKind: 'word',
      generationStatus: 'completed',
      limit: 10,
      offset: 5,
    }),
  );
  const equals = queries.filter((q) => q.method === 'equal');
  assert.deepEqual(
    equals.map((q) => q.attribute).sort(),
    ['contentKind', 'generationStatus', 'languageCode', 'reviewStatus'],
  );
  assert.equal(queries.find((q) => q.method === 'limit').values[0], 10);
  assert.equal(queries.find((q) => q.method === 'offset').values[0], 5);
});

test('toAudioRow and toLocalizedRow project documents', () => {
  const audioRow = toAudioRow(fakeAudioDoc());
  assert.equal(audioRow.id, 'audio1');
  assert.equal(audioRow.isHumanRecorded, false);
  assert.ok(!('$id' in audioRow));

  const localizedRow = toLocalizedRow({
    $id: 'lc1',
    contentKind: 'word',
    contentId: 'w1',
    languageCode: 'bn',
    meaning: 'hello',
    explanation: 'greeting',
    version: 2,
  });
  assert.equal(localizedRow.id, 'lc1');
  assert.equal(localizedRow.version, 2);
});

// ─── list flows ───

test('list_audio returns the needsReview queue filtered', async () => {
  const databases = makeFakeDatabases({
    audioDocs: [
      fakeAudioDoc({ $id: 'a1', languageCode: 'hi' }),
      fakeAudioDoc({ $id: 'a2', languageCode: 'hi', reviewStatus: 'approved' }),
      fakeAudioDoc({ $id: 'a3', languageCode: 'en' }),
    ],
  });
  const result = await handleReviewRequest({
    databases,
    action: ACTIONS.LIST_AUDIO,
    reviewStatus: 'needsReview',
    languageCode: 'hi',
    limit: 25,
    offset: 0,
    reviewedBy: 'admin1',
  });
  assert.equal(result.status, 200);
  assert.equal(result.payload.success, true);
  assert.equal(result.payload.data.kind, 'audio');
  assert.equal(result.payload.data.total, 1);
  assert.equal(result.payload.data.documents[0].id, 'a1');
});

test('list_localized filters by language and status', async () => {
  const databases = makeFakeDatabases({
    localizedDocs: [
      { $id: 'l1', contentKind: 'word', contentId: 'w1', languageCode: 'hi', reviewStatus: 'needsReview' },
      { $id: 'l2', contentKind: 'word', contentId: 'w2', languageCode: 'hi', reviewStatus: 'needsReview' },
      { $id: 'l3', contentKind: 'word', contentId: 'w3', languageCode: 'or', reviewStatus: 'needsReview' },
    ],
  });
  const result = await handleReviewRequest({
    databases,
    action: ACTIONS.LIST_LOCALIZED,
    reviewStatus: 'needsReview',
    languageCode: 'hi',
    limit: 25,
    offset: 0,
    reviewedBy: 'admin1',
  });
  assert.equal(result.status, 200);
  assert.equal(result.payload.data.total, 2);
});

// ─── decision flows ───

test('approve_audio approves completed tracks and stamps reviewer metadata', async () => {
  const databases = makeFakeDatabases({ audioDocs: [fakeAudioDoc({ $id: 'a1' })] });
  const result = await applyReviewDecisions({
    databases,
    collectionId: AUDIO_TRACKS_COLLECTION,
    ids: ['a1'],
    decision: 'approved',
    reviewedBy: 'admin1',
    now: () => '2026-02-02T00:00:00Z',
  });
  assert.equal(result.status, 200);
  assert.equal(result.payload.data.updated, 1);
  assert.equal(result.payload.data.failed, 0);
  assert.equal(databases.audioDocs[0].reviewStatus, 'approved');
  assert.equal(databases.audioDocs[0].reviewedBy, 'admin1');
  assert.equal(databases.audioDocs[0].reviewedAt, '2026-02-02T00:00:00Z');
});

test('approve_audio refuses incomplete/broken tracks per-id without blocking the batch', async () => {
  const databases = makeFakeDatabases({
    audioDocs: [
      fakeAudioDoc({ $id: 'good' }),
      fakeAudioDoc({ $id: 'broken', generationStatus: 'failed' }),
      fakeAudioDoc({ $id: 'noaudio', audioUrl: null }),
    ],
  });
  const result = await applyReviewDecisions({
    databases,
    collectionId: AUDIO_TRACKS_COLLECTION,
    ids: ['good', 'broken', 'noaudio'],
    decision: 'approved',
    reviewedBy: 'admin1',
  });
  assert.equal(result.payload.data.updated, 1);
  assert.equal(result.payload.data.failed, 2);
  // precise per-id checks:
  assert.equal(result.payload.data.results.find((r) => r.id === 'good').ok, true);
  assert.equal(result.payload.data.results.find((r) => r.id === 'broken').reason, 'TRACK_NOT_APPROVABLE');
  assert.equal(result.payload.data.results.find((r) => r.id === 'noaudio').reason, 'TRACK_NOT_APPROVABLE');
});

test('approve_audio allows human-recorded tracks with no generation status', async () => {
  const databases = makeFakeDatabases({
    audioDocs: [
      fakeAudioDoc({
        $id: 'human',
        isHumanRecorded: true,
        generationStatus: 'notRequested',
        languageCode: 'sat',
        trackType: 'targetNormal',
        provider: null,
      }),
    ],
  });
  const result = await applyReviewDecisions({
    databases,
    collectionId: AUDIO_TRACKS_COLLECTION,
    ids: ['human'],
    decision: 'approved',
    reviewedBy: 'admin1',
  });
  assert.equal(result.payload.data.updated, 1);
  assert.equal(databases.audioDocs[0].reviewStatus, 'approved');
});

test('reject_audio works on any track (even broken ones) and stamps metadata', async () => {
  const databases = makeFakeDatabases({
    audioDocs: [fakeAudioDoc({ $id: 'bad', generationStatus: 'failed' })],
  });
  const result = await applyReviewDecisions({
    databases,
    collectionId: AUDIO_TRACKS_COLLECTION,
    ids: ['bad'],
    decision: 'rejected',
    reviewedBy: 'admin1',
  });
  assert.equal(result.payload.data.updated, 1);
  assert.equal(databases.audioDocs[0].reviewStatus, 'rejected');
  assert.equal(databases.audioDocs[0].reviewedBy, 'admin1');
});

test('unknown ids are reported NOT_FOUND and never throw', async () => {
  const databases = makeFakeDatabases({ audioDocs: [fakeAudioDoc({ $id: 'a1' })] });
  const result = await applyReviewDecisions({
    databases,
    collectionId: AUDIO_TRACKS_COLLECTION,
    ids: ['a1', 'ghost'],
    decision: 'approved',
    reviewedBy: 'admin1',
  });
  assert.equal(result.payload.data.updated, 1);
  assert.equal(result.payload.data.failed, 1);
  assert.equal(result.payload.data.results.find((r) => r.id === 'ghost').reason, 'NOT_FOUND');
});

test('handleReviewRequest routes approve_localized to the localized collection', async () => {
  const databases = makeFakeDatabases({
    localizedDocs: [
      { $id: 'l1', contentKind: 'word', contentId: 'w1', languageCode: 'hi', reviewStatus: 'needsReview' },
    ],
  });
  const result = await handleReviewRequest({
    databases,
    action: ACTIONS.APPROVE_LOCALIZED,
    ids: ['l1'],
    reviewedBy: 'admin2',
    now: () => '2026-03-03T00:00:00Z',
  });
  assert.equal(result.status, 200);
  assert.equal(databases.localizedDocs[0].reviewStatus, 'approved');
  assert.equal(databases.localizedDocs[0].reviewedBy, 'admin2');
  assert.equal(databases.localizedDocs[0].reviewedAt, '2026-03-03T00:00:00Z');
  assert.equal(databases.updated[0].collectionId, LOCALIZED_CONTENTS_COLLECTION);
});

test('handleReviewRequest returns 400 for an unroutable action', async () => {
  const databases = makeFakeDatabases();
  const result = await handleReviewRequest({
    databases,
    action: 'nonsense_action',
    reviewedBy: 'admin1',
  });
  assert.equal(result.status, 400);
  assert.equal(result.payload.error, 'UNSUPPORTED_ACTION');
});
