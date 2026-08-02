#!/usr/bin/env node

import { readFileSync } from 'fs';

const PROJECT_ID = '699495910038e39622c5';
const DATABASE_ID = 'olitun_db';
const ENDPOINT = 'https://sgp.cloud.appwrite.io/v1';

let activeCookie;
try {
  const prefs = JSON.parse(readFileSync('/Users/dulorai/.appwrite/prefs.json', 'utf8'));
  const session = prefs[PROJECT_ID];
  activeCookie = session.cookie;
  if (!activeCookie) {
    throw new Error('No active session cookie found in prefs.json.');
  }
} catch (e) {
  console.error(`❌ Failed to read Appwrite console session: ${e.message}`);
  process.exit(1);
}

const headers = {
  'cookie': activeCookie,
  'x-appwrite-project': PROJECT_ID,
  'x-appwrite-mode': 'admin',
  'Content-Type': 'application/json',
};

async function api(method, path, body = null) {
  const opts = { method, headers };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(`${ENDPOINT}${path}`, opts);
  const text = await res.text();
  if (!res.ok) {
    throw new Error(`HTTP ${res.status} ${method} ${path}: ${text}`);
  }
  return text ? JSON.parse(text) : null;
}

async function getAllDocuments(collectionId) {
  let documents = [];
  let offset = 0;
  let hasMore = true;
  
  while (hasMore) {
    const params = new URLSearchParams();
    params.append('queries[]', JSON.stringify({ method: 'limit', values: [100] }));
    params.append('queries[]', JSON.stringify({ method: 'offset', values: [offset] }));
    
    const res = await api('GET', `/databases/${DATABASE_ID}/collections/${collectionId}/documents?${params.toString()}`);
    const docs = res.documents || [];
    documents = documents.concat(docs);
    
    if (docs.length < 100) {
      hasMore = false;
    } else {
      offset += docs.length;
    }
  }
  return documents;
}

async function run() {
  console.log('🔍 Executing Read-Only Database Audit...\n');

  const letters = await getAllDocuments('letters');
  const numbers = await getAllDocuments('numbers');

  console.log(`================ LETTERS AUDIT ================`);
  console.log(`Total Document Count: ${letters.length}`);
  
  // Prefix breakdown
  const lettersPrefixes = {
    'l_ (Canonical)': [],
    'letter_ (Legacy 1)': [],
    'letter_X_ (Legacy 2)': [],
    'Others': []
  };

  for (const doc of letters) {
    const id = doc.$id;
    if (id.startsWith('l_')) {
      lettersPrefixes['l_ (Canonical)'].push(doc);
    } else if (id.startsWith('letter_') && /letter_\d_/.test(id)) {
      lettersPrefixes['letter_X_ (Legacy 2)'].push(doc);
    } else if (id.startsWith('letter_')) {
      lettersPrefixes['letter_ (Legacy 1)'].push(doc);
    } else {
      lettersPrefixes['Others'].push(doc);
    }
  }

  for (const [prefix, list] of Object.entries(lettersPrefixes)) {
    console.log(`   - Prefix ${prefix.padEnd(25)}: ${list.length} docs`);
  }

  // Group by character
  const lettersByChar = {};
  for (const doc of letters) {
    const char = doc.charOlChiki || doc.olChiki || 'empty';
    if (!lettersByChar[char]) lettersByChar[char] = [];
    lettersByChar[char].push(doc);
  }

  console.log('\nGroup Size Breakdown (by Ol Chiki Character):');
  for (const [char, docs] of Object.entries(lettersByChar)) {
    console.log(`   - Char "${char}": ${docs.length} docs`);
    docs.sort((a, b) => new Date(a.$createdAt) - new Date(b.$createdAt));
    for (const d of docs) {
      console.log(`       * ID: ${d.$id.padEnd(35)} Created: ${d.$createdAt}  Label: ${d.transliterationLatin || 'none'}`);
    }
  }

  console.log(`\n================ NUMBERS AUDIT ================`);
  console.log(`Total Document Count: ${numbers.length}`);

  // Prefix breakdown
  const numbersPrefixes = {
    'n_ (Canonical)': [],
    'n[digit] (Legacy)': [],
    'Others': []
  };

  for (const doc of numbers) {
    const id = doc.$id;
    if (id.startsWith('n_')) {
      numbersPrefixes['n_ (Canonical)'].push(doc);
    } else if (/^n\d+$/.test(id)) {
      numbersPrefixes['n[digit] (Legacy)'].push(doc);
    } else {
      numbersPrefixes['Others'].push(doc);
    }
  }

  for (const [prefix, list] of Object.entries(numbersPrefixes)) {
    console.log(`   - Prefix ${prefix.padEnd(25)}: ${list.length} docs`);
  }

  // Group by value
  const numbersByVal = {};
  for (const doc of numbers) {
    const val = doc.value !== undefined ? doc.value : 'empty';
    if (!numbersByVal[val]) numbersByVal[val] = [];
    numbersByVal[val].push(doc);
  }

  console.log('\nGroup Size Breakdown (by Numeric Value):');
  for (const [val, docs] of Object.entries(numbersByVal)) {
    console.log(`   - Value "${val}": ${docs.length} docs`);
    docs.sort((a, b) => new Date(a.$createdAt) - new Date(b.$createdAt));
    for (const d of docs) {
      console.log(`       * ID: ${d.$id.padEnd(35)} Created: ${d.$createdAt}  Label: ${d.nameLatin || 'none'}  OlChiki: ${d.nameOlChiki || 'none'}`);
    }
  }
}

run().catch(e => console.error(e));
