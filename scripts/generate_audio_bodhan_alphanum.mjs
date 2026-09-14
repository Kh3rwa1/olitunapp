#!/usr/bin/env node
/**
 * Bodhan AI Audio for Alphabets & Numbers (creation run — DB-sourced).
 *
 * Fills the gap the v2 replacement run explicitly excluded:
 *   - letters collection (30 docs)   -> TTS charOlChiki -> `ltr_<docId>`
 *   - numbers collection (0-100)     -> TTS nameOlChiki -> `num_<docId>`
 *   - alphabet + number lesson blocks lacking audioUrl -> `snd_<short>_<i>`
 *
 * Idempotent: existing audio is NEVER replaced (docs/blocks that already
 * have an audioUrl are skipped). Missing numbers docs (n_10..n_100) and the
 * number lessons 21-50 / 51-100 are created first when CREATE_MISSING=1.
 *
 * TTS: Bodhan `indic-speak`, voice `Phulmani`, instructions '{"lang":"sat"}'
 * (same voice as the words/sentences/lessons run, for a consistent app voice).
 *
 * Number lesson blocks speak the Santali NAME (e.g. "ᱯᱩᱱ ᱜᱮᱞ ᱵᱟᱨ"),
 * not the bare numeral, so learners hear the counting word.
 *
 * Usage:
 *   BODHAN_API_KEY="sk-..." node scripts/generate_audio_bodhan_alphanum.mjs
 *
 * ENV:
 *   TARGET="all" | "letters" | "numbers" | "lessons"
 *   CREATE_MISSING="1" (upsert n_10..n_100 + lessons 21-50/51-100; default 1)
 *   WRITE_SEEDS="1" (patch assets/seed/letters.json + numbers.json audioUrl
 *     for succeeded docs; default 0 — run after generation completes)
 *   LIMIT="0" OFFSET="0" ONLY_IDS="ltr_l_la,num_n_42" DRY_RUN="1" LIST_ONLY="1"
 *   DELAY_MS="5000" SHARD_COUNT="1" SHARD_INDEX="0" SKIP_IDS_FILE=""
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
const CREATE_MISSING = process.env.CREATE_MISSING !== '0';
const WRITE_SEEDS = process.env.WRITE_SEEDS === '1';
const LIMIT = parseInt(process.env.LIMIT || '0', 10);
const OFFSET = parseInt(process.env.OFFSET || '0', 10);
const ONLY_IDS = (process.env.ONLY_IDS || '').split(',').map((s) => s.trim().toLowerCase()).filter(Boolean);
const DRY_RUN = process.env.DRY_RUN === '1';
const LIST_ONLY = process.env.LIST_ONLY === '1';
const DELAY_MS = parseInt(process.env.DELAY_MS || '5000', 10);

const ENDPOINT = 'https://sgp.cloud.appwrite.io/v1';
const PROJECT_ID = '699495910038e39622c5';
const DATABASE_ID = 'olitun_db';
const BUCKET_ID = 'audio';

if (!BODHAN_API_KEY && !LIST_ONLY) {
  console.error('❌ Error: BODHAN_API_KEY (or BODHAN_API_KEY_FILE) is required.');
  process.exit(1);
}

// ---- Santali numbers (mirrors lib/shared/utils/santali_numbers.dart) ----
const _olDigits = ['᱐', '᱑', '᱒', '᱓', '᱔', '᱕', '᱖', '᱗', '᱘', '᱙'];
const _unitLat = { 0: 'Sunya', 1: 'Mit', 2: 'Bar', 3: 'Pe', 4: 'Pun', 5: 'Mone', 6: 'Turui', 7: 'Eae', 8: 'Iral', 9: 'Are' };
const _unitOl = { 0: 'ᱥᱩᱱᱭᱟ', 1: 'ᱢᱤᱫ', 2: 'ᱵᱟᱨ', 3: 'ᱯᱮ', 4: 'ᱯᱩᱱ', 5: 'ᱢᱚᱬᱮ', 6: 'ᱛᱩᱨᱩᱭ', 7: 'ᱮᱭᱟᱭ', 8: 'ᱤᱨᱟᱹᱞ', 9: 'ᱟᱨᱮ' };
const _olNumeral = (v) => String(v).split('').map((d) => _olDigits[Number(d)]).join('');
function _santaliLatin(v) {
  if (v <= 9) return _unitLat[v];
  if (v === 10) return 'Gel';
  if (v < 20) return `Gel ${_unitLat[v - 10]}`;
  if (v === 20) return 'Isi';
  if (v < 30) return `Isi ${_unitLat[v - 20]}`;
  if (v === 100) return 'Say';
  const t = Math.floor(v / 10), o = v % 10;
  const base = `${_unitLat[t]} Gel`;
  return o === 0 ? base : `${base} ${_unitLat[o]}`;
}
function _santaliOl(v) {
  if (v <= 9) return _unitOl[v];
  if (v === 10) return 'ᱜᱮᱞ';
  if (v < 20) return `ᱜᱮᱞ ${_unitOl[v - 10]}`;
  if (v === 20) return 'ᱤᱥᱤ';
  if (v < 30) return `ᱤᱥᱤ ${_unitOl[v - 20]}`;
  if (v === 100) return 'ᱥᱟᱭ';
  const t = Math.floor(v / 10), o = v % 10;
  const base = `${_unitOl[t]} ᱜᱮᱞ`;
  return o === 0 ? base : `${base} ${_unitOl[o]}`;
}
const _onesEn = ['Zero', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
const _tensEn = { 2: 'Twenty', 3: 'Thirty', 4: 'Forty', 5: 'Fifty', 6: 'Sixty', 7: 'Seventy', 8: 'Eighty', 9: 'Ninety' };
function _english(v) {
  if (v < 20) return _onesEn[v];
  if (v === 100) return 'One Hundred';
  const t = Math.floor(v / 10), o = v % 10;
  return o === 0 ? _tensEn[t] : `${_tensEn[t]}-${_onesEn[o]}`;
}
/** Ol Chiki numeral string -> int (for resolving number-lesson block text to its name). */
function _parseOlNumeral(s) {
  const map = Object.fromEntries(_olDigits.map((c, i) => [c, i]));
  let out = '';
  for (const ch of String(s || '').trim()) {
    if (!(ch in map)) return null;
    out += map[ch];
  }
  return out === '' ? null : parseInt(out, 10);
}

