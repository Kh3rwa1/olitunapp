import assert from 'node:assert/strict';
import test from 'node:test';
import { Client, Databases } from 'node-appwrite';
import { checkRateLimit, pruneExpiredRateLimits } from '../src/rate_limiter.js';

const STAGING_ENDPOINT = process.env.STAGING_APPWRITE_ENDPOINT;
const STAGING_PROJECT_ID = process.env.STAGING_APPWRITE_PROJECT_ID;
const STAGING_API_KEY = process.env.STAGING_APPWRITE_API_KEY;
const IS_STAGING_MANDATORY = process.env.CI_STAGING_MANDATORY === 'true';

test('Staging Integration: Real Appwrite parallel concurrency execution', async (t) => {
  if (!STAGING_ENDPOINT || !STAGING_PROJECT_ID || !STAGING_API_KEY) {
    if (IS_STAGING_MANDATORY) {
      assert.fail('FATAL: Required staging credentials missing for scheduled staging run.');
    }
    t.skip('Skipping live Appwrite staging test: STAGING_APPWRITE_* credentials not set.');
    return;
  }

  const client = new Client()
    .setEndpoint(STAGING_ENDPOINT)
    .setProject(STAGING_PROJECT_ID)
    .setKey(STAGING_API_KEY);

  const databases = new Databases(client);
  const testRunId = `stg_test_${Date.now()}`;
  const identifier = `net_stg_${testRunId}`;
  const now = Date.now();
  const burstLimit = 4;
  const env = {
    RATE_LIMIT_ANON_PER_MINUTE: `${burstLimit}`,
    RATE_LIMIT_ANON_PER_HOUR: '20',
  };

  try {
    // Fire 10 simultaneous requests to real Appwrite cluster
    const results = await Promise.all(
      Array.from({ length: 10 }, () =>
        checkRateLimit({
          databases,
          identifier,
          isAuth: false,
          now,
          env,
        })
      )
    );

    const allowed = results.filter((r) => r.allowed);
    const denied = results.filter((r) => !r.allowed && r.reason === 'burst_limit_exceeded');

    assert.equal(
      allowed.length,
      burstLimit,
      `Real Appwrite must strictly allow exactly ${burstLimit} requests under concurrent burst`
    );
    assert.equal(denied.length, 6, 'Real Appwrite must reject 6 excess requests with burst_limit_exceeded');
  } finally {
    // Cleanup test records
    await pruneExpiredRateLimits({
      databases,
      now: now + 3 * 3600 * 1000,
      retentionBufferMs: 0,
    });
  }
});
