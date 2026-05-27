/**
 * Standalone Migration Script for Rhymes play-along audio track conversion.
 * Migrates legacy audio blocks from `blocks` array to the new top-level database fields.
 * Performs a collection backup to scripts/backups/ prior to run.
 *
 * Usage:
 *   node scripts/migrate_rhyme_audio_blocks.mjs --dry-run
 *   node scripts/migrate_rhyme_audio_blocks.mjs --apply
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

function extractFileIdFromUrl(url) {
  if (!url) return null;
  // Appwrite URL pattern: .../storage/buckets/{bucket}/files/{fileId}/view?...
  const match = url.match(/\/files\/([^/]+)\/view/);
  return match ? match[1] : null;
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
  console.log(`🚀 Starting Rhymes Audio Migration...`);
  console.log(`Endpoint: ${ENDPOINT}`);
  console.log(`Project:  ${PROJECT_ID}`);
  console.log(`Mode:     ${DRY_RUN ? 'DRY-RUN (No changes will be saved)' : 'APPLY (Mutating database)'}\n`);

  // 1. Fetch categories for resolving categoryId
  console.log('Fetching categories collection...');
  let categoryByName = new Map();
  try {
    const categoriesResult = await api('GET', `/databases/${DATABASE_ID}/collections/categories/documents?limit=100`);
    const categoryDocs = categoriesResult.documents || [];
    for (const c of categoryDocs) {
      const name = c.titleLatin || c.name || c.title;
      if (name && c.$id) {
        categoryByName.set(name.toLowerCase(), c.$id);
      }
    }
    console.log(`  ✓ Loaded ${categoryByName.size} categories for lookup.\n`);
  } catch (err) {
    console.error('⚠️ Warning: Failed to load categories. Category ID resolution will be skipped:', err.message);
  }

  // 2. Fetch all rhymes documents
  console.log('Fetching rhymes documents...');
  const listRes = await api('GET', `/databases/${DATABASE_ID}/collections/${COLLECTION_ID}/documents?limit=1000`);
  const docs = listRes.documents || [];
  console.log(`Found ${docs.length} documents.`);

  if (docs.length === 0) {
    console.log('No documents found to migrate.');
    return;
  }

  // 3. Perform Backup (must exist and run before any apply/dry-run)
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupDir = './scripts/backups';
  try {
    mkdirSync(backupDir, { recursive: true });
  } catch (_) {}
  const backupPath = join(backupDir, `rhymes_backup_${timestamp}.json`);
  writeFileSync(backupPath, JSON.stringify(docs, null, 2), 'utf8');
  console.log(`✅ Pre-run collection backup written to: ${backupPath}\n`);

  // 4. Process documents
  let migratedCount = 0;
  let skippedCount = 0;

  for (const doc of docs) {
    let blocks = [];
    if (doc.blocks) {
      try {
        blocks = typeof doc.blocks === 'string' ? JSON.parse(doc.blocks) : doc.blocks;
      } catch (_) {
        console.warn(`⚠️ Warning: Failed to parse blocks for doc ${doc.$id}`);
      }
    }

    // Find any audio blocks
    let audioUrl = doc.audioUrl || '';
    let audioFileId = doc.audioFileId || '';
    let durationMs = doc.durationMs || null;
    let hasLegacyAudio = false;

    let audioBlock = null;
    if (Array.isArray(blocks)) {
      audioBlock = blocks.find(b => b.type === 'audio');
      if (audioBlock && audioBlock.media) {
        audioUrl = audioBlock.media.url || audioUrl;
        audioFileId = audioBlock.media.fileId || audioFileId;
        durationMs = audioBlock.media.durationMs || durationMs;
        hasLegacyAudio = true;
      }
    }

    // 1. Empty fileId -> extract from URL fallback
    const legacyFileId = audioFileId;
    const urlFileId = extractFileIdFromUrl((audioBlock && audioBlock.media && audioBlock.media.url) || doc.audioUrl);
    if ((!legacyFileId || legacyFileId.trim().length === 0) && urlFileId) {
      audioFileId = urlFileId;
      console.log(`  ℹ️  Extracted audioFileId from URL: ${urlFileId}`);
    }

    // 2. Filter, don't wipe blocks
    const remainingBlocks = Array.isArray(blocks) ? blocks.filter(b => b.type !== 'audio') : [];
    const newBlocksJson = JSON.stringify(remainingBlocks);

    // 3. Resolve categoryId from category string if null/missing
    let categoryId = doc.categoryId || null;
    if (!categoryId && doc.category) {
      const resolvedId = categoryByName.get(doc.category.toLowerCase());
      if (resolvedId) {
        categoryId = resolvedId;
        console.log(`  ✓ Resolved categoryId from category="${doc.category}" → ${resolvedId}`);
      } else {
        console.warn(`  ⚠️  Could not resolve category "${doc.category}" — leaving null`);
      }
    }

    // Check if we actually need to migrate
    const currentBlocksJson = typeof doc.blocks === 'string' ? doc.blocks : JSON.stringify(doc.blocks || []);
    const blocksChanged = currentBlocksJson !== newBlocksJson;
    const audioFileIdChanged = doc.audioFileId !== audioFileId;
    const categoryIdChanged = doc.categoryId !== categoryId;

    const needsMigration = hasLegacyAudio || blocksChanged || audioFileIdChanged || categoryIdChanged;

    if (!needsMigration) {
      skippedCount++;
      continue;
    }

    migratedCount++;
    const payload = {
      audioUrl: audioUrl || null,
      audioFileId: audioFileId || null,
      durationMs: durationMs || null,
      blocks: newBlocksJson
    };
    if (categoryId) {
      payload.categoryId = categoryId;
    }

    console.log(`Document [${doc.$id}] - "${doc.titleLatin}"`);
    console.log(`  Current audioUrl:    "${doc.audioUrl || 'none'}"`);
    console.log(`  Current audioFileId: "${doc.audioFileId || 'none'}"`);
    console.log(`  Current categoryId:  "${doc.categoryId || 'none'}"`);
    console.log(`  Legacy blocks:       ${doc.blocks}`);
    console.log(`  Migrating to:        audioUrl="${payload.audioUrl}", audioFileId="${payload.audioFileId}", categoryId="${payload.categoryId || 'none'}", blocks="${newBlocksJson}"`);

    if (!DRY_RUN) {
      await api('PATCH', `/databases/${DATABASE_ID}/collections/${COLLECTION_ID}/documents/${doc.$id}`, {
        data: payload
      });
      console.log(`  ⚡ Updated successfully.`);
    }
    console.log();
  }

  console.log(`Migration summary:`);
  console.log(`  Total documents: ${docs.length}`);
  console.log(`  Migrated:        ${migratedCount}`);
  console.log(`  Skipped:         ${skippedCount}`);
  console.log(DRY_RUN ? 'Done! (Dry run completed without database changes)' : 'Done! Database updated successfully! 🎉');
}

run().catch((e) => console.error('❌ Migration failed:', e));
