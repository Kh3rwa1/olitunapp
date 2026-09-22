#!/usr/bin/env node
/**
 * Bodhan AI Audio Generator for Sentences (Olitun App)
 *
 * 1. Cleans up existing sentence audio files (`sentence_*`) from Appwrite storage bucket `audio`.
 * 2. Fetches all 250 sentence documents from Appwrite database `olitun_db.sentences`.
 * 3. Synthesizes audio using Bodhan AI (`model: indic-speak`, `voice: Phulmani`, `instructions: {"lang": "sat"}`)
 *    rotating round-robin across all 8 available API keys in `.keys/bodhan0`..`bodhan7`.
 * 4. Uploads each audio file to Appwrite storage bucket `audio` with ID `sentence_${docId}`.
 * 5. Updates each document in Appwrite collection `sentences` with its public `audioUrl`.
 * 6. Validates completeness across storage and database.
 */

import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const rootDir = join(__dirname, '..');

// Configuration
const ENDPOINT = process.env.APPWRITE_ENDPOINT || 'https://sgp.cloud.appwrite.io/v1';
const PROJECT_ID = process.env.APPWRITE_PROJECT_ID || '699495910038e39622c5';
const DATABASE_ID = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
const COLLECTION_ID = 'sentences';
const BUCKET_ID = 'audio';

const BODHAN_URL = process.env.BODHAN_URL || 'https://api.bodhan.ai/v1/audio/speech';
const MODEL = 'indic-speak';
const VOICE = 'Phulmani';
const INSTRUCTIONS = '{"lang": "sat"}';

const DELETE_EXISTING = process.env.DELETE_EXISTING !== '0';
const DRY_RUN = process.env.DRY_RUN === '1';
const DELAY_MS = parseInt(process.env.DELAY_MS || '400', 10);
const ONLY_IDS = (process.env.ONLY_IDS || '')
  .split(',')
  .map((s) => s.trim().toLowerCase())
  .filter(Boolean);

// Load Bodhan keys
function loadBodhanKeys() {
  const keys = [];
  for (let i = 0; i < 10; i++) {
    const keyPath = join(rootDir, '.keys', `bodhan${i}`);
    if (existsSync(keyPath)) {
      const key = readFileSync(keyPath, 'utf8').trim();
      if (key) {
        keys.push({ id: `bodhan${i}`, key });
      }
    }
  }
  if (keys.length === 0) {
    if (process.env.BODHAN_API_KEY) {
      keys.push({ id: 'env_key', key: process.env.BODHAN_API_KEY.trim() });
    } else {
      throw new Error('No Bodhan API keys found in .keys/bodhan* or BODHAN_API_KEY env var.');
    }
  }
  return keys;
}

// Appwrite authentication headers from CLI session
function getAppwriteHeaders(isJson = false) {
  const prefsPath = join(process.env.HOME || '', '.appwrite', 'prefs.json');
  if (!existsSync(prefsPath)) {
    throw new Error(`Appwrite prefs not found at ${prefsPath}`);
  }
  const prefs = JSON.parse(readFileSync(prefsPath, 'utf8'));
  const p = prefs[PROJECT_ID];
  if (!p || !p.cookie) {
    throw new Error(`No active Appwrite CLI session cookie found for project ${PROJECT_ID}`);
  }
  const headers = {
    'X-Appwrite-Project': PROJECT_ID,
    'X-Appwrite-Mode': 'admin',
    Cookie: p.cookie.split(';')[0],
  };
  if (isJson) {
    headers['Content-Type'] = 'application/json';
  }
  return headers;
}

const viewUrl = (fileId) => `${ENDPOINT}/storage/buckets/${BUCKET_ID}/files/${fileId}/view?project=${PROJECT_ID}`;

// Appwrite API Helpers
async function fetchAllSentenceFiles() {
  const headers = getAppwriteHeaders(false);
  const files = [];
  let offset = 0;
  for (;;) {
    const params = new URLSearchParams();
    params.append('search', 'sentence_');
    params.append('queries[]', JSON.stringify({ method: 'limit', values: [100] }));
    params.append('queries[]', JSON.stringify({ method: 'offset', values: [offset] }));
    const res = await fetch(`${ENDPOINT}/storage/buckets/${BUCKET_ID}/files?${params}`, { headers });
    if (!res.ok) {
      throw new Error(`List files failed (${res.status}): ${await res.text()}`);
    }
    const json = await res.json();
    const batch = (json.files || []).filter((f) => f.$id.startsWith('sentence_'));
    files.push(...batch);
    if ((json.files || []).length < 100) break;
    offset += 100;
  }
  return files;
}

