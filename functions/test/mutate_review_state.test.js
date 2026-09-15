import { describe, test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';

import {
  handleMutateReviewState,
  rowIdFor,
  legacyRowIdFor,
  isValidAppwriteRowId,
} from '../mutateReviewState/src/main.js';
import {
  REVIEW_TABLE_SPEC,
  REVIEW_COLUMNS_SPEC,
  REVIEW_INDEXES_SPEC,
  REVIEW_SCHEMA_LIMITS,
} from '../mutateReviewState/src/review_schema_contract.js';

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
    this.tables = new Map(); // key: tableId -> Map(rowId -> row)
    this.failNextCreate = false;
    this.failNextDelete = false;
    this.calls = [];
  }

  get callCount() {
    return this.calls.length;
  }

  _record(method, ...args) {
    this.calls.push({ method, args });
  }

  _table(tableId) {
    if (!this.tables.has(tableId)) {
      this.tables.set(tableId, new Map());
    }
    return this.tables.get(tableId);
  }

  async getRow(dbId, tableId, rowId) {
    this._record('getRow', dbId, tableId, rowId);
    const table = this._table(tableId);
    if (!table.has(rowId)) {
      const err = new Error(`Row ${rowId} not found`);
      err.code = 404;
      throw err;
    }
    return JSON.parse(JSON.stringify(table.get(rowId)));
  }

  async createRow(dbId, tableId, rowId, data, permissions = []) {
    this._record('createRow', dbId, tableId, rowId, data, permissions);
    if (this.failNextCreate) {
      this.failNextCreate = false;
      const err = new Error('Database write failure');
      err.code = 500;
      throw err;
    }
    const table = this._table(tableId);
    if (table.has(rowId)) {
      const err = new Error(`Row ${rowId} already exists`);
      err.code = 409;
      throw err;
    }
    const row = {
      $id: rowId,
      $permissions: permissions,
      ...JSON.parse(JSON.stringify(data)),
    };
    table.set(rowId, row);
    return JSON.parse(JSON.stringify(row));
  }

  async updateRow(dbId, tableId, rowId, data, permissions = []) {
    this._record('updateRow', dbId, tableId, rowId, data, permissions);
    const table = this._table(tableId);
    if (!table.has(rowId)) {
      const err = new Error(`Row ${rowId} not found`);
      err.code = 404;
      throw err;
    }
    const existing = table.get(rowId);
    const updated = {
      ...existing,
      ...JSON.parse(JSON.stringify(data)),
      $permissions: permissions && permissions.length ? permissions : existing.$permissions,
    };
    table.set(rowId, updated);
    return JSON.parse(JSON.stringify(updated));
  }

  async deleteRow(dbId, tableId, rowId) {
    this._record('deleteRow', dbId, tableId, rowId);
    if (this.failNextDelete) {
      this.failNextDelete = false;
      const err = new Error('Database delete failure');
      err.code = 500;
      throw err;
    }
    const table = this._table(tableId);
    if (!table.has(rowId)) {
      const err = new Error(`Row ${rowId} not found`);
      err.code = 404;
      throw err;
    }
    table.delete(rowId);
    return { ok: true };
  }

  async listRows(dbId, tableId, queries = []) {
    this._record('listRows', dbId, tableId, queries);
    const table = this._table(tableId);
    return { rows: Array.from(table.values()) };
  }
}

function makeValidPayload(overrides = {}) {
  const itemId = overrides.itemId !== undefined ? overrides.itemId : 'word_1';
  const itemType = overrides.itemType !== undefined ? overrides.itemType : 'word';
  const nextReviewAt = overrides.nextReviewAt !== undefined ? overrides.nextReviewAt : '2026-01-04T09:00:00.000Z';
  const lastReviewedAt = Object.prototype.hasOwnProperty.call(overrides, 'lastReviewedAt')
    ? overrides.lastReviewedAt
    : '2026-01-01T09:00:00.000Z';
  const schemaVersion = overrides.schemaVersion !== undefined ? overrides.schemaVersion : 3;

  let stateJson;
  if (Object.prototype.hasOwnProperty.call(overrides, 'stateJson')) {
    stateJson = overrides.stateJson;
  } else {
    stateJson = JSON.stringify({
      itemId,
      itemType,
      nextReviewAt,
      ...(lastReviewedAt ? { lastReviewedAt } : {}),
      schemaVersion,
      successfulRecalls: 1,
      failedRecalls: 0,
    });
  }

  const payload = {
    action: 'upsert',
    itemId,
    itemType,
    stateJson,
    nextReviewAt,
    schemaVersion,
    ...overrides,
  };

  if (lastReviewedAt !== undefined && lastReviewedAt !== null) {
    payload.lastReviewedAt = lastReviewedAt;
  } else if (Object.prototype.hasOwnProperty.call(overrides, 'lastReviewedAt') && overrides.lastReviewedAt === null) {
    delete payload.lastReviewedAt;
  }

  return payload;
}

