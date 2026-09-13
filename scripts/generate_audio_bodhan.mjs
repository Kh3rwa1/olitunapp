#!/usr/bin/env node
/**
 * Bodhan AI Audio Generation & Appwrite Storage Replacement Script (v2 — DB-sourced)
 *
 * Source of truth: Appwrite database `olitun_db` (LIVE Santali Ol Chiki text).
 *   - words collection     -> wordOlChiki      -> storage file `word_<docId>`
 *   - sentences collection -> sentenceOlChiki  -> storage file `sentence_<docId>`
 *   - lessons collection   -> blocks[].textOlChiki -> storage file parsed from
 *                             block.audioUrl / block.meta.audioUrl
 *                             (`.../files/<fileId>/view?...`)
 *
 * NEVER uses:
 *   - assets/seed/*.json (seed defaults — ignored)
 *   - Roman fields (wordLatin / sentenceLatin / textLatin — never sent to TTS)
 *
 * NEVER touches alphabets & numbers:
 *   - letters / numbers collections skipped
 *   - lessons with categoryId cat_alphabets_* / cat_numbers_* skipped
 *   - lesson ids lesson_alphabet_* / lesson_numbers_* skipped
 *
 * TTS: Bodhan `indic-speak`, voice `Phulmani`, instructions '{"lang": "sat"}'.
 * Replacement: DELETE + POST with the SAME storage fileId, so existing
 * audioUrl values stay valid (no DB document updates required).
 *
 * Usage:
 *   BODHAN_API_KEY="sk-..." node scripts/generate_audio_bodhan.mjs
 *
 * ENV:
 *   TARGET="all" | "words" | "sentences" | "lessons"
 *   LIMIT="0"   (0 = no limit)
 *   OFFSET="0"  (skip first N in queue)
 *   ONLY_IDS="word_w_g1,sentence_s1" (filter by storage fileId, for testing)
 *   DRY_RUN="1" (generate only, no delete/upload)
 *   DELAY_MS="4000" (pause between TTS calls; default 4000 to respect rate limits)
 */

import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';

let BODHAN_API_KEY = process.env.BODHAN_API_KEY;
if (!BODHAN_API_KEY && process.env.BODHAN_API_KEY_FILE) {
  BODHAN_API_KEY = readFileSync(process.env.BODHAN_API_KEY_FILE, 'utf8').trim();
}
const SKIP_IDS_FILE = process.env.SKIP_IDS_FILE || '';
const SHARD_COUNT = parseInt(process.env.SHARD_COUNT || '1', 10);
const SHARD_INDEX = parseInt(process.env.SHARD_INDEX || '0', 10);
const BODHAN_URL = process.env.BODHAN_URL || 'https://api.bodhan.ai/v1/audio/speech';
const MODEL = process.env.MODEL || 'indic-speak';
const VOICE = process.env.VOICE || 'Phulmani';
const TARGET = process.env.TARGET || 'all';
const LIMIT = parseInt(process.env.LIMIT || '0', 10);
const OFFSET = parseInt(process.env.OFFSET || '0', 10);
const ONLY_IDS = (process.env.ONLY_IDS || '').split(',').map((s) => s.trim().toLowerCase()).filter(Boolean);
const DRY_RUN = process.env.DRY_RUN === '1';
const DELAY_MS = parseInt(process.env.DELAY_MS || '4000', 10);

const ENDPOINT = 'https://sgp.cloud.appwrite.io/v1';
const PROJECT_ID = '699495910038e39622c5';
const DATABASE_ID = 'olitun_db';
const BUCKET_ID = 'audio';

if (!BODHAN_API_KEY) {
  console.error('❌ Error: BODHAN_API_KEY environment variable is required.');
  process.exit(1);
}

