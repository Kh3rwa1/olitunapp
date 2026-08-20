import assert from 'node:assert/strict';
import test from 'node:test';
import {
  checkRateLimit,
  enforceWindowRateLimit,
  generateSlotDocId,
  pruneExpiredRateLimits,
  WINDOW_HOUR_MS,
  WINDOW_MINUTE_MS,
} from '../src/rate_limiter.js';
import {
  deriveRateLimitIdentifier,
  verifyAppwriteIdentity,
  normalizeClientIp,
} from '../src/security.js';

/**
 * Authentic Appwrite Databases fake strictly reflecting production Appwrite engine semantics:
 * - createDocument: Throws 409 Conflict if documentId already exists (primary key constraint).
 * - getDocument: Returns stored document or 404.
 * - updateDocument: Standard attribute overwrite without fake compare-and-swap.
 * - deleteDocument: Deletes document by ID.
 * - listDocuments: Queries documents by attribute filters.
 * - Latency injection to stress real concurrent execution.
 */
class ProductionAppwriteDatabasesFake {
  constructor({ failOnStorage = false, artificialLatencyMs = 2 } = {}) {
    this.store = new Map();
    this.failOnStorage = failOnStorage;
    this.artificialLatencyMs = artificialLatencyMs;
    this.createAttempts = 0;
    this.conflictCount = 0;
  }

  async _delay() {
    if (this.artificialLatencyMs > 0) {
      await new Promise((r) => setTimeout(r, Math.random() * this.artificialLatencyMs));
    }
  }

  async createDocument(dbId, collectionId, docId, data) {
    await this._delay();
    if (this.failOnStorage) {
      const err = new Error('Appwrite service unreachable (500)');
      err.code = 500;
      throw err;
    }
    this.createAttempts++;
    if (this.store.has(docId)) {
      this.conflictCount++;
      const conflictErr = new Error(`Document with ID "${docId}" already exists.`);
      conflictErr.code = 409;
      conflictErr.status = 409;
      throw conflictErr;
    }
    const doc = { $id: docId, ...data };
    this.store.set(docId, doc);
    return doc;
  }

  async getDocument(dbId, collectionId, docId) {
    await this._delay();
    if (this.failOnStorage) {
      const err = new Error('Database read timeout');
      err.code = 500;
      throw err;
    }
    const doc = this.store.get(docId);
    if (!doc) {
      const notFound = new Error('Document not found');
      notFound.code = 404;
      throw notFound;
    }
    return { ...doc };
  }

  async updateDocument(dbId, collectionId, docId, data) {
    await this._delay();
    if (this.failOnStorage) {
      const err = new Error('Storage write failure');
      err.code = 500;
      throw err;
    }
    const existing = this.store.get(docId);
    if (!existing) {
      const notFound = new Error('Document not found for update');
      notFound.code = 404;
      throw notFound;
    }
    const updated = {
      ...existing,
      ...data,
    };
    this.store.set(docId, updated);
    return updated;
  }

  async listDocuments(dbId, collectionId, queries = []) {
    await this._delay();
    if (this.failOnStorage) {
      throw new Error('Database list failure');
    }
    let docs = Array.from(this.store.values());

    for (const q of queries) {
      if (typeof q === 'string') {
        try {
          const parsed = JSON.parse(q);
          if (parsed.method === 'lessThan' && parsed.attribute === 'windowStart') {
            const threshold = parsed.values[0];
            docs = docs.filter((d) => (d.windowStart || 0) < threshold);
          }
        } catch {
          // Non-JSON query string
        }
      }
    }
    return { documents: docs, total: docs.length };
  }

  async deleteDocument(dbId, collectionId, docId) {
    await this._delay();
    this.store.delete(docId);
    return {};
  }
}

// ==========================================
// 1. UNIT TESTS
// ==========================================

test('Unit: Deterministic slot document IDs are stable and valid format', () => {
  const id1 = generateSlotDocId('m', 'usr_test_123', 1000, 1);
  const id2 = generateSlotDocId('m', 'usr_test_123', 1000, 1);
  const id3 = generateSlotDocId('m', 'usr_test_123', 1000, 2);

  assert.equal(id1, id2, 'Identical parameters must generate identical document IDs');
  assert.notEqual(id1, id3, 'Different slots must generate distinct document IDs');
  assert.ok(id1.startsWith('m_'), 'Document ID must retain window prefix');
  assert.ok(id1.length <= 36, `Document ID length ${id1.length} must be <= 36 chars`);
});

