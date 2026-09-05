import test from 'node:test';
import assert from 'node:assert/strict';
import { createGetAuthorizedLessonHandler, evaluateLessonAccess } from '../getAuthorizedLesson/src/main.js';

function mockRes() {
  const res = {
    statusCode: 200,
    headers: {},
    body: null,
    json(data, code = 200) {
      res.statusCode = code;
      res.body = data;
      return res;
    },
  };
  return res;
}

function makeFakeDatabases({
  lessons = {},
  categories = {},
  purchases = [],
} = {}) {
  return {
    async getDocument(databaseId, collectionId, documentId) {
      if (collectionId === 'lessons') {
        const lesson = lessons[documentId];
        if (!lesson) {
          const err = new Error('Lesson document not found');
          err.code = 404;
          throw err;
        }
        return { $id: documentId, ...lesson };
      }
      if (collectionId === 'categories') {
        const cat = categories[documentId];
        if (!cat) {
          const err = new Error('Category document not found');
          err.code = 404;
          throw err;
        }
        return { $id: documentId, ...cat };
      }
      throw new Error(`Unexpected collection: ${collectionId}`);
    },
    async listDocuments(databaseId, collectionId, queries) {
      if (collectionId === 'course_purchases') {
        let filtered = [...purchases];
        for (const query of queries) {
          let parsed;
          try {
            parsed = typeof query === 'string' ? JSON.parse(query) : query;
          } catch (_) {
            parsed = null;
          }
          if (parsed && parsed.method === 'equal') {
            if (parsed.attribute === 'userId') {
              filtered = filtered.filter((p) => parsed.values.includes(p.userId));
            }
            if (parsed.attribute === 'categoryId') {
              filtered = filtered.filter((p) => parsed.values.includes(p.categoryId));
            }
          }
        }
        return { total: filtered.length, documents: filtered };
      }
      return { total: 0, documents: [] };
    },
  };
}

function makeFakeStorage({ files = {} } = {}) {
  return {
    async getFileDownload(bucketId, fileId) {
      if (files[fileId]) {
        return Buffer.from(files[fileId]);
      }
      const err = new Error('File not found');
      err.code = 404;
      throw err;
    },
  };
}

const samplePaidBlocks = [
  { type: 'text', textOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ', textLatin: 'Ol Chiki' },
  { type: 'audio', audioUrl: 'https://example.com/audio1.mp3' },
];

test('Authorized Lesson: Anonymous caller denied protected lesson body', async () => {
  const databases = makeFakeDatabases({
    lessons: {
      lesson_paid_1: {
        categoryId: 'cat_advanced',
        titleLatin: 'Advanced Vocab',
        titleOlChiki: 'ᱟᱹᱲᱟᱹ ᱜᱟᱵᱟᱱ',
        order: 5,
        blocks: JSON.stringify(samplePaidBlocks),
      },
    },
    categories: {
      cat_advanced: {
        unlockMode: 'paid_only',
        previewLessonCount: 2,
      },
    },
  });

  const handler = createGetAuthorizedLessonHandler({ databases });
  const req = {
    method: 'POST',
    headers: {},
    body: JSON.stringify({ lessonId: 'lesson_paid_1' }),
  };
  const res = mockRes();

  await handler({ req, res });

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.ok, true);
  assert.equal(res.body.locked, true);
  assert.equal(res.body.reason, 'unauthenticated');
  assert.deepEqual(res.body.lesson.blocks, []);
  assert.equal(res.body.lesson.isLocked, true);
});

test('Authorized Lesson: Authenticated non-buyer denied protected lesson body', async () => {
  const databases = makeFakeDatabases({
    lessons: {
      lesson_paid_1: {
        categoryId: 'cat_advanced',
        titleLatin: 'Advanced Vocab',
        order: 5,
        blocks: JSON.stringify(samplePaidBlocks),
      },
    },
    categories: {
      cat_advanced: {
        unlockMode: 'paid_only',
        previewLessonCount: 2,
      },
    },
    purchases: [],
  });

  const handler = createGetAuthorizedLessonHandler({ databases });
  const req = {
    method: 'POST',
    headers: { 'x-appwrite-user-id': 'user_student_1' },
    body: JSON.stringify({ lessonId: 'lesson_paid_1' }),
  };
  const res = mockRes();

  await handler({ req, res });

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.ok, true);
  assert.equal(res.body.locked, true);
  assert.equal(res.body.reason, 'purchase_required');
  assert.deepEqual(res.body.lesson.blocks, []);
});

