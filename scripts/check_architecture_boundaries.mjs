#!/usr/bin/env node
/**
 * Architecture Boundary Checker for Olitun Flutter App.
 *
 * SDK isolation rule: the Appwrite SDK (`package:appwrite/`) may only be
 * imported from
 *   - `lib/core/**`            (auth seams: AppwriteAuthService, EdgeAuth…;
 *                               Appwrite is auth-only, see
 *                               scripts/check_appwrite_auth_only.mjs)
 *   - `lib/features/<feature>/data/**` (repository/datasource impls + DI)
 * Every other Dart file under `lib/` (presentation, domain, providers,
 * `lib/shared/**`, `lib/app/**`, `lib/main.dart`, …) must go through those
 * seams instead.
 *
 * Layering rules (see ARCHITECTURE.md):
 *   - `lib/core/**` is app-agnostic infrastructure and must not import
 *     `lib/shared/**` or `lib/features/**`.
 *   - `lib/shared/**` must not import `lib/features/**`.
 *   - `lib/features/<a>/{data,domain}/**` must not import another feature's
 *     `presentation/` layer (use that feature's `data`/`domain` API).
 * Every import/export URI (including conditional `if (...) '...'` URIs and
 * multi-line directives) is resolved to a `lib/` path before classifying.
 *
 * Exit code 0 if all boundaries are respected.
 * Exit code 1 with list of violations if any forbidden import is found.
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, '..');

const PACKAGE_NAME = 'itun';

/**
 * Explicit, reviewed exceptions: `{ 'lib/path.dart': ['rule-id', …] }`, each
 * with a comment giving the reason. Keep it empty — fix the dependency
 * (move code down a layer, or invert it) instead of adding entries. Stale
 * entries fail the check.
 */
export const ALLOW_LIST = {};

export const RULES = {
  'appwrite-sdk':
    'package:appwrite/ may only be imported from lib/core/** or lib/features/*/data/** (use the core/api seams)',
  'core-upward':
    'lib/core/** must not import lib/shared/** or lib/features/** (move the code down or invert the dependency)',
  'shared-upward':
    'lib/shared/** must not import lib/features/** (move the code down into shared/core, or move the consumer into the feature)',
  'feature-presentation':
    "lib/features/*/{data,domain}/** must not import another feature's presentation/ layer (use its data/domain API)",
};

/** Returns true when `relativePath` may import package:appwrite. */
export function isAllowedAppwriteImporter(relativePath) {
  if (relativePath.startsWith('lib/core/')) return true;
  return /^lib\/features\/[^/]+\/data\//.test(relativePath);
}

/**
 * Resolves a directive URI to a repo-relative `lib/...` path, or returns
 * `null` for SDK/third-party URIs. Like Dart, `..` never climbs above the
 * package root (`lib/`).
 */
export function resolveUri(fromRelativePath, uri) {
  if (uri.startsWith(`package:${PACKAGE_NAME}/`)) {
    return `lib/${path.posix.normalize(uri.slice(PACKAGE_NAME.length + 9))}`;
  }
  if (/^[a-z][a-z0-9+.-]*:/i.test(uri)) return null;
  if (!fromRelativePath.startsWith('lib/')) return null;
  const segments = path.posix.dirname(fromRelativePath.slice(4)).split('/').filter((s) => s && s !== '.');
  for (const part of uri.split('/')) {
    if (part === '..') segments.pop();
    else if (part !== '.' && part !== '') segments.push(part);
  }
  return `lib/${segments.join('/')}`;
}

