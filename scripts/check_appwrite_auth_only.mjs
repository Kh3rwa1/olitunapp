#!/usr/bin/env node
/**
 * Appwrite Auth-Only Gate for the Olitun Flutter app.
 *
 * Appwrite is used ONLY for authentication (Account, sessions, JWTs, OAuth,
 * Teams for the admin check). Every other backend call — content, storage,
 * functions, change feeds — goes to the Cloudflare Worker. This gate scans
 * `lib/**\/*.dart` and fails when Appwrite non-auth usage creeps back in:
 *
 *   - SDK services: TablesDB, Databases, Storage, Realtime, Functions
 *     (and their DB/Storage helpers Query, InputFile, Permission, Role)
 *     in any file that imports `package:appwrite`;
 *   - `package:appwrite/` imports other than appwrite.dart / models.dart /
 *     enums.dart (e.g. realtime/io entry points);
 *   - `createExecution` anywhere (Appwrite Functions executions);
 *   - Appwrite REST paths for storage, functions, tablesdb and databases.
 *
 * Comments are ignored. SDK identifiers are matched in code only (string
 * literals blanked); REST paths are matched in code and string literals.
 *
 * Exit code 0 when clean, 1 with a list of violations otherwise.
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ALLOWED_APPWRITE_IMPORTS = new Set([
  'package:appwrite/appwrite.dart',
  'package:appwrite/models.dart',
  'package:appwrite/enums.dart',
]);

const FORBIDDEN_SDK_SYMBOLS = [
  'TablesDB',
  'Databases',
  'Storage',
  'Realtime',
  'RealtimeSubscription',
  'Functions',
  'Query',
  'InputFile',
  'Permission',
  'Role',
];

export const RULES = {
  'appwrite-import': 'imports a non-auth package:appwrite entry point',
  'sdk-symbol': 'uses a non-auth Appwrite SDK service/helper',
  'create-execution': 'calls Appwrite Functions (createExecution)',
  'storage-path': 'references the Appwrite Storage REST path',
  'functions-path': 'references the Appwrite Functions REST path',
  'tablesdb-path': 'references the Appwrite TablesDB REST path',
  'databases-path': 'references the Appwrite Databases REST path',
};

const PATH_RULES = [
  ['storage-path', /(?:\/v1)?\/storage\/buckets\b/],
  ['functions-path', /\/v1\/functions\b|\/functions\/[^/\s'"]+\/executions\b/],
  ['tablesdb-path', /\/v1\/tablesdb\b/i],
  ['databases-path', /\/v1\/databases\b|\/databases\/[^/\s'"]+\/collections\b/],
];

/**
 * Per-file exceptions. Each entry names the rules it may trip and why.
 * Only code that PARSES legacy stored URLs belongs here — never code that
 * calls Appwrite. Entries that no longer match anything fail the gate so
 * the list can only shrink.
 */
export const ALLOW_LIST = {
  // PrivateMediaReference.parse recognises legacy Appwrite Storage URLs that
  // are still stored in lesson content, to map them onto Worker paid media.
  'lib/core/media/authorized_media.dart': ['storage-path'],
  // notificationArtworkUri rewrites legacy stored Appwrite Storage
  // /view URLs to /preview for notification thumbnails; it makes no call.
  'lib/core/audio/notification_artwork_uri.dart': ['storage-path'],
};

/**
 * Returns `{ code, codeWithStrings }`: the source with comments blanked, and
 * additionally with string-literal contents blanked. Newlines are preserved
 * so offsets map to the original line numbers.
 */
export function stripDart(source) {
  const code = source.split('');
  const noStr = source.split('');
  const n = source.length;
  const blank = (arr, from, to) => {
    for (let k = from; k < to; k++) if (arr[k] !== '\n') arr[k] = ' ';
  };
  let i = 0;
  while (i < n) {
    const c = source[i];
    const next = source[i + 1];
    if (c === '/' && next === '/') {
      let j = source.indexOf('\n', i);
      if (j === -1) j = n;
      blank(code, i, j);
      blank(noStr, i, j);
      i = j;
      continue;
    }
    if (c === '/' && next === '*') {
      let depth = 1;
      let j = i + 2;
      while (j < n && depth > 0) {
        if (source[j] === '/' && source[j + 1] === '*') {
          depth++;
          j += 2;
        } else if (source[j] === '*' && source[j + 1] === '/') {
          depth--;
          j += 2;
        } else {
          j++;
        }
      }
      blank(code, i, j);
      blank(noStr, i, j);
      i = j;
      continue;
    }
    if (c === "'" || c === '"') {
      const raw = i > 0 && source[i - 1] === 'r' && !/[A-Za-z0-9_$]/.test(source[i - 2] ?? '');
      const triple = source.startsWith(c.repeat(3), i);
      const quote = triple ? c.repeat(3) : c;
      let j = i + quote.length;
      while (j < n) {
        if (!raw && source[j] === '\\') {
          j += 2;
          continue;
        }
        if (source.startsWith(quote, j)) break;
        if (!triple && source[j] === '\n') break;
        j++;
      }
      const end = Math.min(n, j + quote.length);
      blank(noStr, i + quote.length, Math.min(j, n));
      i = end;
      continue;
    }
    i++;
  }
  return { code: noStr.join(''), codeWithStrings: code.join('') };
}

