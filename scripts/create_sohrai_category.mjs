import { readFileSync } from 'fs';

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
const DATABASE_ID = 'olitun_db';

if (!PROJECT_ID || !API_KEY) {
  console.error('❌ Error: Set APPWRITE_PROJECT_ID and APPWRITE_API_KEY');
  process.exit(1);
}

const headers = {
  'Content-Type': 'application/json',
  'X-Appwrite-Project': PROJECT_ID,
  'X-Appwrite-Key': API_KEY,
};

async function api(method, path, body = null) {
  const opts = { method, headers };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(`${ENDPOINT}${path}`, opts);
  const text = await res.text();
  if (!res.ok) {
    throw new Error(`${res.status} ${method} ${path}: ${text}`);
  }
  return text ? JSON.parse(text) : null;
}

async function run() {
  console.log('Checking if Sohrai category exists...');
  const listRes = await api('GET', `/databases/${DATABASE_ID}/collections/categories/documents?limit=100`);
  const docs = listRes.documents || [];
  const exists = docs.some(d => (d.titleLatin || '').toLowerCase() === 'sohrai');
  
  if (exists) {
    console.log('✅ Sohrai category already exists!');
    return;
  }
  
  console.log('Creating Sohrai category...');
  const payload = {
    titleLatin: 'Sohrai',
    titleOlChiki: 'ᱥᱚᱦᱨᱟᱭ',
    iconName: 'stories',
    order: 5,
    isActive: true,
    totalLessons: 0,
    description: 'Sohrai stories and rhymes',
    unlockMode: 'free',
    priceInr: 0,
    previewLessonCount: 3,
  };
  
  const created = await api('POST', `/databases/${DATABASE_ID}/collections/categories/documents`, {
    documentId: 'cat_sohrai',
    data: payload
  });
  console.log('🎉 Created Sohrai category:', created.$id);
}

run().catch(e => console.error('❌ Error:', e));