/** Extracts `{ uri, line }` for every import/export/part URI in `source`. */
export function directiveUris(source) {
  const results = [];
  const directive = /^[ \t]*(?:import|export|part)\b[^;]*;/gm;
  let match;
  while ((match = directive.exec(source)) !== null) {
    const startLine = source.slice(0, match.index).split('\n').length;
    const uriRegex = /(['"])([^'"\n]+)\1/g;
    let uriMatch;
    while ((uriMatch = uriRegex.exec(match[0])) !== null) {
      const line = startLine + match[0].slice(0, uriMatch.index).split('\n').length - 1;
      results.push({ uri: uriMatch[2], line });
    }
  }
  return results;
}

function featureOf(libPath) {
  const m = /^lib\/features\/([^/]+)\//.exec(libPath);
  return m ? m[1] : null;
}

/** Returns the rule id violated by `from` importing `target`, or null. */
export function layerViolation(from, target) {
  if (from.startsWith('lib/core/')) {
    if (target.startsWith('lib/shared/') || target.startsWith('lib/features/')) return 'core-upward';
  }
  if (from.startsWith('lib/shared/') && target.startsWith('lib/features/')) return 'shared-upward';
  if (/^lib\/features\/[^/]+\/(data|domain)\//.test(from)) {
    const targetFeature = featureOf(target);
    if (
      targetFeature &&
      targetFeature !== featureOf(from) &&
      /^lib\/features\/[^/]+\/presentation\//.test(target)
    ) {
      return 'feature-presentation';
    }
  }
  return null;
}

/** Scans one Dart source file (repo-relative path) for violations. */
export function scanSource(relativePath, source) {
  const violations = [];
  for (const { uri, line } of directiveUris(source)) {
    if (uri.startsWith('package:appwrite/') && !isAllowedAppwriteImporter(relativePath)) {
      violations.push({ file: relativePath, line, rule: 'appwrite-sdk', code: uri });
      continue;
    }
    const target = resolveUri(relativePath, uri);
    if (!target) continue;
    const rule = layerViolation(relativePath, target);
    if (rule) violations.push({ file: relativePath, line, rule, code: uri });
  }
  return violations;
}

function walkDir(dir) {
  if (!fs.existsSync(dir)) return [];
  let files = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) files = files.concat(walkDir(fullPath));
    else if (entry.isFile() && entry.name.endsWith('.dart')) files.push(fullPath);
  }
  return files;
}

/**
 * Checks every Dart file under `<root>/lib`. Returns violations not covered
 * by `allowList`, the allowed ones, and allow-list entries that no longer
 * match anything.
 */
export function checkTree(root, allowList = ALLOW_LIST) {
  const files = walkDir(path.join(root, 'lib'));
  const violations = [];
  const allowed = [];
  const used = new Set();
  for (const file of files) {
    const relativePath = path.relative(root, file).split(path.sep).join('/');
    for (const v of scanSource(relativePath, fs.readFileSync(file, 'utf8'))) {
      if ((allowList[v.file] ?? []).includes(v.rule)) {
        allowed.push(v);
        used.add(`${v.file}\u0000${v.rule}`);
      } else {
        violations.push(v);
      }
    }
  }
  const staleAllowEntries = [];
  for (const [file, rules] of Object.entries(allowList)) {
    for (const rule of rules) {
      if (!used.has(`${file}\u0000${rule}`)) staleAllowEntries.push({ file, rule });
    }
  }
  return { fileCount: files.length, violations, allowed, staleAllowEntries };
}

function main() {
  const { fileCount, violations, staleAllowEntries } = checkTree(repoRoot);
  if (violations.length > 0 || staleAllowEntries.length > 0) {
    console.error(
      `❌ Architecture boundary check failed with ${violations.length} violation(s) and ${staleAllowEntries.length} stale allow-list entr(ies):\n`,
    );
    for (const v of violations) {
      console.error(`  - ${v.file}:${v.line}`);
      console.error(`    Rule: ${RULES[v.rule]}`);
      console.error(`    Code: ${v.code}\n`);
    }
    for (const s of staleAllowEntries) {
      console.error(`  - Stale ALLOW_LIST entry ${s.file} (${s.rule}): remove it from scripts/check_architecture_boundaries.mjs`);
    }
    process.exit(1);
  }
  console.log(`✅ Architecture boundary check passed: ${fileCount} Dart files checked, 0 violations.`);
}

if (process.argv[1] && path.resolve(process.argv[1]) === __filename) {
  main();
}
