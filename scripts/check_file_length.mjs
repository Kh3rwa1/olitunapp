#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';

const MAX_LINES = 600;

// Files permanently exempt from the length gate (code-generated or static data arrays)
const PERMANENT_EXEMPTIONS = new Set([
  'lib/features/lessons/data/ol_chiki_strokes.dart', // SVG stroke coordinates database
]);

// Grandfather list of existing legacy files exceeding 600 lines.
// As each file is refactored below 600 lines, remove it from this list.
// If a grandfathered file drops below 600 lines, the script will require its removal to ratchet down.
const GRANDFATHERED_FILES = new Set([
  // Empty as of the 2026-09 god-file refactor: every hand-written file is
  // under the 600-line cap. Add entries only with a dated removal plan.
]);

function getAllDartFiles(dir, fileList = []) {
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);
    if (stat.isDirectory()) {
      // Exclude generated localization directory
      if (filePath.includes('lib/l10n/generated') || filePath.includes('lib\\l10n\\generated')) {
        continue;
      }
      getAllDartFiles(filePath, fileList);
    } else if (file.endsWith('.dart')) {
      fileList.push(filePath);
    }
  }
  return fileList;
}

function countLines(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  if (!content || content.trim().length === 0) return 0;
  return content.trimEnd().split('\n').length;
}

function main() {
  const rootDir = process.cwd();
  const libDir = path.join(rootDir, 'lib');

  if (!fs.existsSync(libDir)) {
    console.error('Error: "lib" directory not found.');
    process.exit(1);
  }

  const allFiles = getAllDartFiles(libDir);
  const violations = [];
  const staleGrandfathered = [];
  let checkedCount = 0;

  for (const filePath of allFiles) {
    const relPath = path.relative(rootDir, filePath).replace(/\\/g, '/');

    if (PERMANENT_EXEMPTIONS.has(relPath)) {
      continue;
    }

    checkedCount++;
    const lines = countLines(filePath);

    if (GRANDFATHERED_FILES.has(relPath)) {
      if (lines <= MAX_LINES) {
        staleGrandfathered.push({ path: relPath, lines });
      }
    } else if (lines > MAX_LINES) {
      violations.push({ path: relPath, lines });
    }
  }

  console.log(`\n🔍 Checked ${checkedCount} Dart files in lib/ against ${MAX_LINES}-line limit.\n`);

  let hasError = false;

  if (staleGrandfathered.length > 0) {
    console.warn('⚠️  Ratcheting Gate: The following grandfathered files are now ≤ ' + MAX_LINES + ' lines and must be removed from GRANDFATHERED_FILES:');
    for (const item of staleGrandfathered) {
      console.warn(`  - ${item.path} (${item.lines} lines)`);
    }
    hasError = true;
  }

  if (violations.length > 0) {
    console.error('❌ File Length Violations: The following files exceed ' + MAX_LINES + ' lines:');
    for (const item of violations) {
      console.error(`  - ${item.path} (${item.lines} lines, exceeds by ${item.lines - MAX_LINES})`);
    }
    hasError = true;
  }

  if (hasError) {
    console.error('\n🚫 File length gate check failed.\n');
    process.exit(1);
  }

  console.log('✅ File length gate passed successfully! All non-exempted files are under ' + MAX_LINES + ' lines.\n');
}

main();
