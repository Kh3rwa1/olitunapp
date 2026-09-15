import fs from 'node:fs';
import assert from 'node:assert/strict';
const read = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const canonical = read('appwrite.json').functions;
assert.deepEqual(read('appwrite.config.json').functions, canonical, 'Function deployment manifests have drifted');
for (const id of ['reconcileOrphanedDeletions', 'reconcilePaymentAttempts']) {
  const fn = canonical.find(f => f.$id === id);
  assert.ok(fn && fn.enabled && fn.schedule, `${id} must be enabled and scheduled`);
  assert.deepEqual(fn.execute, [], `${id} must not be callable by ordinary users`);
  assert.ok(fs.existsSync(`${fn.path}/${fn.entrypoint}`));
  if (id === 'reconcileOrphanedDeletions') {
    // Reconciliation reads account ownership but never mutates Appwrite users.
    for (const scope of ['users.read', 'documents.read', 'documents.write'])
      assert.ok(fn.scopes.includes(scope), `${id} missing ${scope}`);
    assert.ok(!fn.scopes.includes('users.write'), `${id} must not grant users.write`);
  }
}
const translator = canonical.find(f => f.name === 'translator');
for (const scope of ['documents.read', 'documents.write']) {
  assert.ok(translator.scopes.includes(scope), `translator missing ${scope}`);
}

const mutateReviewState = canonical.find(f => f.$id === 'mutateReviewState' || f.name === 'mutateReviewState');
assert.ok(mutateReviewState && mutateReviewState.enabled, 'mutateReviewState must be enabled');
assert.deepEqual(mutateReviewState.execute, ['users'], 'mutateReviewState must allow execution strictly by authenticated users ["users"]');
assert.equal(mutateReviewState.runtime, 'node-22.0', 'mutateReviewState runtime must be node-22.0');
assert.equal(mutateReviewState.entrypoint, 'src/main.js', 'mutateReviewState entrypoint must be src/main.js');
assert.ok(fs.existsSync(`${mutateReviewState.path}/${mutateReviewState.entrypoint}`), 'mutateReviewState entrypoint file must exist');
assert.deepEqual(
  [...mutateReviewState.scopes].sort(),
  ['rows.read', 'rows.write'],
  'mutateReviewState scopes must strictly be ["rows.read", "rows.write"]'
);
for (const forbiddenScope of ['databases.read', 'databases.write', 'documents.read', 'documents.write']) {
  assert.ok(!mutateReviewState.scopes.includes(forbiddenScope), `mutateReviewState must not contain legacy scope ${forbiddenScope}`);
}

console.log('Function manifests, schedules, execution roles and required scopes verified.');