test('Authorized Lesson: Verified buyer receives complete protected lesson body', async () => {
  const databases = makeFakeDatabases({
    lessons: {
      lesson_paid_1: {
        categoryId: 'cat_advanced',
        titleLatin: 'Advanced Vocab',
        order: 5,
        blocks: JSON.stringify(samplePaidBlocks),
      },
    },
    categories: {
      cat_advanced: {
        unlockMode: 'paid_only',
        previewLessonCount: 2,
      },
    },
    purchases: [
      {
        userId: 'user_student_1',
        categoryId: 'cat_advanced',
        status: 'verified',
        expectedAmount: '499',
        refundedAmountPaise: 0,
      },
    ],
  });

  const handler = createGetAuthorizedLessonHandler({ databases });
  const req = {
    method: 'POST',
    headers: { 'x-appwrite-user-id': 'user_student_1' },
    body: JSON.stringify({ lessonId: 'lesson_paid_1' }),
  };
  const res = mockRes();

  await handler({ req, res });

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.ok, true);
  assert.equal(res.body.locked, false);
  assert.equal(res.body.accessReason, 'entitled');
  assert.equal(res.body.lesson.isLocked, false);
  assert.equal(res.body.lesson.blocks.length, 2);
  assert.equal(res.body.lesson.blocks[0].textLatin, 'Ol Chiki');
});

test('Authorized Lesson: Refunded purchase denies access', async () => {
  const databases = makeFakeDatabases({
    lessons: {
      lesson_paid_1: {
        categoryId: 'cat_advanced',
        titleLatin: 'Advanced Vocab',
        order: 5,
        blocks: JSON.stringify(samplePaidBlocks),
      },
    },
    categories: {
      cat_advanced: {
        unlockMode: 'paid_only',
        previewLessonCount: 2,
      },
    },
    purchases: [
      {
        userId: 'user_refunded',
        categoryId: 'cat_advanced',
        status: 'refunded',
        expectedAmount: '499',
        refundedAmountPaise: 49900,
      },
    ],
  });

  const handler = createGetAuthorizedLessonHandler({ databases });
  const req = {
    method: 'POST',
    headers: { 'x-appwrite-user-id': 'user_refunded' },
    body: JSON.stringify({ lessonId: 'lesson_paid_1' }),
  };
  const res = mockRes();

  await handler({ req, res });

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.locked, true);
  assert.equal(res.body.reason, 'purchase_required');
  assert.deepEqual(res.body.lesson.blocks, []);
});

test('Authorized Lesson: Disputed or revoked purchase denies access', async () => {
  const databases = makeFakeDatabases({
    lessons: {
      lesson_paid_1: {
        categoryId: 'cat_advanced',
        titleLatin: 'Advanced Vocab',
        order: 5,
        blocks: JSON.stringify(samplePaidBlocks),
      },
    },
    categories: {
      cat_advanced: {
        unlockMode: 'paid_only',
        previewLessonCount: 2,
      },
    },
    purchases: [
      {
        userId: 'user_disputed',
        categoryId: 'cat_advanced',
        status: 'disputed',
        expectedAmount: '499',
      },
    ],
  });

  const handler = createGetAuthorizedLessonHandler({ databases });
  const req = {
    method: 'POST',
    headers: { 'x-appwrite-user-id': 'user_disputed' },
    body: JSON.stringify({ lessonId: 'lesson_paid_1' }),
  };
  const res = mockRes();

  await handler({ req, res });

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.locked, true);
  assert.deepEqual(res.body.lesson.blocks, []);
});

test('Authorized Lesson: Free category lesson grants full body to anonymous caller', async () => {
  const databases = makeFakeDatabases({
    lessons: {
      lesson_free_1: {
        categoryId: 'cat_free_basics',
        titleLatin: 'Basic Letters',
        order: 1,
        blocks: JSON.stringify(samplePaidBlocks),
      },
    },
    categories: {
      cat_free_basics: {
        unlockMode: 'free',
      },
    },
  });

  const handler = createGetAuthorizedLessonHandler({ databases });
  const req = {
    method: 'POST',
    headers: {},
    body: JSON.stringify({ lessonId: 'lesson_free_1' }),
  };
  const res = mockRes();

  await handler({ req, res });

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.ok, true);
  assert.equal(res.body.locked, false);
  assert.equal(res.body.accessReason, 'free_category');
  assert.equal(res.body.lesson.blocks.length, 2);
});

test('Authorized Lesson: Explicit preview (isPreview=true) grants access regardless of order', async () => {
  const databases = makeFakeDatabases({
    lessons: {
      lesson_preview_explicit: {
        categoryId: 'cat_advanced',
        titleLatin: 'Preview Bonus Lesson',
        order: 99,
        isPreview: true,
        blocks: JSON.stringify(samplePaidBlocks),
      },
    },
    categories: {
      cat_advanced: {
        unlockMode: 'paid_only',
        previewLessonCount: 1,
      },
    },
  });

  const handler = createGetAuthorizedLessonHandler({ databases });
  const req = {
    method: 'POST',
    headers: {},
    body: JSON.stringify({ lessonId: 'lesson_preview_explicit' }),
  };
  const res = mockRes();

  await handler({ req, res });

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.locked, false);
  assert.equal(res.body.accessReason, 'explicit_preview');
  assert.equal(res.body.lesson.blocks.length, 2);
});

