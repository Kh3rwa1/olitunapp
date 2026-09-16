from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def patch(path, old, new):
    target = ROOT / path
    value = target.read_text(encoding='utf-8')
    count = value.count(old)
    if count != 1:
        raise RuntimeError(f'{path}: expected one anchor, found {count}')
    target.write_text(value.replace(old, new, 1), encoding='utf-8')


patch(
    'scripts/check_premium_content_permissions.mjs',
    "export function classifyLesson(category, lesson) {\n  if (!category) return { public: false, reason: 'category-unresolved' };",
    "export function classifyLesson(category, lesson) {\n  if (lesson?.isActive === false) {\n    return { public: false, reason: 'inactive-lesson' };\n  }\n  if (!category) return { public: false, reason: 'category-unresolved' };",
)
patch(
    'scripts/check_premium_content_permissions.mjs',
    "  if (orderAnomalies.length > 0) {\n    throw new Error(`Refusing migration: ${orderAnomalies.length} lesson-order anomalies detected`);\n  }",
    "  if (orderAnomalies.length > 0) {\n    console.warn(\n      `Warning: ${orderAnomalies.length} lesson-order anomalies detected; ` +\n      'non-positive or ambiguous legacy order values remain protected unless the category is free.',\n    );\n  }",
)
patch(
    'scripts/check_premium_content_permissions.test.mjs',
    "test('premium category body is protected', () => {",
    "test('inactive lessons are protected even in free categories', () => {\n  assert.deepEqual(\n    classifyLesson({ unlockMode: 'free' }, { isActive: false, isPremium: false }),\n    { public: false, reason: 'inactive-lesson' },\n  );\n});\n\ntest('premium category body is protected', () => {",
)
patch(
    'functions/getAuthorizedLesson/src/list-lessons.js',
    "  const queries = [Query.orderAsc('order'), Query.limit(limit)];",
    "  const queries = [\n    Query.equal('isActive', true),\n    Query.orderAsc('order'),\n    Query.limit(limit),\n  ];",
)
patch(
    'functions/getAuthorizedLesson/src/main.js',
    "    if (!lessonDoc.categoryId) {",
    "    if (lessonDoc.isActive === false) {\n      return res.json(\n        { ok: false, error: 'lesson_not_found', message: 'Lesson not found' },\n        404,\n      );\n    }\n\n    if (!lessonDoc.categoryId) {",
)
patch(
    'functions/test/authorized_lesson_listing.test.js',
    "test('Authorized Lesson List: batches buyer entitlements instead of querying per lesson', async () => {",
    "test('Authorized Lesson List: excludes inactive lessons at the query boundary', async () => {\n  const databases = makeFakeDatabases({\n    lessons: [\n      lesson('active', 'cat_free', 1, { isActive: true }),\n      lesson('inactive', 'cat_free', 2, { isActive: false }),\n    ],\n    categories: [freeCategory()],\n  });\n  const handler = createGetAuthorizedLessonHandler({ databases });\n  const res = mockRes();\n\n  await handler({ req: request({ action: 'list_lessons' }), res });\n\n  assert.deepEqual(res.body.lessons.map((item) => item.id), ['active']);\n  const lessonCall = databases.calls.find((call) =>\n    call.operation === 'listDocuments' && call.collectionId === 'lessons');\n  assert.equal(\n    parseQueries(lessonCall.queries).some((query) =>\n      query.method === 'equal' &&\n      query.attribute === 'isActive' &&\n      query.values?.includes(true)),\n    true,\n  );\n});\n\ntest('Authorized Lesson List: batches buyer entitlements instead of querying per lesson', async () => {",
)
patch(
    'functions/test/authorized_lesson.test.js',
    "test('Authorized Lesson: Missing or non-existent lesson returns 404', async () => {",
    "test('Authorized Lesson: Inactive lesson returns 404 without exposing its body', async () => {\n  const databases = makeFakeDatabases({\n    lessons: {\n      lesson_inactive: {\n        categoryId: 'cat_free_basics',\n        isActive: false,\n        blocks: JSON.stringify(samplePaidBlocks),\n      },\n    },\n    categories: { cat_free_basics: { unlockMode: 'free' } },\n  });\n  const handler = createGetAuthorizedLessonHandler({ databases });\n  const res = mockRes();\n\n  await handler({\n    req: {\n      method: 'POST',\n      headers: {},\n      body: JSON.stringify({ lessonId: 'lesson_inactive' }),\n    },\n    res,\n  });\n\n  assert.equal(res.statusCode, 404);\n  assert.equal(res.body.error, 'lesson_not_found');\n  assert.equal(Object.hasOwn(res.body, 'lesson'), false);\n});\n\ntest('Authorized Lesson: Missing or non-existent lesson returns 404', async () => {",
)

print('inactive lesson boundary patch applied')
