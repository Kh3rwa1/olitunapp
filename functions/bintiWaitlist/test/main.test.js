import test from 'node:test';
import assert from 'node:assert/strict';

import handler, {
  validateWaitlistInput,
  deriveCallerIdentifier,
  derivePhoneIdentifier,
  WAITLIST_COLLECTION,
} from '../src/main.js';

function createMockRes() {
  const res = {
    statusCode: 200,
    body: null,
    json(payload, status = 200) {
      res.statusCode = status;
      res.body = payload;
      return payload;
    },
  };
  return res;
}

function createInMemoryDb({ seedWaitlist = [] } = {}) {
  const docs = new Map();
  const created = [];
  const key = (col, id) => `${col}/${id}`;

  for (const doc of seedWaitlist) {
    docs.set(key(WAITLIST_COLLECTION, doc.$id), doc);
  }

  function applyQuery(items, q) {
    const parsed = typeof q === 'string' ? JSON.parse(q) : q;
    if (parsed.method === 'equal') {
      return items.filter((d) => parsed.values.includes(d[parsed.attribute]));
    }
    if (parsed.method === 'lessThan') {
      const [threshold] = parsed.values;
      return items.filter((d) => Number(d[parsed.attribute]) < threshold);
    }
    return items;
  }

  return {
    created,
    docs,
    async listDocuments(_db, col, queries) {
      let items = [];
      for (const [k, v] of docs.entries()) {
        if (k.startsWith(`${col}/`)) items.push(v);
      }
      for (const q of queries) {
        items = applyQuery(items, q);
      }
      return { documents: items, total: items.length };
    },
    async createDocument(_db, col, id, data, permissions) {
      const k = key(col, id);
      if (docs.has(k)) {
        const err = new Error('Document with the requested ID already exists.');
        err.code = 409;
        err.type = 'document_already_exists';
        throw err;
      }
      const doc = { $id: id, ...data };
      docs.set(k, doc);
      created.push({ col, id, data, permissions });
      return doc;
    },
    async deleteDocument(_db, col, id) {
      docs.delete(key(col, id));
      return {};
    },
  };
}

const VALID_BODY = {
  fullName: 'Sabit Murmu',
  phoneNumber: '+91 98765 43210',
  ceremonyType: 'Wedding',
  city: 'Jamshedpur',
  state: 'Jharkhand',
  notes: 'Morning ceremony preferred.',
};

function buildRequest(overrides = {}) {
  return {
    method: 'POST',
    headers: overrides.headers || { 'x-real-ip': '203.0.113.7' },
    body: JSON.stringify({ ...VALID_BODY, ...(overrides.body || {}) }),
  };
}

async function callHandler({ req, env = {}, seedWaitlist = [], db } = {}) {
  const saved = {};
  for (const [k, v] of Object.entries(env)) {
    saved[k] = process.env[k];
    process.env[k] = v;
  }
  const logs = [];
  const errors = [];
  const databases = db || createInMemoryDb({ seedWaitlist });
  const res = createMockRes();
  try {
    await handler({
      req,
      res,
      log: (m) => logs.push(m),
      error: (m) => errors.push(m),
      databases,
    });
    return { res, db: databases, logs, errors };
  } finally {
    for (const [k, v] of Object.entries(saved)) {
      if (v === undefined) delete process.env[k];
      else process.env[k] = v;
    }
  }
}

test('validateWaitlistInput accepts a valid submission and normalizes it', () => {
  const result = validateWaitlistInput(VALID_BODY);
  assert.equal(result.ok, true);
  assert.equal(result.entry.ceremonyType, 'wedding');
  assert.equal(result.entry.phoneNumber, '+91 98765 43210');
  assert.equal(result.entry.notes, 'Morning ceremony preferred.');
});

