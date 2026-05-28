/**
 * Rhyme Cover Media Types Backfill Script
 * 
 * Lists all rhymes in the rhymes collection.
 * For each rhyme where coverMediaType is null/empty:
 *   - If thumbnailUrl is present or hero_media JSON contains an image-kind media, set coverMediaType: 'image'.
 *   - If hero_media JSON contains a video-kind media, set coverMediaType: 'video'.
 *   - Otherwise, set coverMediaType: 'image' as default.
 * 
 * Default mode is --dry-run. Pass --apply to save changes.
 * 
 * Usage:
 *   node scripts/backfill_rhyme_cover_media_types.mjs [--apply] [--verbose]
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
  console.log(`🚀 Starting Rhyme Cover Media Types Backfill...`);
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
  const backupPath = join(backupDir, `rhymes_pre_cover_media_type_${timestamp}.json`);
  try {
    writeFileSync(backupPath, JSON.stringify(rhymes, null, 2), 'utf8');
    console.log(`✅ Pre-run collection backup written to: ${backupPath}\n`);
  } catch (e) {
    console.error(`❌ Failed to write backup: ${e.message}`);
    process.exit(1);
  }

  let totalScanned = 0;
  let alreadyHadType = 0;
  let updatedOrWouldUpdate = 0;
  let errors = 0;

  for (const rhyme of rhymes) {
    totalScanned++;
    const rhymeId = rhyme.$id;
    const titleLatin = rhyme.titleLatin || rhyme.title || 'Untitled';
    const currentType = rhyme.coverMediaType;

    if (VERBOSE) {
      console.log(`📄 Scanning [${rhymeId}] ("${titleLatin}"): coverMediaType="${currentType || 'null'}"`);
    }

    if (currentType && currentType.trim().length > 0) {
      alreadyHadType++;
      if (VERBOSE) {
        console.log(`   [SKIP] Already has coverMediaType="${currentType}"`);
      }
      continue;
    }

    // Determine cover media type
    let resolvedType = 'image'; // default
    const heroMediaRaw = rhyme.hero_media;
    const thumbnailUrl = rhyme.thumbnailUrl;

    if (heroMediaRaw && heroMediaRaw.trim().length > 0) {
      try {
        const parsedHero = JSON.parse(heroMediaRaw);
        const kind = parsedHero.kind || parsedHero.type;
        if (kind === 'video') {
          resolvedType = 'video';
        } else if (kind === 'image' || kind === 'svg') {
          resolvedType = 'image';
        }
      } catch (e) {
        console.warn(`   [WARN] Failed to parse hero_media JSON for [${rhymeId}]: ${e.message}. Defaulting to 'image'.`);
      }
    } else if (thumbnailUrl && thumbnailUrl.trim().length > 0) {
      resolvedType = 'image';
    }

    if (thumbnailUrl && heroMediaRaw) {
      try {
        const parsedHero = JSON.parse(heroMediaRaw);
        const kind = parsedHero.kind || parsedHero.type;
        if (kind === 'video') {
          console.warn(`   [WARN] Conflicting cover media fields on [${rhymeId}]: thumbnailUrl exists but hero_media is video. Defaulting to 'image'.`);
          resolvedType = 'image'; // existing behavior conflict defaults to image
        }
      } catch (_) {}
    }

    updatedOrWouldUpdate++;
    if (DRY_RUN) {
      console.log(`🚫 [DRY-RUN] Would update [${rhymeId}] ("${titleLatin}"): coverMediaType=null → coverMediaType="${resolvedType}"`);
    } else {
      try {
        console.log(`🔥 Updating [${rhymeId}] ("${titleLatin}"): coverMediaType=null → coverMediaType="${resolvedType}"...`);
        runCli([
          'databases', 'update-document',
          '--database-id', DATABASE_ID,
          '--collection-id', 'rhymes',
          '--document-id', rhymeId,
          '--data', JSON.stringify({ coverMediaType: resolvedType })
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
  console.log(`  Already had type:          ${alreadyHadType} [SKIP]`);
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
