import { describe, test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

import {
  handleMutateReviewState,
  rowIdFor,
  operationRowIdFor,
  parseApplyRecallRequest,
} from '../mutateReviewState/src/main.js';

function createMockRes() {
  const res = {
    statusCode: 200,
    body: null,
    json: (body, status = 200) => {
      res.statusCode = status;
      res.body = body;
      return body;
    },
  };
  return res;
}

class InMemTablesDB {
  constructor() {
    this.tables = new Map();
  }
  _table(tableId) {
    if (!this.tables.has(tableId)) this.tables.set(tableId, new Map());
    return this.tables.get(tableId);
  }
  async getRow(dbId, tableId, rowId) {
    const table = this._table(tableId);
    if (!table.has(rowId)) {
      const err = new Error(`Row ${rowId} not found`);
      err.code = 404;
      throw err;
    }
    return JSON.parse(JSON.stringify(table.get(rowId)));
  }
  async createRow(dbId, tableId, rowId, data, permissions = []) {
    const table = this._table(tableId);
    if (table.has(rowId)) {
      const err = new Error(`Row ${rowId} already exists`);
      err.code = 409;
      throw err;
    }
    const row = { $id: rowId, $permissions: permissions, ...JSON.parse(JSON.stringify(data)) };
    table.set(rowId, row);
    return JSON.parse(JSON.stringify(row));
  }
  async updateRow(dbId, tableId, rowId, data, permissions = []) {
    const table = this._table(tableId);
    if (!table.has(rowId)) {
      const err = new Error(`Row ${rowId} not found`);
      err.code = 404;
      throw err;
    }
    const updated = { ...table.get(rowId), ...JSON.parse(JSON.stringify(data)) };
    table.set(rowId, updated);
    return JSON.parse(JSON.stringify(updated));
  }
}

const headers = (userId) => ({ 'x-appwrite-user-id': userId });

function opBody(overrides = {}) {
  return {
    action: 'applyRecall',
    operationId: 'op_1',
    itemId: 'w_1',
    itemType: 'word',
    exerciseType: 'recognition',
    correct: true,
    occurredAt: '2026-04-01T10:00:00.000Z',
    deviceId: 'd1',
    localSequence: 0,
    schemaVersion: 3,
    ...overrides,
  };
}

async function call(db, body, userId = 'user_1') {
  const res = createMockRes();
  await handleMutateReviewState({
    req: { method: 'POST', headers: headers(userId), body },
    res,
    error: () => {},
    log: () => {},
    tablesDBOverride: db,
  });
  return res;
}

async function snapshotOf(db, userId, itemId) {
  const row = await db.getRow('olitun_db', 'review_states', rowIdFor(userId, itemId));
  return JSON.parse(row.stateJson);
}

describe('mutateReviewState: applyRecall validation', () => {
  let db;
  beforeEach(() => { db = new InMemTablesDB(); });

  test('unauthenticated applyRecall rejected with 401', async () => {
    const res = createMockRes();
    await handleMutateReviewState({
      req: { method: 'POST', headers: {}, body: opBody() },
      res, error: () => {}, log: () => {}, tablesDBOverride: db,
    });
    assert.equal(res.statusCode, 401);
  });

  test('body userId mismatch rejected with 403 (never trusted)', async () => {
    const res = await call(db, { ...opBody(), userId: 'attacker' }, 'user_1');
    assert.equal(res.statusCode, 403);
  });

  test('invalid exerciseType rejected with 400', async () => {
    const res = await call(db, opBody({ exerciseType: 'telepathy' }));
    assert.equal(res.statusCode, 400);
  });

  test('missing operationId rejected with 400', async () => {
    const res = await call(db, opBody({ operationId: '' }));
    assert.equal(res.statusCode, 400);
  });

  test('oversized itemId rejected with 400', async () => {
    const res = await call(db, opBody({ itemId: 'x'.repeat(121) }));
    assert.equal(res.statusCode, 400);
  });

  test('oversized stateJson rejected with 413', async () => {
    const res = await call(db, opBody({ stateJson: 'x'.repeat(9000) }));
    assert.equal(res.statusCode, 413);
  });

  test('invalid occurredAt rejected with 400', async () => {
    const res = await call(db, opBody({ occurredAt: 'not-a-date' }));
    assert.equal(res.statusCode, 400);
  });

  test('parseApplyRecallRequest is exported and pure', () => {
    const parsed = parseApplyRecallRequest(opBody({ operationId: 'op_z' }), 'user_1');
    assert.equal(parsed.ok, true);
    assert.equal(parsed.op.operationId, 'op_z');
    assert.equal(parsed.op.userId, 'user_1');
  });
});

describe('mutateReviewState: applyRecall idempotency & convergence', () => {
  let db;
  beforeEach(() => { db = new InMemTablesDB(); });

  test('first apply succeeds, duplicate returns duplicate:true without double count', async () => {
    const first = await call(db, opBody());
    assert.equal(first.statusCode, 200);
    assert.equal(first.body.ok, true);
    assert.equal(first.body.duplicate, false);

    const snap1 = await snapshotOf(db, 'user_1', 'w_1');
    assert.equal(snap1.successfulRecalls, 1);

    const second = await call(db, opBody());
    assert.equal(second.statusCode, 200);
    assert.equal(second.body.duplicate, true);

    const snap2 = await snapshotOf(db, 'user_1', 'w_1');
    assert.equal(snap2.successfulRecalls, 1);
  });

  test('device A and B independent successes are both retained', async () => {
    const at = '2026-04-01T10:00:00.000Z';
    await call(db, opBody({ operationId: 'op_a', deviceId: 'dA', occurredAt: at }));
    await call(db, opBody({ operationId: 'op_b', deviceId: 'dB', occurredAt: at }));
    const snap = await snapshotOf(db, 'user_1', 'w_1');
    assert.equal(snap.successfulRecalls, 2);
  });

  test('different delivery orders converge to the same counters', async () => {
    const mk = (id, at) => opBody({ operationId: id, deviceId: `d_${id}`, occurredAt: at });
    const db1 = new InMemTablesDB();
    await call(db1, mk('op_1', '2026-04-01T10:00:00.000Z'));
    await call(db1, mk('op_2', '2026-04-02T10:00:00.000Z'));
    const s1 = await snapshotOf(db1, 'user_1', 'w_1');

    const db2 = new InMemTablesDB();
    await call(db2, mk('op_2', '2026-04-02T10:00:00.000Z'));
    await call(db2, mk('op_1', '2026-04-01T10:00:00.000Z'));
    const s2 = await snapshotOf(db2, 'user_1', 'w_1');

    assert.equal(s1.successfulRecalls, s2.successfulRecalls);
    assert.equal(s1.successfulRecalls, 2);
    // Scheduling converges on the newest occurredAt regardless of order.
    assert.equal(s1.lastReviewedAt, s2.lastReviewedAt);
  });

  test('A succeeds while B fails: failure counted, item in learning', async () => {
    await call(db, opBody({ operationId: 'op_ok', occurredAt: '2026-04-01T10:00:00.000Z' }));
    await call(db, opBody({ operationId: 'op_bad', correct: false, occurredAt: '2026-04-02T10:00:00.000Z' }));
    const snap = await snapshotOf(db, 'user_1', 'w_1');
    assert.equal(snap.successfulRecalls, 1);
    assert.equal(snap.failedRecalls, 1);
  });

  test('typing correct counts double (scheduler parity)', async () => {
    await call(db, opBody({ operationId: 'op_t', exerciseType: 'typing' }));
    const snap = await snapshotOf(db, 'user_1', 'w_1');
    assert.equal(snap.successfulRecalls, 2);
    assert.equal(snap.typingSuccesses, 1);
  });

  test('clock skew never loses operations (old op still counted)', async () => {
    await call(db, opBody({ operationId: 'op_new', occurredAt: '2026-05-01T10:00:00.000Z' }));
    // A lagged device delivers an older op afterwards.
    await call(db, opBody({ operationId: 'op_old', occurredAt: '2026-01-01T10:00:00.000Z' }));
    const snap = await snapshotOf(db, 'user_1', 'w_1');
    assert.equal(snap.successfulRecalls, 2);
    // Scheduling keeps the newest (monotonic lastReviewedAt).
    assert.equal(snap.lastReviewedAt, '2026-05-01T10:00:00.000Z');
  });

  test('cross-type apply is rejected', async () => {
    await call(db, opBody({ operationId: 'op_w' }));
    const res = await call(db, opBody({ operationId: 'op_s', itemType: 'sentence' }));
    assert.equal(res.statusCode, 400);
  });

  test('operations from another user are rejected', async () => {
    await call(db, opBody({ operationId: 'op_u' }), 'user_1');
    const snap = await snapshotOf(db, 'user_1', 'w_1');
    assert.equal(snap.successfulRecalls, 1);
    // Same operationId under another user is a distinct ledger entry.
    const other = await call(db, opBody({ operationId: 'op_u' }), 'user_2');
    assert.equal(other.body.duplicate, false);
    const snap2 = await snapshotOf(db, 'user_2', 'w_1');
    assert.equal(snap2.successfulRecalls, 1);
  });

  test('operationRowIdFor is deterministic and scoped', async () => {
    const a = operationRowIdFor('user_1', 'op_1');
    const b = operationRowIdFor('user_1', 'op_1');
    const c = operationRowIdFor('user_2', 'op_1');
    assert.equal(a, b);
    assert.notEqual(a, c);
  });

  test('malformed stored snapshot is quarantined-safe (fresh base, no throw)', async () => {
    // Seed a corrupt row directly.
    await db.createRow('olitun_db', 'review_states', rowIdFor('user_1', 'w_1'), {
      userId: 'user_1', itemId: 'w_1', itemType: 'word',
      stateJson: 'not-json{{{', nextReviewAt: '2026-04-01T10:00:00.000Z',
      lastReviewedAt: null, schemaVersion: 3,
    });
    const res = await call(db, opBody({ operationId: 'op_fix' }));
    assert.equal(res.statusCode, 200);
    const snap = await snapshotOf(db, 'user_1', 'w_1');
    assert.equal(snap.successfulRecalls, 1);
  });
});
