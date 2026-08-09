import { test, describe } from 'node:test';
import assert from 'node:assert';
import deleteAccountHandler from '../delete-account/src/main.js';

describe('delete-account serverless function suite', () => {
  test('rejects non-POST HTTP methods with 405 Method Not Allowed', async () => {
    let responseStatus = null;
    let responseBody = null;

    const req = { method: 'GET', headers: {} };
    const res = {
      json: (body, status = 200) => {
        responseStatus = status;
        responseBody = body;
        return body;
      },
    };

    await deleteAccountHandler({ req, res, log: () => {}, error: () => {} });

    assert.strictEqual(responseStatus, 405);
    assert.strictEqual(responseBody.ok, false);
    assert.strictEqual(responseBody.code, 'method_not_allowed');
  });

  test('rejects requests without authentication headers with 401 Unauthenticated', async () => {
    let responseStatus = null;
    let responseBody = null;

    const req = { method: 'POST', headers: {} };
    const res = {
      json: (body, status = 200) => {
        responseStatus = status;
        responseBody = body;
        return body;
      },
    };

    // Ensure function user id env is clean
    const origEnv = process.env.APPWRITE_FUNCTION_USER_ID;
    delete process.env.APPWRITE_FUNCTION_USER_ID;

    await deleteAccountHandler({ req, res, log: () => {}, error: () => {} });

    if (origEnv) process.env.APPWRITE_FUNCTION_USER_ID = origEnv;

    assert.strictEqual(responseStatus, 401);
    assert.strictEqual(responseBody.ok, false);
    assert.strictEqual(responseBody.code, 'unauthenticated');
  });

  test('returns 500 server_misconfiguration when required env vars are missing', async () => {
    let responseStatus = null;
    let responseBody = null;

    const req = { method: 'POST', headers: { 'x-appwrite-user-id': 'user_test_123' } };
    const res = {
      json: (body, status = 200) => {
        responseStatus = status;
        responseBody = body;
        return body;
      },
    };

    const origApiKey = process.env.APPWRITE_API_KEY;
    delete process.env.APPWRITE_API_KEY;

    await deleteAccountHandler({ req, res, log: () => {}, error: () => {} });

    if (origApiKey) process.env.APPWRITE_API_KEY = origApiKey;

    assert.strictEqual(responseStatus, 500);
    assert.strictEqual(responseBody.ok, false);
    assert.strictEqual(responseBody.code, 'server_misconfiguration');
  });
});