async function deleteStorageFile(fileId) {
  const headers = getAppwriteHeaders(false);
  const res = await fetch(`${ENDPOINT}/storage/buckets/${BUCKET_ID}/files/${fileId}`, {
    method: 'DELETE',
    headers,
  });
  if (res.status === 404) return true;
  if (!res.ok) {
    throw new Error(`Delete ${fileId} failed (${res.status}): ${await res.text()}`);
  }
  return true;
}

async function fetchAllSentences() {
  const headers = getAppwriteHeaders(true);
  const docs = [];
  let offset = 0;
  for (;;) {
    const params = new URLSearchParams();
    params.append('queries[]', JSON.stringify({ method: 'limit', values: [100] }));
    params.append('queries[]', JSON.stringify({ method: 'offset', values: [offset] }));
    const res = await fetch(
      `${ENDPOINT}/databases/${DATABASE_ID}/collections/${COLLECTION_ID}/documents?${params}`,
      { headers }
    );
    if (!res.ok) {
      throw new Error(`List sentences failed (${res.status}): ${await res.text()}`);
    }
    const json = await res.json();
    docs.push(...(json.documents || []));
    if ((json.documents || []).length < 100) break;
    offset += 100;
  }
  return docs;
}

async function uploadAudioFile(fileId, audioBuffer) {
  const appwriteHeaders = getAppwriteHeaders(false);
  const base = `${ENDPOINT}/storage/buckets/${BUCKET_ID}/files`;
  const boundary = '----BodhanBoundary' + Math.random().toString(36).substring(2);
  const head = [
    `--${boundary}`,
    'Content-Disposition: form-data; name="fileId"',
    '',
    fileId,
    `--${boundary}`,
    `Content-Disposition: form-data; name="file"; filename="${fileId}.wav"`,
    'Content-Type: audio/wav',
    '',
    '',
  ].join('\r\n');
  const body = Buffer.concat([
    Buffer.from(head, 'utf8'),
    audioBuffer,
    Buffer.from(`\r\n--${boundary}--\r\n`),
  ]);
  const res = await fetch(base, {
    method: 'POST',
    headers: {
      ...appwriteHeaders,
      'Content-Type': `multipart/form-data; boundary=${boundary}`,
    },
    body,
  });
  if (res.status === 409) {
    // If already exists, return the view url
    return viewUrl(fileId);
  }
  if (!res.ok) {
    const errText = await res.text().catch(() => '');
    throw new Error(`Upload ${fileId} failed (${res.status}): ${errText.slice(0, 150)}`);
  }
  const json = await res.json();
  return viewUrl(json.$id);
}

async function patchSentenceDocument(docId, audioUrl) {
  const headers = getAppwriteHeaders(true);
  const res = await fetch(
    `${ENDPOINT}/databases/${DATABASE_ID}/collections/${COLLECTION_ID}/documents/${docId}`,
    {
      method: 'PATCH',
      headers,
      body: JSON.stringify({ data: { audioUrl } }),
    }
  );
  if (!res.ok) {
    const errText = await res.text().catch(() => '');
    throw new Error(`Patch ${docId} failed (${res.status}): ${errText.slice(0, 150)}`);
  }
}

// Bodhan TTS with Key Rotation & Backoff
class BodhanRotator {
  constructor(keys) {
    this.keys = keys;
    this.currentIndex = 0;
  }

  getKey() {
    return this.keys[this.currentIndex];
  }

  rotate() {
    this.currentIndex = (this.currentIndex + 1) % this.keys.length;
    return this.getKey();
  }

