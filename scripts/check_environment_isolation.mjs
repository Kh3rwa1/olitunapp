import { readFileSync } from 'node:fs';

const runtimeFiles = [
  'lib/core/config/appwrite_config.dart',
  'lib/core/observability/crash_reporting.dart',
  'scripts/build_web.sh',
  'scripts/vercel_build.sh',
  '.github/workflows/flutter-ci.yml',
  '.github/workflows/build-apk.yml',
];

const forbiddenProductionLiterals = [
  '699495910038e39622c5',
  '6a007db60024418c0997',
  '84bebaf2d902ae3f5326d29727aa6635',
];

for (const path of runtimeFiles) {
  const source = readFileSync(path, 'utf8');
  for (const literal of forbiddenProductionLiterals) {
    if (source.includes(literal)) {
      throw new Error(
        `${path} contains a production identifier. Inject it through release secrets instead.`,
      );
    }
  }
}

const appwriteConfig = readFileSync(
  'lib/core/config/appwrite_config.dart',
  'utf8',
);
const defaultEndpointMatch = appwriteConfig.match(
  /defaultValue:\s*'(?<url>https?:\/\/[^']+)'/,
);
if (!defaultEndpointMatch?.groups?.url) {
  throw new Error('AppwriteConfig must declare a development endpoint.');
}

const developmentEndpoint = new URL(defaultEndpointMatch.groups.url);
if (
  developmentEndpoint.protocol !== 'https:' ||
  developmentEndpoint.hostname !== 'example.invalid' ||
  developmentEndpoint.port !== '' ||
  developmentEndpoint.pathname !== '/v1' ||
  developmentEndpoint.search !== '' ||
  developmentEndpoint.hash !== ''
) {
  throw new Error(
    'The development Appwrite endpoint must be exactly https://example.invalid/v1.',
  );
}

for (const path of ['scripts/build_web.sh', 'scripts/vercel_build.sh']) {
  const source = readFileSync(path, 'utf8');
  if (!source.includes('APP_ENV')) {
    throw new Error(`${path} must pass an explicit APP_ENV.`);
  }
}

const releaseWorkflow = readFileSync(
  '.github/workflows/build-apk.yml',
  'utf8',
);
if (!releaseWorkflow.includes('--dart-define=APP_ENV=production')) {
  throw new Error('Production APK builds must set APP_ENV=production.');
}

console.log(
  '✅ Runtime and release configuration are isolated from production literals.',
);
