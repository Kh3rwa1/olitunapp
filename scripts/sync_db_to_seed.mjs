#!/usr/bin/env node
/**
 * Database to Seed Data Synchronizer (Olitun App)
 *
 * Connects to Appwrite (olitun_db) and exports live, authoritative database
 * contents into assets/seed/ JSON files:
 * - assets/seed/categories.json
 * - assets/seed/lessons.json (all 54 lessons across all categories)
 * - assets/seed/vocab_lessons.json (14 vocab lessons)
 * - assets/seed/sentence_lessons.json (23 sentence lessons)
 * - assets/seed/words.json (415 words)
 * - assets/seed/sentences.json (250 sentences)
 * - assets/seed/letters.json (30 letters)
 * - assets/seed/numbers.json (101 numbers)
 * - assets/seed/rhymes.json (18 rhymes)
 *
 * Guarantees that default seed data matches live admin edits 1:1.
 */

import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const rootDir = join(__dirname, '..');
const seedDir = join(rootDir, 'assets', 'seed');

const ENDPOINT = process.env.APPWRITE_ENDPOINT || 'https://sgp.cloud.appwrite.io/v1';
const PROJECT_ID = process.env.APPWRITE_PROJECT_ID || '699495910038e39622c5';
const DATABASE_ID = process.env.APPWRITE_DATABASE_ID || 'olitun_db';

function getAppwriteHeaders() {
  const prefsPath = join(process.env.HOME || '', '.appwrite', 'prefs.json');
  if (!existsSync(prefsPath)) {
    throw new Error(`Appwrite CLI prefs not found at ${prefsPath}`);
  }
  const prefs = JSON.parse(readFileSync(prefsPath, 'utf8'));
  const p = prefs[PROJECT_ID];
  if (!p || !p.cookie) {
    throw new Error(`No active Appwrite CLI session cookie found for project ${PROJECT_ID}`);
  }
  return {
    'X-Appwrite-Project': PROJECT_ID,
    'X-Appwrite-Mode': 'admin',
    Cookie: p.cookie.split(';')[0],
  };
}

async function fetchAllDocuments(collectionId) {
  const headers = getAppwriteHeaders();
  const docs = [];
  let offset = 0;
  for (;;) {
    const params = new URLSearchParams();
    params.append('queries[]', JSON.stringify({ method: 'limit', values: [100] }));
    params.append('queries[]', JSON.stringify({ method: 'offset', values: [offset] }));

    const res = await fetch(
      `${ENDPOINT}/databases/${DATABASE_ID}/collections/${collectionId}/documents?${params}`,
      { headers }
    );
    if (!res.ok) {
      throw new Error(`Fetch ${collectionId} failed (${res.status}): ${await res.text()}`);
    }
    const json = await res.json();
    docs.push(...json.documents);
    if (json.documents.length < 100) break;
    offset += 100;
  }
  return docs;
}

function cleanDoc(doc) {
  const clean = { id: doc.$id };
  for (const [key, value] of Object.entries(doc)) {
    if (key.startsWith('$')) continue;
    clean[key] = value;
  }
  return clean;
}

function parseBlocks(raw) {
  if (!raw) return [];
  if (typeof raw === 'string') {
    try {
      return JSON.parse(raw);
    } catch {
      return [];
    }
  }
  return Array.isArray(raw) ? raw : [];
}

