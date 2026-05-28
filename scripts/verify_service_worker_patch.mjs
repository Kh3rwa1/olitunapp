import fs from 'fs';
import path from 'path';

const swPath = path.resolve('build/web/flutter_service_worker.js');

if (!fs.existsSync(swPath)) {
  console.error(`Error: Service worker file not found at ${swPath}`);
  process.exit(1);
}

const content = fs.readFileSync(swPath, 'utf8');

// Find RESOURCES block
const resourcesMatch = content.match(/const\s+RESOURCES\s*=\s*\{([^}]+)\}/);
if (!resourcesMatch) {
  console.error('Error: Could not locate RESOURCES map declaration in service worker.');
  process.exit(1);
}

const resourcesBlock = resourcesMatch[1];

if (resourcesBlock.includes('flutter_bootstrap.js')) {
  console.error('Verification Failure: "flutter_bootstrap.js" is still present inside the RESOURCES cache manifest!');
  process.exit(1);
}

console.log('Verification Success: "flutter_bootstrap.js" has been successfully excluded from the service worker cache map.');
process.exit(0);
