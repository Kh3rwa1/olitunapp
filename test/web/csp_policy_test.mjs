import { test } from 'node:test';
import assert from 'node:assert/strict';
import { cspDirectives, readPagesHeaders } from './pages_headers.mjs';

const rules = readPagesHeaders();
const headers = rules['/*'];
const directives = cspDirectives(headers['Content-Security-Policy']);

const api = ['https://olitun.in', 'https://olitun-api.dulalkisku0.workers.dev'];
const appwrite = 'https://sgp.cloud.appwrite.io';

test('the Worker API and Appwrite sign-in are the only backend origins', () => {
  assert.deepEqual(directives.get('connect-src'), [
    "'self'", ...api, appwrite,
    'https://*.sentry.io', 'https://*.ingest.sentry.io', 'https://*.ingest.us.sentry.io',
    'https://api.razorpay.com',
  ]);
  assert.deepEqual(directives.get('media-src'), ["'self'", 'blob:', ...api, appwrite]);
  assert.deepEqual(directives.get('img-src'), [
    "'self'", 'data:', 'blob:', ...api, appwrite, 'https://*.razorpay.com',
  ]);
});

test('allowing lesson media does not broaden executable resource policies', () => {
  assert.deepEqual(directives.get('default-src'), ["'self'"]);
  assert.deepEqual(directives.get('script-src'), [
    "'self'", "'wasm-unsafe-eval'", 'https://checkout.razorpay.com',
  ]);
  assert.deepEqual(directives.get('worker-src'), ["'self'"]);
  assert.deepEqual(directives.get('object-src'), ["'none'"]);
  assert.deepEqual(directives.get('base-uri'), ["'self'"]);
  assert.deepEqual(directives.get('frame-ancestors'), ["'self'"]);
  assert.deepEqual(directives.get('frame-src'), [
    "'self'", 'https://api.razorpay.com', 'https://checkout.razorpay.com',
  ]);
});

test('no source list allows unrestricted hosts or insecure transport', () => {
  for (const [name, values] of directives) {
    for (const broad of ['*', 'https:', 'http:', "'unsafe-eval'"]) {
      assert.ok(!values.includes(broad), `${name} must not allow ${broad}`);
    }
    for (const value of values) {
      assert.ok(!value.startsWith('http://'), `${name} must not allow ${value}`);
    }
  }
  assert.ok(!directives.get('media-src').includes('data:'));
});

test('baseline security and service-worker headers are preserved', () => {
  assert.equal(headers['X-Content-Type-Options'], 'nosniff');
  assert.equal(headers['X-Frame-Options'], 'SAMEORIGIN');
  assert.match(headers['Strict-Transport-Security'], /^max-age=63072000; includeSubDomains/);
  assert.equal(headers['Referrer-Policy'], 'strict-origin-when-cross-origin');
  assert.equal(rules['/sw.js']['Service-Worker-Allowed'], '/');
  assert.match(rules['/sw.js']['Cache-Control'], /no-cache/);
  assert.equal(rules['/flutter_service_worker.js']['Cache-Control'], 'no-cache');
});

test('a header is set by one rule only, so Cloudflare never joins two values', () => {
  for (const [path, rule] of Object.entries(rules)) {
    if (path === '/*') continue;
    for (const name of Object.keys(rule)) {
      assert.ok(!Object.hasOwn(headers, name), `${name} is set on both /* and ${path}`);
    }
  }
});
