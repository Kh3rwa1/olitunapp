#!/usr/bin/env node
/**
 * Architecture Boundary Checker for Olitun Flutter App.
 *
 * SDK isolation rule: the Appwrite SDK (`package:appwrite/`) may only be
 * imported from
 *   - `lib/core/**`            (anti-corruption seams: AppwriteDbService,
 *                               AppwriteFunctionsService, RealtimeChangeFeed…)
 *   - `lib/features/<feature>/data/**` (repository/datasource impls + DI)
 * Every other Dart file under `lib/` (presentation, domain, providers,
 * `lib/shared/**`, `lib/app/**`, `lib/main.dart`, …) must go through those
 * seams instead.
 *
 * Layering rule: `lib/core/**` is app-agnostic and must not import
 * `lib/shared/**` or `lib/features/**`. Pre-existing exceptions are listed in
 * CORE_UPWARD_IMPORT_BASELINE and may only shrink.
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

// Matches import/export directives (including multi-line conditional ones
// whose first URI sits on the directive line).
const FORBIDDEN_IMPORT_REGEX = /^\s*(import|export)\s+['"]package:appwrite\//;

const CORE_UPWARD_IMPORT_REGEX =
  /^\s*(import|export)\s+['"](package:itun\/(shared|features)\/|(\.\.\/)+(shared|features)\/)/;

// Legacy core → shared/features imports. Remove entries as they are fixed;
// never add new ones.
const CORE_UPWARD_IMPORT_BASELINE = new Set([
  'lib/core/accessibility/app_experience_scope.dart',
  'lib/core/ads/ad_state.dart',
  'lib/core/ads/rewarded_ad_manager.dart',
  'lib/core/api/ai_service.dart',
  'lib/core/config/feature_flags.dart',
  'lib/core/languages/ol_chiki_multilingual_helper.dart',
  'lib/core/media/authorized_media_provider.dart',
  'lib/core/motion/confetti_overlay.dart',
  'lib/core/storage/media_uploader.dart',
]);

/** Returns true when `relativePath` may import package:appwrite. */
export function isAllowedAppwriteImporter(relativePath) {
  if (relativePath.startsWith('lib/core/')) return true;
  return /^lib\/features\/[^/]+\/data\//.test(relativePath);
}

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
    const content = fs.readFileSync(file, 'utf8');
    const lines = content.split('\n');
    const checkUpward =
      relativePath.startsWith('lib/core/') &&
      !CORE_UPWARD_IMPORT_BASELINE.has(relativePath);

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      if (checkUpward && CORE_UPWARD_IMPORT_REGEX.test(line)) {
        violations.push({
          file: relativePath,
          line: i + 1,
          rule: 'lib/core/** must not import lib/shared/** or lib/features/** (move the code down or invert the dependency)',
          code: line.trim(),
        });
      }
      if (isAllowedAppwriteImporter(relativePath)) continue;
      if (FORBIDDEN_IMPORT_REGEX.test(line)) {
        violations.push({
          file: relativePath,
          line: i + 1,
          rule:
            'package:appwrite/ may only be imported from lib/core/** or lib/features/*/data/** (use the core/api seams)',
          code: line.trim(),
        });
      }
    }
  }

  for (const baselined of CORE_UPWARD_IMPORT_BASELINE) {
    const full = path.join(root, baselined);
    const stillViolates =
      fs.existsSync(full) &&
      fs
        .readFileSync(full, 'utf8')
        .split('\n')
        .some((line) => CORE_UPWARD_IMPORT_REGEX.test(line));
    if (!stillViolates) {
      violations.push({
        file: baselined,
        line: 0,
        rule: 'Stale CORE_UPWARD_IMPORT_BASELINE entry: remove it from scripts/check_architecture_boundaries.mjs',
        code: '',
      });
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

if (process.argv[1] && path.resolve(process.argv[1]) === __filename) {
  checkArchitectureBoundaries();
}
