/**
 * Rhyme Category Strings Backfill Script
 * 
 * Lists all rhymes in the rhymes collection.
 * For each rhyme where categoryId exists but category is null/empty:
 *   - Look up the corresponding category document by ID.
 *   - Read titleLatin from that category.
 *   - Update the rhyme to set category: <titleLatin>.
 * 
 * Default mode is --dry-run. Pass --apply to save changes.
 * 
 * Usage:
 *   node scripts/backfill_rhyme_category_strings.mjs [--apply] [--verbose]
 */

import { spawnSync } from 'child_process';
import { writeFileSync, mkdirSync } from 'fs';
import { join } from 'path';

const APPLY = process.argv.includes('--apply');
const DRY_RUN = !APPLY;
const VERBOSE = process.argv.includes('--verbose');
const DATABASE_ID = 'olitun_db';

function runCli(argsArray) {
  try {
    const res = spawnSync('appwrite', [...argsArray, '--json'], { encoding: 'utf8' });
    if (res.error) {
      throw res.error;
    }
    if (res.status !== 0) {
      throw new Error(`CLI returned status ${res.status}: ${res.stderr || ''}`);
    }
    return JSON.parse(res.stdout.trim());
  } catch (e) {
    throw new Error(`CLI execution failed: ${e.message}`);
  }
}

async function run() {
  console.log(`🚀 Starting Rhyme Category Strings Backfill...`);
  console.log(`   Mode: ${DRY_RUN ? 'DRY-RUN (Default)' : 'APPLY (Mutating database)'}`);
  console.log(`   Verbose: ${VERBOSE ? 'YES' : 'NO'}\n`);

  // 1. Fetch all rhymes
  console.log('🔍 Listing rhymes from database...');
  let rhymesResult;
  try {
    rhymesResult = runCli([
      'databases', 'list-documents',
      '--database-id', DATABASE_ID,
      '--collection-id', 'rhymes'
    ]);
  } catch (e) {
    console.error(`❌ Failed to list rhymes: ${e.message}`);
    process.exit(1);
  }

  const rhymes = rhymesResult.documents || [];
  console.log(`   Found ${rhymes.length} rhymes total.\n`);

  // 2. Perform Pre-flight Backup (mandatory before dry-run or apply)
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupDir = './scripts/backups';
  try {
    mkdirSync(backupDir, { recursive: true });
  } catch (_) {}
  const backupPath = join(backupDir, `rhymes_pre_backfill_${timestamp}.json`);
  try {
    writeFileSync(backupPath, JSON.stringify(rhymes, null, 2), 'utf8');
    console.log(`✅ Pre-run collection backup written to: ${backupPath}\n`);
  } catch (e) {
    console.error(`❌ Failed to write backup: ${e.message}`);
    process.exit(1);
  }

  // Cache for resolved categories to prevent duplicate lookup
  const categoryCache = {};

  let totalScanned = 0;
  let alreadyHadCategory = 0;
  let missingCategoryId = 0;
  let missingCategoryDoc = 0;
  let updatedOrWouldUpdate = 0;
  let errors = 0;

  for (const rhyme of rhymes) {
    totalScanned++;
    const rhymeId = rhyme.$id;
    const titleLatin = rhyme.titleLatin || rhyme.title || 'Untitled';
    const categoryId = rhyme.categoryId;
    const currentCategory = rhyme.category;

    if (VERBOSE) {
      console.log(`📄 Scanning [${rhymeId}] ("${titleLatin}"): categoryId="${categoryId || 'none'}", category="${currentCategory || 'null'}"`);
    }

    if (currentCategory && currentCategory.trim().length > 0) {
      alreadyHadCategory++;
      if (VERBOSE) {
        console.log(`   [SKIP] Already has category="${currentCategory}"`);
      }
      continue;
    }

    if (!categoryId || categoryId.trim().length === 0) {
      missingCategoryId++;
      if (VERBOSE) {
        console.log(`   [SKIP] No categoryId present`);
      }
      continue;
    }

    // Resolve category title
    let categoryTitle = categoryCache[categoryId];
    if (categoryTitle === undefined) {
      try {
        const catDoc = runCli([
          'databases', 'get-document',
          '--database-id', DATABASE_ID,
          '--collection-id', 'categories',
          '--document-id', categoryId
        ]);
        categoryTitle = catDoc.titleLatin || catDoc.title || catDoc.name || '';
        categoryCache[categoryId] = categoryTitle;
      } catch (e) {
        console.warn(`   [WARN] Category document [${categoryId}] referenced by rhyme [${rhymeId}] ("${titleLatin}") does not exist.`);
        categoryCache[categoryId] = null;
        categoryTitle = null;
      }
    }

    if (categoryTitle === null || categoryTitle === '') {
      missingCategoryDoc++;
      continue;
    }

    updatedOrWouldUpdate++;
    if (DRY_RUN) {
      console.log(`🚫 [DRY-RUN] Would update [${rhymeId}] ("${titleLatin}"): category=null → category="${categoryTitle}"`);
    } else {
      try {
        console.log(`🔥 Updating [${rhymeId}] ("${titleLatin}"): category=null → category="${categoryTitle}"...`);
        runCli([
          'databases', 'update-document',
          '--database-id', DATABASE_ID,
          '--collection-id', 'rhymes',
          '--document-id', rhymeId,
          '--data', JSON.stringify({ category: categoryTitle })
        ]);
        console.log(`   ✅ Successfully updated!`);
      } catch (e) {
        errors++;
        console.error(`   ❌ Failed to update [${rhymeId}]: ${e.message}`);
      }
    }
  }

  console.log(`\n=============================================================`);
  console.log(`📊 Backfill Summary:`);
  console.log(`=============================================================`);
  console.log(`  Total rhymes scanned:      ${totalScanned}`);
  console.log(`  Already had category:      ${alreadyHadCategory} [SKIP]`);
  console.log(`  Missing categoryId:        ${missingCategoryId} [SKIP]`);
  console.log(`  Missing category doc:      ${missingCategoryDoc} [WARN]`);
  console.log(`  Updated (or would update): ${updatedOrWouldUpdate}`);
  console.log(`  Errors:                    ${errors}`);
  console.log(`=============================================================`);

  if (DRY_RUN) {
    console.log(`\n💡 Run with '--apply' flag to perform actual database updates.`);
  } else {
    console.log(`\n🎉 Backfill execution completed!`);
  }
}

run().catch((e) => console.error('\n❌ Backfill Script Failed:', e.message));
