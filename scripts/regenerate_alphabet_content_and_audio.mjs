#!/usr/bin/env node
/**
 * Ol Chiki Alphabet Lessons & Letters Overhaul and Audio Synthesizer
 *
 * Replaces the flawed legacy alphabet lessons with authentic Ol Chiki curriculum:
 * - 30 Letters in `letters` collection: accurate names, Ol Chiki example words, multi-language meanings, and audio.
 * - 5 Alphabet Lessons in `lessons` collection:
 *   1. `lesson_alphabet_0`: The 6 Pure Vowels (ᱨᱟᱦᱟ ᱟᱲᱟᱝ - ᱚ, ᱟ, ᱤ, ᱩ, ᱮ, ᱳ)
 *   2. `lesson_alphabet_1`: Consonants Group 1 (ᱠᱮᱪᱮᱫ ᱟᱲᱟᱝ I - ᱛ, ᱜ, ᱝ, ᱞ, ᱠ, ᱡ, ᱢ, ᱣ)
 *   3. `lesson_alphabet_2`: Consonants Group 2 (ᱠᱮᱪᱮᱫ ᱟᱲᱟᱝ II - ᱥ, ᱦ, ᱧ, ᱨ, ᱪ, ᱫ, ᱬ, ᱭ)
 *   4. `lesson_alphabet_3`: Consonants Group 3 (ᱠᱮᱪᱮᱫ ᱟᱲᱟᱝ III - ᱯ, ᱰ, ᱱ, ᱲ, ᱴ, ᱵ, ᱶ, ᱷ)
 *   5. `lesson_alphabet_4`: Modifiers & Signs (ᱡᱟᱯᱟᱜ ᱟᱲᱟᱝ - ᱹ, ᱸ, ᱺ, ᱽ, ᱻ, ᱾)
 *
 * Synthesizes audio using Bodhan AI (Phulmani voice, indic-speak, lang: sat) rotating across 8 keys.
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const rootDir = join(__dirname, '..');

const ENDPOINT = process.env.APPWRITE_ENDPOINT || 'https://sgp.cloud.appwrite.io/v1';
const PROJECT_ID = process.env.APPWRITE_PROJECT_ID || '699495910038e39622c5';
const DATABASE_ID = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
const BUCKET_ID = process.env.APPWRITE_BUCKET_ID || 'audio';

const BODHAN_URL = process.env.BODHAN_URL || 'https://api.bodhan.ai/v1/audio/speech';
const MODEL = 'indic-speak';
const VOICE = 'Phulmani';
const INSTRUCTIONS = '{"lang": "sat"}';

const DELAY_MS = parseInt(process.env.DELAY_MS || '200', 10);
const DRY_RUN = process.env.DRY_RUN === '1';

// Load Bodhan keys
function loadBodhanKeys() {
  const keys = [];
  for (let i = 0; i < 10; i++) {
    const keyPath = join(rootDir, '.keys', `bodhan${i}`);
    if (existsSync(keyPath)) {
      const key = readFileSync(keyPath, 'utf8').trim();
      if (key) keys.push({ id: `bodhan${i}`, key });
    }
  }
  if (keys.length === 0) throw new Error('No Bodhan API keys found in .keys/bodhan*');
  return keys;
}

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

  await deleteStorageFile(fileId);

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
        throw new Error(`Upload failed (${res.status}): ${errText}`);
      }
      return `${ENDPOINT}/storage/buckets/${BUCKET_ID}/files/${fileId}/view?project=${PROJECT_ID}`;
    } catch (err) {
      if (attempt === 3) throw err;
      await new Promise((r) => setTimeout(r, 1000 * (attempt + 1)));
    }
  }
}

async function patchDocument(collectionId, documentId, data) {
  const headers = getAppwriteHeaders(true);
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const res = await fetch(`${ENDPOINT}/databases/${DATABASE_ID}/collections/${collectionId}/documents/${documentId}`, {
        method: 'PATCH',
        headers,
        body: JSON.stringify({ data }),
      });
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
    const sanitizedText = text
      .replace(/।/g, '᱾')
      .replace(/॥/g, '᱾')
      .replace(/\s+/g, ' ')
      .trim();

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
          await new Promise((r) => setTimeout(r, 1000));
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
        await new Promise((r) => setTimeout(r, 1000));
      }
    }
    throw lastError || new Error('Bodhan TTS failed');
  }
}

// Canonical Letters Dataset (All 30 Letters in proper order)
const CANONICAL_LETTERS = [
  { id: 'l_la', char: 'ᱚ', name: 'La (ɔ)', wordOlChiki: 'ᱚᱞ', wordLatin: 'Ol', wordMeaning: 'To write / Study', speech: 'ᱚ ᱚᱞ' },
  { id: 'l_at', char: 'ᱛ', name: 'At (t)', wordOlChiki: 'ᱛᱤ', wordLatin: 'Ti', wordMeaning: 'Hand', speech: 'ᱛ ᱛᱤ' },
  { id: 'l_ag', char: 'ᱜ', name: 'Ag (g)', wordOlChiki: 'ᱜᱟᱰᱟ', wordLatin: 'Gada', wordMeaning: 'River', speech: 'ᱜ ᱜᱟᱰᱟ' },
  { id: 'l_ang', char: 'ᱝ', name: 'Ang (ng)', wordOlChiki: 'ᱥᱟᱝ', wordLatin: 'Sang', wordMeaning: 'Companion / With', speech: 'ᱝ ᱥᱟᱝ' },
  { id: 'l_al', char: 'ᱞ', name: 'Al (l)', wordOlChiki: 'ᱞᱟᱸᱫᱟ', wordLatin: 'Landa', wordMeaning: 'Smile / Laugh', speech: 'ᱞ ᱞᱟᱸᱫᱟ' },

  { id: 'l_laa', char: 'ᱟ', name: 'Laa (a)', wordOlChiki: 'ᱟᱭᱳ', wordLatin: 'Ayo', wordMeaning: 'Mother', speech: 'ᱟ ᱟᱭᱳ' },
  { id: 'l_ak', char: 'ᱠ', name: 'Aak (k)', wordOlChiki: 'ᱠᱟᱹᱢᱤ', wordLatin: 'Kami', wordMeaning: 'Work / Labor', speech: 'ᱠ ᱠᱟᱹᱢᱤ' },
  { id: 'l_aj', char: 'ᱡ', name: 'Aaj (j)', wordOlChiki: 'ᱡᱚ', wordLatin: 'Jo', wordMeaning: 'Fruit', speech: 'ᱡ ᱡᱚ' },
  { id: 'l_am', char: 'ᱢ', name: 'Aam (m)', wordOlChiki: 'ᱢᱟᱹᱱᱢᱤ', wordLatin: 'Manmi', wordMeaning: 'Human / Person', speech: 'ᱢ ᱢᱟᱹᱱᱢᱤ' },
  { id: 'l_aw', char: 'ᱣ', name: 'Aaw (w)', wordOlChiki: 'ᱫᱟᱣ', wordLatin: 'Daw', wordMeaning: 'Opportunity', speech: 'ᱣ ᱫᱟᱣ' },

  { id: 'l_li', char: 'ᱤ', name: 'Li (i)', wordOlChiki: 'ᱤᱧ', wordLatin: 'Iny', wordMeaning: 'I / Me', speech: 'ᱤ ᱤᱧ' },
  { id: 'l_is', char: 'ᱥ', name: 'Is (s)', wordOlChiki: 'ᱥᱟᱹᱨᱤ', wordLatin: 'Sari', wordMeaning: 'Truth / Real', speech: 'ᱥ ᱥᱟᱹᱨᱤ' },
  { id: 'l_ih', char: 'ᱦ', name: 'Ih (h)', wordOlChiki: 'ᱦᱚᱲ', wordLatin: 'Hor', wordMeaning: 'Person / Santal', speech: 'ᱦ ᱦᱚᱲ' },
  { id: 'l_iny', char: 'ᱧ', name: 'Iny (ny)', wordOlChiki: 'ᱧᱮᱞ', wordLatin: 'Nyel', wordMeaning: 'To see / Look', speech: 'ᱧ ᱧᱮᱞ' },
  { id: 'l_ir', char: 'ᱨ', name: 'Ir (r)', wordOlChiki: 'ᱨᱚᱲ', wordLatin: 'Ror', wordMeaning: 'To speak / Speech', speech: 'ᱨ ᱨᱚᱲ' },

  { id: 'l_lu', char: 'ᱩ', name: 'Lu (u)', wordOlChiki: 'ᱩᱞ', wordLatin: 'Ul', wordMeaning: 'Mango', speech: 'ᱩ ᱩᱞ' },
  { id: 'l_uc', char: 'ᱪ', name: 'Uch (ch)', wordOlChiki: 'ᱪᱮᱬᱮ', wordLatin: 'Chene', wordMeaning: 'Bird', speech: 'ᱪ ᱪᱮᱬᱮ' },
  { id: 'l_ud', char: 'ᱫ', name: 'Ud (d)', wordOlChiki: 'ᱫᱟᱜ', wordLatin: 'Dag', wordMeaning: 'Water / Rain', speech: 'ᱫ ᱫᱟᱜ' },
  { id: 'l_unn', char: 'ᱬ', name: 'Enn (nn)', wordOlChiki: 'ᱨᱬ', wordLatin: 'Ran', wordMeaning: 'Echo / Resonance', speech: 'ᱬ ᱨᱬ' },
  { id: 'l_uy', char: 'ᱭ', name: 'Uy (y)', wordOlChiki: 'ᱠᱚᱭ', wordLatin: 'Koy', wordMeaning: 'To ask / Request', speech: 'ᱭ ᱠᱚᱭ' },

  { id: 'l_le', char: 'ᱮ', name: 'Le (e)', wordOlChiki: 'ᱮᱱᱮᱡ', wordLatin: 'Enej', wordMeaning: 'Dance / To dance', speech: 'ᱮ ᱮᱱᱮᱡ' },
  { id: 'l_ep', char: 'ᱯ', name: 'Ep (p)', wordOlChiki: 'ᱯᱚᱨᱚᱵ', wordLatin: 'Porob', wordMeaning: 'Festival', speech: 'ᱯ ᱯᱚᱨᱚᱵ' },
  { id: 'l_edd', char: 'ᱰ', name: 'Edd (dd)', wordOlChiki: 'ᱰᱟᱦᱟᱨ', wordLatin: 'Dahar', wordMeaning: 'Way / Path', speech: 'ᱰ ᱰᱟᱦᱟᱨ' },
  { id: 'l_en', char: 'ᱱ', name: 'En (n)', wordOlChiki: 'ᱱᱟᱯᱟᱭ', wordLatin: 'Napay', wordMeaning: 'Good / Fine', speech: 'ᱱ ᱱᱟᱯᱟᱭ' },
  { id: 'l_err', char: 'ᱲ', name: 'Err (rr)', wordOlChiki: 'ᱫᱟᱲᱮ', wordLatin: 'Dare', wordMeaning: 'Strength / Power', speech: 'ᱲ ᱫᱟᱲᱮ' },

  { id: 'l_lo', char: 'ᱳ', name: 'Lo (o)', wordOlChiki: 'ᱳᱲᱟᱜ', wordLatin: 'Orag', wordMeaning: 'House / Home', speech: 'ᱳ ᱳᱲᱟᱜ' },
  { id: 'l_ott', char: 'ᱴ', name: 'Ott (tt)', wordOlChiki: 'ᱴᱟᱠᱟ', wordLatin: 'Taka', wordMeaning: 'Money / Rupee', speech: 'ᱴ ᱴᱟᱠᱟ' },
  { id: 'l_obb', char: 'ᱵ', name: 'Ob (b)', wordOlChiki: 'ᱵᱟᱦᱟ', wordLatin: 'Baha', wordMeaning: 'Flower', speech: 'ᱵ ᱵᱟᱦᱟ' },
  { id: 'l_ov', char: 'ᱶ', name: 'Ov (w̃)', wordOlChiki: 'ᱥᱟᱶ', wordLatin: 'Saw', wordMeaning: 'Together / With', speech: 'ᱶ ᱥᱟᱶ' },
  { id: 'l_oh', char: 'ᱷ', name: 'Oh (h)', wordOlChiki: 'ᱯᱷᱟᱹᱜᱩᱱ', wordLatin: 'Phagun', wordMeaning: 'Spring Month (Phagun)', speech: 'ᱷ ᱯᱷᱟᱹᱜᱩᱱ' },
];

// Authentic 5 Alphabet Lessons
const ALPHABET_LESSONS = [
  {
    id: 'lesson_alphabet_0',
    titleLatin: 'The 6 Vowels (Raha Arang)',
    titleOlChiki: 'ᱨᱟᱦᱟ ᱟᱲᱟᱝ (ᱢᱩᱞ ᱖ ᱜᱚᱴᱟᱝ)',
    blocks: [
      {
        type: 'text',
        textOlChiki: 'ᱨᱟᱦᱟ ᱟᱲᱟᱝ ᱫᱚ ᱛᱩᱨᱩᱭ ᱜᱚᱴᱟᱝ ᱢᱮᱱᱟᱜᱼᱟ᱾',
        textLatin: 'Ol Chiki has 6 basic vowels called Raha Arang (ᱨᱟᱦᱟ ᱟᱲᱟᱝ).',
        speech: 'ᱨᱟᱦᱟ ᱟᱲᱟᱝ ᱫᱚ ᱛᱩᱨᱩᱭ ᱜᱚᱴᱟᱝ ᱢᱮᱱᱟᱜᱼᱟ᱾',
        meta: {
          textBengali: 'রাহা আড়াং দ তুরুয় গটাং মেনাঃ-আ।',
          textHindi: 'राहा आड़ांग द तुरुय गोटांग मेनाग-आ।',
          textOdia: 'ରାହା ଆଡ଼ାଙ୍ଗ ଦ ତୁରୁୟ ଗଟାଙ୍ଗ ମେନାଗ-ଆ।',
          pronunciation: 'Raha arang do turuy gotang menag-a.',
          meaning: 'There are 6 basic vowels in Ol Chiki.',
          meaning_en: 'There are 6 basic vowels in Ol Chiki.',
          meaning_bn: 'অল চিকিতে মূল ৬টি স্বরবর্ণ রয়েছে।',
          meaning_hi: 'ओल चिकी में मूल ६ स्वर वर्ण हैं।',
          meaning_or: 'ଅଲ ଚିକିରେ ମୂଳ ୬ଟି ସ୍ୱରବର୍ଣ୍ଣ ରହିଛି।',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱚ - ᱚᱞ',
        textLatin: 'ᱚ (La) – as in ᱚᱞ (Ol: To write / Study)',
        speech: 'ᱚ, ᱚᱞ',
        meta: {
          textBengali: 'অ - অল (লেখা / পড়া)',
          textHindi: 'ओ - ओल (लिखना / पढ़ना)',
          textOdia: 'ଅ - ଅଲ୍ (ଲେଖିବା / ପଢ଼ିବା)',
          pronunciation: 'La – Ol',
          meaning: 'Vowel ᱚ (La), as in ᱚᱞ (Ol: To write / Study)',
          meaning_en: 'Vowel ᱚ (La), as in ᱚᱞ (Ol: To write / Study)',
          meaning_bn: 'স্বরবর্ণ ᱚ (ল), যেমন ᱚᱞ (অল: লেখা / পড়াশোনা)',
          meaning_hi: 'स्वर ᱚ (ल), जैसे ᱚᱞ (ओल: लिखना / पढ़ना)',
          meaning_or: 'ସ୍ୱରବର୍ଣ୍ଣ ᱚ (ଲ), ଯେପରି ᱚᱞ (ଅଲ୍: ଲେଖିବା / ପଢ଼ିବା)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱟ - ᱟᱭᱳ',
        textLatin: 'ᱟ (Laa) – as in ᱟᱭᱳ (Ayo: Mother)',
        speech: 'ᱟ, ᱟᱭᱳ',
        meta: {
          textBengali: 'আ - আয়ো (মা)',
          textHindi: 'आ - आयो (माँ)',
          textOdia: 'ଆ - ଆୟୋ (ମାଆ)',
          pronunciation: 'Laa – Ayo',
          meaning: 'Vowel ᱟ (Laa), as in ᱟᱭᱳ (Ayo: Mother)',
          meaning_en: 'Vowel ᱟ (Laa), as in ᱟᱭᱳ (Ayo: Mother)',
          meaning_bn: 'স্বরবর্ণ ᱟ (লা), যেমন ᱟᱭᱳ (আইয়ো: মা)',
          meaning_hi: 'स्वर ᱟ (ला), जैसे ᱟᱭᱳ (आयो: माँ)',
          meaning_or: 'ସ୍ୱରବର୍ଣ୍ଣ ᱟ (ଲା), ଯେପରି ᱟୟୋ (ଆୟୋ: ମାଆ)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱤ - ᱤᱧ',
        textLatin: 'ᱤ (Li) – as in ᱤᱧ (Iny: I / Me)',
        speech: 'ᱤ, ᱤᱧ',
        meta: {
          textBengali: 'ই - ইঞ (আমি)',
          textHindi: 'इ - इञ (मैं)',
          textOdia: 'ଇ - ଇଞ (ମୁଁ)',
          pronunciation: 'Li – Iny',
          meaning: 'Vowel ᱤ (Li), as in ᱤᱧ (Iny: I / Me)',
          meaning_en: 'Vowel ᱤ (Li), as in ᱤᱧ (Iny: I / Me)',
          meaning_bn: 'স্বরবর্ণ ᱤ (লি), যেমন ᱤᱧ (ইঞ: আমি)',
          meaning_hi: 'स्वर ᱤ (लि), जैसे ᱤᱧ (इञ: मैं)',
          meaning_or: 'ସ୍ୱରବର୍ଣ୍ଣ ᱤ (ଲି), ଯେପରି ᱤଞ (ମୁଁ)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱩ - ᱩᱞ',
        textLatin: 'ᱩ (Lu) – as in ᱩᱞ (Ul: Mango)',
        speech: 'ᱩ, ᱩᱞ',
        meta: {
          textBengali: 'উ - উল (আম)',
          textHindi: 'उ - उल (आम)',
          textOdia: 'ଉ - ଉଲ୍ (ଆମ୍ବ)',
          pronunciation: 'Lu – Ul',
          meaning: 'Vowel ᱩ (Lu), as in ᱩᱞ (Ul: Mango)',
          meaning_en: 'Vowel ᱩ (Lu), as in ᱩᱞ (Ul: Mango)',
          meaning_bn: 'স্বরবর্ণ ᱩ (লু), যেমন ᱩᱞ (উল: আম)',
          meaning_hi: 'स्वर ᱩ (लु), जैसे ᱩᱞ (उल: आम)',
          meaning_or: 'ସ୍ୱରବର୍ଣ୍ଣ ᱩ (ଲୁ), ଯେପରି ଉଲ୍ (ଆମ୍ବ)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱮ - ᱮᱱᱮᱡ',
        textLatin: 'ᱮ (Le) – as in ᱮᱱᱮᱡ (Enej: Dance)',
        speech: 'ᱮ, ᱮᱱᱮᱡ',
        meta: {
          textBengali: 'এ - এনেজ (নাচ)',
          textHindi: 'ए - एनेज (नाचना)',
          textOdia: 'ଏ - ଏନେଜ୍ (ନାଚିବା)',
          pronunciation: 'Le – Enej',
          meaning: 'Vowel ᱮ (Le), as in ᱮᱱᱮᱡ (Enej: Dance)',
          meaning_en: 'Vowel ᱮ (Le), as in ᱮᱱᱮᱡ (Enej: Dance)',
          meaning_bn: 'স্বরবর্ণ ᱮ (লে), যেমন ᱮᱱᱮᱡ (এনেজ: নাচ)',
          meaning_hi: 'स्वर ᱮ (ले), जैसे ᱮᱱᱮᱡ (एनेज: नाचना / नृत्य)',
          meaning_or: 'ସ୍ୱରବର୍ଣ୍ଣ ᱮ (ଲେ), ଯେପରି ଏନେଜ୍ (ନାଚିବା)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱳ - ᱳᱲᱟᱜ',
        textLatin: 'ᱳ (Lo) – as in ᱳᱲᱟᱜ (Orag: House / Home)',
        speech: 'ᱳ, ᱳᱲᱟᱜ',
        meta: {
          textBengali: 'ও - ওড়াগ (ঘর / বাড়ি)',
          textHindi: 'ओ - ओड़ाग (घर)',
          textOdia: 'ଓ - ଓଡ଼ାଗ୍ (ଘର)',
          pronunciation: 'Lo – Orag',
          meaning: 'Vowel ᱳ (Lo), as in ᱳᱲᱟᱜ (Orag: House / Home)',
          meaning_en: 'Vowel ᱳ (Lo), as in ᱳᱲᱟᱜ (Orag: House / Home)',
          meaning_bn: 'স্বরবর্ণ ᱳ (লো), যেমন ᱳᱲᱟᱜ (ওড়াগ: ঘর / বাড়ি)',
          meaning_hi: 'स्वर ᱳ (लो), जैसे ᱳᱲᱟᱜ (ओड़ाग: घर / मकान)',
          meaning_or: 'ସ୍ୱରବର୍ଣ୍ଣ ଓ (ଲୋ), ଯେପରି ଓଡ଼ାଗ୍ (ଘର)',
        },
      },
    ],
  },
  {
    id: 'lesson_alphabet_1',
    titleLatin: 'Consonants: Group 1 (Velar & Dental)',
    titleOlChiki: 'ᱠᱮᱪᱮᱫ ᱟᱲᱟᱝ I (ᱚ ᱟᱨ ᱟ ᱛᱷᱚᱠ)',
    blocks: [
      {
        type: 'text',
        textOlChiki: 'ᱛ - ᱛᱤ',
        textLatin: 'ᱛ (At) – as in ᱛᱤ (Ti: Hand)',
        speech: 'ᱛ, ᱛᱤ',
        meta: {
          textBengali: 'ত - তি (হাত)',
          textHindi: 'त - ति (हाथ)',
          textOdia: 'ତ - ତି (ହାତ)',
          pronunciation: 'At – Ti',
          meaning: 'Consonant ᱛ (At), as in ᱛᱤ (Ti: Hand)',
          meaning_en: 'Consonant ᱛ (At), as in ᱛᱤ (Ti: Hand)',
          meaning_bn: 'ব্যঞ্জনবর্ণ ᱛ (অৎ), যেমন ᱛᱤ (তি: হাত)',
          meaning_hi: 'व्यंजन ᱛ (अत), जैसे ᱛᱤ (ति: हाथ)',
          meaning_or: 'ବ୍ୟଞ୍ଜନବର୍ଣ୍ଣ ᱛ (ଅତ୍), ଯେପରି ᱛᱤ (ତି: ହାତ)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱜ - ᱜᱟᱰᱟ',
        textLatin: 'ᱜ (Ag) – as in ᱜᱟᱰᱟ (Gada: River)',
        speech: 'ᱜ, ᱜᱟᱰᱟ',
        meta: {
          textBengali: 'গ - গাডা (নদী)',
          textHindi: 'ग - गाडा (नदी)',
          textOdia: 'ଗ - ଗାଡ଼ା (ନଦୀ)',
          pronunciation: 'Ag – Gada',
          meaning: 'Consonant ᱜ (Ag), as in ᱜᱟᱰᱟ (Gada: River)',
          meaning_en: 'Consonant ᱜ (Ag), as in ᱜᱟᱰᱟ (Gada: River)',
          meaning_bn: 'ব্যঞ্জনবর্ণ ᱜ (অগ্), যেমন ᱜᱟᱰᱟ (গাডা: নদী)',
          meaning_hi: 'व्यंजन ᱜ (अग), जैसे ᱜᱟᱰᱟ (गाडा: नदी)',
          meaning_or: 'ବ୍ୟଞ୍ଜନବର୍ଣ୍ଣ ᱜ (ଅଗ୍), ଯେପରି ᱜାଡ଼ା (ନଦୀ)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱝ - ᱥᱟᱝ',
        textLatin: 'ᱝ (Ang) – as in ᱥᱟᱝ (Sang: Companion / With)',
        speech: 'ᱝ, ᱥᱟᱝ',
        meta: {
          textBengali: 'ঙ - সাং (সঙ্গী)',
          textHindi: 'ङ - सांग (साथी)',
          textOdia: 'ଙ - ସାଙ୍ଗ୍ (ସାଥୀ)',
          pronunciation: 'Ang – Sang',
          meaning: 'Consonant ᱝ (Ang), as in ᱥᱟᱝ (Sang: Companion / With)',
          meaning_en: 'Consonant ᱝ (Ang), as in ᱥᱟᱝ (Sang: Companion / With)',
          meaning_bn: 'ব্যঞ্জনবর্ণ ᱝ (অঙ্), যেমন ᱥᱟᱝ (সাং: সঙ্গী)',
          meaning_hi: 'व्यंजन ᱝ (अंग), जैसे ᱥᱟᱝ (सांग: साथी)',
          meaning_or: 'ବ୍ୟଞ୍ଜନବର୍ଣ୍ଣ ᱝ (ଅଙ୍ଗ୍), ଯେପରି ସାଙ୍ଗ୍ (ସାଥୀ)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱞ - ᱞᱟᱸᱫᱟ',
        textLatin: 'ᱞ (Al) – as in ᱞᱟᱸᱫᱟ (Landa: Smile / Laugh)',
        speech: 'ᱞ, ᱞᱟᱸᱫᱟ',
        meta: {
          textBengali: 'ল - লাঁদা (হাসি)',
          textHindi: 'ल - लांदा (हंसी)',
          textOdia: 'ଲ - ଲାନ୍ଦା (ହସ)',
          pronunciation: 'Al – Landa',
          meaning: 'Consonant ᱞ (Al), as in ᱞᱟᱸᱫᱟ (Landa: Smile / Laugh)',
          meaning_en: 'Consonant ᱞ (Al), as in ᱞᱟᱸᱫᱟ (Landa: Smile / Laugh)',
          meaning_bn: 'ব্যঞ্জনবর্ণ ᱞ (অল্), যেমন ᱞᱟᱸᱫᱟ (লাঁদা: হাসি)',
          meaning_hi: 'व्यंजन ᱞ (अल), जैसे ᱞᱟᱸᱫᱟ (लांदा: हंसी)',
          meaning_or: 'ବ୍ୟଞ୍ଜନବର୍ଣ୍ଣ ᱞ (ଅଲ୍), ଯେପରି ଲାନ୍ଦା (ହସ)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱠ - ᱠᱟᱹᱢᱤ',
        textLatin: 'ᱠ (Aak) – as in ᱠᱟᱹᱢᱤ (Kami: Work / Deed)',
        speech: 'ᱠ, ᱠᱟᱹᱢᱤ',
        meta: {
          textBengali: 'ক - কামি (কাজ)',
          textHindi: 'क - कामि (काम)',
          textOdia: 'କ - କାମି (କାମ)',
          pronunciation: 'Aak – Kami',
          meaning: 'Consonant ᱠ (Aak), as in ᱠᱟᱹᱢᱤ (Kami: Work / Deed)',
          meaning_en: 'Consonant ᱠ (Aak), as in ᱠᱟᱹᱢᱤ (Kami: Work / Deed)',
          meaning_bn: 'ব্যঞ্জনবর্ণ ᱠ (আক্), যেমন ᱠᱟᱹᱢᱤ (কামি: কাজ)',
          meaning_hi: 'व्यंजन ᱠ (आक), जैसे ᱠᱟᱹᱢᱤ (कामि: काम)',
          meaning_or: 'ବ୍ୟଞ୍ଜନବର୍ଣ୍ଣ ᱠ (ଆକ୍), ଯେପରି କାମି (କାମ)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱡ - ᱡᱚ',
        textLatin: 'ᱡ (Aaj) – as in ᱡᱚ (Jo: Fruit)',
        speech: 'ᱡ, ᱡᱚ',
        meta: {
          textBengali: 'জ - জ (ফল)',
          textHindi: 'ज - जो (फल)',
          textOdia: 'ଜ - ଜୋ (ଫଳ)',
          pronunciation: 'Aaj – Jo',
          meaning: 'Consonant ᱡ (Aaj), as in ᱡᱚ (Jo: Fruit)',
          meaning_en: 'Consonant ᱡ (Aaj), as in ᱡᱚ (Jo: Fruit)',
          meaning_bn: 'ব্যঞ্জনবর্ণ ᱡ (আজ্), যেমন ᱡᱚ (জ: ফল)',
          meaning_hi: 'व्यंजन ᱡ (आज), जैसे ᱡᱚ (जो: फल)',
          meaning_or: 'ବ୍ୟଞ୍ଜନବର୍ଣ୍ଣ ᱡ (ଆଜ୍), ଯେପରି ଜୋ (ଫଳ)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱢ - ᱢᱟᱹᱱᱢᱤ',
        textLatin: 'ᱢ (Aam) – as in ᱢᱟᱹᱱᱢᱤ (Manmi: Human / Person)',
        speech: 'ᱢ, ᱢᱟᱹᱱᱢᱤ',
        meta: {
          textBengali: 'ম - মানমি (মানুষ)',
          textHindi: 'म - मानमि (इंसान / मनुष्य)',
          textOdia: 'ମ - ମାନମି (ମଣିଷ)',
          pronunciation: 'Aam – Manmi',
          meaning: 'Consonant ᱢ (Aam), as in ᱢᱟᱹᱱᱢᱤ (Manmi: Human / Person)',
          meaning_en: 'Consonant ᱢ (Aam), as in ᱢᱟᱹᱱᱢᱤ (Manmi: Human / Person)',
          meaning_bn: 'ব্যঞ্জনবর্ণ ᱢ (আম্), যেমন ᱢᱟᱹᱱᱢᱤ (মানমি: মানুষ)',
          meaning_hi: 'व्यंजन ᱢ (आम), जैसे ᱢᱟᱹᱱᱢᱤ (मानमि: इंसान)',
          meaning_or: 'ବ୍ୟଞ୍ଜନବର୍ଣ୍ଣ ᱢ (ଆମ୍), ଯେପରି ମାନମି (ମଣିଷ)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱣ - ᱫᱟᱣ',
        textLatin: 'ᱣ (Aaw) – as in ᱫᱟᱣ (Daw: Opportunity)',
        speech: 'ᱣ, ᱫᱟᱣ',
        meta: {
          textBengali: 'ওয় - দাও (সুযোগ)',
          textHindi: 'व - दाव (अवसर)',
          textOdia: 'ୱ - ଦାୱ (ସୁଯୋଗ)',
          pronunciation: 'Aaw – Daw',
          meaning: 'Consonant ᱣ (Aaw), as in ᱫᱟᱣ (Daw: Opportunity)',
          meaning_en: 'Consonant ᱣ (Aaw), as in ᱫᱟᱣ (Daw: Opportunity)',
          meaning_bn: 'ব্যঞ্জনবর্ণ ᱣ (আও), যেমন ᱫᱟᱣ (দাও: সুযোগ)',
          meaning_hi: 'व्यंजन ᱣ (आव), जैसे ᱫᱟᱣ (दाव: अवसर / मौका)',
          meaning_or: 'ବ୍ୟଞ୍ଜନବର୍ଣ୍ଣ ᱣ (ଆୱ), ଯେପରି ଦାୱ (ସୁଯୋଗ)',
        },
      },
    ],
  },
  {
    id: 'lesson_alphabet_2',
    titleLatin: 'Consonants: Group 2 (Palatal & Sibilant)',
    titleOlChiki: 'ᱠᱮᱪᱮᱫ ᱟᱲᱟᱝ II (ᱤ ᱟᱨ ᱩ ᱛᱷᱚᱠ)',
    blocks: [
      {
        type: 'text',
        textOlChiki: 'ᱥ - ᱥᱟᱹᱨᱤ',
        textLatin: 'ᱥ (Is) – as in ᱥᱟᱹᱨᱤ (Sari: Truth / Real)',
        speech: 'ᱥ, ᱥᱟᱹᱨᱤ',
        meta: {
          textBengali: 'স - সারি (সত্য)',
          textHindi: 'स - सारि (सत्य / सच)',
          textOdia: 'ସ - ସାରି (ସତ୍ୟ)',
          pronunciation: 'Is – Sari',
          meaning: 'Consonant ᱥ (Is), as in ᱥᱟᱹᱨᱤ (Sari: Truth / Real)',
          meaning_en: 'Consonant ᱥ (Is), as in ᱥᱟᱹᱨᱤ (Sari: Truth / Real)',
          meaning_bn: 'ব্যঞ্জনবর্ণ ᱥ (ইস্), যেমন ᱥᱟᱹᱨᱤ (সারি: সত্য)',
          meaning_hi: 'व्यंजन ᱥ (इस), जैसे ᱥᱟᱹᱨᱤ (सारि: सच)',
          meaning_or: 'ବ୍ୟଞ୍ଜନବର୍ଣ୍ଣ ᱥ (ଇସ୍), ଯେପରି ସାରି (ସତ୍ୟ)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱦ - ᱦᱚᱲ',
        textLatin: 'ᱦ (Ih) – as in ᱦᱚᱲ (Hor: Person / Santal)',
        speech: 'ᱦ, ᱦᱚᱲ',
        meta: {
          textBengali: 'হ - হড় (মানুষ)',
          textHindi: 'ह - होड़ (इंसान / संताल)',
          textOdia: 'ହ - ହୋଡ଼ (ମଣିଷ)',
          pronunciation: 'Ih – Hor',
          meaning: 'Consonant ᱦ (Ih), as in ᱦᱚᱲ (Hor: Person / Santal)',
          meaning_en: 'Consonant ᱦ (Ih), as in ᱦᱚᱲ (Hor: Person / Santal)',
          meaning_bn: 'ব্যঞ্জনবর্ণ ᱦ (ইহ্), যেমন ᱦᱚᱲ (হড়: মানুষ / সাঁওতাল)',
          meaning_hi: 'व्यंजन ᱦ (इह), जैसे ᱦᱚᱲ (होड़: इंसान / संताल)',
          meaning_or: 'ବ୍ୟଞ୍ଜନବର୍ଣ୍ଣ ᱦ (ଇହ୍), ଯେପରି ହୋଡ଼ (ମଣିଷ / ସାନ୍ତାଳ)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱧ - ᱧᱮᱞ',
        textLatin: 'ᱧ (Iny) – as in ᱧᱮᱞ (Nyel: To see / Look)',
        speech: 'ᱧ, ᱧᱮᱞ',
        meta: {
          textBengali: 'ঞ - ঞেল (দেখা)',
          textHindi: 'ञ - ञेल (देखना)',
          textOdia: 'ଞ - ଞେଲ୍ (ଦେଖିବା)',
          pronunciation: 'Iny – Nyel',
          meaning: 'Consonant ᱧ (Iny), as in ᱧᱮᱞ (Nyel: To see / Look)',
          meaning_en: 'Consonant ᱧ (Iny), as in ᱧᱮᱞ (Nyel: To see / Look)',
          meaning_bn: 'ব্যঞ্জনবর্ণ ᱧ (ইঞ্), যেমন ᱧᱮᱞ (ঞেল: দেখা)',
          meaning_hi: 'व्यंजन ᱧ (इञ), जैसे ᱧᱮᱞ (ञेल: देखना)',
          meaning_or: 'ବ୍ୟଞ୍ଜନବର୍ଣ୍ଣ ᱧ (ଇଞ୍), ଯେପରି ଞେଲ୍ (ଦେଖିବା)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱨ - ᱨᱚᱲ',
        textLatin: 'ᱨ (Ir) – as in ᱨᱚᱲ (Ror: To speak / Speech)',
        speech: 'ᱨ, ᱨᱚᱲ',
        meta: {
          textBengali: 'র - রড় (কথা বলা)',
          textHindi: 'र - रोड़ (बोलना)',
          textOdia: 'ର - ରୋଡ଼ (କଥା କହିବା)',
          pronunciation: 'Ir – Ror',
          meaning: 'Consonant ᱨ (Ir), as in ᱨᱚᱲ (Ror: To speak / Speech)',
          meaning_en: 'Consonant ᱨ (Ir), as in ᱨᱚᱲ (Ror: To speak / Speech)',
          meaning_bn: 'ব্যঞ্জনবর্ণ ᱨ (ইর্), যেমন ᱨᱚᱲ (রড়: কথা বলা)',
          meaning_hi: 'व्यंजन ᱨ (इर), जैसे ᱨᱚᱲ (रोड़: बोलना)',
          meaning_or: 'ବ୍ୟଞ୍ଜନବର୍ଣ୍ଣ ᱨ (ଇର୍), ଯେପରି ରୋଡ଼ (କଥା କହିବା)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱪ - ᱪᱮᱬᱮ',
        textLatin: 'ᱪ (Uch) – as in ᱪᱮᱬᱮ (Chene: Bird)',
        speech: 'ᱪ, ᱪᱮᱬᱮ',
        meta: {
          textBengali: 'চ - চেঁড়ে (পাখি)',
          textHindi: 'च - चेँड़े (चिड़िया)',
          textOdia: 'ଚ - ଚେଁଡ଼େ (ପକ୍ଷୀ)',
          pronunciation: 'Uch – Chene',
          meaning: 'Consonant ᱪ (Uch), as in ᱪᱮᱬᱮ (Chene: Bird)',
          meaning_en: 'Consonant ᱪ (Uch), as in ᱪᱮᱬᱮ (Chene: Bird)',
          meaning_bn: 'ব্যঞ্জনবর্ণ ᱪ (উচ্), যেমন ᱪᱮᱬᱮ (চেঁড়ে: পাখি)',
          meaning_hi: 'व्यंजन ᱪ (उच), जैसे ᱪᱮᱬᱮ (चेँड़े: चिड़िया / पक्षी)',
          meaning_or: 'ବ୍ୟଞ୍ଜନବର୍ଣ୍ଣ ᱪ (ଉଚ୍), ଯେପରି ଚେଁଡ଼େ (ପକ୍ଷୀ)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱫ - ᱫᱟᱜ',
        textLatin: 'ᱫ (Ud) – as in ᱫᱟᱜ (Dag: Water / Rain)',
        speech: 'ᱫ, ᱫᱟᱜ',
        meta: {
          textBengali: 'দ - দাগ (জল / বৃষ্টি)',
          textHindi: 'द - दाग (पानी / वर्षा)',
          textOdia: 'ଦ - ଦାଗ୍ (ପାଣି / ବର୍ଷା)',
          pronunciation: 'Ud – Dag',
          meaning: 'Consonant ᱫ (Ud), as in ᱫᱟᱜ (Dag: Water / Rain)',
          meaning_en: 'Consonant ᱫ (Ud), as in ᱫᱟᱜ (Dag: Water / Rain)',
          meaning_bn: 'ব্যঞ্জনবর্ণ ᱫ (উদ্), যেমন ᱫᱟᱜ (দাগ: জল / বৃষ্টি)',
          meaning_hi: 'व्यंजन ᱫ (उद), जैसे ᱫᱟᱜ (दाग: पानी / वर्षा)',
          meaning_or: 'ବ୍ୟଞ୍ଜନବର୍ଣ୍ଣ ᱫ (ଉଦ୍), ଯେପରି ଦାଗ୍ (ପାଣି / ବର୍ଷା)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱬ - ᱨᱬ',
        textLatin: 'ᱬ (Enn) – as in ᱨᱬ (Ran: Sound / Echo)',
        speech: 'ᱬ, ᱨᱬ',
        meta: {
          textBengali: 'ণ - রণ (ধ্বনি / প্রতিধ্বনি)',
          textHindi: 'ण - रण (ध्वनि / गूंज)',
          textOdia: 'ଣ - ରଣ (ଧ୍ୱନି)',
          pronunciation: 'Enn – Ran',
          meaning: 'Consonant ᱬ (Enn), as in ᱨᱬ (Ran: Sound / Echo)',
          meaning_en: 'Consonant ᱬ (Enn), as in ᱨᱬ (Ran: Sound / Echo)',
          meaning_bn: 'ব্যঞ্জনবর্ণ ᱬ (উণ্), যেমন ᱨᱬ (রণ: ধ্বনি)',
          meaning_hi: 'व्यंजन ᱬ (उण), जैसे ᱨᱬ (रण: ध्वनि)',
          meaning_or: 'ବ୍ୟଞ୍ଜନବର୍ଣ୍ଣ ᱬ (ଉଣ୍), ଯେପରି ରଣ (ଧ୍ୱନି)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱭ - ᱠᱚᱭ',
        textLatin: 'ᱭ (Uy) – as in ᱠᱚᱭ (Koy: To ask / Request)',
        speech: 'ᱭ, ᱠᱚᱭ',
        meta: {
          textBengali: 'য় - কয় (চাওয়া / প্রার্থনা)',
          textHindi: 'य - कोय (मांगना)',
          textOdia: 'ୟ - କୟ (ମାଗିବା)',
          pronunciation: 'Uy – Koy',
          meaning: 'Consonant ᱭ (Uy), as in ᱠᱚᱭ (Koy: To ask / Request)',
          meaning_en: 'Consonant ᱭ (Uy), as in ᱠᱚᱭ (Koy: To ask / Request)',
          meaning_bn: 'ব্যঞ্জনবর্ণ ᱭ (উয়্), যেমন ᱠᱚᱭ (কয়: চাওয়া / প্রার্থনা)',
          meaning_hi: 'व्यंजन ᱭ (उय), जैसे ᱠᱚᱭ (कोय: मांगना)',
          meaning_or: 'ବ୍ୟଞ୍ଜନବର୍ଣ୍ଣ ୟ (ଉୟ୍), ଯେପରି କୟ (ମାଗିବା)',
        },
      },
    ],
  },
  {
    id: 'lesson_alphabet_3',
    titleLatin: 'Consonants: Group 3 (Labial & Retroflex)',
    titleOlChiki: 'ᱠᱮᱪᱮᱫ ᱟᱲᱟᱝ III (ᱮ ᱟᱨ ᱳ ᱛᱷᱚᱠ)',
    blocks: [
      {
        type: 'text',
        textOlChiki: 'ᱯ - ᱯᱚᱨᱚᱵ',
        textLatin: 'ᱯ (Ep) – as in ᱯᱚᱨᱚᱵ (Porob: Festival)',
        speech: 'ᱯ, ᱯᱚᱨᱚᱵ',
        meta: {
          textBengali: 'প - পরব (উৎসব)',
          textHindi: 'प - पोरोब (त्योहार)',
          textOdia: 'ପ - ପୋରୋବ୍ (ପର୍ବ)',
          pronunciation: 'Ep – Porob',
          meaning: 'Consonant ᱯ (Ep), as in ᱯᱚᱨᱚᱵ (Porob: Festival)',
          meaning_en: 'Consonant ᱯ (Ep), as in ᱯᱚᱨᱚᱵ (Porob: Festival)',
          meaning_bn: 'ব্যঞ্জনবর্ণ ᱯ (এপ্), যেমন ᱯᱚᱨᱚᱵ (পরব: উৎসব)',
          meaning_hi: 'व्यंजन ᱯ (एप), जैसे ᱯᱚᱨᱚᱵ (पोरोब: त्योहार)',
          meaning_or: 'ବ୍ୟଞ୍ଜନବର୍ଣ୍ଣ ᱯ (ଏପ୍), ଯେପରି ପୋରୋବ୍ (ପର୍ବ)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱰ - ᱰᱟᱦᱟᱨ',
        textLatin: 'ᱰ (Edd) – as in ᱰᱟᱦᱟᱨ (Dahar: Way / Path)',
        speech: 'ᱰ, ᱰᱟᱦᱟᱨ',
        meta: {
          textBengali: 'ড - ডাহার (রাস্তা / পথ)',
          textHindi: 'ड - डाहार (रास्ता / मार्ग)',
          textOdia: 'ଡ - ଡାହାର (ରାସ୍ତା)',
          pronunciation: 'Edd – Dahar',
          meaning: 'Consonant ᱰ (Edd), as in ᱰᱟᱦᱟᱨ (Dahar: Way / Path)',
          meaning_en: 'Consonant ᱰ (Edd), as in ᱰᱟᱦᱟᱨ (Dahar: Way / Path)',
          meaning_bn: 'ব্যঞ্জনবর্ণ ᱰ (এড্), যেমন ᱰᱟᱦᱟᱨ (ডাহার: রাস্তা)',
          meaning_hi: 'व्यंजन ᱰ (एड), जैसे ᱰᱟᱦᱟᱨ (डाहार: रास्ता)',
          meaning_or: 'ବ୍ୟଞ୍ଜନବର୍ଣ୍ଣ ଡ (ଏଡ୍), ଯେପରି ଡାହାର (ରାସ୍ତା)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱱ - ᱱᱟᱯᱟᱭ',
        textLatin: 'ᱱ (En) – as in ᱱᱟᱯᱟᱭ (Napay: Good / Fine)',
        speech: 'ᱱ, ᱱᱟᱯᱟᱭ',
        meta: {
          textBengali: 'ন - নাপায় (ভালো / সুন্দর)',
          textHindi: 'न - नापाय (अच्छा / सुंदर)',
          textOdia: 'ନ - ନାପାୟ (ଭଲ / ସୁନ୍ଦର)',
          pronunciation: 'En – Napay',
          meaning: 'Consonant ᱱ (En), as in ᱱᱟᱯᱟᱭ (Napay: Good / Fine)',
          meaning_en: 'Consonant ᱱ (En), as in ᱱᱟᱯᱟᱭ (Napay: Good / Fine)',
          meaning_bn: 'ব্যঞ্জনবর্ণ ᱱ (এন্), যেমন ᱱᱟᱯᱟᱭ (নাপায়: ভালো)',
          meaning_hi: 'व्यंजन ᱱ (एन), जैसे ᱱᱟᱯᱟᱭ (नापाय: अच्छा)',
          meaning_or: 'ବ୍ୟଞ୍ଜନବର୍ଣ୍ଣ ନ (ଏନ୍), ଯେପରି ନାପାୟ (ଭଲ)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱲ - ᱫᱟᱲᱮ',
        textLatin: 'ᱲ (Err) – as in ᱫᱟᱲᱮ (Dare: Strength / Power)',
        speech: 'ᱲ, ᱫᱟᱲᱮ',
        meta: {
          textBengali: 'ড় - দাড়ে (শক্তি / বল)',
          textHindi: 'ड़ - दाड़े (शक्ति / ताकत)',
          textOdia: 'ଡ଼ - ଦାଡ଼େ (ଶକ୍ତି)',
          pronunciation: 'Err – Dare',
          meaning: 'Consonant ᱲ (Err), as in ᱫᱟᱲᱮ (Dare: Strength / Power)',
          meaning_en: 'Consonant ᱲ (Err), as in ᱫᱟᱲᱮ (Dare: Strength / Power)',
          meaning_bn: 'ব্যঞ্জনবর্ণ ᱲ (এড়্), যেমন ᱫᱟᱲᱮ (দাড়ো: শক্তি)',
          meaning_hi: 'व्यंजन ᱲ (एड़), जैसे ᱫᱟᱲᱮ (दाड़े: शक्ति)',
          meaning_or: 'ବ୍ୟଞ୍ଜନବର୍ଣ୍ଣ ଡ଼ (ଏଡ଼୍), ଯେପରି ଦାଡ଼େ (ଶକ୍ତି)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱴ - ᱴᱟᱠᱟ',
        textLatin: 'ᱴ (Ott) – as in ᱴᱟᱠᱟ (Taka: Money / Rupee)',
        speech: 'ᱴ, ᱴᱟᱠᱟ',
        meta: {
          textBengali: 'ট - টাকা (টাকা / মুদ্রা)',
          textHindi: 'ट - टाका (पैसा / रुपया)',
          textOdia: 'ଟ - ଟାକା (ଟଙ୍କା)',
          pronunciation: 'Ott – Taka',
          meaning: 'Consonant ᱴ (Ott), as in ᱴᱟᱠᱟ (Taka: Money / Rupee)',
          meaning_en: 'Consonant ᱴ (Ott), as in ᱴᱟᱠᱟ (Taka: Money / Rupee)',
          meaning_bn: 'ব্যঞ্জনবর্ণ ᱴ (অট্), যেমন ᱴᱟᱠᱟ (টাকা: টাকা)',
          meaning_hi: 'व्यंजन ᱴ (ओट), जैसे ᱴᱟᱠᱟ (टाका: पैसा / रुपया)',
          meaning_or: 'ବ୍ୟଞ୍ଜନବର୍ଣ୍ଣ ଟ (ଅଟ୍), ଯେପରି ଟାକା (ଟଙ୍କା)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱵ - ᱵᱟᱦᱟ',
        textLatin: 'ᱵ (Ob) – as in ᱵᱟᱦᱟ (Baha: Flower)',
        speech: 'ᱵ, ᱵᱟᱦᱟ',
        meta: {
          textBengali: 'ব - বাহা (ফুল)',
          textHindi: 'ब - बाहा (फूल)',
          textOdia: 'ବ - ବାହା (ଫୁଲ)',
          pronunciation: 'Ob – Baha',
          meaning: 'Consonant ᱵ (Ob), as in ᱵᱟᱦᱟ (Baha: Flower)',
          meaning_en: 'Consonant ᱵ (Ob), as in ᱵᱟᱦᱟ (Baha: Flower)',
          meaning_bn: 'ব্যঞ্জনবর্ণ ᱵ (অব্), যেমন ᱵᱟᱦᱟ (বাহা: ফুল)',
          meaning_hi: 'व्यंजन ᱵ (ओब), जैसे ᱵᱟᱦᱟ (बाहा: फूल)',
          meaning_or: 'ବ୍ୟଞ୍ଜନବର୍ଣ୍ଣ ବ (ଅବ୍), ଯେପରି ବାହା (ଫୁଲ)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱶ - ᱥᱟᱶ',
        textLatin: 'ᱶ (Ov) – as in ᱥᱟᱶ (Saw: Together / With)',
        speech: 'ᱶ, ᱥᱟᱶ',
        meta: {
          textBengali: 'ওঁ - সাঁও (সাথে / সঙ্গে)',
          textHindi: 'व् - सांव (साथ / संग)',
          textOdia: 'ୱ - ସାୱ (ସାଥିରେ)',
          pronunciation: 'Ov – Saw',
          meaning: 'Consonant ᱶ (Ov), as in ᱥᱟᱶ (Saw: Together / With)',
          meaning_en: 'Consonant ᱶ (Ov), as in ᱥᱟᱶ (Saw: Together / With)',
          meaning_bn: 'ব্যঞ্জনবর্ণ ᱶ (ওঁভ), যেমন ᱥᱟᱶ (সাঁও: সঙ্গে / সাথে)',
          meaning_hi: 'व्यंजन ᱶ (ओव), जैसे ᱥᱟᱶ (सांव: साथ)',
          meaning_or: 'ବ୍ୟଞ୍ଜନବର୍ଣ୍ଣ ୱ (ଓୱ୍), ଯେପରି ସାୱ (ସାଥିରେ)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱷ - ᱯᱷᱟᱹᱜᱩᱱ',
        textLatin: 'ᱷ (Oh) – as in ᱯᱷᱟᱹᱜᱩᱱ (Phagun: Spring Month)',
        speech: 'ᱷ, ᱯᱷᱟᱹᱜᱩᱱ',
        meta: {
          textBengali: 'হ - ফাগুন (ফাল্গুন মাস)',
          textHindi: 'ह - फागुन (फाल्गुन मास)',
          textOdia: 'ହ - ଫାଗୁନ (ଫାଲ୍ଗୁନ ମାସ)',
          pronunciation: 'Oh – Phagun',
          meaning: 'Consonant ᱷ (Oh), as in ᱯᱷᱟᱹᱜᱩᱱ (Phagun: Spring Month)',
          meaning_en: 'Consonant ᱷ (Oh), as in ᱯᱷᱟᱹᱜᱩᱱ (Phagun: Spring Month)',
          meaning_bn: 'ব্যঞ্জনবর্ণ ᱷ (অহ্), যেমন ᱯᱷᱟᱹᱜᱩᱱ (ফাগুন: বসন্তকাল / ফাল্গুন)',
          meaning_hi: 'व्यंजन ᱷ (ओह), जैसे ᱯᱷᱟᱹᱜᱩᱱ (फागुन: वसंत मास)',
          meaning_or: 'ବ୍ୟଞ୍ଜନବର୍ଣ୍ଣ ହ (ଅହ୍), ଯେପରି ଫାଗୁନ (ଫାଲ୍ଗୁନ ମାସ)',
        },
      },
    ],
  },
  {
    id: 'lesson_alphabet_4',
    titleLatin: 'Modifiers & Signs (Japag Arang)',
    titleOlChiki: 'ᱡᱟᱯᱟᱜ ᱟᱲᱟᱝ ᱟᱨ ᱪᱤᱱᱦᱟᱹ',
    blocks: [
      {
        type: 'text',
        textOlChiki: 'ᱹ - ᱜᱟᱹᱦᱞᱟᱹ ᱴᱩᱰᱟᱹᱜ',
        textLatin: 'ᱹ (Gahla Tudag) – Baseline dot that deepens/opens vowel, as in ᱟᱹᱛᱩ (Atu: Village)',
        speech: 'ᱜᱟᱹᱦᱞᱟᱹ ᱴᱩᱰᱟᱹᱜ, ᱟᱹᱛᱩ',
        meta: {
          textBengali: 'গাহলা টুডাগ (নিচের বিন্দু) – স্বর গভীর করে, যেমন ᱟᱹᱛᱩ (গ্রাম)',
          textHindi: 'गाहला टुडाग (निचला बिंदु) – स्वर को गहरा करता है, जैसे ᱟᱹᱛᱩ (गाँव)',
          textOdia: 'ଗାହଲା ଟୁଡାଗ (ତଳ ବିନ୍ଦୁ) – ସ୍ୱରକୁ ଗଭୀର କରେ, ଯେପରି ᱟᱹᱛᱩ (ଗାଁ)',
          pronunciation: 'Gahla Tudag – Atu',
          meaning: 'Baseline dot modifying vowel into deep/open variant (e.g. ᱟ -> ᱟᱹ as in ᱟᱹᱛᱩ)',
          meaning_en: 'Baseline dot modifying vowel into deep/open variant (e.g. ᱟ -> ᱟᱹ as in ᱟᱹᱛᱩ)',
          meaning_bn: 'গাহলা টুডাগ (নিচের বিন্দু) – স্বর গভীর করে, যেমন ᱟᱹᱛᱩ (গ্রাম)',
          meaning_hi: 'गाहला टुडाग – स्वर को गहरा बनाता है, जैसे ᱟᱹᱛᱩ (गाँव)',
          meaning_or: 'ଗାହଲା ଟୁଡାଗ – ସ୍ୱରକୁ ଗଭୀର କରେ, ଯେପରି ᱟᱹᱛᱩ (ଗାଁ)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱸ - ᱢᱩ ᱴᱩᱰᱟᱹᱜ',
        textLatin: 'ᱸ (Mu Tudag) – Top dot for nasalization, as in ᱦᱮᱸ (Hẽ: Yes)',
        speech: 'ᱢᱩ ᱴᱩᱰᱟᱹᱜ, ᱦᱮᱸ',
        meta: {
          textBengali: 'মু টুডাগ (নাসিক্য বিন্দু) – স্বর অনুনাসিক করে, যেমন ᱦᱮᱸ (হ্যাঁ)',
          textHindi: 'मु टुडाग (नासिक बिंदु) – अनुनासिक ध्वनि बनाता है, जैसे ᱦᱮᱸ (हाँ)',
          textOdia: 'ମୁ ଟୁଡାଗ (ନାସିକ୍ୟ ବିନ୍ଦୁ) – ନାସିକ୍ୟ ଧ୍ୱନି କରେ, ଯେପରି ᱦᱮᱸ (ହଁ)',
          pronunciation: 'Mu Tudag – Hẽ',
          meaning: 'Top dot adding nasalization to vowel (e.g. ᱦᱮᱸ: Yes)',
          meaning_en: 'Top dot adding nasalization to vowel (e.g. ᱦᱮᱸ: Yes)',
          meaning_bn: 'মু টুডাগ (উপরের বিন্দু) – অনুনাসিক ধ্বনি তৈরি করে, যেমন ᱦᱮᱸ (হ্যাঁ)',
          meaning_hi: 'मु टुडाग – स्वर को अनुनासिक करता है, जैसे ᱦᱮᱸ (हाँ)',
          meaning_or: 'ମୁ ଟୁଡାଗ – ନାସିକ୍ୟ ଧ୍ୱନି କରେ, ଯେପରି ᱦେᱸ (ହଁ)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱺ - ᱢᱩ-ᱜᱟᱹᱦᱞᱟᱹ ᱴᱩᱰᱟᱹᱜ',
        textLatin: 'ᱺ (Mu-Gahla Tudag) – Double dot for deep nasalized vowel, as in ᱥᱟᱺᱜᱤᱧ (Sanginj: Far)',
        speech: 'ᱢᱩ-ᱜᱟᱹᱦᱞᱟᱹ ᱴᱩᱰᱟᱹᱜ, ᱥᱟᱺᱜᱤᱧ',
        meta: {
          textBengali: 'মু-গাহলা টুডাগ – গভীর ও অনুনাসিক স্বর, যেমন ᱥᱟᱺᱜᱤᱧ (দূর)',
          textHindi: 'मु-गाहला टुडाग – गहरा और अनुनासिक स्वर, जैसे ᱥᱟᱺᱜᱤᱧ (दूर)',
          textOdia: 'ମୁ-ଗାହଲା ଟୁଡାଗ – ଗଭୀର ଓ ନାସିକ୍ୟ ସ୍ୱର, ଯେପରି ᱥᱟᱺଗିᱧ (ଦୂର)',
          pronunciation: 'Mu-Gahla Tudag – Sanginj',
          meaning: 'Colon-like double dot combining deepening and nasalization together',
          meaning_en: 'Colon-like double dot combining deepening and nasalization together',
          meaning_bn: 'মু-গাহলা টুডাগ – গভীর ও অনুনাসিক যুগল ধ্বনি, যেমন ᱥᱟᱺᱜᱤᱧ (দূর)',
          meaning_hi: 'मु-गाहला टुडाग – गहरा और अनुनासिक का संयुक्त रूप, जैसे ᱥᱟᱺᱜᱤᱧ (दूर)',
          meaning_or: 'ମୁ-ଗାହଲା ଟୁଡାଗ – ଗଭୀର ଓ ନାସିକ୍ୟର ସଂଯୁକ୍ତ ରୂପ',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱽ - ᱚᱦᱚᱫ',
        textLatin: 'ᱽ (Ohod) – Deglottalizer mark releasing checked stops, as in ᱢᱟᱹᱡᱷᱤ (Majhi: Headman)',
        speech: 'ᱚᱦᱚᱫ, ᱢᱟᱹᱡᱷᱤ',
        meta: {
          textBengali: 'অহদ – অবরুদ্ধ ধ্বনি মুক্ত করে, যেমন ᱢᱟᱹᱡᱷᱤ (গ্রামপ্রধান)',
          textHindi: 'ओहद – रुके हुए व्यंजन को मुक्त करता है, जैसे ᱢᱟᱹᱡᱷᱤ (मुखिया)',
          textOdia: 'ଓହଦ୍ – ସ୍ୱର ପ୍ରବାହ ମୁକ୍ତ କରେ, ଯେପରି ᱢᱟᱹᱡᱷᱤ (ଗ୍ରାମ ମୁଖ୍ୟ)',
          pronunciation: 'Ohod – Majhi',
          meaning: 'Deglottalizer releasing checked consonants ᱜ, ᱡ, ᱫ, ᱵ into continuous sounds',
          meaning_en: 'Deglottalizer releasing checked consonants ᱜ, ᱡ, ᱫ, ᱵ into continuous sounds',
          meaning_bn: 'অহদ – অবরুদ্ধ ব্যঞ্জনধ্বনিকে পূর্ণ কণ্ঠে প্রকাশ করে, যেমন ᱢᱟᱹᱡᱷᱤ (গ্রামপ্রধান)',
          meaning_hi: 'ओहद – रुके हुए व्यंजन को मुक्त करता है, जैसे ᱢᱟᱹᱡᱷᱤ (ग्राम प्रधान)',
          meaning_or: 'ଓହଦ୍ – ସ୍ୱର ପ୍ରବାହ ମୁକ୍ତ କରେ, ଯେପରି ᱢᱟᱹᱡᱷᱤ (ଗ୍ରାମ ମୁଖ୍ୟ)',
        },
      },
      {
        type: 'text',
        textOlChiki: 'ᱻ - ᱟᱦᱚᱫ',
        textLatin: 'ᱻ (Ahd) – Lengthens preceding vowel for melodic or poetic emphasis',
        speech: 'ᱟᱦᱚᱫ, ᱥᱮᱨᱮᱧ ᱨᱮ ᱨᱟᱦᱟ ᱡᱤᱞᱤᱧ',
        meta: {
          textBengali: 'আহদ – স্বরধ্বনি দীর্ঘায়িত করার চিহ্ন',
          textHindi: 'आहद – स्वर को लंबा खींचने का चिह्न',
          textOdia: 'ଆହଦ୍ – ସ୍ୱରକୁ ଲମ୍ବା କରିବାର ଚିହ୍ନ',
          pronunciation: 'Ahd',
          meaning: 'Vowel lengthener used for elongation in songs and chants',
          meaning_en: 'Vowel lengthener used for elongation in songs and chants',
          meaning_bn: 'আহদ – স্বরধ্বনি দীর্ঘায়িত করার চিহ্ন',
          meaning_hi: 'आहद – स्वर को दीर्घ करने का चिह्न',
          meaning_or: 'ଆହଦ୍ – ସ୍ୱରକୁ ଦୀର୍ଘ କରିବାର ଚିହ୍ନ',
        },
      },
      {
        type: 'text',
        textOlChiki: '᱾ - ᱢᱩᱪᱟᱹᱫ',
        textLatin: '᱾ (Mucaad) – Full stop punctuation mark, as in ᱤᱧ ᱚᱞᱚᱜ ᱠᱟᱱᱟᱹᱧ᱾ (I am reading.)',
        speech: 'ᱢᱩᱪᱟᱹᱫ, ᱤᱧ ᱚᱞᱚᱜ ᱠᱟᱱᱟᱹᱧ᱾',
        meta: {
          textBengali: 'মুচাদ – পূর্ণচ্ছেদ (দাঁড়ি), যেমন ᱤᱧ ᱚᱞᱚᱜ ᱠᱟᱱᱟᱹᱧ᱾ (আমি পড়ছি।)',
          textHindi: 'मुचाद – पूर्ण विराम (खड़ी पाई), जैसे ᱤᱧ ᱚᱞᱚᱜ ᱠᱟᱱᱟᱹᱧ᱾ (मैं पढ़ रहा हूँ।)',
          textOdia: 'ମୁଚାଦ୍ – ପୂର୍ଣ୍ଣଚ୍ଛେଦ, ଯେପରି ᱤᱧ ᱚᱞᱚᱜ ᱠᱟᱱᱟᱹᱧ᱾ (ମୁଁ ପଢ଼ୁଛି।)',
          pronunciation: 'Mucaad',
          meaning: 'Sentence terminal punctuation mark (full stop)',
          meaning_en: 'Sentence terminal punctuation mark (full stop)',
          meaning_bn: 'মুচাদ – পূর্ণচ্ছেদ (দাঁড়ি / ফুলস্টপ)',
          meaning_hi: 'मुचाद – पूर्ण विराम (खड़ी पाई)',
          meaning_or: 'ମୁଚାଦ୍ – ପୂର୍ଣ୍ଣଚ୍ଛେଦ',
        },
      },
    ],
  },
];

async function main() {
  console.log('═══════════════════════════════════════════════════════════════════════');
  console.log('  Ol Chiki Alphabet Overhaul & Audio Synthesizer (Bodhan AI - 8 Keys)');
  console.log('═══════════════════════════════════════════════════════════════════════');
  console.log(`Endpoint:    ${ENDPOINT}`);
  console.log(`Project:     ${PROJECT_ID}`);
  console.log(`Model:       ${MODEL}`);
  console.log(`Voice:       ${VOICE} (Santali)`);
  console.log(`Dry Run:     ${DRY_RUN ? 'YES' : 'NO'}`);

  const keys = loadBodhanKeys();
  console.log(`Loaded ${keys.length} Bodhan keys: ${keys.map((k) => k.id).join(', ')}\n`);
  const rotator = new BodhanRotator(keys);

  // 1. UPDATE AND REGENERATE ALL 30 LETTERS
  console.log('🔤 [Part 1] Processing 30 Letters in "letters" collection...');
  for (let i = 0; i < CANONICAL_LETTERS.length; i++) {
    const ltr = CANONICAL_LETTERS[i];
    const fileId = `ltr_${i}`;
    process.stdout.write(`  [Letter ${i + 1}/30] ${ltr.id} (${ltr.char} - ${ltr.name}) `);

    try {
      if (DRY_RUN) {
        console.log(`-> 🔍 dry run for ${fileId}`);
        continue;
      }

      // Synthesize letter sound + example word
      const { buffer, keyId } = await rotator.synthesize(ltr.speech);
      process.stdout.write(`-> TTS OK (${buffer.length}b, ${keyId}) `);

      const uploadedUrl = await uploadAudioFile(fileId, buffer);
      process.stdout.write(`-> Uploaded `);

      const glyphBlock = [
        {
          id: 'glyph_block',
          order: 0,
          type: 'glyph',
          olChiki: ltr.char,
          latin: ltr.name,
          audioUrl: uploadedUrl,
        },
      ];

      await patchDocument('letters', ltr.id, {
        charOlChiki: ltr.char,
        transliterationLatin: ltr.name,
        exampleWord: `${ltr.wordLatin} (${ltr.wordMeaning})`,
        exampleWordOlChiki: ltr.wordOlChiki,
        exampleWordLatin: ltr.wordLatin,
        audioUrl: uploadedUrl,
        blocks: JSON.stringify(glyphBlock),
        order: i,
        orderIndex: i,
      });
      process.stdout.write(`-> Patched DB ✅\n`);
    } catch (err) {
      console.log(`-> ❌ FAILED: ${err.message}`);
    }

    if (DELAY_MS > 0) await new Promise((r) => setTimeout(r, DELAY_MS));
  }

  // 2. UPDATE AND REGENERATE ALL 5 ALPHABET LESSONS
  console.log('\n📚 [Part 2] Processing 5 Alphabet Lessons in "lessons" collection...');
  for (let lIdx = 0; lIdx < ALPHABET_LESSONS.length; lIdx++) {
    const lesson = ALPHABET_LESSONS[lIdx];
    console.log(`\n  Lesson ${lIdx + 1}/5: ${lesson.id} (${lesson.titleLatin}) - ${lesson.blocks.length} blocks:`);

    const blocksToSave = [];
    for (let bIdx = 0; bIdx < lesson.blocks.length; bIdx++) {
      const blockDef = lesson.blocks[bIdx];
      const fileId = `snd_alphabet_${lIdx}_${bIdx}`;
      process.stdout.write(`    [Block ${bIdx + 1}/${lesson.blocks.length}] ${fileId} ("${blockDef.textOlChiki}") `);

      try {
        if (DRY_RUN) {
          console.log(`-> 🔍 dry run for ${fileId}`);
          blocksToSave.push({
            id: `blk_${bIdx}`,
            order: bIdx,
            type: blockDef.type,
            markdown: blockDef.textLatin,
            textOlChiki: blockDef.textOlChiki,
            textLatin: blockDef.textLatin,
            audioUrl: '',
            meta: blockDef.meta,
          });
          continue;
        }

        const { buffer, keyId } = await rotator.synthesize(blockDef.speech || blockDef.textOlChiki);
        process.stdout.write(`-> TTS OK (${buffer.length}b, ${keyId}) `);

        const uploadedUrl = await uploadAudioFile(fileId, buffer);
        process.stdout.write(`-> Uploaded ✅\n`);

        const blockMeta = {
          ...blockDef.meta,
          audioUrl: uploadedUrl,
        };

        blocksToSave.push({
          id: `blk_${bIdx}`,
          order: bIdx,
          type: blockDef.type,
          markdown: blockDef.textLatin,
          textOlChiki: blockDef.textOlChiki,
          textLatin: blockDef.textLatin,
          audioUrl: uploadedUrl,
          meta: blockMeta,
        });
      } catch (err) {
        console.log(`-> ❌ FAILED: ${err.message}`);
      }

      if (DELAY_MS > 0) await new Promise((r) => setTimeout(r, DELAY_MS));
    }

    if (!DRY_RUN) {
      await patchDocument('lessons', lesson.id, {
        titleLatin: lesson.titleLatin,
        titleOlChiki: lesson.titleOlChiki,
        order: lIdx,
        blocks: JSON.stringify(blocksToSave),
      });
      console.log(`    📝 Successfully updated ${lesson.id} in database.`);
    }
  }

  console.log('\n═══════════════════════════════════════════════════════════════════════');
  console.log('🎉 ALPHABET LESSONS & LETTERS OVERHAUL COMPLETED SUCCESSFULLY!');
  console.log('═══════════════════════════════════════════════════════════════════════\n');
}

main().catch((err) => {
  console.error('\nFatal Error in alphabet overhaul script:', err);
  process.exit(1);
});
