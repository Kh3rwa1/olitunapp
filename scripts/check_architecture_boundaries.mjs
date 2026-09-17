#!/usr/bin/env node
/**
 * Architecture Boundary Checker for Olitun Flutter App.
 *
 * Enforces clean architecture invariants across layers:
 * 1. Presentation layer (`lib/**\/presentation\/`) MUST NOT directly import the Appwrite SDK (`package:appwrite/`).
 *    All backend access must be mediated by domain/data/core services and datasources.
 * 2. Shared repositories (`lib/shared/repositories/`) MUST NOT directly import the Appwrite SDK (`package:appwrite/`).
 *    Remote access must be delegated through datasources in `lib/core/api/`.
 *
 * Exit code 0 if all boundaries are respected.
 * Exit code 1 with list of violations if any forbidden import is found.
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const root = path.resolve(__dirname, '..');
const libDir = path.join(root, 'lib');

const FORBIDDEN_IMPORT_REGEX = /import\s+['"]package:appwrite\//;

function walkDir(dir) {
  let files = [];
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files = files.concat(walkDir(fullPath));
    } else if (entry.isFile() && entry.name.endsWith('.dart')) {
      files.push(fullPath);
    }
  }
  return files;
}

function checkArchitectureBoundaries() {
  const dartFiles = walkDir(libDir);
  const violations = [];

  for (const file of dartFiles) {
    const relativePath = path.relative(root, file).replace(/\\/g, '/');
    const isPresentation = relativePath.includes('/presentation/');
    const isSharedRepo = relativePath.startsWith('lib/shared/repositories/');

    if (!isPresentation && !isSharedRepo) {
      continue;
    }

    const content = fs.readFileSync(file, 'utf8');
    const lines = content.split('\n');

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      if (FORBIDDEN_IMPORT_REGEX.test(line)) {
        violations.push({
          file: relativePath,
          line: i + 1,
          rule: isPresentation
            ? 'Presentation layer must not directly import package:appwrite/'
            : 'Shared repositories must not directly import package:appwrite/ (use core/api datasources)',
          code: line.trim(),
        });
      }
    }
  }

  if (violations.length > 0) {
    console.error(`❌ Architecture boundary check failed with ${violations.length} violation(s):\n`);
    for (const v of violations) {
      console.error(`  - ${v.file}:${v.line}`);
      console.error(`    Rule: ${v.rule}`);
      console.error(`    Code: ${v.code}\n`);
    }
    process.exit(1);
  }

  console.log(`✅ Architecture boundary check passed: ${dartFiles.length} Dart files checked, 0 violations.`);
}

checkArchitectureBoundaries();
