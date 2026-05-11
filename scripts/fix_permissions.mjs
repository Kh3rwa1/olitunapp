import { readFileSync } from 'fs';

function readProjectIdFromConfig() {
  try {
    const raw = readFileSync(new URL('../appwrite.config.json', import.meta.url), 'utf8');
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
  console.error('❌ Set APPWRITE_PROJECT_ID and APPWRITE_API_KEY environment variables');
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

const collectionsToFix = [
  'categories',
  'lessons',
  'quizzes',
  'letters',
  'numbers',
  'words',
  'sentences',
  'rhymes',
  'rhyme_categories',
  'rhyme_subcategories',
  'banners'
];

async function fixPermissions() {
  console.log('🚀 Fixing document permissions...');
  
  for (const collectionId of collectionsToFix) {
    console.log(`\n📋 Processing collection: ${collectionId}`);
    
    try {
      // Get all documents in the collection
      let offset = 0;
      let hasMore = true;
      let count = 0;
      
      while (hasMore) {
        const query = `queries[]=limit(100)&queries[]=offset(${offset})`;
        const res = await api('GET', `/databases/${DATABASE_ID}/collections/${collectionId}/documents?${query}`);
        
        if (!res.documents || res.documents.length === 0) {
          hasMore = false;
          continue;
        }
        
        for (const doc of res.documents) {
          // Check if it already has read("any")
          if (!doc.$permissions.includes('read("any")')) {
            const newPermissions = [...doc.$permissions, 'read("any")'];
            
            // Update the document with new permissions
            await api('PATCH', `/databases/${DATABASE_ID}/collections/${collectionId}/documents/${doc.$id}`, {
              permissions: newPermissions
            });
            count++;
            console.log(`  ✅ Fixed permissions for document: ${doc.$id}`);
          }
        }
        
        offset += res.documents.length;
        if (res.documents.length < 100) hasMore = false;
      }
      
      console.log(`✨ Collection ${collectionId} complete. Updated ${count} documents.`);
    } catch (e) {
      console.error(`❌ Error processing ${collectionId}:`, e.message);
    }
  }
  
  console.log('\n🎉 All permissions fixed successfully!');
}

fixPermissions().catch(err => {
  console.error('\n❌ Script failed:', err.message);
  process.exit(1);
});
