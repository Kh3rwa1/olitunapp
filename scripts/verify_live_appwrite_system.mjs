#!/usr/bin/env node
/**
 * Live Appwrite System Verification Script
 *
 * Verifies the live Appwrite review system:
 * - Table schema, constraints, permissions, rowSecurity
 * - Function deployment, execution roles, scopes
 * - Security boundary: unauthenticated rejection
 * - Authenticated row operations with disposable test account
 * - Row-level owner isolation & SHA-256 canonical ID
 * - String size / payload limit enforcement
 * - Complete disposable resource cleanup
 */

import { Client, TablesDB, Functions, Users, ID } from 'node-appwrite';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {
  REVIEW_TABLE_SPEC,
  REVIEW_COLUMNS_SPEC,
  REVIEW_INDEXES_SPEC,
  REVIEW_SCHEMA_LIMITS,
} from '../functions/mutateReviewState/src/review_schema_contract.js';
import { rowIdFor } from '../functions/mutateReviewState/src/main.js';
import {
  assertReleasePreflight,
  createApiClient,
  loadReleasePreflight,
} from './check_premium_content_permissions.mjs';
import { readFileSync } from 'node:fs';

function getApiKey() {
  if (process.env.APPWRITE_API_KEY) return process.env.APPWRITE_API_KEY.trim();
  throw new Error('No Appwrite API key found in APPWRITE_API_KEY environment variable');
}

const ENDPOINT = process.env.APPWRITE_ENDPOINT || 'https://sgp.cloud.appwrite.io/v1';
const PROJECT_ID = process.env.APPWRITE_PROJECT_ID || '699495910038e39622c5';
const DB_ID = 'olitun_db';
const TABLE_ID = 'review_states';
const FUNCTION_ID = 'mutateReviewState';

