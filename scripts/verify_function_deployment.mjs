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
    for (const scope of ['users.read', 'users.write', 'documents.read', 'documents.write'])
      assert.ok(fn.scopes.includes(scope), `${id} missing ${scope}`);
  }
}
const translator = canonical.find(f => f.name === 'translator');
for (const scope of ['documents.read', 'documents.write']) {
  assert.ok(translator.scopes.includes(scope), `translator missing ${scope}`);
}
console.log('Function manifests, schedules, execution roles and required scopes verified.');
