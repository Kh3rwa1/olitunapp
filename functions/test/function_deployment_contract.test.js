import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { handleMutateReviewState } from '../mutateReviewState/src/main.js';

describe('Function Deployment Contract & Security Manifest', () => {
  const readManifest = (file) => JSON.parse(fs.readFileSync(file, 'utf8'));

  test('appwrite.json and appwrite.config.json have identical functions manifest', async () => {
    const canonical = readManifest('appwrite.json').functions;
    const config = readManifest('appwrite.config.json').functions;
    assert.deepEqual(config, canonical, 'Function deployment manifests have drifted between appwrite.json and appwrite.config.json');
  });

  test('mutateReviewState manifest defines trusted execution parameters', () => {
    const canonical = readManifest('appwrite.json').functions;
    const mutateFn = canonical.find((f) => f.$id === 'mutateReviewState' || f.name === 'mutateReviewState');
    assert.ok(mutateFn, 'mutateReviewState must be present in manifest');
    assert.equal(mutateFn.enabled, true, 'mutateReviewState must be enabled');
    assert.equal(mutateFn.runtime, 'node-22.0', 'runtime must be node-22.0');
    assert.equal(mutateFn.entrypoint, 'src/main.js', 'entrypoint must be src/main.js');
    assert.deepEqual(mutateFn.execute, ['users'], 'mutateReviewState must allow execute strictly to authenticated users ["users"]');

    assert.deepEqual(
      [...mutateFn.scopes].sort(),
      ['rows.read', 'rows.write'],
      'mutateReviewState must strictly declare ["rows.read", "rows.write"] scopes'
    );
    for (const forbidden of ['databases.read', 'databases.write', 'documents.read', 'documents.write']) {
      assert.ok(!mutateFn.scopes.includes(forbidden), `mutateReviewState must not contain legacy scope ${forbidden}`);
    }
  });

  test('anonymous execution is denied at handler level with 401 UNAUTHENTICATED', async () => {
    let statusCode = null;
    let responseBody = null;
    const res = {
      json: (data, code = 200) => {
        statusCode = code;
        responseBody = data;
        return data;
      },
    };

    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: {}, // No x-appwrite-user-id
        body: { action: 'delete', itemId: 'word_test' },
      },
      res,
      error: () => {},
    });

    assert.equal(statusCode, 401);
    assert.equal(responseBody.error, 'UNAUTHENTICATED');
  });

  test('spoofed client identity is denied with 403 FORBIDDEN', async () => {
    let statusCode = null;
    let responseBody = null;
    const res = {
      json: (data, code = 200) => {
        statusCode = code;
        responseBody = data;
        return data;
      },
    };

    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'legitimate-user' },
        body: { action: 'delete', itemId: 'word_test', userId: 'victim-user' },
      },
      res,
      error: () => {},
    });

    assert.equal(statusCode, 403);
    assert.equal(responseBody.error, 'FORBIDDEN');
  });

  test('function deployment verification script runs cleanly', async () => {
    await import('../../scripts/verify_function_deployment.mjs');
  });
});
