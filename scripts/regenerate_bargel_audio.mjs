#!/usr/bin/env node
/**
 * Regenerates audio for Santali numbers 20-29 using Bodhan AI (Phulmani, sat).
 * Synthesizes "Bar Gel", "Bar Gel Mit", ... "Bar Gel Are" and uploads to Appwrite Storage
 * (both numbers collection audio and lesson blocks audio), then updates numbers DB docs.
 * Includes multi-key rotation and rate-limit retry.
 */

import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const ENDPOINT = 'https://sgp.cloud.appwrite.io/v1';
const PROJECT_ID = '699495910038e39622c5';
const DATABASE_ID = 'olitun_db';
const BUCKET_ID = 'audio';
const BODHAN_TTS_URL = 'https://api.bodhan.ai/v1/audio/speech';

function getAppwriteHeaders(isJson = false) {
  const prefsPath = join(process.env.HOME || '', '.appwrite', 'prefs.json');
  const prefs = JSON.parse(readFileSync(prefsPath, 'utf8'));
  const p = prefs[PROJECT_ID];
  if (!p || !p.cookie) throw new Error('No active Appwrite CLI session cookie found');
  const h = {
    'X-Appwrite-Project': PROJECT_ID,
    'X-Appwrite-Mode': 'admin',
    Cookie: p.cookie.split(';')[0],
  };
  if (isJson) h['Content-Type'] = 'application/json';
  return h;
}

async function getActiveBodhanKeys() {
  const headers = getAppwriteHeaders(true);
  const res = await fetch(`${ENDPOINT}/databases/${DATABASE_ID}/collections/bodhan_api_keys/documents`, { headers });
  if (!res.ok) throw new Error(`Failed to load bodhan keys: ${res.status}`);
  const data = await res.json();
  const activeKeys = data.documents?.filter((d) => d.isActive && d.key?.trim()) || [];
  if (activeKeys.length === 0) throw new Error('No active Bodhan API keys found.');
  return activeKeys.map((d) => ({ id: d.$id, label: d.label, key: d.key.trim() }));
}

