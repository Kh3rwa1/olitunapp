import { test, describe } from 'node:test';
import assert from 'node:assert';
import deleteAccountHandler from '../delete-account/src/main.js';

describe('Account Deletion Function Tests', () => {
  test('rejects non-POST HTTP methods with 405', async () => {
    const req = { method: 'GET', headers: {} };
    let responseCode;
    let responseData;

    const res = {
      json: (data, code = 200) => {
        responseData = data;
        responseCode = code;
        return data;
      },
    };

    await deleteAccountHandler({ req, res, log: () => {}, error: () => {} });

    assert.strictEqual(responseCode, 405);
    assert.strictEqual(responseData.ok, false);
    assert.strictEqual(responseData.code, 'method_not_allowed');
  });

  test('rejects unauthenticated requests lacking x-appwrite-user-id header', async () => {
    const req = { method: 'POST', headers: {} };
    let responseCode;
    let responseData;

    const res = {
      json: (data, code = 200) => {
        responseData = data;
        responseCode = code;
        return data;
      },
    };

    await deleteAccountHandler({ req, res, log: () => {}, error: () => {} });

    assert.strictEqual(responseCode, 401);
    assert.strictEqual(responseData.ok, false);
    assert.strictEqual(responseData.code, 'unauthenticated');
  });

  test('returns 500 when mandatory environment variables are missing', async () => {
    const req = {
      method: 'POST',
      headers: { 'x-appwrite-user-id': 'user_test_999' },
    };
    let responseCode;
    let responseData;

    const res = {
      json: (data, code = 200) => {
        responseData = data;
        responseCode = code;
        return data;
      },
    };

    // Backup env vars
    const oldKey = process.env.APPWRITE_API_KEY;
    delete process.env.APPWRITE_API_KEY;

    await deleteAccountHandler({ req, res, log: () => {}, error: () => {} });

    // Restore env vars
    if (oldKey) process.env.APPWRITE_API_KEY = oldKey;

    assert.strictEqual(responseCode, 500);
    assert.strictEqual(responseData.ok, false);
    assert.strictEqual(responseData.code, 'server_misconfiguration');
  });
});
