import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import reconcilePaymentAttemptsHandler from '../reconcilePaymentAttempts/src/main.js';
import reconcileOrphanedDeletionsHandler from '../reconcileOrphanedDeletions/src/main.js';

function createMockRes() {
  const res = {
    statusCode: 200,
    body: null,
    json: (body, status = 200) => {
      res.statusCode = status;
      res.body = body;
      return body;
    },
  };
  return res;
}

describe('Reconciliation Serverless Function Wrappers Suite', () => {
  test('reconcilePaymentAttempts returns 500 when environment configuration is missing', async () => {
    const origKey = process.env.APPWRITE_FUNCTION_API_KEY;
    delete process.env.APPWRITE_FUNCTION_API_KEY;
    delete process.env.APPWRITE_API_KEY;

    const req = {};
    const res = createMockRes();

    await reconcilePaymentAttemptsHandler({
      req,
      res,
      log: () => {},
      error: () => {},
    });

    if (origKey) process.env.APPWRITE_FUNCTION_API_KEY = origKey;

    assert.equal(res.statusCode, 500);
    assert.equal(res.body.ok, false);
    assert.equal(res.body.message, 'Server misconfiguration');
  });

  test('reconcileOrphanedDeletions returns 500 when database ID is missing', async () => {
    const origDb = process.env.APPWRITE_DATABASE_ID;
    delete process.env.APPWRITE_DATABASE_ID;

    const req = {};
    const res = createMockRes();

    await reconcileOrphanedDeletionsHandler({
      req,
      res,
      log: () => {},
      error: () => {},
    });

    if (origDb) process.env.APPWRITE_DATABASE_ID = origDb;

    assert.equal(res.statusCode, 500);
    assert.equal(res.body.ok, false);
    assert.equal(res.body.message, 'Server misconfiguration');
  });

  test('reconcilePaymentAttempts returns 200 and scans payment_attempts when env is configured', async () => {
    const req = {};
    const res = createMockRes();

    // Mock environment vars for test execution
    process.env.APPWRITE_FUNCTION_API_KEY = 'test_key';
    process.env.APPWRITE_ENDPOINT = 'http://localhost/v1';
    process.env.APPWRITE_PROJECT_ID = 'test_project';
    process.env.APPWRITE_DATABASE_ID = 'test_db';

    await reconcilePaymentAttemptsHandler({
      req,
      res,
      log: () => {},
      error: () => {},
    });

    assert.equal(res.statusCode, 200);
    assert.equal(res.body.ok, true);
    assert.ok(res.body.stats !== undefined);
  });

  test('reconcileOrphanedDeletions returns 200 and completes scan when env is configured', async () => {
    const req = {};
    const res = createMockRes();

    process.env.APPWRITE_FUNCTION_API_KEY = 'test_key';
    process.env.APPWRITE_ENDPOINT = 'http://localhost/v1';
    process.env.APPWRITE_PROJECT_ID = 'test_project';
    process.env.APPWRITE_DATABASE_ID = 'test_db';

    await reconcileOrphanedDeletionsHandler({
      req,
      res,
      log: () => {},
      error: () => {},
    });

    assert.equal(res.statusCode, 200);
    assert.equal(res.body.ok, true);
    assert.ok(res.body.stats !== undefined);
    assert.equal(typeof res.body.stats.scanned, 'number');
  });
});