// ---- Appwrite helpers (admin cookie, same as previous Bodhan runs) ----
function getAppwriteHeaders(json = false) {
  const prefs = JSON.parse(readFileSync(process.env.HOME + '/.appwrite/prefs.json', 'utf8'));
  const p = prefs[PROJECT_ID];
  if (!p || !p.cookie) throw new Error('No active Appwrite CLI session cookie found');
  const h = { 'X-Appwrite-Project': PROJECT_ID, 'X-Appwrite-Mode': 'admin', Cookie: p.cookie.split(';')[0] };
  if (json) h['Content-Type'] = 'application/json';
  return h;
}
const safeFileId = (s) => String(s || '').toLowerCase().replace(/[^a-z0-9_.]/g, '_').slice(0, 36);
const viewUrl = (fileId) => `${ENDPOINT}/storage/buckets/${BUCKET_ID}/files/${fileId}/view?project=${PROJECT_ID}`;
const hasUrl = (v) => !!(v && String(v).trim());

async function fetchAllDocuments(collectionId) {
  const headers = getAppwriteHeaders(true);
  const docs = [];
  let offset = 0;
  for (;;) {
    const params = new URLSearchParams();
    params.append('queries[]', JSON.stringify({ method: 'limit', values: [100] }));
    params.append('queries[]', JSON.stringify({ method: 'offset', values: [offset] }));
    const url = `${ENDPOINT}/databases/${DATABASE_ID}/collections/${collectionId}/documents?${params}`;
    const res = await fetch(url, { headers });
    if (!res.ok) throw new Error(`List ${collectionId} failed (${res.status}): ${(await res.text()).slice(0, 200)}`);
    const json = await res.json();
    docs.push(...(json.documents || []));
    if ((json.documents || []).length < 100) break;
    offset += 100;
  }
  return docs;
}

async function getDocument(collectionId, docId) {
  const res = await fetch(`${ENDPOINT}/databases/${DATABASE_ID}/collections/${collectionId}/documents/${docId}`, { headers: getAppwriteHeaders(true) });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`Get ${collectionId}/${docId} failed (${res.status})`);
  return res.json();
}