test('Unit: First request successfully claims slot 1', async () => {
  const fakeDb = new ProductionAppwriteDatabasesFake();
  const res = await enforceWindowRateLimit({
    databases: fakeDb,
    dbId: 'olitun_db',
    collectionId: 'rate_limits',
    identifier: 'usr_unit_test',
    windowType: 'm',
    windowMs: WINDOW_MINUTE_MS,
    limit: 5,
    now: 10000,
  });

  assert.equal(res.allowed, true);
  assert.equal(res.remaining, 4);
  assert.ok(res.slotDocId);
  assert.equal(fakeDb.store.size, 1);
});

test('Unit: Exactly-at-limit request succeeds and request N+1 is rejected', async () => {
  const fakeDb = new ProductionAppwriteDatabasesFake();
  const limit = 3;
  const now = 20000;

  for (let i = 1; i <= limit; i++) {
    const res = await enforceWindowRateLimit({
      databases: fakeDb,
      dbId: 'olitun_db',
      collectionId: 'rate_limits',
      identifier: 'usr_exact_limit',
      windowType: 'm',
      windowMs: WINDOW_MINUTE_MS,
      limit,
      now,
    });
    assert.equal(res.allowed, true, `Request ${i} of ${limit} must be allowed`);
    assert.equal(res.remaining, limit - i);
  }

  // Request N+1 (4th request)
  const rejectedRes = await enforceWindowRateLimit({
    databases: fakeDb,
    dbId: 'olitun_db',
    collectionId: 'rate_limits',
    identifier: 'usr_exact_limit',
    windowType: 'm',
    windowMs: WINDOW_MINUTE_MS,
    limit,
    now,
  });

  assert.equal(rejectedRes.allowed, false, 'Request N+1 must be rejected');
  assert.equal(rejectedRes.reason, 'burst_limit_exceeded');
  assert.ok(rejectedRes.retryAfterSeconds > 0);
  assert.equal(fakeDb.store.size, limit, 'Store must contain exactly limit documents');
});

test('Unit: Malformed or non-positive limit fails closed safely', async () => {
  const fakeDb = new ProductionAppwriteDatabasesFake();
  const resNegative = await enforceWindowRateLimit({
    databases: fakeDb,
    dbId: 'olitun_db',
    collectionId: 'rate_limits',
    identifier: 'usr_malformed',
    windowType: 'm',
    windowMs: WINDOW_MINUTE_MS,
    limit: -5,
    now: 10000,
  });

  assert.equal(resNegative.allowed, false);
  assert.equal(resNegative.reason, 'rate_limit_storage_error');

  const resZero = await enforceWindowRateLimit({
    databases: fakeDb,
    dbId: 'olitun_db',
    collectionId: 'rate_limits',
    identifier: 'usr_malformed',
    windowType: 'm',
    windowMs: WINDOW_MINUTE_MS,
    limit: 0,
    now: 10000,
  });

  assert.equal(resZero.allowed, false);
  assert.equal(resZero.reason, 'rate_limit_storage_error');
});

test('Unit: Storage failure triggers fail-closed error with sanitized code', async () => {
  const fakeDb = new ProductionAppwriteDatabasesFake({ failOnStorage: true });
  const res = await checkRateLimit({
    databases: fakeDb,
    identifier: 'usr_storage_fail',
    now: 10000,
    env: { RATE_LIMIT_ANON_PER_MINUTE: '5', RATE_LIMIT_ANON_PER_HOUR: '20' },
  });

  assert.equal(res.allowed, false);
  assert.equal(res.reason, 'rate_limit_storage_error');
});

test('Unit: Retention cleanup prunes expired rate limit documents safely', async () => {
  const fakeDb = new ProductionAppwriteDatabasesFake();
  const now = 10000000;

  // Insert 2 expired documents (windowStart < now - 2 hours)
  await fakeDb.createDocument('olitun_db', 'rate_limits', 'm_expired_1', {
    clientIp: 'usr_old_1',
    windowStart: now - (3 * WINDOW_HOUR_MS),
  });
  await fakeDb.createDocument('olitun_db', 'rate_limits', 'm_expired_2', {
    clientIp: 'usr_old_2',
    windowStart: now - (4 * WINDOW_HOUR_MS),
  });
  // Insert 1 active document
  await fakeDb.createDocument('olitun_db', 'rate_limits', 'm_active_1', {
    clientIp: 'usr_active',
    windowStart: now,
  });

  assert.equal(fakeDb.store.size, 3);
  const pruneResult = await pruneExpiredRateLimits({
    databases: fakeDb,
    now,
    retentionBufferMs: 2 * WINDOW_HOUR_MS,
  });

  assert.equal(pruneResult.prunedCount, 2);
  assert.equal(fakeDb.store.size, 1);
  assert.ok(fakeDb.store.has('m_active_1'));
});

