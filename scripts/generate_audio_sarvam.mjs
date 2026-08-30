#!/usr/bin/env node

/**
 * Sarvam AI Audio Generation & Appwrite Storage Sync Script
 * 
 * Generates natural Indic text-to-speech audio using Sarvam AI (bulbul:v4 / bulbul:v3)
 * for Olitun stories, sentences, vocabulary lessons, and words, then automatically uploads
 * the generated audio to the Appwrite Storage "audio" bucket and updates the database records.
 * 
 * Usage:
 *   SARVAM_API_KEY="your_sarvam_key" node scripts/generate_audio_sarvam.mjs
 * 
 * Options via ENV:
 *   SARVAM_MODEL="bulbul:v4" (default: bulbul:v4 with auto-fallback to bulbul:v3)
 *   SPEAKER="shubh" (or "aditi", "priya", "amartya")
 *   PACE="0.9" (0.5 to 2.0; 0.9 is ideal for learners)
 *   TARGET="all" | "vocab" | "sentences" | "words"
 */

import { readFileSync, writeFileSync } from 'node:fs';

const SARVAM_API_KEY = process.env.SARVAM_API_KEY;
const PREFERRED_MODEL = process.env.SARVAM_MODEL || 'bulbul:v4';
const SPEAKER = process.env.SPEAKER || 'shubh';
const PACE = parseFloat(process.env.PACE || '0.9');
const TARGET = process.env.TARGET || 'all';

const ENDPOINT = 'https://sgp.cloud.appwrite.io/v1';
const PROJECT_ID = '699495910038e39622c5';
const DATABASE_ID = 'olitun_db';
const BUCKET_ID = 'audio';

if (!SARVAM_API_KEY) {
  console.error('❌ Error: SARVAM_API_KEY environment variable is required.');
  console.error('   Usage: SARVAM_API_KEY="your_key" node scripts/generate_audio_sarvam.mjs');
  process.exit(1);
}

function getAppwriteHeaders() {
  const prefs = JSON.parse(readFileSync(process.env.HOME + '/.appwrite/prefs.json', 'utf8'));
  const p = prefs[PROJECT_ID];
  if (!p || !p.cookie) {
    throw new Error('No active Appwrite CLI session cookie found in ~/.appwrite/prefs.json');
  }
  return {
    'X-Appwrite-Project': PROJECT_ID,
    'X-Appwrite-Mode': 'admin',
    'Cookie': p.cookie.split(';')[0],
  };
}

let activeModel = PREFERRED_MODEL;

/**
 * Call Sarvam AI Text-To-Speech API with Rate Limit Retry & Fallback
 */
async function generateSpeech(text, targetLang = 'hi-IN', retries = 3) {
  const clean = text.replace(/[\(\)\[\]"']/g, '').split('–')[0].split('-')[0].trim();
  if (!clean) return null;

  const payload = {
    text: clean.slice(0, 2500),
    language_code: targetLang,
    speaker: SPEAKER,
    model: activeModel,
    pace: PACE,
  };

  for (let attempt = 0; attempt <= retries; attempt++) {
    let res = await fetch('https://api.sarvam.ai/text-to-speech', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'api-subscription-key': SARVAM_API_KEY,
      },
      body: JSON.stringify(payload),
    });

    if (res.status === 429 && attempt < retries) {
      const waitTime = (attempt + 1) * 1500;
      process.stdout.write(`⏳ (429 rate limit, waiting ${waitTime}ms)... `);
      await new Promise(r => setTimeout(r, waitTime));
      continue;
    }

    // Auto-fallback from bulbul:v4 to bulbul:v3 if v4 preview is not enabled on the key
    if (!res.ok && activeModel === 'bulbul:v4' && (res.status === 400 || res.status === 404)) {
      console.log('ℹ️  bulbul:v4 not enabled for this tier, falling back to bulbul:v3...');
      activeModel = 'bulbul:v3';
      payload.model = 'bulbul:v3';
      res = await fetch('https://api.sarvam.ai/text-to-speech', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'api-subscription-key': SARVAM_API_KEY,
        },
        body: JSON.stringify(payload),
      });
    }

    if (!res.ok) {
      const errText = await res.text();
      throw new Error(`Sarvam AI API failed (${res.status}): ${errText}`);
    }

    const json = await res.json();
    if (!json.audios || !json.audios[0]) {
      throw new Error('No audio returned in Sarvam AI response');
    }

    return Buffer.from(json.audios[0], 'base64');
  }

  return null;
}

