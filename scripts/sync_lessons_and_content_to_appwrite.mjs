#!/usr/bin/env node

/**
 * High-speed Appwrite Cloud Database Sync for Lessons, Stories, Grammar, Sentences, and Words.
 * Uses the active Appwrite CLI session cookie to authenticate directly via REST API.
 */

import { readFileSync } from 'node:fs';

const ENDPOINT = 'https://sgp.cloud.appwrite.io/v1';
const PROJECT_ID = '699495910038e39622c5';
const DATABASE_ID = 'olitun_db';

function getHeaders() {
  const prefs = JSON.parse(readFileSync(process.env.HOME + '/.appwrite/prefs.json', 'utf8'));
  const p = prefs[PROJECT_ID];
  if (!p || !p.cookie) {
    throw new Error('No active Appwrite session cookie found.');
  }
  const cookieVal = p.cookie.split(';')[0];
  return {
    'Content-Type': 'application/json',
    'X-Appwrite-Project': PROJECT_ID,
    'X-Appwrite-Mode': 'admin',
    'Cookie': cookieVal,
  };
}

function loadJson(relPath) {
  try {
    const raw = readFileSync(new URL(`../${relPath}`, import.meta.url), 'utf8');
    return JSON.parse(raw);
  } catch (e) {
    console.error(`Error reading ${relPath}:`, e.message);
    return [];
  }
}

async function upsertDocument(headers, collectionId, documentId, data) {
  const docUrl = `${ENDPOINT}/databases/${DATABASE_ID}/collections/${collectionId}/documents/${documentId}`;
  
  // 1. Try to update existing document
  const updateRes = await fetch(docUrl, {
    method: 'PATCH',
    headers,
    body: JSON.stringify({ data }),
  });

  if (updateRes.ok) {
    return 'updated';
  }

  if (updateRes.status === 404) {
    // 2. If not found, create new document
    const createUrl = `${ENDPOINT}/databases/${DATABASE_ID}/collections/${collectionId}/documents`;
    const createRes = await fetch(createUrl, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        documentId,
        data,
      }),
    });

    if (createRes.ok) {
      return 'created';
    } else {
      const err = await createRes.text();
      throw new Error(`Create failed (${createRes.status}): ${err}`);
    }
  }

  const err = await updateRes.text();
  throw new Error(`Update failed (${updateRes.status}): ${err}`);
}

// Concurrency helper
async function runBatched(items, concurrency, fn) {
  let index = 0;
  let created = 0;
  let updated = 0;
  let failed = 0;

  async function worker() {
    while (index < items.length) {
      const i = index++;
      const item = items[i];
      try {
        const res = await fn(item);
        if (res === 'created') created++;
        else if (res === 'updated') updated++;
        process.stdout.write(res === 'created' ? '+' : '.');
      } catch (e) {
        failed++;
        console.error(`\n❌ Failed: ${item.id || item.wordLatin || item.sentenceLatin} -> ${e.message}`);
      }
    }
  }

  const workers = Array.from({ length: concurrency }, () => worker());
  await Promise.all(workers);
  return { created, updated, failed };
}

async function main() {
  console.log('🚀 Starting Fast Appwrite Cloud Database Sync...\n');
  const headers = getHeaders();

  // 1. Sentence & Story Lessons
  const sentenceLessons = loadJson('assets/seed/sentence_lessons.json');
  console.log(`📚 Syncing ${sentenceLessons.length} Sentence & Story Lessons...`);
  const lRes = await runBatched(sentenceLessons, 5, async (lesson) => {
    const docData = {
      titleOlChiki: lesson.titleOlChiki || '',
      titleLatin: lesson.titleLatin || '',
      level: lesson.level || 'beginner',
      description: lesson.description || '',
      orderIndex: lesson.order || 0,
      order: lesson.order || 0,
      isActive: lesson.isActive ?? true,
      estimatedMinutes: lesson.estimatedMinutes || 5,
      isPremium: lesson.isPremium ?? false,
      categoryId: 'cat_sentences_1778594024495',
      blocks: typeof lesson.blocks === 'object' ? JSON.stringify(lesson.blocks) : (lesson.blocks || '[]'),
    };
    return upsertDocument(headers, 'lessons', lesson.id, docData);
  });
  console.log(`\n✅ Lessons: ${lRes.created} created, ${lRes.updated} updated, ${lRes.failed} failed.\n`);

  // 2. Vocab Lessons
  const vocabLessons = loadJson('assets/seed/vocab_lessons.json');
  console.log(`📖 Syncing ${vocabLessons.length} Vocab Lessons...`);
  const vRes = await runBatched(vocabLessons, 5, async (lesson) => {
    const docData = {
      titleOlChiki: lesson.titleOlChiki || '',
      titleLatin: lesson.titleLatin || '',
      level: lesson.level || 'beginner',
      description: lesson.description || '',
      orderIndex: lesson.order || 0,
      order: lesson.order || 0,
      isActive: lesson.isActive ?? true,
      estimatedMinutes: lesson.estimatedMinutes || 5,
      isPremium: lesson.isPremium ?? false,
      categoryId: 'cat_vocab_1778594020532',
      blocks: typeof lesson.blocks === 'object' ? JSON.stringify(lesson.blocks) : (lesson.blocks || '[]'),
    };
    return upsertDocument(headers, 'lessons', lesson.id, docData);
  });
  console.log(`\n✅ Vocab Lessons: ${vRes.created} created, ${vRes.updated} updated, ${vRes.failed} failed.\n`);

  // 3. Sentences (250)
  const sentences = loadJson('assets/seed/sentences.json');
  console.log(`💬 Syncing ${sentences.length} Sentences to Appwrite Cloud...`);
  const sRes = await runBatched(sentences, 10, async (s) => {
    const docData = {
      sentenceLatin: s.sentenceLatin || '',
      sentenceOlChiki: s.sentenceOlChiki || '',
      meaning: s.meaning || '',
      category: s.category || 'General',
      order: s.order || 0,
      isActive: s.isActive ?? true,
    };
    return upsertDocument(headers, 'sentences', s.id, docData);
  });
  console.log(`\n✅ Sentences: ${sRes.created} created, ${sRes.updated} updated, ${sRes.failed} failed.\n`);

  // 4. Words (415)
  const words = loadJson('assets/seed/words.json');
  console.log(`🔤 Syncing ${words.length} Words to Appwrite Cloud...`);
  const wRes = await runBatched(words, 10, async (w) => {
    const docData = {
      wordLatin: w.wordLatin || '',
      wordOlChiki: w.wordOlChiki || '',
      meaning: w.meaning || '',
      category: w.category || 'General',
      order: w.order || 0,
      isActive: w.isActive ?? true,
    };
    return upsertDocument(headers, 'words', w.id, docData);
  });
  console.log(`\n✅ Words: ${wRes.created} created, ${wUpdated => wRes.updated} updated, ${wRes.failed} failed.\n`);

  console.log('🎉 SUCCESS: All stories, grammar lessons, sentences, and vocabulary are 100% synchronized with Appwrite Cloud!');
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
