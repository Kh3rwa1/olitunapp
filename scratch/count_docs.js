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
    const errText = await res.text();
    throw new Error(`HTTP Error ${res.status}: ${errText}`);
  }
  return await res.json();
}

async function run() {
  console.log('l_la:');
  console.log(await getDoc('letters', 'l_la'));
  
  console.log('\nletter_0_1778594018254000:');
  try {
    console.log(await getDoc('letters', 'letter_0_1778594018254000'));
  } catch (e) {
    console.log('Error fetching letter_0_1778594018254000:', e.message);
  }

  console.log('\nn_0:');
  console.log(await getDoc('numbers', 'n_0'));
  
  console.log('\nn0:');
  try {
    console.log(await getDoc('numbers', 'n0'));
  } catch (e) {
    console.log('Error fetching n0:', e.message);
  }
}

run().catch(e => console.error('Error running count:', e));
