#!/usr/bin/env node

/**
 * Sync Google Sheet Affirmations to Appwrite Database
 * Usage:
 *   APPWRITE_API_KEY=your_key node scripts/sync_google_sheet_affirmations.mjs
 */

import { readFileSync } from 'fs';
import { createHash, randomUUID } from 'crypto';

function readProjectIdFromConfig() {
  try {
    const raw = readFileSync(new URL('../appwrite.json', import.meta.url), 'utf8');
    return JSON.parse(raw).projectId || '';
  } catch (_) {
    return '';
  }
}

const ENDPOINT = process.env.APPWRITE_ENDPOINT || 'https://sgp.cloud.appwrite.io/v1';
const PROJECT_ID = process.env.APPWRITE_PROJECT_ID || readProjectIdFromConfig();
const API_KEY = process.env.APPWRITE_API_KEY;
const DB = 'olitun_db';
const COLLECTION = 'daily_affirmations';
const SHEET_URL = process.env.GOOGLE_SHEET_CSV_URL ||
  'https://docs.google.com/spreadsheets/d/1zJXlcPzXtWxHyvpifqnA832HR2L5DCTX8RmnfypBxOk/gviz/tq?tqx=out:csv';

if (!PROJECT_ID) {
  console.error('❌ Set APPWRITE_PROJECT_ID or appwrite.json projectId');
  process.exit(1);
}

if (!API_KEY) {
  console.error('❌ Set APPWRITE_API_KEY environment variable. Example:');
  console.error('   APPWRITE_API_KEY=your_key node scripts/sync_google_sheet_affirmations.mjs');
  process.exit(1);
}

const headers = {
  'Content-Type': 'application/json',
  'X-Appwrite-Project': PROJECT_ID,
  'X-Appwrite-Key': API_KEY,
};

function parseCSV(csvText) {
  const rows = [];
  let currentRow = [];
  let currentCell = '';
  let inQuotes = false;
  let i = 0;

  while (i < csvText.length) {
    const char = csvText[i];
    const nextChar = csvText[i + 1];

    if (inQuotes) {
      if (char === '"' && nextChar === '"') {
        currentCell += '"';
        i += 2;
      } else if (char === '"') {
        inQuotes = false;
        i++;
      } else {
        currentCell += char;
        i++;
      }
    } else {
      if (char === '"') {
        inQuotes = true;
        i++;
      } else if (char === ',') {
        currentRow.push(currentCell.trim());
        currentCell = '';
        i++;
      } else if (char === '\r' && nextChar === '\n') {
        currentRow.push(currentCell.trim());
        currentCell = '';
        rows.push(currentRow);
        currentRow = [];
        i += 2;
      } else if (char === '\n' || char === '\r') {
        currentRow.push(currentCell.trim());
        currentCell = '';
        rows.push(currentRow);
        currentRow = [];
        i++;
      } else {
        currentCell += char;
        i++;
      }
    }
  }

  if (currentCell.length > 0 || currentRow.length > 0) {
    currentRow.push(currentCell.trim());
    rows.push(currentRow);
  }

  return rows;
}

async function run() {
  console.log(`📡 Fetching live CSV from Google Sheet...`);
  const res = await fetch(SHEET_URL);
  if (!res.ok) throw new Error(`Fetch failed: HTTP ${res.status}`);
  const csv = await res.text();
  const rows = parseCSV(csv);

  if (rows.length <= 1) {
    console.log(`⚠️ No data rows found in Google Sheet.`);
    return;
  }

  console.log(`📊 Found ${rows.length - 1} data row(s) in sheet. Syncing to Appwrite...`);

  // Fetch existing affirmations to get current count & orders
  const listRes = await fetch(`${ENDPOINT}/databases/${DB}/collections/${COLLECTION}/documents?limit=100`, {
    headers,
  });
  const existingData = await listRes.json();
  const existingDocs = existingData.documents || [];
  const existingHashes = new Set(
    existingDocs.map((d) => `${d.olChikiText}|${d.santaliPhonetic}`)
  );

  let currentOrder = existingDocs.reduce((max, d) => Math.max(max, d.order || 0), 0);

  for (let r = 1; r < rows.length; r++) {
    const row = rows[r];
    const olChikiText = (row[0] || '').trim();
    const santaliPhonetic = (row[1] || '').trim();
    const englishMeaning = (row[2] || '').trim();
    const category = (row[3] || 'identity').trim().toLowerCase() || 'identity';
    const audioUrl = (row[4] || '').trim() || null;
    const isPremium = (row[5] || '').trim().toLowerCase() === 'true';

    if (!olChikiText || !santaliPhonetic || !englishMeaning) continue;

    const hashKey = `${olChikiText}|${santaliPhonetic}`;
    if (existingHashes.has(hashKey)) {
      console.log(`⏩ [Skip Existing]: ${santaliPhonetic}`);
      continue;
    }

    currentOrder++;
    const docId = randomUUID().replace(/-/g, '').slice(0, 32);
    const nowIso = new Date().toISOString();

    const docPayload = {
      olChikiText,
      santaliPhonetic,
      englishMeaning,
      category,
      audioUrl,
      isPremium,
      order: currentOrder,
      publishedAt: nowIso,
    };

    const createRes = await fetch(`${ENDPOINT}/databases/${DB}/collections/${COLLECTION}/documents`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ documentId: docId, data: docPayload }),
    });

    if (!createRes.ok) {
      const errText = await createRes.text();
      console.error(`❌ Failed to insert "${santaliPhonetic}": ${errText}`);
    } else {
      console.log(`✅ [Inserted]: "${olChikiText}" (${santaliPhonetic}) -> Order: ${currentOrder}`);
      existingHashes.add(hashKey);
    }
  }

  console.log(`✨ Google Sheet sync completed!`);
}

run().catch((err) => {
  console.error(`❌ Error:`, err.message);
  process.exit(1);
});
