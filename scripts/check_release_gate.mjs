import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

// Keep this list aligned with release-gate.needs in flutter-ci.yml.
export const requiredJobs = Object.freeze([
  'format-and-analyze',
  'flutter-unit-widget-tests',
  'node-backend-tests',
  'permission-and-schema-tests',
  'web-integration-tests',
  'android-emulator-e2e',
  'web-release-build',
  'android-release-build',
  'artifact-verification',
  'dependency-freshness-gate',
]);

export function releaseGateFailures(needs) {
  if (!needs || typeof needs !== 'object' || Array.isArray(needs)) {
    return ['Required job results are missing or malformed.'];
  }

  return requiredJobs.flatMap((job) => {
    const result = Object.hasOwn(needs, job) ? needs[job]?.result : undefined;
    return result === 'success'
      ? []
      : [`${job}: ${typeof result === 'string' ? result : 'missing result'}`];
  });
}

export function runReleaseGate(rawNeeds, output = console) {
  let needs;
  try {
    needs = JSON.parse(rawNeeds);
  } catch {
    output.error('Release gate blocked: required job results are not valid JSON.');
    return 1;
  }

  const failures = releaseGateFailures(needs);
  if (failures.length > 0) {
    output.error(`Release gate blocked:\n${failures.join('\n')}`);
    return 1;
  }

  output.log('Release gate passed: every required job succeeded.');
  return 0;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  process.exitCode = runReleaseGate(process.env.NEEDS_JSON);
}
