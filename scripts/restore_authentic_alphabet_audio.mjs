#!/usr/bin/env node
/**
 * Restore Authentic Original Audio Files for the 35 Ol Chiki Letters
 *
 * 1. Restores authentic studio recordings (June 5, 2026, 48kHz PCM WAV with gentle background tone)
 *    for all 30 base letters.
 * 2. Adds/ensures the 5 modifier signs (Japag Arang) in the letters collection (making 35 letters total).
 * 3. Updates `ltr_l_<id>` in Appwrite Storage with the authentic 48kHz audio (replacing the synthetic 24kHz TTS).
 * 4. Updates `letters` collection in Appwrite database with the authentic audio URLs and glyph blocks.
 * 5. Updates `lesson_alphabet_0`..`lesson_alphabet_4` blocks with the authentic audio URLs.
 * 6. Preserves 100% of newer audio for other lessons (vocab, sentences, greetings, numbers).
 */

import { existsSync, readFileSync, writeFileSync } from 'node:fs';
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

// 30 base letters mapped 1-to-1 with their June 5 authentic recordings
const ORIGINAL_LETTER_MAP = [
  // Row 1
  { id: 'l_la', char: 'ᱚ', name: 'La (a)', juneFileId: '6a2250190a7f82535f27', example: 'Ol', order: 0 },
  { id: 'l_at', char: 'ᱛ', name: 'At (t)', juneFileId: '6a2250556e988268cbc4', example: 'At', order: 1 },
  { id: 'l_ag', char: 'ᱜ', name: 'Ag (g)', juneFileId: '6a2250b4a4100e7defbd', example: 'Ag', order: 2 },
  { id: 'l_ang', char: 'ᱝ', name: 'Ang (ng)', juneFileId: '6a2250d67b0c04c6801c', example: 'Ang', order: 3 },
  { id: 'l_al', char: 'ᱞ', name: 'Al (l)', juneFileId: '6a2250ee96258c657ea3', example: 'Al', order: 4 },

  // Row 2
  { id: 'l_laa', char: 'ᱟ', name: 'Laa (aa)', juneFileId: '6a225105a16085db8931', example: 'Aa', order: 5 },
  { id: 'l_ak', char: 'ᱠ', name: 'Ak (k)', juneFileId: '6a22514a3b9203095ee3', example: 'Ka', order: 6 },
  { id: 'l_aj', char: 'ᱡ', name: 'Aj (j)', juneFileId: '6a22516063da850d046a', example: 'Ja', order: 7 },
  { id: 'l_am', char: 'ᱢ', name: 'Am (m)', juneFileId: '6a22517837e889fdb03b', example: 'Ma', order: 8 },
  { id: 'l_aw', char: 'ᱣ', name: 'Aw (w)', juneFileId: '6a225190700f8c03fa04', example: 'Wa', order: 9 },

  // Row 3
  { id: 'l_li', char: 'ᱤ', name: 'Li (i)', juneFileId: '6a2251b5cfc383d059c4', example: 'Ir', order: 10 },
  { id: 'l_is', char: 'ᱥ', name: 'Is (s)', juneFileId: '6a2251e2501402bad607', example: 'Si', order: 11 },
  { id: 'l_ih', char: 'ᱦ', name: 'Ih (h)', juneFileId: '6a2251fe4c2c04d55d95', example: 'Ha', order: 12 },
  { id: 'l_iny', char: 'ᱧ', name: 'Iny (ny)', juneFileId: '6a2252113e41828569e5', example: 'Ny', order: 13 },
  { id: 'l_ir', char: 'ᱨ', name: 'Ir (r)', juneFileId: '6a2252351adb06d109e1', example: 'Ra', order: 14 },

  // Row 4
  { id: 'l_lu', char: 'ᱩ', name: 'Lu (u)', juneFileId: '6a22525a21ef8b1b0c78', example: 'Ul', order: 15 },
  { id: 'l_uc', char: 'ᱪ', name: 'Uc (c)', juneFileId: '6a2252741ccf0c743cbd', example: 'Ca', order: 16 },
  { id: 'l_ud', char: 'ᱫ', name: 'Ud (d)', juneFileId: '6a22528ed13a81b80015', example: 'Da', order: 17 },
  { id: 'l_unn', char: 'ᱬ', name: 'Unn (nn)', juneFileId: '6a2252ac05dc0a9715c2', example: 'Nn', order: 18 },
  { id: 'l_uy', char: 'ᱭ', name: 'Uy (y)', juneFileId: '6a2252c70714877a5a0a', example: 'Ya', order: 19 },

  // Row 5
  { id: 'l_le', char: 'ᱮ', name: 'Le (e)', juneFileId: '6a2252dc708c86888ec6', example: 'En', order: 20 },
  { id: 'l_ep', char: 'ᱯ', name: 'Ep (p)', juneFileId: '6a22533a8d9a0373fe0b', example: 'Pa', order: 21 },
  { id: 'l_edd', char: 'ᱰ', name: 'Edd (dd)', juneFileId: '6a225355084d08dea4ca', example: 'Dd', order: 22 },
  { id: 'l_en', char: 'ᱱ', name: 'En (n)', juneFileId: '6a22537d416e01308ed2', example: 'Na', order: 23 },
  { id: 'l_err', char: 'ᱲ', name: 'Err (rr)', juneFileId: '6a225395372d07ecb0de', example: 'Rr', order: 24 },

  // Row 6
  { id: 'l_lo', char: 'ᱳ', name: 'Lo (o)', juneFileId: '6a2259f209c40c851e46', example: 'Ol', order: 25 },
  { id: 'l_ott', char: 'ᱴ', name: 'Ott (tt)', juneFileId: '6a225a094e200e7c1e99', example: 'Tt', order: 26 },
  { id: 'l_obb', char: 'ᱵ', name: 'Obb (b)', juneFileId: '6a225a203f7a00d74225', example: 'Ba', order: 27 },
  { id: 'l_ov', char: 'ᱶ', name: 'Ov (v)', juneFileId: '6a225a389c400594c3dd', example: 'Va', order: 28 },
  { id: 'l_oh', char: 'ᱷ', name: 'Oh (h)', juneFileId: '6a225a4cf07a8a62fb2e', example: 'Ha', order: 29 },
];

