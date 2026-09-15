#!/usr/bin/env node
/**
 * Creates and verifies the `review_states` Appwrite table for cloud-backed review state
 * (per-user item-level memory scheduler state).
 *
 * Supports:
 *   --apply: Idempotently creates/updates table, columns, indexes, permissions, row security.
 *   --verify-only: Strictly read-only verification (GET only) with deep drift detection.
 *   --confirm-prod: Required when targeting production endpoints.
 *
 * Run once per environment (staging/production):
 *   APPWRITE_API_KEY=... node scripts/create_review_collection.mjs --apply
 *   APPWRITE_API_KEY=... node scripts/create_review_collection.mjs --verify-only
 */

import { readFileSync } from 'node:fs';
import {
  REVIEW_TABLE_SPEC,
  REVIEW_COLUMNS_SPEC,
  REVIEW_INDEXES_SPEC,
  REVIEW_SCHEMA_LIMITS,
} from '../functions/mutateReviewState/src/review_schema_contract.js';

export const TABLE_SPEC = REVIEW_TABLE_SPEC;
export const COLUMNS_SPEC = REVIEW_COLUMNS_SPEC;
export const INDEXES_SPEC = REVIEW_INDEXES_SPEC;
export { REVIEW_SCHEMA_LIMITS };

export function maskSecret(secret) {
  if (!secret) return '(not set)';
  if (secret.length <= 8) return '********';
  return `${secret.slice(0, 4)}...${secret.slice(-4)}`;
}

function readProjectIdFromConfig() {
  try {
    const raw = readFileSync(new URL('../appwrite.config.json', import.meta.url), 'utf8');
    return JSON.parse(raw).projectId || '';
  } catch (_) {
    return '';
  }
}

export function createApiClient({ endpoint, projectId, apiKey, verifyOnly = false }) {
  async function call(method, path, body = null) {
    if (verifyOnly && method !== 'GET') {
      throw new Error(`Forbidden mutating request in verify-only mode: ${method} ${path}`);
    }

    const headers = {
      'X-Appwrite-Project': projectId,
      'X-Appwrite-Key': apiKey,
      'Content-Type': 'application/json',
    };

    const res = await fetch(`${endpoint}${path}`, {
      method,
      headers,
      body: body ? JSON.stringify(body) : undefined,
    });

    if (res.status === 404) {
      return null;
    }

    if (!res.ok) {
      const text = await res.text();
      const err = new Error(`${method} ${path} -> ${res.status}: ${text.slice(0, 300)}`);
      err.status = res.status;
      err.responseBody = text;
      throw err;
    }

    return res.status === 204 ? null : res.json();
  }

  return {
    get: (path) => call('GET', path),
    post: (path, body) => call('POST', path, body),
    put: (path, body) => call('PUT', path, body),
    patch: (path, body) => call('PATCH', path, body),
    delete: (path) => call('DELETE', path),
  };
}

