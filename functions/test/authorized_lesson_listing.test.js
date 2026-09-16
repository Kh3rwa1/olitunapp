import test from 'node:test';
import assert from 'node:assert/strict';
import {
  createGetAuthorizedLessonHandler,
  createSlidingWindowRateLimiter,
} from '../getAuthorizedLesson/src/main.js';

function mockRes() {
  const res = {
    statusCode: 200,
    headers: {},
    body: null,
    json(data, code = 200, headers = {}) {
      res.statusCode = code;
      res.headers = headers;
      res.body = data;
      return res;
    },
  };
  return res;
}

function parseQueries(queries = []) {
  return queries.map((query) => {
    if (typeof query !== 'string') return query;
    try {
      return JSON.parse(query);
    } catch (_) {
      return null;
    }
  }).filter(Boolean);
}

function makeFakeDatabases({ lessons = [], categories = [], purchases = [] } = {}) {
  const calls = [];
  return {
    calls,
    async getDocument(databaseId, collectionId, documentId) {
      calls.push({ operation: 'getDocument', collectionId, documentId });
      const source = collectionId === 'categories' ? categories : lessons;
      const document = source.find((item) => item.$id === documentId);
      if (!document) {
        const error = new Error('Not found');
        error.code = 404;
        throw error;
      }
      return document;
    },
    async listDocuments(databaseId, collectionId, queries) {
      calls.push({ operation: 'listDocuments', collectionId, queries });
      const parsed = parseQueries(queries);
      let documents = collectionId === 'lessons'
        ? [...lessons]
        : collectionId === 'categories'
          ? [...categories]
          : [...purchases];

      for (const query of parsed) {
        if (query.method === 'equal') {
          const values = query.values || [];
          documents = documents.filter((document) => values.includes(document[query.attribute]));
        }
      }
      if (collectionId === 'lessons') {
        documents.sort((left, right) => Number(left.order || 0) - Number(right.order || 0));
      }
      const cursorQuery = parsed.find((query) => query.method === 'cursorAfter');
      if (cursorQuery) {
        const cursor = cursorQuery.values?.[0];
        const index = documents.findIndex((document) => document.$id === cursor);
        documents = index >= 0 ? documents.slice(index + 1) : [];
      }
      const limitQuery = parsed.find((query) => query.method === 'limit');
      const limit = Number(limitQuery?.values?.[0] || 25);
      return { total: documents.length, documents: documents.slice(0, limit) };
    },
  };
}

function paidCategory(id = 'cat_paid') {
  return { $id: id, unlockMode: 'paid_only', previewLessonCount: 0 };
}

function freeCategory(id = 'cat_free') {
  return { $id: id, unlockMode: 'free', previewLessonCount: 0 };
}

function lesson(id, categoryId, order, extra = {}) {
  return {
    $id: id,
    categoryId,
    order,
    titleLatin: `Lesson ${order}`,
    titleOlChiki: `ᱯᱟᱹᱴ ${order}`,
    blocks: JSON.stringify([{ type: 'text', textLatin: 'SECRET BODY' }]),
    data: JSON.stringify({ answer: 'SECRET DATA' }),
    thumbnailUrl: 'https://example.test/private-thumbnail',
    heroMediaUrl: 'https://example.test/private-hero',
    ...extra,
  };
}

function request(body, headers = {}) {
  return { method: 'POST', headers, body: JSON.stringify(body) };
}

test('Authorized Lesson List: returns server-authoritative metadata without lesson bodies', async () => {
  const databases = makeFakeDatabases({
    lessons: [lesson('free_1', 'cat_free', 1), lesson('paid_1', 'cat_paid', 2)],
    categories: [freeCategory(), paidCategory()],
  });
  const handler = createGetAuthorizedLessonHandler({ databases });
  const res = mockRes();

  await handler({ req: request({ action: 'list_lessons', limit: 100 }), res });

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.ok, true);
  assert.equal(res.body.lessons.length, 2);
  assert.equal(res.body.lessons[0].isLocked, false);
  assert.equal(res.body.lessons[0].accessReason, 'free_category');
  assert.equal(res.body.lessons[1].isLocked, true);
  assert.equal(res.body.lessons[1].accessReason, 'unauthenticated');
  for (const metadata of res.body.lessons) {
    for (const forbidden of ['blocks', 'data', 'thumbnailUrl', 'heroMediaUrl', 'heroPosterUrl']) {
      assert.equal(Object.hasOwn(metadata, forbidden), false, `${forbidden} must never be listed`);
    }
  }
});

