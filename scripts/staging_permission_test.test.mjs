import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import { parseAndValidateStagingUrl } from './staging_permission_test.mjs';

describe('Strict Staging URL Parsing & Safety Guard Suite', () => {
  test('1. Accepts valid HTTPS staging endpoint', () => {
    const res = parseAndValidateStagingUrl('https://staging.olitun.internal/v1');
    assert.equal(res.hostname, 'staging.olitun.internal');
    assert.equal(res.protocol, 'https:');
    assert.equal(res.isProductionCloud, false);
  });

  test('2. Rejects HTTP insecure endpoint for non-local host', () => {
    assert.throws(
      () => parseAndValidateStagingUrl('http://staging.olitun.internal/v1'),
      /Insecure protocol http: rejected/
    );
  });

  test('3. Allows HTTP for localhost when explicitly enabled', () => {
    const res = parseAndValidateStagingUrl('http://localhost:8080/v1', { allowLocalHttp: true });
    assert.equal(res.hostname, 'localhost');
    assert.equal(res.isLocalHost, true);
  });

  test('4. Rejects Appwrite production cloud host without override flag', () => {
    assert.throws(
      () => parseAndValidateStagingUrl('https://cloud.appwrite.io/v1'),
      /SAFETY GUARD: Production Appwrite host detected/
    );
  });

  test('5. Allows Appwrite production cloud host when explicit override is provided', () => {
    const res = parseAndValidateStagingUrl('https://cloud.appwrite.io/v1', { allowProductionOverride: true });
    assert.equal(res.hostname, 'cloud.appwrite.io');
    assert.equal(res.isProductionCloud, true);
  });

  test('6. Prevents user credential embedded URLs', () => {
    assert.throws(
      () => parseAndValidateStagingUrl('https://user:password@cloud.appwrite.io/v1'),
      /URLs containing credentials/
    );
  });

  test('7. Handles suffix bypass attempt safely without mistaking as cloud host', () => {
    const res = parseAndValidateStagingUrl('https://cloud.appwrite.io.attacker.example/v1');
    assert.equal(res.hostname, 'cloud.appwrite.io.attacker.example');
    assert.equal(res.isProductionCloud, false);
  });

  test('8. Rejects malformed non-URL strings', () => {
    assert.throws(
      () => parseAndValidateStagingUrl('invalid_endpoint_string'),
      /Invalid URL format/
    );
  });
});
