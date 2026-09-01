#!/usr/bin/env node

/**
 * CI Gate: Ban Deprecated Flutter APIs
 *
 * Rules:
 * 1. `.withOpacity(...)` is prohibited — use `.withValues(alpha: ...)` instead.
 *    Flutter deprecated withOpacity in favor of withValues (wide-gamut color
 *    support); relying on it creates upgrade friction on future SDK bumps.
 * 2. Additional deprecated API bans can be appended to DEPRECATED_PATTERNS
 *    as the Flutter SDK evolves.
 * 3. `lib/l10n/generated/` is exempt (code-generated).
 *
 * Zero-tolerance gate: the codebase was fully migrated, so there is no
 * grandfather list. Any new occurrence fails CI.
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT_DIR = path.resolve(__dirname, '..');

const SCAN_DIRS = ['lib', 'test', 'integration_test'];

const EXEMPT_DIRECTORIES = ['lib/l10n/generated'];

const DEPRECATED_PATTERNS = [
  {
    name: 'Color.withOpacity',
    regex: /\.withOpacity\s*\(/g,
    replacement: 'Use `.withValues(alpha: ...)` instead.',
  },
];

function walkDartFiles(dir, out = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walkDartFiles(full, out);
    } else if (entry.isFile() && entry.name.endsWith('.dart')) {
      out.push(full);
    }
  }
  return out;
}

function isExempt(relPath) {
  return EXEMPT_DIRECTORIES.some(
    (d) => relPath === d || relPath.startsWith(`${d}/`),
  );
}

let violations = 0;

for (const scanDir of SCAN_DIRS) {
  const abs = path.join(ROOT_DIR, scanDir);
  if (!fs.existsSync(abs)) continue;

  for (const file of walkDartFiles(abs)) {
    const relPath = path.relative(ROOT_DIR, file).split(path.sep).join('/');
    if (isExempt(relPath)) continue;

    const lines = fs.readFileSync(file, 'utf8').split('\n');
    lines.forEach((line, idx) => {
      const trimmed = line.trim();
      if (trimmed.startsWith('//')) return; // skip comments
      for (const pattern of DEPRECATED_PATTERNS) {
        pattern.regex.lastIndex = 0;
        if (pattern.regex.test(line)) {
          violations += 1;
          console.error(
            `✗ ${relPath}:${idx + 1} uses deprecated ${pattern.name}. ${pattern.replacement}`,
          );
        }
      }
    });
  }
}

if (violations > 0) {
  console.error(
    `\nDeprecated API gate failed with ${violations} violation(s).`,
  );
  process.exit(1);
}

console.log('✓ Deprecated API gate passed: no banned Flutter APIs found.');
