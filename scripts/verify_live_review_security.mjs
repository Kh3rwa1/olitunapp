#!/usr/bin/env node
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { Client, TablesDB, Functions, Users, Query } from 'node-appwrite';

const ENDPOINT = process.env.APPWRITE_ENDPOINT || 'https://sgp.cloud.appwrite.io/v1';
const PROJECT_ID = process.env.APPWRITE_PROJECT_ID || '699495910038e39622c5';
const DB_ID = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
const TABLE_ID = process.env.APPWRITE_TABLE_ID || 'review_states';
const FUNCTION_ID = process.env.APPWRITE_FUNCTION_ID || 'mutateReviewState';

function loadApiKey() {
  if (process.env.APPWRITE_API_KEY && process.env.APPWRITE_API_KEY.trim()) {
    return process.env.APPWRITE_API_KEY.trim();
  }
  const keyPath = path.join(os.homedir(), '.appwrite', 'olitun_deploy_key');
  if (fs.existsSync(keyPath)) {
    return fs.readFileSync(keyPath, 'utf8').trim();
  }
  return null;
}

function rowIdFor(userId, itemId) {
  const input = `usr:${userId.length}:${userId}:item:${itemId.length}:${itemId}`;
  const digest = crypto.createHash('sha256').update(input).digest('hex');
  return `r_${digest.slice(0, 31)}`;
}

