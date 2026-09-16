import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const read = (filePath) => JSON.parse(fs.readFileSync(filePath, 'utf8'));
const canonical = read('appwrite.json').functions;
const secondary = read('appwrite.config.json').functions;

assert.ok(Array.isArray(canonical) && canonical.length > 0, 'appwrite.json must define functions');
assert.deepEqual(secondary, canonical, 'Function deployment manifests have drifted');

const ids = new Set();
const names = new Set();
for (const fn of canonical) {
  assert.equal(typeof fn.$id, 'string', 'Every function must have a string $id');
  assert.ok(fn.$id.length > 0 && fn.$id.length <= 36, `Invalid function ID: ${fn.$id}`);
  assert.ok(!ids.has(fn.$id), `Duplicate function ID: ${fn.$id}`);
  ids.add(fn.$id);

  assert.equal(typeof fn.name, 'string', `${fn.$id} must have a name`);
  assert.ok(fn.name.length > 0, `${fn.$id} must have a non-empty name`);
  assert.ok(!names.has(fn.name), `Duplicate function name: ${fn.name}`);
  names.add(fn.name);

  assert.match(fn.runtime, /^node-\d+\.\d+$/, `${fn.$id} must use a versioned Node runtime`);
  assert.equal(typeof fn.enabled, 'boolean', `${fn.$id} must declare enabled`);
  assert.equal(typeof fn.logging, 'boolean', `${fn.$id} must declare logging`);
  assert.ok(Number.isInteger(fn.timeout) && fn.timeout > 0, `${fn.$id} must have a positive timeout`);
  assert.ok(Array.isArray(fn.execute), `${fn.$id} must declare execute roles`);
  assert.ok(Array.isArray(fn.events), `${fn.$id} must declare events`);
  assert.ok(Array.isArray(fn.scopes), `${fn.$id} must declare scopes`);
  assert.equal(new Set(fn.execute).size, fn.execute.length, `${fn.$id} has duplicate execute roles`);
  assert.equal(new Set(fn.scopes).size, fn.scopes.length, `${fn.$id} has duplicate scopes`);

  assert.equal(typeof fn.path, 'string', `${fn.$id} must declare a source path`);
  assert.equal(typeof fn.entrypoint, 'string', `${fn.$id} must declare an entrypoint`);
  const sourcePath = path.resolve(fn.path);
  const entrypointPath = path.resolve(fn.path, fn.entrypoint);
  assert.ok(fs.statSync(sourcePath).isDirectory(), `${fn.$id} source path must be a directory`);
  assert.ok(fs.statSync(entrypointPath).isFile(), `${fn.$id} entrypoint file must exist`);
  assert.ok(entrypointPath.startsWith(`${sourcePath}${path.sep}`), `${fn.$id} entrypoint must stay inside its source path`);
}

function getFunction(id) {
  const fn = canonical.find((candidate) => candidate.$id === id || candidate.name === id);
  assert.ok(fn, `Missing required function: ${id}`);
  return fn;
}

function assertExactScopes(fn, expected) {
  assert.deepEqual(
    [...fn.scopes].sort(),
    [...expected].sort(),
    `${fn.$id} scopes must follow least privilege`,
  );
}

for (const id of ['reconcileOrphanedDeletions', 'reconcilePaymentAttempts']) {
  const fn = getFunction(id);
  assert.ok(fn.enabled && fn.schedule, `${id} must be enabled and scheduled`);
  assert.deepEqual(fn.execute, [], `${id} must not be callable by ordinary users`);
  if (id === 'reconcileOrphanedDeletions') {
    for (const scope of ['users.read', 'documents.read', 'documents.write']) {
      assert.ok(fn.scopes.includes(scope), `${id} missing ${scope}`);
    }
    assert.ok(!fn.scopes.includes('users.write'), `${id} must not grant users.write`);
  }
}

const translator = getFunction('translator');
for (const scope of ['documents.read', 'documents.write']) {
  assert.ok(translator.scopes.includes(scope), `translator missing ${scope}`);
}

const mutateReviewState = getFunction('mutateReviewState');
assert.ok(mutateReviewState.enabled, 'mutateReviewState must be enabled');
assert.deepEqual(
  mutateReviewState.execute,
  ['users'],
  'mutateReviewState must allow execution strictly by authenticated users ["users"]',
);
assert.equal(mutateReviewState.runtime, 'node-22.0');
assert.equal(mutateReviewState.path, 'functions/mutateReviewState');
assert.equal(mutateReviewState.entrypoint, 'src/main.js');
assertExactScopes(mutateReviewState, ['rows.read', 'rows.write']);

const getAuthorizedLesson = getFunction('getAuthorizedLesson');
assert.ok(getAuthorizedLesson.enabled, 'getAuthorizedLesson must be enabled');
assert.deepEqual(
  getAuthorizedLesson.execute,
  ['any'],
  'getAuthorizedLesson must support anonymous previews while enforcing access in-function',
);
assert.deepEqual(getAuthorizedLesson.events, [], 'getAuthorizedLesson must not have event triggers');
assert.equal(getAuthorizedLesson.schedule, '', 'getAuthorizedLesson must not be scheduled');
assert.equal(getAuthorizedLesson.runtime, 'node-22.0');
assert.equal(getAuthorizedLesson.path, 'functions/getAuthorizedLesson');
assert.equal(getAuthorizedLesson.entrypoint, 'src/main.js');
assertExactScopes(getAuthorizedLesson, [
  'databases.read',
  'documents.read',
  'files.read',
  'tokens.write',
]);

console.log(
  `Verified ${canonical.length} function manifests, source paths, execution roles, schedules, and least-privilege scopes.`,
);
