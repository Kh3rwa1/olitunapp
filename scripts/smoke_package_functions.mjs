import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

const manifest = JSON.parse(fs.readFileSync('appwrite.json', 'utf8'));
const functions = manifest.functions;
assert.ok(Array.isArray(functions) && functions.length > 0, 'appwrite.json must define functions');

function readJson(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (err) {
    throw new Error(`${path.basename(filePath)} must exist and be valid JSON: ${err.message}`);
  }
}

const failures = [];

for (const fn of functions) {
  const id = fn.$id || fn.name;
  try {
    assert.equal(typeof fn.path, 'string', 'path must be a string');
    assert.equal(typeof fn.entrypoint, 'string', 'entrypoint must be a string');

    const sourcePath = path.resolve(fn.path);
    const entrypointPath = path.resolve(fn.path, fn.entrypoint);
    assert.ok(fs.statSync(sourcePath).isDirectory(), 'source path must be a directory');
    assert.ok(fs.statSync(entrypointPath).isFile(), 'entrypoint must exist');

    const pkg = readJson(path.join(sourcePath, 'package.json'));
    assert.equal(typeof pkg.name, 'string', 'package.json must declare name');
    assert.ok(pkg.name.length > 0, 'package.json name must be non-empty');
    assert.equal(typeof pkg.type, 'string', 'package.json must declare type');
    assert.ok(
      pkg.type === 'module' || pkg.type === 'commonjs',
      `package.json type must be module or commonjs, got ${pkg.type}`,
    );
    assert.equal(typeof pkg.dependencies, 'object', 'package.json must declare dependencies');
    assert.ok(pkg.dependencies && Object.keys(pkg.dependencies).length > 0, 'dependencies must be non-empty');

    if (pkg.main) {
      assert.ok(
        fs.statSync(path.resolve(sourcePath, pkg.main)).isFile(),
        `package.json main (${pkg.main}) must exist`,
      );
    }

    const lock = readJson(path.join(sourcePath, 'package-lock.json'));
    assert.equal(lock.name, pkg.name, 'package-lock.json name must match package.json');
    const lockPackages = lock.packages || {};
    const rootLock = lockPackages[''];
    assert.ok(rootLock, 'package-lock.json must include root packages entry');
    assert.ok(
      rootLock.dependencies && Object.keys(rootLock.dependencies).length > 0,
      'package-lock.json root dependencies must be non-empty',
    );

    execFileSync(process.execPath, ['--check', entrypointPath], { stdio: 'pipe' });
  } catch (err) {
    failures.push(`${id}: ${err.message}`);
  }
}

if (failures.length > 0) {
  console.error('Function packaging smoke failed:');
  for (const failure of failures) {
    console.error(`  - ${failure}`);
  }
  process.exit(1);
}

console.log(
  `Packaging smoke passed for ${functions.length} functions (package.json, lockfile, entrypoint syntax).`,
);
