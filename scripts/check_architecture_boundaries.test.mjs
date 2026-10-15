import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  ALLOW_LIST,
  checkTree,
  directiveUris,
  resolveUri,
  scanSource,
} from './check_architecture_boundaries.mjs';

const rules = (file, source) => scanSource(file, source).map((v) => v.rule);

test('resolveUri handles package, relative and SDK URIs', () => {
  assert.equal(resolveUri('lib/core/a/b.dart', 'package:itun/shared/x.dart'), 'lib/shared/x.dart');
  assert.equal(resolveUri('lib/core/a/b.dart', '../../shared/x.dart'), 'lib/shared/x.dart');
  assert.equal(resolveUri('lib/core/a/b.dart', 'c.dart'), 'lib/core/a/c.dart');
  // Like Dart, `..` never climbs above the package root.
  assert.equal(resolveUri('lib/shared/m/c.dart', '../../../../features/f/x.dart'), 'lib/features/f/x.dart');
  assert.equal(resolveUri('lib/core/a.dart', 'package:flutter/material.dart'), null);
  assert.equal(resolveUri('lib/core/a.dart', 'dart:async'), null);
});

test('directiveUris finds conditional and multi-line URIs with line numbers', () => {
  const src = `import 'a.dart';\n\nimport 'stub.dart'\n    if (dart.library.js_interop) 'web.dart';\nexport 'b.dart' show B;\n`;
  assert.deepEqual(directiveUris(src), [
    { uri: 'a.dart', line: 1 },
    { uri: 'stub.dart', line: 3 },
    { uri: 'web.dart', line: 4 },
    { uri: 'b.dart', line: 5 },
  ]);
});

test('core must not import shared or features', () => {
  assert.deepEqual(rules('lib/core/x.dart', `import '../shared/providers/p.dart';\n`), ['core-upward']);
  assert.deepEqual(rules('lib/core/a/x.dart', `import 'package:itun/features/auth/a.dart';\n`), ['core-upward']);
  assert.deepEqual(rules('lib/core/a/x.dart', `export '../../features/f/presentation/p.dart';\n`), ['core-upward']);
  assert.deepEqual(rules('lib/core/a/x.dart', `import '../b/y.dart';\nimport 'package:itun/core/c.dart';\n`), []);
});

test('shared must not import features (including conditional URIs)', () => {
  assert.deepEqual(rules('lib/shared/x.dart', `import '../features/a/domain/e.dart';\n`), ['shared-upward']);
  assert.deepEqual(
    rules('lib/shared/w/x.dart', `import 'stub.dart'\n    if (dart.library.js_interop) '../../features/l/web.dart';\n`),
    ['shared-upward'],
  );
  assert.deepEqual(rules('lib/shared/w/x.dart', `import '../../core/a.dart';\nimport '../m/b.dart';\n`), []);
});

test("feature data/domain must not import another feature's presentation", () => {
  assert.deepEqual(
    rules('lib/features/quiz/data/r.dart', `import '../../lessons/presentation/providers/p.dart';\n`),
    ['feature-presentation'],
  );
  assert.deepEqual(
    rules('lib/features/quiz/domain/r.dart', `import 'package:itun/features/profile/presentation/p.dart';\n`),
    ['feature-presentation'],
  );
  // Allowed: another feature's data/domain, own presentation, presentation → presentation.
  assert.deepEqual(rules('lib/features/quiz/data/r.dart', `import '../../lessons/data/d.dart';\n`), []);
  assert.deepEqual(rules('lib/features/quiz/data/r.dart', `import '../presentation/p.dart';\n`), []);
  assert.deepEqual(
    rules('lib/features/quiz/presentation/s.dart', `import '../../profile/presentation/w.dart';\n`),
    [],
  );
});

test('Appwrite SDK only from core and feature data', () => {
  const src = `import 'package:appwrite/appwrite.dart';\n`;
  assert.deepEqual(rules('lib/core/auth/a.dart', src), []);
  assert.deepEqual(rules('lib/features/auth/data/a.dart', src), []);
  assert.deepEqual(rules('lib/shared/a.dart', src), ['appwrite-sdk']);
  assert.deepEqual(rules('lib/features/auth/presentation/a.dart', src), ['appwrite-sdk']);
});

function tempTree(files) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'arch-boundaries-'));
  for (const [rel, content] of Object.entries(files)) {
    const full = path.join(root, rel);
    fs.mkdirSync(path.dirname(full), { recursive: true });
    fs.writeFileSync(full, content);
  }
  return root;
}

test('checkTree applies the allow-list and reports stale entries', () => {
  const root = tempTree({
    'lib/core/a.dart': `import '../shared/b.dart';\n`,
    'lib/shared/b.dart': `import '../features/f/c.dart';\n`,
  });
  const result = checkTree(root, {
    'lib/core/a.dart': ['core-upward'],
    'lib/core/gone.dart': ['core-upward'],
  });
  assert.equal(result.allowed.length, 1);
  assert.deepEqual(
    result.violations.map((v) => `${v.file}:${v.line}:${v.rule}`),
    ['lib/shared/b.dart:1:shared-upward'],
  );
  assert.deepEqual(result.staleAllowEntries, [{ file: 'lib/core/gone.dart', rule: 'core-upward' }]);
});

test('the shipped allow-list is empty', () => {
  assert.deepEqual(ALLOW_LIST, {});
});

test('the real lib/ tree passes', () => {
  const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
  const result = checkTree(root);
  assert.deepEqual(result.violations, []);
  assert.deepEqual(result.staleAllowEntries, []);
});
