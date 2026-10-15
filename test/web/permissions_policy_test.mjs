import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { readPagesHeaders } from './pages_headers.mjs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, '../..');

test('Permissions-Policy configuration test', async (t) => {
  const catchAllRule = readPagesHeaders()['/*'];
  assert.ok(catchAllRule, 'web/_headers must define a /* rule');

  const policyValue = catchAllRule['Permissions-Policy'];
  assert.ok(policyValue, 'Permissions-Policy header must be configured');

  await t.test('camera is allowed for self and not globally disabled', () => {
    assert.ok(
      policyValue.includes('camera=(self)'),
      `camera must be configured as (self) for AI Studio document scanning, found: ${policyValue}`
    );
    assert.ok(
      !policyValue.includes('camera=()'),
      'camera must not be globally disabled camera=() while AI Studio is enabled'
    );
    assert.ok(
      !policyValue.includes('camera=*'),
      'camera must not allow unrestricted cross-origin access camera=*'
    );
  });

  await t.test('microphone is allowed for self and not globally disabled', () => {
    assert.ok(
      policyValue.includes('microphone=(self)'),
      `microphone must be configured as (self) for in-app voice recording, found: ${policyValue}`
    );
    assert.ok(
      !policyValue.includes('microphone=()'),
      'microphone must not be globally disabled microphone=() while AI Studio is enabled'
    );
    assert.ok(
      !policyValue.includes('microphone=*'),
      'microphone must not allow unrestricted cross-origin access microphone=*'
    );
  });

  await t.test('geolocation remains disabled', () => {
    assert.ok(
      policyValue.includes('geolocation=()'),
      `geolocation must remain disabled geolocation=(), found: ${policyValue}`
    );
  });

  await t.test('SECURITY.md describes current Permissions-Policy and CSP', () => {
    const securityMdPath = path.join(rootDir, 'SECURITY.md');
    const securityMd = fs.readFileSync(securityMdPath, 'utf8');
    assert.ok(
      securityMd.includes('camera=(self), microphone=(self), geolocation=()'),
      'SECURITY.md must accurately document the exact Permissions-Policy'
    );
  });
});
