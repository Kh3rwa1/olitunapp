import assert from 'node:assert/strict';
import test from 'node:test';
import {
  assertCollectionBoundary,
  auditLessonOrders,
  classifyLesson,
  desiredPermissions,
  parseArgs,
} from './check_premium_content_permissions.mjs';

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

test('explicit isPreview grants public access even outside order window', () => {
  assert.deepEqual(
    classifyLesson({ unlockMode: 'paid_only', previewLessonCount: 2 }, { order: 10, isPreview: true }),
    { public: true, reason: 'explicit-preview' },
  );
});

test('unknown mode denies even a positive order-window preview', () => {
  assert.deepEqual(
    classifyLesson({ unlockMode: 'future_mode', previewLessonCount: 5 }, { order: 1 }),
    { public: false, reason: 'unknown-unlock-mode-future_mode' },
  );
});

test('missing category fails closed', () => {
  assert.equal(classifyLesson(undefined, { order: 1 }).public, false);
});

test('protected permissions remove every read role and retain writes', () => {
  assert.deepEqual(
    desiredPermissions([
      'read("any")',
      'read("guests")',
      'read("users")',
      'read("users/verified")',
      'read("label:premium")',
      'read("team:admins")',
      'update("team:admins")',
      'delete("team:admins")',
    ], false),
    ['update("team:admins")', 'delete("team:admins")'],
  );
});

test('public permissions canonicalize reads to anonymous and preserve writes', () => {
  assert.deepEqual(
    desiredPermissions(['read("guests")', 'update("team:admins")'], true),
    ['update("team:admins")', 'read("any")'],
  );
});

test('collection read grants are rejected even with document security', () => {
  assert.throws(
    () => assertCollectionBoundary({
      documentSecurity: true,
      $permissions: ['read("any")', 'create("team:admins")'],
    }),
    /collection-level read grants/,
  );
  assert.doesNotThrow(() => assertCollectionBoundary({
    documentSecurity: true,
    $permissions: ['create("team:admins")'],
  }));
});

test('apply confirmation is bound to the explicit project', () => {
  assert.throws(
    () => parseArgs(['--apply', '--confirm-project=wrong'], 'target-project'),
    /--confirm-project=target-project/,
  );
  assert.deepEqual(
    parseArgs(['--apply', '--confirm-project=target-project'], 'target-project'),
    { apply: true },
  );
});

test('auditLessonOrders passes for sequential positive orders', () => {
  const lessons = [
    { $id: 'l1', categoryId: 'cat1', order: 1 },
    { $id: 'l2', categoryId: 'cat1', order: 2 },
    { $id: 'l3', categoryId: 'cat1', order: 3 },
  ];
  assert.deepEqual(auditLessonOrders(lessons), []);
});

test('auditLessonOrders detects zeroes, negatives, duplicates, and gaps', () => {
  const lessons = [
    { $id: 'l0', categoryId: 'cat1', order: 0 },
    { $id: 'l1a', categoryId: 'cat1', order: 2 },
    { $id: 'l1b', categoryId: 'cat1', order: 2 },
    { $id: 'l5', categoryId: 'cat1', order: 5 },
  ];
  const anomalies = auditLessonOrders(lessons);
  assert.equal(anomalies.length, 4);
  assert.equal(anomalies.some((a) => a.type === 'invalid_or_zero' && a.lessonId === 'l0'), true);
  assert.equal(anomalies.some((a) => a.type === 'duplicate' && a.order === 2), true);
  assert.equal(anomalies.some((a) => a.type === 'gap' && a.expected === 1), true);
  assert.equal(anomalies.some((a) => a.type === 'gap' && a.expected === 3 && a.actual === 5), true);
});

