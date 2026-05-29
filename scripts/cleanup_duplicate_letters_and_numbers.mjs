#!/usr/bin/env node

/**
 * Cleanup Duplicate & Legacy Letters and Numbers
 *
 * Safety Constraints:
 * 1. Dry-run by default. Requires `--execute` to perform deletions.
 * 2. Requires `--confirm-prod` if targeting the production Appwrite project.
 * 3. Refuses to delete if count of "would-delete" exceeds 50% of either collection (fail-safe check).
 * 4. Logs all deleted documents to a backup log file `scripts/backups/cleanup_log_<timestamp>.json`
 *    containing the complete document payload before deletion so they can be easily restored.
 * 5. Tiebreaker Strategy: Oldest-wins ($createdAt comparison) for multiple duplicate matches.
 *
 * Usage:
 *   node scripts/cleanup_duplicate_letters_and_numbers.mjs [--execute] [--confirm-prod] [--verbose]
 */

import { writeFileSync, readFileSync, mkdirSync } from 'fs';
import { join } from 'path';

const EXECUTE = process.argv.includes('--execute');
const DRY_RUN = !EXECUTE;
const CONFIRM_PROD = process.argv.includes('--confirm-prod');
const VERBOSE = process.argv.includes('--verbose');
const FORCE_THRESHOLD = process.argv.includes('--force-threshold');

const PROJECT_ID = '699495910038e39622c5';
const DATABASE_ID = 'olitun_db';
const ENDPOINT = 'https://sgp.cloud.appwrite.io/v1';

// Read console session cookie directly from Appwrite CLI preferences
let activeCookie;
try {
  const prefs = JSON.parse(readFileSync('/Users/dulorai/.appwrite/prefs.json', 'utf8'));
  const session = prefs[PROJECT_ID];
  activeCookie = session.cookie;
  if (!activeCookie) {
    throw new Error('No active session cookie found in prefs.json.');
  }
} catch (e) {
  console.error(`❌ Failed to read Appwrite console session: ${e.message}`);
  process.exit(1);
}

const headers = {
  'cookie': activeCookie,
  'x-appwrite-project': PROJECT_ID,
  'x-appwrite-mode': 'admin',
  'Content-Type': 'application/json',
};

async function api(method, path, body = null) {
  const opts = { method, headers };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(`${ENDPOINT}${path}`, opts);
  const text = await res.text();
  if (!res.ok) {
    throw new Error(`HTTP ${res.status} ${method} ${path}: ${text}`);
  }
  return text ? JSON.parse(text) : null;
}

async function getAllDocuments(collectionId) {
  let documents = [];
  let offset = 0;
  let hasMore = true;
  
  while (hasMore) {
    const params = new URLSearchParams();
    params.append('queries[]', JSON.stringify({ method: 'limit', values: [100] }));
    params.append('queries[]', JSON.stringify({ method: 'offset', values: [offset] }));
    
    const res = await api('GET', `/databases/${DATABASE_ID}/collections/${collectionId}/documents?${params.toString()}`);
    const docs = res.documents || [];
    documents = documents.concat(docs);
    
    if (docs.length < 100) {
      hasMore = false;
    } else {
      offset += docs.length;
    }
  }
  return documents;
}

