import { describe, test } from 'node:test';
import assert from 'node:assert/strict';

import {
  handleMutateReviewState,
  parseReviewStateListRequest,
} from '../../functions/mutateReviewState/src/main.js';

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

function queryMethods(queries) {
  return queries.map((query) => JSON.parse(query).method);
}

class ListTablesDB {
  constructor(rows = []) {
    this.rows = rows;
    this.calls = [];
    this.failure = null;
  }

  async listRows(databaseId, tableId, queries) {
    this.calls.push({ databaseId, tableId, queries });
    if (this.failure) throw this.failure;
    return { rows: this.rows };
  }
}

async function invokeList(db, body) {
  const res = createMockRes();
  await handleMutateReviewState({
    req: {
      method: 'POST',
      headers: { 'x-appwrite-user-id': 'alice' },
      body,
    },
    res,
    dbOverride: db,
  });
  return res;
}

describe('mutateReviewState: cursor-paginated list action', () => {
  test('lists a bounded first page without requiring itemId', async () => {
    const rows = [
      { $id: 'r_first', userId: 'alice' },
      { $id: 'r_second', userId: 'alice' },
    ];
    const db = new ListTablesDB(rows);

    const res = await invokeList(db, { action: 'list', limit: 2 });

    assert.equal(res.statusCode, 200);
    assert.equal(res.body.ok, true);
    assert.deepEqual(res.body.rows, rows);
    assert.deepEqual(res.body.documents, rows);
    assert.equal(res.body.hasMore, true);
    assert.equal(res.body.nextCursor, 'r_second');
    assert.equal(db.calls.length, 1);
    assert.equal(db.calls[0].databaseId, 'olitun_db');
    assert.equal(db.calls[0].tableId, 'review_states');
    assert.deepEqual(queryMethods(db.calls[0].queries), [
      'equal',
      'orderAsc',
      'limit',
    ]);
  });

  test('continues from a validated cursor and terminates a short page', async () => {
    const rows = [{ $id: 'r_third', userId: 'alice' }];
    const db = new ListTablesDB(rows);

    const res = await invokeList(db, {
      action: 'list',
      limit: 2,
      cursor: 'r_second',
    });

    assert.equal(res.statusCode, 200);
    assert.equal(res.body.hasMore, false);
    assert.equal(res.body.nextCursor, null);
    assert.deepEqual(queryMethods(db.calls[0].queries), [
      'equal',
      'orderAsc',
      'limit',
      'cursorAfter',
    ]);
  });

  test('uses the bounded default page size', () => {
    assert.deepEqual(parseReviewStateListRequest({}), {
      ok: true,
      limit: 100,
      cursor: null,
    });
  });

  test('rejects invalid limits before any database call', async () => {
    for (const limit of [0, 101, 1.5, 'not-a-number']) {
      const db = new ListTablesDB();
      const res = await invokeList(db, { action: 'list', limit });

      assert.equal(res.statusCode, 400);
      assert.equal(res.body.error, 'INVALID_ARGUMENT');
      assert.equal(db.calls.length, 0);
    }
  });

  test('rejects invalid cursors before any database call', async () => {
    for (const cursor of ['_leading-underscore', 'x'.repeat(37), { id: 'r_1' }]) {
      const db = new ListTablesDB();
      const res = await invokeList(db, { action: 'list', cursor });

      assert.equal(res.statusCode, 400);
      assert.equal(res.body.error, 'INVALID_ARGUMENT');
      assert.equal(db.calls.length, 0);
    }
  });

  test('rejects unknown actions before item and database validation', async () => {
    const db = new ListTablesDB();
    const res = await invokeList(db, { action: 'export_all' });

    assert.equal(res.statusCode, 400);
    assert.equal(res.body.error, 'INVALID_ARGUMENT');
    assert.match(res.body.message, /Unknown action/);
    assert.equal(db.calls.length, 0);
  });
});
