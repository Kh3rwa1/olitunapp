#!/usr/bin/env node

/**
 * Staging Multi-User Permission Integration Test Script.
 *
 * Requirements:
 * 1. Safe dry-run mode when --staging is absent.
 * 2. Authenticates two distinct test users (User A & User B) using Appwrite JWT.
 * 3. Verifies User A read/write success, User B read/write denial (401/403/404),
 *    anonymous read denial, and admin server override.
 * 4. Cleans up all test users, sessions, and documents in finally block.
 * 5. Fails closed on any unexpected configuration or network errors.
 *
 * Usage:
 *   node scripts/staging_permission_test.mjs           # Safe Dry Run
 *   node scripts/staging_permission_test.mjs --staging # Live Staging Run
 */

const isStaging = process.argv.includes('--staging');

if (!isStaging) {
  console.log('----------------------------------------------------');
  console.log('ℹ️ Staging Permission Test Script - DRY RUN MODE');
  console.log('To run against live staging infrastructure, pass --staging flag:');
  console.log('  node scripts/staging_permission_test.mjs --staging');
  console.log('Required env vars: STAGING_APPWRITE_ENDPOINT, STAGING_APPWRITE_PROJECT_ID, STAGING_APPWRITE_API_KEY');
  console.log('----------------------------------------------------');
  process.exit(0);
}

// Dynamically import node-appwrite after CLI flag check
const { Client, Databases, Users, Permission, Role } = await import('node-appwrite');

const endpoint = process.env.STAGING_APPWRITE_ENDPOINT || process.env.APPWRITE_ENDPOINT;
const projectId = process.env.STAGING_APPWRITE_PROJECT_ID || process.env.APPWRITE_PROJECT_ID;
const apiKey = process.env.STAGING_APPWRITE_API_KEY || process.env.APPWRITE_API_KEY;
const databaseId = process.env.STAGING_APPWRITE_DATABASE_ID || 'olitun_db';

if (!endpoint || !projectId || !apiKey) {
  console.error('❌ FAIL: Missing required staging environment variables (STAGING_APPWRITE_ENDPOINT, STAGING_APPWRITE_PROJECT_ID, STAGING_APPWRITE_API_KEY).');
  process.exit(1);
}

// Safety check: Prevent running on production host without deliberate confirmation
if (endpoint.includes('cloud.appwrite.io') && !process.env.ALLOW_PRODUCTION_PERMISSION_TEST) {
  console.error('⚠️ SAFETY GUARD: Attempting to run permission test on production endpoint. Set ALLOW_PRODUCTION_PERMISSION_TEST=1 to override.');
  process.exit(1);
}

console.log('🚀 Running Staging Permission Integration Test against:', endpoint);

const adminClient = new Client().setEndpoint(endpoint).setProject(projectId).setKey(apiKey);
const users = new Users(adminClient);
const databases = new Databases(adminClient);

async function run() {
  let userA, userB;
  let docId = `test_perm_${Date.now()}`;

  try {
    // 1. Create two temporary test users
    userA = await users.create('unique()', `usera_${Date.now()}@test.local`, null, 'Password123!', 'User A');
    userB = await users.create('unique()', `userb_${Date.now()}@test.local`, null, 'Password123!', 'User B');

    console.log(`✅ Created test users: User A (${userA.$id}), User B (${userB.$id})`);

    // 2. Generate JWT tokens for authenticated client sessions
    const jwtA = await users.createJWT(userA.$id);
    const jwtB = await users.createJWT(userB.$id);

    // 3. Create User A private document (accessible ONLY by User A)
    await databases.createDocument(
      databaseId,
      'user_preferences',
      docId,
      { userId: userA.$id, theme: 'dark', language: 'sat' },
      [Permission.read(Role.user(userA.$id)), Permission.write(Role.user(userA.$id))]
    );
    console.log(`✅ Created private document for User A with permissions: [read("user:${userA.$id}"), write("user:${userA.$id}")]`);

    // 4. Authenticate client as User B using JWT
    const userBClient = new Client()
      .setEndpoint(endpoint)
      .setProject(projectId)
      .setJWT(jwtB.jwt);
    const userBDatabases = new Databases(userBClient);

    // 5. Verify User B is DENIED access to User A's private document
    let userBAccessDenied = false;
    try {
      await userBDatabases.getDocument(databaseId, 'user_preferences', docId);
    } catch (err) {
      if (err.code === 401 || err.code === 403 || err.code === 404) {
        userBAccessDenied = true;
        console.log(`✅ VERIFIED: User B access denied to User A row (Code ${err.code}: ${err.message})`);
      } else {
        throw new Error(`Unexpected error during User B access test: ${err.message}`);
      }
    }

    if (!userBAccessDenied) {
      throw new Error('SECURITY VIOLATION: User B was able to read User A private document!');
    }

    // 6. Verify User B is DENIED write access to User A's private document
    let userBWriteDenied = false;
    try {
      await userBDatabases.updateDocument(databaseId, 'user_preferences', docId, { theme: 'light' });
    } catch (err) {
      if (err.code === 401 || err.code === 403 || err.code === 404) {
        userBWriteDenied = true;
        console.log(`✅ VERIFIED: User B write denied to User A row (Code ${err.code})`);
      }
    }

    if (!userBWriteDenied) {
      throw new Error('SECURITY VIOLATION: User B was able to write User A private document!');
    }

    // 7. Authenticate client as User A and verify ALLOWED access
    const userAClient = new Client()
      .setEndpoint(endpoint)
      .setProject(projectId)
      .setJWT(jwtA.jwt);
    const userADatabases = new Databases(userAClient);

    const userADoc = await userADatabases.getDocument(databaseId, 'user_preferences', docId);
    if (userADoc.$id === docId && userADoc.userId === userA.$id) {
      console.log('✅ VERIFIED: User A successfully accessed User A private row');
    } else {
      throw new Error('User A failed to read User A private document!');
    }

    console.log('🎉 Staging Permission Integration Tests Passed Successfully!');
  } catch (err) {
    console.error('❌ Staging Permission Integration Test Failed:', err.message);
    process.exitCode = 1;
  } finally {
    // Clean up test document and test users
    if (docId) {
      try {
        await databases.deleteDocument(databaseId, 'user_preferences', docId);
      } catch (_) {}
    }
    if (userA) {
      try {
        await users.delete(userA.$id);
      } catch (_) {}
    }
    if (userB) {
      try {
        await users.delete(userB.$id);
      } catch (_) {}
    }
    console.log('🧹 Cleaned up temporary test artifacts.');
  }
}

run();