function lineOf(source, index) {
  let line = 1;
  for (let k = 0; k < index; k++) if (source[k] === '\n') line++;
  return line;
}

/** Scans one Dart source. `relPath` is POSIX-style relative to the repo. */
export function scanSource(relPath, source) {
  const { code, codeWithStrings } = stripDart(source);
  const violations = [];
  const add = (rule, index, detail) =>
    violations.push({ file: relPath, line: lineOf(source, index), rule, detail });

  const importRe = /^\s*(?:import|export)\s+['"](package:appwrite\/[^'"]+)['"]/gm;
  let importsAppwrite = false;
  for (const m of codeWithStrings.matchAll(importRe)) {
    importsAppwrite = true;
    if (!ALLOWED_APPWRITE_IMPORTS.has(m[1])) add('appwrite-import', m.index, m[1]);
  }

  if (importsAppwrite) {
    const symbolRe = new RegExp(`\\b(${FORBIDDEN_SDK_SYMBOLS.join('|')})\\b`, 'g');
    for (const m of code.matchAll(symbolRe)) add('sdk-symbol', m.index, m[1]);
  }

  for (const m of code.matchAll(/\bcreateExecution\b/g)) {
    add('create-execution', m.index, m[0]);
  }

  for (const [rule, re] of PATH_RULES) {
    const global = new RegExp(re.source, re.flags.includes('g') ? re.flags : `${re.flags}g`);
    for (const m of codeWithStrings.matchAll(global)) add(rule, m.index, m[0]);
  }
  return violations;
}

function listDartFiles(dir) {
  const out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) out.push(...listDartFiles(full));
    else if (entry.isFile() && entry.name.endsWith('.dart')) out.push(full);
  }
  return out;
}

/**
 * Scans `<root>/lib`. Returns `{ violations, allowed, staleAllowEntries }`.
 * A violation is allowed only when its file+rule is in [allowList].
 */
export function checkTree(root, allowList = ALLOW_LIST) {
  const libDir = path.join(root, 'lib');
  const violations = [];
  const allowed = [];
  const used = new Set();
  for (const file of listDartFiles(libDir).sort()) {
    const rel = path.relative(root, file).split(path.sep).join('/');
    for (const v of scanSource(rel, fs.readFileSync(file, 'utf8'))) {
      if ((allowList[rel] ?? []).includes(v.rule)) {
        allowed.push(v);
        used.add(`${rel}::${v.rule}`);
      } else {
        violations.push(v);
      }
    }
  }
  const staleAllowEntries = [];
  for (const [file, rules] of Object.entries(allowList)) {
    for (const rule of rules) {
      if (!used.has(`${file}::${rule}`)) staleAllowEntries.push({ file, rule });
    }
  }
  return { violations, allowed, staleAllowEntries };
}

const __filename = fileURLToPath(import.meta.url);
const isDirectCall =
  process.argv[1] && path.resolve(process.argv[1]) === path.resolve(__filename);

if (isDirectCall) {
  const root = path.resolve(path.dirname(__filename), '..');
  const { violations, allowed, staleAllowEntries } = checkTree(root);
  let failed = false;
  if (violations.length > 0) {
    failed = true;
    console.error(`\n❌ Appwrite auth-only gate FAILED: ${violations.length} non-auth Appwrite usage(s):\n`);
    for (const v of violations) {
      console.error(`  - ${v.file}:${v.line} [${v.rule}] ${RULES[v.rule]}: ${v.detail}`);
    }
    console.error('\nAppwrite is for authentication only; route data, storage and functions through the Cloudflare Worker.');
  }
  if (staleAllowEntries.length > 0) {
    failed = true;
    console.error('\n❌ Stale ALLOW_LIST entries (remove them from scripts/check_appwrite_auth_only.mjs):\n');
    for (const e of staleAllowEntries) console.error(`  - ${e.file} [${e.rule}]`);
  }
  if (failed) {
    console.error('');
    process.exit(1);
  }
  console.log(
    `✅ Appwrite is auth-only in lib/ (${allowed.length} allow-listed legacy URL parser match(es)).\n`,
  );
}
