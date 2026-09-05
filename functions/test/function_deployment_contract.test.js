import test from 'node:test';

test('function deployment manifests, schedules and scopes match the required contract', async () => {
  await import('../../scripts/verify_function_deployment.mjs');
});