// Row 7: The 5 Japag Arang modifier signs completing the 35 letters
const MODIFIER_LETTERS = [
  { id: 'l_mu_tudag', char: 'ᱸ', name: 'Mu Tudag', example: 'ᱦᱮᱸ', exampleLatin: 'Hẽ', order: 30 },
  { id: 'l_gahla_tudag', char: 'ᱹ', name: 'Gahla Tudag', example: 'ᱟᱹᱛᱩ', exampleLatin: 'Atu', order: 31 },
  { id: 'l_mu_gahla_tudag', char: 'ᱺ', name: 'Mu-Gahla Tudag', example: 'ᱥᱟᱺᱜᱤᱧ', exampleLatin: 'Sanginj', order: 32 },
  { id: 'l_ohod', char: 'ᱽ', name: 'Ohod', example: 'ᱢᱟᱹᱡᱷᱤ', exampleLatin: 'Majhi', order: 33 },
  { id: 'l_ahd', char: 'ᱻ', name: 'Ahd', example: 'ᱮᱻ', exampleLatin: 'E', order: 34 },
];

// Mapping for alphabet lesson blocks to their corresponding June 5 authentic audio
const LESSON_LETTER_MAP = {
  lesson_alphabet_0: [
    null,                    // Block 0: Intro text
    '6a2250190a7f82535f27',  // Block 1: ᱚ (La)
    '6a225105a16085db8931',  // Block 2: ᱟ (Laa)
    '6a2251b5cfc383d059c4',  // Block 3: ᱤ (Li)
    '6a22525a21ef8b1b0c78',  // Block 4: ᱩ (Lu)
    '6a2252dc708c86888ec6',  // Block 5: ᱮ (Le)
    '6a2259f209c40c851e46',  // Block 6: ᱳ (Lo)
  ],
  lesson_alphabet_1: [
    '6a2250556e988268cbc4',  // Block 0: ᱛ (At)
    '6a2250b4a4100e7defbd',  // Block 1: ᱜ (Ag)
    '6a2250d67b0c04c6801c',  // Block 2: ᱝ (Ang)
    '6a2250ee96258c657ea3',  // Block 3: ᱞ (Al)
    '6a22514a3b9203095ee3',  // Block 4: ᱠ (Ak)
    '6a22516063da850d046a',  // Block 5: ᱡ (Aj)
    '6a22517837e889fdb03b',  // Block 6: ᱢ (Am)
    '6a225190700f8c03fa04',  // Block 7: ᱣ (Aw)
  ],
  lesson_alphabet_2: [
    '6a2251e2501402bad607',  // Block 0: ᱥ (Is)
    '6a2251fe4c2c04d55d95',  // Block 1: ᱦ (Ih)
    '6a2252113e41828569e5',  // Block 2: ᱧ (Iny)
    '6a2252351adb06d109e1',  // Block 3: ᱨ (Ir)
    '6a2252741ccf0c743cbd',  // Block 4: ᱪ (Uc)
    '6a22528ed13a81b80015',  // Block 5: ᱫ (Ud)
    '6a2252ac05dc0a9715c2',  // Block 6: ᱬ (Unn)
    '6a2252c70714877a5a0a',  // Block 7: ᱭ (Uy)
  ],
  lesson_alphabet_3: [
    '6a22533a8d9a0373fe0b',  // Block 0: ᱯ (Ep)
    '6a225355084d08dea4ca',  // Block 1: ᱰ (Edd)
    '6a22537d416e01308ed2',  // Block 2: ᱱ (En)
    '6a225395372d07ecb0de',  // Block 3: ᱲ (Err)
    '6a225a094e200e7c1e99',  // Block 4: ᱴ (Ott)
    '6a225a203f7a00d74225',  // Block 5: ᱵ (Obb)
    '6a225a389c400594c3dd',  // Block 6: ᱶ (Ov)
    '6a225a4cf07a8a62fb2e',  // Block 7: ᱷ (Oh)
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

async function upsertDocument(collectionId, documentId, data) {
  const headers = getAppwriteHeaders(true);
  try {
    const res = await fetch(
      `${ENDPOINT}/databases/${DATABASE_ID}/collections/${collectionId}/documents/${documentId}`,
      {
        method: 'PATCH',
        headers,
        body: JSON.stringify({ data }),
      },
    );
    if (res.ok) return res.json();
  } catch {}

  // If patch failed, create new document
  const createRes = await fetch(
    `${ENDPOINT}/databases/${DATABASE_ID}/collections/${collectionId}/documents`,
    {
      method: 'POST',
      headers,
      body: JSON.stringify({ documentId, data }),
    },
  );
  if (!createRes.ok) {
    const errText = await createRes.text().catch(() => '');
    throw new Error(`Create ${collectionId}/${documentId} failed (${createRes.status}): ${errText}`);
  }
  return createRes.json();
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

async function uploadStorageFile(fileId, filename, buffer, mimeType = 'audio/wav') {
  const headers = getAppwriteHeaders();
  const formData = new FormData();
  formData.append('fileId', fileId);
  formData.append(
    'file',
    new Blob([buffer], { type: mimeType }),
    filename,
  );
  formData.append('permissions[]', 'read("any")');

  const res = await fetch(`${ENDPOINT}/storage/buckets/${BUCKET_ID}/files`, {
    method: 'POST',
    headers,
    body: formData,
  });
  if (!res.ok) {
    const text = await res.text().catch(() => '');
    throw new Error(`Upload ${fileId} failed (${res.status}): ${text}`);
  }
  return res.json();
}

async function main() {
  console.log('═══════════════════════════════════════════════════════════════════');
  console.log('  Restoring Authentic Original Audio for the 35 Ol Chiki Letters   ');
  console.log('═══════════════════════════════════════════════════════════════════\n');

  // 1. Verify all 30 original June 5 audio files in Storage
  console.log('🔍 Step 1: Verifying all 30 original June 5 audio files in Storage...');
  for (const item of ORIGINAL_LETTER_MAP) {
    const url = viewUrl(item.juneFileId);
    const res = await fetch(url);
    if (!res.ok) {
      throw new Error(`Missing June 5 file for ${item.id} (${item.char}): ${item.juneFileId} (${res.status})`);
    }
  }
  console.log('   ✅ All 30 authentic original audio files verified.\n');

  // 2. Overwrite `ltr_l_<id>` in Storage with the authentic 48kHz WAV
  console.log('💾 Step 2: Replacing synthetic TTS ltr_l_* with authentic 48kHz audio in Storage...');
  for (const item of ORIGINAL_LETTER_MAP) {
    const ltrFileId = `ltr_${item.id}`;
    // Download original June 5 file
    const res = await fetch(viewUrl(item.juneFileId));
    const buf = Buffer.from(await res.arrayBuffer());

    // Delete existing ltr_l_* if present
    await deleteStorageFile(ltrFileId);

    // Re-upload authentic audio under ltr_l_*
    await uploadStorageFile(ltrFileId, `${ltrFileId}.wav`, buf, 'audio/wav');
    process.stdout.write(`   ✓ ${ltrFileId} (${buf.length} bytes, 48kHz authentic studio recording)\n`);
  }
  console.log('   ✅ All 30 storage files updated with authentic studio recordings.\n');

  // 3. Update all 30 base letters in Appwrite Database
  console.log('📝 Step 3: Updating letters collection with authentic audio URLs...');
  for (const item of ORIGINAL_LETTER_MAP) {
    const audioUrl = viewUrl(item.juneFileId);
    const glyphBlock = [
      {
        id: 'glyph_block',
        order: 0,
        type: 'glyph',
        olChiki: item.char,
        latin: item.name,
        audioUrl: audioUrl,
      },
    ];

    await patchDocument('letters', item.id, {
      audioUrl: audioUrl,
      charOlChiki: item.char,
      transliterationLatin: item.name,
      exampleWord: item.example,
      order: item.order,
      isActive: true,
      blocks: JSON.stringify(glyphBlock),
    });
    process.stdout.write(`   ✓ letters/${item.id} (${item.char} - ${item.name})\n`);
  }

  // 4. Ensure the 5 modifier signs (Japag Arang) in the letters collection (making 35 letters)
  console.log('\n📝 Step 4: Ensuring 5 modifier signs in letters collection (35 letters total)...');
  for (const mod of MODIFIER_LETTERS) {
    const glyphBlock = [
      {
        id: 'glyph_block',
        order: 0,
        type: 'glyph',
        olChiki: mod.char,
        latin: mod.name,
        audioUrl: null,
      },
    ];

    await upsertDocument('letters', mod.id, {
      charOlChiki: mod.char,
      transliterationLatin: mod.name,
      exampleWord: mod.example,
      exampleWordLatin: mod.exampleLatin,
      order: mod.order,
      isActive: true,
      audioUrl: null,
      blocks: JSON.stringify(glyphBlock),
    });
    process.stdout.write(`   ✓ letters/${mod.id} (${mod.char} - ${mod.name})\n`);
  }
  console.log('   ✅ All 35 letters configured in Database.\n');

  // 5. Update alphabet lessons to use authentic audio URLs
  console.log('📝 Step 5: Updating alphabet lessons with authentic audio URLs...');
  for (const [lessonId, blockMapping] of Object.entries(LESSON_LETTER_MAP)) {
    const lessonDoc = await getDocument('lessons', lessonId);
    const rawBlocks = typeof lessonDoc.blocks === 'string'
      ? JSON.parse(lessonDoc.blocks)
      : lessonDoc.blocks || [];

    const updatedBlocks = rawBlocks.map((block, idx) => {
      const fileId = blockMapping[idx];
      const audioUrl = fileId ? viewUrl(fileId) : null;
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

  console.log('🎉 Authentic original audio restoration complete for all 35 letters!');
}

main().catch((err) => {
  console.error('\n❌ Fatal error:', err.message);
  process.exit(1);
});
