import fs from 'fs';
import path from 'path';

const swPath = path.resolve('build/web/flutter_service_worker.js');

if (!fs.existsSync(swPath)) {
  console.error(`Error: Service worker file not found at ${swPath}`);
  process.exit(1);
}

let content = fs.readFileSync(swPath, 'utf8');

// --- Idempotency check ---
// If already patched, verify bootstrap is fully absent and exit clean.
if (content.includes('// ITUN_PATCHED_SW')) {
  const hasBootstrap = content.includes('flutter_bootstrap.js');
  if (!hasBootstrap) {
    console.log('Verification: patch marker present and flutter_bootstrap.js fully absent. Exiting successfully.');
    process.exit(0);
  }
  // Marker present but bootstrap still found — fall through to re-patch.
  console.log('Warning: patch marker present but flutter_bootstrap.js still found. Re-patching...');
}

let patched = false;

// --- Target 1: RESOURCES hash map (older Flutter SDK) ---
// Matches "flutter_bootstrap.js": "hash" with optional trailing comma and whitespace.
const resourcesRegex = /["']flutter_bootstrap\.js["']\s*:\s*["'][a-f0-9]+["']\s*,?\s*/gi;
if (resourcesRegex.test(content)) {
  resourcesRegex.lastIndex = 0;
  content = content.replace(resourcesRegex, '');
  console.log('  - Removed flutter_bootstrap.js from RESOURCES map.');
  patched = true;
}

// --- Target 2: CORE array (current Flutter SDK) ---
// Matches "flutter_bootstrap.js" as an array element with optional trailing comma and whitespace/newline.
const coreRegex = /["']flutter_bootstrap\.js["']\s*,?\s*\n?/g;
if (coreRegex.test(content)) {
  coreRegex.lastIndex = 0;
  content = content.replace(coreRegex, '');
  console.log('  - Removed flutter_bootstrap.js from CORE array.');
  patched = true;
}

if (!patched) {
  // flutter_bootstrap.js not found in either RESOURCES or CORE, and no patch marker — SDK drift.
  console.error('Error: flutter_bootstrap.js not found in RESOURCES map or CORE array (and no patch marker was found).');
  console.error('The Flutter SDK output format may have changed. Manual investigation required.');
  process.exit(1);
}

// --- Append patch marker ---
if (!content.includes('// ITUN_PATCHED_SW')) {
  content = content.trim() + '\n\n// ITUN_PATCHED_SW\n';
}

// --- Resource count reporting ---
const resourceEntries = content.match(/"[^"]+"\s*:\s*"[^"]+"/g) || [];
const coreEntries = content.match(/const\s+CORE\s*=\s*\[([^\]]*)\]/s);
const coreItems = coreEntries ? coreEntries[1].match(/"[^"]+"/g) || [] : [];

fs.writeFileSync(swPath, content, 'utf8');
console.log('Successfully patched service worker.');
console.log(`  - RESOURCES entries: ${resourceEntries.length}`);
console.log(`  - CORE entries: ${coreItems.length}`);
process.exit(0);
