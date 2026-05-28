/**
 * Orphan Media Cleanup Script
 * Scans Appwrite storage buckets (audio, cover_videos) for orphaned files and cleans them up.
 * Uses Appwrite CLI for native, authenticated API requests.
 * Default mode is --dry-run. Pass --apply to actually delete files.
 *
 * Usage:
 *   node scripts/cleanup_orphaned_media.mjs [--apply] [--dry-run]
 */

import { execSync } from 'child_process';

const APPLY = process.argv.includes('--apply');
const DRY_RUN = !APPLY || process.argv.includes('--dry-run');
const DATABASE_ID = 'olitun_db';

function runCli(args) {
  try {
    const cmd = `appwrite ${args} --json`;
    const output = execSync(cmd, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] });
    return JSON.parse(output.trim());
  } catch (e) {
    throw new Error(`CLI execution failed: ${e.message}`);
  }
}

/**
 * Recursively scans any object or array to extract all string values
 * that match typical Appwrite file ID pattern or URL paths.
 */
function extractFileIds(obj, set) {
  if (!obj) return;
  if (typeof obj === 'string') {
    // Match direct fileIds or url file pattern /files/([a-zA-Z0-9]+)
    const match = obj.match(/\/files\/([a-zA-Z0-9]+)/);
    if (match) {
      set.add(match[1]);
    }
    // Also capture strings that are 20-character alphanumeric IDs (Appwrite ID style)
    if (/^[a-zA-Z0-9]{20}$/.test(obj)) {
      set.add(obj);
    }
  } else if (Array.isArray(obj)) {
    for (const item of obj) {
      extractFileIds(item, set);
    }
  } else if (typeof obj === 'object') {
    for (const key in obj) {
      // Explicitly check common keys
      if (key === 'fileId' || key === 'audioFileId' || key === 'imageFileId') {
        if (typeof obj[key] === 'string' && obj[key].length > 0) {
          set.add(obj[key]);
        }
      }
      extractFileIds(obj[key], set);
    }
  }
}

/**
 * Generic bucket-agnostic function to scan a bucket and clean up orphaned files.
 */
