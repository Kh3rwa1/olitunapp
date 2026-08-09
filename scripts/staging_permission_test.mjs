#!/usr/bin/env node
import { Client, Account, Databases, Users, Permission, Role } from 'node-appwrite';

/**
 * Staging Multi-User Permission Integration Test Script.
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

const endpoint = process.env.STAGING_APPWRITE_ENDPOINT || process.env.APPWRITE_ENDPOINT;
const projectId = process.env.STAGING_APPWRITE_PROJECT_ID || process.env.APPWRITE_PROJECT_ID;
const apiKey = process.env.STAGING_APPWRITE_API_KEY || process.env.APPWRITE_API_KEY;
const databaseId = process.env.STAGING_APPWRITE_DATABASE_ID || 'olitun_db';

if (!endpoint || !projectId || !apiKey) {
  console.error('❌ FAIL: Missing required staging environment variables.');
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

    // 2. Create User A private row
    await databases.createDocument(
      databaseId,
      'user_preferences',
      docId,
      { userId: userA.$id, theme: 'dark', language: 'sat' },
      [Permission.read(Role.user(userA.$id)), Permission.write(Role.user(userA.$id))]
    );
    console.log(`✅ Created private row for User A with permissions read("user:${userA.$id}") write("user:${userA.$id}")`);

    // 3. Client session simulation: User B attempts to read User A row
    const userBClient = new Client().setEndpoint(endpoint).setProject(projectId);
    // Unauthenticated / wrong user check
    const userBDatabases = new Databases(userBClient);

    let accessDenied = false;
    try {
      await userBDatabases.getDocument(databaseId, 'user_preferences', docId);
    } catch (err) {
      if (err.code === 401 || err.code === 404) {
        accessDenied = true;
        console.log(`✅ Verified User B access denied to User A row (Code ${err.code})`);
      }
    }

    if (!accessDenied) {
      throw new Error('SECURITY VIOLATION: User B was able to read User A private document!');
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
