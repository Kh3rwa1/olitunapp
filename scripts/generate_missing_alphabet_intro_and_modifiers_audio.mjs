#!/usr/bin/env node
/**
 * Synthesizes and uploads audio for:
 * 1. lesson_alphabet_0, Block 0: "ᱨᱟᱦᱟ ᱟᱲᱟᱝ ᱫᱚ ᱛᱩᱨᱩᱭ ᱜᱚᱴᱟᱝ ᱢᱮᱱᱟᱜᱼᱟ᱾"
 * 2. lesson_alphabet_4, Blocks 0-5: The 6 Modifiers & Signs (Japag Arang)
 * 3. letters collection: The 5 modifier sign documents (l_gahla_tudag, l_mu_tudag, l_mu_gahla_tudag, l_ohod, l_ahd)
 */

import { existsSync, readFileSync } from 'node:fs';
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

async function patchDocument(collectionId, documentId, data) {
  const headers = getAppwriteHeaders();
  const res = await fetch(
    `${ENDPOINT}/databases/${DATABASE_ID}/collections/${collectionId}/documents/${documentId}`,
    {
      method: 'PATCH',
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ data }),
    }
  );
  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`Failed to update ${collectionId}/${documentId}: ${txt}`);
  }
  return res.json();
}

async function main() {
  const keys = loadBodhanKeys();
  console.log(`Loaded ${keys.length} Bodhan keys.`);
  let keyIdx = 0;

  // 1. Synthesize lesson_alphabet_0 Block 0
  console.log('\n--- Synthesizing lesson_alphabet_0 Intro Block ---');
  const introText = 'ᱨᱟᱦᱟ ᱟᱲᱟᱝ ᱫᱚ ᱛᱩᱨᱩᱭ ᱜᱚᱴᱟᱝ ᱢᱮᱱᱟᱜᱼᱟ᱾';
  const introBuf = await synthesizeBodhan(introText, keys[keyIdx++ % keys.length]);
  const introAudioUrl = await uploadToStorage('snd_alphabet_0_intro', 'snd_alphabet_0_intro.wav', introBuf);
  console.log(`✓ Uploaded snd_alphabet_0_intro -> ${introAudioUrl}`);

  // Fetch and update lesson_alphabet_0
  const headers = getAppwriteHeaders();
  const l0Res = await fetch(`${ENDPOINT}/databases/${DATABASE_ID}/collections/lessons/documents/lesson_alphabet_0`, { headers });
  const l0 = await l0Res.json();
  const l0Blocks = typeof l0.blocks === 'string' ? JSON.parse(l0.blocks) : l0.blocks;
  l0Blocks[0].audioUrl = introAudioUrl;
  if (!l0Blocks[0].meta) l0Blocks[0].meta = {};
  l0Blocks[0].meta.audioUrl = introAudioUrl;
  await patchDocument('lessons', 'lesson_alphabet_0', {
    blocks: JSON.stringify(l0Blocks),
  });
  console.log('✅ Updated lesson_alphabet_0 Block 0 in Appwrite!');

  // 2. Synthesize lesson_alphabet_4 Modifiers & Signs
  console.log('\n--- Synthesizing lesson_alphabet_4 Modifiers & Signs ---');
  const modifierItems = [
    { order: 0, text: 'ᱜᱟᱹᱦᱞᱟᱹ ᱴᱩᱰᱟᱹᱜ', fileId: 'snd_mod_gahla_tudag', letterId: 'l_gahla_tudag' },
    { order: 1, text: 'ᱢᱩ ᱴᱩᱰᱟᱹᱜ', fileId: 'snd_mod_mu_tudag', letterId: 'l_mu_tudag' },
    { order: 2, text: 'ᱢᱩ-ᱜᱟᱹᱦᱞᱟᱹ ᱴᱩᱰᱟᱹᱜ', fileId: 'snd_mod_mu_gahla_tudag', letterId: 'l_mu_gahla_tudag' },
    { order: 3, text: 'ᱚᱦᱚᱫ', fileId: 'snd_mod_ohod', letterId: 'l_ohod' },
    { order: 4, text: 'ᱟᱦᱚᱫ', fileId: 'snd_mod_ahd', letterId: 'l_ahd' },
    { order: 5, text: 'ᱢᱩᱪᱟᱹᱫ', fileId: 'snd_mod_mucaad', letterId: null },
  ];

  const l4Res = await fetch(`${ENDPOINT}/databases/${DATABASE_ID}/collections/lessons/documents/lesson_alphabet_4`, { headers });
  const l4 = await l4Res.json();
  const l4Blocks = typeof l4.blocks === 'string' ? JSON.parse(l4.blocks) : l4.blocks;

  for (const item of modifierItems) {
    console.log(`Synthesizing modifier: ${item.text}...`);
    const buf = await synthesizeBodhan(item.text, keys[keyIdx++ % keys.length]);
    const audioUrl = await uploadToStorage(item.fileId, `${item.fileId}.wav`, buf);
    console.log(`✓ Uploaded ${item.fileId} -> ${audioUrl}`);

    if (l4Blocks[item.order]) {
      l4Blocks[item.order].audioUrl = audioUrl;
      if (!l4Blocks[item.order].meta) l4Blocks[item.order].meta = {};
      l4Blocks[item.order].meta.audioUrl = audioUrl;
    }

    if (item.letterId) {
      await patchDocument('letters', item.letterId, {
        audioUrl,
      });
      console.log(`✓ Updated letters/${item.letterId} with audioUrl`);
    }
  }

  await patchDocument('lessons', 'lesson_alphabet_4', {
    blocks: JSON.stringify(l4Blocks),
  });
  console.log('✅ Updated lesson_alphabet_4 in Appwrite!');

  console.log('\n🎉 All missing instructional audio successfully synthesized and uploaded!');
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
