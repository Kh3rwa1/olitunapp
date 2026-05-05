#!/usr/bin/env node

/**
 * Olitun Seed Data Import
 * Imports seed data (from seed_data.sql + schema.sql) into Appwrite collections.
 *
 * Usage:
 *   APPWRITE_API_KEY=your_key node scripts/appwrite_seed.mjs
 */

import { readFileSync } from 'fs';

function readProjectIdFromConfig() {
  try {
    const raw = readFileSync(new URL('../appwrite.config.json', import.meta.url), 'utf8');
    return JSON.parse(raw).projectId || '';
  } catch (_) {
    return '';
  }
}

const ENDPOINT = process.env.APPWRITE_ENDPOINT || 'https://sgp.cloud.appwrite.io/v1';
const PROJECT_ID = process.env.APPWRITE_PROJECT_ID || readProjectIdFromConfig();
const API_KEY = process.env.APPWRITE_API_KEY;
const DB = 'olitun_db';

if (!PROJECT_ID) {
  console.error('❌ Set APPWRITE_PROJECT_ID or appwrite.config.json projectId');
  process.exit(1);
}

if (!API_KEY) {
  console.error('❌ Set APPWRITE_API_KEY environment variable');
  process.exit(1);
}

const headers = {
  'Content-Type': 'application/json',
  'X-Appwrite-Project': PROJECT_ID,
  'X-Appwrite-Key': API_KEY,
};

async function createDoc(collection, docId, data) {
  const url = `${ENDPOINT}/databases/${DB}/collections/${collection}/documents`;
  const res = await fetch(url, {
    method: 'POST',
    headers,
    body: JSON.stringify({ documentId: docId, data }),
  });
  if (res.status === 409) return 'skip';
  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`${collection}/${docId}: ${res.status} - ${txt}`);
  }
  return 'ok';
}

async function importCollection(name, rows) {
  console.log(`\n📋 ${name} (${rows.length} docs)`);
  let ok = 0, skip = 0, fail = 0;

  for (const { id, ...data } of rows) {
    try {
      const result = await createDoc(name, id, data);
      if (result === 'skip') { skip++; process.stdout.write('⏭'); }
      else { ok++; process.stdout.write('✅'); }
    } catch (e) {
      fail++;
      process.stdout.write('❌');
      console.error(`\n   ${e.message}`);
    }
  }
  console.log(`  → ${ok} added, ${skip} skipped, ${fail} failed`);
}

// ─── SEED DATA ───

