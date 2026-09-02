import assert from 'node:assert/strict';
import test from 'node:test';
import {
  createCacheKey,
  MAX_TRANSLATION_CHARS,
  normalizeLanguage,
  isLanguageSupported,
  deriveRateLimitIdentifier,
  SUPPORTED_LANGUAGES,
} from '../src/security.js';
import { checkRateLimit } from '../../_shared/rate_limiter.js';
import {
  BaseTranslationProvider,
  VitaletsTranslationProvider,
  GoogleCloudTranslationProvider,
  getTranslationProvider,
} from '../src/providers/translation_provider.js';

test('Security: Rate-limit identifier derivation preserves privacy and never exposes raw IP', () => {
  const ip1 = '192.168.1.50';
  const ip2 = '203.0.113.195';
  const salt = 'test-secret-salt';

  const id1 = deriveRateLimitIdentifier({ clientIp: ip1, salt });
  const id2 = deriveRateLimitIdentifier({ clientIp: ip2, salt });
  const id1Repeat = deriveRateLimitIdentifier({ clientIp: ip1, salt });

  assert.equal(id1, id1Repeat);
  assert.notEqual(id1, id2);
  assert.ok(id1.startsWith('net_'));
  assert.ok(!id1.includes(ip1));
  assert.ok(!id2.includes(ip2));

  // Authenticated verified user ID takes precedence
  const authId = deriveRateLimitIdentifier({ verifiedUserId: 'user_12345', clientIp: ip1, salt });
  assert.ok(authId.startsWith('usr_'));
  assert.ok(!authId.includes('192.168'));
});

test('Security: Supported languages validation and normalization', () => {
  assert.equal(isLanguageSupported('sat'), true);
  assert.equal(isLanguageSupported('en'), true);
  assert.equal(isLanguageSupported('hi'), true);
  assert.equal(isLanguageSupported('bn'), true);
  assert.equal(isLanguageSupported('or'), true);
  assert.equal(isLanguageSupported('auto'), true);
  assert.equal(isLanguageSupported('unsupported_lang_xyz'), false);
  assert.equal(isLanguageSupported(''), false);
  assert.equal(isLanguageSupported(null), false);

  assert.equal(normalizeLanguage('SAT', 'en'), 'sat');
  assert.equal(normalizeLanguage('invalid', 'en'), 'en');
});

test('Security: Cache keys are immutable SHA-256 hashes without text leaks', () => {
  const key1 = createCacheKey({ from: 'en', to: 'sat', text: 'Hello, world!' });
  const key2 = createCacheKey({ from: 'EN', to: 'SAT', text: '  Hello, world!  ' });
  const key3 = createCacheKey({ from: 'en', to: 'sat', text: 'Different text' });

  assert.equal(key1, key2);
  assert.notEqual(key1, key3);
  assert.match(key1, /^[a-f0-9]{64}$/);
  assert.ok(!key1.includes('Hello'));
});

test('RateLimiter: Burst and sustained limits enforce bounds correctly', async () => {
  const store = new Map();
  const mockDatabases = {
    async createDocument(dbId, collectionId, id, data) {
      if (store.has(id)) {
        const err = new Error('Document already exists');
        err.code = 409;
        throw err;
      }
      const doc = { $id: id, ...data };
      store.set(id, doc);
      return doc;
    },
    async getDocument(dbId, collectionId, id) {
      const doc = store.get(id);
      if (!doc) {
        const err = new Error('Document not found');
        err.code = 404;
        throw err;
      }
      return { ...doc };
    },
    async updateDocument(dbId, collectionId, id, data) {
      const existing = store.get(id) || { $id: id };
      const updated = { ...existing, ...data };
      store.set(id, updated);
      return updated;
    },
  };

  const identifier = 'net_abc123';
  const env = {
    RATE_LIMIT_ANON_PER_HOUR: '3',
    RATE_LIMIT_ANON_PER_MINUTE: '2',
  };

  const now = 1000000;

  // 1st request -> allowed
  const r1 = await checkRateLimit({
    databases: mockDatabases,
    identifier,
    isAuth: false,
    now,
    env,
  });
  assert.equal(r1.allowed, true);

  // 2nd request -> allowed
  const r2 = await checkRateLimit({
    databases: mockDatabases,
    identifier,
    isAuth: false,
    now: now + 1000,
    env,
  });
  assert.equal(r2.allowed, true);

  // 3rd request in same minute -> blocked by burst limit
  const r3 = await checkRateLimit({
    databases: mockDatabases,
    identifier,
    isAuth: false,
    now: now + 2000,
    env,
  });
  assert.equal(r3.allowed, false);
  assert.equal(r3.reason, 'burst_limit_exceeded');

  // After 1 minute (minute burst expires, but hourly remains active)
  const r4 = await checkRateLimit({
    databases: mockDatabases,
    identifier,
    isAuth: false,
    now: now + 65000,
    env,
  });
  assert.equal(r4.allowed, true);

  // 4th request in hour -> blocked by sustained hourly limit (limit was 3)
  const r5 = await checkRateLimit({
    databases: mockDatabases,
    identifier,
    isAuth: false,
    now: now + 70000,
    env,
  });
  assert.equal(r5.allowed, false);
  assert.equal(r5.reason, 'hourly_limit_exceeded');
});

test('RateLimiter: Fail-closed on storage error', async () => {
  const brokenDatabases = {
    async createDocument() {
      throw new Error('Connection refused to database cluster');
    },
  };

  const res = await checkRateLimit({
    databases: brokenDatabases,
    identifier: 'net_fail_closed',
    isAuth: false,
  });

  assert.equal(res.allowed, false);
  assert.equal(res.reason, 'rate_limit_storage_error');
});

test('Providers: Provider factory correctly instantiates configured provider', () => {
  const defaultProvider = getTranslationProvider();
  assert.ok(defaultProvider instanceof BaseTranslationProvider);

  const vitaletsProvider = new VitaletsTranslationProvider();
  assert.equal(vitaletsProvider.name, 'vitalets');

  const gcloudProvider = new GoogleCloudTranslationProvider({ apiKey: 'fake_key' });
  assert.equal(gcloudProvider.name, 'google_cloud');
});
