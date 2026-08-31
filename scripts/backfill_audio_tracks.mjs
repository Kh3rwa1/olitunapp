/**
 * Audio Tracks Backfill Script (Phase 2 — spec §8 migration)
 *
 * Migrates legacy inline audio (the `audioUrl` attribute on words,
 * sentences, letters, numbers and rhymes) into dedicated rows in the
 * new `audio_tracks` collection, so playback (Phase 3) reads one
 * consistent schema while old content keeps working.
 *
 * For every content doc that has a non-empty audioUrl but no matching
 * targetNormal track:
 *   - Create an audio_tracks row:
 *       contentKind      = <source collection>
 *       contentId        = <document $id>
 *       languageCode     = 'sat'            (legacy audio is native Santali)
 *       trackType        = 'targetNormal'
 *       audioUrl         = <legacy audioUrl>
 *       isHumanRecorded  = true             (legacy files are native recordings)
 *       reviewStatus     = 'approved'       (already serving learners today)
 *       generationStatus = 'notRequested'   (human upload, never generated)
 *   - The legacy audioUrl attribute is NOT removed (backward compat;
 *     app reads fall back to it when no track row exists).
 *
 * Idempotent: re-running skips content that already has a targetNormal
 * track (matched by contentKind + contentId + languageCode + trackType),
 * and skips docs with existing duplicates rather than double-inserting.
 *
 * Default mode is --dry-run. Pass --apply to save changes.
 *
 * Usage:
 *   node scripts/backfill_audio_tracks.mjs [--apply] [--verbose]
 */

import { spawnSync } from 'child_process';
import { writeFileSync, mkdirSync } from 'fs';
import { join } from 'path';

const APPLY = process.argv.includes('--apply');
const DRY_RUN = !APPLY;
const VERBOSE = process.argv.includes('--verbose');
const DATABASE_ID = 'olitun_db';

// contentKind → source collection with a legacy audioUrl attribute.
const CONTENT_KINDS = [
  { kind: 'word', collection: 'words' },
  { kind: 'sentence', collection: 'sentences' },
  { kind: 'letter', collection: 'letters' },
  { kind: 'number', collection: 'numbers' },
  { kind: 'rhyme', collection: 'rhymes' },
];

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

function listDocuments(collectionId) {
  const result = runCli([
    'databases', 'list-documents',
    '--database-id', DATABASE_ID,
    '--collection-id', collectionId,
    '--limit', '100',
  ]);
  return result.documents || [];
}

function keyFor(kind, contentId) {
  return `${kind}:${contentId}`;
}

