import assert from 'node:assert/strict';
import test from 'node:test';

import {
  createCacheKey,
  MAX_TRANSLATION_CHARS,
  normalizeLanguage,
} from '../src/security.js';

test('cache keys are stable SHA-256 hashes, not raw text', () => {
  const input = { from: 'auto', to: 'sat', text: 'hello world' };

  const first = createCacheKey(input);
  const second = createCacheKey(input);

  assert.equal(first, second);
  assert.match(first, /^[a-f0-9]{64}$/);
  assert.doesNotMatch(first, /hello|world/);
});

test('language tags are normalized or replaced with safe defaults', () => {
  assert.equal(normalizeLanguage('ZH-CN', 'sat'), 'zh-cn');
  assert.equal(normalizeLanguage('', 'auto'), 'auto');
  assert.equal(normalizeLanguage('../secret', 'sat'), 'sat');
});

test('translation input limit defaults to a bounded value', () => {
  assert.equal(MAX_TRANSLATION_CHARS, 5000);
});
