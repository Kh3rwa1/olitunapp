#!/usr/bin/env node
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

const BODHAN_URL = process.env.BODHAN_URL || 'https://api.bodhan.ai/v1/audio/speech';
const MODEL = 'indic-speak';
const VOICE = 'Phulmani';
const INSTRUCTIONS = '{"lang": "sat"}';

function loadBodhanKeys() {
  const keys = [];
  for (let i = 0; i < 8; i++) {
    const keyPath = join(rootDir, '.keys', `bodhan${i}`);
    if (existsSync(keyPath)) {
      const key = readFileSync(keyPath, 'utf8').trim();
      if (key) keys.push(key);
    }
  }
  return keys;
}

function getAppwriteHeaders() {
  const prefsPath = join(process.env.HOME || '', '.appwrite', 'prefs.json');
  const prefs = JSON.parse(readFileSync(prefsPath, 'utf8'));
  const p = prefs[PROJECT_ID];
  return {
    'X-Appwrite-Project': PROJECT_ID,
    'X-Appwrite-Mode': 'admin',
    Cookie: p.cookie.split(';')[0],
  };
}

async function synthesizeBodhan(text, apiKey) {
  const res = await fetch(BODHAN_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: MODEL,
      voice: VOICE,
      input: text,
      instructions: INSTRUCTIONS,
    }),
  });
  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`Bodhan TTS failed (${res.status}): ${txt}`);
  }
  return Buffer.from(await res.arrayBuffer());
}

async function uploadToStorage(fileId, filename, buffer) {
  const headers = getAppwriteHeaders();
  // Delete existing if present
  await fetch(`${ENDPOINT}/storage/buckets/${BUCKET_ID}/files/${fileId}`, {
    method: 'DELETE',
    headers,
  }).catch(() => {});

  const boundary = `----AppwriteBoundary${Date.now()}`;
  const preamble = Buffer.from(
    `--${boundary}\r\nContent-Disposition: form-data; name="fileId"\r\n\r\n${fileId}\r\n` +
    `--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="${filename}"\r\nContent-Type: audio/wav\r\n\r\n`
  );
  const postamble = Buffer.from(`\r\n--${boundary}--\r\n`);
  const body = Buffer.concat([preamble, buffer, postamble]);

  const uploadRes = await fetch(`${ENDPOINT}/storage/buckets/${BUCKET_ID}/files`, {
    method: 'POST',
    headers: {
      ...headers,
      'Content-Type': `multipart/form-data; boundary=${boundary}`,
    },
    body,
  });

  if (!uploadRes.ok) {
    const txt = await uploadRes.text();
    throw new Error(`Storage upload failed for ${fileId}: ${txt}`);
  }
  return `${ENDPOINT}/storage/buckets/${BUCKET_ID}/files/${fileId}/view?project=${PROJECT_ID}`;
}

async function main() {
  const keys = loadBodhanKeys();
  console.log(`Loaded ${keys.length} Bodhan keys`);

  const headers = getAppwriteHeaders();
  const lessonRes = await fetch(`${ENDPOINT}/databases/${DATABASE_ID}/collections/lessons/documents/lesson_grammar_conjunctions`, {
    headers,
  });
  if (!lessonRes.ok) throw new Error('Failed to fetch lesson_grammar_conjunctions');
  const lesson = await lessonRes.json();
  const blocks = typeof lesson.blocks === 'string' ? JSON.parse(lesson.blocks) : (lesson.blocks || []);

  console.log(`Current lesson has ${blocks.length} blocks`);

  let keyIdx = 0;
  for (let i = 0; i < blocks.length; i++) {
    const b = blocks[i];
    if (b.type === 'quiz') continue;
    if (b.audioUrl) continue;

    const santaliText = b.textOlChiki || b.textLatin || b.markdown;
    console.log(`Synthesizing audio for block ${b.order} (${santaliText})...`);

    const key = keys[keyIdx % keys.length];
    keyIdx++;

    const audioBuf = await synthesizeBodhan(santaliText, key);
    const fileId = `snd_grammar_conjunctions_${b.order + 1}`;
    const filename = `${fileId}.wav`;
    const audioUrl = await uploadToStorage(fileId, filename, audioBuf);

    b.audioUrl = audioUrl;
    if (!b.meta) b.meta = {};
    b.meta.audioUrl = audioUrl;
    console.log(`✓ Uploaded ${fileId} -> ${audioUrl}`);
  }

  // Update lesson document
  const updateRes = await fetch(`${ENDPOINT}/databases/${DATABASE_ID}/collections/lessons/documents/lesson_grammar_conjunctions`, {
    method: 'PATCH',
    headers: {
      ...headers,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      data: {
        blocks: JSON.stringify(blocks),
      },
    }),
  });

  if (!updateRes.ok) {
    throw new Error(`Failed to update lesson: ${await updateRes.text()}`);
  }
  console.log('✅ Updated lesson_grammar_conjunctions in Appwrite database!');
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