function getAppwriteHeaders(json = false) {
  const prefs = JSON.parse(readFileSync(process.env.HOME + '/.appwrite/prefs.json', 'utf8'));
  const p = prefs[PROJECT_ID];
  if (!p || !p.cookie) throw new Error('No active Appwrite CLI session cookie found');
  const h = {
    'X-Appwrite-Project': PROJECT_ID,
    'X-Appwrite-Mode': 'admin',
    Cookie: p.cookie.split(';')[0],
  };
  if (json) h['Content-Type'] = 'application/json';
  return h;
}

function safeFileId(fileId) {
  return String(fileId || '').toLowerCase().replace(/[^a-z0-9_.]/g, '_').slice(0, 36);
}

/** Extract storage fileId from an Appwrite view URL: .../files/<id>/view?... */
function fileIdFromAudioUrl(url) {
  if (!url || typeof url !== 'string') return null;
  const m = url.match(/\/files\/([^/]+)\/view/);
  return m ? m[1] : null;
}

function isAlphabetOrNumberLesson(doc) {
  const cat = String(doc.categoryId || '');
  const id = String(doc.$id || '');
  return (
    cat.startsWith('cat_alphabets') ||
    cat.startsWith('cat_numbers') ||
    id.startsWith('lesson_alphabet') ||
    id.startsWith('lesson_numbers')
  );
}

async function fetchAllDocuments(collectionId) {
  const headers = getAppwriteHeaders(true);
  const docs = [];
  let offset = 0;
  const pageSize = 100;
  for (;;) {
    const params = new URLSearchParams();
    params.append('queries[]', JSON.stringify({ method: 'limit', values: [pageSize] }));
    params.append('queries[]', JSON.stringify({ method: 'offset', values: [offset] }));
    const url = `${ENDPOINT}/databases/${DATABASE_ID}/collections/${collectionId}/documents?${params.toString()}`;
    const res = await fetch(url, { headers });
    if (!res.ok) throw new Error(`List ${collectionId} failed (${res.status}): ${(await res.text()).slice(0, 300)}`);
    const json = await res.json();
    docs.push(...(json.documents || []));
    if ((json.documents || []).length < pageSize) break;
    offset += pageSize;
  }
  return docs;
}

/** Build queue EXCLUSIVELY from live DB Ol Chiki text. */
async function buildQueueFromDB() {
  const queue = [];

  if (TARGET === 'words' || TARGET === 'all') {
    console.log('📥 Fetching words from DB...');
    const docs = await fetchAllDocuments('words');
    console.log(`   ${docs.length} word docs`);
    for (const d of docs) {
      const text = String(d.wordOlChiki || '').trim();
      if (!text) continue; // no Ol Chiki -> skip (never fall back to Roman)
      queue.push({ kind: 'word', docId: d.$id, fileId: safeFileId(`word_${d.$id}`), text });
    }
  }

  if (TARGET === 'sentences' || TARGET === 'all') {
    console.log('📥 Fetching sentences from DB...');
    const docs = await fetchAllDocuments('sentences');
    console.log(`   ${docs.length} sentence docs`);
    for (const d of docs) {
      const text = String(d.sentenceOlChiki || '').trim();
      if (!text) continue;
      queue.push({ kind: 'sentence', docId: d.$id, fileId: safeFileId(`sentence_${d.$id}`), text });
    }
  }

  if (TARGET === 'lessons' || TARGET === 'all') {
    console.log('📥 Fetching lessons from DB...');
    const docs = await fetchAllDocuments('lessons');
    console.log(`   ${docs.length} lesson docs`);
    let skippedAlphaNum = 0;
    let blocksSeen = 0;
    let blocksNoAudio = 0;
    for (const d of docs) {
      if (isAlphabetOrNumberLesson(d)) {
        skippedAlphaNum++;
        continue; // alphabets & numbers untouched
      }
      let blocks = [];
      try {
        blocks = typeof d.blocks === 'string' ? JSON.parse(d.blocks || '[]') : d.blocks || [];
      } catch { continue; }
      for (let i = 0; i < blocks.length; i++) {
        const b = blocks[i];
        if (!b || b.type === 'quiz') continue;
        const text = String(b.textOlChiki || '').trim();
        if (!text) continue; // never use textLatin
        blocksSeen++;
        const audioUrl = b.audioUrl || b.meta?.audioUrl || null;
        const fileId = fileIdFromAudioUrl(audioUrl);
        if (!fileId) {
          blocksNoAudio++;
          continue; // nothing to replace
        }
        queue.push({ kind: 'lesson_block', docId: `${d.$id}#${i}`, fileId, text });
      }
    }
    console.log(`   skipped ${skippedAlphaNum} alphabet/number lessons; ${blocksSeen} blocks with Ol Chiki, ${blocksNoAudio} without existing audio (skipped)`);
  }

  return queue;
}