test('Authorized Lesson: Legacy order window preview grants access for order <= previewLessonCount', async () => {
  const databases = makeFakeDatabases({
    lessons: {
      lesson_order_preview: {
        categoryId: 'cat_advanced',
        titleLatin: 'First Chapter',
        order: 2,
        blocks: JSON.stringify(samplePaidBlocks),
      },
    },
    categories: {
      cat_advanced: {
        unlockMode: 'paid_only',
        previewLessonCount: 2,
      },
    },
  });

  const handler = createGetAuthorizedLessonHandler({ databases });
  const req = {
    method: 'POST',
    headers: {},
    body: JSON.stringify({ lessonId: 'lesson_order_preview' }),
  };
  const res = mockRes();

  await handler({ req, res });

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.locked, false);
  assert.equal(res.body.accessReason, 'legacy_order_window_preview');
});

test('Authorized Lesson: Unknown unlock mode fails closed', async () => {
  const databases = makeFakeDatabases({
    lessons: {
      lesson_weird: {
        categoryId: 'cat_weird',
        order: 1,
        blocks: JSON.stringify(samplePaidBlocks),
      },
    },
    categories: {
      cat_weird: {
        unlockMode: 'experimental_cryptocoin',
      },
    },
  });

  const handler = createGetAuthorizedLessonHandler({ databases });
  const req = {
    method: 'POST',
    headers: { 'x-appwrite-user-id': 'user_123' },
    body: JSON.stringify({ lessonId: 'lesson_weird' }),
  };
  const res = mockRes();

  await handler({ req, res });

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.locked, true);
  assert.match(res.body.reason, /unknown_unlock_mode/);
  assert.deepEqual(res.body.lesson.blocks, []);
});

test('Authorized Lesson: Missing or non-existent lesson returns 404', async () => {
  const databases = makeFakeDatabases();
  const handler = createGetAuthorizedLessonHandler({ databases });
  const req = {
    method: 'POST',
    headers: {},
    body: JSON.stringify({ lessonId: 'non_existent_lesson' }),
  };
  const res = mockRes();

  await handler({ req, res });

  assert.equal(res.statusCode, 404);
  assert.equal(res.body.ok, false);
  assert.equal(res.body.error, 'lesson_not_found');
});

test('Authorized Lesson: Client-supplied userId in body is ignored', async () => {
  const databases = makeFakeDatabases({
    lessons: {
      lesson_paid_1: {
        categoryId: 'cat_advanced',
        order: 5,
        blocks: JSON.stringify(samplePaidBlocks),
      },
    },
    categories: {
      cat_advanced: {
        unlockMode: 'paid_only',
      },
    },
    purchases: [
      {
        userId: 'real_buyer_id',
        categoryId: 'cat_advanced',
        status: 'verified',
        expectedAmount: '499',
      },
    ],
  });

  const handler = createGetAuthorizedLessonHandler({ databases });
  // Attacker puts real_buyer_id in body, but x-appwrite-user-id header is spoofing or empty
  const req = {
    method: 'POST',
    headers: {}, // No authenticated header
    body: JSON.stringify({
      lessonId: 'lesson_paid_1',
      userId: 'real_buyer_id', // Spoofed client claim!
      isPremiumUnlocked: true, // Spoofed client claim!
    }),
  };
  const res = mockRes();

  await handler({ req, res });

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.locked, true);
  assert.equal(res.body.reason, 'unauthenticated');
  assert.deepEqual(res.body.lesson.blocks, []);
});

test('Authorized Lesson: Private media action allows entitled buyer and denies non-buyer', async () => {
  const databases = makeFakeDatabases({
    lessons: {
      lesson_paid_1: {
        categoryId: 'cat_advanced',
        order: 5,
        blocks: JSON.stringify(samplePaidBlocks),
      },
    },
    categories: {
      cat_advanced: {
        unlockMode: 'paid_only',
      },
    },
    purchases: [
      {
        userId: 'buyer_user',
        categoryId: 'cat_advanced',
        status: 'verified',
        expectedAmount: '499',
      },
    ],
  });

  const storage = makeFakeStorage({
    files: {
      audio_secure_123: 'FAKE_MP3_BINARY_DATA',
    },
  });

  const handler = createGetAuthorizedLessonHandler({ databases, storage });

  // 1. Non-buyer denied
  const unauthReq = {
    method: 'POST',
    headers: { 'x-appwrite-user-id': 'non_buyer_user' },
    body: JSON.stringify({
      lessonId: 'lesson_paid_1',
      action: 'get_media',
      fileId: 'audio_secure_123',
    }),
  };
  const unauthRes = mockRes();
  await handler({ req: unauthReq, res: unauthRes });
  assert.equal(unauthRes.statusCode, 403);
  assert.equal(unauthRes.body.ok, false);

  // 2. Buyer authorized
  const authReq = {
    method: 'POST',
    headers: { 'x-appwrite-user-id': 'buyer_user' },
    body: JSON.stringify({
      lessonId: 'lesson_paid_1',
      action: 'get_media',
      fileId: 'audio_secure_123',
    }),
  };
  const authRes = mockRes();
  await handler({ req: authReq, res: authRes });
  assert.equal(authRes.statusCode, 200);
  assert.equal(authRes.body.ok, true);
  assert.equal(authRes.body.fileId, 'audio_secure_123');
  assert.ok(authRes.body.base64);
});
