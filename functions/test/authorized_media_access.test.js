import test from 'node:test';
import assert from 'node:assert/strict';
import { createGetAuthorizedLessonHandler, createSlidingWindowRateLimiter } from '../getAuthorizedLesson/src/main.js';
import { MEDIA_TTL_MS, createMediaAccess } from '../getAuthorizedLesson/src/media-access.js';

process.env.MEDIA_PUBLIC_ENDPOINT = 'https://media.example.test/v1';
process.env.APPWRITE_PROJECT_ID = 'test_project';
const NOW = Date.parse('2026-09-06T00:00:00Z');
const buyer = { userId: 'buyer', categoryId: 'cat', status: 'verified', expectedAmount: 499 };

function harness({ lesson = {}, category = {}, purchases = [buyer], ledgerError = false, tokenError = null } = {}) {
  const calls = [];
  const databases = {
    async getDocument(db, collection, id) {
      if (id === 'missing') throw Object.assign(new Error('missing'), { code: 404 });
      return collection === 'lessons' ? {
        $id: 'lesson', categoryId: 'cat', order: 5,
        blocks: JSON.stringify([{ type: 'audio', audioUrl: 'appwrite-storage://paid_media/file' }]),
        ...lesson,
      } : { $id: 'cat', unlockMode: 'paid_only', ...category };
    },
    async listDocuments(db, collection, queries) {
      if (ledgerError) throw new Error('ledger unavailable');
      const equals = queries.map(JSON.parse).filter(q => q.method === 'equal');
      return { documents: purchases.filter(p => equals.every(q => q.values.includes(p[q.attribute]))) };
    },
  };
  const storage = {
    async getFile(args) { calls.push(['metadata', args]); return { mimeType: 'audio/mpeg', sizeOriginal: 100 * 1024 * 1024 }; },
    async getFileDownload() { assert.fail('Never download or buffer the media in the function'); },
  };
  const tokens = { async createFileToken(args) {
    calls.push(['token', args]);
    if (tokenError) throw tokenError;
    return { secret: 'test-only-token', expire: args.expire };
  } };
  const rateLimiter = createSlidingWindowRateLimiter({ windowMs: 60000, maxPerWindow: 60, clock: () => NOW });
  const handler = createGetAuthorizedLessonHandler({ databases, storage, tokens, rateLimiter, clock: () => NOW });
  async function request({ user = 'buyer', action = 'get_media', ...body } = {}) {
    const res = { status: 0, body: null, headers: {}, json(data, status = 200, headers = {}) { Object.assign(this, { body: data, status, headers }); return this; } };
    await handler({ req: { method: 'POST', headers: user ? { 'x-appwrite-user-id': user } : {}, body: { lessonId: 'lesson', action, fileId: 'file', protocolVersion: 2, ...body } }, res, error() {}, log() {} });
    return res;
  }
  return { request, calls };
}

for (const user of [null, 'nonbuyer']) {
  test(`protected body stripped and media denied: ${user}`, async () => {
    const h = harness();
    const body = await h.request({ user, action: 'get_lesson', userId: 'buyer', isPremiumUnlocked: true });
    assert.equal(body.body.locked, true);
    assert.deepEqual(body.body.lesson.blocks, []);
    assert.equal((await h.request({ user, userId: 'buyer' })).status, 403);
    assert.deepEqual(h.calls, []);
  });
}

for (const purchase of [
  { ...buyer, status: 'refunded' }, { ...buyer, status: 'disputed' },
  { ...buyer, status: 'revoked' }, { ...buyer, refundStatus: 'fully_refunded' },
  { ...buyer, refundedAmountPaise: 49900 }, { ...buyer, categoryId: 'other' },
  { ...buyer, userId: 'other' },
]) {
  test(`denied entitlement ${JSON.stringify(purchase)}`, async () => {
    const h = harness({ purchases: [purchase] });
    assert.equal((await h.request()).status, 403);
    assert.deepEqual(h.calls, []);
  });
}

for (const options of [
  { category: { unlockMode: 'unknown' } }, { category: { unlockMode: '' } },
  { lesson: { categoryId: '' } }, { lesson: { categoryId: 'missing' } },
  { ledgerError: true },
  { lesson: { isPremium: true, isPreview: true }, purchases: [] },
  { lesson: { isPremium: true }, category: { unlockMode: 'free' }, purchases: [] },
]) {
  test(`fail closed ${JSON.stringify(options)}`, async () => {
    const h = harness(options);
    assert.equal((await h.request()).status, 403);
    assert.deepEqual(h.calls, []);
  });
}

