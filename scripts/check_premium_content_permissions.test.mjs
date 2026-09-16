import assert from 'node:assert/strict';
import test from 'node:test';
import {
  assertActiveDeployment,
  assertCollectionBoundary,
  assertRequiredVariables,
  auditLessonOrders,
  classifyLesson,
  createRollbackRecord,
  cursorQueries,
  desiredPermissions,
  desiredTablePermissions,
  parseArgs,
} from './check_premium_content_permissions.mjs';

test('inactive lessons are protected even in free categories', () => {
  assert.deepEqual(
    classifyLesson({ unlockMode: 'free' }, { isActive: false, isPremium: false }),
    { public: false, reason: 'inactive-lesson' },
  );
});

test('premium category body is protected', () => {
  assert.deepEqual(
    classifyLesson({ unlockMode: 'paid_only', previewLessonCount: 1 }, { order: 2 }),
    { public: false, reason: 'category-paid_only' },
  );
});

test('known paid mode may use the legacy positive-order window', () => {
  assert.equal(
    classifyLesson({ unlockMode: 'review_or_paid', previewLessonCount: 2 }, { order: 1 }).public,
    true,
  );
});

test('explicit preview grants public access outside the order window', () => {
  assert.deepEqual(
    classifyLesson(
      { unlockMode: 'paid_only', previewLessonCount: 2 },
      { order: 10, isPreview: true },
    ),
    { public: true, reason: 'explicit-preview' },
  );
});

test('explicit premium flag wins over preview', () => {
  assert.deepEqual(
    classifyLesson(
      { unlockMode: 'free', previewLessonCount: 5 },
      { order: 1, isPreview: true, isPremium: true },
    ),
    { public: false, reason: 'item-marked-premium' },
  );
});

test('unknown mode and missing category fail closed', () => {
  assert.equal(
    classifyLesson({ unlockMode: 'future_mode', previewLessonCount: 5 }, { order: 1 }).public,
    false,
  );
  assert.equal(classifyLesson(undefined, { order: 1 }).public, false);
});

test('protected row permissions remove every read role and retain writes', () => {
  assert.deepEqual(
    desiredPermissions(
      [
        'read("any")',
        'read("guests")',
        'read("users")',
        'read("users/verified")',
        'read("label:premium")',
        'read("team:admins")',
        'update("team:admins")',
        'delete("team:admins")',
      ],
      false,
    ),
    ['update("team:admins")', 'delete("team:admins")'],
  );
});

test('public row permissions canonicalize reads to anonymous', () => {
  assert.deepEqual(
    desiredPermissions(['read("guests")', 'update("team:admins")'], true),
    ['update("team:admins")', 'read("any")'],
  );
});

test('table boundary permits only admin-team read access', () => {
  assert.deepEqual(
    desiredTablePermissions(
      ['read("users")', 'create("team:admins")', 'update("team:admins")'],
      'admins',
    ),
    ['create("team:admins")', 'update("team:admins")', 'read("team:admins")'],
  );
  assert.throws(
    () =>
      assertCollectionBoundary({
        rowSecurity: true,
        $permissions: ['read("users")', 'read("team:admins")'],
      }),
    /non-admin table-level read grant/,
  );
  assert.doesNotThrow(() =>
    assertCollectionBoundary({
      rowSecurity: true,
      $permissions: ['read("team:admins")', 'create("team:admins")'],
    }),
  );
});

test('apply confirmation is bound to the explicit project and phase', () => {
  assert.throws(
    () => parseArgs(['--phase=rows', '--apply', '--confirm-project=wrong'], 'target-project'),
    /--confirm-project=target-project/,
  );
  assert.deepEqual(
    parseArgs(['--phase=rows', '--apply', '--confirm-project=target-project'], 'target-project'),
    {
      phase: 'rows',
      apply: true,
      expectedReleaseCommit: null,
      rollbackOutput: null,
    },
  );
});