export async function verifyTable(api, { db = 'olitun_db', tableId = 'review_states' } = {}) {
  const drifts = [];

  // 1. Verify database exists
  const database = await api.get(`/tablesdb/${db}`);
  if (!database) {
    drifts.push(`Database "${db}" does not exist.`);
    return { ok: false, databaseMissing: true, tableMissing: true, drifts };
  }

  // 2. Verify table exists
  const table = await api.get(`/tablesdb/${db}/tables/${tableId}`);
  if (!table) {
    drifts.push(`Table "${tableId}" does not exist.`);
    return { ok: false, databaseMissing: false, tableMissing: true, drifts };
  }

  // 3. Verify table permissions
  const remotePerms = Array.isArray(table.permissions) ? table.permissions : [];
  const expectedPerms = TABLE_SPEC.permissions;
  const hasExpectedPerms =
    remotePerms.length === expectedPerms.length &&
    expectedPerms.every((p) => remotePerms.includes(p));

  // Ensure zero anonymous/public permissions
  const hasInsecurePerms = remotePerms.some((p) =>
    p.includes('any') || p.includes('guest') || (p.includes('users') && !p.startsWith('create('))
  );

  if (!hasExpectedPerms || hasInsecurePerms) {
    drifts.push(
      `Table permissions drift: expected ${JSON.stringify(expectedPerms)}, got ${JSON.stringify(remotePerms)}`
    );
  }

  // 4. Verify row security
  if (table.rowSecurity !== true) {
    drifts.push(`Table rowSecurity drift: expected true, got ${table.rowSecurity}`);
  }

  // 5. Verify columns
  const remoteCols = Array.isArray(table.columns) ? table.columns : [];
  const remoteColMap = new Map(remoteCols.map((c) => [c.key, c]));

  for (const expected of COLUMNS_SPEC) {
    const remote = remoteColMap.get(expected.key);
    if (!remote) {
      drifts.push(`Missing column: "${expected.key}" (${expected.type})`);
      continue;
    }

    const isEnumMatch =
      expected.type.toLowerCase() === 'enum' &&
      (remote.type?.toLowerCase() === 'enum' ||
        (remote.type?.toLowerCase() === 'string' && Array.isArray(remote.elements)));

    if (!isEnumMatch && remote.type?.toLowerCase() !== expected.type.toLowerCase()) {
      drifts.push(
        `Column "${expected.key}" type drift: expected "${expected.type}", got "${remote.type}"`
      );
    }

    if (Boolean(remote.required) !== expected.required) {
      drifts.push(
        `Column "${expected.key}" required drift: expected ${expected.required}, got ${remote.required}`
      );
    }

    if (expected.size !== undefined && remote.size !== expected.size) {
      drifts.push(
        `Column "${expected.key}" size drift: expected ${expected.size}, got ${remote.size}`
      );
    }

    if (expected.elements) {
      const expectedElements = [...expected.elements].sort();
      const remoteElements = [...(remote.elements || [])].sort();
      if (JSON.stringify(expectedElements) !== JSON.stringify(remoteElements)) {
        drifts.push(
          `Column "${expected.key}" enum elements drift: expected ${JSON.stringify(expectedElements)}, got ${JSON.stringify(remoteElements)}`
        );
      }
    }

    if (expected.default !== undefined) {
      if (remote.default != expected.default) {
        drifts.push(
          `Column "${expected.key}" default drift: expected ${expected.default}, got ${remote.default}`
        );
      }
    }
  }

  // Check extra columns
  const expectedColKeys = new Set(COLUMNS_SPEC.map((c) => c.key));
  for (const col of remoteCols) {
    if (!expectedColKeys.has(col.key)) {
      drifts.push(`Unexpected extra column found: "${col.key}"`);
    }
  }

  // 6. Verify indexes
  let remoteIndexes = Array.isArray(table.indexes) ? table.indexes : null;
  if (!remoteIndexes) {
    const indexesRes = await api.get(`/tablesdb/${db}/tables/${tableId}/indexes`);
    remoteIndexes = Array.isArray(indexesRes?.indexes) ? indexesRes.indexes : [];
  }
  const remoteIndexMap = new Map(remoteIndexes.map((i) => [i.key, i]));

  for (const expected of INDEXES_SPEC) {
    const remote = remoteIndexMap.get(expected.key);
    if (!remote) {
      drifts.push(`Missing index: "${expected.key}"`);
      continue;
    }

    if (remote.type?.toLowerCase() !== expected.type.toLowerCase()) {
      drifts.push(
        `Index "${expected.key}" type drift: expected "${expected.type}", got "${remote.type}"`
      );
    }

    if (JSON.stringify(remote.columns) !== JSON.stringify(expected.columns)) {
      drifts.push(
        `Index "${expected.key}" columns drift: expected ${JSON.stringify(expected.columns)}, got ${JSON.stringify(remote.columns)}`
      );
    }

    if (JSON.stringify(remote.orders) !== JSON.stringify(expected.orders)) {
      drifts.push(
        `Index "${expected.key}" orders drift: expected ${JSON.stringify(expected.orders)}, got ${JSON.stringify(remote.orders)}`
      );
    }
  }

  return {
    ok: drifts.length === 0,
    databaseMissing: false,
    tableMissing: false,
    drifts,
    table,
    columns: remoteCols,
    indexes: remoteIndexes,
  };
}

export async function waitColumnsAvailable(
  api,
  { db = 'olitun_db', tableId = 'review_states', maxWaitMs = 60000, intervalMs = 1000 } = {}
) {
  const startTime = Date.now();
  while (Date.now() - startTime < maxWaitMs) {
    const table = await api.get(`/tablesdb/${db}/tables/${tableId}`);
    if (table) {
      const cols = table.columns || [];
      const pending = cols.filter((c) => c.status !== 'available');
      if (cols.length >= COLUMNS_SPEC.length && pending.length === 0) {
        return;
      }
    }
    await new Promise((r) => setTimeout(r, intervalMs));
  }
  throw new Error(`Columns did not become available within timeout of ${maxWaitMs}ms`);
}

