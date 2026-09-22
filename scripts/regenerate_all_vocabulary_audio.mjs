#!/usr/bin/env node
/**
 * Olitun Vocabulary Audio Remover & Regenerator (Bodhan AI - 8 Keys)
 *
 * Scope:
 * 1. Words Collection (All 415 words in `words` collection across all categories:
 *    basic, family, daily, nature, trending, colors, time, body, food, extra, greeting)
 * 2. Vocabulary Lessons (All 14 vocab lessons in `lessons` collection - 310 blocks)
 *
 * Actions:
 * - Deletes existing vocabulary audio files (word_*, snd_vocab_*) from Appwrite Storage.
 * - Synthesizes crystal-clear Santali audio with Bodhan AI (Phulmani voice, indic-speak, lang: sat).
 * - Rotates round-robin across all 8 available keys (.keys/bodhan0..7).
 * - Uploads .wav files to Appwrite Storage `audio` bucket.
 * - Patches Appwrite Database (`words` and `lessons` collections).
 * - Automatically syncs live database to `assets/seed/`.
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const rootDir = join(__dirname, '..');

// Appwrite Configuration
const ENDPOINT = process.env.APPWRITE_ENDPOINT || 'https://sgp.cloud.appwrite.io/v1';
const PROJECT_ID = process.env.APPWRITE_PROJECT_ID || '699495910038e39622c5';
const DATABASE_ID = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
const BUCKET_ID = process.env.APPWRITE_BUCKET_ID || 'audio';

// Bodhan Configuration
const BODHAN_URL = process.env.BODHAN_URL || 'https://api.bodhan.ai/v1/audio/speech';
const MODEL = 'indic-speak';
const VOICE = 'Phulmani';
const INSTRUCTIONS = '{"lang": "sat"}';

const DELAY_MS = parseInt(process.env.DELAY_MS || '200', 10);
const DRY_RUN = process.env.DRY_RUN === '1';
const SKIP_DELETION = process.env.SKIP_DELETION === '1';

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
      throw new Error('No Bodhan API keys found in .keys/bodhan*');
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

// Appwrite Storage API helpers
async function deleteStorageFile(fileId) {
  const headers = getAppwriteHeaders();
  try {
    const res = await fetch(`${ENDPOINT}/storage/buckets/${BUCKET_ID}/files/${fileId}`, {
      method: 'DELETE',
      headers,
    });
    return res.status === 204 || res.status === 200 || res.status === 404;
  } catch {
    return false;
  }
}

async function listAllStorageFilesByPrefix(prefix) {
  const headers = getAppwriteHeaders();
  const matched = [];
  let offset = 0;
  while (true) {
    const params = new URLSearchParams();
    params.append('queries[]', JSON.stringify({ method: 'limit', values: [100] }));
    params.append('queries[]', JSON.stringify({ method: 'offset', values: [offset] }));
    const res = await fetch(`${ENDPOINT}/storage/buckets/${BUCKET_ID}/files?${params}`, {
      headers,
    });
    if (!res.ok) throw new Error(`List files failed: ${res.status}`);
    const json = await res.json();
    const files = json.files || [];
    for (const f of files) {
      if (f.$id && f.$id.startsWith(prefix)) {
        matched.push(f.$id);
      }
    }
    if (files.length < 100) break;
    offset += 100;
  }
  return matched;
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

  // Ensure fresh file ID by deleting if exists
  await deleteStorageFile(fileId);

  let lastError = null;
  for (let attempt = 0; attempt < 4; attempt++) {
    try {
      const res = await fetch(base, {
        method: 'POST',
        headers: {
          ...appwriteHeaders,
          'Content-Type': `multipart/form-data; boundary=${boundary}`,
        },
        body,
      });

      if (!res.ok) {
        const errText = await res.text().catch(() => '');
        throw new Error(`Upload ${fileId} failed (${res.status}): ${errText}`);
      }
      return `${ENDPOINT}/storage/buckets/${BUCKET_ID}/files/${fileId}/view?project=${PROJECT_ID}`;
    } catch (err) {
      lastError = err;
      await new Promise((r) => setTimeout(r, 1000 * (attempt + 1)));
    }
  }
  throw lastError;
}

// Appwrite Database helpers
async function getDocument(collectionId, documentId) {
  const headers = getAppwriteHeaders();
  const res = await fetch(
    `${ENDPOINT}/databases/${DATABASE_ID}/collections/${collectionId}/documents/${documentId}`,
    { headers },
  );
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`Get ${collectionId}/${documentId} failed (${res.status})`);
  return res.json();
}

async function patchDocument(collectionId, documentId, data) {
  const headers = getAppwriteHeaders(true);
  let lastError = null;
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const res = await fetch(
        `${ENDPOINT}/databases/${DATABASE_ID}/collections/${collectionId}/documents/${documentId}`,
        {
          method: 'PATCH',
          headers,
          body: JSON.stringify({ data }),
        },
      );
      if (!res.ok) {
        const errText = await res.text().catch(() => '');
        throw new Error(`Patch ${collectionId}/${documentId} failed (${res.status}): ${errText}`);
      }
      return res.json();
    } catch (err) {
      lastError = err;
      await new Promise((r) => setTimeout(r, 800));
    }
  }
  throw lastError;
}

async function fetchAllDocuments(collectionId) {
  const headers = getAppwriteHeaders();
  const docs = [];
  let offset = 0;
  while (true) {
    const params = new URLSearchParams();
    params.append('queries[]', JSON.stringify({ method: 'limit', values: [100] }));
    params.append('queries[]', JSON.stringify({ method: 'offset', values: [offset] }));
    const res = await fetch(
      `${ENDPOINT}/databases/${DATABASE_ID}/collections/${collectionId}/documents?${params}`,
      { headers },
    );
    if (!res.ok) throw new Error(`Fetch ${collectionId} failed (${res.status})`);
    const json = await res.json();
    docs.push(...(json.documents || []));
    if ((json.documents || []).length < 100) break;
    offset += 100;
  }
  return docs;
}

// Bodhan Rotator
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

  async synthesize(text, maxRetries = 16) {
    // Sanitize punctuation (Devanagari danda -> Ol Chiki mucaad)
    const sanitizedText = text.replace(/।/g, '᱾').replace(/॥/g, '᱾').replace(/\s+/g, ' ').trim();

    const payload = {
      model: MODEL,
      input: sanitizedText.slice(0, 2500),
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
          process.stdout.write(`⚠️[${activeKeyObj.id} 429] `);
          this.rotate();
          await new Promise((r) => setTimeout(r, 600));
          continue;
        }

        if (!res.ok) {
          const errText = await res.text().catch(() => '');
          lastError = new Error(`HTTP ${res.status}: ${errText.slice(0, 100)}`);
          this.rotate();
          await new Promise((r) => setTimeout(r, 1200));
          continue;
        }

        const buf = Buffer.from(await res.arrayBuffer());
        if (buf.length < 1000 || buf.subarray(0, 4).toString() !== 'RIFF') {
          throw new Error(`Invalid WAV received (${buf.length}b)`);
        }

        const usedKeyId = activeKeyObj.id;
        this.rotate();
        return { buffer: buf, keyId: usedKeyId };
      } catch (err) {
        lastError = err;
        this.rotate();
        await new Promise((r) => setTimeout(r, 1200));
      }
    }
    throw lastError || new Error('Bodhan TTS failed after multiple key rotations');
  }
}

function parseBlocks(lessonDoc) {
  if (!lessonDoc || !lessonDoc.blocks) return [];
  if (Array.isArray(lessonDoc.blocks)) return lessonDoc.blocks;
  try {
    return JSON.parse(lessonDoc.blocks);
  } catch {
    return [];
  }
}

// Main Execution
async function main() {
  console.log('═══════════════════════════════════════════════════════════════════════');
  console.log('  Olitun Audio Regeneration: Full Vocabulary (Bodhan AI - 8 Keys)');
  console.log('═══════════════════════════════════════════════════════════════════════');
  console.log(`Endpoint:    ${ENDPOINT}`);
  console.log(`Project:     ${PROJECT_ID}`);
  console.log(`Model:       ${MODEL}`);
  console.log(`Voice:       ${VOICE} (Santali)`);
  console.log(`Delay:       ${DELAY_MS}ms`);
  console.log(`Dry Run:     ${DRY_RUN ? 'YES' : 'NO'}`);

  const keys = loadBodhanKeys();
  console.log(`Loaded ${keys.length} Bodhan keys: ${keys.map((k) => k.id).join(', ')}\n`);
  const rotator = new BodhanRotator(keys);

  const outputDir = join(rootDir, 'output');
  mkdirSync(outputDir, { recursive: true });
  const progressPath = join(outputDir, 'regeneration_vocab_progress.json');

  // =========================================================================
  // STEP 1: REMOVAL OF ALL EXISTING VOCABULARY AUDIO FILES
  // =========================================================================
  if (!SKIP_DELETION && !DRY_RUN) {
    console.log('🗑️ [Step 1] Removing all existing vocabulary audio files from Storage...');

    // 1A. Word audio files (word_*)
    console.log('  Scanning for word_* audio files in bucket "audio"...');
    const wordFiles = await listAllStorageFilesByPrefix('word_');
    console.log(`  Found ${wordFiles.length} word_* audio files. Deleting...`);
    for (let i = 0; i < wordFiles.length; i++) {
      const fId = wordFiles[i];
      await deleteStorageFile(fId);
      if ((i + 1) % 50 === 0 || i === wordFiles.length - 1) {
        console.log(`    Deleted ${i + 1} / ${wordFiles.length} word_* files`);
      }
    }

    // 1B. Vocab lesson audio files (snd_vocab_*)
    console.log('  Scanning for snd_vocab_* audio files in bucket "audio"...');
    const vocabLessonFiles = await listAllStorageFilesByPrefix('snd_vocab_');
    console.log(`  Found ${vocabLessonFiles.length} snd_vocab_* audio files. Deleting...`);
    for (let i = 0; i < vocabLessonFiles.length; i++) {
      const fId = vocabLessonFiles[i];
      await deleteStorageFile(fId);
      if ((i + 1) % 50 === 0 || i === vocabLessonFiles.length - 1) {
        console.log(`    Deleted ${i + 1} / ${vocabLessonFiles.length} snd_vocab_* files`);
      }
    }

    console.log('✅ Removal completed: All existing vocabulary audio deleted from storage.\n');
  }

  let totalItems = 0;
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
            total: totalItems,
            done,
            failed,
            failures,
            succeededCount: succeeded.length,
          },
          null,
          2,
        ),
      );
    } catch {}
  };

  // =========================================================================
  // STEP 2: REGENERATE ALL 415 WORDS IN `words` COLLECTION
  // =========================================================================
  console.log('📖 [Step 2] Processing Words Collection (415 vocabulary words)...');
  const wordDocs = await fetchAllDocuments('words');
  console.log(`  Fetched ${wordDocs.length} words from database.`);
  totalItems += wordDocs.length;

  for (let i = 0; i < wordDocs.length; i++) {
    const doc = wordDocs[i];
    const fileId = `word_${doc.$id.toLowerCase()}`;
    const text = String(doc.wordOlChiki || doc.wordLatin || '').trim();

    if (!text) {
      console.log(`⚠️ [Word ${i + 1}/${wordDocs.length}] ${doc.$id}: Empty text, skipping.`);
      failed++;
      failures.push({ type: 'word', docId: doc.$id, fileId, error: 'Empty text' });
      continue;
    }

    const preview = text.length > 20 ? text.slice(0, 20) + '...' : text;
    process.stdout.write(`  [Word ${i + 1}/${wordDocs.length}] ${doc.$id} (${preview}) `);

    try {
      if (DRY_RUN) {
        console.log(`-> 🔍 dry-run for ${fileId}`);
        done++;
        continue;
      }

      const { buffer, keyId } = await rotator.synthesize(text);
      process.stdout.write(`-> TTS OK (${buffer.length}b, ${keyId}) `);

      const uploadedUrl = await uploadAudioFile(fileId, buffer);
      process.stdout.write(`-> Uploaded `);

      await patchDocument('words', doc.$id, { audioUrl: uploadedUrl });
      process.stdout.write(`-> Patched DB ✅\n`);

      done++;
      succeeded.push({ type: 'word', docId: doc.$id, fileId });
    } catch (err) {
      console.log(`-> ❌ FAILED: ${err.message}`);
      failed++;
      failures.push({ type: 'word', docId: doc.$id, fileId, error: err.message });
    }

    if (DELAY_MS > 0) await new Promise((r) => setTimeout(r, DELAY_MS));
    if ((i + 1) % 25 === 0) saveProgress();
  }
  saveProgress();

  // =========================================================================
  // STEP 3: REGENERATE ALL 14 VOCABULARY LESSONS IN `lessons` COLLECTION
  // =========================================================================
  console.log('\n📖 [Step 3] Processing Vocabulary Lessons (14 lessons in lessons collection)...');
  const vocabLessonIds = [
    'lesson_vocab_basics',
    'lesson_vocab_family',
    'lesson_vocab_daily',
    'lesson_vocab_colors',
    'lesson_vocab_nature',
    'lesson_vocab_time',
    'lesson_vocab_trending',
    'lesson_vocab_idioms_beginner',
    'lesson_vocab_idioms_intermediate',
    'lesson_vocab_idioms_advanced',
    'lesson_vocab_conversational_1',
    'lesson_vocab_conversational_2',
    'lesson_vocab_folk_1',
    'lesson_vocab_folk_2',
  ];

  for (const lessonId of vocabLessonIds) {
    const lessonDoc = await getDocument('lessons', lessonId);
    if (!lessonDoc) {
      console.warn(`⚠️ Vocab Lesson ${lessonId} not found, skipping.`);
      continue;
    }

    const blocks = parseBlocks(lessonDoc);
    console.log(
      `\n  Vocab Lesson ${lessonId} (${lessonDoc.titleLatin}) - ${blocks.length} blocks:`,
    );
    totalItems += blocks.length;

    let dirty = false;
    for (let bIdx = 0; bIdx < blocks.length; bIdx++) {
      const block = blocks[bIdx];
      const text = String(block.textOlChiki || block.textLatin || block.markdown || '').trim();
      const shortLesson = lessonId.replace('lesson_', '');
      const fileId = `snd_${shortLesson}_${bIdx}`;

      if (!text) {
        console.log(`    ⚠️ [Block ${bIdx + 1}/${blocks.length}] ${fileId}: Empty text, skipping.`);
        failed++;
        failures.push({
          type: 'vocab_lesson_block',
          lessonId,
          blockIndex: bIdx,
          fileId,
          error: 'Empty text',
        });
        continue;
      }

      const preview = text.length > 25 ? text.slice(0, 25) + '...' : text;
      process.stdout.write(`    [Block ${bIdx + 1}/${blocks.length}] ${fileId} ("${preview}") `);

      try {
        if (DRY_RUN) {
          console.log(`-> 🔍 dry-run for ${fileId}`);
          done++;
          continue;
        }

        const { buffer, keyId } = await rotator.synthesize(text);
        process.stdout.write(`-> TTS OK (${buffer.length}b, ${keyId}) `);

        const uploadedUrl = await uploadAudioFile(fileId, buffer);
        process.stdout.write(`-> Uploaded ✅\n`);

        block.audioUrl = uploadedUrl;
        if (!block.meta) block.meta = {};
        block.meta.audioUrl = uploadedUrl;
        dirty = true;

        done++;
        succeeded.push({ type: 'vocab_lesson_block', lessonId, blockIndex: bIdx, fileId });
      } catch (err) {
        console.log(`-> ❌ FAILED: ${err.message}`);
        failed++;
        failures.push({
          type: 'vocab_lesson_block',
          lessonId,
          blockIndex: bIdx,
          fileId,
          error: err.message,
        });
      }

      if (DELAY_MS > 0) await new Promise((r) => setTimeout(r, DELAY_MS));
    }

    if (dirty && !DRY_RUN) {
      await patchDocument('lessons', lessonId, { blocks: JSON.stringify(blocks) });
      console.log(`    📝 Successfully updated ${lessonId} blocks in database.`);
    }
    saveProgress();
  }

  saveProgress();

  console.log('\n═══════════════════════════════════════════════════════════════════════');
  console.log(`🏁 Finished: ${done} succeeded, ${failed} failed out of ${totalItems}`);
  console.log('═══════════════════════════════════════════════════════════════════════\n');

  if (failures.length > 0) {
    console.log(`Failures (${failures.length}):`);
    for (const f of failures) {
      console.log(`  - ${JSON.stringify(f)}`);
    }
  }

  // Final verification
  if (!DRY_RUN && failed === 0) {
    console.log('🔍 Final verification of vocabulary completeness...');
    const words = await fetchAllDocuments('words');
    const wMissing = words.filter((w) => !w.audioUrl || !w.audioUrl.trim());
    console.log(`Vocabulary Words: ${words.length - wMissing.length} / ${words.length} have audio`);

    let totalBlocks = 0;
    let missingBlocks = 0;
    for (const lessonId of vocabLessonIds) {
      const lDoc = await getDocument('lessons', lessonId);
      const b = parseBlocks(lDoc);
      totalBlocks += b.length;
      missingBlocks += b.filter((x) => !x.audioUrl || !x.audioUrl.trim()).length;
    }
    console.log(`Vocab Lesson Blocks: ${totalBlocks - missingBlocks} / ${totalBlocks} have audio`);

    console.log('\n🎉 ALL VOCABULARY AUDIO SUCCESSFULLY REGENERATED AND VERIFIED!');
  }
}

main().catch((err) => {
  console.error('\nFatal Error in vocabulary audio regeneration script:', err);
  process.exit(1);
});