test('boundary requires exact protected-main commit confirmation', () => {
  const sha = 'a'.repeat(40);
  assert.throws(
    () => parseArgs(['--phase=boundary', `--expected-release-commit=${sha}`, '--apply', '--confirm-project=p'], 'p'),
    /--confirm-release-commit=/,
  );
  assert.deepEqual(
    parseArgs(
      [
        '--phase=boundary',
        `--expected-release-commit=${sha}`,
        '--apply',
        '--confirm-project=p',
        `--confirm-release-commit=${sha}`,
      ],
      'p',
    ),
    {
      phase: 'boundary',
      apply: true,
      expectedReleaseCommit: sha,
      rollbackOutput: null,
    },
  );
});

test('cursor pagination never uses offset', () => {
  assert.deepEqual(cursorQueries(null, 100), ['{"method":"limit","values":[100]}']);
  assert.deepEqual(cursorQueries('row-100', 100), [
    '{"method":"limit","values":[100]}',
    '{"method":"cursorAfter","values":["row-100"]}',
  ]);
  assert.equal(cursorQueries('row-100').some((query) => query.includes('offset')), false);
});

test('active deployment verification never substitutes latest deployment', () => {
  const expected = 'b'.repeat(40);
  assert.doesNotThrow(() =>
    assertActiveDeployment(
      { deploymentId: 'active', latestDeploymentId: 'preview' },
      { $id: 'active', status: 'ready', providerCommitHash: expected, providerBranch: 'main' },
      expected,
      'site',
    ),
  );
  assert.throws(
    () =>
      assertActiveDeployment(
        { deploymentId: 'active', latestDeploymentId: 'preview' },
        { $id: 'preview', status: 'ready', providerCommitHash: expected },
        expected,
        'site',
      ),
    /did not load deploymentId/,
  );
});

test('authorization variables reject stale entitlement configuration', () => {
  const valid = [
    { key: 'APPWRITE_DATABASE_ID', value: 'olitun_db' },
    { key: 'LESSONS_COLLECTION_ID', value: 'lessons' },
    { key: 'COURSE_PURCHASES_COLLECTION_ID', value: 'course_purchases' },
    { key: 'PAID_MEDIA_BUCKET_ID', value: 'paid_media' },
    { key: 'MEDIA_PUBLIC_ENDPOINT', value: 'https://sgp.cloud.appwrite.io/v1' },
  ];
  assert.doesNotThrow(() => assertRequiredVariables(valid));
  assert.throws(
    () => assertRequiredVariables([...valid, { key: 'PAYMENT_COLLECTION_ID', value: 'payments' }]),
    /stale PAYMENT_COLLECTION_ID/,
  );
});

test('auditLessonOrders detects zeroes, duplicates, and gaps', () => {
  const lessons = [
    { $id: 'l0', categoryId: 'cat1', order: 0 },
    { $id: 'l1a', categoryId: 'cat1', order: 2 },
    { $id: 'l1b', categoryId: 'cat1', order: 2 },
    { $id: 'l5', categoryId: 'cat1', order: 5 },
  ];
  const anomalies = auditLessonOrders(lessons);
  assert.equal(anomalies.length, 4);
  assert.equal(anomalies.some((item) => item.type === 'invalid_or_zero'), true);
  assert.equal(anomalies.some((item) => item.type === 'duplicate'), true);
  assert.equal(anomalies.some((item) => item.type === 'gap' && item.expected === 1), true);
  assert.equal(anomalies.some((item) => item.type === 'gap' && item.expected === 3), true);
});

test('rollback record contains permissions but no variables or secrets', () => {
  const record = createRollbackRecord({
    projectId: 'p',
    databaseId: 'd',
    table: {
      $id: 'lessons',
      name: 'Lessons',
      rowSecurity: false,
      enabled: true,
      $permissions: ['read("users")'],
    },
    plans: [
      {
        lesson: { $id: 'lesson-1' },
        current: ['read("any")'],
      },
    ],
    expectedCommit: 'c'.repeat(40),
    generatedAt: '2026-09-16T00:00:00.000Z',
  });
  assert.equal(record.rows[0].id, 'lesson-1');
  assert.equal(JSON.stringify(record).includes('APPWRITE_API_KEY'), false);
  assert.equal(JSON.stringify(record).includes('variables'), false);
});
