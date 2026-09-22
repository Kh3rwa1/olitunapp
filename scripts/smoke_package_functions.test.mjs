import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import test from 'node:test';

const root = new URL('../', import.meta.url);
const read = (rel) => readFileSync(new URL(rel, root), 'utf8');

test('CI workflow runs manifest parity and packaging smoke gates', () => {
  const workflow = read('.github/workflows/flutter-ci.yml');
  assert.match(workflow, /node scripts\/verify_function_deployment\.mjs/);
  assert.match(workflow, /node scripts\/smoke_package_functions\.mjs/);
  assert.match(workflow, /node scripts\/check_l10n_parity\.mjs/);
  assert.match(workflow, /node scripts\/check_file_length\.mjs/);
});

test('test:backend chains packaging smoke after manifest verification', () => {
  const pkg = JSON.parse(read('package.json'));
  const chain = pkg.scripts['test:backend'];
  const verify = chain.indexOf('node scripts/verify_function_deployment.mjs');
  const smoke = chain.indexOf('node scripts/smoke_package_functions.mjs');
  assert.ok(verify >= 0, 'test:backend must run verify_function_deployment');
  assert.ok(smoke > verify, 'test:backend must run smoke after verification');
});

test('manifests declare matching function and bucket sets', () => {
  const appwrite = JSON.parse(read('appwrite.json'));
  const config = JSON.parse(read('appwrite.config.json'));
  assert.deepEqual(config.functions, appwrite.functions);
  assert.deepEqual(config.buckets, appwrite.buckets);
  assert.equal(config.projectId, appwrite.projectId);
  assert.deepEqual(config.sites, appwrite.sites);
});

test('smoke_package_functions passes against the real tree', () => {
  const result = spawnSync(process.execPath, ['scripts/smoke_package_functions.mjs'], {
    cwd: root,
    encoding: 'utf8',
  });
  assert.equal(result.status, 0, result.stderr || result.stdout);
  assert.match(result.stdout, /Packaging smoke passed for \d+ functions/);
});
