#!/usr/bin/env node

/**
 * CI Gate: Bottom sheets must open above the floating shell navigation.
 *
 * The mobile shell renders the glass bottom nav as a floating overlay above
 * the branch navigators. A bottom sheet opened on a branch navigator renders
 * beneath it, hiding sheet actions (e.g. Done / Share buttons) behind the
 * nav bar. Every showModalBottomSheet call must therefore pass
 * `useRootNavigator: true` so the sheet opens on the root navigator.
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT_DIR = path.resolve(__dirname, '..');
const LIB_DIR = path.join(ROOT_DIR, 'lib');

function getAllDartFiles(dir) {
  let results = [];
  const list = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of list) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results = results.concat(getAllDartFiles(fullPath));
    } else if (entry.name.endsWith('.dart')) {
      results.push(fullPath);
    }
  }
  return results;
}

const violations = [];
for (const file of getAllDartFiles(LIB_DIR)) {
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  lines.forEach((line, index) => {
    if (!line.includes('showModalBottomSheet')) return;
    // Doc comments and the parameter definition itself are not call sites.
    const trimmed = line.trim();
    if (trimmed.startsWith('///') || trimmed.startsWith('//')) return;
    const window = lines.slice(index, index + 15).join('\n');
    if (!window.includes('useRootNavigator: true')) {
      violations.push(
        `${path.relative(ROOT_DIR, file)}:${index + 1}: ` +
          'showModalBottomSheet without useRootNavigator: true',
      );
    }
  });
}

if (violations.length > 0) {
  console.error(
    '❌ Bottom sheets must open above the floating nav ' +
      '(useRootNavigator: true):\n' +
      violations.map((v) => `  - ${v}`).join('\n'),
  );
  process.exit(1);
}

console.log(
  '✅ All bottom sheets open above the floating navigation.',
);