const categories = [
  { id: 'cat_alphabet', titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ ᱟᱠᱷᱟ', titleLatin: 'Alphabet', iconName: 'alphabet', gradientPreset: 'skyBlue', order: 0, isActive: true, totalLessons: 30, description: 'Learn the Ol Chiki script letters' },
  { id: 'cat_numbers', titleOlChiki: 'ᱮᱞᱠᱷᱟ ᱠᱚ', titleLatin: 'Numbers', iconName: 'numbers', gradientPreset: 'sunset', order: 1, isActive: true, totalLessons: 10, description: 'Learn Santali numbers and counting' },
  { id: 'cat_words', titleOlChiki: 'ᱨᱚᱲ ᱠᱚ', titleLatin: 'Words', iconName: 'words', gradientPreset: 'forest', order: 2, isActive: true, totalLessons: 50, description: 'Build your Santali vocabulary' },
  { id: 'cat_sentences', titleOlChiki: 'ᱣᱟᱠᱭ ᱠᱚ', titleLatin: 'Sentences', iconName: 'stories', gradientPreset: 'ocean', order: 3, isActive: true, totalLessons: 20, description: 'Form sentences in Santali' },
];

const letters = [
  { id: 'l_la', charOlChiki: 'ᱚ', transliterationLatin: 'La (a)', order: 0, isActive: true, exampleWord: 'Ol' },
  { id: 'l_at', charOlChiki: 'ᱛ', transliterationLatin: 'At (t)', order: 1, isActive: true, exampleWord: 'At' },
  { id: 'l_ag', charOlChiki: 'ᱜ', transliterationLatin: 'Ag (g)', order: 2, isActive: true, exampleWord: 'Ag' },
  { id: 'l_ang', charOlChiki: 'ᱝ', transliterationLatin: 'Ang (ng)', order: 3, isActive: true, exampleWord: 'Ang' },
  { id: 'l_al', charOlChiki: 'ᱞ', transliterationLatin: 'Al (l)', order: 4, isActive: true, exampleWord: 'Al' },
  { id: 'l_laa', charOlChiki: 'ᱟ', transliterationLatin: 'Laa (aa)', order: 5, isActive: true, exampleWord: 'Aa' },
  { id: 'l_ak', charOlChiki: 'ᱠ', transliterationLatin: 'Ak (k)', order: 6, isActive: true, exampleWord: 'Ka' },
  { id: 'l_aj', charOlChiki: 'ᱡ', transliterationLatin: 'Aj (j)', order: 7, isActive: true, exampleWord: 'Ja' },
  { id: 'l_am', charOlChiki: 'ᱢ', transliterationLatin: 'Am (m)', order: 8, isActive: true, exampleWord: 'Ma' },
  { id: 'l_aw', charOlChiki: 'ᱣ', transliterationLatin: 'Aw (w)', order: 9, isActive: true, exampleWord: 'Wa' },
  { id: 'l_li', charOlChiki: 'ᱤ', transliterationLatin: 'Li (i)', order: 10, isActive: true, exampleWord: 'Ir' },
  { id: 'l_is', charOlChiki: 'ᱥ', transliterationLatin: 'Is (s)', order: 11, isActive: true, exampleWord: 'Si' },
  { id: 'l_ih', charOlChiki: 'ᱦ', transliterationLatin: 'Ih (h)', order: 12, isActive: true, exampleWord: 'Ha' },
  { id: 'l_iny', charOlChiki: 'ᱧ', transliterationLatin: 'Iny (ny)', order: 13, isActive: true, exampleWord: 'Ny' },
  { id: 'l_ir', charOlChiki: 'ᱨ', transliterationLatin: 'Ir (r)', order: 14, isActive: true, exampleWord: 'Ra' },
  { id: 'l_lu', charOlChiki: 'ᱩ', transliterationLatin: 'Lu (u)', order: 15, isActive: true, exampleWord: 'Ul' },
  { id: 'l_uc', charOlChiki: 'ᱪ', transliterationLatin: 'Uc (c)', order: 16, isActive: true, exampleWord: 'Ca' },
  { id: 'l_ud', charOlChiki: 'ᱫ', transliterationLatin: 'Ud (d)', order: 17, isActive: true, exampleWord: 'Da' },
  { id: 'l_unn', charOlChiki: 'ᱬ', transliterationLatin: 'Unn (nn)', order: 18, isActive: true, exampleWord: 'Nn' },
  { id: 'l_uy', charOlChiki: 'ᱭ', transliterationLatin: 'Uy (y)', order: 19, isActive: true, exampleWord: 'Ya' },
  { id: 'l_le', charOlChiki: 'ᱮ', transliterationLatin: 'Le (e)', order: 20, isActive: true, exampleWord: 'En' },
  { id: 'l_ep', charOlChiki: 'ᱯ', transliterationLatin: 'Ep (p)', order: 21, isActive: true, exampleWord: 'Pa' },
  { id: 'l_edd', charOlChiki: 'ᱰ', transliterationLatin: 'Edd (dd)', order: 22, isActive: true, exampleWord: 'Dd' },
  { id: 'l_en', charOlChiki: 'ᱱ', transliterationLatin: 'En (n)', order: 23, isActive: true, exampleWord: 'Na' },
  { id: 'l_err', charOlChiki: 'ᱲ', transliterationLatin: 'Err (rr)', order: 24, isActive: true, exampleWord: 'Rr' },
  { id: 'l_lo', charOlChiki: 'ᱳ', transliterationLatin: 'Lo (o)', order: 25, isActive: true, exampleWord: 'Ol' },
  { id: 'l_ott', charOlChiki: 'ᱴ', transliterationLatin: 'Ott (tt)', order: 26, isActive: true, exampleWord: 'Tt' },
  { id: 'l_obb', charOlChiki: 'ᱵ', transliterationLatin: 'Obb (b)', order: 27, isActive: true, exampleWord: 'Ba' },
  { id: 'l_ov', charOlChiki: 'ᱶ', transliterationLatin: 'Ov (v)', order: 28, isActive: true, exampleWord: 'Va' },
  { id: 'l_oh', charOlChiki: 'ᱷ', transliterationLatin: 'Oh (h)', order: 29, isActive: true, exampleWord: 'Ha' },
];

const numbers = [
  { id: 'n_0', numeral: '᱐', value: 0, nameOlChiki: 'ᱥᱩᱱ', nameLatin: 'Sun', order: 0 },
  { id: 'n_1', numeral: '᱑', value: 1, nameOlChiki: 'ᱢᱤᱛ', nameLatin: 'Mit', order: 1 },
  { id: 'n_2', numeral: '᱒', value: 2, nameOlChiki: 'ᱵᱟᱨ', nameLatin: 'Bar', order: 2 },
  { id: 'n_3', numeral: '᱓', value: 3, nameOlChiki: 'ᱯᱮ', nameLatin: 'Pe', order: 3 },
  { id: 'n_4', numeral: '᱔', value: 4, nameOlChiki: 'ᱯᱚᱱ', nameLatin: 'Pon', order: 4 },
  { id: 'n_5', numeral: '᱕', value: 5, nameOlChiki: 'ᱢᱚᱬᱮ', nameLatin: 'Mone', order: 5 },
  { id: 'n_6', numeral: '᱖', value: 6, nameOlChiki: 'ᱛᱩᱨᱩᱭ', nameLatin: 'Turui', order: 6 },
  { id: 'n_7', numeral: '᱗', value: 7, nameOlChiki: 'ᱮᱭᱟᱭ', nameLatin: 'Eae', order: 7 },
  { id: 'n_8', numeral: '᱘', value: 8, nameOlChiki: 'ᱤᱨᱟᱹᱞ', nameLatin: 'Irel', order: 8 },
  { id: 'n_9', numeral: '᱙', value: 9, nameOlChiki: 'ᱟᱨᱮ', nameLatin: 'Are', order: 9 },
];

const rhyme_categories = [
  { id: 'rcat_animal', nameOlChiki: 'ᱡᱟᱱᱣᱟᱨ', nameLatin: 'Animal', iconName: 'pets', order: 0 },
  { id: 'rcat_nature', nameOlChiki: 'ᱯᱨᱚᱠᱨᱤᱛᱤ', nameLatin: 'Nature', iconName: 'nature', order: 1 },
  { id: 'rcat_moral', nameOlChiki: 'ᱱᱤᱛᱤ', nameLatin: 'Moral', iconName: 'auto_awesome', order: 2 },
  { id: 'rcat_general', nameOlChiki: 'ᱥᱟᱫᱷᱟᱨᱚᱬ', nameLatin: 'General', iconName: 'child_care', order: 3 },
];

const rhyme_subcategories = [
  { id: 'rsub_wild', categoryId: 'rcat_animal', nameOlChiki: 'ᱵᱤᱨ ᱡᱟᱱᱣᱟᱨ', nameLatin: 'Wild Animals', order: 0 },
  { id: 'rsub_domestic', categoryId: 'rcat_animal', nameOlChiki: 'ᱜᱷᱚᱨ ᱡᱟᱱᱣᱟᱨ', nameLatin: 'Domestic Animals', order: 1 },
  { id: 'rsub_birds', categoryId: 'rcat_animal', nameOlChiki: 'ᱪᱮᱬᱮ', nameLatin: 'Birds', order: 2 },
  { id: 'rsub_insects', categoryId: 'rcat_animal', nameOlChiki: 'ᱠᱤᱲᱟ', nameLatin: 'Insects', order: 3 },
  { id: 'rsub_rivers', categoryId: 'rcat_nature', nameOlChiki: 'ᱜᱟᱰᱟ', nameLatin: 'Rivers & Water', order: 0 },
  { id: 'rsub_mountains', categoryId: 'rcat_nature', nameOlChiki: 'ᱵᱩᱨᱩ', nameLatin: 'Mountains & Forest', order: 1 },
  { id: 'rsub_weather', categoryId: 'rcat_nature', nameOlChiki: 'ᱦᱚᱭ ᱦᱤᱥᱤᱫ', nameLatin: 'Weather', order: 2 },
  { id: 'rsub_flowers', categoryId: 'rcat_nature', nameOlChiki: 'ᱵᱟᱦᱟ', nameLatin: 'Flowers & Plants', order: 3 },
  { id: 'rsub_honesty', categoryId: 'rcat_moral', nameOlChiki: 'ᱥᱟᱹᱨᱤ', nameLatin: 'Honesty', order: 0 },
  { id: 'rsub_kindness', categoryId: 'rcat_moral', nameOlChiki: 'ᱫᱟᱭᱟ', nameLatin: 'Kindness', order: 1 },
  { id: 'rsub_courage', categoryId: 'rcat_moral', nameOlChiki: 'ᱵᱤᱨ', nameLatin: 'Courage', order: 2 },
  { id: 'rsub_wisdom', categoryId: 'rcat_moral', nameOlChiki: 'ᱜᱤᱭᱟᱱ', nameLatin: 'Wisdom', order: 3 },
  { id: 'rsub_lullaby', categoryId: 'rcat_general', nameOlChiki: 'ᱡᱩᱢᱤᱫ ᱥᱮᱨᱮᱧ', nameLatin: 'Lullaby', order: 0 },
  { id: 'rsub_festive', categoryId: 'rcat_general', nameOlChiki: 'ᱯᱚᱨᱚᱵ', nameLatin: 'Festive', order: 1 },
  { id: 'rsub_counting', categoryId: 'rcat_general', nameOlChiki: 'ᱞᱮᱠᱷᱟ', nameLatin: 'Counting', order: 2 },
  { id: 'rsub_play', categoryId: 'rcat_general', nameOlChiki: 'ᱟᱹᱭᱩᱨ', nameLatin: 'Play Songs', order: 3 },
];

// ─── Run ───
async function main() {
  console.log('🚀 Seeding Appwrite database...\n');

  await importCollection('categories', categories);
  await importCollection('letters', letters);
  await importCollection('numbers', numbers);
  await importCollection('rhyme_categories', rhyme_categories);
  await importCollection('rhyme_subcategories', rhyme_subcategories);

  console.log('\n🎉 Seed import complete!');
}

main().catch(e => {
  console.error('Fatal:', e);
  process.exit(1);
});