/**
 * Upload Audio Buffer to Appwrite Storage Bucket
 */
async function uploadToAppwrite(appwriteHeaders, fileId, audioBuffer, filename = 'speech.wav') {
  // Sanitize file ID to comply with Appwrite rules (max 36 chars, alphanumeric, _, .)
  const safeFileId = fileId.toLowerCase().replace(/[^a-z0-9_.]/g, '_').slice(0, 36);

  const boundary = '----AppwriteFormBoundary' + Math.random().toString(36).substring(2);
  
  const headerParts = [
    `--${boundary}`,
    `Content-Disposition: form-data; name="fileId"`,
    '',
    safeFileId,
    `--${boundary}`,
    `Content-Disposition: form-data; name="file"; filename="${filename}"`,
    `Content-Type: audio/wav`,
    '',
    '',
  ].join('\r\n');

  const footer = `\r\n--${boundary}--\r\n`;
  const fullBody = Buffer.concat([
    Buffer.from(headerParts, 'utf8'),
    audioBuffer,
    Buffer.from(footer, 'utf8'),
  ]);

  const url = `${ENDPOINT}/storage/buckets/${BUCKET_ID}/files`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      ...appwriteHeaders,
      'Content-Type': `multipart/form-data; boundary=${boundary}`,
    },
    body: fullBody,
  });

  if (res.status === 409) {
    // Already exists
    return `${ENDPOINT}/storage/buckets/${BUCKET_ID}/files/${safeFileId}/view?project=${PROJECT_ID}`;
  }

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Appwrite file upload failed (${res.status}): ${err}`);
  }

  const json = await res.json();
  return `${ENDPOINT}/storage/buckets/${BUCKET_ID}/files/${json.$id}/view?project=${PROJECT_ID}`;
}

async function processVocabLessons(appwriteHeaders) {
  console.log('\n📖 Generating Sarvam AI Audio for Vocabulary Lessons (vocab_lessons.json)...');
  const filePath = new URL('../assets/seed/vocab_lessons.json', import.meta.url);
  const lessons = JSON.parse(readFileSync(filePath, 'utf8'));

  let generatedCount = 0;

  for (const lesson of lessons) {
    console.log(`\n📚 Vocab Lesson: ${lesson.titleLatin || lesson.id} (${lesson.id})`);
    for (let i = 0; i < lesson.blocks.length; i++) {
      const block = lesson.blocks[i];
      if (block.type === 'quiz') continue;

      if (block.audioUrl && block.audioUrl.startsWith('http')) {
        console.log(`  [${i + 1}/${lesson.blocks.length}] ⏭️ Already has audio`);
        continue;
      }

      const speechText = block.textLatin || block.textOlChiki || '';
      if (!speechText) continue;

      const cleanPrompt = speechText.replace(/[\(\)\[\]"]/g, '').split('–')[0].split('-')[0].trim();
      const prefix = lesson.id.replace('lesson_', '');
      const fileId = `snd_${prefix}_${i}`.slice(0, 36);

      try {
        process.stdout.write(`  [${i + 1}/${lesson.blocks.length}] "${cleanPrompt.slice(0, 30)}..." -> `);
        const audioBuf = await generateSpeech(cleanPrompt);
        if (!audioBuf) {
          console.log(`⚠️ Empty text prompt, skipping`);
          continue;
        }
        const fileUrl = await uploadToAppwrite(appwriteHeaders, fileId, audioBuf, `${fileId}.wav`);
        block.audioUrl = fileUrl;
        console.log(`✅ ${fileUrl}`);
        generatedCount++;
        await new Promise(r => setTimeout(r, 200));
      } catch (e) {
        console.log(`❌ Error: ${e.message}`);
      }
    }
  }

  writeFileSync(filePath, JSON.stringify(lessons, null, 2), 'utf8');
  console.log(`\n🎉 Updated assets/seed/vocab_lessons.json with ${generatedCount} new Sarvam audio URLs!`);
}

async function processSentenceLessons(appwriteHeaders) {
  console.log('\n📖 Generating Sarvam AI Audio for Sentence & Story Lessons (sentence_lessons.json)...');
  const filePath = new URL('../assets/seed/sentence_lessons.json', import.meta.url);
  const lessons = JSON.parse(readFileSync(filePath, 'utf8'));

  let generatedCount = 0;

  for (const lesson of lessons) {
    console.log(`\n📚 Lesson: ${lesson.titleLatin || lesson.id} (${lesson.id})`);
    for (let i = 0; i < lesson.blocks.length; i++) {
      const block = lesson.blocks[i];
      if (block.type === 'quiz') continue;

      if (block.audioUrl && block.audioUrl.startsWith('http')) {
        console.log(`  [${i + 1}/${lesson.blocks.length}] ⏭️ Already has audio`);
        continue;
      }

      const speechText = block.textLatin || block.textOlChiki || '';
      if (!speechText) continue;

      const cleanPrompt = speechText.replace(/[\(\)\[\]"]/g, '').split('–')[0].split('-')[0].trim();
      const prefix = lesson.id.replace('lesson_', '');
      const fileId = `snd_${prefix}_${i}`.slice(0, 36);

      try {
        process.stdout.write(`  [${i + 1}/${lesson.blocks.length}] "${cleanPrompt.slice(0, 30)}..." -> `);
        const audioBuf = await generateSpeech(cleanPrompt);
        if (!audioBuf) {
          console.log(`⚠️ Empty text prompt, skipping`);
          continue;
        }
        const fileUrl = await uploadToAppwrite(appwriteHeaders, fileId, audioBuf, `${fileId}.wav`);
        block.audioUrl = fileUrl;
        console.log(`✅ ${fileUrl}`);
        generatedCount++;
        await new Promise(r => setTimeout(r, 200));
      } catch (e) {
        console.log(`❌ Error: ${e.message}`);
      }
    }
  }

  writeFileSync(filePath, JSON.stringify(lessons, null, 2), 'utf8');
  console.log(`\n🎉 Updated assets/seed/sentence_lessons.json with ${generatedCount} new Sarvam audio URLs!`);
}

async function processWords(appwriteHeaders) {
  console.log('\n🔤 Generating Sarvam AI Audio for Vocabulary Words...');
  const filePath = new URL('../assets/seed/words.json', import.meta.url);
  const words = JSON.parse(readFileSync(filePath, 'utf8'));

  let generatedCount = 0;

  for (let i = 0; i < words.length; i++) {
    const word = words[i];
    if (word.audioUrl && word.audioUrl.startsWith('http')) continue;

    const speechText = word.latin || word.santaliLatin || word.wordLatin || word.santali || '';
    if (!speechText) continue;

    const fileId = `word_${word.id || i}`.slice(0, 36);
    try {
      process.stdout.write(`  [${i + 1}/${words.length}] "${speechText}" -> `);
      const audioBuf = await generateSpeech(speechText);
      if (!audioBuf) continue;
      const fileUrl = await uploadToAppwrite(appwriteHeaders, fileId, audioBuf, `${fileId}.wav`);
      word.audioUrl = fileUrl;
      console.log(`✅ ${fileUrl}`);
      generatedCount++;
      await new Promise(r => setTimeout(r, 250));
    } catch (e) {
      console.log(`❌ Error: ${e.message}`);
    }
  }

  writeFileSync(filePath, JSON.stringify(words, null, 2), 'utf8');
  console.log(`\n🎉 Updated assets/seed/words.json with ${generatedCount} word audio URLs!`);
}

async function main() {
  console.log(`🚀 Initializing Sarvam AI Audio Generator...`);
  console.log(`   Model Preference: ${PREFERRED_MODEL}`);
  console.log(`   Speaker Voice: ${SPEAKER}`);
  console.log(`   Pace: ${PACE}x`);
  console.log(`   Target: ${TARGET}`);

  const appwriteHeaders = getAppwriteHeaders();

  if (TARGET === 'vocab' || TARGET === 'all') {
    await processVocabLessons(appwriteHeaders);
  }
  if (TARGET === 'sentences' || TARGET === 'all') {
    await processSentenceLessons(appwriteHeaders);
  }
  if (TARGET === 'words' || TARGET === 'all') {
    await processWords(appwriteHeaders);
  }

  console.log('\n🏁 Complete audio pipeline execution finished successfully!');
}

main().catch(err => {
  console.error('\nFatal Error:', err);
  process.exit(1);
});
