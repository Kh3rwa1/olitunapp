import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { scanSource, stripDart, checkTree } from './check_appwrite_auth_only.mjs';

const rules = (source, file = 'lib/x.dart') => scanSource(file, source).map((v) => v.rule);

test('auth-only Appwrite usage passes', () => {
  const src = `
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

Future<models.Jwt> jwt(Client client) async {
  final account = Account(client);
  final teams = Teams(client);
  await teams.list();
  await account.createOAuth2Session(provider: OAuthProvider.google);
  if (ID.unique().isEmpty) throw AppwriteException('x', 1);
  return account.createJWT();
}
`;
  assert.deepEqual(rules(src), []);
});

test('flags each non-auth SDK service', () => {
  for (const symbol of ['TablesDB', 'Databases', 'Storage', 'Realtime', 'Functions']) {
    const src = `import 'package:appwrite/appwrite.dart';\nfinal s = ${symbol}(client);\n`;
    assert.deepEqual(rules(src), ['sdk-symbol'], symbol);
  }
});

test('flags DB/Storage helpers Query, InputFile, Permission, Role', () => {
  const src = `import 'package:appwrite/appwrite.dart';
final q = Query.equal('a', 1);
final f = InputFile.fromPath(path: 'p');
final p = Permission.read(Role.any());
`;
  assert.deepEqual(
    scanSource('lib/x.dart', src).map((v) => v.detail),
    ['Query', 'InputFile', 'Permission', 'Role'],
  );
});

test('flags prefixed and show-imported SDK services', () => {
  assert.deepEqual(
    rules(`import 'package:appwrite/appwrite.dart' as aw;\nfinal db = aw.TablesDB(c);\n`),
    ['sdk-symbol'],
  );
  assert.deepEqual(
    rules(`import 'package:appwrite/appwrite.dart' show Storage;\n`),
    ['sdk-symbol'],
  );
});

test('flags non-auth package:appwrite entry points', () => {
  assert.deepEqual(rules(`import 'package:appwrite/realtime_io.dart';\n`), ['appwrite-import']);
});

test('SDK names are fine without an Appwrite import, in comments and in strings', () => {
  assert.deepEqual(rules(`class Storage {}\nfinal s = Storage();\n`), []);
  assert.deepEqual(
    rules(`import 'package:appwrite/appwrite.dart';
// Replaces Appwrite Storage and Realtime.
/* Databases are gone. /* nested Functions */ still a comment */
final msg = 'Storage upload failed';
`),
    [],
  );
});

test('flags createExecution anywhere in code but not in comments', () => {
  assert.deepEqual(rules(`final r = await fns.createExecution(functionId: 'x');\n`), ['create-execution']);
  assert.deepEqual(rules(`// legacy createExecution was removed\n`), []);
});

test('flags Appwrite REST paths in strings', () => {
  assert.deepEqual(rules(`final u = '$e/v1/storage/buckets/audio/files/1/view';\n`), ['storage-path']);
  assert.deepEqual(rules(`final u = '$e/v1/functions/reviewContent/executions';\n`), ['functions-path']);
  assert.deepEqual(rules(`final u = '$e/v1/tablesdb/olitun_db/tables/x/rows';\n`), ['tablesdb-path']);
  assert.deepEqual(rules(`final u = '$e/v1/databases/olitun_db/collections/x';\n`), ['databases-path']);
  assert.deepEqual(rules(`final re = RegExp(r'/storage/buckets/([a-z]+)/files');\n`), ['storage-path']);
  assert.deepEqual(rules(`// see /v1/storage/buckets in the old docs\n`), []);
});

test('reports the original line number', () => {
  const v = scanSource('lib/x.dart', `\n\n/* a\n b */\nfinal r = x.createExecution();\n`);
  assert.equal(v[0].line, 5);
});

test('stripDart keeps raw strings with backslashes and triple quotes intact', () => {
  const { code, codeWithStrings } = stripDart(`final a = r'\\d+'; final b = '''x\n'y'\n'''; final c = 1;`);
  assert.ok(code.includes('final c = 1;'));
  assert.ok(codeWithStrings.includes("r'\\d+'"));
  assert.equal(code.split('\n').length, 3);
});

function tempTree(files) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'appwrite-auth-only-'));
  for (const [rel, content] of Object.entries(files)) {
    const full = path.join(root, rel);
    fs.mkdirSync(path.dirname(full), { recursive: true });
    fs.writeFileSync(full, content);
  }
  return root;
}

test('checkTree applies the per-file allow-list by rule', () => {
  const root = tempTree({
    'lib/core/media/parser.dart': `final re = RegExp(r'/storage/buckets/([a-z]+)');\n`,
    'lib/core/media/caller.dart': `final u = '/v1/storage/buckets/a/files/b';\nfinal x = f.createExecution();\n`,
  });
  const result = checkTree(root, { 'lib/core/media/parser.dart': ['storage-path'] });
  assert.equal(result.allowed.length, 1);
  assert.deepEqual(
    result.violations.map((v) => `${v.file}:${v.rule}`).sort(),
    ['lib/core/media/caller.dart:create-execution', 'lib/core/media/caller.dart:storage-path'],
  );
  assert.deepEqual(result.staleAllowEntries, []);
});

test('checkTree reports stale allow-list entries', () => {
  const root = tempTree({ 'lib/a.dart': `void main() {}\n` });
  const result = checkTree(root, { 'lib/a.dart': ['storage-path'], 'lib/gone.dart': ['functions-path'] });
  assert.deepEqual(result.violations, []);
  assert.deepEqual(result.staleAllowEntries, [
    { file: 'lib/a.dart', rule: 'storage-path' },
    { file: 'lib/gone.dart', rule: 'functions-path' },
  ]);
});

test('the real lib/ tree passes with the shipped allow-list', () => {
  const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
  const result = checkTree(root);
  assert.deepEqual(result.violations, []);
  assert.deepEqual(result.staleAllowEntries, []);
});