describe('mutateReviewState: Contract & Limit Validation', () => {
  let db;
  let logs;
  let errors;

  beforeEach(() => {
    db = new InMemTablesDB();
    logs = [];
    errors = [];
  });

  test('contract specification matches required table schema and limits', () => {
    assert.equal(REVIEW_TABLE_SPEC.id, 'review_states');
    assert.equal(REVIEW_TABLE_SPEC.name, 'Review States');
    assert.deepEqual(REVIEW_TABLE_SPEC.permissions, []);
    assert.equal(REVIEW_TABLE_SPEC.rowSecurity, true);

    assert.equal(REVIEW_SCHEMA_LIMITS.USER_ID_MAX_LENGTH, 80);
    assert.equal(REVIEW_SCHEMA_LIMITS.ITEM_ID_MAX_LENGTH, 120);
    assert.equal(REVIEW_SCHEMA_LIMITS.STATE_JSON_MAX_BYTES, 8192);
    assert.equal(REVIEW_SCHEMA_LIMITS.STATE_JSON_MAX_LENGTH, 8192);
    assert.deepEqual(REVIEW_SCHEMA_LIMITS.ITEM_TYPES, ['word', 'sentence']);
    assert.deepEqual(REVIEW_SCHEMA_LIMITS.SUPPORTED_SCHEMA_VERSIONS, [1, 2, 3]);
    assert.equal(REVIEW_SCHEMA_LIMITS.DEFAULT_SCHEMA_VERSION, 3);

    const colMap = new Map(REVIEW_COLUMNS_SPEC.map((c) => [c.key, c]));
    assert.equal(colMap.get('userId').size, 80);
    assert.equal(colMap.get('itemId').size, 120);
    assert.equal(colMap.get('stateJson').size, 8192);
    assert.equal(colMap.get('itemType').type, 'enum');
    assert.deepEqual(colMap.get('itemType').elements, ['word', 'sentence']);
    assert.equal(colMap.get('nextReviewAt').type, 'datetime');
    assert.equal(colMap.get('nextReviewAt').required, true);
    assert.equal(colMap.get('lastReviewedAt').type, 'datetime');
    assert.equal(colMap.get('lastReviewedAt').required, false);
    assert.equal(colMap.get('schemaVersion').type, 'integer');
    assert.equal(colMap.get('schemaVersion').default, 3);
  });

  test('main.js does not import or instantiate Databases or call document methods', () => {
    const source = fs.readFileSync(new URL('../mutateReviewState/src/main.js', import.meta.url), 'utf8');
    assert.ok(!source.includes('Databases'), 'main.js must not reference Databases');
    assert.ok(!source.includes('getDocument'), 'main.js must not call getDocument');
    assert.ok(!source.includes('createDocument'), 'main.js must not call createDocument');
    assert.ok(!source.includes('updateDocument'), 'main.js must not call updateDocument');
    assert.ok(!source.includes('deleteDocument'), 'main.js must not call deleteDocument');
    assert.ok(!source.includes('listDocuments'), 'main.js must not call listDocuments');
    assert.ok(source.includes('TablesDB'), 'main.js must import and instantiate TablesDB');
    assert.ok(source.includes('getRow'), 'main.js must use getRow');
    assert.ok(source.includes('createRow'), 'main.js must use createRow');
    assert.ok(source.includes('updateRow'), 'main.js must use updateRow');
    assert.ok(source.includes('deleteRow'), 'main.js must use deleteRow');
    assert.ok(source.includes('listRows'), 'main.js must use listRows');
  });

  test('schema version parity between ReviewStore, contract defaults, and column spec', () => {
    const storeSource = fs.readFileSync(new URL('../../lib/features/review/data/review_store.dart', import.meta.url), 'utf8');
    const match = storeSource.match(/static const int schemaVersion = (\d+);/);
    assert.ok(match, 'ReviewStore must declare schemaVersion');
    const storeVersion = Number(match[1]);
    assert.equal(storeVersion, 3, 'ReviewStore.schemaVersion must equal 3');
    assert.equal(storeVersion, REVIEW_SCHEMA_LIMITS.DEFAULT_SCHEMA_VERSION, 'Contract default must match ReviewStore');
    const colSpec = REVIEW_COLUMNS_SPEC.find((c) => c.key === 'schemaVersion');
    assert.equal(storeVersion, colSpec.default, 'Column default must match ReviewStore');
  });


  test('itemId length 120 is accepted, 121 is rejected with 400 without DB call', async () => {
    const id120 = 'w'.repeat(120);
    const res1 = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({ itemId: id120 }),
      },
      res: res1,
      dbOverride: db,
    });
    assert.equal(res1.statusCode, 200);

    db.calls = [];
    const id121 = 'w'.repeat(121);
    const res2 = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({ itemId: id121 }),
      },
      res: res2,
      dbOverride: db,
    });
    assert.equal(res2.statusCode, 400);
    assert.equal(res2.body.error, 'INVALID_ARGUMENT');
    assert.equal(db.callCount, 0, 'No database call must occur after itemId validation failure');
  });

  test('userId length 80 is accepted, 81 is rejected with 400 without DB call', async () => {
    const user80 = 'u'.repeat(80);
    const res1 = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': user80 },
        body: makeValidPayload(),
      },
      res: res1,
      dbOverride: db,
    });
    assert.equal(res1.statusCode, 200);

    db.calls = [];
    const user81 = 'u'.repeat(81);
    const res2 = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': user81 },
        body: makeValidPayload(),
      },
      res: res2,
      dbOverride: db,
    });
    assert.equal(res2.statusCode, 400);
    assert.equal(res2.body.error, 'INVALID_ARGUMENT');
    assert.equal(db.callCount, 0, 'No database call must occur after userId validation failure');
  });

  test('stateJson UTF-8 byte length semantics: ASCII 8192 accepted, 8193 rejected with 413 and zero DB calls', async () => {
    const buildAsciiPadded = (targetBytes) => {
      const template = {
        itemId: 'word_1',
        itemType: 'word',
        nextReviewAt: '2026-01-04T09:00:00.000Z',
        lastReviewedAt: '2026-01-01T09:00:00.000Z',
        schemaVersion: 3,
        pad: '',
      };
      const initialJson = JSON.stringify(template);
      const neededPad = targetBytes - Buffer.byteLength(initialJson, 'utf8');
      template.pad = 'x'.repeat(neededPad);
      const finalJson = JSON.stringify(template);
      assert.equal(Buffer.byteLength(finalJson, 'utf8'), targetBytes);
      return finalJson;
    };

    const json8192 = buildAsciiPadded(8192);
    const res1 = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({ stateJson: json8192 }),
      },
      res: res1,
      dbOverride: db,
    });
    assert.equal(res1.statusCode, 200);

    db.calls = [];
    const json8193 = buildAsciiPadded(8193);
    const res2 = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({ stateJson: json8193 }),
      },
      res: res2,
      dbOverride: db,
    });
    assert.equal(res2.statusCode, 413);
    assert.equal(res2.body.error, 'PAYLOAD_TOO_LARGE');
    assert.equal(db.callCount, 0, 'No database call must occur after stateJson byte length rejection');
  });

  test('stateJson UTF-8 byte length semantics: Ol Chiki (3 bytes/char) boundary', async () => {
    assert.equal(Buffer.byteLength('ᱚ', 'utf8'), 3);

    // Build payload with Ol Chiki chars + ASCII padding to reach exactly 8192 bytes
    const templateOl = {
      itemId: 'word_1',
      itemType: 'word',
      nextReviewAt: '2026-01-04T09:00:00.000Z',
      lastReviewedAt: '2026-01-01T09:00:00.000Z',
      schemaVersion: 3,
      olChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
      pad: '',
    };
    const baseOlBytes = Buffer.byteLength(JSON.stringify(templateOl), 'utf8');
    templateOl.pad = 'a'.repeat(8192 - baseOlBytes);
    const olJson8192 = JSON.stringify(templateOl);
    assert.equal(Buffer.byteLength(olJson8192, 'utf8'), 8192);

    const resOl1 = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({ stateJson: olJson8192 }),
      },
      res: resOl1,
      dbOverride: db,
    });
    assert.equal(resOl1.statusCode, 200);

    // Exceed 8192 bytes by 1 Ol Chiki character (+3 bytes -> 8195 bytes)
    db.calls = [];
    templateOl.olChiki += 'ᱚ';
    const olJson8195 = JSON.stringify(templateOl);
    assert.equal(Buffer.byteLength(olJson8195, 'utf8'), 8195);
    const resOl2 = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({ stateJson: olJson8195 }),
      },
      res: resOl2,
      dbOverride: db,
    });
    assert.equal(resOl2.statusCode, 413);
    assert.equal(resOl2.body.error, 'PAYLOAD_TOO_LARGE');
    assert.equal(db.callCount, 0, 'No DB call on Ol Chiki byte overflow');
  });

  test('stateJson UTF-8 byte length semantics: Emoji (4 bytes/char) boundary', async () => {
    assert.equal(Buffer.byteLength('🚀', 'utf8'), 4);

    const templateEmoji = {
      itemId: 'word_1',
      itemType: 'word',
      nextReviewAt: '2026-01-04T09:00:00.000Z',
      lastReviewedAt: '2026-01-01T09:00:00.000Z',
      schemaVersion: 3,
      emoji: '🚀',
      pad: '',
    };
    const baseEmojiBytes = Buffer.byteLength(JSON.stringify(templateEmoji), 'utf8');
    templateEmoji.pad = 'e'.repeat(8192 - baseEmojiBytes);
    const emojiJson8192 = JSON.stringify(templateEmoji);
    assert.equal(Buffer.byteLength(emojiJson8192, 'utf8'), 8192);

    const resEmoji1 = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({ stateJson: emojiJson8192 }),
      },
      res: resEmoji1,
      dbOverride: db,
    });
    assert.equal(resEmoji1.statusCode, 200);

    // Adding another 4-byte emoji causes overflow (8196 bytes)
    db.calls = [];
    templateEmoji.emoji += '🚀';
    const emojiOverflowJson = JSON.stringify(templateEmoji);
    assert.equal(Buffer.byteLength(emojiOverflowJson, 'utf8'), 8196);
    const resEmoji2 = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({ stateJson: emojiOverflowJson }),
      },
      res: resEmoji2,
      dbOverride: db,
    });
    assert.equal(resEmoji2.statusCode, 413);
    assert.equal(resEmoji2.body.error, 'PAYLOAD_TOO_LARGE');
    assert.equal(db.callCount, 0, 'No DB call on Emoji byte overflow');
  });

  test('stateJson UTF-8 byte length semantics: Combining characters boundary', async () => {
    assert.equal(Buffer.byteLength('e\u0301', 'utf8'), 3);
    assert.equal('e\u0301'.length, 2);

    const templateComb = {
      itemId: 'word_1',
      itemType: 'word',
      nextReviewAt: '2026-01-04T09:00:00.000Z',
      lastReviewedAt: '2026-01-01T09:00:00.000Z',
      schemaVersion: 3,
      accent: 'e\u0301',
      pad: '',
    };
    const baseCombBytes = Buffer.byteLength(JSON.stringify(templateComb), 'utf8');
    templateComb.pad = 'c'.repeat(8192 - baseCombBytes);
    const combJson8192 = JSON.stringify(templateComb);
    assert.equal(Buffer.byteLength(combJson8192, 'utf8'), 8192);

    const resComb1 = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({ stateJson: combJson8192 }),
      },
      res: resComb1,
      dbOverride: db,
    });
    assert.equal(resComb1.statusCode, 200);

    // Add 1 more combining character (+3 bytes -> 8195 bytes)
    db.calls = [];
    templateComb.accent += 'e\u0301';
    const combOverflowJson = JSON.stringify(templateComb);
    assert.equal(Buffer.byteLength(combOverflowJson, 'utf8'), 8195);
    const resComb2 = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({ stateJson: combOverflowJson }),
      },
      res: resComb2,
      dbOverride: db,
    });
    assert.equal(resComb2.statusCode, 413);
    assert.equal(resComb2.body.error, 'PAYLOAD_TOO_LARGE');
    assert.equal(db.callCount, 0, 'No DB call on Combining Character byte overflow');
  });

  test('invalid JSON string is rejected with 400 without DB call', async () => {
    db.calls = [];
    const res = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({ stateJson: '{ not valid json: true }' }),
      },
      res,
      dbOverride: db,
    });
    assert.equal(res.statusCode, 400);
    assert.equal(res.body.error, 'INVALID_ARGUMENT');
    assert.equal(db.callCount, 0);
  });

  test('JSON array stateJson is rejected with 400 without DB call', async () => {
    db.calls = [];
    const res = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({ stateJson: JSON.stringify([1, 2, 3]) }),
      },
      res,
      dbOverride: db,
    });
    assert.equal(res.statusCode, 400);
    assert.equal(res.body.error, 'INVALID_ARGUMENT');
    assert.equal(db.callCount, 0);
  });

  test('JSON primitive stateJson is rejected with 400 without DB call', async () => {
    for (const primitive of ['"just a string"', '12345', 'true', 'null']) {
      db.calls = [];
      const res = createMockRes();
      await handleMutateReviewState({
        req: {
          method: 'POST',
          headers: { 'x-appwrite-user-id': 'alice' },
          body: makeValidPayload({ stateJson: primitive }),
        },
        res,
        dbOverride: db,
      });
      assert.equal(res.statusCode, 400);
      assert.equal(res.body.error, 'INVALID_ARGUMENT');
      assert.equal(db.callCount, 0);
    }
  });

  test('mismatched itemId between outer and inner stateJson is rejected with 400', async () => {
    db.calls = [];
    const res = createMockRes();
    const badState = JSON.stringify({
      itemId: 'mismatched_item_id',
      itemType: 'word',
      nextReviewAt: '2026-01-04T09:00:00.000Z',
      lastReviewedAt: '2026-01-01T09:00:00.000Z',
      schemaVersion: 3,
    });
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({ itemId: 'word_1', stateJson: badState }),
      },
      res,
      dbOverride: db,
    });
    assert.equal(res.statusCode, 400);
    assert.equal(res.body.error, 'INVALID_ARGUMENT');
    assert.equal(db.callCount, 0);
  });

  test('mismatched itemType between outer and inner stateJson is rejected with 400', async () => {
    db.calls = [];
    const res = createMockRes();
    const badState = JSON.stringify({
      itemId: 'word_1',
      itemType: 'sentence', // differs from outer 'word'
      nextReviewAt: '2026-01-04T09:00:00.000Z',
      lastReviewedAt: '2026-01-01T09:00:00.000Z',
      schemaVersion: 3,
    });
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({ itemType: 'word', stateJson: badState }),
      },
      res,
      dbOverride: db,
    });
    assert.equal(res.statusCode, 400);
    assert.equal(res.body.error, 'INVALID_ARGUMENT');
    assert.equal(db.callCount, 0);
  });

  test('mismatched nextReviewAt between outer and inner stateJson is rejected with 400', async () => {
    db.calls = [];
    const res = createMockRes();
    const badState = JSON.stringify({
      itemId: 'word_1',
      itemType: 'word',
      nextReviewAt: '2026-01-04T09:00:01.000Z', // 1 second off
      lastReviewedAt: '2026-01-01T09:00:00.000Z',
      schemaVersion: 3,
    });
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({ nextReviewAt: '2026-01-04T09:00:00.000Z', stateJson: badState }),
      },
      res,
      dbOverride: db,
    });
    assert.equal(res.statusCode, 400);
    assert.equal(res.body.error, 'INVALID_ARGUMENT');
    assert.equal(db.callCount, 0);
  });

  test('mismatched lastReviewedAt presence or instant is rejected with 400', async () => {
    // Case 1: outer has lastReviewedAt, inner does not
    let res = createMockRes();
    let stateWithoutLast = JSON.stringify({
      itemId: 'word_1',
      itemType: 'word',
      nextReviewAt: '2026-01-04T09:00:00.000Z',
      schemaVersion: 3,
    });
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({ lastReviewedAt: '2026-01-01T09:00:00.000Z', stateJson: stateWithoutLast }),
      },
      res,
      dbOverride: db,
    });
    assert.equal(res.statusCode, 400);
    assert.equal(res.body.error, 'INVALID_ARGUMENT');

    // Case 2: outer omitted, inner present
    res = createMockRes();
    let stateWithLast = JSON.stringify({
      itemId: 'word_1',
      itemType: 'word',
      nextReviewAt: '2026-01-04T09:00:00.000Z',
      lastReviewedAt: '2026-01-01T09:00:00.000Z',
      schemaVersion: 3,
    });
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({ lastReviewedAt: null, stateJson: stateWithLast }),
      },
      res,
      dbOverride: db,
    });
    assert.equal(res.statusCode, 400);
    assert.equal(res.body.error, 'INVALID_ARGUMENT');

    // Case 3: both present but different instant
    res = createMockRes();
    let stateWithDiffLast = JSON.stringify({
      itemId: 'word_1',
      itemType: 'word',
      nextReviewAt: '2026-01-04T09:00:00.000Z',
      lastReviewedAt: '2026-01-01T09:00:10.000Z',
      schemaVersion: 3,
    });
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({ lastReviewedAt: '2026-01-01T09:00:00.000Z', stateJson: stateWithDiffLast }),
      },
      res,
      dbOverride: db,
    });
    assert.equal(res.statusCode, 400);
    assert.equal(res.body.error, 'INVALID_ARGUMENT');
  });

  test('equivalent timestamp offsets (UTC vs +05:30) are accepted with 200', async () => {
    // 09:00 UTC == 14:30 +05:30
    const outerNext = '2026-01-04T09:00:00.000Z';
    const innerNext = '2026-01-04T14:30:00.000+05:30';
    assert.equal(Date.parse(outerNext), Date.parse(innerNext));

    const outerLast = '2026-01-01T09:00:00.000Z';
    const innerLast = '2026-01-01T14:30:00.000+05:30';
    assert.equal(Date.parse(outerLast), Date.parse(innerLast));

    const state = JSON.stringify({
      itemId: 'word_1',
      itemType: 'word',
      nextReviewAt: innerNext,
      lastReviewedAt: innerLast,
      schemaVersion: 3,
    });

    const res = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({
          nextReviewAt: outerNext,
          lastReviewedAt: outerLast,
          stateJson: state,
        }),
      },
      res,
      dbOverride: db,
    });
    assert.equal(res.statusCode, 200);
    assert.equal(res.body.ok, true);
  });

  test('both lastReviewedAt omitted is accepted with 200', async () => {
    const state = JSON.stringify({
      itemId: 'word_1',
      itemType: 'word',
      nextReviewAt: '2026-01-04T09:00:00.000Z',
      schemaVersion: 3,
    });
    const res = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({ lastReviewedAt: null, stateJson: state }),
      },
      res,
      dbOverride: db,
    });
    assert.equal(res.statusCode, 200);
    assert.equal(res.body.ok, true);
  });

  test('mismatched schemaVersion between outer and inner stateJson is rejected with 400', async () => {
    db.calls = [];
    const res = createMockRes();
    const badState = JSON.stringify({
      itemId: 'word_1',
      itemType: 'word',
      nextReviewAt: '2026-01-04T09:00:00.000Z',
      lastReviewedAt: '2026-01-01T09:00:00.000Z',
      schemaVersion: 2, // differs from outer 3
    });
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({ schemaVersion: 3, stateJson: badState }),
      },
      res,
      dbOverride: db,
    });
    assert.equal(res.statusCode, 400);
    assert.equal(res.body.error, 'INVALID_ARGUMENT');
    assert.equal(db.callCount, 0);
  });

  test('unsupported schemaVersion is rejected with 400 without DB call', async () => {
    for (const v of [0, 4, -1, 999]) {
      db.calls = [];
      const res = createMockRes();
      await handleMutateReviewState({
        req: {
          method: 'POST',
          headers: { 'x-appwrite-user-id': 'alice' },
          body: makeValidPayload({ schemaVersion: v }),
        },
        res,
        dbOverride: db,
      });
      assert.equal(res.statusCode, 400);
      assert.equal(res.body.error, 'INVALID_ARGUMENT');
      assert.equal(db.callCount, 0);
    }
  });
});