  async synthesize(text, maxRetries = 10) {
    const payload = {
      model: MODEL,
      input: text.slice(0, 2500),
      voice: VOICE,
      instructions: INSTRUCTIONS,
    };

    let lastError = null;
    for (let attempt = 0; attempt < maxRetries; attempt++) {
      const activeKeyObj = this.getKey();
      try {
        const res = await fetch(BODHAN_URL, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${activeKeyObj.key}`,
          },
          body: JSON.stringify(payload),
        });

        if (res.status === 429) {
          // Rate limited on current key -> rotate immediately to next key and small pause
          process.stdout.write(`⚠️ [${activeKeyObj.id} 429, rotating] `);
          this.rotate();
          await new Promise((r) => setTimeout(r, 1000));
          continue;
        }

        if (!res.ok) {
          const errText = await res.text().catch(() => '');
          lastError = new Error(`HTTP ${res.status}: ${errText.slice(0, 100)}`);
          this.rotate();
          await new Promise((r) => setTimeout(r, 2000));
          continue;
        }

        const buf = Buffer.from(await res.arrayBuffer());
        if (buf.length < 1000 || buf.subarray(0, 4).toString() !== 'RIFF') {
          throw new Error(`Invalid WAV payload received (${buf.length} bytes)`);
        }

        // Rotate key for the next sentence to distribute load evenly
        const usedKeyId = activeKeyObj.id;
        this.rotate();
        return { buffer: buf, keyId: usedKeyId };
      } catch (err) {
        lastError = err;
        this.rotate();
        await new Promise((r) => setTimeout(r, 2000));
      }
    }
    throw lastError || new Error('Bodhan TTS failed after multiple key rotations');
  }
}

async function main() {
  console.log('═══════════════════════════════════════════════════════════════════════');
  console.log('       Olitun Sentences Audio Regeneration (Bodhan AI - Phulmani)     ');
  console.log('═══════════════════════════════════════════════════════════════════════');
  console.log(`Endpoint:    ${ENDPOINT}`);
  console.log(`Project:     ${PROJECT_ID}`);
  console.log(`Model:       ${MODEL}`);
  console.log(`Voice:       ${VOICE} (Santali)`);
  console.log(`Delay:       ${DELAY_MS}ms`);
  console.log(`Dry Run:     ${DRY_RUN ? 'YES' : 'NO'}`);
  console.log(`Delete Old:  ${DELETE_EXISTING ? 'YES' : 'NO'}`);

  const keys = loadBodhanKeys();
  console.log(`Loaded ${keys.length} Bodhan keys: ${keys.map((k) => k.id).join(', ')}`);
  const rotator = new BodhanRotator(keys);

  // Phase 1: Clean up existing sentence audio files in storage
  if (DELETE_EXISTING && !DRY_RUN) {
    console.log('\n🧹 [Phase 1] Searching existing sentence audio files in bucket "audio"...');
    const existingFiles = await fetchAllSentenceFiles();
    console.log(`Found ${existingFiles.length} existing sentence files to delete.`);
    let deletedCount = 0;
    for (const f of existingFiles) {
      if (ONLY_IDS.length > 0 && !ONLY_IDS.includes(f.$id.toLowerCase())) continue;
      process.stdout.write(`  Deleting ${f.$id}... `);
      await deleteStorageFile(f.$id);
      deletedCount++;
      process.stdout.write('deleted\n');
    }
    console.log(`✅ Finished deleting ${deletedCount} files from storage.\n`);
  } else if (DRY_RUN) {
    console.log('\n🔍 [Phase 1 Skipped in DRY_RUN mode]');
  }

  // Phase 2: Fetch sentence documents
  console.log('📥 [Phase 2] Fetching sentence documents from Appwrite database...');
  let docs = await fetchAllSentences();
  console.log(`Total sentences fetched: ${docs.length}`);

  // Sort logically by order or doc ID (s1, s2, ..., s250)
  docs.sort((a, b) => {
    const numA = parseInt(a.$id.replace('s', ''), 10) || a.order || 0;
    const numB = parseInt(b.$id.replace('s', ''), 10) || b.order || 0;
    return numA - numB;
  });

  if (ONLY_IDS.length > 0) {
    const filterSet = new Set(ONLY_IDS.map((id) => (id.startsWith('sentence_') ? id.replace('sentence_', '') : id)));
    docs = docs.filter((d) => filterSet.has(d.$id.toLowerCase()));
    console.log(`Filtered to ${docs.length} sentence documents matching ONLY_IDS.`);
  }

  const outputDir = join(rootDir, 'output');
  mkdirSync(outputDir, { recursive: true });
  const progressPath = join(outputDir, 'bodhan_sentences_progress.json');

  const total = docs.length;
  console.log(`\n🚀 [Phase 3] Generating audio & updating Appwrite for ${total} sentences...\n`);

  let done = 0;
  let failed = 0;
  const failures = [];
  const succeeded = [];

  const saveProgress = () => {
    try {
      writeFileSync(
        progressPath,
        JSON.stringify(
          {
            timestamp: new Date().toISOString(),
            total,
            done,
            failed,
            failures,
            succeeded,
          },
          null,
          2
        )
      );
    } catch (e) {
      console.error(`Failed to save progress: ${e.message}`);
    }
  };

  for (let i = 0; i < total; i++) {
    const doc = docs[i];
    const fileId = `sentence_${doc.$id.toLowerCase()}`;
    const text = String(doc.sentenceOlChiki || '').trim();

    if (!text) {
      console.log(`⚠️  [${i + 1}/${total}] ${doc.$id}: Empty sentenceOlChiki, skipping.`);
      failed++;
      failures.push({ docId: doc.$id, fileId, error: 'Empty sentenceOlChiki' });
      continue;
    }

    const preview = text.length > 30 ? text.slice(0, 30) + '...' : text;
    process.stdout.write(`[${i + 1}/${total}] ${doc.$id} (${preview}) `);

    try {
      if (DRY_RUN) {
        console.log(`-> 🔍 dry-run (would generate for ${fileId})`);
        done++;
        continue;
      }

      // 1. Synthesize audio
      const { buffer, keyId } = await rotator.synthesize(text);
      process.stdout.write(`-> TTS OK (${buffer.length}b, ${keyId}) `);

      // 2. Upload to storage
      const uploadedUrl = await uploadAudioFile(fileId, buffer);
      process.stdout.write(`-> Uploaded `);

      // 3. Patch database document
      await patchSentenceDocument(doc.$id, uploadedUrl);
      process.stdout.write(`-> Patched DB ✅\n`);

      done++;
      succeeded.push({ docId: doc.$id, fileId, audioUrl: uploadedUrl, size: buffer.length });
    } catch (err) {
      console.log(`-> ❌ FAILED: ${err.message}`);
      failed++;
      failures.push({ docId: doc.$id, fileId, error: err.message });
    }

    if (i < total - 1 && DELAY_MS > 0) {
      await new Promise((r) => setTimeout(r, DELAY_MS));
    }

    if ((i + 1) % 5 === 0 || i === total - 1) {
      saveProgress();
    }
  }

  saveProgress();

  console.log('\n═══════════════════════════════════════════════════════════════════════');
  console.log(`🏁 Generation Finished: ${done} succeeded, ${failed} failed out of ${total}`);
  console.log('═══════════════════════════════════════════════════════════════════════\n');

  if (failures.length > 0) {
    console.log('Failures:');
    for (const f of failures) {
      console.log(`  - ${f.docId}: ${f.error}`);
    }
  }

  // Phase 4: Final Verification
  if (!DRY_RUN && failed === 0) {
    console.log('🔍 [Phase 4] Verifying database and storage completeness...');
    const allFiles = await fetchAllSentenceFiles();
    const allDocs = await fetchAllSentences();
    const docsWithoutAudio = allDocs.filter((d) => !d.audioUrl || !d.audioUrl.trim());

    console.log(`Appwrite Storage sentence files count: ${allFiles.length} / 250`);
    console.log(`Appwrite Database docs count:           ${allDocs.length} / 250`);
    console.log(`Database docs missing audioUrl:        ${docsWithoutAudio.length}`);

    if (allFiles.length === 250 && docsWithoutAudio.length === 0) {
      console.log('\n🎉 ALL 250 SENTENCES SUCCESSFULLY REGENERATED AND VERIFIED!');
    } else {
      console.warn(`\n⚠️ Notice: Some items may still be pending (files: ${allFiles.length}, missing: ${docsWithoutAudio.length})`);
    }
  }
}

main().catch((err) => {
  console.error('\nFatal Error in generation script:', err);
  process.exit(1);
});