async function cleanupBucket({ bucketId, collections, customExtractFilter }) {
  console.log(`\n=============================================================`);
  console.log(`🧹 SCANNING BUCKET: [${bucketId}]`);
  console.log(`=============================================================`);

  // 1. Fetch all referenced file IDs from database collections
  const referencedFileIds = new Set();

  for (const col of collections) {
    console.log(`🔍 Scanning database collection: [${col.collectionId}]`);
    try {
      const args = `databases list-documents --database-id ${DATABASE_ID} --collection-id ${col.collectionId}`;
      const res = runCli(args);
      const docs = res.documents || [];

      for (const doc of docs) {
        // Apply custom doc filter if configured (e.g. coverMediaType === 'video' for cover_videos)
        if (customExtractFilter && !customExtractFilter(doc)) {
          continue;
        }

        for (const field of col.fieldPaths) {
          const val = doc[field];
          if (!val) continue;

          // If the field is a string and looks like a JSON array/object, try to parse it
          if (typeof val === 'string' && (val.startsWith('[') || val.startsWith('{'))) {
            try {
              const parsed = JSON.parse(val);
              extractFileIds(parsed, referencedFileIds);
            } catch (_) {
              extractFileIds(val, referencedFileIds);
            }
          } else {
            extractFileIds(val, referencedFileIds);
          }
        }
      }

      console.log(`   Read ${docs.length} documents, total references found so far: ${referencedFileIds.size}`);
    } catch (e) {
      console.warn(`⚠️  Failed to scan collection [${col.collectionId}]: ${e.message}`);
    }
  }

  // 2. Fetch all files currently present in storage bucket
  console.log(`\n📦 Fetching files in storage bucket: [${bucketId}]`);
  const bucketFiles = [];
  try {
    const args = `storage list-files --bucket-id ${bucketId}`;
    const res = runCli(args);
    const files = res.files || [];
    bucketFiles.push(...files);
  } catch (e) {
    console.error(`❌ Failed to list files in bucket [${bucketId}]: ${e.message}`);
  }

  console.log(`   Total files in storage bucket [${bucketId}]: ${bucketFiles.length}`);

  // 3. Identify and process orphans
  const now = new Date();
  const ONE_HOUR_MS = 60 * 60 * 1000;
  let orphanedCount = 0;
  let deletedCount = 0;
  let skippedSafeCount = 0;

  console.log(`\n📋 Analyzing files...`);
  for (const file of bucketFiles) {
    const fileId = file.$id;
    const isReferenced = referencedFileIds.has(fileId);

    if (!isReferenced) {
      // Orphan detected!
      orphanedCount++;
      const createdAt = new Date(file.$createdAt);
      const ageMs = now - createdAt;
      const isSafeWindow = ageMs < ONE_HOUR_MS;

      if (isSafeWindow) {
        skippedSafeCount++;
        console.log(`⚠️  [IN-FLIGHT SAFE] Orphaned file [${fileId}] (created: ${file.$createdAt}) is < 1 hour old. Skipping deletion.`);
      } else {
        const ageHours = (ageMs / (1000 * 60 * 60)).toFixed(1);
        if (DRY_RUN) {
          console.log(`🚫  [DRY-RUN] Would delete orphaned file [${fileId}] (created: ${file.$createdAt}, age: ${ageHours}h, size: ${file.sizeOriginal} bytes)`);
        } else {
          try {
            console.log(`🔥  Deleting orphaned file [${fileId}] (created: ${file.$createdAt}, age: ${ageHours}h, size: ${file.sizeOriginal} bytes)...`);
            const args = `storage delete-file --bucket-id ${bucketId} --file-id ${fileId}`;
            runCli(args);
            deletedCount++;
          } catch (e) {
            console.error(`❌  Failed to delete file [${fileId}]: ${e.message}`);
          }
        }
      }
    }
  }

  console.log(`\n📊 Bucket Scan Summary: [${bucketId}]`);
  console.log(`   - Total Files in Bucket: ${bucketFiles.length}`);
  console.log(`   - Referenced Files:     ${bucketFiles.length - orphanedCount}`);
  console.log(`   - Total Orphans Found:  ${orphanedCount}`);
  console.log(`     - Skipped (In-flight): ${skippedSafeCount}`);
  console.log(`     - Processed/Eligible:  ${orphanedCount - skippedSafeCount}`);
  if (DRY_RUN) {
    console.log(`   - [DRY-RUN] No deletions were made. Run with --apply to clean up.`);
  } else {
    console.log(`   - Successfully deleted: ${deletedCount} files.`);
  }
}

async function run() {
  console.log(`🚀 Starting Orphan Media Cleanup...`);
  console.log(`   Mode: ${DRY_RUN ? 'DRY RUN (Default)' : 'APPLY (Destructive Cleanup)'}`);

  // 1. Audio Bucket Scan
  const audioCollections = [
    {
      collectionId: 'rhymes',
      fieldPaths: ['audioFileId', 'audioUrl', 'blocks']
    },
    {
      collectionId: 'bakhed_vocabulary',
      fieldPaths: ['audioFileId']
    },
    {
      collectionId: 'lessons',
      fieldPaths: ['blocks', 'hero_media']
    },
    {
      collectionId: 'stories',
      fieldPaths: ['blocks', 'hero_media']
    }
  ];

  await cleanupBucket({
    bucketId: 'audio',
    collections: audioCollections
  });

  // 2. Cover Videos Bucket Scan
  const coverVideoCollections = [
    {
      collectionId: 'rhymes',
      fieldPaths: ['hero_media', 'heroMedia']
    }
  ];

  await cleanupBucket({
    bucketId: 'cover_videos',
    collections: coverVideoCollections,
    customExtractFilter: (doc) => doc.coverMediaType === 'video'
  });

  console.log('\n🎉 Cleanup process finished!');
}

run().catch((e) => console.error('\n❌ Cleanup Script Failed:', e.message));