async function generateBodhanSpeech(text, retries = 5) {
  const payload = {
    model: MODEL,
    input: text.slice(0, 2500),
    voice: VOICE,
    instructions: '{"lang": "sat"}',
  };

  let lastError = null;
  for (let attempt = 0; attempt <= retries; attempt++) {
    const res = await fetch(BODHAN_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${BODHAN_API_KEY}`,
      },
      body: JSON.stringify(payload),
    });

    if (res.status === 429 && attempt < retries) {
      const wait = Math.min(60000, (attempt + 1) * 10000);
      process.stdout.write(`⏳ (429, waiting ${wait}ms)... `);
      await new Promise((r) => setTimeout(r, wait));
      continue;
    }

    if (!res.ok) {
      const errText = await res.text().catch(() => '');
      lastError = new Error(`Bodhan API failed (${res.status}): ${errText.slice(0, 200)}`);
      if (res.status >= 500 && attempt < retries) {
        await new Promise((r) => setTimeout(r, (attempt + 1) * 8000));
        continue;
      }
      throw lastError;
    }

    const buf = Buffer.from(await res.arrayBuffer());
    if (buf.length < 1000 || buf.subarray(0, 4).toString() !== 'RIFF') {
      throw new Error(`Bodhan returned invalid WAV (${buf.length} bytes)`);
    }
    return buf;
  }
  throw lastError || new Error('Bodhan API failed after retries');
}

async function replaceFileInBucket(appwriteHeaders, fileId, audioBuffer) {
  const base = `${ENDPOINT}/storage/buckets/${BUCKET_ID}/files`;

  const del = await fetch(`${base}/${fileId}`, { method: 'DELETE', headers: appwriteHeaders });
  if (!del.ok && del.status !== 404) {
    throw new Error(`Appwrite delete failed (${del.status}): ${(await del.text().catch(() => '')).slice(0, 200)}`);
  }

  const boundary = '----BodhanBoundary' + Math.random().toString(36).substring(2);
  const headerParts = [
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
  const footer = `\r\n--${boundary}--\r\n`;
  const body = Buffer.concat([Buffer.from(headerParts, 'utf8'), audioBuffer, Buffer.from(footer, 'utf8')]);

  const res = await fetch(base, {
    method: 'POST',
    headers: { ...appwriteHeaders, 'Content-Type': `multipart/form-data; boundary=${boundary}` },
    body,
  });
  if (!res.ok) throw new Error(`Appwrite upload failed (${res.status}): ${(await res.text().catch(() => '')).slice(0, 200)}`);
  const json = await res.json();
  return `${ENDPOINT}/storage/buckets/${BUCKET_ID}/files/${json.$id}/view?project=${PROJECT_ID}`;
}

async function main() {
  console.log('🚀 Bodhan AI Audio Replacement (DB-sourced v2)');
  console.log(`   Model: ${MODEL} | Voice: ${VOICE} | lang: sat | delay: ${DELAY_MS}ms`);
  console.log(`   Target: ${TARGET} | Limit: ${LIMIT || 'none'} | Offset: ${OFFSET} | DryRun: ${DRY_RUN ? 'YES' : 'NO'}`);
  console.log('   Source: Appwrite DB Ol Chiki ONLY (words.wordOlChiki, sentences.sentenceOlChiki, lessons blocks[].textOlChiki)');
  console.log('   Excluded: seed files, Roman fields, letters/numbers, alphabets/numbers lessons');

  let queue = await buildQueueFromDB();
  console.log(`\n📦 Queue built from DB: ${queue.length} files`);

  if (SKIP_IDS_FILE) {
    try {
      const skip = new Set(JSON.parse(readFileSync(SKIP_IDS_FILE, 'utf8')).map((s) => String(s).toLowerCase()));
      const before = queue.length;
      queue = queue.filter((q) => !skip.has(q.fileId.toLowerCase()));
      console.log(`⏭️  SKIP_IDS_FILE: skipped ${before - queue.length} already-done, ${queue.length} remain`);
    } catch (e) {
      console.error(`⚠️  Could not read SKIP_IDS_FILE: ${e.message}`);
    }
  }

  if (SHARD_COUNT > 1) {
    queue = queue.filter((_, i) => i % SHARD_COUNT === SHARD_INDEX);
    console.log(`🧩 Shard ${SHARD_INDEX}/${SHARD_COUNT}: ${queue.length} files`);
  }

  if (ONLY_IDS.length > 0) {
    const set = new Set(ONLY_IDS);
    queue = queue.filter((q) => set.has(q.fileId.toLowerCase()));
    console.log(`🎯 ONLY_IDS filter: ${queue.length} files`);
  }
  if (OFFSET > 0) queue = queue.slice(OFFSET);
  if (LIMIT > 0) queue = queue.slice(0, LIMIT);
  console.log(`▶️  Processing ${queue.length} files\n`);

  if (process.env.LIST_ONLY === '1') {
    console.log('📋 LIST_ONLY: queue preview (first 5):');
    for (const q of queue.slice(0, 5)) console.log(`   - ${q.fileId} [${q.kind}:${q.docId}]`);
    return;
  }

  if (queue.length === 0) {
    console.log('Nothing to do.');
    return;
  }

  const appwriteHeaders = DRY_RUN ? null : getAppwriteHeaders();

  let done = 0;
  let failed = 0;
  const failures = [];
  const progressName = SHARD_COUNT > 1 ? `bodhan_progress_s${SHARD_INDEX}.json` : 'bodhan_progress.json';
  const progressPath = new URL(`../output/${progressName}`, import.meta.url);
  try { mkdirSync(new URL('../output/', import.meta.url), { recursive: true }); } catch {}

  for (let i = 0; i < queue.length; i++) {
    const item = queue[i];
    try {
      process.stdout.write(`  [${i + 1}/${queue.length}] ${item.fileId} "${item.text.slice(0, 28)}..." -> `);
      const audioBuf = await generateBodhanSpeech(item.text);
      if (DRY_RUN) {
        console.log(`🔍 dry-run OK (${audioBuf.length}b) [${item.kind}:${item.docId}]`);
      } else {
        const url = await replaceFileInBucket(appwriteHeaders, item.fileId, audioBuf);
        console.log(`✅ (${audioBuf.length}b)`);
        void url;
      }
      done++;
    } catch (e) {
      failed++;
      failures.push({ fileId: item.fileId, docId: item.docId, error: e.message });
      console.log(`❌ ${e.message}`);
    }

    if (i < queue.length - 1) await new Promise((r) => setTimeout(r, DELAY_MS));

    if ((i + 1) % 10 === 0 || i === queue.length - 1) {
      try {
        writeFileSync(progressPath, JSON.stringify({ at: new Date().toISOString(), done, failed, total: queue.length, failures }, null, 2));
      } catch {}
    }
  }

  console.log(`\n🏁 Done: ${done} replaced, ${failed} failed (of ${queue.length})`);
  for (const f of failures.slice(0, 20)) console.log(`  - ${f.fileId} (${f.docId}): ${f.error}`);
}

main().catch((err) => {
  console.error('\nFatal Error:', err);
  process.exit(1);
});