export async function applyTable(
  api,
  {
    db = 'olitun_db',
    tableId = 'review_states',
    pollTimeoutMs = 60000,
    pollIntervalMs = 1000,
  } = {}
) {
  // 1. Verify database exists
  const database = await api.get(`/tablesdb/${db}`);
  if (!database) {
    throw new Error(`Target database "${db}" does not exist. Cannot apply review_states schema.`);
  }

  // 2. Table creation or update
  let table = await api.get(`/tablesdb/${db}/tables/${tableId}`);
  if (!table) {
    console.log(`Creating table ${tableId}...`);
    try {
      table = await api.post(`/tablesdb/${db}/tables`, {
        databaseId: db,
        tableId: tableId,
        name: TABLE_SPEC.name,
        permissions: TABLE_SPEC.permissions,
        rowSecurity: TABLE_SPEC.rowSecurity,
      });
      console.log(`  table ${tableId}: created`);
    } catch (e) {
      if (String(e).includes('409') || e.status === 409) {
        console.log(`  table ${tableId}: already exists (409)`);
        table = await api.get(`/tablesdb/${db}/tables/${tableId}`);
      } else {
        throw e;
      }
    }
  } else {
    // Check permissions and rowSecurity drift
    const remotePerms = Array.isArray(table.permissions) ? table.permissions : [];
    const expectedPerms = TABLE_SPEC.permissions;
    const permsMatch =
      remotePerms.length === expectedPerms.length &&
      expectedPerms.every((p) => remotePerms.includes(p));

    if (!permsMatch || table.rowSecurity !== TABLE_SPEC.rowSecurity) {
      console.log(`Updating table ${tableId} permissions / rowSecurity...`);
      await api.put(`/tablesdb/${db}/tables/${tableId}`, {
        name: TABLE_SPEC.name,
        permissions: TABLE_SPEC.permissions,
        rowSecurity: TABLE_SPEC.rowSecurity,
      });
      console.log(`  table ${tableId}: permissions/rowSecurity updated`);
    }
  }

  // 3. Create missing columns
  const existingCols = new Set((table.columns || []).map((c) => c.key));
  for (const col of COLUMNS_SPEC) {
    if (existingCols.has(col.key)) {
      console.log(`  column ${col.key}: already exists (skip)`);
      if (col.type === 'integer' && col.default !== undefined) {
        const remoteCol = (table.columns || []).find((c) => c.key === col.key);
        if (remoteCol && remoteCol.default != col.default) {
          console.log(`  updating column ${col.key} default to ${col.default}...`);
          try {
            await api.patch(`/tablesdb/${db}/tables/${tableId}/columns/integer/${col.key}`, {
              required: Boolean(col.required),
              default: col.default,
            });
            console.log(`  column ${col.key}: default updated`);
          } catch (e) {
            console.warn(`  failed to update column ${col.key} default: ${e.message}`);
          }
        }
      }
      continue;
    }

    const { type, ...payload } = col;
    try {
      await api.post(`/tablesdb/${db}/tables/${tableId}/columns/${type}`, payload);
      console.log(`  column ${col.key}: created`);
    } catch (e) {
      if (
        String(e).includes('409') ||
        e.status === 409 ||
        String(e).includes('column_limit_exceeded')
      ) {
        console.log(`  column ${col.key}: already exists (skip)`);
      } else {
        throw e;
      }
    }
  }

  // 4. Wait for schema columns to reach available status
  console.log('Waiting for columns to reach available status...');
  await waitColumnsAvailable(api, {
    db,
    tableId,
    maxWaitMs: pollTimeoutMs,
    intervalMs: pollIntervalMs,
  });
  console.log('  all columns available');

  // 5. Create missing indexes
  let existingIndexes = new Set();
  if (Array.isArray(table.indexes)) {
    existingIndexes = new Set(table.indexes.map((i) => i.key));
  } else {
    const idxRes = await api.get(`/tablesdb/${db}/tables/${tableId}/indexes`);
    if (idxRes && Array.isArray(idxRes.indexes)) {
      existingIndexes = new Set(idxRes.indexes.map((i) => i.key));
    }
  }

  for (const index of INDEXES_SPEC) {
    if (existingIndexes.has(index.key)) {
      console.log(`  index ${index.key}: already exists (skip)`);
      continue;
    }

    try {
      await api.post(`/tablesdb/${db}/tables/${tableId}/indexes`, index);
      console.log(`  index ${index.key}: created`);
    } catch (e) {
      if (String(e).includes('409') || e.status === 409) {
        console.log(`  index ${index.key}: already exists (skip)`);
      } else {
        throw e;
      }
    }
  }

  // 6. Post-apply verification
  console.log('\nRunning post-apply verification...');
  const verifyResult = await verifyTable(api, { db, tableId });
  if (!verifyResult.ok) {
    throw new Error(`Post-apply verification failed:\n  - ${verifyResult.drifts.join('\n  - ')}`);
  }
  console.log(`\n${tableId} provisioned and verified successfully.`);
  return verifyResult;
}

