import fs from 'fs';

const project = '699495910038e39622c5';
const endpoint = 'https://sgp.cloud.appwrite.io/v1';

// Read from prefs.json directly to avoid copy-paste errors
const prefs = JSON.parse(fs.readFileSync('/Users/dulorai/.appwrite/prefs.json', 'utf8'));
const session = prefs[project];
const activeCookie = session.cookie;

const headers = {
  'cookie': activeCookie,
  'x-appwrite-project': project,
  'x-appwrite-mode': 'admin',
};

async function getDoc(collectionId, docId) {
  const url = `${endpoint}/databases/olitun_db/collections/${collectionId}/documents/${docId}`;
  const res = await fetch(url, { headers });
  if (!res.ok) {
    return null;
  }
  return await res.json();
}

async function run() {
  const pairs = [
    { char: 'ᱚ', canonical: 'l_la', legacy: 'letter_a' },
    { char: 'ᱛ', canonical: 'l_at', legacy: 'letter_at' },
    { char: 'ᱜ', canonical: 'l_ag', legacy: 'letter_ag' },
  ];

  for (const pair of pairs) {
    console.log(`\n======================================================`);
    console.log(`Comparison for Character: ${pair.char}`);
    console.log(`======================================================`);
    const docCanonical = await getDoc('letters', pair.canonical);
    const docLegacy = await getDoc('letters', pair.legacy);

    if (docCanonical) {
      console.log(`✅ Canonical Document (${pair.canonical}):`);
      console.log(`   Translit: ${docCanonical.transliterationLatin}`);
      console.log(`   Image URL: ${docCanonical.imageUrl ? 'Populated' : 'NULL'}`);
      console.log(`   Tracing Config: ${docCanonical.tracing ? 'Populated' : 'NULL'}`);
      console.log(`   Hero Media: ${docCanonical.hero_media ? 'Populated' : 'NULL'}`);
      console.log(`   Blocks: ${docCanonical.blocks ? 'Populated' : 'NULL'}`);
    } else {
      console.log(`❌ Canonical Document (${pair.canonical}) not found!`);
    }

    if (docLegacy) {
      console.log(`⚠️ Legacy Document (${pair.legacy}):`);
      console.log(`   Translit: ${docLegacy.transliterationLatin}`);
      console.log(`   Image URL: ${docLegacy.imageUrl ? 'Populated' : 'NULL'}`);
      console.log(`   Tracing Config: ${docLegacy.tracing ? 'Populated' : 'NULL'}`);
      console.log(`   Hero Media: ${docLegacy.hero_media ? 'Populated' : 'NULL'}`);
      console.log(`   Blocks: ${docLegacy.blocks ? 'Populated' : 'NULL'}`);
    } else {
      console.log(`❌ Legacy Document (${pair.legacy}) not found!`);
    }
  }
}

run().catch(e => console.error(e));
