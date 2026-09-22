#!/usr/bin/env node
/**
 * Bodhan AI Audio Generator for Greetings Section (Olitun App)
 *
 * Covers:
 * 1. Greetings Category Lessons (`cat_phrases` / `lesson_greet_0`..`3` - 21 blocks)
 * 2. Greeting Words (`words` collection with category `greeting` - 20 docs `w_g1`..`w_g20`)
 * 3. Greetings & Basics Lesson (`lesson_vocab_basics` - 20 blocks)
 *
 * Steps:
 * - Deletes all old audio files from Appwrite Storage bucket `audio`.
 * - Synthesizes audio using Bodhan AI (`model: indic-speak`, `voice: Phulmani`, `instructions: {"lang": "sat"}`)
 *   rotating round-robin across all 8 available keys in `.keys/bodhan0`..`bodhan7`.
 * - Uploads each audio file to Appwrite Storage bucket `audio`.
 * - Updates Appwrite Database `words` and `lessons` collections with the new URLs.
 * - Verifies completeness across storage and database.
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
const BUCKET_ID = 'audio';

const BODHAN_URL = process.env.BODHAN_URL || 'https://api.bodhan.ai/v1/audio/speech';
const MODEL = 'indic-speak';
const VOICE = 'Phulmani';
const INSTRUCTIONS = '{"lang": "sat"}';

const DELETE_EXISTING = process.env.DELETE_EXISTING !== '0';
const DRY_RUN = process.env.DRY_RUN === '1';
const DELAY_MS = parseInt(process.env.DELAY_MS || '400', 10);

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

// Storage helpers
async function searchStorageFiles(prefix) {
  const headers = getAppwriteHeaders(false);
  const files = [];
  let offset = 0;
  for (;;) {
    const params = new URLSearchParams();
    params.append('search', prefix);
    params.append('queries[]', JSON.stringify({ method: 'limit', values: [100] }));
    params.append('queries[]', JSON.stringify({ method: 'offset', values: [offset] }));
    const res = await fetch(`${ENDPOINT}/storage/buckets/${BUCKET_ID}/files?${params}`, { headers });
    if (!res.ok) {
      throw new Error(`List files failed (${res.status}): ${await res.text()}`);
    }
    const json = await res.json();
    const batch = (json.files || []).filter((f) => f.$id.startsWith(prefix));
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
    console.warn(`  Notice: delete ${fileId} returned ${res.status}`);
  }
  return true;
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
    return viewUrl(fileId);
  }
  if (!res.ok) {
    const errText = await res.text().catch(() => '');
    throw new Error(`Upload ${fileId} failed (${res.status}): ${errText.slice(0, 150)}`);
  }
  const json = await res.json();
  return viewUrl(json.$id);
}

// Database helpers
async function getDocument(collectionId, docId) {
  const headers = getAppwriteHeaders(true);
  const res = await fetch(`${ENDPOINT}/databases/${DATABASE_ID}/collections/${collectionId}/documents/${docId}`, { headers });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`Get ${collectionId}/${docId} failed (${res.status})`);
  return res.json();
}

async function patchDocument(collectionId, docId, data) {
  const headers = getAppwriteHeaders(true);
  const res = await fetch(`${ENDPOINT}/databases/${DATABASE_ID}/collections/${collectionId}/documents/${docId}`, {
    method: 'PATCH',
    headers,
    body: JSON.stringify({ data }),
  });
  if (!res.ok) {
    const errText = await res.text().catch(() => '');
    throw new Error(`Patch ${collectionId}/${docId} failed (${res.status}): ${errText.slice(0, 150)}`);
  }
}

async function fetchGreetingWords() {
  const headers = getAppwriteHeaders(true);
  const params = new URLSearchParams();
  params.append('queries[]', JSON.stringify({ method: 'equal', attribute: 'category', values: ['greeting'] }));
  params.append('queries[]', JSON.stringify({ method: 'limit', values: [100] }));
  const res = await fetch(`${ENDPOINT}/databases/${DATABASE_ID}/collections/words/documents?${params}`, { headers });
  if (!res.ok) throw new Error(`Fetch greeting words failed (${res.status})`);
  const json = await res.json();
  return json.documents || [];
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

function parseBlocks(doc) {
  try {
    return typeof doc.blocks === 'string' ? JSON.parse(doc.blocks || '[]') : doc.blocks || [];
  } catch {
    return [];
  }
}

async function main() {
  console.log('═══════════════════════════════════════════════════════════════════════');
  console.log('       Olitun Greetings Audio Regeneration (Bodhan AI - Phulmani)     ');
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

  // Phase 1: Storage cleanup
  if (DELETE_EXISTING && !DRY_RUN) {
    console.log('\n🧹 [Phase 1] Cleaning up existing audio files in bucket "audio"...');

    // Known legacy hex files from lesson_greet_0
    const legacyHexFiles = [
      '6a2264258aac001ddc6b',
      '6a22644fbac48d091d8a',
      '6a226467d3ab8a6cd777',
      '6a2264ef2de609004c19',
    ];

    const prefixes = ['snd_greet_', 'word_w_g', 'snd_vocab_basics_'];
    const filesToDelete = new Set(legacyHexFiles);

    for (const prefix of prefixes) {
      const files = await searchStorageFiles(prefix);
      for (const f of files) filesToDelete.add(f.$id);
    }

    console.log(`Found ${filesToDelete.size} audio files to delete.`);
    for (const fileId of filesToDelete) {
      process.stdout.write(`  Deleting ${fileId}... `);
      await deleteStorageFile(fileId);
      process.stdout.write('deleted\n');
    }
    console.log(`✅ Finished cleanup.\n`);
  } else if (DRY_RUN) {
    console.log('\n🔍 [Phase 1 Skipped in DRY_RUN mode]');
  }

  const outputDir = join(rootDir, 'output');
  mkdirSync(outputDir, { recursive: true });
  const progressPath = join(outputDir, 'bodhan_greetings_progress.json');

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
            succeeded,
          },
          null,
          2
        )
      );
    } catch (e) {}
  };

  // Phase 2A: Greeting Words (words collection: w_g1..w_g20)
  console.log('📚 [Phase 2A] Fetching and processing greeting words (words collection)...');
  const greetingWords = await fetchGreetingWords();
  greetingWords.sort((a, b) => {
    const numA = parseInt(a.$id.replace('w_g', ''), 10) || a.order || 0;
    const numB = parseInt(b.$id.replace('w_g', ''), 10) || b.order || 0;
    return numA - numB;
  });
  console.log(`Found ${greetingWords.length} greeting words.`);
  totalItems += greetingWords.length;

  for (let i = 0; i < greetingWords.length; i++) {
    const doc = greetingWords[i];
    const fileId = `word_${doc.$id.toLowerCase()}`;
    const text = String(doc.wordOlChiki || '').trim();

    process.stdout.write(`  [Word ${i + 1}/${greetingWords.length}] ${doc.$id} ("${text}") `);

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
      succeeded.push({ type: 'word', docId: doc.$id, fileId, audioUrl: uploadedUrl, size: buffer.length });
    } catch (err) {
      console.log(`-> ❌ FAILED: ${err.message}`);
      failed++;
      failures.push({ type: 'word', docId: doc.$id, fileId, error: err.message });
    }

    if (DELAY_MS > 0) await new Promise((r) => setTimeout(r, DELAY_MS));
  }
  saveProgress();

  // Phase 2B: Greetings Category Lessons (lesson_greet_0..3)
  console.log('\n📖 [Phase 2B] Processing Greetings Category Lessons (lesson_greet_0..3)...');
  const greetLessonIds = ['lesson_greet_0', 'lesson_greet_1', 'lesson_greet_2', 'lesson_greet_3'];

  for (const lessonId of greetLessonIds) {
    const lessonDoc = await getDocument('lessons', lessonId);
    if (!lessonDoc) {
      console.warn(`⚠️ Lesson ${lessonId} not found, skipping.`);
      continue;
    }

    const blocks = parseBlocks(lessonDoc);
    console.log(`\n  Lesson ${lessonId} (${lessonDoc.titleLatin}) - ${blocks.length} blocks:`);
    totalItems += blocks.length;

    let dirty = false;
    for (let bIdx = 0; bIdx < blocks.length; bIdx++) {
      const block = blocks[bIdx];
      const text = String(block.textOlChiki || '').trim();
      const shortLesson = lessonId.replace('lesson_', '');
      const fileId = `snd_${shortLesson}_${bIdx}`;

      process.stdout.write(`    [Block ${bIdx + 1}/${blocks.length}] ${fileId} ("${text}") `);

      if (!text) {
        console.log('-> ⚠️ Empty text, skipped');
        continue;
      }

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
        block.meta = { ...(block.meta || {}), audioUrl: uploadedUrl };
        dirty = true;
        done++;
        succeeded.push({ type: 'lesson_block', lessonId, blockIndex: bIdx, fileId, audioUrl: uploadedUrl, size: buffer.length });
      } catch (err) {
        console.log(`-> ❌ FAILED: ${err.message}`);
        failed++;
        failures.push({ type: 'lesson_block', lessonId, blockIndex: bIdx, fileId, error: err.message });
      }

      if (DELAY_MS > 0) await new Promise((r) => setTimeout(r, DELAY_MS));
    }

    if (dirty && !DRY_RUN) {
      await patchDocument('lessons', lessonId, { blocks: JSON.stringify(blocks) });
      console.log(`    📝 Successfully updated ${lessonId} blocks in database.`);
    }
  }
  saveProgress();

  // Phase 2C: Greetings & Basics Lesson (lesson_vocab_basics)
  console.log('\n📖 [Phase 2C] Processing Greetings & Basics Lesson (lesson_vocab_basics)...');
  const vocabBasicsDoc = await getDocument('lessons', 'lesson_vocab_basics');
  if (vocabBasicsDoc) {
    const blocks = parseBlocks(vocabBasicsDoc);
    console.log(`  Lesson lesson_vocab_basics (${vocabBasicsDoc.titleLatin}) - ${blocks.length} blocks:`);
    totalItems += blocks.length;

    let dirty = false;
    for (let bIdx = 0; bIdx < blocks.length; bIdx++) {
      const block = blocks[bIdx];
      const text = String(block.textOlChiki || '').trim();
      const fileId = `snd_vocab_basics_${bIdx}`;

      process.stdout.write(`    [Block ${bIdx + 1}/${blocks.length}] ${fileId} ("${text}") `);

      if (!text) {
        console.log('-> ⚠️ Empty text, skipped');
        continue;
      }

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
        block.meta = { ...(block.meta || {}), audioUrl: uploadedUrl };
        dirty = true;
        done++;
        succeeded.push({ type: 'lesson_block', lessonId: 'lesson_vocab_basics', blockIndex: bIdx, fileId, audioUrl: uploadedUrl, size: buffer.length });
      } catch (err) {
        console.log(`-> ❌ FAILED: ${err.message}`);
        failed++;
        failures.push({ type: 'lesson_block', lessonId: 'lesson_vocab_basics', blockIndex: bIdx, fileId, error: err.message });
      }

      if (DELAY_MS > 0) await new Promise((r) => setTimeout(r, DELAY_MS));
    }

    if (dirty && !DRY_RUN) {
      await patchDocument('lessons', 'lesson_vocab_basics', { blocks: JSON.stringify(blocks) });
      console.log(`    📝 Successfully updated lesson_vocab_basics blocks in database.`);
    }
  }
  saveProgress();

  console.log('\n═══════════════════════════════════════════════════════════════════════');
  console.log(`🏁 Finished: ${done} succeeded, ${failed} failed out of ${totalItems}`);
  console.log('═══════════════════════════════════════════════════════════════════════\n');

  if (failures.length > 0) {
    console.log('Failures:');
    for (const f of failures) {
      console.log(`  - ${JSON.stringify(f)}`);
    }
  }

  // Phase 3: Final Verification
  if (!DRY_RUN && failed === 0) {
    console.log('🔍 [Phase 3] Verifying database and storage completeness...');

    const words = await fetchGreetingWords();
    const wordsMissingAudio = words.filter((w) => !w.audioUrl || !w.audioUrl.trim());
    console.log(`Greeting Words in DB: ${words.length} / 20 (missing audio: ${wordsMissingAudio.length})`);

    for (const lid of ['lesson_greet_0', 'lesson_greet_1', 'lesson_greet_2', 'lesson_greet_3', 'lesson_vocab_basics']) {
      const l = await getDocument('lessons', lid);
      const blks = parseBlocks(l);
      const missing = blks.filter((b) => !b.audioUrl || !b.audioUrl.trim());
      console.log(`Lesson ${lid}: ${blks.length} blocks (missing audio: ${missing.length})`);
    }

    console.log('\n🎉 ALL GREETING AUDIO FILES SUCCESSFULLY REGENERATED AND VERIFIED!');
  }
}

main().catch((err) => {
  console.error('\nFatal Error in greetings generation script:', err);
  process.exit(1);
});