test('validateWaitlistInput rejects invalid fields with readable errors', () => {
  const result = validateWaitlistInput({
    fullName: 'A',
    phoneNumber: '123',
    ceremonyType: 'birthday',
    city: 'J',
    state: 'X',
    eventDate: 'not-a-date',
  });
  assert.equal(result.ok, false);
  const joined = result.errors.join(' ');
  assert.match(joined, /fullName/);
  assert.match(joined, /phoneNumber/);
  assert.match(joined, /ceremonyType/);
  assert.match(joined, /city/);
  assert.match(joined, /eventDate/);
});

test('deriveCallerIdentifier prefers the verified user and never leaks raw values', () => {
  const userBased = deriveCallerIdentifier({
    userId: 'user-1',
    clientIp: '1.2.3.4',
    env: { RATE_LIMIT_SALT: 's3cret' },
  });
  const networkBased = deriveCallerIdentifier({
    userId: null,
    clientIp: '1.2.3.4',
    env: { RATE_LIMIT_SALT: 's3cret' },
  });
  assert.match(userBased, /^wusr_[0-9a-f]{32}$/);
  assert.match(networkBased, /^wnet_[0-9a-f]{32}$/);
  assert.notEqual(userBased, networkBased);
});

test('derivePhoneIdentifier is domain-separated from the caller identifier', () => {
  const phone = derivePhoneIdentifier({
    phoneNumber: '+919876543210',
    env: { RATE_LIMIT_SALT: 's3cret' },
  });
  assert.match(phone, /^wph_[0-9a-f]{32}$/);
});

test('valid POST creates an entry with server-owned fields and admin-only permissions', async () => {
  const { res, db } = await callHandler({
    req: buildRequest({ headers: { 'x-real-ip': '203.0.113.7', 'x-appwrite-user-id': 'user-abc' } }),
  });

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.ok, true);
  assert.equal(res.body.duplicate, false);
  assert.equal(res.body.entry.userId, 'user-abc');
  assert.equal(res.body.entry.status, 'new');
  assert.ok(res.body.entry.submittedAt, 'server stamped submittedAt');
  assert.equal(res.body.entry.ceremonyType, 'wedding');

  const write = db.created.find((c) => c.col === WAITLIST_COLLECTION);
  assert.deepEqual(write.permissions, [
    'read("team:admins")',
    'update("team:admins")',
    'delete("team:admins")',
  ]);
});

test('client-supplied id, userId, status, and submittedAt are ignored', async () => {
  const { res, db } = await callHandler({
    req: buildRequest({
      body: {
        id: 'attacker-chosen-id',
        userId: 'spoofed-user',
        status: 'converted',
        submittedAt: '1999-01-01T00:00:00.000Z',
      },
    }),
  });

  assert.equal(res.statusCode, 200);
  const write = db.created.find((c) => c.col === WAITLIST_COLLECTION);
  assert.notEqual(write.id, 'attacker-chosen-id');
  assert.equal(write.data.userId, null);
  assert.equal(write.data.status, 'new');
  assert.notEqual(write.data.submittedAt, '1999-01-01T00:00:00.000Z');
});

test('rejects non-POST requests', async () => {
  const { res } = await callHandler({ req: { method: 'GET', headers: {}, body: '' } });
  assert.equal(res.statusCode, 405);
});

test('deduplicates pending submissions for the same phone + ceremony', async () => {
  const existing = {
    $id: 'existing-entry-1',
    userId: null,
    fullName: 'Sabit Murmu',
    phoneNumber: '+91 98765 43210',
    ceremonyType: 'wedding',
    city: 'Jamshedpur',
    state: 'Jharkhand',
    submittedAt: '2026-08-01T00:00:00.000Z',
    status: 'new',
  };
  const { res, db } = await callHandler({
    req: buildRequest(),
    seedWaitlist: [existing],
  });

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.ok, true);
  assert.equal(res.body.duplicate, true);
  assert.equal(res.body.entry.id, 'existing-entry-1');
  assert.equal(
    db.created.filter((c) => c.col === WAITLIST_COLLECTION).length,
    0,
    'no second document created',
  );
});