for (const options of [
  {}, { category: { unlockMode: 'free' }, purchases: [] },
  { lesson: { isPreview: true }, purchases: [] },
  { lesson: { order: 1 }, category: { previewLessonCount: 1 }, purchases: [] },
  { purchases: [{ ...buyer, refundedAmountPaise: 100 }] },
  { lesson: { blocks: JSON.stringify([{ data: JSON.stringify({ imageUrl: 'https://example.test/v1/storage/buckets/paid_media/files/file/view' }) }]) } },
]) {
  test(`authorized bounded lease ${JSON.stringify(options)}`, async () => {
    const h = harness(options);
    const res = await h.request();
    assert.equal(res.status, 200);
    assert.equal(res.body.transport, 'appwrite-file-token');
    assert.equal(res.body.protocolVersion, 2);
    assert.equal(res.body.base64, undefined);
    assert.match(res.headers['cache-control'], /no-store/);
    assert.equal(Date.parse(res.body.expiresAt) - NOW, MEDIA_TTL_MS);
    const url = new URL(res.body.url);
    assert.equal(url.pathname, '/v1/storage/buckets/paid_media/files/file/view');
    assert.equal(url.searchParams.get('project'), 'test_project');
    assert.equal(url.searchParams.get('token'), 'test-only-token');
    assert.deepEqual(h.calls.map(c => c[0]), ['metadata', 'token']);
    assert.deepEqual(h.calls[1][1], { bucketId: 'paid_media', fileId: 'file', expire: new Date(NOW + MEDIA_TTL_MS).toISOString() });
    assert.ok(JSON.stringify(res.body).length < 1000, '100MB files still produce only a small lease');
    const lesson = await h.request({ action: 'get_lesson' });
    assert.equal(lesson.body.locked, false);
    assert.ok(lesson.body.lesson.blocks.length > 0);
    assert.ok(!JSON.stringify(lesson.body).includes('test-only-token'));
  });
}

for (const [body, error] of [
  [{ fileId: 'course_b_file' }, 'media_not_associated'],
  [{ bucketId: 'other' }, 'bucket_mismatch'],
  [{ fileId: '' }, undefined],
  [{ protocolVersion: 1 }, 'media_client_upgrade_required'],
]) {
  test(`invalid media request ${JSON.stringify(body)}`, async () => {
    const h = harness();
    const res = await h.request(body);
    assert.ok(res.status >= 400);
    if (error) assert.equal(res.body.error, error);
    assert.deepEqual(h.calls, []);
  });
}

test('accessible lesson cannot authorize an unrelated file or public bucket token', async () => {
  const h = harness({ category: { unlockMode: 'free' }, lesson: { blocks: [{ audioUrl: 'appwrite-file:other:file' }] } });
  assert.equal((await h.request({ bucketId: 'other' })).body.error, 'bucket_not_permitted');
  assert.equal((await h.request({ fileId: 'unrelated' })).body.error, 'media_not_associated');
  assert.deepEqual(h.calls, []);
});

test('missing lesson and token service failures are distinct; no fallback to base64', async () => {
  assert.equal((await harness().request({ lessonId: 'missing' })).status, 404);
  assert.equal((await harness({ tokenError: { code: 500 } }).request()).status, 503);
  assert.equal((await harness({ tokenError: { code: 404 } }).request()).status, 404);
});

test('TTL cannot be controlled by client; reauthorization reads changed ledger', async () => {
  const purchases = [{ ...buyer }];
  const h = harness({ purchases });
  const result = await h.request({ expire: '2099-01-01', url: 'https://evil.test', bucketId: 'paid_media' });
  assert.equal(Date.parse(result.body.expiresAt), NOW + MEDIA_TTL_MS);
  purchases[0].status = 'refunded';
  assert.equal((await h.request()).status, 403);
  assert.equal(h.calls.filter(c => c[0] === 'token').length, 1);
});

test('invalid/unbounded token or insecure public endpoint fails closed', async () => {
  for (const token of [{ secret: '', expire: new Date(NOW + 1000).toISOString() }, { secret: 'x', expire: '' }, { secret: 'x', expire: new Date(NOW + MEDIA_TTL_MS + 1).toISOString() }]) {
    await assert.rejects(createMediaAccess({ storage: { getFile: async () => ({}) }, tokens: { createFileToken: async () => token }, bucketId: 'paid_media', fileId: 'file', publicEndpoint: process.env.MEDIA_PUBLIC_ENDPOINT, projectId: 'test_project', now: NOW }));
  }
  await assert.rejects(createMediaAccess({ publicEndpoint: 'http://internal/v1', projectId: 'test_project', now: NOW }));
});

test('rate limiting returns 429 when max requests per window is reached', async () => {
  const h = harness();
  let lastRes;
  // Send 60 requests (default window max)
  for (let i = 0; i < 60; i++) {
    lastRes = await h.request();
    assert.equal(lastRes.status, 200);
  }
  // 61st request should be throttled with HTTP 429
  const throttled = await h.request();
  assert.equal(throttled.status, 429);
  assert.equal(throttled.body.error, 'rate_limit_exceeded');
  assert.ok(throttled.headers['retry-after']);
});

