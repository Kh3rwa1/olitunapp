#!/usr/bin/env node

/**
 * Olitun Data Import Script
 * Imports MySQL data (exported as JSON) into Appwrite collections.
 *
 * Usage:
 *   1. First export data:
 *      curl "https://olitun.in/admin-panel/api/export_data.php?key=olitun_export_2025" > scripts/exported_data.json
 *
 *   2. Then import:
 *      APPWRITE_API_KEY=your_key node scripts/appwrite_import.mjs
 */

import { readFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

const ENDPOINT = 'https://sgp.cloud.appwrite.io/v1';
const PROJECT_ID = '699495910038e39622c5';
const API_KEY = process.env.APPWRITE_API_KEY;
const DATABASE_ID = 'olitun_db';

if (!API_KEY) {
  console.error('❌ Set APPWRITE_API_KEY environment variable');
  process.exit(1);
}

const headers = {
  'Content-Type': 'application/json',
  'X-Appwrite-Project': PROJECT_ID,
  'X-Appwrite-Key': API_KEY,
};

async function api(method, path, body = null) {
  const url = `${ENDPOINT}${path}`;
  const opts = { method, headers };
  if (body) opts.body = JSON.stringify(body);

  const res = await fetch(url, opts);
  if (!res.ok) {
    const text = await res.text();
    if (res.status === 409) return null; // Already exists
    throw new Error(`${method} ${path} → ${res.status}: ${text}`);
  }
  return res.json();
}

// ─── Column → Appwrite field mapping ───
// MySQL uses snake_case, Appwrite collections use camelCase

const FIELD_MAP = {
  categories: {
    id: 'id',
    title_ol_chiki: 'titleOlChiki',
    title_latin: 'titleLatin',
    icon_name: 'iconName',
    icon_url: 'iconUrl',
    lottie_url: 'lottieUrl',
    gradient_preset: 'gradientPreset',
    order_index: 'order',
    is_active: 'isActive',
    total_lessons: 'totalLessons',
    description: 'description',
  },
  lessons: {
    id: 'id',
    category_id: 'categoryId',
    title_ol_chiki: 'titleOlChiki',
    title_latin: 'titleLatin',
    level: 'level',
    order_index: 'order',
    is_active: 'isActive',
    estimated_minutes: 'estimatedMinutes',
    description: 'description',
    thumbnail_url: 'thumbnailUrl',
    is_premium: 'isPremium',
  },
  lesson_blocks: {
    id: 'id',
    lesson_id: 'lessonId',
    type: 'type',
    content_json: 'contentJson',
    order_index: 'order',
  },
  letters: {
    id: 'id',
    char_ol_chiki: 'charOlChiki',
    transliteration_latin: 'transliterationLatin',
    order_index: 'order',
    is_active: 'isActive',
    example_word: 'exampleWord',
    audio_url: 'audioUrl',
    image_url: 'imageUrl',
    lottie_url: 'lottieUrl',
  },
  numbers: {
    id: 'id',
    numeral: 'numeral',
    value: 'value',
    name_ol_chiki: 'nameOlChiki',
    name_latin: 'nameLatin',
    order_index: 'order',
    audio_url: 'audioUrl',
    image_url: 'imageUrl',
  },
  words: {
    id: 'id',
    word_ol_chiki: 'wordOlChiki',
    word_latin: 'wordLatin',
    meaning: 'meaning',
    usage_example: 'usageExample',
    category: 'category',
    order_index: 'order',
    audio_url: 'audioUrl',
    image_url: 'imageUrl',
  },
  rhymes: {
    id: 'id',
    title_ol_chiki: 'titleOlChiki',
    title_latin: 'titleLatin',
    content_ol_chiki: 'contentOlChiki',
    content_latin: 'contentLatin',
    audio_url: 'audioUrl',
    thumbnail_url: 'thumbnailUrl',
    category: 'categoryId',        // Map to new field name
    subcategory: 'subcategoryId',   // Map to new field name
    difficulty: 'difficulty',
    duration_seconds: 'durationSeconds',
    is_premium: 'isPremium',
  },
  banners: {
    id: 'id',
    title: 'title',
    subtitle: 'subtitle',
    image_url: 'imageUrl',
    lottie_url: 'animationUrl',
    gradient_preset: 'gradientPreset',
    action_url: 'targetRoute',
    order_index: 'order',
    is_active: 'isActive',
  },
  rhyme_categories: {
    id: 'id',
    name_ol_chiki: 'nameOlChiki',
    name_latin: 'nameLatin',
    icon_name: 'iconName',
    order_index: 'order',
  },
  rhyme_subcategories: {
    id: 'id',
    category_id: 'categoryId',
    name_ol_chiki: 'nameOlChiki',
    name_latin: 'nameLatin',
    order_index: 'order',
  },
  app_settings: {
    setting_key: 'settingKey',
    setting_value: 'settingValue',
  },
};

// ─── Type conversions ───
function convertValue(key, value) {
  if (value === null || value === undefined) return null;
  // Boolean fields
  if (['isActive', 'isPremium'].includes(key)) {
    return value === 1 || value === '1' || value === true;
  }
  // Integer fields
  if (['order', 'totalLessons', 'estimatedMinutes', 'value', 'durationSeconds'].includes(key)) {
    return parseInt(value, 10) || 0;
  }
  return value;
}

function transformRow(table, row) {
  const mapping = FIELD_MAP[table];
  if (!mapping) return null;

  const doc = {};
  let docId = null;

  for (const [mysqlCol, appwriteField] of Object.entries(mapping)) {
    if (mysqlCol === 'id' || mysqlCol === 'setting_key') {
      docId = String(row[mysqlCol] || '');
      continue;
    }
    const val = row[mysqlCol];
    doc[appwriteField] = convertValue(appwriteField, val);
  }

  // Remove null values
  for (const k of Object.keys(doc)) {
    if (doc[k] === null || doc[k] === undefined) delete doc[k];
  }

  return { docId, doc };
}

// ─── Main ───
async function main() {
  const dataPath = resolve(__dirname, 'exported_data.json');
  let rawData;

  try {
    rawData = readFileSync(dataPath, 'utf-8');
  } catch {
    console.error(`❌ File not found: ${dataPath}`);
    console.error('   Run this first:');
    console.error('   curl "https://olitun.in/admin-panel/api/export_data.php?key=olitun_export_2025" > scripts/exported_data.json');
    process.exit(1);
  }

  const data = JSON.parse(rawData);
  console.log('📂 Loaded export data\n');

  // Import order matters (foreign keys)
  const importOrder = [
    'categories',
    'rhyme_categories',
    'rhyme_subcategories',
    'lessons',
    'lesson_blocks',
    'letters',
    'numbers',
    'words',
    'rhymes',
    'banners',
    'app_settings',
  ];

  let totalImported = 0;
  let totalSkipped = 0;
  let totalFailed = 0;

  for (const table of importOrder) {
    const rows = data[table];
    if (!rows || rows._error) {
      console.log(`⚠️  ${table}: ${rows?._error || 'No data'}`);
      continue;
    }

    console.log(`📋 Importing ${table} (${rows.length} rows)...`);

    for (const row of rows) {
      const result = transformRow(table, row);
      if (!result || !result.docId) {
        totalFailed++;
        continue;
      }

      try {
        const path = `/databases/${DATABASE_ID}/collections/${table}/documents`;
        const resp = await api('POST', path, {
          documentId: result.docId,
          data: result.doc,
        });
        if (resp === null) {
          totalSkipped++;
          process.stdout.write('⏭');
        } else {
          totalImported++;
          process.stdout.write('✅');
        }
      } catch (e) {
        totalFailed++;
        process.stdout.write('❌');
        console.error(`\n   Failed: ${result.docId} → ${e.message}`);
      }
    }
    console.log(''); // newline
  }

  console.log(`\n🎉 Import complete!`);
  console.log(`   ✅ Imported: ${totalImported}`);
  console.log(`   ⏭  Skipped (already exists): ${totalSkipped}`);
  console.log(`   ❌ Failed: ${totalFailed}`);
}

main().catch(e => {
  console.error('Fatal error:', e);
  process.exit(1);
});
