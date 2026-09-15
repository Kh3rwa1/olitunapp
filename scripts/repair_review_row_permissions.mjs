#!/usr/bin/env node
import { Client, TablesDB, Query } from 'node-appwrite';

const DEFAULT_ENDPOINT = 'https://sgp.cloud.appwrite.io/v1';
const DEFAULT_PROJECT_ID = '699495910038e39622c5';
const DEFAULT_DATABASE_ID = 'olitun_db';
const DEFAULT_TABLE_ID = 'review_states';

function loadApiKey() {
  if (process.env.APPWRITE_API_KEY && process.env.APPWRITE_API_KEY.trim()) {
    return process.env.APPWRITE_API_KEY.trim();
  }
  return null;
}

export function isRowPermissionCompliant(row) {
  if (!row || !row.userId) return false;
  const expected = `read("user:${row.userId}")`;
  const perms = row.$permissions || [];
  if (perms.length !== 1 || perms[0] !== expected) {
    return false;
  }
  return true;
}

export function getCleanPermissions(row) {
  return [`read("user:${row.userId}")`];
}

async function main() {
  const args = process.argv.slice(2);
  const isApply = args.includes('--apply');
  const isVerifyOnly = args.includes('--verify-only') || !isApply;
  const confirmProd = args.includes('--confirm-prod');

  const endpoint = process.env.APPWRITE_ENDPOINT || DEFAULT_ENDPOINT;
  const projectId = process.env.APPWRITE_PROJECT_ID || DEFAULT_PROJECT_ID;
  const databaseId = process.env.APPWRITE_DATABASE_ID || DEFAULT_DATABASE_ID;
  const tableId = process.env.APPWRITE_TABLE_ID || DEFAULT_TABLE_ID;

  let isCloudEndpoint = false;
  try {
    const parsedEndpoint = new URL(endpoint);
    isCloudEndpoint =
      parsedEndpoint.hostname === 'cloud.appwrite.io' ||
      parsedEndpoint.hostname.endsWith('.cloud.appwrite.io');
  } catch {
    isCloudEndpoint = false;
  }
  const isProd = isCloudEndpoint || projectId === DEFAULT_PROJECT_ID;

  if (isApply && isProd && !confirmProd) {
    console.error('ERROR: Modifying production permissions requires --confirm-prod flag.');
    process.exit(1);
  }

  const apiKey = loadApiKey();
  if (!apiKey) {
    console.error('ERROR: APPWRITE_API_KEY environment variable is required.');
    process.exit(1);
  }

  const client = new Client().setEndpoint(endpoint).setProject(projectId).setKey(apiKey);
  const tablesDb = new TablesDB(client);

  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('REVIEW_STATES ROW PERMISSIONS REPAIR & AUDIT');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`Endpoint:   ${endpoint}`);
  console.log(`Project ID: ${projectId}`);
  console.log(`Database:   ${databaseId}`);
  console.log(`Table:      ${tableId}`);
  console.log(`Mode:       ${isApply ? 'APPLY (remediating stale permissions)' : 'VERIFY-ONLY (dry run)'}`);
  console.log('────────────────────────────────────────────────────────────');

  let totalChecked = 0;
  let compliantCount = 0;
  let nonCompliantCount = 0;
  let repairedCount = 0;
  let errorCount = 0;

  let cursor = null;
  const limit = 100;

  while (true) {
    const queries = [Query.limit(limit)];
    if (cursor) {
      queries.push(Query.cursorAfter(cursor));
    }

    let res;
    try {
      res = await tablesDb.listRows(databaseId, tableId, queries);
    } catch (e) {
      console.error(`Failed to list rows: ${e.message}`);
      process.exit(1);
    }

    const rows = res.rows || res.documents || [];
    if (rows.length === 0) break;

    for (const row of rows) {
      totalChecked++;
      const compliant = isRowPermissionCompliant(row);
      if (compliant) {
        compliantCount++;
      } else {
        nonCompliantCount++;
        if (isApply) {
          try {
            const cleanPerms = getCleanPermissions(row);
            await tablesDb.updateRow(databaseId, tableId, row.$id, undefined, cleanPerms);
            repairedCount++;
          } catch (err) {
            errorCount++;
            console.error(`Failed to repair row permissions (index ${totalChecked}): ${err.message}`);
          }
        }
      }
    }

    if (rows.length < limit) break;
    cursor = rows[rows.length - 1].$id;
  }

  console.log('\nAudit Summary:');
  console.log(`  Total rows checked:        ${totalChecked}`);
  console.log(`  Fully compliant rows:      ${compliantCount}`);
  console.log(`  Over-privileged / drifted: ${nonCompliantCount}`);
  if (isApply) {
    console.log(`  Successfully repaired:     ${repairedCount}`);
    console.log(`  Errors during repair:      ${errorCount}`);
  }

  if (isVerifyOnly && nonCompliantCount > 0) {
    console.log('\n⚠️  Found rows with non-compliant permissions. Run with --apply --confirm-prod to repair.');
    process.exit(2);
  }

  console.log('\n✅ Permission audit completed successfully.');
  process.exit(errorCount > 0 ? 1 : 0);
}

if (process.argv[1] && process.argv[1].endsWith('repair_review_row_permissions.mjs')) {
  main().catch((err) => {
    console.error('Fatal error:', err);
    process.exit(1);
  });
}
