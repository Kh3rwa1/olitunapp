#!/usr/bin/env node

/**
 * Olitun Comprehensive Lesson & Database Sanitizer
 *
 * 1. Sanitizes assets/seed/sentence_lessons.json so that:
 *    - textOlChiki contains ONLY pure Ol Chiki script.
 *    - textLatin contains ONLY clean Romanized Santali pronunciation.
 *    - data.meaning contains the clean English translation.
 *    - data.pronunciation contains the clean pronunciation guide.
 * 2. Syncs all cleaned lessons directly into Appwrite database collection `lessons`.
 */

import { readFileSync, writeFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import { spawnSync } from 'child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SEED_PATH = resolve(__dirname, '../assets/seed/sentence_lessons.json');
const DATABASE_ID = 'olitun_db';

const rawSeed = readFileSync(SEED_PATH, 'utf8');
const lessons = JSON.parse(rawSeed);

console.log(`Loaded ${lessons.length} lessons from seed.`);

// Specific cleanups for grammar lessons
const GRAMMAR_CLEANUPS = {
  'lesson_grammar_pronouns': [
    { oc: 'ᱤᱧ', lt: 'Inj', meaning: 'I / Me', pron: 'Inj' },
    { oc: 'ᱟᱢ', lt: 'Am', meaning: 'You', pron: 'Am' },
    { oc: 'ᱩᱱᱤ', lt: 'Uni', meaning: 'He / She', pron: 'Uni' },
    { oc: 'ᱟᱵᱚ', lt: 'Abo', meaning: 'We all (inclusive)', pron: 'Abo' },
    { oc: 'ᱟᱞᱮ', lt: 'Ale', meaning: 'We (exclusive)', pron: 'Ale' },
    { oc: 'ᱟᱯᱮ', lt: 'Ape', meaning: 'You all', pron: 'Ape' },
    { oc: 'ᱩᱱᱠᱩ', lt: 'Unku', meaning: 'They', pron: 'Unku' },
  ],
  'lesson_grammar_questions_cases': [
    { oc: 'ᱪᱮᱫ', lt: 'Ched', meaning: 'What?', pron: 'Ched' },
    { oc: 'ᱚᱠᱚᱭ', lt: 'Okoi', meaning: 'Who?', pron: 'Okoi' },
    { oc: 'ᱚᱠᱟ', lt: 'Oka', meaning: 'Which / Where?', pron: 'Oka' },
    { oc: 'ᱛᱤᱥ', lt: 'Tis', meaning: 'When?', pron: 'Tis' },
    { oc: 'ᱪᱮᱞᱠᱟ', lt: 'Cileka', meaning: 'How?', pron: 'Ci-le-ka' },
    { oc: '-ᱨᱮ', lt: '-re', meaning: 'in / at / on', pron: '-re' },
    { oc: '-ᱠᱷᱚᱱ', lt: '-khon', meaning: 'from', pron: '-khon' },
  ],
  'lesson_grammar_verb_tenses': [
    { oc: 'ᱯᱟᱲᱦᱟᱣ ᱮᱫᱟᱧ', lt: 'Parhaw edanj', meaning: 'I am reading', pron: 'Par-haw ed-anj' },
    { oc: 'ᱡᱚᱢ ᱠᱮᱫᱟᱧ', lt: 'Jom kedanj', meaning: 'I ate', pron: 'Jom ked-anj' },
    { oc: 'ᱦᱤᱡᱩᱜᱼᱟᱧ', lt: 'Hijug-anj', meaning: 'I will come', pron: 'Hi-jug anj' },
  ],
  'lesson_grammar_possessives': [
    { oc: 'ᱤᱧᱟᱜ', lt: 'Inyag', meaning: 'My / Mine', pron: 'Iny-ag' },
    { oc: 'ᱟᱵᱚᱣᱟᱜ', lt: 'Aboyag', meaning: 'Our (inclusive)', pron: 'Ab-o-yag' },
    { oc: 'ᱩᱱᱤᱭᱟᱜ', lt: 'Uniyag', meaning: 'His / Her', pron: 'Un-i-yag' },
  ],
  'lesson_grammar_plurals_numbers': [
    { oc: 'ᱜᱟᱛᱮᱠᱤᱱ', lt: 'Gatekin', meaning: 'Two friends', pron: 'Ga-te-kin' },
    { oc: 'ᱜᱤᱫᱽᱨᱟᱹᱠᱚ', lt: 'Gidrako', meaning: 'Children', pron: 'Gid-ra-ko' },
  ],
  'lesson_grammar_conjunctions': [
    { oc: 'ᱟᱨ', lt: 'Ar', meaning: 'And', pron: 'Ar' },
    { oc: 'ᱢᱮᱱᱠᱷᱟᱱ', lt: 'Menkhan', meaning: 'But', pron: 'Men-khan' },
    { oc: 'ᱮᱱᱛᱮ', lt: 'Ente', meaning: 'Because', pron: 'En-te' },
  ],
};

function cleanComposite(str) {
  if (!str) return { roman: '', meaning: '' };
  const seps = [' – ', ' - ', ' — ', ': '];
  for (const sep of seps) {
    if (str.includes(sep)) {
      const parts = str.split(sep);
      return {
        roman: parts[0].trim(),
        meaning: parts.slice(1).join(sep).trim()
      };
    }
  }
  return { roman: str.trim(), meaning: '' };
}

let modifiedLessonsCount = 0;

for (const lesson of lessons) {
  let lessonChanged = false;
  const customList = GRAMMAR_CLEANUPS[lesson.id];

  if (lesson.blocks && Array.isArray(lesson.blocks)) {
    for (let i = 0; i < lesson.blocks.length; i++) {
      const block = lesson.blocks[i];
      if (block.type !== 'text') continue;

      if (customList && customList[i]) {
        const c = customList[i];
        block.textOlChiki = c.oc;
        block.textLatin = c.lt;
        block.data = block.data || {};
        block.data.meaning = c.meaning;
        block.data.pronunciation = c.pron;
        lessonChanged = true;
        continue;
      }

      // General cleanup for composite textLatin (e.g. "Daka jom me – Please eat food")
      if (block.textLatin && (block.textLatin.includes(' – ') || block.textLatin.includes(' - ') || block.textLatin.includes(' — '))) {
        const { roman, meaning } = cleanComposite(block.textLatin);
        if (roman && meaning) {
          block.textLatin = roman;
          block.data = block.data || {};
          if (!block.data.meaning) {
            block.data.meaning = meaning;
          }
          lessonChanged = true;
        }
      }

      // Clean Ol Chiki if polluted with Latin
      if (block.textOlChiki && /[a-zA-Z]/.test(block.textOlChiki)) {
        // e.g. "ᱪᱮᱫ - Ched (What?)" -> extract Ol Chiki portion
        const match = block.textOlChiki.match(/^([\u1C50-\u1C7F\s\-–\.]+)/);
        if (match && match[1].trim()) {
          block.textOlChiki = match[1].trim();
          lessonChanged = true;
        }
      }
    }
  }

  if (lessonChanged) {
    modifiedLessonsCount++;
  }
}

console.log(`Sanitized ${modifiedLessonsCount} lessons in memory.`);
writeFileSync(SEED_PATH, JSON.stringify(lessons, null, 2), 'utf8');
console.log(`Saved clean data to ${SEED_PATH}`);

// Now sync modified lessons to Appwrite
console.log('\n--- Syncing Cleaned Lessons to Appwrite DB ---');
for (const lesson of lessons) {
  const blocksJson = JSON.stringify(lesson.blocks || []);
  const docId = lesson.id;

  const res = spawnSync('appwrite', [
    'databases', 'update-document',
    '--database-id', DATABASE_ID,
    '--collection-id', 'lessons',
    '--document-id', docId,
    '--data', JSON.stringify({ blocks: blocksJson }),
    '-j'
  ], { encoding: 'utf8' });

  if (res.status === 0) {
    console.log(`✅ Synced ${docId} to Appwrite.`);
  } else {
    // If update failed (e.g. doc doesn't exist by that ID in DB), check why
    console.log(`⚠️ Note for ${docId}: ${res.stderr || res.stdout}`);
  }
}

console.log('\n🎉 Lesson sanitization and database sync complete!');
