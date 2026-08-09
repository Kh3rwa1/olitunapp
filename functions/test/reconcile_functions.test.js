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
    const origEnv = process.env.APPWRITE_FUNCTION_API_KEY;
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

    if (origEnv) process.env.APPWRITE_FUNCTION_API_KEY = origEnv;

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
});