export async function run(argv = process.argv.slice(2), env = process.env) {
  const isApply = argv.includes('--apply');
  const isVerifyOnly = argv.includes('--verify-only');
  const isConfirmProd = argv.includes('--confirm-prod');

  if (!isApply && !isVerifyOnly) {
    console.error('Usage: node create_review_collection.mjs [--apply | --verify-only] [--confirm-prod]');
    console.error('Error: Either --apply or --verify-only must be specified.');
    process.exit(1);
  }

  if (isApply && isVerifyOnly) {
    console.error('Error: --apply and --verify-only are mutually exclusive.');
    process.exit(1);
  }

  const endpoint = env.APPWRITE_ENDPOINT || 'https://sgp.cloud.appwrite.io/v1';
  const projectId =
    env.APPWRITE_PROJECT_ID !== undefined
      ? env.APPWRITE_PROJECT_ID
      : readProjectIdFromConfig();
  const apiKey = env.APPWRITE_API_KEY || '';
  const db = env.APPWRITE_DB || 'olitun_db';
  const tableId = env.APPWRITE_COLLECTION || 'review_states';

  if (!apiKey) {
    console.error('Error: APPWRITE_API_KEY is required.');
    process.exit(1);
  }

  if (!projectId) {
    console.error('Error: APPWRITE_PROJECT_ID is required.');
    process.exit(1);
  }

  let isCloudProd = false;
  try {
    const parsedEndpoint = new URL(endpoint);
    isCloudProd =
      parsedEndpoint.hostname === 'cloud.appwrite.io' ||
      parsedEndpoint.hostname.endsWith('.cloud.appwrite.io');
  } catch {
    isCloudProd = false;
  }

  if (isApply && isCloudProd && !isConfirmProd) {
    console.error('Error: Targeting production endpoint requires --confirm-prod flag.');
    process.exit(1);
  }

  console.log('--- Appwrite Review States Configuration ---');
  console.log(`Endpoint:   ${endpoint}`);
  console.log(`Project ID: ${projectId}`);
  console.log(`Database:   ${db}`);
  console.log(`Table:      ${tableId}`);
  console.log(`Mode:       ${isVerifyOnly ? 'VERIFY-ONLY (Read-Only)' : 'APPLY'}`);
  console.log(`API Key:    ${apiKey ? '[CONFIGURED]' : '[MISSING]'}`);
  console.log('--------------------------------------------\n');

  const pollTimeoutMs = parseInt(env.POLL_TIMEOUT_MS || '300000', 10);
  const pollIntervalMs = parseInt(env.POLL_INTERVAL_MS || '1000', 10);

  const api = createApiClient({
    endpoint,
    projectId,
    apiKey,
    verifyOnly: isVerifyOnly,
  });

  if (isVerifyOnly) {
    console.log(`Running deep verification on ${db}.${tableId}...`);
    const result = await verifyTable(api, { db, tableId });
    if (!result.ok) {
      console.error(`\n❌ Drift detected on ${db}.${tableId}:`);
      for (const d of result.drifts) {
        console.error(`  - ${d}`);
      }
      process.exit(1);
    }
    console.log(`\n✅ Schema verified: ${db}.${tableId} matches expected specification exactly (0 drift).`);
    process.exit(0);
  }

  if (isApply) {
    await applyTable(api, {
      db,
      tableId,
      pollTimeoutMs,
      pollIntervalMs,
    });
    process.exit(0);
  }
}

// Only auto-run if executed directly as a script
if (process.argv[1] && process.argv[1].endsWith('create_review_collection.mjs')) {
  run().catch((e) => {
    console.error(`\nOperation failed: ${e.message}`);
    process.exit(1);
  });
}
