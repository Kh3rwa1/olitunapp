import fs from 'fs';
import path from 'path';

const swPath = path.resolve('build/web/flutter_service_worker.js');

if (!fs.existsSync(swPath)) {
  console.error(`Error: Service worker file not found at ${swPath}`);
  process.exit(1);
}

const content = fs.readFileSync(swPath, 'utf8');
let failures = [];

// --- Check 1: RESOURCES map ---
const resourcesMatch = content.match(/const\s+RESOURCES\s*=\s*\{([^}]+)\}/);
if (!resourcesMatch) {
  console.error('Error: Could not locate RESOURCES map declaration in service worker.');
  process.exit(1);
}

if (resourcesMatch[1].includes('flutter_bootstrap.js')) {
  failures.push('flutter_bootstrap.js is still present in the RESOURCES cache manifest');
}

// --- Check 2: CORE array ---
const coreMatch = content.match(/const\s+CORE\s*=\s*\[([^\]]*)\]/s);
if (!coreMatch) {
  console.error('Error: Could not locate CORE array declaration in service worker.');
  process.exit(1);
}

if (coreMatch[1].includes('flutter_bootstrap.js')) {
  failures.push('flutter_bootstrap.js is still present in the CORE shell files array');
}

// --- Check 3: Patch marker ---
if (!content.includes('// ITUN_PATCHED_SW')) {
  failures.push('ITUN_PATCHED_SW marker is missing — patch may not have run');
}

if (failures.length > 0) {
  console.error('Verification Failure:');
  failures.forEach(f => console.error(`  - ${f}`));
  process.exit(1);
}

console.log('Verification Success: flutter_bootstrap.js excluded from both RESOURCES and CORE, patch marker present.');
process.exit(0);