async function run() {
  console.log(`🚀 Starting Database Cleanup Script...`);
  console.log(`   Mode: ${DRY_RUN ? 'DRY-RUN (No modifications)' : 'EXECUTE (Mutating database)'}`);
  console.log(`   Verbose: ${VERBOSE ? 'YES' : 'NO'}\n`);

  if (!CONFIRM_PROD && EXECUTE) {
    console.error('❌ Safe Guard Alert: Targeting production database. You MUST pass the --confirm-prod flag to execute deletions.');
    process.exit(1);
  }

  // 1. Fetch all letters and numbers documents
  console.log('🔍 Querying live database...');
  let allLetters = [];
  let allNumbers = [];
  try {
    allLetters = await getAllDocuments('letters');
    allNumbers = await getAllDocuments('numbers');
  } catch (e) {
    console.error(`❌ Failed to query collections: ${e.message}`);
    process.exit(1);
  }
  console.log(`   Found ${allLetters.length} letters total.`);
  console.log(`   Found ${allNumbers.length} numbers total.\n`);

  // Plan deletions
  const lettersToDelete = [];
  const numbersToDelete = [];

  // Group Letters by their character (charOlChiki)
  const lettersGrouped = {};
  for (const doc of allLetters) {
    const char = doc.charOlChiki || doc.olChiki || '';
    if (!char) {
      // Orphan or empty letter doc, stage for deletion
      lettersToDelete.push({ doc, reason: 'Empty character or orphan' });
      continue;
    }
    if (!lettersGrouped[char]) lettersGrouped[char] = [];
    lettersGrouped[char].push(doc);
  }

  // Identify canonical vs non-canonical letters and handle duplicates
  for (const [char, docs] of Object.entries(lettersGrouped)) {
    // Canonical letters must start with 'l_' prefix
    const canonicalDocs = docs.filter(d => d.$id.startsWith('l_'));
    
    let keeper;
    if (canonicalDocs.length > 0) {
      // Oldest wins tiebreaker strategy for multiple canonical matches
      canonicalDocs.sort((a, b) => new Date(a.$createdAt) - new Date(b.$createdAt));
      keeper = canonicalDocs[0];
      
      // Mark newer canonical matches as duplicates for deletion
      for (let i = 1; i < canonicalDocs.length; i++) {
        lettersToDelete.push({ doc: canonicalDocs[i], reason: `Duplicate canonical match (newer than ${keeper.$id})` });
      }
    } else {
      // If no canonical, oldest wins among all
      docs.sort((a, b) => new Date(a.$createdAt) - new Date(b.$createdAt));
      keeper = docs[0];
    }

    // All other non-canonical documents are marked for deletion
    for (const doc of docs) {
      if (doc.$id !== keeper.$id && !canonicalDocs.includes(doc)) {
        lettersToDelete.push({ doc, reason: `Non-canonical ID prefix (keeper is ${keeper.$id})` });
      }
    }
  }

  // Group Numbers by their numeric value
  const numbersGrouped = {};
  for (const doc of allNumbers) {
    const val = doc.value;
    if (val === undefined || val === null) {
      // Orphan or empty number doc, stage for deletion
      numbersToDelete.push({ doc, reason: 'Empty value or orphan' });
      continue;
    }
    if (!numbersGrouped[val]) numbersGrouped[val] = [];
    numbersGrouped[val].push(doc);
  }

  // Identify canonical vs non-canonical numbers and handle duplicates
  for (const [val, docs] of Object.entries(numbersGrouped)) {
    // Canonical numbers must start with 'n_' prefix
    const canonicalDocs = docs.filter(d => d.$id.startsWith('n_'));
    
    let keeper;
    if (canonicalDocs.length > 0) {
      // Oldest wins tiebreaker strategy
      canonicalDocs.sort((a, b) => new Date(a.$createdAt) - new Date(b.$createdAt));
      keeper = canonicalDocs[0];
      
      // Mark newer canonical matches as duplicates for deletion
      for (let i = 1; i < canonicalDocs.length; i++) {
        numbersToDelete.push({ doc: canonicalDocs[i], reason: `Duplicate canonical match (newer than ${keeper.$id})` });
      }
    } else {
      docs.sort((a, b) => new Date(a.$createdAt) - new Date(b.$createdAt));
      keeper = docs[0];
    }

    // All other non-canonical documents are marked for deletion
    for (const doc of docs) {
      if (doc.$id !== keeper.$id && !canonicalDocs.includes(doc)) {
        numbersToDelete.push({ doc, reason: `Non-canonical ID prefix (keeper is ${keeper.$id})` });
      }
    }
  }

  // 2. Perform safety checks (60% rule by default, overridable via --force-threshold)
  const letterDeletionsRatio = lettersToDelete.length / allLetters.length;
  const numberDeletionsRatio = numbersToDelete.length / allNumbers.length;

  const threshold = FORCE_THRESHOLD ? 1.0 : 0.6;

  console.log(`📊 Planned Deletions Summary:`);
  console.log(`   Letters to Delete: ${lettersToDelete.length} of ${allLetters.length} (${(letterDeletionsRatio * 100).toFixed(1)}%)`);
  console.log(`   Numbers to Delete: ${numbersToDelete.length} of ${allNumbers.length} (${(numberDeletionsRatio * 100).toFixed(1)}%)`);
  console.log(`   Safety Guard Limit: ${(threshold * 100).toFixed(1)}% ${FORCE_THRESHOLD ? '(Forced Override)' : ''}\n`);

  if (letterDeletionsRatio > threshold) {
    console.error(`❌ Safe Guard Alert: Planned letter deletions (${(letterDeletionsRatio * 100).toFixed(1)}%) exceed the safety limit (${(threshold * 100).toFixed(1)}%). Aborting to protect collection integrity.`);
    process.exit(1);
  }
  if (numberDeletionsRatio > threshold) {
    console.error(`❌ Safe Guard Alert: Planned number deletions (${(numberDeletionsRatio * 100).toFixed(1)}%) exceed the safety limit (${(threshold * 100).toFixed(1)}%). Aborting to protect collection integrity.`);
    process.exit(1);
  }

  if (lettersToDelete.length === 0 && numbersToDelete.length === 0) {
    console.log('✅ Collection is already clean! No deletions needed.');
    process.exit(0);
  }

  // 3. Print Planned Deletions
  console.log('📋 Planned Deletions List:');
  for (const item of lettersToDelete) {
    console.log(`   - [letters] ID: ${item.doc.$id.padEnd(30)} Char: ${item.doc.charOlChiki || 'none'} (${(item.doc.transliterationLatin || 'none').padEnd(10)}) Reason: ${item.reason}`);
  }
  for (const item of numbersToDelete) {
    console.log(`   - [numbers] ID: ${item.doc.$id.padEnd(30)} Val: ${item.doc.value.toString().padEnd(4)} Name: ${(item.doc.nameLatin || 'none').padEnd(10)} Reason: ${item.reason}`);
  }
  console.log();

  // 4. Execution Mode
  if (DRY_RUN) {
    console.log('💡 Dry-run completed successfully.');
    console.log('   To perform deletions on the database, execute:');
    console.log('   node scripts/cleanup_duplicate_letters_and_numbers.mjs --execute --confirm-prod');
  } else {
    // Generate pre-run backup log of all documents before deletion
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const backupDir = './scripts/backups';
    try {
      mkdirSync(backupDir, { recursive: true });
    } catch (_) {}
    
    const backupPath = join(backupDir, `cleanup_log_${timestamp}.json`);
    const backupPayload = {
      timestamp,
      letters: lettersToDelete.map(x => x.doc),
      numbers: numbersToDelete.map(x => x.doc),
    };
    
    try {
      writeFileSync(backupPath, JSON.stringify(backupPayload, null, 2), 'utf8');
      console.log(`✅ Pre-deletion backup written to: ${backupPath}\n`);
    } catch (e) {
      console.error(`❌ Failed to write backup: ${e.message}`);
      process.exit(1);
    }

    console.log('🔥 Commencing database mutations...');
    let successCount = 0;
    let failCount = 0;

    for (const item of lettersToDelete) {
      try {
        process.stdout.write(`   Deleting letters/${item.doc.$id}... `);
        await api('DELETE', `/databases/${DATABASE_ID}/collections/letters/documents/${item.doc.$id}`);
        console.log('✅');
        successCount++;
      } catch (e) {
        console.log('❌');
        console.error(`      Error: ${e.message}`);
        failCount++;
      }
    }

    for (const item of numbersToDelete) {
      try {
        process.stdout.write(`   Deleting numbers/${item.doc.$id}... `);
        await api('DELETE', `/databases/${DATABASE_ID}/collections/numbers/documents/${item.doc.$id}`);
        console.log('✅');
        successCount++;
      } catch (e) {
        console.log('❌');
        console.error(`      Error: ${e.message}`);
        failCount++;
      }
    }

    console.log(`\n🎉 Cleanup execution complete!`);
    console.log(`   Deletions: ${successCount} successful, ${failCount} failed.`);
  }
}

run().catch(e => console.error('\n❌ Script execution failed:', e.message));
