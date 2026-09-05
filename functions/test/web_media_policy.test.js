import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const config = JSON.parse(readFileSync(new URL('../../vercel.json', import.meta.url), 'utf8'));
const headers = config.headers.find(rule => rule.source === '/(.*)').headers;
const policy = headers.find(header => header.key.toLowerCase() === 'content-security-policy').value;
const directives = new Map(policy.split(';').map(part => part.trim().split(/\s+/)).filter(([name]) => name).map(([name, ...values]) => [name, values]));

test('remote lesson media has an explicit restricted source directive', () => {
  assert.deepEqual(directives.get('media-src'), [
    "'self'", 'blob:', 'https://*.appwrite.io', 'https://*.appwrite.run',
  ]);
});

test('allowing lesson media does not broaden executable resource policies', () => {
  assert.deepEqual(directives.get('default-src'), ["'self'"]);
  assert.deepEqual(directives.get('script-src'), [
    "'self'", "'wasm-unsafe-eval'", 'https://checkout.razorpay.com',
  ]);
  assert.deepEqual(directives.get('object-src'), ["'none'"]);
  assert.deepEqual(directives.get('base-uri'), ["'self'"]);
  assert.deepEqual(directives.get('frame-ancestors'), ["'self'"]);
});

test('media allowlist excludes unrestricted hosts and insecure transport', () => {
  const allowed = directives.get('media-src');
  assert.ok(allowed && allowed.length > 0);
  for (const broad of ['*', 'https:', 'http:', 'data:']) {
    assert.ok(!allowed.includes(broad), `Unexpected broad media source: ${broad}`);
  }
});

test('worker update and baseline security headers are preserved', () => {
  assert.equal(headers.find(h => h.key === 'X-Content-Type-Options').value, 'nosniff');
  assert.equal(headers.find(h => h.key === 'X-Frame-Options').value, 'SAMEORIGIN');
  const worker = config.headers.find(rule => rule.source === '/flutter_service_worker.js');
  assert.ok(worker.headers.some(h => h.key === 'Cache-Control' && h.value === 'no-cache'));
});
