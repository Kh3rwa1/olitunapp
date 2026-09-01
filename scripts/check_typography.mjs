#!/usr/bin/env node

/**
 * CI Gate: Enforce Bundled Typography & Zero GoogleFonts Runtime
 *
 * Rules:
 * 1. Zero imports of package:google_fonts/google_fonts.dart.
 * 2. Zero usage of GoogleFonts.* API.
 * 3. Only authorized font families allowed in font declarations: 'Inter' and 'OlChiki'.
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT_DIR = path.resolve(__dirname, '..');
const LIB_DIR = path.join(ROOT_DIR, 'lib');

const ALLOWED_FONT_FAMILIES = new Set(['Inter', 'OlChiki']);
const DISALLOWED_FONT_FAMILIES = ['Poppins', 'Fredoka', 'Roboto', 'OpenSans', 'Lato', 'Montserrat'];

function getAllDartFiles(dir) {
  let results = [];
  const list = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of list) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results = results.concat(getAllDartFiles(fullPath));
    } else if (entry.isFile() && entry.name.endsWith('.dart')) {
      results.push(fullPath);
    }
  }

  return results;
}

function checkTypography() {
  const dartFiles = getAllDartFiles(LIB_DIR);
  const violations = [];

  for (const file of dartFiles) {
    const relPath = path.relative(ROOT_DIR, file).replace(/\\/g, '/');
    const content = fs.readFileSync(file, 'utf-8');
    const lines = content.split('\n');

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const lineNum = i + 1;

      // Check 1: GoogleFonts import
      if (line.includes('package:google_fonts/google_fonts.dart')) {
        violations.push({
          file: relPath,
          line: lineNum,
          rule: 'google-fonts-import',
          message: 'Found disallowed google_fonts import. Use bundled fonts via AppTypography.',
        });
      }

      // Check 2: GoogleFonts API usage
      if (line.includes('GoogleFonts.')) {
        violations.push({
          file: relPath,
          line: lineNum,
          rule: 'google-fonts-api',
          message: 'Found GoogleFonts.* usage. Use AppTypography / Theme.of(context).textTheme instead.',
        });
      }

      // Check 3: Disallowed font family strings
      for (const disallowed of DISALLOWED_FONT_FAMILIES) {
        const pattern = new RegExp(`['"]${disallowed}['"]`, 'i');
        if (pattern.test(line)) {
          violations.push({
            file: relPath,
            line: lineNum,
            rule: 'unauthorized-font-family',
            message: `Found unauthorized font family '${disallowed}'. Allowed font families are: ${Array.from(ALLOWED_FONT_FAMILIES).join(', ')}.`,
          });
        }
      }
    }
  }

  console.log(`\n🔍 Checked ${dartFiles.length} Dart files in lib/ for typography compliance.`);

  if (violations.length > 0) {
    console.error(`\n❌ Typography Gate Failed! Found ${violations.length} violation(s):\n`);
    for (const v of violations) {
      console.error(`  - ${v.file}:${v.line} [${v.rule}]: ${v.message}`);
    }
    console.error('\nEnsure all text uses bundled Inter / OlChiki variable fonts via AppTypography or AppTheme.\n');
    process.exit(1);
  }

  console.log('✅ Typography gate passed successfully! All text complies with bundled Inter & OlChiki.\n');
}

checkTypography();
