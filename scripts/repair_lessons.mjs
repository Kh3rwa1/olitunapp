#!/usr/bin/env node

/**
 * Olitun Targeted Lesson Block Repair Tool (Appwrite CLI Edition)
 * Automatically leverages your active Appwrite CLI session.
 *
 * DRY RUN BY DEFAULT:
 *   node scripts/repair_lessons.mjs
 *
 * COMMIT REPAIRS:
 *   node scripts/repair_lessons.mjs --commit
 */

import { readFileSync, writeFileSync, mkdirSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import { spawnSync } from 'child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));
const COMMIT_MODE = process.argv.includes('--commit');
const DATABASE_ID = 'olitun_db';

// Ground truth block data for Basic Greetings & Sentences
const GROUND_TRUTH_DATA = {
  // --- GREETINGS ---
  'lesson_greet_0': [
    { type: 'text', textOlChiki: 'ᱡᱚᱦᱟᱨ', textLatin: 'Johar – Hello / Greetings', id: 'blk_text_0', order: 0, markdown: 'Johar – Hello / Greetings' },
    { type: 'text', textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱥᱮᱛᱟᱜ', textLatin: 'Sagun setag – Good morning', id: 'blk_text_1', order: 1, markdown: 'Sagun setag – Good morning' },
    { type: 'text', textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱛᱤᱠᱤᱱ', textLatin: 'Sagun tikin – Good afternoon', id: 'blk_text_2', order: 2, markdown: 'Sagun tikin – Good afternoon' },
    { type: 'text', textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱟᱹᱭᱩᱵ', textLatin: 'Sagun ayub – Good evening', id: 'blk_text_3', order: 3, markdown: 'Sagun ayub – Good evening' },
    { type: 'text', textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱧᱤᱫᱟᱹ', textLatin: 'Sagun njida – Good night', id: 'blk_text_4', order: 4, markdown: 'Sagun njida – Good night' }
  ],
  'lesson_greet_1': [
    { type: 'text', textOlChiki: 'ᱟᱢᱟᱜ ᱧᱩᱛᱩᱢ ᱪᱮᱫ?', textLatin: 'Amag njutum ced? – What is your name?', id: 'blk_text_0', order: 0, markdown: 'Amag njutum ced? – What is your name?' },
    { type: 'text', textOlChiki: 'ᱤᱧᱟᱜ ᱧᱩᱛᱩᱢ ᱫᱚ ... ᱠᱟᱱᱟ', textLatin: 'Injag njutum do ... kana – My name is ...', id: 'blk_text_1', order: 1, markdown: 'Injag njutum do ... kana – My name is ...' },
    { type: 'text', textOlChiki: 'ᱟᱢ ᱚᱠᱟ ᱠᱷᱚᱱᱮᱢ ᱦᱮᱡ ᱠᱟᱱᱟ?', textLatin: 'Am oka khonem hej kana? – Where are you from?', id: 'blk_text_2', order: 2, markdown: 'Am oka khonem hej kana? – Where are you from?' },
    { type: 'text', textOlChiki: 'ᱤᱧ ᱫᱚ ... ᱠᱷᱚᱱᱤᱧ ᱦᱮᱡ ᱠᱟᱱᱟ', textLatin: 'In do ... khoninj hej kana – I am from ...', id: 'blk_text_3', order: 3, markdown: 'In do ... khoninj hej kana – I am from ...' },
    { type: 'text', textOlChiki: 'ᱟᱢ ᱥᱟᱶ ᱧᱟᱯᱟᱢ ᱠᱟᱛᱮ ᱨᱟᱹᱥᱠᱟᱹᱧ ᱵᱩᱡᱷᱟᱹᱣ ᱠᱮᱫᱟ', textLatin: 'Am saw njapam kate raskanj bujhau keda – Nice to meet you!', id: 'blk_text_4', order: 4, markdown: 'Am saw njapam kate raskanj bujhau keda – Nice to meet you!' }
  ],
  'lesson_greet_2': [
    { type: 'text', textOlChiki: 'ᱥᱟᱨᱦᱟᱣ', textLatin: 'Sarhaw – Thank you', id: 'blk_text_0', order: 0, markdown: 'Sarhaw – Thank you' },
    { type: 'text', textOlChiki: 'ᱤᱠᱟᱹ ᱠᱟᱹᱧ ᱢᱮ', textLatin: 'Ika kanj me – Excuse me / Sorry', id: 'blk_text_1', order: 1, markdown: 'Ika kanj me – Excuse me / Sorry' },
    { type: 'text', textOlChiki: 'ᱦᱮᱸ', textLatin: 'Hẽ – Yes', id: 'blk_text_2', order: 2, markdown: 'Hẽ – Yes' },
    { type: 'text', textOlChiki: 'ᱵᱟᱝ', textLatin: 'Bang – No', id: 'blk_text_3', order: 3, markdown: 'Bang – No' },
    { type: 'text', textOlChiki: 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ', textLatin: 'Daya kate – Please', id: 'blk_text_4', order: 4, markdown: 'Daya kate – Please' },
    { type: 'text', textOlChiki: 'ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ', textLatin: 'Adi napay – Very good / Well done', id: 'blk_text_5', order: 5, markdown: 'Adi napay – Very good / Well done' }
  ],
  'lesson_greet_3': [
    { type: 'text', textOlChiki: 'ᱡᱚᱦᱟᱨ ᱜᱮ', textLatin: 'Johar ge – Goodbye', id: 'blk_text_0', order: 0, markdown: 'Johar ge – Goodbye' },
    { type: 'text', textOlChiki: 'ᱜᱟᱯᱟ ᱵᱚᱱ ᱧᱟᱯᱟᱢᱟ', textLatin: 'Gapa bon njapama – See you tomorrow', id: 'blk_text_1', order: 1, markdown: 'Gapa bon njapama – See you tomorrow' },
    { type: 'text', textOlChiki: 'ᱱᱟᱯᱟᱭ ᱛᱮ ᱛᱟᱦᱮᱸᱱ ᱢᱮ', textLatin: 'Napay te tahen me – Take care / Stay well', id: 'blk_text_2', order: 2, markdown: 'Napay te tahen me – Take care / Stay well' },
    { type: 'text', textOlChiki: 'ᱤᱧ ᱫᱚᱧ ᱪᱟᱞᱟᱜ ᱠᱟᱱᱟ', textLatin: 'In donj chalag kana – I am leaving now', id: 'blk_text_3', order: 3, markdown: 'In donj chalag kana – I am leaving now' },
    { type: 'text', textOlChiki: 'ᱫᱩᱞᱟᱹᱲ ᱡᱚᱦᱟᱨ', textLatin: 'Dulaar Johar – Goodbye with love', id: 'blk_text_4', order: 4, markdown: 'Dulaar Johar – Goodbye with love' }
  ],

  // --- SENTENCES ---
  'lesson_sentences_basics': [
    { type: 'text', textOlChiki: 'ᱟᱢᱟᱜ ᱧᱩᱛᱩᱢ ᱪᱮᱫ?', textLatin: 'Amaak nyutum ced? – What is your name?', id: 'blk_text_0', order: 0, markdown: 'Amaak nyutum ced? – What is your name?' },
    { type: 'text', textOlChiki: 'ᱤᱧᱟᱜ ᱧᱩᱛᱩᱢ ᱫᱚ ᱥᱟᱱᱛᱷᱟᱞ', textLatin: 'Injaak nyutum do Santhal – My name is Santhal', id: 'blk_text_1', order: 1, markdown: 'Injaak nyutum do Santhal – My name is Santhal' },
    { type: 'text', textOlChiki: 'ᱟᱢ ᱫᱚ ᱚᱠᱟᱛᱮm ᱪᱟᱞᱟᱜ ᱠᱟᱱᱟ?', textLatin: 'Am do okatem chalag kana? – Where are you going?', id: 'blk_text_2', order: 2, markdown: 'Am do okatem chalag kana? – Where are you going?' },
    { type: 'text', textOlChiki: 'ᱟᱢ ᱫᱚ ᱚᱠᱟᱨᱮm ᱛᱟᱦᱮᱸᱱᱟ?', textLatin: 'Am do okarem tahena? – Where do you live?', id: 'blk_text_3', order: 3, markdown: 'Am do okarem tahena? – Where do you live?' },
    { type: 'text', textOlChiki: 'ᱤᱧ ᱫᱚ ᱱᱚᱸᱰᱮᱧ ᱛᱟᱦᱮᱸᱱᱟ', textLatin: 'In do nondenj tahena – I live here', id: 'blk_text_4', order: 4, markdown: 'In do nondenj tahena – I live here' },
    { type: 'text', textOlChiki: 'ᱤᱧ ᱫᱚᱧ ᱪᱟᱞᱟᱜ ᱠᱟᱱᱟ', textLatin: 'Inj donj chalag kana – I am going', id: 'blk_text_5', order: 5, markdown: 'Inj donj chalag kana – I am going' },
    { type: 'text', textOlChiki: 'ᱟᱢ ᱫᱚ ᱚᱠᱟᱭ ᱠᱟᱱᱟm?', textLatin: 'Am do okoy kanam? – Who are you?', id: 'blk_text_6', order: 6, markdown: 'Am do okoy kanam? – Who are you?' },
    { type: 'text', textOlChiki: 'ᱩᱱᱤ ᱫᱚ ᱤᱧᱤᱡ ᱵᱚᱠᱚᱧ ᱠᱟᱱᱟᱭ', textLatin: 'Uni do injij bokonj kanay – He is my younger brother', id: 'blk_text_7', order: 7, markdown: 'Uni do injij bokonj kanay – He is my younger brother' },
    { type: 'text', textOlChiki: 'ᱱᱩᱭ ᱫᱚ ᱤᱧᱤᱡ ᱜᱟᱛᱮ ᱠᱟᱱᱟᱭ', textLatin: 'Nuy do injij gate kanay – This is my friend', id: 'blk_text_8', order: 8, markdown: 'Nuy do injij gate kanay – This is my friend' },
    { type: 'text', textOlChiki: 'ᱟᱢ ᱫᱚ ᱚᱠᱟ ᱠᱷᱚᱱ ᱮᱢ ᱦᱮᱡ ᱮᱱᱟ?', textLatin: 'Am do oka khon em hej ena? – Where did you come from?', id: 'blk_text_9', order: 9, markdown: 'Am do oka khon em hej ena? – Where did you come from?' },
    { type: 'text', textOlChiki: 'ᱤᱧ ᱫᱚ ᱟᱹᱛᱩ ᱠᱷᱚᱱ ᱤᱧ ᱦᱮᱡ ᱮᱱᱟ', textLatin: 'Inj do atu khon inj hej ena – I came from the village', id: 'blk_text_10', order: 10, markdown: 'Inj do atu khon inj hej ena – I came from the village' },
    { type: 'text', textOlChiki: 'ᱱᱚᱶᱟ ᱫᱚ ᱪᱮᱫ ᱠᱟᱱᱟ?', textLatin: 'Nowa do ced kana? – What is this?', id: 'blk_text_11', order: 11, markdown: 'Nowa do ced kana? – What is this?' },
    { type: 'text', textOlChiki: 'ᱱᱚᱶᱟ ᱫᱚ ᱫᱟᱨᱮ ᱠᱟᱱᱟ', textLatin: 'Nowa do dare kana – This is a tree', id: 'blk_text_12', order: 12, markdown: 'Nowa do dare kana – This is a tree' },
    { type: 'text', textOlChiki: 'ᱟᱢ ᱫᱚ ᱪᱮᱫ ᱮᱢ ᱠᱩᱥᱤᱭᱟᱜᱼᱟ?', textLatin: 'Am do ced em kusiyaga? – What do you like?', id: 'blk_text_13', order: 13, markdown: 'Am do ced em kusiyaga? – What do you like?' },
    { type: 'text', textOlChiki: 'ᱤᱧ ᱫᱚ ᱥᱟᱱᱛᱟᱲᱤ ᱨᱚᱲ ᱤᱧ ᱠᱩᱥᱤᱭᱟᱜᱼᱟ', textLatin: 'Inj do Santali ror inj kusiyaga – I like speaking Santali', id: 'blk_text_14', order: 14, markdown: 'Inj do Santali ror inj kusiyaga – I like speaking Santali' },
    { type: 'text', textOlChiki: 'ᱟᱢ ᱫᱚ ᱠᱟᱹᱢᱤᱭᱟm?', textLatin: 'Am do kamiyam? – Do you work?', id: 'blk_text_15', order: 15, markdown: 'Am do kamiyam? – Do you work?' },
    { type: 'text', textOlChiki: 'ᱦᱮᱸ, ᱤᱧ ᱫᱚ ᱠᱟᱹᱢᱤᱭᱟᱹᱧ', textLatin: 'Hẽ, inj do kamiyanj – Yes, I work', id: 'blk_text_16', order: 16, markdown: 'Hẽ, inj do kamiyanj – Yes, I work' },
    { type: 'text', textOlChiki: 'ᱩᱱᱤ ᱫᱚ ᱚᱠᱟᱨᱮ ᱢᱮᱱᱟᱭᱟ?', textLatin: 'Uni do okare menaya? – Where is he/she?', id: 'blk_text_17', order: 17, markdown: 'Uni do okare menaya? – Where is he/she?' },
    { type: 'text', textOlChiki: 'ᱩᱱᱤ ᱫᱚ ᱚᱲᱟᱜ ᱨᱮ ᱢᱮᱱᱟᱭᱟ', textLatin: 'Uni do orag re menaya – He/she is at home', id: 'blk_text_18', order: 18, markdown: 'Uni do orag re menaya – He/she is at home' }
  ],
  'lesson_sentences_conversations': [
    { type: 'text', textOlChiki: 'ᱤᱧ ᱨᱮᱸᱜᱮᱡ ᱮᱫ ᱤᱧᱟ', textLatin: 'In rengej ed inja – I am hungry', id: 'blk_text_0', order: 0, markdown: 'In rengej ed inja – I am hungry' },
    { type: 'text', textOlChiki: 'ᱫᱟᱠᱟ ᱡᱚᱢ ᱢᱮ', textLatin: 'Daka jom me – Please eat food', id: 'blk_text_1', order: 1, markdown: 'Daka jom me – Please eat food' },
    { type: 'text', textOlChiki: 'ᱫᱟᱜ ᱧᱩ ᱢᱮ', textLatin: 'Dag nju me – Please drink water', id: 'blk_text_2', order: 2, markdown: 'Dag nju me – Please drink water' },
    { type: 'text', textOlChiki: 'ᱤᱧ ᱯᱟᱲᱦᱟᱜ ᱠᱟᱱᱟᱧ', textLatin: 'In parhaag kananj – I am studying', id: 'blk_text_3', order: 3, markdown: 'In parhaag kananj – I am studying' },
    { type: 'text', textOlChiki: 'ᱟᱢ ᱪᱮᱫ ᱮᱢ ᱪᱤᱠᱟᱹᱭᱮᱫᱟ?', textLatin: 'Am ced em cikayeda? – What are you doing?', id: 'blk_text_4', order: 4, markdown: 'Am ced em cikayeda? – What are you doing?' },
    { type: 'text', textOlChiki: 'ᱤᱧ ᱫᱚ ᱠᱟᱹᱢᱤᱭᱮᱫᱟᱧ', textLatin: 'In do kamiyedanj – I am working', id: 'blk_text_5', order: 5, markdown: 'In do kamiyedanj – I am working' },
    { type: 'text', textOlChiki: 'ᱟᱢ ᱛᱩᱢᱫᱟᱜ ᱨᱩ ᱮᱢ ᱵᱟᱰᱟᱭᱟ?', textLatin: 'Am tumdag ru em badaya? – Do you know how to play the drum?', id: 'blk_text_6', order: 6, markdown: 'Am tumdag ru em badaya? – Do you know how to play the drum?' },
    { type: 'text', textOlChiki: 'ᱵᱟᱹᱧ ᱵᱟᱰᱟᱭᱟ', textLatin: 'Banj badaya – I do not know', id: 'blk_text_7', order: 7, markdown: 'Banj badaya – I do not know' },
    { type: 'text', textOlChiki: 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱪᱮᱫ ᱟᱹᱧ ᱢᱮ', textLatin: 'Daya kate chet anj me – Please teach me', id: 'blk_text_8', order: 8, markdown: 'Daya kate chet anj me – Please teach me' },
    { type: 'text', textOlChiki: 'ᱦᱮᱸ, ᱜᱟᱯᱟᱧ ᱪᱮᱫ ᱟᱢᱟ', textLatin: 'Hẽ, gapanj chet ama – Yes, I will teach you tomorrow', id: 'blk_text_9', order: 9, markdown: 'Hẽ, gapanj chet ama – Yes, I will teach you tomorrow' },
    { type: 'text', textOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱟᱹᱰᱤ ᱨᱟᱹᱥᱠᱟᱹ ᱫᱤᱱ ᱠᱟᱱᱟ', textLatin: 'Tehenj do adi raska din kana – Today is a very joyful day', id: 'blk_text_10', order: 10, markdown: 'Tehenj do adi raska din kana – Today is a very joyful day' },
    { type: 'text', textOlChiki: 'ᱟᱞᱮ ᱚᱲᱟᱜ ᱛᱮ ᱦᱤᱡᱩᱜ ᱢᱮ', textLatin: 'Ale orag te hijug me – Come to our house', id: 'blk_text_11', order: 11, markdown: 'Ale orag te hijug me – Come to our house' },
    { type: 'text', textOlChiki: 'ᱤᱧ ᱫᱚ ᱜᱟᱯᱟ ᱱᱩ ᱦᱤᱡᱩᱜᱼᱟ', textLatin: 'Inj do gapa nu hijuga – I will come tomorrow', id: 'blk_text_12', order: 12, markdown: 'Inj do gapa nu hijuga – I will come tomorrow' },
    { type: 'text', textOlChiki: 'ᱟᱢᱟᱜ ᱚᱞ ᱪᱤᱠᱤ ᱯᱩᱛᱷᱤ ᱮᱢᱟᱧ ᱢᱮ', textLatin: 'Amaak Ol Chiki puthi emanj me – Give me your Ol Chiki book', id: 'blk_text_13', order: 13, markdown: 'Amaak Ol Chiki puthi emanj me – Give me your Ol Chiki book' },
    { type: 'text', textOlChiki: 'ᱱᱚᱶᱟ ᱫᱚ ᱤᱧᱟᱜ ᱯᱩᱛᱷᱤ ᱠᱟᱱᱟ', textLatin: 'Nowa do injaak puthi kana – This is my book', id: 'blk_text_14', order: 14, markdown: 'Nowa do injaak puthi kana – This is my book' }
  ]
};

function runCliCommand(args) {
  const result = spawnSync('appwrite', [...args, '-j'], {
    encoding: 'utf-8',
    maxBuffer: 20 * 1024 * 1024
  });

  if (result.status !== 0) {
    throw new Error(result.stderr || 'Appwrite CLI execution failed.');
  }

  return JSON.parse(result.stdout);
}

async function main() {
  console.log('==================================================');
  console.log('🌟 Olitun Targeted Lesson Block Repair Tool');
  console.log('   (Executing via Active Appwrite CLI Session)');
  console.log('==================================================');
  console.log('🔍 MODE:', COMMIT_MODE ? '🔴 COMMIT MODE (Updating Database)' : '🟢 DRY-RUN MODE (Read-only / Audit)');
  console.log('==================================================\n');

  console.log('📚 Fetching all lessons from collection "lessons"...');

  let lessons;
  try {
    const res = runCliCommand([
      'databases', 'list-documents',
      '--database-id', DATABASE_ID,
      '--collection-id', 'lessons'
    ]);
    lessons = res.documents || [];
    console.log(`✅ Successfully fetched ${lessons.length} lessons.`);
  } catch (e) {
    console.error('❌ Failed to fetch lessons using Appwrite CLI:', e.message);
    process.exit(1);
  }

  // 1. Create a safety backup on disk
  const backupDir = resolve(__dirname, 'backups');
  try {
    mkdirSync(backupDir, { recursive: true });
  } catch (_) {}

  const stamp = new Date().toISOString().replaceAll(':', '-').replaceAll('.', '-');
  const backupPath = resolve(backupDir, `lessons_pre_repair_${stamp}.json`);

  try {
    writeFileSync(backupPath, JSON.stringify(lessons, null, 2), 'utf-8');
    console.log(`💾 Local safety backup successfully written: ${backupPath}`);
  } catch (e) {
    console.error('❌ Failed to write backup file to disk:', e.message);
    process.exit(1);
  }

  // 2. Perform targeted repairs and scans
  let repairedCount = 0;
  let corruptedCustomCount = 0;

  console.log('\n🔎 Starting database corruption scan & audit...\n');

  for (const lesson of lessons) {
    const lessonId = lesson.$id || lesson.id;
    const title = lesson.titleLatin || 'Untitled';
    let blocks = [];

    if (lesson.blocks) {
      try {
        blocks = typeof lesson.blocks === 'string' ? JSON.parse(lesson.blocks) : lesson.blocks;
      } catch (_) {
        console.error(`⚠️  Could not parse blocks JSON for lesson: ${title} (${lessonId})`);
        continue;
      }
    }

    // Check if it is a default lesson in our repair catalog
    if (GROUND_TRUTH_DATA[lessonId]) {
      console.log(`📌 [Target Found] Default Lesson: "${title}" (ID: ${lessonId})`);

      if (COMMIT_MODE) {
        console.log(`   ⚙️  Restoring ground-truth blocks (jsonEncode'd string mapping)...`);
        const cleanBlocks = GROUND_TRUTH_DATA[lessonId];
        
        // CRITICAL CHECK: Sending as a stringified JSON representation, NOT a raw JSON array
        const stringifiedBlocks = JSON.stringify(cleanBlocks);

        try {
          runCliCommand([
            'databases', 'update-document',
            '--database-id', DATABASE_ID,
            '--collection-id', 'lessons',
            '--document-id', lessonId,
            '--data', JSON.stringify({ blocks: stringifiedBlocks })
          ]);
          console.log(`   ✅ Correct blocks written successfully via CLI!`);
          repairedCount++;
        } catch (e) {
          console.error(`   ❌ CLI write failed:`, e.message);
        }
      } else {
        console.log(`   ⏭  [DRY-RUN] Will replace blocks with clean ground-truth values.`);
        repairedCount++;
      }
      continue;
    }

    // Scan other lessons (custom or other defaults) for corrupted text blocks
    let hasCorruptedBlocks = false;
    let corruptedBlockCount = 0;
    if (Array.isArray(blocks)) {
      for (const block of blocks) {
        if (block.type === 'text' && (block.textOlChiki === null || block.textOlChiki === undefined)) {
          hasCorruptedBlocks = true;
          corruptedBlockCount++;
        }
      }
    }

    if (hasCorruptedBlocks) {
      console.warn(`⚠️  [CORRUPTED] "${title}" (ID: ${lessonId}) | Category: ${lesson.categoryId} | Blocks affected: ${corruptedBlockCount}`);
      corruptedCustomCount++;
    }
  }

  console.log('\n==================================================');
  console.log('🎉 Execution Summary');
  console.log('==================================================');
  console.log(`   📁 Safety Backup written to: ${backupPath}`);
  console.log(`   🛠️  Default lessons targeted/repaired: ${repairedCount}`);
  console.log(`   ⚠️  Other corrupted lessons scanned: ${corruptedCustomCount}`);
  console.log('==================================================');
  
  if (!COMMIT_MODE) {
    console.log('\n👉 NOTE: This run was a safe READ-ONLY DRY-RUN.');
    console.log('   Review the flagged list above. If everything looks correct, run:');
    console.log('   node scripts/repair_lessons.mjs --commit');
  } else {
    console.log('\n🟢 Database patch execution completed successfully via CLI.');
  }
}

main().catch(e => {
  console.error('Fatal error during execution:', e);
  process.exit(1);
});
