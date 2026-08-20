import assert from 'node:assert/strict';
import test from 'node:test';
import { verifyAppwriteIdentity, deriveRateLimitIdentifier } from '../src/security.js';
import { checkRateLimit } from '../src/rate_limiter.js';

class MockAppwriteDatabases {
  constructor() {
    this.store = new Map();
  }
  async createDocument(dbId, collectionId, docId, data) {
    if (this.store.has(docId)) {
      const err = new Error('Document already exists');
      err.code = 409;
      throw err;
    }
    const doc = { $id: docId, ...data };
    this.store.set(docId, doc);
    return doc;
  }
  async deleteDocument(dbId, collectionId, docId) {
    this.store.delete(docId);
    return {};
  }
}

test('Identity Trust Boundary: Spoofed x-appwrite-user-id header is ignored without valid JWT', async () => {
  const failingAccountService = {
    get: async () => {
      throw new Error('Unauthorized');
    },
  };

  const identity = await verifyAppwriteIdentity({
    jwt: 'invalid_attacker_jwt',
    endpoint: 'https://cloud.appwrite.io/v1',
    projectId: 'olitun_app',
    accountServiceOverride: failingAccountService,
  });

  assert.equal(identity.isVerified, false);
  assert.equal(identity.userId, null);

  const identifier = deriveRateLimitIdentifier({
    verifiedUserId: identity.userId,
    clientIp: '203.0.113.50',
    salt: 'test_salt_boundary',
  });

  assert.ok(
    identifier.startsWith('net_'),
    'Unverified caller must be assigned anonymous net_ rate limit tier'
  );
  assert.ok(!identifier.includes('attacker'));
  assert.ok(!identifier.includes('203.0.113.50'));
});

test('Identity Trust Boundary: Valid Appwrite JWT grants authenticated tier with usr_ domain separation', async () => {
  const verifiedAccountService = {
    get: async () => ({
      $id: 'verified_student_999',
      email: 'student@olitun.app',
    }),
  };

  const identity = await verifyAppwriteIdentity({
    jwt: 'authentic_appwrite_session_jwt',
    endpoint: 'https://cloud.appwrite.io/v1',
    projectId: 'olitun_app',
    accountServiceOverride: verifiedAccountService,
  });

  assert.equal(identity.isVerified, true);
  assert.equal(identity.userId, 'verified_student_999');

  const identifier = deriveRateLimitIdentifier({
    verifiedUserId: identity.userId,
    clientIp: '198.51.100.12',
    salt: 'test_salt_boundary',
  });

  assert.ok(
    identifier.startsWith('usr_'),
    'Cryptographically verified caller must receive usr_ domain separated quota'
  );
  assert.ok(!identifier.includes('verified_student_999'));
});

test('Identity Trust Boundary: Authenticated callers receive higher rate limits than anonymous callers', async () => {
  const fakeDb = new MockAppwriteDatabases();
  const env = {
    RATE_LIMIT_ANON_PER_MINUTE: '2',
    RATE_LIMIT_ANON_PER_HOUR: '5',
    RATE_LIMIT_AUTH_PER_MINUTE: '10',
    RATE_LIMIT_AUTH_PER_HOUR: '30',
  };
  const now = 100000;

  const anonIdent = 'net_anon_user_1';
  const authIdent = 'usr_auth_user_1';

  // Anonymous caller exhausts quota after 2 requests
  await checkRateLimit({ databases: fakeDb, identifier: anonIdent, isAuth: false, now, env });
  await checkRateLimit({ databases: fakeDb, identifier: anonIdent, isAuth: false, now: now + 10, env });
  const anon3rd = await checkRateLimit({ databases: fakeDb, identifier: anonIdent, isAuth: false, now: now + 20, env });
  assert.equal(anon3rd.allowed, false);
  assert.equal(anon3rd.reason, 'burst_limit_exceeded');

  // Authenticated caller makes 5 requests successfully
  for (let i = 1; i <= 5; i++) {
    const res = await checkRateLimit({
      databases: fakeDb,
      identifier: authIdent,
      isAuth: true,
      now: now + i * 10,
      env,
    });
    assert.equal(res.allowed, true, `Auth caller request ${i} must succeed`);
  }
});
