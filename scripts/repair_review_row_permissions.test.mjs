import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { isRowPermissionCompliant, getCleanPermissions } from './repair_review_row_permissions.mjs';

describe('repair_review_row_permissions unit tests', () => {
  test('isRowPermissionCompliant accepts strictly owner read-only permission', () => {
    const row = {
      userId: 'learner_123',
      $permissions: ['read("user:learner_123")'],
    };
    assert.equal(isRowPermissionCompliant(row), true);
  });

  test('isRowPermissionCompliant rejects rows with owner update or delete permissions', () => {
    const overPrivileged = {
      userId: 'learner_123',
      $permissions: [
        'read("user:learner_123")',
        'update("user:learner_123")',
        'delete("user:learner_123")',
      ],
    };
    assert.equal(isRowPermissionCompliant(overPrivileged), false);
  });

  test('isRowPermissionCompliant rejects rows with missing or empty permissions', () => {
    assert.equal(isRowPermissionCompliant({ userId: 'u1', $permissions: [] }), false);
    assert.equal(isRowPermissionCompliant({ userId: 'u1' }), false);
    assert.equal(isRowPermissionCompliant(null), false);
  });

  test('isRowPermissionCompliant rejects rows with mismatched user ID in permission', () => {
    const mismatched = {
      userId: 'user_a',
      $permissions: ['read("user:user_b")'],
    };
    assert.equal(isRowPermissionCompliant(mismatched), false);
  });

  test('getCleanPermissions produces exactly owner read-only permission', () => {
    assert.deepEqual(getCleanPermissions({ userId: 'alice' }), ['read("user:alice")']);
  });
});
