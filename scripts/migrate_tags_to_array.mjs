/**
 * Standalone Migration Script to migrate legacy comma-separated tags to the new tagsList array column.
 * Performs a collection backup to scripts/backups/ prior to running.
 *
 * Usage:
 *   node scripts/migrate_tags_to_array.mjs --dry-run
 *   node scripts/migrate_tags_to_array.mjs --apply
 */

import { readFileSync, writeFileSync, mkdirSync } from 'fs';
import { join } from 'path';

function readProjectIdFromConfig() {
  try {
    const raw = readFileSync(new URL('../appwrite.config.json', import.meta.url), 'utf8');
    return JSON.parse(raw).projectId || '';
  } catch (_) {
    return '';
  }
}

const ENDPOINT = process.env.APPWRITE_ENDPOINT || 'https://sgp.cloud.appwrite.io/v1';
const PROJECT_ID = process.env.APPWRITE_PROJECT_ID || readProjectIdFromConfig();
const API_KEY = process.env.APPWRITE_API_KEY;
const DATABASE_ID = 'olitun_db';
const COLLECTION_ID = 'rhymes';

const DRY_RUN = !process.argv.includes('--apply') || process.argv.includes('--dry-run');

if (!PROJECT_ID) {
  console.error('❌ Error: Set APPWRITE_PROJECT_ID or specify projectId in appwrite.config.json');
  process.exit(1);
}

if (!API_KEY) {
  console.error('❌ Error: Set APPWRITE_API_KEY environment variable');
  process.exit(1);
}

const headers = {
  'Content-Type': 'application/json',
  'X-Appwrite-Project': PROJECT_ID,
  'X-Appwrite-Key': API_KEY,
};

async function api(method, path, body = null) {
  const opts = { method, headers };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(`${ENDPOINT}${path}`, opts);
  const text = await res.text();
  if (!res.ok) {
    throw new Error(`${res.status} ${method} ${path}: ${text}`);
  }
  return text ? JSON.parse(text) : null;
}

async function run() {
  console.log(`🚀 Starting Rhymes Tags Migration to Array...`);
  console.log(`Endpoint: ${ENDPOINT}`);
  console.log(`Project:  ${PROJECT_ID}`);
  console.log(`Mode:     ${DRY_RUN ? 'DRY-RUN (No database mutations)' : 'APPLY (Mutating database)'}\n`);

  // 1. Fetch all rhymes documents
  console.log('Fetching rhymes documents...');
  const listRes = await api('GET', `/databases/${DATABASE_ID}/collections/${COLLECTION_ID}/documents?limit=1000`);
  const docs = listRes.documents || [];
  console.log(`Found ${docs.length} documents.`);

  if (docs.length === 0) {
    console.log('No documents found to migrate.');
    return;
  }

  // 2. Perform Backup
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupDir = './scripts/backups';
  try {
    mkdirSync(backupDir, { recursive: true });
  } catch (_) {}
  const backupPath = join(backupDir, `rhymes_tags_backup_${timestamp}.json`);
  writeFileSync(backupPath, JSON.stringify(docs, null, 2), 'utf8');
  console.log(`✅ Pre-run collection backup written to: ${backupPath}\n`);

  // 3. Process documents
  let migratedCount = 0;
  let skippedCount = 0;

  for (const doc of docs) {
    const tagsLegacy = doc.tags || '';
    const tagsList = doc.tagsList || [];

    // If tagsList is empty/null and tagsLegacy is not empty
    if ((!tagsList || tagsList.length === 0) && tagsLegacy && tagsLegacy.trim().length > 0) {
      const parsedTags = tagsLegacy
        .split(',')
        .map(t => t.trim())
        .filter(t => t.length > 0);

      if (parsedTags.length > 0) {
        migratedCount++;
        console.log(`Document [${doc.$id}] - "${doc.titleLatin}"`);
        console.log(`  Current tags:     "${tagsLegacy}"`);
        console.log(`  Current tagsList: ${JSON.stringify(doc.tagsList || null)}`);
        console.log(`  Migrated to tagsList: ${JSON.stringify(parsedTags)}`);

        if (!DRY_RUN) {
          await api('PATCH', `/databases/${DATABASE_ID}/collections/${COLLECTION_ID}/documents/${doc.$id}`, {
            data: {
              tagsList: parsedTags
            }
          });
          console.log(`  ⚡ Updated successfully.`);
        }
        console.log();
      } else {
        skippedCount++;
      }
    } else {
      skippedCount++;
    }
  }

  console.log(`Migration summary:`);
  console.log(`  Total documents: ${docs.length}`);
  console.log(`  Migrated:        ${migratedCount}`);
  console.log(`  Skipped:         ${skippedCount}`);
  console.log(DRY_RUN ? 'Done! (Dry run completed without database changes)' : 'Done! Database updated successfully! 🎉');
}

run().catch((e) => console.error('❌ Migration failed:', e));
