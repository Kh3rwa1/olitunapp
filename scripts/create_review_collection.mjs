#!/usr/bin/env node
/**
 * Creates the `review_states` Appwrite table for cloud-backed review state
 * (per-user item-level memory scheduler state).
 *
 * VERIFIED against Appwrite Cloud (TablesDB API v2, sgp) on 2026-09-14.
 * Run once per environment (staging/production):
 *   APPWRITE_API_KEY=... node scripts/create_review_collection.mjs
 *
 * Schema (olitun_db / review_states):
 *  - userId            string 80, required    (owner identity)
 *  - itemId            string 120, required   (content item identity)
 *  - itemType          enum(word|sentence)    (scheduler item kind)
 *  - stateJson         string 8192, required  (full scheduler state)
 *  - nextReviewAt      datetime, required     (due queries)
 *  - lastReviewedAt    datetime, optional     (conflict resolution LWW)
 *  - schemaVersion     integer, optional, default 2 (future migrations;
 *                      required columns cannot carry defaults on this API)
 *
 * API notes (this server version):
 *  - Columns are created via TYPE-SPECIFIC routes:
 *      POST /tablesdb/{db}/tables/{table}/columns/{string|enum|datetime|integer}
 *    (a generic POST .../columns does NOT exist — returns HTML 404).
 *  - Indexes take a `columns` param (not `attributes`).
 *  - Column create returns 202 (processing); poll until status=available
 *    before creating indexes.
 *
 * Document ID: `${userId}__${itemId}` (sanitized) — Appwrite's unique-ID
 * constraint is the duplicate-prevention mechanism (verified: duplicate
 * create -> 409 row_already_exists); pushes are idempotent
 * (create -> 409 -> update with `{"data":{...}}` wrapper, permissions preserved).
 *
 * Permissions: collection-level none; every row gets explicit
 * `user:{userId}` read/update/delete — a user can never read or modify
 * another user's review state. Admin/CMS is not granted here.
 */

const ENDPOINT =
  process.env.APPWRITE_ENDPOINT || 'https://sgp.cloud.appwrite.io/v1';
const PROJECT_ID = process.env.APPWRITE_PROJECT_ID;
const API_KEY = process.env.APPWRITE_API_KEY;
const DB = 'olitun_db';
const COLLECTION = 'review_states';

if (!API_KEY) {
  console.error('APPWRITE_API_KEY is required');
  process.exit(1);
}

async function call(method, path, body) {
  const res = await fetch(`${ENDPOINT}${path}`, {
    method,
    headers: {
      'X-Appwrite-Project': PROJECT_ID,
      'X-Appwrite-Key': API_KEY,
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`${method} ${path} -> ${res.status}: ${text.slice(0, 300)}`);
  }
  return res.status === 204 ? null : res.json();
}

async function existingColumnKeys() {
  const table = await call('GET', `/tablesdb/${DB}/tables/${COLLECTION}`);
  return new Set((table.columns ?? []).map((c) => c.key));
}

async function createColumn(type, attr, existing) {
  if (existing.has(attr.key)) {
    console.log(`  column ${attr.key}: already exists (skip)`);
    return;
  }
  try {
    await call(
      'POST',
      `/tablesdb/${DB}/tables/${COLLECTION}/columns/${type}`,
      attr
    );
    console.log(`  column ${attr.key}: created`);
  } catch (e) {
    // Some servers report re-creates of large columns as
    // column_limit_exceeded instead of 409; treat as existing.
    if (String(e).includes('409') || String(e).includes('column_limit_exceeded')) {
      console.log(`  column ${attr.key}: already exists (skip)`);
    } else {
      throw e;
    }
  }
}

async function createIndex(index) {
  try {
    await call(
      'POST',
      `/tablesdb/${DB}/tables/${COLLECTION}/indexes`,
      index
    );
    console.log(`  index ${index.key}: created`);
  } catch (e) {
    if (String(e).includes('409')) {
      console.log(`  index ${index.key}: already exists (skip)`);
    } else {
      throw e;
    }
  }
}

async function waitColumnsAvailable() {
  for (let i = 0; i < 60; i++) {
    const table = await call(
      'GET',
      `/tablesdb/${DB}/tables/${COLLECTION}`
    );
    const cols = table.columns ?? [];
    const pending = cols.filter((c) => c.status !== 'available');
    if (cols.length >= 7 && pending.length === 0) {
      console.log(`  all ${cols.length} columns available`);
      return;
    }
    await new Promise((r) => setTimeout(r, 5000));
  }
  throw new Error('columns did not become available in time');
}

async function main() {
  // 1. Table (owner-only defaults; rows carry explicit user perms).
  try {
    await call('POST', `/tablesdb/${DB}/tables`, {
      databaseId: DB,
      tableId: COLLECTION,
      name: 'Review States',
      permissions: [],
      rowSecurity: true,
    });
    console.log(`table ${COLLECTION}: created`);
  } catch (e) {
    if (String(e).includes('409')) {
      console.log(`table ${COLLECTION}: already exists (skip)`);
    } else {
      throw e;
    }
  }

  // 2. Columns (type-specific routes; skip ones that already exist).
  const existing = await existingColumnKeys();
  await createColumn('string', { key: 'userId', size: 80, required: true }, existing);
  await createColumn('string', { key: 'itemId', size: 120, required: true }, existing);
  await createColumn('enum', {
    key: 'itemType',
    elements: ['word', 'sentence'],
    required: true,
  }, existing);
  await createColumn('string', { key: 'stateJson', size: 8192, required: true }, existing);
  await createColumn('datetime', { key: 'nextReviewAt', required: true }, existing);
  await createColumn('datetime', { key: 'lastReviewedAt', required: false }, existing);
  await createColumn('integer', {
    key: 'schemaVersion',
    required: false,
    default: 2,
  }, existing);

  // 3. Wait for schema to settle, then index.
  await waitColumnsAvailable();
  await createIndex({
    key: 'idx_user_nextReview',
    type: 'key',
    columns: ['userId', 'nextReviewAt'],
    orders: ['ASC', 'ASC'],
  });
  await createIndex({
    key: 'idx_user_lastReviewed',
    type: 'key',
    columns: ['userId', 'lastReviewedAt'],
    orders: ['ASC', 'DESC'],
  });

  console.log(`\n${COLLECTION} ready.`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