async function synthesizeWithRotation(text, keys) {
  for (let attempt = 0; attempt < keys.length * 2; attempt++) {
    const keyObj = keys[attempt % keys.length];
    try {
      const res = await fetch(BODHAN_TTS_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${keyObj.key}`,
        },
        body: JSON.stringify({
          model: 'indic-speak',
          voice: 'Phulmani',
          input: text,
          instructions: JSON.stringify({ lang: 'sat' }),
        }),
      });

      if (res.ok) {
        return Buffer.from(await res.arrayBuffer());
      }

      const txt = await res.text();
      console.warn(`   ⚠️ Key ${keyObj.label} returned ${res.status}: ${txt.slice(0, 100)}`);
      if (res.status === 429) {
        console.log(`   Rate limit reached on ${keyObj.label}, rotating to next key...`);
        await new Promise((r) => setTimeout(r, 2000));
        continue;
      }
    } catch (e) {
      console.warn(`   ⚠️ Network error with key ${keyObj.label}: ${e.message}`);
      await new Promise((r) => setTimeout(r, 2000));
    }
  }
  throw new Error(`Failed to synthesize "${text}" after exhausting all available keys.`);
}

async function uploadToStorage(fileId, filename, buffer) {
  const headers = getAppwriteHeaders();
  // Delete existing file if present to overwrite
  await fetch(`${ENDPOINT}/storage/buckets/${BUCKET_ID}/files/${fileId}`, {
    method: 'DELETE',
    headers,
  }).catch(() => {});

  const boundary = `----AppwriteBoundary${Date.now()}_${Math.random().toString(36).slice(2)}`;
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

async function getNumberDoc(docId) {
  const headers = getAppwriteHeaders(true);
  const res = await fetch(`${ENDPOINT}/databases/${DATABASE_ID}/collections/numbers/documents/${docId}`, { headers });
  if (!res.ok) return null;
  return res.json();
}

async function updateNumberDoc(docId, data) {
  const headers = getAppwriteHeaders(true);
  const res = await fetch(`${ENDPOINT}/databases/${DATABASE_ID}/collections/numbers/documents/${docId}`, {
    method: 'PATCH',
    headers,
    body: JSON.stringify({ data }),
  });
  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`Failed to update numbers doc ${docId}: ${txt}`);
  }
  return res.json();
}

const ITEMS = [
  { val: 20, ol: 'ᱵᱟᱨ ᱜᱮᱞ', latin: 'Bar Gel', numFileId: 'num_n_20', lessonFileId: '6a225ef14bed8faddd31' },
  { val: 21, ol: 'ᱵᱟᱨ ᱜᱮᱞ ᱢᱤᱫ', latin: 'Bar Gel Mit', numFileId: 'num_n_21', lessonFileId: 'snd_numbers_21_50_0' },
  { val: 22, ol: 'ᱵᱟᱨ ᱜᱮᱞ ᱵᱟᱨ', latin: 'Bar Gel Bar', numFileId: 'num_n_22', lessonFileId: 'snd_numbers_21_50_1' },
  { val: 23, ol: 'ᱵᱟᱨ ᱜᱮᱞ ᱯᱮ', latin: 'Bar Gel Pe', numFileId: 'num_n_23', lessonFileId: 'snd_numbers_21_50_2' },
  { val: 24, ol: 'ᱵᱟᱨ ᱜᱮᱞ ᱯᱩᱱ', latin: 'Bar Gel Pun', numFileId: 'num_n_24', lessonFileId: 'snd_numbers_21_50_3' },
  { val: 25, ol: 'ᱵᱟᱨ ᱜᱮᱞ ᱢᱚᱬᱮ', latin: 'Bar Gel Mone', numFileId: 'num_n_25', lessonFileId: 'snd_numbers_21_50_4' },
  { val: 26, ol: 'ᱵᱟᱨ ᱜᱮᱞ ᱛᱩᱨᱩᱭ', latin: 'Bar Gel Turui', numFileId: 'num_n_26', lessonFileId: 'snd_numbers_21_50_5' },
  { val: 27, ol: 'ᱵᱟᱨ ᱜᱮᱞ ᱮᱭᱟᱭ', latin: 'Bar Gel Eae', numFileId: 'num_n_27', lessonFileId: 'snd_numbers_21_50_6' },
  { val: 28, ol: 'ᱵᱟᱨ ᱜᱮᱞ ᱤᱨᱟᱹᱞ', latin: 'Bar Gel Iral', numFileId: 'num_n_28', lessonFileId: 'snd_numbers_21_50_7' },
  { val: 29, ol: 'ᱵᱟᱨ ᱜᱮᱞ ᱟᱨᱮ', latin: 'Bar Gel Are', numFileId: 'num_n_29', lessonFileId: 'snd_numbers_21_50_8' },
];

async function main() {
  console.log('🎙️  Starting audio regeneration for Santali numbers 20-29 (Bar Gel)...');
  const keys = await getActiveBodhanKeys();
  console.log(`✅ ${keys.length} active Bodhan keys loaded.`);

  for (const item of ITEMS) {
    const existingDoc = await getNumberDoc(`n_${item.val}`);
    if (existingDoc && existingDoc.nameLatin === item.latin) {
      console.log(`⏭️  [${item.val}] ${item.latin} already up-to-date in DB, skipping.`);
      continue;
    }

    console.log(`\n▶ [${item.val}] ${item.latin} (${item.ol})...`);
    console.log(`   Synthesizing via Bodhan AI with key rotation...`);
    const audioBuf = await synthesizeWithRotation(item.ol, keys);
    console.log(`   Audio synthesized: ${audioBuf.length} bytes`);

    console.log(`   Uploading to Appwrite Storage as ${item.numFileId}...`);
    const numUrl = await uploadToStorage(item.numFileId, `${item.numFileId}.wav`, audioBuf);
    console.log(`   Uploaded: ${numUrl}`);

    if (item.lessonFileId) {
      console.log(`   Uploading to Appwrite Storage as ${item.lessonFileId}...`);
      await uploadToStorage(item.lessonFileId, `${item.lessonFileId}.wav`, audioBuf);
      console.log(`   Lesson audio replaced: ${item.lessonFileId}`);
    }

    console.log(`   Updating numbers document n_${item.val} in DB...`);
    await updateNumberDoc(`n_${item.val}`, {
      nameLatin: item.latin,
      nameOlChiki: item.ol,
      audioUrl: numUrl,
    });
    console.log(`   Document n_${item.val} updated.`);

    // 2-second delay between items
    await new Promise((r) => setTimeout(r, 2000));
  }

  console.log('\n🎉 Successfully regenerated and updated all 10 numbers (20-29) with Bar Gel audio!');
}

main().catch((err) => {
  console.error('\n❌ Error:', err.message);
  process.exit(1);
});