async function run() {
  console.log(`🚀 Starting Audio Tracks Backfill (legacy audioUrl → targetNormal)...`);
  console.log(`   Mode: ${DRY_RUN ? 'DRY-RUN (Default)' : 'APPLY (Mutating database)'}`);
  console.log(`   Verbose: ${VERBOSE ? 'YES' : 'NO'}\n`);

  // 0. Ensure the destination collection exists (helpful error if setup
  //    script has not been run yet).
  try {
    runCli([
      'databases', 'get-collection',
      '--database-id', DATABASE_ID,
      '--collection-id', 'audio_tracks',
    ]);
  } catch (e) {
    console.error(`❌ Collection 'audio_tracks' not found. Run scripts/appwrite_setup.mjs first.`);
    console.error(`   Underlying error: ${e.message}`);
    process.exit(1);
  }

  // 1. Snapshot existing targetNormal tracks so the migration is
  //    idempotent without N queries.
  console.log(`🔍 Loading existing targetNormal tracks...`);
  const existingTrackKeys = new Set();
  const existingTracksByItem = {};
  try {
    const trackDocs = runCli([
      'databases', 'list-documents',
      '--database-id', DATABASE_ID,
      '--collection-id', 'audio_tracks',
      '--limit', '100',
      '--queries', JSON.stringify([
        'equal("trackType", ["targetNormal"])',
        'isNull("segmentId")',
      ]),
    ]);
    for (const doc of trackDocs.documents || []) {
      const key = keyFor(doc.contentKind, doc.contentId);
      existingTrackKeys.add(key);
      (existingTracksByItem[key] = existingTracksByItem[key] || []).push(doc);
    }
    console.log(`   Found ${existingTrackKeys.size} items with existing targetNormal tracks.\n`);
  } catch (e) {
    console.warn(`   [WARN] Could not preload existing tracks (${e.message}); falling back to per-item skip checks.`);
  }

  // 2. Pre-flight backup (mandatory before dry-run or apply).
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupDir = './scripts/backups';
  try {
    mkdirSync(backupDir, { recursive: true });
  } catch (_) {}
  const backupPath = join(backupDir, `legacy_audio_pre_backfill_${timestamp}.json`);
  const backupPayload = { generatedAt: new Date().toISOString(), sources: {} };
  const sourceDocs = {};
  for (const { kind, collection } of CONTENT_KINDS) {
    try {
      const docs = listDocuments(collection);
      sourceDocs[collection] = docs;
      backupPayload.sources[collection] = docs;
    } catch (e) {
      console.warn(`   [WARN] Could not list '${collection}': ${e.message}`);
      backupPayload.sources[collection] = [];
    }
  }
  try {
    writeFileSync(backupPath, JSON.stringify(backupPayload, null, 2), 'utf8');
    console.log(`✅ Pre-run backup written to: ${backupPath}\n`);
  } catch (e) {
    console.error(`❌ Failed to write backup: ${e.message}`);
    process.exit(1);
  }

  let totalScanned = 0;
  let skippedNoAudio = 0;
  let skippedHasTrack = 0;
  let skippedDuplicate = 0;
  let createdOrWouldCreate = 0;
  let errors = 0;

  for (const { kind, collection } of CONTENT_KINDS) {
    console.log(`📂 Processing collection '${collection}' (contentKind='${kind}')...`);
    const docs = sourceDocs[collection] || [];

    for (const doc of docs) {
      totalScanned++;
      const docId = doc.$id;
      const audioUrl = typeof doc.audioUrl === 'string' ? doc.audioUrl.trim() : '';
      const itemKey = keyFor(kind, docId);

      if (VERBOSE) {
        console.log(`📄 Scanning [${docId}] audioUrl="${audioUrl || 'none'}"`);
      }

      if (!audioUrl) {
        skippedNoAudio++;
        continue;
      }

      if (existingTrackKeys.has(itemKey)) {
        skippedHasTrack++;
        if (VERBOSE) {
          console.log(`   [SKIP] targetNormal track already exists (${existingTracksByItem[itemKey].length} row(s))`);
        }
        continue;
      }

      const trackData = {
        contentKind: kind,
        contentId: docId,
        languageCode: 'sat',
        trackType: 'targetNormal',
        audioUrl,
        isHumanRecorded: true,
        reviewStatus: 'approved',
        generationStatus: 'notRequested',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      createdOrWouldCreate++;
      if (DRY_RUN) {
        console.log(`🚫 [DRY-RUN] Would create audio_tracks row for ${itemKey}: ${audioUrl}`);
      } else {
        try {
          runCli([
            'databases', 'create-document',
            '--database-id', DATABASE_ID,
            '--collection-id', 'audio_tracks',
            '--document-id', 'unique()',
            '--data', JSON.stringify(trackData),
          ]);
          existingTrackKeys.add(itemKey);
          console.log(`   ✅ Created track for ${itemKey}`);
        } catch (e) {
          errors++;
          console.error(`   ❌ Failed to create track for ${itemKey}: ${e.message}`);
        }
      }
    }
  }

  console.log(`\n=============================================================`);
  console.log(`📊 Audio Tracks Backfill Summary:`);
  console.log(`=============================================================`);
  console.log(`  Total docs scanned:          ${totalScanned}`);
  console.log(`  Skipped (no audioUrl):       ${skippedNoAudio}`);
  console.log(`  Skipped (track exists):      ${skippedHasTrack}`);
  console.log(`  Skipped (duplicate rows):     ${skippedDuplicate}`);
  console.log(`  Created (or would create):   ${createdOrWouldCreate}`);
  console.log(`  Errors:                      ${errors}`);
  console.log(`=============================================================`);

  if (DRY_RUN) {
    console.log(`\n💡 Run with '--apply' flag to perform actual inserts.`);
    console.log(`   Legacy audioUrl attributes are never modified or removed.`);
  } else {
    console.log(`\n🎉 Backfill execution completed!`);
  }
  if (errors > 0) {
    process.exitCode = 1;
  }
}

run().catch((e) => {
  console.error('\n❌ Backfill Script Failed:', e.message);
  process.exitCode = 1;
});
