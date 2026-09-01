#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';

const ARB_DIR = 'lib/l10n/arb';
const CANONICAL_FILE = 'app_en.arb';

function extractPlaceholders(text) {
  if (typeof text !== 'string') return [];
  const matches = text.match(/\{([^}]+)\}/g);
  if (!matches) return [];
  return matches.map(m => m.slice(1, -1).trim()).sort();
}

function checkL10nParity() {
  const canonicalPath = path.join(ARB_DIR, CANONICAL_FILE);
  if (!fs.existsSync(canonicalPath)) {
    console.error(`❌ Canonical ARB file not found: ${canonicalPath}`);
    process.exit(1);
  }

  const canonicalContent = JSON.parse(fs.readFileSync(canonicalPath, 'utf8'));
  const canonicalKeys = Object.keys(canonicalContent).filter(k => !k.startsWith('@'));
  console.log(`\n🌐 Canonical ARB (${CANONICAL_FILE}): ${canonicalKeys.length} keys`);

  const arbFiles = fs.readdirSync(ARB_DIR).filter(f => f.endsWith('.arb') && f !== CANONICAL_FILE);
  let hasErrors = false;

  for (const file of arbFiles) {
    const filePath = path.join(ARB_DIR, file);
    const content = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    const fileKeys = new Set(Object.keys(content).filter(k => !k.startsWith('@')));

    const missingKeys = canonicalKeys.filter(k => !fileKeys.has(k));
    const extraKeys = [...fileKeys].filter(k => !canonicalContent[k]);

    if (missingKeys.length > 0) {
      hasErrors = true;
      console.error(`\n❌ ${file} is missing ${missingKeys.length} key(s):`);
      for (const k of missingKeys) {
        console.error(`   - ${k}`);
      }
    }

    if (extraKeys.length > 0) {
      hasErrors = true;
      console.error(`\n❌ ${file} has ${extraKeys.length} unknown extra key(s) not in ${CANONICAL_FILE}:`);
      for (const k of extraKeys) {
        console.error(`   + ${k}`);
      }
    }

    // Check placeholder consistency
    for (const key of canonicalKeys) {
      if (fileKeys.has(key)) {
        const expectedPlaceholders = extractPlaceholders(canonicalContent[key]);
        const actualPlaceholders = extractPlaceholders(content[key]);
        if (expectedPlaceholders.join(',') !== actualPlaceholders.join(',')) {
          hasErrors = true;
          console.error(`\n❌ ${file} placeholder mismatch on key "${key}":`);
          console.error(`   Expected: [${expectedPlaceholders.join(', ')}]`);
          console.error(`   Actual:   [${actualPlaceholders.join(', ')}]`);
        }
      }
    }

    if (missingKeys.length === 0 && extraKeys.length === 0) {
      console.log(`✅ ${file}: 100% parity (${fileKeys.size}/${canonicalKeys.length} keys)`);
    }
  }

  if (hasErrors) {
    console.error('\n❌ Localization parity check failed! All languages must have 100% key and placeholder parity with app_en.arb.\n');
    process.exit(1);
  }

  console.log('\n🎉 All ARB files passed 100% localization parity check!\n');
}

checkL10nParity();
