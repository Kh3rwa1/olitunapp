import assert from 'node:assert/strict';
import test from 'node:test';
import {
  checkRateLimit,
  enforceWindowRateLimit,
  generateWindowDocId,
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
 * High-fidelity concurrent storage fake simulating Appwrite Databases behavior:
 * - Deterministic document ID unique constraint (throws 409 conflict on duplicate create)
 * - Atomic read-modify-write revision tracking with CAS conflict detection
 * - Latency injection to stress concurrent races
 */
class ConcurrentAppwriteDatabasesFake {
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
    const doc = { $id: docId, ...data, _revision: data._revision || 1 };
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
    // Optimistic Concurrency Control (OCC) check
    if (data._expectedRevision !== undefined && existing._revision !== data._expectedRevision) {
      this.conflictCount++;
      const conflictErr = new Error('Document revision conflict during concurrent update.');
      conflictErr.code = 409;
      conflictErr.status = 409;
      throw conflictErr;
    }
    const updated = {
      ...existing,
      ...data,
      _revision: (existing._revision || 1) + 1,
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

    // Query evaluation for retention prune tests
    for (const q of queries) {
      if (typeof q === 'string') {
        try {
          const parsed = JSON.parse(q);
          if (parsed.method === 'lessThan' && parsed.attribute === 'expiresAt') {
            const threshold = parsed.values[0];
            docs = docs.filter((d) => (d.expiresAt || 0) < threshold);
          }
        } catch {
          // Non-JSON query
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

test('Concurrency: 20 simultaneous requests never exceed the burst limit', async () => {
  const fakeDb = new ConcurrentAppwriteDatabasesFake({ artificialLatencyMs: 1 });
  const identifier = 'usr_test_concurrency_20';
  const now = 5000000;
  const env = {
    RATE_LIMIT_ANON_PER_MINUTE: '5',
    RATE_LIMIT_ANON_PER_HOUR: '20',
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

  const allowedCount = results.filter((r) => r.allowed).length;
  const rejectedCount = results.filter((r) => !r.allowed).length;

  assert.equal(allowedCount, 5, 'Exactly 5 burst requests must be allowed');
  assert.equal(rejectedCount, 15, 'Exactly 15 requests must be rejected under burst limit');
  assert.ok(fakeDb.conflictCount > 0, 'Creation race conflicts must have occurred and been handled');
});

test('Concurrency: 50 simultaneous requests under hourly limit test strictly bounds successes', async () => {
  const fakeDb = new ConcurrentAppwriteDatabasesFake({ artificialLatencyMs: 1 });
  const identifier = 'usr_test_concurrency_50';
  const now = 6000000;
  const env = {
    RATE_LIMIT_ANON_PER_MINUTE: '50', // high burst to test hourly cap
    RATE_LIMIT_ANON_PER_HOUR: '12',
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

  const allowedCount = results.filter((r) => r.allowed).length;
  assert.equal(allowedCount, 12, 'Exactly 12 hourly requests must be allowed');
  const rejected = results.filter((r) => !r.allowed);
  assert.equal(rejected.length, 38);
  assert.ok(rejected.some((r) => r.reason === 'hourly_limit_exceeded'));
  assert.ok(
    rejected.every((r) =>
      ['hourly_limit_exceeded', 'rate_limit_storage_error'].includes(r.reason)
    )
  );
});

test('Concurrency: 100 simultaneous requests across multiple simulated workers do not exceed limit', async () => {
  const sharedDb = new ConcurrentAppwriteDatabasesFake({ artificialLatencyMs: 1 });
  const identifier = 'net_simulated_multiworker_100';
  const now = 7000000;
  const env = {
    RATE_LIMIT_AUTH_PER_MINUTE: '15',
    RATE_LIMIT_AUTH_PER_HOUR: '60',
  };

  const workerSimulations = Array.from({ length: 100 }, () =>
    checkRateLimit({
      databases: sharedDb,
      identifier,
      isAuth: true,
      now,
      env,
    })
  );

  const results = await Promise.all(workerSimulations);
  const allowedCount = results.filter((r) => r.allowed).length;

  assert.equal(allowedCount, 15, 'Burst limit of 15 strictly maintained under 100 concurrent callers');
});

test('RateLimiter: Fail-closed on storage error returns safe service-unavailable code', async () => {
  const brokenDb = new ConcurrentAppwriteDatabasesFake({ failOnStorage: true });
  const result = await checkRateLimit({
    databases: brokenDb,
    identifier: 'usr_fail_closed_test',
    isAuth: true,
    now: 8000000,
  });

  assert.equal(result.allowed, false);
  assert.equal(result.reason, 'rate_limit_storage_error');
  assert.ok(!JSON.stringify(result).includes('password'));
});

test('RateLimiter: Retention prune deletes expired rate limit documents safely', async () => {
  const fakeDb = new ConcurrentAppwriteDatabasesFake();
  const past = 100000;
  const now = past + WINDOW_HOUR_MS * 3;

  await fakeDb.createDocument('olitun_db', 'rate_limits', 'doc_old_1', {
    expiresAt: past + WINDOW_HOUR_MS,
  });
  await fakeDb.createDocument('olitun_db', 'rate_limits', 'doc_old_2', {
    expiresAt: past + WINDOW_HOUR_MS,
  });
  await fakeDb.createDocument('olitun_db', 'rate_limits', 'doc_fresh_3', {
    expiresAt: now + WINDOW_HOUR_MS,
  });

  const pruneResult = await pruneExpiredRateLimits({
    databases: fakeDb,
    now,
  });

  assert.equal(pruneResult.success, true);
  assert.equal(pruneResult.deletedCount, 2);
  assert.equal(fakeDb.store.size, 1);
  assert.ok(fakeDb.store.has('doc_fresh_3'));
});

test('Verified Identity: Cryptographic verification succeeds for valid JWT and fails for invalid/fake claims', async () => {
  const mockAccountService = {
    async get() {
      return { $id: 'verified_user_abc_999', name: 'Real User' };
    },
  };

  const validRes = await verifyAppwriteIdentity({
    jwt: 'sample_valid_jwt_token',
    endpoint: 'https://cloud.appwrite.io/v1',
    projectId: 'test_proj',
    accountServiceOverride: mockAccountService,
  });

  assert.equal(validRes.isVerified, true);
  assert.equal(validRes.userId, 'verified_user_abc_999');

  const failingAccountService = {
    async get() {
      const err = new Error('Invalid credentials');
      err.code = 401;
      throw err;
    },
  };

  const invalidRes = await verifyAppwriteIdentity({
    jwt: 'sample_expired_jwt_token',
    endpoint: 'https://cloud.appwrite.io/v1',
    projectId: 'test_proj',
    accountServiceOverride: failingAccountService,
  });

  assert.equal(invalidRes.isVerified, false);
  assert.equal(invalidRes.userId, null);

  // Empty or null JWT
  const emptyRes = await verifyAppwriteIdentity({ jwt: '' });
  assert.equal(emptyRes.isVerified, false);
  assert.equal(emptyRes.userId, null);
});

test('Verified Identity: Mandatory RATE_LIMIT_SALT in production & domain separation', () => {
  const salt = 'dedicated-production-salt-secret-12345';

  // Domain separation
  const userIdentifier = deriveRateLimitIdentifier({
    verifiedUserId: 'user_xyz',
    salt,
    env: { NODE_ENV: 'production' },
  });
  const netIdentifier = deriveRateLimitIdentifier({
    clientIp: '198.51.100.24',
    salt,
    env: { NODE_ENV: 'production' },
  });

  assert.ok(userIdentifier.startsWith('usr_'));
  assert.ok(netIdentifier.startsWith('net_'));
  assert.notEqual(userIdentifier, netIdentifier);

  // Missing salt in production MUST throw fatal security error
  assert.throws(
    () => {
      deriveRateLimitIdentifier({
        clientIp: '198.51.100.24',
        env: { NODE_ENV: 'production' },
      });
    },
    /RATE_LIMIT_SALT is mandatory in production/
  );

  // Non-production uses safe development salt
  const devIdentifier = deriveRateLimitIdentifier({
    clientIp: '198.51.100.24',
    env: { NODE_ENV: 'development' },
  });
  assert.ok(devIdentifier.startsWith('net_'));
});
