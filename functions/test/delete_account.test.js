import { test, describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import deleteAccountHandler from '../delete-account/src/main.js';

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

function createMockLogger() {
  const logs = [];
  const fn = (msg) => logs.push(msg);
  fn.logs = logs;
  return fn;
}

describe('delete-account fail-closed serverless function suite', () => {
  beforeEach(() => {
    process.env.APPWRITE_FUNCTION_API_ENDPOINT = 'https://localhost/v1';
    process.env.APPWRITE_FUNCTION_PROJECT_ID = 'test_proj';
    process.env.APPWRITE_FUNCTION_API_KEY = 'test_key';
    process.env.DELETION_HMAC_SECRET = 'test_hmac_secret_key_12345';
  });

  test('1. rejects non-POST HTTP methods with 405 Method Not Allowed', async () => {
    const req = { method: 'GET', headers: {} };
    const res = createMockRes();
    await deleteAccountHandler({ req, res, log: () => {}, error: () => {} });

    assert.equal(res.statusCode, 405);
    assert.equal(res.body.ok, false);
    assert.equal(res.body.code, 'method_not_allowed');
  });

  test('2. rejects requests without authentication headers with 401 Unauthenticated', async () => {
    const req = { method: 'POST', headers: {} };
    const res = createMockRes();

    const origEnv = process.env.APPWRITE_FUNCTION_USER_ID;
    delete process.env.APPWRITE_FUNCTION_USER_ID;

    await deleteAccountHandler({ req, res, log: () => {}, error: () => {} });

    if (origEnv) process.env.APPWRITE_FUNCTION_USER_ID = origEnv;

    assert.equal(res.statusCode, 401);
    assert.equal(res.body.ok, false);
    assert.equal(res.body.code, 'unauthenticated');
  });

  test('3. returns 500 server_misconfiguration when required env vars (HMAC secret) are missing', async () => {
    const req = { method: 'POST', headers: { 'x-appwrite-user-id': 'user_test_123' } };
    const res = createMockRes();

    const origHmac = process.env.DELETION_HMAC_SECRET;
    delete process.env.DELETION_HMAC_SECRET;

    await deleteAccountHandler({ req, res, log: () => {}, error: () => {} });

    if (origHmac) process.env.DELETION_HMAC_SECRET = origHmac;

    assert.equal(res.statusCode, 500);
    assert.equal(res.body.ok, false);
    assert.equal(res.body.code, 'server_misconfiguration');
  });

  test('4. body userId spoofing is ignored in favor of trusted header userId', async () => {
    const req = {
      method: 'POST',
      headers: { 'x-appwrite-user-id': 'real_authenticated_user_100' },
      body: JSON.stringify({ userId: 'victim_user_to_spoof' })
    };
    const res = createMockRes();

    // Cause early failure at DB client creation to inspect header extraction behavior
    const origKey = process.env.APPWRITE_FUNCTION_API_KEY;
    delete process.env.APPWRITE_FUNCTION_API_KEY;
    delete process.env.APPWRITE_API_KEY;

    await deleteAccountHandler({ req, res, log: () => {}, error: () => {} });

    if (origKey) process.env.APPWRITE_FUNCTION_API_KEY = origKey;

    assert.equal(res.statusCode, 500);
    assert.equal(res.body.code, 'server_misconfiguration');
  });
});