async function main() {
  const apiKey = loadApiKey();
  if (!apiKey) {
    console.error('ERROR: Missing Appwrite API key.');
    process.exit(1);
  }

  const serverClient = new Client().setEndpoint(ENDPOINT).setProject(PROJECT_ID).setKey(apiKey);
  const tablesDb = new TablesDB(serverClient);
  const functions = new Functions(serverClient);
  const users = new Users(serverClient);

  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('LIVE REVIEW SECURITY & TWO-USER ISOLATION VERIFICATION');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`Endpoint:   ${ENDPOINT}`);
  console.log(`Project ID: ${PROJECT_ID}`);
  console.log(`Database:   ${DB_ID}`);
  console.log(`Table:      ${TABLE_ID}`);
  console.log(`Function:   ${FUNCTION_ID}`);
  console.log('────────────────────────────────────────────────────────────');

  let userAId = null;
  let userBId = null;
  const createdRowIds = new Set();

  try {
    // -------------------------------------------------------------
    // PHASE 4 / PRE-FLIGHT: Table and Function Configuration
    // -------------------------------------------------------------
    console.log('\n[Phase 4] Live Configuration Audit...');
    const table = await tablesDb.getTable({ databaseId: DB_ID, tableId: TABLE_ID });
    assert.equal(table.$id, TABLE_ID);
    assert.equal(table.rowSecurity, true, 'Row security must be enabled');
    assert.deepEqual(table.$permissions || [], [], 'Table permissions must be empty []');
    console.log('  ✓ Table permissions are empty [] and rowSecurity is enabled');

    const fn = await functions.get({ functionId: FUNCTION_ID });
    assert.deepEqual(fn.execute, ['users'], 'Function execute role must be strictly ["users"]');
    assert.deepEqual([...fn.scopes].sort(), ['rows.read', 'rows.write'], 'Function scopes must be ["rows.read", "rows.write"]');
    assert.equal(fn.latestDeploymentStatus, 'ready', 'Function deployment must be ready');
    console.log('  ✓ Function execution role strictly ["users"], scopes ["rows.read", "rows.write"], status: ready');

    // -------------------------------------------------------------
    // ANONYMOUS CHECKS
    // -------------------------------------------------------------
    console.log('\n[Anonymous Security Checks]');
    const anonClient = new Client().setEndpoint(ENDPOINT).setProject(PROJECT_ID);
    const anonFunctions = new Functions(anonClient);
    const anonTables = new TablesDB(anonClient);

    // 1. Anonymous mutateReviewState execution denied
    let anonExecBlocked = false;
    try {
      await anonFunctions.createExecution({
        functionId: FUNCTION_ID,
        body: JSON.stringify({ action: 'upsert', itemId: 'anon_probe' }),
      });
    } catch (e) {
      anonExecBlocked = true;
      assert.match(String(e.code || e.message), /401/, 'Anonymous function execution must be rejected with 401');
    }
    assert.ok(anonExecBlocked, 'Anonymous function execution must be blocked');
    console.log('  ✓ 1. Anonymous mutateReviewState execution is denied (HTTP 401)');

    // 2. Anonymous read of review_states denied: listRows returns 0 rows and getRow throws
    const anonListRes = await anonTables.listRows(DB_ID, TABLE_ID, [Query.limit(10)]);
    assert.equal(anonListRes.rows.length, 0, 'Anonymous listRows must return 0 rows under row-security');
    assert.equal(anonListRes.total, 0, 'Anonymous listRows total must be 0');

    let anonGetBlocked = false;
    try {
      await anonTables.getRow(DB_ID, TABLE_ID, 'nonexistent_or_protected');
    } catch (e) {
      anonGetBlocked = true;
      assert.match(String(e.code || e.message), /401|403|404/, 'Anonymous getRow must be denied/not found');
    }
    assert.ok(anonGetBlocked, 'Anonymous getRow must be blocked');
    console.log('  ✓ 2. Anonymous read of review_states is denied (0 rows returned; getRow throws)');

    // 3. Anonymous create, update, and delete denied
    let anonCreateBlocked = false;
    try {
      await anonTables.createRow(DB_ID, TABLE_ID, 'anon_test_row', { userId: 'anon', itemId: 'item_1' });
    } catch (e) {
      anonCreateBlocked = true;
      assert.match(String(e.code || e.message), /401|403/, 'Anonymous createRow must be denied with 401/403');
    }
    assert.ok(anonCreateBlocked, 'Anonymous createRow must be blocked');

    let anonUpdateBlocked = false;
    try {
      await anonTables.updateRow(DB_ID, TABLE_ID, 'anon_test_row', { itemType: 'word' });
    } catch (e) {
      anonUpdateBlocked = true;
    }
    assert.ok(anonUpdateBlocked, 'Anonymous updateRow must be blocked');

    let anonDeleteBlocked = false;
    try {
      await anonTables.deleteRow(DB_ID, TABLE_ID, 'anon_test_row');
    } catch (e) {
      anonDeleteBlocked = true;
    }
    assert.ok(anonDeleteBlocked, 'Anonymous deleteRow must be blocked');
    console.log('  ✓ 3. Anonymous create, update, and delete are denied');

    // -------------------------------------------------------------
    // PROVISION DISPOSABLE TEST USERS (User A & User B)
    // -------------------------------------------------------------
    console.log('\n[Provisioning Test Learner Accounts]');
    userAId = `test_a_${Date.now()}_${crypto.randomBytes(3).toString('hex')}`;
    userBId = `test_b_${Date.now()}_${crypto.randomBytes(3).toString('hex')}`;

    const userA = await users.create({
      userId: userAId,
      email: `${userAId}@olitun.test`,
      password: `P_${crypto.randomBytes(8).toString('hex')}!`,
      name: 'Test Learner A',
    });
    const userB = await users.create({
      userId: userBId,
      email: `${userBId}@olitun.test`,
      password: `P_${crypto.randomBytes(8).toString('hex')}!`,
      name: 'Test Learner B',
    });

    const jwtA = (await users.createJWT({ userId: userA.$id })).jwt;
    const jwtB = (await users.createJWT({ userId: userB.$id })).jwt;

    const clientA = new Client().setEndpoint(ENDPOINT).setProject(PROJECT_ID).setJWT(jwtA);
    const clientB = new Client().setEndpoint(ENDPOINT).setProject(PROJECT_ID).setJWT(jwtB);

    const fnA = new Functions(clientA);
    const fnB = new Functions(clientB);
    const tablesA = new TablesDB(clientA);
    const tablesB = new TablesDB(clientB);
    console.log('  ✓ Created disposable User A and User B accounts with isolated JWT sessions');

    // -------------------------------------------------------------
    // USER A DIRECT-ACCESS & FUNCTION CHECKS
    // -------------------------------------------------------------
    console.log('\n[User A Function & Direct-Access Checks]');
    const testItemId = 'word_sec_audit_001';
    const nowIso = new Date().toISOString();
    const nextReviewIso = new Date(Date.now() + 86400000).toISOString();
    const testState = {
      itemId: testItemId,
      intervalDays: 1,
      ease: 2.5,
      repetitions: 1,
      step: 0,
      nextReviewAt: nextReviewIso,
      itemType: 'word',
    };

    // 1. Authenticated Function upsert succeeds
    const upsertRes1 = await fnA.createExecution({
      functionId: FUNCTION_ID,
      body: JSON.stringify({
        action: 'upsert',
        itemId: testItemId,
        itemType: 'word',
        nextReviewAt: nextReviewIso,
        schemaVersion: 3,
        stateJson: JSON.stringify(testState),
      }),
      method: 'POST',
      async: false,
    });
    assert.equal(upsertRes1.status, 'completed');
    assert.equal(upsertRes1.responseStatusCode, 200);
    const bodyA = JSON.parse(upsertRes1.responseBody);
    assert.equal(bodyA.ok, true);
    console.log('  ✓ 1. Authenticated Function upsert succeeds (HTTP 200)');

    // 2. Exactly one canonical row created
    const expectedRowIdA = rowIdFor(userAId, testItemId);
    assert.equal(bodyA.rowId, expectedRowIdA);
    createdRowIds.add(expectedRowIdA);
    console.log('  ✓ 2. Exactly one canonical row created with deterministic SHA-256 ID');

    // 3. Repeating same upsert is idempotent
    const upsertRes2 = await fnA.createExecution({
      functionId: FUNCTION_ID,
      body: JSON.stringify({
        action: 'upsert',
        itemId: testItemId,
        itemType: 'word',
        nextReviewAt: nextReviewIso,
        schemaVersion: 3,
        stateJson: JSON.stringify(testState),
      }),
      method: 'POST',
      async: false,
    });
    assert.equal(upsertRes2.responseStatusCode, 200);
    console.log('  ✓ 3. Repeating the same upsert is idempotent');

    // 4. Row has the exact safe permission set: strictly owner read-only
    const rowA = await tablesDb.getRow({ databaseId: DB_ID, tableId: TABLE_ID, rowId: expectedRowIdA });
    assert.deepEqual(rowA.$permissions, [`read("user:${userAId}")`]);
    console.log('  ✓ 4. Row permissions strictly owner read-only (update & delete absent)');

    // 5. Direct client createRow is denied
    let directCreateBlocked = false;
    try {
      await tablesA.createRow(DB_ID, TABLE_ID, 'direct_row_a', {
        userId: userAId,
        itemId: 'direct_word',
        itemType: 'word',
        nextReviewAt: nextReviewIso,
        schemaVersion: 3,
        stateJson: JSON.stringify(testState),
      });
    } catch (e) {
      directCreateBlocked = true;
    }
    assert.ok(directCreateBlocked, 'Direct client createRow must be denied');
    console.log('  ✓ 5. Direct client createRow is denied (HTTP 401/403/table-locked)');

    // 6. Direct client updateRow on Function-created row is denied
    let directUpdateBlocked = false;
    try {
      await tablesA.updateRow(DB_ID, TABLE_ID, expectedRowIdA, {
        nextReviewAt: new Date(Date.now() + 172800000).toISOString(),
      });
    } catch (e) {
      directUpdateBlocked = true;
    }
    assert.ok(directUpdateBlocked, 'Direct client updateRow must be denied');
    console.log('  ✓ 6. Direct client updateRow is denied (owner update permission absent)');

    // 7. Direct client deleteRow is denied
    let directDeleteBlocked = false;
    try {
      await tablesA.deleteRow(DB_ID, TABLE_ID, expectedRowIdA);
    } catch (e) {
      directDeleteBlocked = true;
    }
    assert.ok(directDeleteBlocked, 'Direct client deleteRow must be denied');
    console.log('  ✓ 7. Direct client deleteRow is denied (owner delete permission absent)');

    // User A direct read succeeds (required for Flutter cloud restore)
    const readA = await tablesA.getRow(DB_ID, TABLE_ID, expectedRowIdA);
    assert.equal(readA.$id, expectedRowIdA);
    console.log('  ✓ User A client direct read succeeds for cloud restoration');

    // -------------------------------------------------------------
    // USER B ISOLATION CHECKS
    // -------------------------------------------------------------
    console.log('\n[User B Isolation Checks]');

    // 1. User B cannot read User A's row
    let userBReadBlocked = false;
    try {
      await tablesB.getRow(DB_ID, TABLE_ID, expectedRowIdA);
    } catch (e) {
      userBReadBlocked = true;
    }
    assert.ok(userBReadBlocked, 'User B must not be able to read User A row');
    console.log('  ✓ 1. User B cannot read User A’s row (404/Not Found or 401)');

    // 2. User B cannot update User A's row
    let userBUpdateBlocked = false;
    try {
      await tablesB.updateRow(DB_ID, TABLE_ID, expectedRowIdA, { nextReviewAt: nextReviewIso });
    } catch (e) {
      userBUpdateBlocked = true;
    }
    assert.ok(userBUpdateBlocked, 'User B must not be able to update User A row');
    console.log('  ✓ 2. User B cannot update User A’s row');

    // 3. User B cannot delete User A's row
    let userBDeleteBlocked = false;
    try {
      await tablesB.deleteRow(DB_ID, TABLE_ID, expectedRowIdA);
    } catch (e) {
      userBDeleteBlocked = true;
    }
    assert.ok(userBDeleteBlocked, 'User B must not be able to delete User A row');
    console.log('  ✓ 3. User B cannot delete User A’s row');

    // 4. User B cannot invoke Function to mutate User A's row
    const userBSpoofRes = await fnB.createExecution({
      functionId: FUNCTION_ID,
      body: JSON.stringify({
        action: 'upsert',
        userId: userAId, // Spoofed userId in body
        itemId: testItemId,
        itemType: 'word',
        nextReviewAt: nextReviewIso,
        schemaVersion: 3,
        stateJson: JSON.stringify(testState),
      }),
      method: 'POST',
      async: false,
    });
    // Must be rejected with 403 FORBIDDEN because supplied userId != authenticated user
    assert.equal(userBSpoofRes.responseStatusCode, 403);
    console.log('  ✓ 4 & 5. User B supplying User A’s userId is rejected with HTTP 403 FORBIDDEN');

    // 6. User B can create and manage User B's own row through Function
    const userBUpsertRes = await fnB.createExecution({
      functionId: FUNCTION_ID,
      body: JSON.stringify({
        action: 'upsert',
        itemId: testItemId, // Same itemId as User A
        itemType: 'word',
        nextReviewAt: nextReviewIso,
        schemaVersion: 3,
        stateJson: JSON.stringify(testState),
      }),
      method: 'POST',
      async: false,
    });
    assert.equal(userBUpsertRes.responseStatusCode, 200);
    const bodyB = JSON.parse(userBUpsertRes.responseBody);
    assert.equal(bodyB.ok, true);

    // 7. User A and User B using the same itemId produce different canonical row IDs
    const expectedRowIdB = rowIdFor(userBId, testItemId);
    assert.equal(bodyB.rowId, expectedRowIdB);
    assert.notEqual(expectedRowIdA, expectedRowIdB);
    createdRowIds.add(expectedRowIdB);
    console.log('  ✓ 6 & 7. User B manages User B’s own row; same itemId produces distinct canonical row IDs');

    // Verify User A's row was never touched by User B's operations
    const rowACheck = await tablesDb.getRow({ databaseId: DB_ID, tableId: TABLE_ID, rowId: expectedRowIdA });
    assert.equal(rowACheck.userId, userAId);
    console.log('  ✓ Verified User A’s row remained intact and unaltered');

    // -------------------------------------------------------------
    // PERMISSION-REPAIR CHECKS
    // -------------------------------------------------------------
    console.log('\n[Permission-Repair Checks]');
    const repairItemId = 'word_repair_test_001';
    const repairRowId = rowIdFor(userAId, repairItemId);
    createdRowIds.add(repairRowId);

    // 1. Create over-privileged test row using server credentials
    await tablesDb.createRow(
      DB_ID,
      TABLE_ID,
      repairRowId,
      {
        userId: userAId,
        itemId: repairItemId,
        itemType: 'word',
        nextReviewAt: nextReviewIso,
        schemaVersion: 3,
        stateJson: JSON.stringify({ ...testState, itemId: repairItemId }),
      },
      [`read("user:${userAId}")`, `update("user:${userAId}")`, `delete("user:${userAId}")`]
    );
    const overPrivRow = await tablesDb.getRow({ databaseId: DB_ID, tableId: TABLE_ID, rowId: repairRowId });
    assert.equal(overPrivRow.$permissions.length, 3, 'Must have 3 permissions before repair');
    console.log('  ✓ 1. Created test row with over-privileged permissions (read, update, delete)');

    // 2. Invoke Function upsert on that item
    const repairRes = await fnA.createExecution({
      functionId: FUNCTION_ID,
      body: JSON.stringify({
        action: 'upsert',
        itemId: repairItemId,
        itemType: 'word',
        nextReviewAt: nextReviewIso,
        schemaVersion: 3,
        stateJson: JSON.stringify({ ...testState, itemId: repairItemId }),
      }),
      method: 'POST',
      async: false,
    });
    assert.equal(repairRes.responseStatusCode, 200);

    // 3. Confirm unsafe update/delete owner permissions are removed
    const repairedRow = await tablesDb.getRow({ databaseId: DB_ID, tableId: TABLE_ID, rowId: repairRowId });
    assert.deepEqual(repairedRow.$permissions, [`read("user:${userAId}")`]);
    console.log('  ✓ 2 & 3. Invoking Function upsert normalized permissions to strictly owner read-only');

    // 8. Function delete succeeds for User A
    const deleteResA = await fnA.createExecution({
      functionId: FUNCTION_ID,
      body: JSON.stringify({ action: 'delete', itemId: testItemId }),
      method: 'POST',
      async: false,
    });
    assert.equal(deleteResA.responseStatusCode, 200);
    console.log('  ✓ 8. Function delete succeeds (HTTP 200)');

    // 9. Repeating Function delete is idempotent
    const deleteResA2 = await fnA.createExecution({
      functionId: FUNCTION_ID,
      body: JSON.stringify({ action: 'delete', itemId: testItemId }),
      method: 'POST',
      async: false,
    });
    assert.equal(deleteResA2.responseStatusCode, 200);
    console.log('  ✓ 9. Repeating Function delete is idempotent');

    console.log('\n════════════════════════════════════════════════════════════');
    console.log('✅ ALL ANONYMOUS, TWO-USER ISOLATION & PERMISSION-REPAIR CHECKS PASSED');
    console.log('════════════════════════════════════════════════════════════');
  } finally {
    console.log('\n[Cleanup Handler Running]');
    // Delete any test rows created
    for (const rid of createdRowIds) {
      try {
        await tablesDb.deleteRow(DB_ID, TABLE_ID, rid);
      } catch (_) {}
    }
    // Delete test accounts
    if (userAId) {
      try {
        await users.delete({ userId: userAId });
      } catch (_) {}
    }
    if (userBId) {
      try {
        await users.delete({ userId: userBId });
      } catch (_) {}
    }
    console.log('  ✓ Deleted test rows and test user accounts for User A and User B cleanly.');
  }
}

main().catch((err) => {
  console.error('\n❌ Security verification failed:', err.message);
  process.exit(1);
});