test('Authorized Lesson List: batches buyer entitlements instead of querying per lesson', async () => {
  const databases = makeFakeDatabases({
    lessons: [
      lesson('paid_a_1', 'cat_a', 1),
      lesson('paid_a_2', 'cat_a', 2),
      lesson('paid_b_1', 'cat_b', 3),
    ],
    categories: [paidCategory('cat_a'), paidCategory('cat_b')],
    purchases: [{
      $id: 'purchase_a',
      userId: 'buyer',
      categoryId: 'cat_a',
      status: 'verified',
      expectedAmount: '499',
      refundedAmountPaise: 0,
    }],
  });
  const handler = createGetAuthorizedLessonHandler({ databases });
  const res = mockRes();

  await handler({
    req: request({ action: 'list_lessons' }, { 'x-appwrite-user-id': 'buyer' }),
    res,
  });

  assert.deepEqual(res.body.lessons.map((item) => item.isLocked), [false, false, true]);
  assert.equal(
    databases.calls.filter((call) =>
      call.operation === 'listDocuments' && call.collectionId === 'course_purchases').length,
    1,
  );
});

test('Authorized Lesson List: supports bounded cursor pagination', async () => {
  const databases = makeFakeDatabases({
    lessons: [
      lesson('lesson_1', 'cat_free', 1),
      lesson('lesson_2', 'cat_free', 2),
      lesson('lesson_3', 'cat_free', 3),
    ],
    categories: [freeCategory()],
  });
  const handler = createGetAuthorizedLessonHandler({ databases });

  const first = mockRes();
  await handler({ req: request({ action: 'list_lessons', limit: 2 }), res: first });
  assert.equal(first.body.hasMore, true);
  assert.equal(first.body.nextCursor, 'lesson_2');
  assert.deepEqual(first.body.lessons.map((item) => item.id), ['lesson_1', 'lesson_2']);

  const second = mockRes();
  await handler({
    req: request({ action: 'list_lessons', limit: 2, cursor: first.body.nextCursor }),
    res: second,
  });
  assert.equal(second.body.hasMore, false);
  assert.equal(second.body.nextCursor, null);
  assert.deepEqual(second.body.lessons.map((item) => item.id), ['lesson_3']);
});

test('Authorized Lesson List: filters by category and rejects unsafe pagination input', async () => {
  const databases = makeFakeDatabases({
    lessons: [lesson('free_1', 'cat_free', 1), lesson('paid_1', 'cat_paid', 2)],
    categories: [freeCategory(), paidCategory()],
  });
  const handler = createGetAuthorizedLessonHandler({ databases });

  const filtered = mockRes();
  await handler({
    req: request({ action: 'list_lessons', categoryId: 'cat_free' }),
    res: filtered,
  });
  assert.deepEqual(filtered.body.lessons.map((item) => item.id), ['free_1']);

  for (const badBody of [
    { action: 'list_lessons', limit: 0 },
    { action: 'list_lessons', limit: 101 },
    { action: 'list_lessons', cursor: '../escape' },
    { action: 'list_lessons', categoryId: '_invalid' },
  ]) {
    const res = mockRes();
    await handler({ req: request(badBody), res });
    assert.equal(res.statusCode, 400);
    assert.equal(res.body.ok, false);
  }
});

test('Rate limiter: expires stale records and never exceeds its key bound', () => {
  let now = 1000;
  const limiter = createSlidingWindowRateLimiter({
    clock: () => now,
    windowMs: 100,
    cleanupIntervalMs: 1,
    maxPerWindow: 2,
    maxKeys: 2,
  });

  assert.equal(limiter.isAllowed('one').allowed, true);
  assert.equal(limiter.isAllowed('two').allowed, true);
  assert.equal(limiter.size, 2);
  assert.equal(limiter.isAllowed('three').allowed, true);
  assert.equal(limiter.size, 2);

  now += 101;
  assert.equal(limiter.isAllowed('fresh').allowed, true);
  assert.equal(limiter.size, 1);
});

test('Rate limiter: trusted Appwrite client IP takes precedence over forwarded input', async () => {
  let observedKey = null;
  const handler = createGetAuthorizedLessonHandler({
    rateLimiter: {
      isAllowed(key) {
        observedKey = key;
        return { allowed: false, remaining: 0, retryAfterSec: 30 };
      },
    },
  });
  const res = mockRes();

  await handler({
    req: request(
      { action: 'list_lessons' },
      {
        'x-appwrite-client-ip': '203.0.113.10',
        'x-forwarded-for': '198.51.100.200',
      },
    ),
    res,
  });

  assert.equal(observedKey, 'ip:203.0.113.10');
  assert.equal(res.statusCode, 429);
});