test('a contacted entry does not block a fresh submission', async () => {
  const contacted = {
    $id: 'entry-contacted',
    phoneNumber: '+91 98765 43210',
    ceremonyType: 'wedding',
    status: 'contacted',
    fullName: 'Earlier',
    city: 'Jamshedpur',
    state: 'Jharkhand',
    submittedAt: '2026-01-01T00:00:00.000Z',
  };
  const { res, db } = await callHandler({
    req: buildRequest(),
    seedWaitlist: [contacted],
  });

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.duplicate, false);
  assert.equal(
    db.created.filter((c) => c.col === WAITLIST_COLLECTION).length,
    1,
  );
});

test('per-minute caller rate limit returns 429 before any write', async () => {
  const env = { RATE_LIMIT_ANON_PER_MINUTE: '1', RATE_LIMIT_ANON_PER_HOUR: '20' };
  const shared = createInMemoryDb();
  const first = await callHandler({ req: buildRequest(), env, db: shared });
  assert.equal(first.res.statusCode, 200);

  const second = await callHandler({ req: buildRequest(), env, db: shared });
  assert.equal(second.res.statusCode, 429);
  assert.equal(
    second.db.created.filter((c) => c.col === WAITLIST_COLLECTION).length,
    first.db.created.filter((c) => c.col === WAITLIST_COLLECTION).length,
    'no additional waitlist write once rate limited',
  );
});

test('same phone from a different IP still hits the phone bucket', async () => {
  const env = { RATE_LIMIT_ANON_PER_MINUTE: '1', RATE_LIMIT_ANON_PER_HOUR: '20' };
  const shared = createInMemoryDb();
  const first = await callHandler({
    req: buildRequest({ headers: { 'x-real-ip': '198.51.100.1' } }),
    env,
    db: shared,
  });
  assert.equal(first.res.statusCode, 200);

  const second = await callHandler({
    req: buildRequest({ headers: { 'x-real-ip': '198.51.100.2' } }),
    env,
    db: shared,
  });
  assert.equal(second.res.statusCode, 429);
  assert.match(second.res.body.message, /This number has too many/);
});

test('verified users have a separate bucket from anonymous callers', async () => {
  const env = { RATE_LIMIT_ANON_PER_MINUTE: '1', RATE_LIMIT_ANON_PER_HOUR: '20' };
  const shared = createInMemoryDb();
  const anon = await callHandler({
    req: buildRequest({ headers: { 'x-real-ip': '203.0.113.9' } }),
    env,
    db: shared,
  });
  assert.equal(anon.res.statusCode, 200);

  const authed = await callHandler({
    req: buildRequest({
      headers: { 'x-real-ip': '203.0.113.9', 'x-appwrite-user-id': 'user-xyz' },
      body: { phoneNumber: '+91 90000 00001' },
    }),
    env,
    db: shared,
  });
  assert.equal(authed.res.statusCode, 200);
});

test('the phone bucket also blocks a verified user flooding the same number', async () => {
  const env = { RATE_LIMIT_ANON_PER_MINUTE: '1', RATE_LIMIT_ANON_PER_HOUR: '20' };
  const shared = createInMemoryDb();
  const first = await callHandler({
    req: buildRequest({ headers: { 'x-real-ip': '203.0.113.10', 'x-appwrite-user-id': 'user-xyz' } }),
    env,
    db: shared,
  });
  assert.equal(first.res.statusCode, 200);

  const second = await callHandler({
    req: buildRequest({ headers: { 'x-real-ip': '203.0.113.11', 'x-appwrite-user-id': 'user-abc' } }),
    env,
    db: shared,
  });
  assert.equal(second.res.statusCode, 429);
  assert.match(second.res.body.message, /This number has too many/);
});

test('invalid submissions are rejected with 400 and never rate-limit-clocked twice', async () => {
  const { res } = await callHandler({
    req: buildRequest({ body: { fullName: '', phoneNumber: 'abc', ceremonyType: 'x', city: '', state: '' } }),
  });
  assert.equal(res.statusCode, 400);
  assert.ok(Array.isArray(res.body.errors));
});