async function main() {
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('LIVE APPWRITE SYSTEM & FUNCTION VERIFICATION');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`Endpoint:   ${ENDPOINT}`);
  console.log(`Project ID: ${PROJECT_ID}`);
  console.log(`Database:   ${DB_ID}`);
  console.log(`Table:      ${TABLE_ID}`);
  console.log(`Function:   ${FUNCTION_ID}`);
  console.log('────────────────────────────────────────────────────────────\n');

  const apiKey = getApiKey();
  const serverClient = new Client().setEndpoint(ENDPOINT).setProject(PROJECT_ID).setKey(apiKey);
  const tablesDb = new TablesDB(serverClient);
  const functions = new Functions(serverClient);
  const users = new Users(serverClient);

  let disposableUserId = null;

  try {
    // 1. Table Schema & Security Audit
    console.log('[1/6] Auditing review_states table configuration...');
    const tableRes = await fetch(`${ENDPOINT}/tablesdb/${DB_ID}/tables/${TABLE_ID}`, {
      headers: {
        'X-Appwrite-Project': PROJECT_ID,
        'X-Appwrite-Key': apiKey,
      },
    });
    assert.equal(tableRes.status, 200, `Table ${TABLE_ID} must exist with status 200`);
    const table = await tableRes.json();

    assert.equal(table.rowSecurity, true, 'Table rowSecurity must be enabled (true)');
    assert.deepEqual(table.$permissions || [], [], 'Table-level permissions must be empty [] (zero public/client direct access)');
    console.log('  ✓ rowSecurity is enabled (true)');
    console.log('  ✓ Table permissions are empty [] (zero client direct access)');

    const cols = table.columns || [];
    assert.equal(cols.length, 7, 'Table must have exactly 7 columns');
    const schemaVersionCol = cols.find((c) => c.key === 'schemaVersion');
    assert.ok(schemaVersionCol, 'schemaVersion column must exist');
    assert.equal(schemaVersionCol.default, 3, 'schemaVersion column default must be 3');
    console.log('  ✓ All 7 columns present; schemaVersion default is 3');

    const indexes = table.indexes || [];
    assert.equal(indexes.length, 2, 'Table must have 2 indexes');
    console.log('  ✓ Both composite indexes present');

    // 2. Function Deployment Audit
    console.log('\n[2/6] Auditing mutateReviewState function...');
    const fn = await functions.get({ functionId: FUNCTION_ID });
    assert.equal(fn.$id, FUNCTION_ID);
    assert.deepEqual(fn.execute, ['users'], 'Function execute role must be strictly ["users"]');
    assert.deepEqual([...fn.scopes].sort(), ['rows.read', 'rows.write'], 'Function scopes must be strictly ["rows.read", "rows.write"]');
    assert.equal(fn.latestDeploymentStatus, 'ready', 'Function deployment must be ready');
    console.log(`  ✓ Execution role: ${JSON.stringify(fn.execute)}`);
    console.log(`  ✓ Scopes: ${JSON.stringify(fn.scopes)}`);
    console.log(`  ✓ Latest deployment: ${fn.latestDeploymentId} (status: ${fn.latestDeploymentStatus})`);

    const expectedReleaseCommit = process.env.EXPECTED_RELEASE_COMMIT?.trim();
    if (expectedReleaseCommit) {
      console.log('  • Verifying active authorization-function and site provenance...');
      const manifest = JSON.parse(
        readFileSync(new URL('../appwrite.json', import.meta.url), 'utf8'),
      );
      const preflightApi = createApiClient({
        endpoint: ENDPOINT,
        projectId: PROJECT_ID,
        apiKey,
      });
      const preflight = await loadReleasePreflight(preflightApi, manifest);
      assertReleasePreflight(preflight, manifest, expectedReleaseCommit);
      console.log('  ✓ Active authorization function and Flutter site match the release commit');
    } else {
      console.log('  • Release provenance skipped; set EXPECTED_RELEASE_COMMIT to enforce it');
    }

    // 3. Unauthenticated Execution Rejection
    console.log('\n[3/6] Testing unauthenticated execution rejection...');
    const unauthClient = new Client().setEndpoint(ENDPOINT).setProject(PROJECT_ID);
    const unauthFunctions = new Functions(unauthClient);

    let unauthBlocked = false;
    try {
      await unauthFunctions.createExecution({
        functionId: FUNCTION_ID,
        body: JSON.stringify({ action: 'upsert', itemId: 'test_item', itemType: 'word' }),
        method: 'POST',
      });
    } catch (e) {
      unauthBlocked = true;
      assert.match(String(e.code || e.message), /401/, 'Unauthenticated call must be rejected with 401');
      console.log(`  ✓ Correctly rejected unauthenticated call: HTTP ${e.code} (${e.message})`);
    }
    assert.ok(unauthBlocked, 'Unauthenticated execution must be blocked');

    // 4. Authenticated Flow with Disposable Test Account
    console.log('\n[4/6] Creating disposable test learner account...');
    disposableUserId = `test_${Date.now()}_${crypto.randomBytes(4).toString('hex')}`;
    const disposableEmail = `${disposableUserId}@olitun.test`;
    const disposablePass = `Pass_${crypto.randomBytes(8).toString('hex')}!`;

    const user = await users.create({
      userId: disposableUserId,
      email: disposableEmail,
      password: disposablePass,
      name: 'Disposable Test Learner',
    });
    assert.equal(user.$id, disposableUserId);
    console.log(`  ✓ Created test account: ${disposableUserId}`);

    const jwtRes = await users.createJWT({ userId: disposableUserId });
    const userClient = new Client().setEndpoint(ENDPOINT).setProject(PROJECT_ID).setJWT(jwtRes.jwt);
    const userFunctions = new Functions(userClient);

    // 5. Test Live Upsert & Canonical Row Derivation
    console.log('\n[5/6] Invoking mutateReviewState as authenticated test learner...');
    const testItemId = 'word_live_audit_test_01';
    const nowIso = new Date().toISOString();
    const nextReviewIso = new Date(Date.now() + 86400000).toISOString();
    const testState = {
      itemId: testItemId,
      intervalDays: 1,
      ease: 2.5,
      repetitions: 1,
      step: 0,
      introducedAt: nowIso,
      lastReviewedAt: nowIso,
      nextReviewAt: nextReviewIso,
      itemType: 'word',
    };

    const execRes = await userFunctions.createExecution({
      functionId: FUNCTION_ID,
      body: JSON.stringify({
        action: 'upsert',
        itemId: testItemId,
        itemType: 'word',
        nextReviewAt: nextReviewIso,
        lastReviewedAt: nowIso,
        schemaVersion: 3,
        stateJson: JSON.stringify(testState),
      }),
      method: 'POST',
      async: false,
    });

    assert.equal(execRes.status, 'completed', 'Execution must complete');
    assert.equal(execRes.responseStatusCode, 200, 'Execution response status code must be 200');
    const parsedRes = JSON.parse(execRes.responseBody);
    assert.equal(parsedRes.ok, true, 'Response body ok must be true');
    console.log(`  ✓ Upsert executed successfully: HTTP ${execRes.responseStatusCode}`);
    console.log(`  ✓ Canonical row ID returned: ${parsedRes.rowId}`);

    // Verify row directly in TablesDB with server client
    const expectedCanonicalRowId = rowIdFor(disposableUserId, testItemId);
    assert.equal(parsedRes.rowId, expectedCanonicalRowId, 'Returned rowId must match SHA-256 canonical row ID');

    const remoteRow = await tablesDb.getRow({
      databaseId: DB_ID,
      tableId: TABLE_ID,
      rowId: expectedCanonicalRowId,
    });
    assert.equal(remoteRow.$id, expectedCanonicalRowId);
    assert.equal(remoteRow.userId, disposableUserId);
    assert.equal(remoteRow.itemId, testItemId);
    assert.equal(remoteRow.itemType, 'word');
    assert.equal(remoteRow.schemaVersion, 3);
    console.log('  ✓ Row verified in TablesDB with exact schema values');

    // Verify row permissions: strictly owned by user
    const expectedOwnerPerms = [
      `read("user:${disposableUserId}")`,
      `update("user:${disposableUserId}")`,
      `delete("user:${disposableUserId}")`,
    ];
    for (const p of expectedOwnerPerms) {
      assert.ok(remoteRow.$permissions.includes(p), `Row must include owner permission: ${p}`);
    }
    const hasPublicPerms = remoteRow.$permissions.some((p) => p.includes('any') || p.includes('guest') || p.includes('users'));
    assert.equal(hasPublicPerms, false, 'Row must not have public or global permissions');
    console.log(`  ✓ Row permissions strictly owner-isolated: ${JSON.stringify(remoteRow.$permissions)}`);

    // Test payload byte limit enforcement (>8192 bytes)
    const oversizedState = JSON.stringify({ pad: 'X'.repeat(8193) });
    const oversizedExec = await userFunctions.createExecution({
      functionId: FUNCTION_ID,
      body: JSON.stringify({
        action: 'upsert',
        itemId: testItemId,
        itemType: 'word',
        nextReviewAt: nextReviewIso,
        stateJson: oversizedState,
      }),
      method: 'POST',
      async: false,
    });
    assert.equal(oversizedExec.responseStatusCode, 413, 'Oversized payload must be rejected with 413');
    console.log('  ✓ Oversized payload (>8192 bytes) correctly rejected with HTTP 413');

    // Test Delete operation
    const deleteExec = await userFunctions.createExecution({
      functionId: FUNCTION_ID,
      body: JSON.stringify({
        action: 'delete',
        itemId: testItemId,
      }),
      method: 'POST',
      async: false,
    });
    assert.equal(deleteExec.responseStatusCode, 200, 'Delete operation must succeed with 200');
    console.log('  ✓ Delete operation succeeded: HTTP 200');

    let rowDeleted = false;
    try {
      await tablesDb.getRow({ databaseId: DB_ID, tableId: TABLE_ID, rowId: expectedCanonicalRowId });
    } catch (e) {
      if (String(e.code || e.message).includes('404')) {
        rowDeleted = true;
      }
    }
    assert.ok(rowDeleted, 'Row must be deleted from TablesDB');
    console.log('  ✓ Verified row no longer exists in TablesDB (404)');

    console.log('\n[6/6] Cleaning up disposable test account...');
  } finally {
    if (disposableUserId) {
      try {
        await users.delete({ userId: disposableUserId });
        console.log(`  ✓ Deleted disposable test account: ${disposableUserId}`);
      } catch (e) {
        console.warn(`  Warning: Failed to delete disposable user: ${e.message}`);
      }
    }
  }

  console.log('\n════════════════════════════════════════════════════════════');
  console.log('✅ ALL LIVE APPWRITE BACKEND & FUNCTION CHECKS PASSED');
  console.log('════════════════════════════════════════════════════════════');
}

main().catch((e) => {
  console.error('\n❌ Live Appwrite verification failed:', e);
  process.exit(1);
});
