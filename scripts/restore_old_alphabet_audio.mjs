#!/usr/bin/env node
/**
 * Restore Old Alphabet Audio Files
 *
 * Restores original/old audio files for Alphabets only:
 * - Letters collection (30 letters): points audioUrl and blocks to `ltr_l_<docId>` (e.g. `ltr_l_la`)
 * - Alphabet lessons (0 to 3): points letter blocks' audioUrl to `ltr_l_<docId>`
 * - Alphabet lesson 4 & intro text: sets audioUrl to null (as no old audio existed for diacritics/signs)
 * - Removes newly synthesized `ltr_0`..`ltr_29` and `snd_alphabet_*` from the storage bucket
 * - Leaves ALL newer audio for vocabulary, sentences, greetings, and numbers 100% intact.
 */

import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const rootDir = join(__dirname, '..');

const ENDPOINT = process.env.APPWRITE_ENDPOINT || 'https://sgp.cloud.appwrite.io/v1';
const PROJECT_ID = process.env.APPWRITE_PROJECT_ID || '699495910038e39622c5';
const DATABASE_ID = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
const BUCKET_ID = process.env.APPWRITE_BUCKET_ID || 'audio';

function getAppwriteHeaders(isJson = false) {
  const prefsPath = join(process.env.HOME || '', '.appwrite', 'prefs.json');
  const prefs = JSON.parse(readFileSync(prefsPath, 'utf8'));
  const p = prefs[PROJECT_ID];
  const headers = {
    'X-Appwrite-Project': PROJECT_ID,
    'X-Appwrite-Mode': 'admin',
    Cookie: p.cookie.split(';')[0],
  };
  if (isJson) headers['Content-Type'] = 'application/json';
  return headers;
}

const viewUrl = (fileId) =>
  `${ENDPOINT}/storage/buckets/${BUCKET_ID}/files/${fileId}/view?project=${PROJECT_ID}`;

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

async function patchDocument(collectionId, documentId, data) {
  const headers = getAppwriteHeaders(true);
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
      if (attempt === 2) throw err;
      await new Promise((r) => setTimeout(r, 800));
    }
  }
}

async function getDocument(collectionId, documentId) {
  const headers = getAppwriteHeaders(true);
  const res = await fetch(
    `${ENDPOINT}/databases/${DATABASE_ID}/collections/${collectionId}/documents/${documentId}`,
    { headers },
  );
  if (!res.ok) {
    throw new Error(`Get ${collectionId}/${documentId} failed (${res.status})`);
  }
  return res.json();
}

// Letter ID mapping
const LETTER_IDS = [
  'l_la', 'l_at', 'l_ag', 'l_ang', 'l_al',
  'l_laa', 'l_ak', 'l_aj', 'l_am', 'l_aw',
  'l_li', 'l_is', 'l_ih', 'l_iny', 'l_ir',
  'l_lu', 'l_uc', 'l_ud', 'l_unn', 'l_uy',
  'l_le', 'l_ep', 'l_edd', 'l_en', 'l_err',
  'l_lo', 'l_ott', 'l_obb', 'l_ov', 'l_oh',
];

// Mapping for lesson blocks to their corresponding old letter audio
const LESSON_LETTER_MAP = {
  lesson_alphabet_0: [
    null,      // Block 0: Intro text
    'l_la',    // Block 1: ᱚ
    'l_laa',   // Block 2: ᱟ
    'l_li',    // Block 3: ᱤ
    'l_lu',    // Block 4: ᱩ
    'l_le',    // Block 5: ᱮ
    'l_lo',    // Block 6: ᱳ
  ],
  lesson_alphabet_1: [
    'l_at',    // Block 0: ᱛ
    'l_ag',    // Block 1: ᱜ
    'l_ang',   // Block 2: ᱝ
    'l_al',    // Block 3: ᱞ
    'l_ak',    // Block 4: ᱠ
    'l_aj',    // Block 5: ᱡ
    'l_am',    // Block 6: ᱢ
    'l_aw',    // Block 7: ᱣ
  ],
  lesson_alphabet_2: [
    'l_is',    // Block 0: ᱥ
    'l_ih',    // Block 1: ᱦ
    'l_iny',   // Block 2: ᱧ
    'l_ir',    // Block 3: ᱨ
    'l_uc',    // Block 4: ᱪ
    'l_ud',    // Block 5: ᱫ
    'l_unn',   // Block 6: ᱬ
    'l_uy',    // Block 7: ᱭ
  ],
  lesson_alphabet_3: [
    'l_ep',    // Block 0: ᱯ
    'l_edd',   // Block 1: ᱰ
    'l_en',    // Block 2: ᱱ
    'l_err',   // Block 3: ᱲ
    'l_ott',   // Block 4: ᱴ
    'l_obb',   // Block 5: ᱵ
    'l_ov',    // Block 6: ᱶ
    'l_oh',    // Block 7: ᱷ
  ],
  lesson_alphabet_4: [
    null, // Block 0: ᱹ (Gahla Tudag)
    null, // Block 1: ᱸ (Mu Tudag)
    null, // Block 2: ᱺ (Mu-Gahla Tudag)
    null, // Block 3: ᱽ (Ohod)
    null, // Block 4: ᱻ (Ahd)
    null, // Block 5: ᱾ (Mucaad)
  ],
};