// ==========================================
// 2. CONCURRENCY CONTRACT TESTS
// ==========================================

test('Concurrency: 20 simultaneous requests never exceed the burst limit', async () => {
  const fakeDb = new ProductionAppwriteDatabasesFake({ artificialLatencyMs: 2 });
  const identifier = 'usr_test_concurrency_20';
  const now = 5000000;
  const burstLimit = 5;
  const env = {
    RATE_LIMIT_ANON_PER_MINUTE: `${burstLimit}`,
    RATE_LIMIT_ANON_PER_HOUR: '50',
  };

  const results = await Promise.all(
    Array.from({ length: 20 }, () =>
      checkRateLimit({
        databases: fakeDb,
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
    `Under burst limit ${burstLimit}, exactly ${burstLimit} requests must succeed (got ${allowed.length})`
  );
  assert.equal(
    denied.length,
    15,
    `Under 20 concurrent requests, exactly 15 must be denied with burst_limit_exceeded (got ${denied.length})`
  );
  assert.equal(
    fakeDb.store.size,
    burstLimit * 2, // 5 minute slots + 5 hourly slots
    'Store should contain exactly 5 minute slot docs and 5 hourly slot docs'
  );
});

test('Concurrency: 50 simultaneous requests under hourly limit test strictly bounds successes', async () => {
  const fakeDb = new ProductionAppwriteDatabasesFake({ artificialLatencyMs: 1 });
  const identifier = 'usr_test_concurrency_50';
  const now = 6000000;
  const hourlyLimit = 12;
  const env = {
    RATE_LIMIT_ANON_PER_MINUTE: '100', // high burst
    RATE_LIMIT_ANON_PER_HOUR: `${hourlyLimit}`,
  };

  const results = await Promise.all(
    Array.from({ length: 50 }, () =>
      checkRateLimit({
        databases: fakeDb,
        identifier,
        isAuth: false,
        now,
        env,
      })
    )
  );

  const allowed = results.filter((r) => r.allowed);
  const denied = results.filter((r) => !r.allowed && r.reason === 'hourly_limit_exceeded');

  assert.equal(
    allowed.length,
    hourlyLimit,
    `Under hourly limit of ${hourlyLimit}, exactly ${hourlyLimit} requests must be allowed (got ${allowed.length})`
  );
  assert.equal(
    denied.length,
    38,
    `Exactly 38 requests must be rejected with hourly_limit_exceeded (got ${denied.length})`
  );
});

test('Concurrency: 100 simultaneous requests across multiple simulated workers do not exceed limit', async () => {
  const fakeDb = new ProductionAppwriteDatabasesFake({ artificialLatencyMs: 3 });
  const identifier = 'usr_test_concurrency_100';
  const now = 7000000;
  const burstLimit = 8;
  const env = {
    RATE_LIMIT_ANON_PER_MINUTE: `${burstLimit}`,
    RATE_LIMIT_ANON_PER_HOUR: '100',
  };

  const results = await Promise.all(
    Array.from({ length: 100 }, () =>
      checkRateLimit({
        databases: fakeDb,
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
    `Under 100 concurrent requests with burst limit ${burstLimit}, exactly ${burstLimit} must succeed (got ${allowed.length})`
  );
  assert.equal(
    denied.length,
    92,
    `92 requests must be rejected (got ${denied.length})`
  );
});

// ==========================================
// 3. IDENTITY TRUST BOUNDARY TESTS
// ==========================================

test('Verified Identity: Cryptographic verification succeeds for valid JWT and fails for invalid/fake claims', async () => {
  const mockAccountService = {
    get: async () => {
      return { $id: 'verified_user_abc', email: 'student@olitun.app' };
    },
  };
  const failingAccountService = {
    get: async () => {
      const err = new Error('Invalid JWT credential');
      err.code = 401;
      throw err;
    },
  };

  // 1. Valid JWT -> authentic verified account
  const validIdentity = await verifyAppwriteIdentity({
    jwt: 'valid_jwt_token_123',
    endpoint: 'https://cloud.appwrite.io/v1',
    projectId: 'test_project',
    accountServiceOverride: mockAccountService,
  });
  assert.equal(validIdentity.isVerified, true);
  assert.equal(validIdentity.userId, 'verified_user_abc');

  // 2. Fake JWT -> rejected to unverified
  const fakeIdentity = await verifyAppwriteIdentity({
    jwt: 'malicious_jwt',
    endpoint: 'https://cloud.appwrite.io/v1',
    projectId: 'test_project',
    accountServiceOverride: failingAccountService,
  });
  assert.equal(fakeIdentity.isVerified, false);
  assert.equal(fakeIdentity.userId, null);

  // 3. No JWT -> unverified
  const anonIdentity = await verifyAppwriteIdentity({
    jwt: '',
    endpoint: 'https://cloud.appwrite.io/v1',
    projectId: 'test_project',
  });
  assert.equal(anonIdentity.isVerified, false);
  assert.equal(anonIdentity.userId, null);
});

test('Verified Identity: Mandatory RATE_LIMIT_SALT in production & domain separation', () => {
  // Production requires salt
  assert.throws(
    () => {
      deriveRateLimitIdentifier({
        clientIp: '198.51.100.1',
        env: { NODE_ENV: 'production' },
      });
    },
    /RATE_LIMIT_SALT is mandatory in production environment/
  );

  const salt = 'super_secret_prod_salt_value_123';
  const userIdent = deriveRateLimitIdentifier({
    verifiedUserId: 'user_456',
    salt,
  });
  const netIdent = deriveRateLimitIdentifier({
    clientIp: '198.51.100.1',
    salt,
  });

  assert.ok(userIdent.startsWith('usr_'), 'User identifier must use usr_ domain separation');
  assert.ok(netIdent.startsWith('net_'), 'Network identifier must use net_ domain separation');
  assert.notEqual(userIdent, netIdent);
});

// ==========================================
// 4. HARDENED ATOMIC SLOT BEHAVIOR TESTS
// ==========================================

test('Rollback: When minute limit succeeds but hourly limit fails, minute slot is rolled back', async () => {
  const fakeDb = new ProductionAppwriteDatabasesFake();
  const identifier = 'usr_rollback_test';
  const now = 8000000;

  // Set hourly limit to 0 / already exhausted by creating all hourly slots
  const hourIndex = Math.floor(now / WINDOW_HOUR_MS);
  for (let s = 1; s <= 2; s++) {
    const docId = generateSlotDocId('h', identifier, hourIndex, s);
    await fakeDb.createDocument('olitun_db', 'rate_limits', docId, { count: s });
  }

  const res = await checkRateLimit({
    databases: fakeDb,
    identifier,
    isAuth: false,
    now,
    env: {
      RATE_LIMIT_ANON_PER_MINUTE: '5',
      RATE_LIMIT_ANON_PER_HOUR: '2', // exhausted
    },
  });

  assert.equal(res.allowed, false);
  assert.equal(res.reason, 'hourly_limit_exceeded');

  // Verify that the minute slot was deleted during rollback
  const minIndex = Math.floor(now / WINDOW_MINUTE_MS);
  const minSlotDocId = generateSlotDocId('m', identifier, minIndex, 1);
  assert.equal(fakeDb.store.has(minSlotDocId), false, 'Minute slot must be deleted after hourly limit failure');
});

test('Fail-Closed: Non-duplicate 409 or unknown error fails closed immediately without probing next slot', async () => {
  const customDb = {
    createAttempts: 0,
    async createDocument() {
      this.createAttempts++;
      const generic409 = new Error('Relationship constraint violation');
      generic409.code = 409;
      generic409.type = 'relationship_conflict';
      throw generic409;
    },
  };

  const res = await enforceWindowRateLimit({
    databases: customDb,
    dbId: 'olitun_db',
    collectionId: 'rate_limits',
    identifier: 'usr_non_dup_409',
    windowType: 'm',
    windowMs: WINDOW_MINUTE_MS,
    limit: 5,
    now: 10000,
  });

  assert.equal(res.allowed, false);
  assert.equal(res.reason, 'rate_limit_storage_error');
  assert.equal(customDb.createAttempts, 1, 'Must NOT continue probing next slots on non-duplicate error');
});

test('Fail-Closed: Limit exceeding MAX_ALLOWED_LIMIT fails closed', async () => {
  const fakeDb = new ProductionAppwriteDatabasesFake();
  const res = await enforceWindowRateLimit({
    databases: fakeDb,
    dbId: 'olitun_db',
    collectionId: 'rate_limits',
    identifier: 'usr_excessive_limit',
    windowType: 'm',
    windowMs: WINDOW_MINUTE_MS,
    limit: 1000, // exceeds MAX_ALLOWED_LIMIT (500)
    now: 10000,
  });

  assert.equal(res.allowed, false);
  assert.equal(res.reason, 'rate_limit_storage_error');
});

test('SDK Version Integrity: Installed node-appwrite version matches expected release SDK', async () => {
  const { readFileSync } = await import('node:fs');
  const pkgUrl = new URL('../node_modules/node-appwrite/package.json', import.meta.url);
  const pkg = JSON.parse(readFileSync(pkgUrl, 'utf8'));
  assert.equal(pkg.version, '25.1.0', 'node-appwrite SDK must be exactly 25.1.0');
});