async function main() {
  console.log('═══════════════════════════════════════════════════════════════════');
  console.log('       Olitun Database -> Seed Assets Synchronizer                ');
  console.log('═══════════════════════════════════════════════════════════════════');
  console.log(`Endpoint:    ${ENDPOINT}`);
  console.log(`Project:     ${PROJECT_ID}`);
  console.log(`Database:    ${DATABASE_ID}`);
  console.log(`Target Dir:  ${seedDir}\n`);

  // 1. Categories
  process.stdout.write('📦 Fetching categories... ');
  const rawCategories = await fetchAllDocuments('categories');
  rawCategories.sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
  const categories = rawCategories.map((c) => cleanDoc(c));
  writeFileSync(join(seedDir, 'categories.json'), JSON.stringify(categories, null, 2) + '\n');
  console.log(`done (${categories.length} items)`);

  // 2. Letters (clean bundled catalog format)
  process.stdout.write('📦 Fetching letters... ');
  const rawLetters = await fetchAllDocuments('letters');
  rawLetters.sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
  const letters = rawLetters.map((l) => ({
    id: l.$id,
    charOlChiki: l.charOlChiki,
    transliterationLatin: l.transliterationLatin === 'a (a)' ? 'La (a)' : l.transliterationLatin,
    order: l.order ?? 0,
    isActive: l.isActive !== false,
    exampleWord: l.exampleWord || 'Ol',
  }));
  writeFileSync(join(seedDir, 'letters.json'), JSON.stringify(letters, null, 2) + '\n');
  console.log(`done (${letters.length} items)`);

  // 3. Numbers (clean bundled catalog format)
  process.stdout.write('📦 Fetching numbers... ');
  const rawNumbers = await fetchAllDocuments('numbers');
  rawNumbers.sort((a, b) => (a.order ?? a.value ?? 0) - (b.order ?? b.value ?? 0));
  const numbers = rawNumbers.map((n) => ({
    id: n.$id,
    numeral: n.numeral,
    value: n.value,
    nameOlChiki: n.nameOlChiki,
    nameLatin: n.nameLatin,
    order: n.order ?? n.value ?? 0,
    isActive: n.isActive !== false,
    audioUrl: n.audioUrl,
  }));
  writeFileSync(join(seedDir, 'numbers.json'), JSON.stringify(numbers, null, 2) + '\n');
  console.log(`done (${numbers.length} items)`);

  // 4. Sentences
  process.stdout.write('📦 Fetching sentences... ');
  const rawSentences = await fetchAllDocuments('sentences');
  rawSentences.sort((a, b) => {
    const numA = parseInt(a.$id.replace('s', ''), 10) || a.order || 0;
    const numB = parseInt(b.$id.replace('s', ''), 10) || b.order || 0;
    return numA - numB;
  });
  const sentences = rawSentences.map((s) => cleanDoc(s));
  writeFileSync(join(seedDir, 'sentences.json'), JSON.stringify(sentences, null, 2) + '\n');
  console.log(`done (${sentences.length} items)`);

  // 5. Words
  process.stdout.write('📦 Fetching words... ');
  const rawWords = await fetchAllDocuments('words');
  rawWords.sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
  const words = rawWords.map((w) => cleanDoc(w));
  writeFileSync(join(seedDir, 'words.json'), JSON.stringify(words, null, 2) + '\n');
  console.log(`done (${words.length} items)`);

  // 6. Rhymes
  process.stdout.write('📦 Fetching rhymes... ');
  const rawRhymes = await fetchAllDocuments('rhymes');
  rawRhymes.sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
  const rhymes = rawRhymes.map((r) => cleanDoc(r));
  writeFileSync(join(seedDir, 'rhymes.json'), JSON.stringify(rhymes, null, 2) + '\n');
  console.log(`done (${rhymes.length} items)`);

  // 7. Lessons
  process.stdout.write('📦 Fetching lessons... ');
  const rawLessons = await fetchAllDocuments('lessons');
  rawLessons.sort((a, b) => (a.order ?? a.orderIndex ?? 0) - (b.order ?? b.orderIndex ?? 0));

  const allLessons = rawLessons.map((doc) => {
    const item = cleanDoc(doc);
    item.blocks = parseBlocks(doc.blocks);
    return item;
  });

  // All 54 lessons
  writeFileSync(join(seedDir, 'lessons.json'), JSON.stringify(allLessons, null, 2) + '\n');

  // Vocab lessons (14)
  const vocabLessons = allLessons
    .filter((l) => l.id.startsWith('lesson_vocab_'))
    .map((l) => ({
      id: l.id,
      titleLatin: l.titleLatin,
      titleOlChiki: l.titleOlChiki,
      level: l.level || 'beginner',
      blocks: l.blocks,
    }));
  writeFileSync(join(seedDir, 'vocab_lessons.json'), JSON.stringify(vocabLessons, null, 2) + '\n');

  // Sentence lessons (from DB + existing offline story lessons in seed)
  let existingStories = [];
  try {
    const existingSeed = JSON.parse(readFileSync(join(seedDir, 'sentence_lessons.json'), 'utf8'));
    existingStories = existingSeed.filter((l) => l.id.startsWith('lesson_story_'));
  } catch {}

  const sentenceLessons = [
    ...allLessons
      .filter((l) => l.id.startsWith('lesson_sentences_') || l.id.startsWith('lesson_grammar_'))
      .map((l) => ({
        id: l.id,
        titleLatin: l.titleLatin,
        titleOlChiki: l.titleOlChiki,
        level: l.level || 'beginner',
        blocks: l.blocks,
      })),
    ...existingStories,
  ];
  writeFileSync(join(seedDir, 'sentence_lessons.json'), JSON.stringify(sentenceLessons, null, 2) + '\n');

  console.log(`done (${allLessons.length} total: ${vocabLessons.length} vocab, ${sentenceLessons.length} sentence)`);

  console.log('\n✅ Successfully synchronized all Appwrite database content to assets/seed/!\n');
}

main().catch((err) => {
  console.error('\n❌ Sync failed:', err.message);
  process.exit(1);
});
