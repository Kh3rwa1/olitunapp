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
  const lessonWithMediaBlocks = [
    { type: 'text', textLatin: 'Ol Chiki' },
    {
      type: 'audio',
      audioUrl: 'https://cloud.appwrite.io/v1/storage/buckets/paid_media/files/audio_secure_123/view',
    },
  ];

  const databases = makeFakeDatabases({
    lessons: {
      lesson_paid_1: {
        categoryId: 'cat_advanced',
        order: 5,
        blocks: JSON.stringify(lessonWithMediaBlocks),
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

test('Fix 1 Regression: Buyer of course A requests a file belonging only to course B: denied', async () => {
  let storageDownloadCalled = false;
  const databases = makeFakeDatabases({
    lessons: {
      lesson_course_a: {
        categoryId: 'course_a',
        order: 1,
        blocks: JSON.stringify([
          { type: 'audio', audioUrl: 'https://cloud.appwrite.io/v1/storage/buckets/paid_media/files/audio_course_a/view' },
        ]),
      },
      lesson_course_b: {
        categoryId: 'course_b',
        order: 1,
        blocks: JSON.stringify([
          { type: 'audio', audioUrl: 'https://cloud.appwrite.io/v1/storage/buckets/paid_media/files/audio_course_b/view' },
        ]),
      },
    },
    categories: {
      course_a: { unlockMode: 'paid_only' },
      course_b: { unlockMode: 'paid_only' },
    },
    purchases: [
      {
        userId: 'buyer_of_a',
        categoryId: 'course_a',
        status: 'verified',
        expectedAmount: '499',
      },
    ],
  });

  const storage = {
    async getFileDownload(bucketId, fileId) {
      storageDownloadCalled = true;
      return Buffer.from('SECRET_DATA');
    },
  };

  const handler = createGetAuthorizedLessonHandler({ databases, storage });

  // Buyer of course A tries to fetch file belonging only to course B through authorized lesson A
  const req = {
    method: 'POST',
    headers: { 'x-appwrite-user-id': 'buyer_of_a' },
    body: JSON.stringify({
      lessonId: 'lesson_course_a',
      action: 'get_media',
      fileId: 'audio_course_b',
    }),
  };
  const res = mockRes();
  await handler({ req, res });

  assert.equal(res.statusCode, 403);
  assert.equal(res.body.ok, false);
  assert.equal(res.body.error, 'media_not_associated');
  assert.equal(storageDownloadCalled, false, 'Storage download must not be called for unassociated file');
});

test('Fix 1 Regression: Caller uses accessible free lesson with unrelated private file: denied', async () => {
  let storageDownloadCalled = false;
  const databases = makeFakeDatabases({
    lessons: {
      free_lesson_1: {
        categoryId: 'cat_free',
        order: 1,
        blocks: JSON.stringify([
          { type: 'text', textLatin: 'Free content only' },
        ]),
      },
    },
    categories: {
      cat_free: { unlockMode: 'free' },
    },
    purchases: [],
  });

  const storage = {
    async getFileDownload(bucketId, fileId) {
      storageDownloadCalled = true;
      return Buffer.from('SECRET_DATA');
    },
  };

  const handler = createGetAuthorizedLessonHandler({ databases, storage });

  const req = {
    method: 'POST',
    headers: {},
    body: JSON.stringify({
      lessonId: 'free_lesson_1',
      action: 'get_media',
      fileId: 'secret_paid_file_999',
    }),
  };
  const res = mockRes();
  await handler({ req, res });

  assert.equal(res.statusCode, 403);
  assert.equal(res.body.ok, false);
  assert.equal(res.body.error, 'media_not_associated');
  assert.equal(storageDownloadCalled, false, 'Storage download must not be invoked for unrelated private asset');
});

test('Fix 1 Regression: Correct file ID with wrong bucket: denied', async () => {
  let storageDownloadCalled = false;
  const databases = makeFakeDatabases({
    lessons: {
      lesson_paid_1: {
        categoryId: 'cat_advanced',
        order: 1,
        blocks: JSON.stringify([
          { type: 'audio', audioUrl: 'https://cloud.appwrite.io/v1/storage/buckets/paid_media/files/audio_legit/view' },
        ]),
      },
    },
    categories: {
      cat_advanced: { unlockMode: 'paid_only' },
    },
    purchases: [
      {
        userId: 'buyer_1',
        categoryId: 'cat_advanced',
        status: 'verified',
        expectedAmount: '499',
      },
    ],
  });

  const storage = {
    async getFileDownload(bucketId, fileId) {
      storageDownloadCalled = true;
      return Buffer.from('DATA');
    },
  };

  const handler = createGetAuthorizedLessonHandler({ databases, storage });

  const req = {
    method: 'POST',
    headers: { 'x-appwrite-user-id': 'buyer_1' },
    body: JSON.stringify({
      lessonId: 'lesson_paid_1',
      action: 'get_media',
      fileId: 'audio_legit',
      bucketId: 'other_bucket', // Wrong bucket!
    }),
  };
  const res = mockRes();
  await handler({ req, res });

  assert.equal(res.statusCode, 403);
  assert.equal(res.body.ok, false);
  assert.equal(res.body.error, 'bucket_mismatch');
  assert.equal(storageDownloadCalled, false);
});

test('Fix 1 Regression: Refunded or disputed users cannot retrieve associated paid media', async () => {
  let storageDownloadCalled = false;
  const databases = makeFakeDatabases({
    lessons: {
      lesson_paid_1: {
        categoryId: 'cat_advanced',
        order: 1,
        blocks: JSON.stringify([
          { type: 'audio', audioUrl: 'https://cloud.appwrite.io/v1/storage/buckets/paid_media/files/audio_legit/view' },
        ]),
      },
    },
    categories: {
      cat_advanced: { unlockMode: 'paid_only' },
    },
    purchases: [
      {
        userId: 'refunded_user',
        categoryId: 'cat_advanced',
        status: 'refunded',
        refundStatus: 'fully_refunded',
        expectedAmount: '499',
        refundedAmountPaise: 49900,
      },
    ],
  });

  const storage = {
    async getFileDownload(bucketId, fileId) {
      storageDownloadCalled = true;
      return Buffer.from('DATA');
    },
  };

  const handler = createGetAuthorizedLessonHandler({ databases, storage });

  const req = {
    method: 'POST',
    headers: { 'x-appwrite-user-id': 'refunded_user' },
    body: JSON.stringify({
      lessonId: 'lesson_paid_1',
      action: 'get_media',
      fileId: 'audio_legit',
    }),
  };
  const res = mockRes();
  await handler({ req, res });

  assert.equal(res.statusCode, 403);
  assert.equal(res.body.ok, false);
  assert.equal(res.body.error, 'access_denied');
  assert.equal(storageDownloadCalled, false);
});

test('Fix 1 Regression: Nested block references are correctly extracted and authorized', async () => {
  const databases = makeFakeDatabases({
    lessons: {
      lesson_nested: {
        categoryId: 'cat_advanced',
        order: 1,
        blocks: JSON.stringify([
          {
            type: 'universal_media',
            contentJson: {
              contentJson: {
                imageUrl: 'https://cloud.appwrite.io/v1/storage/buckets/paid_media/files/nested_img_777/view',
              },
            },
          },
        ]),
      },
    },
    categories: {
      cat_advanced: { unlockMode: 'paid_only' },
    },
    purchases: [
      {
        userId: 'buyer_1',
        categoryId: 'cat_advanced',
        status: 'verified',
        expectedAmount: '499',
      },
    ],
  });

  const storage = {
    async getFileDownload(bucketId, fileId) {
      return Buffer.from('IMAGE_BINARY_DATA');
    },
  };

  const handler = createGetAuthorizedLessonHandler({ databases, storage });

  const req = {
    method: 'POST',
    headers: { 'x-appwrite-user-id': 'buyer_1' },
    body: JSON.stringify({
      lessonId: 'lesson_nested',
      action: 'get_media',
      fileId: 'nested_img_777',
    }),
  };
  const res = mockRes();
  await handler({ req, res });

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.ok, true);
  assert.equal(res.body.fileId, 'nested_img_777');
  assert.ok(res.body.base64);
});

test('Fix 1 Regression: Conflicting isPremium=true and isPreview=true requires entitlement', async () => {
  const databases = makeFakeDatabases({
    lessons: {
      lesson_conflict: {
        categoryId: 'cat_advanced',
        order: 1,
        isPremium: true, // Explicitly marked premium
        isPreview: true, // Conflicting preview claim
        blocks: JSON.stringify(samplePaidBlocks),
      },
    },
    categories: {
      cat_advanced: { unlockMode: 'paid_only' },
    },
    purchases: [], // Non-buyer
  });

  const handler = createGetAuthorizedLessonHandler({ databases });

  const req = {
    method: 'POST',
    headers: { 'x-appwrite-user-id': 'non_buyer' },
    body: JSON.stringify({
      lessonId: 'lesson_conflict',
    }),
  };
  const res = mockRes();
  await handler({ req, res });

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.locked, true);
  assert.equal(res.body.reason, 'purchase_required');
  assert.deepEqual(res.body.lesson.blocks, []);
});

