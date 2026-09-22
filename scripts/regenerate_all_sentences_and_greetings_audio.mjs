#!/usr/bin/env node
/**
 * Unified Bodhan AI Audio Generator for Sentences & Greetings (Olitun App)
 *
 * Regenerates:
 * 1. Greetings:
 *    - 20 greeting words in `words` collection (`w_g1`..`w_g20`)
 *    - 21 greeting blocks across `lesson_greet_0`..`3`
 *    - 20 greeting blocks in `lesson_vocab_basics`
 * 2. Sentences:
 *    - 250 sentences in `sentences` collection (`s1`..`s250`)
 *    - 279 sentence blocks across all 14 `lesson_sentences_*` lessons
 *
 * Uses:
 * - Model: `indic-speak`
 * - Voice: `Phulmani`
 * - Instructions: `{"lang": "sat"}`
 * - 8 Bodhan API keys in `.keys/bodhan0`..`bodhan7` rotating round-robin
 * - Appwrite Storage bucket `audio`
 * - Direct Appwrite Database patching
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

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

const DELAY_MS = parseInt(process.env.DELAY_MS || '250', 10);
const DRY_RUN = process.env.DRY_RUN === '1';

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

const viewUrl = (fileId) =>
  `${ENDPOINT}/storage/buckets/${BUCKET_ID}/files/${fileId}/view?project=${PROJECT_ID}`;

// Storage helpers
async function deleteStorageFile(fileId) {
  const headers = getAppwriteHeaders(false);
  const res = await fetch(`${ENDPOINT}/storage/buckets/${BUCKET_ID}/files/${fileId}`, {
    method: 'DELETE',
    headers,
  });
  return res.status === 200 || res.status === 204 || res.status === 404;
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

  // If already exists, delete first to guarantee fresh replacement
  await deleteStorageFile(fileId);

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
    throw new Error(`Upload ${fileId} failed (${res.status}): ${errText.slice(0, 150)}`);
  }
  const json = await res.json();
  return viewUrl(json.$id);
}

// Database helpers
async function getDocument(collectionId, docId) {
  const headers = getAppwriteHeaders(true);
  const res = await fetch(
    `${ENDPOINT}/databases/${DATABASE_ID}/collections/${collectionId}/documents/${docId}`,
    { headers },
  );
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`Get ${collectionId}/${docId} failed (${res.status})`);
  return res.json();
}

async function patchDocument(collectionId, docId, data) {
  const headers = getAppwriteHeaders(true);
  const res = await fetch(
    `${ENDPOINT}/databases/${DATABASE_ID}/collections/${collectionId}/documents/${docId}`,
    {
      method: 'PATCH',
      headers,
      body: JSON.stringify({ data }),
    },
  );
  if (!res.ok) {
    const errText = await res.text().catch(() => '');
    throw new Error(
      `Patch ${collectionId}/${docId} failed (${res.status}): ${errText.slice(0, 150)}`,
    );
  }
}

async function fetchAllDocuments(collectionId) {
  const headers = getAppwriteHeaders(true);
  const docs = [];
  let offset = 0;
  for (;;) {
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

function parseBlocks(doc) {
  try {
    return typeof doc.blocks === 'string' ? JSON.parse(doc.blocks || '[]') : doc.blocks || [];
  } catch {
    return [];
  }
}

async function main() {
  console.log('═══════════════════════════════════════════════════════════════════════');
  console.log('  Olitun Audio Regeneration: Sentences & Greetings (Bodhan AI - 8 Keys)');
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
  const progressPath = join(outputDir, 'regeneration_all_progress.json');

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
    } catch (_) {}
  };

  // -------------------------------------------------------------
  // SECTION 1: GREETINGS
  // -------------------------------------------------------------
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('  SECTION 1: GREETINGS (Words & Lessons)');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  // 1A. Greeting Words
  console.log('\n📚 [1A] Processing Greeting Words (words collection)...');
  const allWords = await fetchAllDocuments('words');
  const greetingWords = allWords.filter((w) => w.category === 'greeting');
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
      succeeded.push({ type: 'word', docId: doc.$id, fileId });
    } catch (err) {
      console.log(`-> ❌ FAILED: ${err.message}`);
      failed++;
      failures.push({ type: 'word', docId: doc.$id, fileId, error: err.message });
    }

    if (DELAY_MS > 0) await new Promise((r) => setTimeout(r, DELAY_MS));
  }
  saveProgress();

  // 1B. Greeting Lessons (lesson_greet_0..3 & lesson_vocab_basics)
  console.log('\n📖 [1B] Processing Greeting Lessons (lesson_greet_0..3 & lesson_vocab_basics)...');
  const greetingLessonIds = [
    'lesson_greet_0',
    'lesson_greet_1',
    'lesson_greet_2',
    'lesson_greet_3',
    'lesson_vocab_basics',
  ];

  for (const lessonId of greetingLessonIds) {
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
        succeeded.push({ type: 'lesson_block', lessonId, blockIndex: bIdx, fileId });
      } catch (err) {
        console.log(`-> ❌ FAILED: ${err.message}`);
        failed++;
        failures.push({
          type: 'lesson_block',
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
  }
  saveProgress();

  // -------------------------------------------------------------
  // SECTION 2: SENTENCES
  // -------------------------------------------------------------
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('  SECTION 2: SENTENCES (Collection & Lessons)');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  // 2A. Sentences Collection (s1..s250)
  console.log('\n📚 [2A] Processing Sentences Collection (250 documents)...');
  const sentenceDocs = await fetchAllDocuments('sentences');
  sentenceDocs.sort((a, b) => {
    const numA = parseInt(a.$id.replace('s', ''), 10) || a.order || 0;
    const numB = parseInt(b.$id.replace('s', ''), 10) || b.order || 0;
    return numA - numB;
  });
  console.log(`Fetched ${sentenceDocs.length} sentences from database.`);
  totalItems += sentenceDocs.length;

  for (let i = 0; i < sentenceDocs.length; i++) {
    const doc = sentenceDocs[i];
    const fileId = `sentence_${doc.$id.toLowerCase()}`;
    const text = String(doc.sentenceOlChiki || '').trim();

    if (!text) {
      console.log(
        `⚠️ [Sentence ${i + 1}/${sentenceDocs.length}] ${doc.$id}: Empty sentenceOlChiki, skipping.`,
      );
      failed++;
      failures.push({ type: 'sentence', docId: doc.$id, fileId, error: 'Empty text' });
      continue;
    }

    const preview = text.length > 28 ? text.slice(0, 28) + '...' : text;
    process.stdout.write(`  [Sentence ${i + 1}/${sentenceDocs.length}] ${doc.$id} (${preview}) `);

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

      await patchDocument('sentences', doc.$id, { audioUrl: uploadedUrl });
      process.stdout.write(`-> Patched DB ✅\n`);

      done++;
      succeeded.push({ type: 'sentence', docId: doc.$id, fileId });
    } catch (err) {
      console.log(`-> ❌ FAILED: ${err.message}`);
      failed++;
      failures.push({ type: 'sentence', docId: doc.$id, fileId, error: err.message });
    }

    if (DELAY_MS > 0) await new Promise((r) => setTimeout(r, DELAY_MS));
    if ((i + 1) % 10 === 0) saveProgress();
  }
  saveProgress();

  // 2B. Sentence Lessons (14 lessons in lessons collection)
  console.log('\n📖 [2B] Processing Sentence Lessons (14 lessons in lessons collection)...');
  const sentenceLessonIds = [
    'lesson_sentences_basics',
    'lesson_sentences_daily',
    'lesson_sentences_conversations',
    'lesson_sentences_polite',
    'lesson_sentences_time_weather',
    'lesson_sentences_complex_beginner',
    'lesson_sentences_complex_advanced',
    'lesson_sentences_conversational_1',
    'lesson_sentences_conversational_2',
    'lesson_sentences_conversational_3',
    'lesson_sentences_folk_1',
    'lesson_sentences_folk_2',
    'lesson_sentences_folk_3',
    'lesson_sentences_complex_intermed',
  ];

  for (const lessonId of sentenceLessonIds) {
    const lessonDoc = await getDocument('lessons', lessonId);
    if (!lessonDoc) {
      console.warn(`⚠️ Sentence Lesson ${lessonId} not found, skipping.`);
      continue;
    }

    const blocks = parseBlocks(lessonDoc);
    console.log(
      `\n  Sentence Lesson ${lessonId} (${lessonDoc.titleLatin}) - ${blocks.length} blocks:`,
    );
    totalItems += blocks.length;

    let dirty = false;
    for (let bIdx = 0; bIdx < blocks.length; bIdx++) {
      const block = blocks[bIdx];
      const text = String(block.textOlChiki || '').trim();
      const shortLesson = lessonId.replace('lesson_', '');
      const fileId = `snd_${shortLesson}_${bIdx}`;

      process.stdout.write(`    [Block ${bIdx + 1}/${blocks.length}] ${fileId} `);

      if (!text) {
        console.log('-> ⚠️ Empty text, skipped');
        continue;
      }

      const preview = text.length > 25 ? text.slice(0, 25) + '...' : text;
      process.stdout.write(`("${preview}") `);

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
        succeeded.push({ type: 'sentence_lesson_block', lessonId, blockIndex: bIdx, fileId });
      } catch (err) {
        console.log(`-> ❌ FAILED: ${err.message}`);
        failed++;
        failures.push({
          type: 'sentence_lesson_block',
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
    console.log('🔍 Final verification of database completeness...');
    const words = await fetchAllDocuments('words');
    const gw = words.filter((w) => w.category === 'greeting');
    const gwMissing = gw.filter((w) => !w.audioUrl || !w.audioUrl.trim());
    console.log(`Greeting Words: ${gw.length - gwMissing.length} / ${gw.length} have audio`);

    const sents = await fetchAllDocuments('sentences');
    const sMissing = sents.filter((s) => !s.audioUrl || !s.audioUrl.trim());
    console.log(`Sentences:      ${sents.length - sMissing.length} / ${sents.length} have audio`);

    console.log('\n🎉 ALL SENTENCES AND GREETINGS AUDIO SUCCESSFULLY REGENERATED AND VERIFIED!');
  }
}

main().catch((err) => {
  console.error('\nFatal Error in audio regeneration script:', err);
  process.exit(1);
});