async function main() {
  console.log('═══════════════════════════════════════════════════════════════════');
  console.log('       Restoring Old Alphabet Audio (Keeping Newer Other Lessons)   ');
  console.log('═══════════════════════════════════════════════════════════════════\n');

  // 1. Verify old audio files exist in Appwrite Storage
  console.log('🔍 Step 1: Verifying all 30 old letter audio files exist in Storage...');
  for (const id of LETTER_IDS) {
    const fileId = `ltr_${id}`;
    const url = viewUrl(fileId);
    const res = await fetch(url);
    if (!res.ok) {
      throw new Error(`Missing expected old audio file: ${fileId} (${res.status})`);
    }
  }
  console.log('   ✅ All 30 old audio files verified (ltr_l_la ... ltr_l_oh).\n');

  // 2. Patch letters collection in Appwrite
  console.log('📝 Step 2: Updating letters collection to use old audio URLs...');
  for (const id of LETTER_IDS) {
    const fileId = `ltr_${id}`;
    const audioUrl = viewUrl(fileId);
    const currentDoc = await getDocument('letters', id);

    const glyphBlock = [
      {
        id: 'glyph_block',
        order: 0,
        type: 'glyph',
        olChiki: currentDoc.charOlChiki,
        latin: currentDoc.transliterationLatin,
        audioUrl: audioUrl,
      },
    ];

    await patchDocument('letters', id, {
      audioUrl: audioUrl,
      blocks: JSON.stringify(glyphBlock),
    });
    process.stdout.write(`   ✓ ${id} -> ${fileId}.wav\n`);
  }
  console.log('   ✅ All 30 letter documents restored to old audio.\n');

  // 3. Patch alphabet lessons in Appwrite
  console.log('📝 Step 3: Updating alphabet lessons to use old audio on letter blocks...');
  for (const [lessonId, blockMapping] of Object.entries(LESSON_LETTER_MAP)) {
    const lessonDoc = await getDocument('lessons', lessonId);
    const rawBlocks = typeof lessonDoc.blocks === 'string'
      ? JSON.parse(lessonDoc.blocks)
      : lessonDoc.blocks || [];

    const updatedBlocks = rawBlocks.map((block, idx) => {
      const letterRef = blockMapping[idx];
      const audioUrl = letterRef ? viewUrl(`ltr_${letterRef}`) : null;
      const meta = { ...(block.meta || {}) };
      if (audioUrl) {
        meta.audioUrl = audioUrl;
      } else {
        delete meta.audioUrl;
      }

      return {
        ...block,
        audioUrl: audioUrl,
        meta,
      };
    });

    await patchDocument('lessons', lessonId, {
      blocks: JSON.stringify(updatedBlocks),
    });
    console.log(`   ✓ ${lessonId}: patched ${updatedBlocks.length} blocks`);
  }
  console.log('   ✅ All 5 alphabet lessons updated.\n');

  // 4. Delete temporary synthesized files from storage
  console.log('🧹 Step 4: Cleaning up temporary newly synthesized alphabet audio files...');
  // Delete ltr_0 to ltr_29
  for (let i = 0; i < 30; i++) {
    const fileId = `ltr_${i}`;
    const deleted = await deleteStorageFile(fileId);
    if (deleted) process.stdout.write(`   - Deleted ${fileId}\n`);
  }
  // Delete snd_alphabet_*
  for (let l = 0; l <= 4; l++) {
    for (let b = 0; b < 10; b++) {
      const fileId = `snd_alphabet_${l}_${b}`;
      const deleted = await deleteStorageFile(fileId);
      if (deleted) process.stdout.write(`   - Deleted ${fileId}\n`);
    }
  }
  console.log('   ✅ Temporary audio cleaned up from Storage.\n');

  console.log('🎉 Old alphabet audio restoration complete!');
}

main().catch((err) => {
  console.error('\n❌ Error:', err.message);
  process.exit(1);
});