async function createDocument(collectionId, docId, data) {
  const res = await fetch(`${ENDPOINT}/databases/${DATABASE_ID}/collections/${collectionId}/documents`, {
    method: 'POST', headers: getAppwriteHeaders(true),
    body: JSON.stringify({ documentId: docId, data }),
  });
  if (res.status === 409) return 'exists';
  if (!res.ok) throw new Error(`Create ${collectionId}/${docId} failed (${res.status}): ${(await res.text()).slice(0, 200)}`);
  return 'created';
}

async function patchDocument(collectionId, docId, data) {
  const res = await fetch(`${ENDPOINT}/databases/${DATABASE_ID}/collections/${collectionId}/documents/${docId}`, {
    method: 'PATCH', headers: getAppwriteHeaders(true),
    body: JSON.stringify({ data }),
  });
  if (!res.ok) throw new Error(`Patch ${collectionId}/${docId} failed (${res.status}): ${(await res.text()).slice(0, 200)}`);
}

async function bodhanSpeech(text, retries = 5) {
  const payload = { model: MODEL, input: text.slice(0, 2500), voice: VOICE, instructions: '{"lang": "sat"}' };
  let lastError = null;
  for (let attempt = 0; attempt <= retries; attempt++) {
    const res = await fetch(BODHAN_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${BODHAN_API_KEY}` },
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
      lastError = new Error(`Bodhan API failed (${res.status}): ${errText.slice(0, 150)}`);
      if (res.status >= 500 && attempt < retries) {
        await new Promise((r) => setTimeout(r, (attempt + 1) * 8000));
        continue;
      }
      throw lastError;
    }
    const buf = Buffer.from(await res.arrayBuffer());
    if (buf.length < 1000 || buf.subarray(0, 4).toString() !== 'RIFF') throw new Error(`Bodhan returned invalid WAV (${buf.length}b)`);
    return buf;
  }
  throw lastError || new Error('Bodhan API failed after retries');
}

async function uploadNewFile(appwriteHeaders, fileId, audioBuffer) {
  const base = `${ENDPOINT}/storage/buckets/${BUCKET_ID}/files`;
  const boundary = '----BodhanBoundary' + Math.random().toString(36).substring(2);
  const head = ['--' + boundary, 'Content-Disposition: form-data; name="fileId"', '', fileId, '--' + boundary, `Content-Disposition: form-data; name="file"; filename="${fileId}.wav"`, 'Content-Type: audio/wav', '', ''].join('\r\n');
  const body = Buffer.concat([Buffer.from(head, 'utf8'), audioBuffer, Buffer.from(`\r\n--${boundary}--\r\n`)]);
  const res = await fetch(base, { method: 'POST', headers: { ...appwriteHeaders, 'Content-Type': `multipart/form-data; boundary=${boundary}` }, body });
  if (res.status === 409) return viewUrl(fileId); // idempotent: already uploaded
  if (!res.ok) throw new Error(`Appwrite upload failed (${res.status}): ${(await res.text().catch(() => '')).slice(0, 150)}`);
  const json = await res.json();
  return viewUrl(json.$id);
}

const isAlphaNumLesson = (d) =>
  String(d.categoryId || '').startsWith('cat_alphabets') ||
  String(d.categoryId || '').startsWith('cat_numbers') ||
  String(d.$id || '').startsWith('lesson_alphabet') ||
  String(d.$id || '').startsWith('lesson_numbers');
const isNumberLesson = (d) =>
  String(d.categoryId || '').startsWith('cat_numbers') ||
  String(d.$id || '').startsWith('lesson_numbers');

function parseBlocks(doc) {
  try {
    return typeof doc.blocks === 'string' ? JSON.parse(doc.blocks || '[]') : doc.blocks || [];
  } catch { return []; }
}

async function main() {
  console.log('🚀 Bodhan AI Audio for Alphabets & Numbers (creation run)');
  console.log(`   Model: ${MODEL} | Voice: ${VOICE} | lang: sat | delay: ${DELAY_MS}ms`);
  console.log(`   Target: ${TARGET} | DryRun: ${DRY_RUN ? 'YES' : 'NO'} | CreateMissing: ${CREATE_MISSING ? 'YES' : 'NO'} | WriteSeeds: ${WRITE_SEEDS ? 'YES' : 'NO'}`);

  // ---- Phase 0: create missing numbers docs + number lessons ----
  // (writes nothing in LIST_ONLY / DRY_RUN modes)
  let numbersCatId = 'cat_numbers';
  const mayWrite = !LIST_ONLY && !DRY_RUN;
  if (mayWrite && CREATE_MISSING && (TARGET === 'all' || TARGET === 'numbers' || TARGET === 'lessons')) {
    console.log('\n📥 Ensuring numbers n_10..n_100 exist...');
    let created = 0;
    for (let v = 10; v <= 100; v++) {
      const id = `n_${v}`;
      const r = await createDocument('numbers', id, {
        numeral: _olNumeral(v), value: v,
        nameOlChiki: _santaliOl(v), nameLatin: _santaliLatin(v),
        order: v, isActive: true,
      });
      if (r === 'created') created++;
    }
    console.log(`   numbers docs created: ${created} (rest already existed)`);

    // Resolve the live numbers category from the existing 10-20 lesson so the
    // new lessons land in the same category the app actually displays.
    const ref = await getDocument('lessons', 'lesson_numbers_10_20');
    if (ref) numbersCatId = ref.categoryId || numbersCatId;
    console.log(`   numbers category: ${numbersCatId}`);
    for (const [id, start, end, order] of [['lesson_numbers_21_50', 21, 50, 2], ['lesson_numbers_51_100', 51, 100, 3]]) {
      const exists = await getDocument('lessons', id);
      if (exists) { console.log(`   ${id} exists (${parseBlocks(exists).length} blocks)`); continue; }
      const blocks = [];
      for (let v = start; v <= end; v++) {
        blocks.push({ type: 'text', textOlChiki: _olNumeral(v), textLatin: `${v} – ${_english(v)}` });
      }
      await createDocument('lessons', id, {
        categoryId: numbersCatId,
        titleOlChiki: `${_olNumeral(start)}-${_olNumeral(end)} ᱮᱞᱠᱷᱟ`,
        titleLatin: `Numbers ${start}-${end}`,
        blocks: JSON.stringify(blocks), order,
      });
      console.log(`   ${id} created (${blocks.length} blocks)`);
    }
  } else {
    const ref = await getDocument('lessons', 'lesson_numbers_10_20').catch(() => null);
    if (ref) numbersCatId = ref.categoryId || numbersCatId;
  }

  // ---- Phase 1: build queues (docs lacking audioUrl only — never replace) ----
  const letterQueue = [];
  const numberQueue = [];
  const lessonGroups = []; // {id, gaps:[{index,text}]}

  if (TARGET === 'all' || TARGET === 'letters') {
    const docs = await fetchAllDocuments('letters');
    console.log(`\n📥 letters: ${docs.length} docs`);
    for (const d of docs) {
      if (hasUrl(d.audioUrl)) continue;
      const text = String(d.charOlChiki || '').trim();
      if (!text) continue;
      letterQueue.push({ fileId: safeFileId(`ltr_${d.$id}`), docId: d.$id, text });
    }
    console.log(`   letters needing audio: ${letterQueue.length}`);
  }

  if (TARGET === 'all' || TARGET === 'numbers') {
    const docs = await fetchAllDocuments('numbers');
    console.log(`\n📥 numbers: ${docs.length} docs`);
    for (const d of docs) {
      if (hasUrl(d.audioUrl)) continue;
      const v = typeof d.value === 'number' ? d.value : _parseOlNumeral(d.numeral);
      const text = String(d.nameOlChiki || (v != null ? _santaliOl(v) : '')).trim();
      if (!text) continue;
      numberQueue.push({ fileId: safeFileId(`num_${d.$id}`), docId: d.$id, text });
    }
    console.log(`   numbers needing audio: ${numberQueue.length}`);
  }

  if (TARGET === 'all' || TARGET === 'lessons') {
    const docs = (await fetchAllDocuments('lessons')).filter(isAlphaNumLesson);
    console.log(`\n📥 alphabet/number lessons: ${docs.length}`);
    // number-name lookup for speaking names instead of bare numerals
    const numDocs = await fetchAllDocuments('numbers');
    const nameByNumeral = new Map(numDocs.map((d) => [String(d.numeral || '').trim(), String(d.nameOlChiki || '').trim()]));
    for (const d of docs) {
      const blocks = parseBlocks(d);
      const gaps = [];
      blocks.forEach((b, i) => {
        if (!b || b.type === 'quiz') return;
        if (hasUrl(b.audioUrl) || hasUrl(b.meta?.audioUrl)) return; // never replace working audio
        const ol = String(b.textOlChiki || '').trim();
        if (!ol) return;
        let text = ol;
        if (isNumberLesson(d)) {
          const v = _parseOlNumeral(ol);
          if (v != null && v >= 0 && v <= 100) text = _santaliOl(v);
          else if (nameByNumeral.get(ol)) text = nameByNumeral.get(ol);
        }
        gaps.push({ index: i, text });
      });
      if (gaps.length) lessonGroups.push({ id: d.$id, gaps });
    }
    const gapBlocks = lessonGroups.reduce((n, l) => n + l.gaps.length, 0);
    console.log(`   lessons with gaps: ${lessonGroups.length} (${gapBlocks} blocks)`);
  }

  // ---- Filters: skip-file, shards, only-ids, offset/limit ----
  let skipSet = new Set();
  if (SKIP_IDS_FILE) {
    try {
      skipSet = new Set(JSON.parse(readFileSync(SKIP_IDS_FILE, 'utf8')).map((s) => String(s).toLowerCase()));
    } catch (e) { console.error(`⚠️  Could not read SKIP_IDS_FILE: ${e.message}`); }
  }
  const shardByIndex = (arr) => arr.filter((_, i) => i % SHARD_COUNT === SHARD_INDEX);
  let letters = shardByIndex(letterQueue.filter((q) => !skipSet.has(q.fileId.toLowerCase())));
  let numbers = shardByIndex(numberQueue.filter((q) => !skipSet.has(q.fileId.toLowerCase())));
  let lessons = lessonGroups.filter((_, i) => i % SHARD_COUNT === SHARD_INDEX);
  if (ONLY_IDS.length) {
    const set = new Set(ONLY_IDS);
    letters = letters.filter((q) => set.has(q.fileId.toLowerCase()));
    numbers = numbers.filter((q) => set.has(q.fileId.toLowerCase()));
  }
  if (OFFSET > 0) { letters = letters.slice(OFFSET); numbers = numbers.slice(OFFSET); }
  if (LIMIT > 0) { letters = letters.slice(0, LIMIT); numbers = numbers.slice(0, LIMIT); }
  console.log(`\n🧩 Shard ${SHARD_INDEX}/${SHARD_COUNT}: ${letters.length} letters, ${numbers.length} numbers, ${lessons.length} lessons`);

  if (LIST_ONLY) {
    for (const q of [...letters.slice(0, 5), ...numbers.slice(0, 5)]) console.log(`   - ${q.fileId} "${q.text.slice(0, 40)}"`);
    for (const l of lessons) console.log(`   - ${l.id}: blocks ${l.gaps.map((g) => g.index).join(',')}`);
    console.log('LIST_ONLY done.');
    return;
  }

  const total = letters.length + numbers.length + lessons.reduce((n, l) => n + l.gaps.length, 0);
  if (total === 0) { console.log('Nothing to do.'); return; }
  console.log(`▶️  Processing ${total} audio clips\n`);

  const appwriteHeaders = DRY_RUN ? null : getAppwriteHeaders();
  try { mkdirSync(new URL('../output/', import.meta.url), { recursive: true }); } catch {}
  const progressName = SHARD_COUNT > 1 ? `bodhan_alphanum_progress_s${SHARD_INDEX}.json` : 'bodhan_alphanum_progress.json';
  const progressPath = new URL(`../output/${progressName}`, import.meta.url);

  let done = 0, failed = 0, n = 0;
  const failures = [];
  const succeededDocIds = { letters: [], numbers: [] };
  const saveProgress = () => {
    try { writeFileSync(progressPath, JSON.stringify({ at: new Date().toISOString(), done, failed, total, failures }, null, 2)); } catch {}
  };

  async function processOne(fileId, text, apply) {
    n++;
    try {
      process.stdout.write(`  [${n}/${total}] ${fileId} "${text.slice(0, 30)}..." -> `);
      const buf = await bodhanSpeech(text);
      if (DRY_RUN) { console.log(`🔍 dry-run OK (${buf.length}b)`); }
      else {
        const url = await uploadNewFile(appwriteHeaders, fileId, buf);
        await apply(url);
        console.log(`✅ (${buf.length}b)`);
      }
      done++;
      return true;
    } catch (e) { failed++; failures.push({ fileId, error: e.message }); console.log(`❌ ${e.message}`); return false; }
  }

  for (const q of letters) {
    const ok = await processOne(q.fileId, q.text, (url) => patchDocument('letters', q.docId, { audioUrl: url }));
    if (ok && !DRY_RUN) succeededDocIds.letters.push(q.docId);
    if (n < total) await new Promise((r) => setTimeout(r, DELAY_MS));
    if (n % 5 === 0) saveProgress();
  }
  for (const q of numbers) {
    const ok = await processOne(q.fileId, q.text, (url) => patchDocument('numbers', q.docId, { audioUrl: url }));
    if (ok && !DRY_RUN) succeededDocIds.numbers.push(q.docId);
    if (n < total) await new Promise((r) => setTimeout(r, DELAY_MS));
    if (n % 5 === 0) saveProgress();
  }
  for (const l of lessons) {
    const res = await getDocument('lessons', l.id);
    if (!res) { console.log(`❌ ${l.id} fetch failed`); failed += l.gaps.length; n += l.gaps.length; continue; }
    const blocks = parseBlocks(res);
    let dirty = false;
    for (const g of l.gaps) {
      const blk = blocks[g.index];
      if (!blk) { n++; continue; }
      if (hasUrl(blk.audioUrl) || hasUrl(blk.meta?.audioUrl)) { console.log(`⏭️  ${l.id}#${g.index} already linked`); n++; continue; }
      const fileId = safeFileId(`snd_${String(l.id).replace('lesson_', '')}_${g.index}`);
      const ok = await processOne(fileId, g.text, async () => {});
      if (ok && !DRY_RUN) {
        const url = viewUrl(fileId);
        blk.audioUrl = url;
        blk.meta = { ...(blk.meta || {}), audioUrl: url };
        dirty = true;
      }
      if (n < total) await new Promise((r) => setTimeout(r, DELAY_MS));
      if (n % 5 === 0) saveProgress();
    }
    if (dirty && !DRY_RUN) {
      // NOTE: processOne already uploaded the file; just persist block links.
      try {
        await patchDocument('lessons', l.id, { blocks: JSON.stringify(blocks) });
        console.log(`📝 ${l.id} patched`);
      } catch (e) { console.log(`❌ ${l.id} patch failed: ${e.message}`); }
    }
  }
  saveProgress();

  // ---- Phase 2: patch bundled seeds so offline/bundled playback works ----
  if (WRITE_SEEDS && !DRY_RUN && (succeededDocIds.letters.length || succeededDocIds.numbers.length)) {
    const patchSeed = (relPath, idKey, docIds) => {
      const url = new URL(`../${relPath}`, import.meta.url);
      const rows = JSON.parse(readFileSync(url, 'utf8'));
      const set = new Set(docIds);
      let count = 0;
      for (const row of rows) {
        if (!set.has(row[idKey])) continue;
        const prefix = relPath.includes('letters') ? 'ltr_' : 'num_';
        row.audioUrl = viewUrl(safeFileId(`${prefix}${row[idKey]}`));
        count++;
      }
      writeFileSync(url, JSON.stringify(rows, null, 2) + '\n', 'utf8');
      console.log(`📝 ${relPath}: ${count} audioUrl wired`);
    };
    if (succeededDocIds.letters.length) patchSeed('assets/seed/letters.json', 'id', succeededDocIds.letters);
    if (succeededDocIds.numbers.length) patchSeed('assets/seed/numbers.json', 'id', succeededDocIds.numbers);
  }

  console.log(`\n🏁 Done: ${done} generated, ${failed} failed (of ${total})`);
  for (const f of failures.slice(0, 20)) console.log(`  - ${f.fileId}: ${f.error}`);
}

main().catch((err) => { console.error('\nFatal Error:', err); process.exit(1); });
