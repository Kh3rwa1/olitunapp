#!/usr/bin/env node

/**
 * CI Gate: No hardcoded user-facing strings outside admin.
 *
 * Flags literal string first-arguments to:
 *   - Text(...) / SelectableText(...)
 *   - AppToast.info|success|error(context, '...')
 *   - AppErrorState(message: '...')
 * when the literal contains translatable letters (2+) outside ${...}
 * interpolation. Emoji/symbol/number-only literals are allowed.
 *
 * Excluded: lib/features/admin/**, lib/l10n/generated/**
 *
 * Flags:
 *   --json                print violations array to stdout
 *   --baseline <path>     grandfathered baseline (default scripts/hardcoded_strings_baseline.json)
 * Stale baseline entries warn only unless HARD_CODED_BASELINE_STRICT=1.
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const ROOT_DIR = path.resolve(path.dirname(__filename), '..');
const LIB_DIR = path.join(ROOT_DIR, 'lib');

const EXCLUDE_PREFIXES = [
  path.join(LIB_DIR, 'features', 'admin') + path.sep,
  path.join(LIB_DIR, 'l10n', 'generated') + path.sep,
];

const PATTERNS = [
  { rule: 'text-literal', re: /(?<![\w])(?:Text|SelectableText)\(\s*(['"])/g },
  {
    rule: 'toast-literal',
    re: /AppToast\.(?:info|success|error)\(\s*context,\s*(['"])/g,
  },
  {
    rule: 'error-state-literal',
    re: /AppErrorState\(\s*message:\s*(['"])/g,
  },
];

function getAllDartFiles(dir) {
  const results = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...getAllDartFiles(fullPath));
    } else if (entry.isFile() && entry.name.endsWith('.dart')) {
      results.push(fullPath);
    }
  }
  return results;
}

function extractLiteral(content, quoteStart, quote) {
  let i = quoteStart + 1;
  let literal = '';
  while (i < content.length) {
    const c = content[i];
    if (c === '\\') {
      literal += c + (content[i + 1] ?? '');
      i += 2;
      continue;
    }
    if (c === quote) break;
    literal += c;
    i += 1;
  }
  return literal;
}

function hasTranslatableLetters(literal) {
  const stripped = literal.replace(/\$\{[^{}]*\}/g, '');
  return /[A-Za-z]{2,}/.test(stripped);
}

function lineOf(content, index) {
  let line = 1;
  for (let i = 0; i < index; i++) {
    if (content[i] === '\n') line += 1;
  }
  return line;
}

function checkHardcodedStrings() {
  const files = getAllDartFiles(LIB_DIR).filter(
    (file) => !EXCLUDE_PREFIXES.some((prefix) => file.startsWith(prefix)),
  );
  const violations = [];

  for (const file of files) {
    const relPath = path.relative(ROOT_DIR, file).replace(/\\/g, '/');
    const content = fs.readFileSync(file, 'utf8');

    for (const { rule, re } of PATTERNS) {
      re.lastIndex = 0;
      let match;
      while ((match = re.exec(content)) !== null) {
        const literal = extractLiteral(content, match.index + match[0].length - 1, match[1]);
        if (hasTranslatableLetters(literal)) {
          violations.push({
            file: relPath,
            line: lineOf(content, match.index),
            rule,
            literal: literal.slice(0, 80),
          });
        }
      }
    }
  }

  const args = process.argv.slice(2);
  const jsonOut = args.includes('--json');
  const baselineIdx = args.indexOf('--baseline');
  const baselinePath =
    baselineIdx !== -1
      ? path.resolve(ROOT_DIR, args[baselineIdx + 1])
      : path.join(ROOT_DIR, 'scripts', 'hardcoded_strings_baseline.json');

  if (jsonOut) {
    process.stdout.write(JSON.stringify(violations, null, 2) + '\n');
  }

  let baselined = new Set();
  if (fs.existsSync(baselinePath)) {
    try {
      const parsed = JSON.parse(fs.readFileSync(baselinePath, 'utf8'));
      baselined = new Set(
        parsed.map((v) => v.file + ' ' + v.rule + ' ' + v.literal),
      );
    } catch {
      console.error(`Hardcoded strings gate: failed to parse baseline ${baselinePath}`);
      process.exit(1);
    }
  }

  const keyOf = (v) => v.file + ' ' + v.rule + ' ' + v.literal;
  const fresh = violations.filter((v) => !baselined.has(keyOf(v)));
  const staleCount = [...baselined].filter(
    (key) => !violations.some((v) => keyOf(v) === key),
  ).length;

  if (staleCount > 0) {
    console.error(
      `Hardcoded strings gate: ${staleCount} stale baseline entr(ies) — please remove them.`,
    );
    if (process.env.HARD_CODED_BASELINE_STRICT === '1') process.exit(1);
  }

  if (fresh.length > 0) {
    if (!jsonOut) {
      console.error(`Hardcoded strings gate: ${fresh.length} violation(s) found.\n`);
      for (const v of fresh) {
        console.error(`  ${v.file}:${v.line} [${v.rule}] ${JSON.stringify(v.literal)}`);
      }
      console.error(
        '\nFix: use AppLocalizations (l10n.*) keys in lib/l10n/arb/*.arb, or restrict changes to lib/features/admin/** (excluded from this gate).',
      );
    } else {
      console.error(`Hardcoded strings gate: ${fresh.length} violation(s) found.`);
    }
    process.exit(1);
  }

  const passMsg = `Hardcoded strings gate passed (${violations.length} baselined, ${files.length} non-admin files checked).`;
  if (jsonOut) {
    console.error(passMsg);
  } else {
    console.log(passMsg);
  }
}

checkHardcodedStrings();
