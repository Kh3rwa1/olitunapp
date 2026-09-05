import assert from 'node:assert/strict';
import test from 'node:test';
import {
  classifyLesson,
  desiredPermissions,
} from './check_premium_content_permissions.mjs';

test('premium category body is protected', () => {
  assert.deepEqual(
    classifyLesson({ unlockMode: 'paid_only', previewLessonCount: 1 }, { order: 2 }),
    { public: false, reason: 'category-paid_only' },
  );
});

test('configured preview remains public', () => {
  assert.equal(
    classifyLesson({ unlockMode: 'review_or_paid', previewLessonCount: 2 }, { order: 1 }).public,
    true,
  );
});

test('missing category fails closed', () => {
  assert.equal(classifyLesson(undefined, { order: 1 }).public, false);
});

test('protected permissions remove anonymous and broad authenticated reads', () => {
  assert.deepEqual(
    desiredPermissions(['read("any")', 'read("users")', 'update("team:admins")'], false),
    ['update("team:admins")'],
  );
});

test('public permissions preserve writes and add anonymous read once', () => {
  assert.deepEqual(
    desiredPermissions(['update("team:admins")'], true),
    ['update("team:admins")', 'read("any")'],
  );
});