describe('mutateReviewState: Authentication & Security', () => {
  let db;
  let logs;
  let errors;

  beforeEach(() => {
    db = new InMemTablesDB();
    logs = [];
    errors = [];
  });

  test('unauthenticated request rejected with 401', async () => {
    const res = createMockRes();
    await handleMutateReviewState({
      req: { method: 'POST', headers: {}, body: makeValidPayload() },
      res,
      error: (e) => errors.push(e),
      dbOverride: db,
    });
    assert.equal(res.statusCode, 401);
    assert.equal(res.body.error, 'UNAUTHENTICATED');
  });

  test('malformed authentication context rejected with 401', async () => {
    const res = createMockRes();
    await handleMutateReviewState({
      req: { method: 'POST', headers: { 'x-appwrite-user-id': '   ' }, body: makeValidPayload() },
      res,
      error: (e) => errors.push(e),
      dbOverride: db,
    });
    assert.equal(res.statusCode, 401);
    assert.equal(res.body.error, 'UNAUTHENTICATED');
  });

  test('body userId cannot impersonate another user (rejected with 403)', async () => {
    const res = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({ userId: 'bob' }),
      },
      res,
      error: (e) => errors.push(e),
      dbOverride: db,
    });
    assert.equal(res.statusCode, 403);
    assert.equal(res.body.error, 'FORBIDDEN');
  });

  test('authenticated user can upsert their own state with owner-only permissions', async () => {
    const res = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload(),
      },
      res,
      log: (m) => logs.push(m),
      error: (e) => errors.push(e),
      dbOverride: db,
    });
    assert.equal(res.statusCode, 200);
    assert.equal(res.body.ok, true);

    const hashedId = rowIdFor('alice', 'word_1');
    assert.equal(res.body.rowId, hashedId);

    const doc = await db.getRow('olitun_db', 'review_states', hashedId);
    assert.equal(doc.userId, 'alice');
    assert.equal(doc.itemId, 'word_1');
    assert.deepEqual(doc.$permissions, [
      'read("user:alice")',
    ]);
    assert.equal(doc.$permissions.some((p) => p.includes('update') || p.includes('delete')), false);
  });

  test('upsert on an existing row normalizes stale over-privileged permissions to owner read-only', async () => {
    const hashedId = rowIdFor('alice', 'word_1');
    // Pre-create row with legacy over-privileged permissions (update, delete)
    await db.createRow(
      'olitun_db',
      'review_states',
      hashedId,
      {
        userId: 'alice',
        itemId: 'word_1',
        itemType: 'word',
        nextReviewAt: '2026-01-02T09:00:00.000Z',
        schemaVersion: 3,
        stateJson: JSON.stringify({ itemId: 'word_1', itemType: 'word', nextReviewAt: '2026-01-02T09:00:00.000Z', schemaVersion: 3 }),
      },
      ['read("user:alice")', 'update("user:alice")', 'delete("user:alice")'],
    );

    const res = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({ itemId: 'word_1' }),
      },
      res,
      dbOverride: db,
    });
    assert.equal(res.statusCode, 200);

    const updated = await db.getRow('olitun_db', 'review_states', hashedId);
    assert.deepEqual(updated.$permissions, ['read("user:alice")']);
    assert.equal(updated.$permissions.some((p) => p.includes('update') || p.includes('delete')), false);
  });

  test('repeated upsert is idempotent (updates existing row without error)', async () => {
    const req = {
      method: 'POST',
      headers: { 'x-appwrite-user-id': 'alice' },
      body: makeValidPayload(),
    };
    const res1 = createMockRes();
    await handleMutateReviewState({ req, res: res1, dbOverride: db });
    assert.equal(res1.statusCode, 200);

    // Second upsert with updated recall count
    const updatedPayload = makeValidPayload({
      stateJson: JSON.stringify({
        itemId: 'word_1',
        itemType: 'word',
        nextReviewAt: '2026-01-04T09:00:00.000Z',
        lastReviewedAt: '2026-01-01T09:00:00.000Z',
        schemaVersion: 3,
        successfulRecalls: 5,
      }),
    });
    const res2 = createMockRes();
    await handleMutateReviewState({
      req: { ...req, body: updatedPayload },
      res: res2,
      dbOverride: db,
    });
    assert.equal(res2.statusCode, 200);

    const hashedId = rowIdFor('alice', 'word_1');
    const doc = await db.getRow('olitun_db', 'review_states', hashedId);
    assert.equal(JSON.parse(doc.stateJson).successfulRecalls, 5);
  });

  test('delete is idempotent (succeeds whether document exists or not)', async () => {
    // Delete non-existent item -> 200 ok
    const res1 = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: { action: 'delete', itemId: 'word_999' },
      },
      res: res1,
      dbOverride: db,
    });
    assert.equal(res1.statusCode, 200);
    assert.equal(res1.body.deleted, true);

    // Upsert an item, then delete it -> 200 ok, item removed
    const resUpsert = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload(),
      },
      res: resUpsert,
      dbOverride: db,
    });
    const hashedId = rowIdFor('alice', 'word_1');
    assert.ok(await db.getRow('olitun_db', 'review_states', hashedId));

    const res2 = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: { action: 'delete', itemId: 'word_1' },
      },
      res: res2,
      dbOverride: db,
    });
    assert.equal(res2.statusCode, 200);
    await assert.rejects(
      async () => db.getRow('olitun_db', 'review_states', hashedId),
      /not found/,
    );
  });

  test('API key and sensitive request headers never appear in logs', async () => {
    const loggedLines = [];
    const res = createMockRes();
    const fakeSecret = 'SECRET_APPWRITE_API_KEY_12345';
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: {
          'x-appwrite-user-id': 'alice',
          authorization: `Bearer ${fakeSecret}`,
          'x-appwrite-key': fakeSecret,
        },
        body: makeValidPayload(),
      },
      res,
      log: (msg) => loggedLines.push(msg),
      error: (msg) => loggedLines.push(msg),
      dbOverride: db,
    });
    assert.equal(res.statusCode, 200);
    for (const line of loggedLines) {
      assert.ok(!line.includes(fakeSecret), `Found secret leaked in log line: ${line}`);
    }
  });
});

