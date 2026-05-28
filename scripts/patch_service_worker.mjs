import fs from 'fs';
import path from 'path';

const swPath = path.resolve('build/web/flutter_service_worker.js');

if (!fs.existsSync(swPath)) {
  console.error(`Error: Service worker file not found at ${swPath}`);
  process.exit(1);
}

let content = fs.readFileSync(swPath, 'utf8');

// Regex to find "flutter_bootstrap.js" entry inside RESOURCES map.
// Matches "flutter_bootstrap.js" (or single quotes) followed by colon, hash, optional comma, and trailing whitespace.
const regex = /["']flutter_bootstrap\.js["']\s*:\s*["'][a-f0-9]+["']\s*,?\s*/gi;

if (!regex.test(content)) {
  // Idempotency: if already patched and absent, exit zero.
  if (!content.includes('flutter_bootstrap.js') && content.includes('// ITUN_PATCHED_SW')) {
    console.log('Verification: flutter_bootstrap.js is already absent and patch marker is present. Exiting successfully.');
    process.exit(0);
  }
  console.error('Error: Could not find "flutter_bootstrap.js" entry in resources map matching the expected format (and no patch marker was found).');
  process.exit(1);
}

// Reset regex index because of test()
regex.lastIndex = 0;

// Log resource count details for visibility
const matchesBefore = content.match(/"[^"]+"\s*:\s*"[^"]+"/g) || [];
const countBefore = matchesBefore.length;

// Remove the bootstrap resource and append the patch marker
let patchedContent = content.replace(regex, '');
if (!patchedContent.includes('// ITUN_PATCHED_SW')) {
  patchedContent = patchedContent.trim() + '\n\n// ITUN_PATCHED_SW\n';
}

const matchesAfter = patchedContent.match(/"[^"]+"\s*:\s*"[^"]+"/g) || [];
const countAfter = matchesAfter.length;

fs.writeFileSync(swPath, patchedContent, 'utf8');
console.log(`Successfully patched service worker.`);
console.log(`  - Resources count before: ${countBefore}`);
console.log(`  - Resources count after:  ${countAfter}`);
process.exit(0);
