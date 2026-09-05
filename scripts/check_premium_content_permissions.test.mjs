import assert from 'node:assert/strict';
import test from 'node:test';
import {
  assertCollectionBoundary,
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