describe('mutateReviewState: Legacy Row ID Migration', () => {
  let db;

  beforeEach(() => {
    db = new InMemTablesDB();
  });

  const t0 = '2026-01-01T09:00:00.000Z';
  const t1 = '2026-01-02T09:00:00.000Z';
  const t2 = '2026-01-03T09:00:00.000Z';

  test('legacy row only: migrated to new hashed row ID and legacy row deleted after persistence', async () => {
    const legacyId = legacyRowIdFor('alice', 'word_1');
    const hashedId = rowIdFor('alice', 'word_1');

    // Pre-create legacy row
    await db.createRow(
      'olitun_db',
      'review_states',
      legacyId,
      {
        userId: 'alice',
        itemId: 'word_1',
        itemType: 'word',
        stateJson: JSON.stringify({
          itemId: 'word_1',
          itemType: 'word',
          nextReviewAt: t1,
          lastReviewedAt: t1,
          schemaVersion: 2,
          successfulRecalls: 10,
        }),
        nextReviewAt: t1,
        lastReviewedAt: t1,
        schemaVersion: 2,
      },
      ['read("user:alice")', 'update("user:alice")', 'delete("user:alice")'],
    );

    const res = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({
          itemId: 'word_1',
          itemType: 'word',
          nextReviewAt: t2,
          lastReviewedAt: t2,
          schemaVersion: 3,
          stateJson: JSON.stringify({
            itemId: 'word_1',
            itemType: 'word',
            nextReviewAt: t2,
            lastReviewedAt: t2,
            schemaVersion: 3,
            successfulRecalls: 11,
          }),
        }),
      },
      res,
      dbOverride: db,
    });

    assert.equal(res.statusCode, 200);
    assert.equal(res.body.migratedLegacy, true);

    // Hashed row now exists
    const newDoc = await db.getRow('olitun_db', 'review_states', hashedId);
    assert.equal(newDoc.userId, 'alice');
    assert.equal(JSON.parse(newDoc.stateJson).successfulRecalls, 11);

    // Legacy row was deleted
    await assert.rejects(
      async () => db.getRow('olitun_db', 'review_states', legacyId),
      /not found/,
    );
  });

  test('both rows exist with legacy newer: legacy whole-state wins and legacy row deleted', async () => {
    const legacyId = legacyRowIdFor('alice', 'word_1');
    const hashedId = rowIdFor('alice', 'word_1');

    // Legacy row has newer timestamp (t2)
    await db.createRow(
      'olitun_db',
      'review_states',
      legacyId,
      {
        userId: 'alice',
        itemId: 'word_1',
        itemType: 'word',
        stateJson: JSON.stringify({
          itemId: 'word_1',
          itemType: 'word',
          nextReviewAt: t2,
          lastReviewedAt: t2,
          schemaVersion: 2,
          successfulRecalls: 99,
        }),
        nextReviewAt: t2,
        lastReviewedAt: t2,
        schemaVersion: 2,
      },
      ['read("user:alice")'],
    );

    // Hashed row has older timestamp (t0)
    await db.createRow(
      'olitun_db',
      'review_states',
      hashedId,
      {
        userId: 'alice',
        itemId: 'word_1',
        itemType: 'word',
        stateJson: JSON.stringify({
          itemId: 'word_1',
          itemType: 'word',
          nextReviewAt: t0,
          lastReviewedAt: t0,
          schemaVersion: 3,
          successfulRecalls: 5,
        }),
        nextReviewAt: t0,
        lastReviewedAt: t0,
        schemaVersion: 3,
      },
      ['read("user:alice")'],
    );

    const res = createMockRes();
    // Incoming request has intermediate timestamp (t1)
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({
          itemId: 'word_1',
          itemType: 'word',
          nextReviewAt: t1,
          lastReviewedAt: t1,
          schemaVersion: 3,
          stateJson: JSON.stringify({
            itemId: 'word_1',
            itemType: 'word',
            nextReviewAt: t1,
            lastReviewedAt: t1,
            schemaVersion: 3,
            successfulRecalls: 15,
          }),
        }),
      },
      res,
      dbOverride: db,
    });

    assert.equal(res.statusCode, 200);

    // Hashed row contains the newer legacy state (99 recalls)
    const doc = await db.getRow('olitun_db', 'review_states', hashedId);
    assert.equal(JSON.parse(doc.stateJson).successfulRecalls, 99);

    // Legacy row is deleted
    await assert.rejects(
      async () => db.getRow('olitun_db', 'review_states', legacyId),
      /not found/,
    );
  });

  test('both rows exist with hashed newer: hashed state kept and legacy row deleted', async () => {
    const legacyId = legacyRowIdFor('alice', 'word_1');
    const hashedId = rowIdFor('alice', 'word_1');

    // Legacy row has older timestamp (t0)
    await db.createRow('olitun_db', 'review_states', legacyId, {
      userId: 'alice',
      itemId: 'word_1',
      itemType: 'word',
      stateJson: JSON.stringify({
        itemId: 'word_1',
        itemType: 'word',
        nextReviewAt: t0,
        lastReviewedAt: t0,
        schemaVersion: 2,
        successfulRecalls: 5,
      }),
      nextReviewAt: t0,
      lastReviewedAt: t0,
      schemaVersion: 2,
    });

    // Hashed row has newer timestamp (t2)
    await db.createRow('olitun_db', 'review_states', hashedId, {
      userId: 'alice',
      itemId: 'word_1',
      itemType: 'word',
      stateJson: JSON.stringify({
        itemId: 'word_1',
        itemType: 'word',
        nextReviewAt: t2,
        lastReviewedAt: t2,
        schemaVersion: 3,
        successfulRecalls: 77,
      }),
      nextReviewAt: t2,
      lastReviewedAt: t2,
      schemaVersion: 3,
    });

    const res = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({
          itemId: 'word_1',
          itemType: 'word',
          nextReviewAt: t1,
          lastReviewedAt: t1,
          schemaVersion: 3,
          stateJson: JSON.stringify({
            itemId: 'word_1',
            itemType: 'word',
            nextReviewAt: t1,
            lastReviewedAt: t1,
            schemaVersion: 3,
            successfulRecalls: 10,
          }),
        }),
      },
      res,
      dbOverride: db,
    });

    assert.equal(res.statusCode, 200);
    const doc = await db.getRow('olitun_db', 'review_states', hashedId);
    assert.equal(JSON.parse(doc.stateJson).successfulRecalls, 77);

    // Legacy row deleted
    await assert.rejects(
      async () => db.getRow('olitun_db', 'review_states', legacyId),
      /not found/,
    );
  });

  test('equal timestamps prefer hashed row', async () => {
    const legacyId = legacyRowIdFor('alice', 'word_1');
    const hashedId = rowIdFor('alice', 'word_1');

    await db.createRow('olitun_db', 'review_states', legacyId, {
      userId: 'alice',
      itemId: 'word_1',
      itemType: 'word',
      stateJson: JSON.stringify({
        itemId: 'word_1',
        itemType: 'word',
        nextReviewAt: t1,
        lastReviewedAt: t1,
        schemaVersion: 2,
        source: 'legacy',
      }),
      nextReviewAt: t1,
      lastReviewedAt: t1,
      schemaVersion: 2,
    });

    await db.createRow('olitun_db', 'review_states', hashedId, {
      userId: 'alice',
      itemId: 'word_1',
      itemType: 'word',
      stateJson: JSON.stringify({
        itemId: 'word_1',
        itemType: 'word',
        nextReviewAt: t1,
        lastReviewedAt: t1,
        schemaVersion: 3,
        source: 'hashed',
      }),
      nextReviewAt: t1,
      lastReviewedAt: t1,
      schemaVersion: 3,
    });

    const res = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({
          itemId: 'word_1',
          itemType: 'word',
          nextReviewAt: t0,
          lastReviewedAt: t0,
          schemaVersion: 3,
          stateJson: JSON.stringify({
            itemId: 'word_1',
            itemType: 'word',
            nextReviewAt: t0,
            lastReviewedAt: t0,
            schemaVersion: 3,
            source: 'incoming',
          }),
        }),
      },
      res,
      dbOverride: db,
    });

    assert.equal(res.statusCode, 200);
    const doc = await db.getRow('olitun_db', 'review_states', hashedId);
    assert.equal(JSON.parse(doc.stateJson).source, 'hashed');
  });

  test('new-row write fails: legacy row remains intact and is NEVER deleted', async () => {
    const legacyId = legacyRowIdFor('alice', 'word_1');
    await db.createRow('olitun_db', 'review_states', legacyId, {
      userId: 'alice',
      itemId: 'word_1',
      itemType: 'word',
      stateJson: JSON.stringify({
        itemId: 'word_1',
        itemType: 'word',
        nextReviewAt: t1,
        lastReviewedAt: t1,
        schemaVersion: 2,
        source: 'precious_data',
      }),
      nextReviewAt: t1,
      lastReviewedAt: t1,
      schemaVersion: 2,
    });

    db.failNextCreate = true; // Simulate write failure

    const res = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({
          itemId: 'word_1',
          itemType: 'word',
          nextReviewAt: t2,
          lastReviewedAt: t2,
          schemaVersion: 3,
          stateJson: JSON.stringify({
            itemId: 'word_1',
            itemType: 'word',
            nextReviewAt: t2,
            lastReviewedAt: t2,
            schemaVersion: 3,
            source: 'new_attempt',
          }),
        }),
      },
      res,
      dbOverride: db,
    });

    assert.equal(res.statusCode, 500);

    // Legacy row MUST still be there intact!
    const legacy = await db.getRow('olitun_db', 'review_states', legacyId);
    assert.equal(JSON.parse(legacy.stateJson).source, 'precious_data');
  });

  test('delete legacy row failure logs warning and permits safe retry', async () => {
    const legacyId = legacyRowIdFor('alice', 'word_1');
    const hashedId = rowIdFor('alice', 'word_1');

    await db.createRow('olitun_db', 'review_states', legacyId, {
      userId: 'alice',
      itemId: 'word_1',
      itemType: 'word',
      stateJson: JSON.stringify({
        itemId: 'word_1',
        itemType: 'word',
        nextReviewAt: t1,
        lastReviewedAt: t1,
        schemaVersion: 2,
      }),
      nextReviewAt: t1,
      lastReviewedAt: t1,
      schemaVersion: 2,
    });

    db.failNextDelete = true; // Legacy delete will fail

    const logMessages = [];
    const res = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': 'alice' },
        body: makeValidPayload({
          itemId: 'word_1',
          itemType: 'word',
          nextReviewAt: t2,
          lastReviewedAt: t2,
          schemaVersion: 3,
          stateJson: JSON.stringify({
            itemId: 'word_1',
            itemType: 'word',
            nextReviewAt: t2,
            lastReviewedAt: t2,
            schemaVersion: 3,
          }),
        }),
      },
      res,
      log: (m) => logMessages.push(m),
      dbOverride: db,
    });

    // Upsert succeeded because new row was persisted
    assert.equal(res.statusCode, 200);
    assert.ok(await db.getRow('olitun_db', 'review_states', hashedId));
    assert.ok(logMessages.some((m) => m.includes('failure deleting migrated legacy row')));
  });

  test('migration is idempotent: multiple runs leave exactly 1 row and 0 duplicates', async () => {
    const legacyId = legacyRowIdFor('alice', 'word_1');
    const hashedId = rowIdFor('alice', 'word_1');

    await db.createRow('olitun_db', 'review_states', legacyId, {
      userId: 'alice',
      itemId: 'word_1',
      itemType: 'word',
      stateJson: JSON.stringify({
        itemId: 'word_1',
        itemType: 'word',
        nextReviewAt: t1,
        lastReviewedAt: t1,
        schemaVersion: 2,
        score: 10,
      }),
      nextReviewAt: t1,
      lastReviewedAt: t1,
      schemaVersion: 2,
    });

    const run = async () => {
      const res = createMockRes();
      await handleMutateReviewState({
        req: {
          method: 'POST',
          headers: { 'x-appwrite-user-id': 'alice' },
          body: makeValidPayload({
            itemId: 'word_1',
            itemType: 'word',
            nextReviewAt: t2,
            lastReviewedAt: t2,
            schemaVersion: 3,
            stateJson: JSON.stringify({
              itemId: 'word_1',
              itemType: 'word',
              nextReviewAt: t2,
              lastReviewedAt: t2,
              schemaVersion: 3,
              score: 20,
            }),
          }),
        },
        res,
        dbOverride: db,
      });
      return res;
    };

    const res1 = await run();
    assert.equal(res1.statusCode, 200);
    const res2 = await run();
    assert.equal(res2.statusCode, 200);

    const docs = (await db.listRows('olitun_db', 'review_states')).rows;
    assert.equal(docs.length, 1);
    assert.equal(docs[0].$id, hashedId);
  });

  test('isValidAppwriteRowId correctly validates Appwrite UID rules', () => {
    assert.equal(isValidAppwriteRowId(''), false);
    assert.equal(isValidAppwriteRowId(null), false);
    assert.equal(isValidAppwriteRowId(undefined), false);
    assert.equal(isValidAppwriteRowId('_leading_underscore'), false);
    assert.equal(isValidAppwriteRowId('a'.repeat(37)), false);
    assert.equal(isValidAppwriteRowId('a'.repeat(36)), true);
    assert.equal(isValidAppwriteRowId('valid_uid_123'), true);
    assert.equal(isValidAppwriteRowId('valid.uid-123'), true);
    assert.equal(isValidAppwriteRowId('invalid spaces in id'), false);
  });

  test('delete and upsert succeed safely when legacyRowId exceeds 36 chars', async () => {
    const longUserId = 'u'.repeat(25);
    const longItemId = 'word_long_item_id_12345';
    const legacyId = legacyRowIdFor(longUserId, longItemId);
    assert.ok(legacyId.length > 36, 'Legacy ID must exceed 36 chars');

    // Upsert with long IDs
    const upsertRes = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': longUserId },
        body: makeValidPayload({
          itemId: longItemId,
          itemType: 'word',
          nextReviewAt: t1,
          lastReviewedAt: t1,
          schemaVersion: 3,
        }),
      },
      res: upsertRes,
      dbOverride: db,
    });
    assert.equal(upsertRes.statusCode, 200);
    const expectedHashedId = rowIdFor(longUserId, longItemId);
    assert.equal(upsertRes.body.rowId, expectedHashedId);

    // Delete with long IDs
    const deleteRes = createMockRes();
    await handleMutateReviewState({
      req: {
        method: 'POST',
        headers: { 'x-appwrite-user-id': longUserId },
        body: {
          action: 'delete',
          itemId: longItemId,
        },
      },
      res: deleteRes,
      dbOverride: db,
    });
    assert.equal(deleteRes.statusCode, 200);
    assert.equal(deleteRes.body.ok, true);
  });
});
