import fs from 'fs';

async function translateText(text, target) {
  if (!text || !text.trim()) return '';
  const trimmed = text.trim();

  // Try Google Translate with client rotation
  const clients = ['dict-chrome-ex', 'gtx', 't'];
  for (const client of clients) {
    try {
      const url = `https://translate.googleapis.com/translate_a/single?client=${client}&sl=en&tl=${target}&dt=t&q=${encodeURIComponent(trimmed)}`;
      const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
      if (res.ok) {
        const data = await res.json();
        if (data && data[0] && Array.isArray(data[0])) {
          const result = data[0].map(item => item[0]).join('').trim();
          if (result) return result;
        }
      }
    } catch (_) {}
  }

  // Fallback to MyMemory API
  try {
    const mmUrl = `https://api.mymemory.translated.net/get?q=${encodeURIComponent(trimmed)}&langpair=en|${target}`;
    const res = await fetch(mmUrl, { headers: { 'User-Agent': 'Mozilla/5.0' } });
    if (res.ok) {
      const data = await res.json();
      if (data?.responseData?.translatedText) {
        const result = data.responseData.translatedText.trim();
        // Ignore warning or error text from mymemory
        if (!result.includes('MYMEMORY WARNING') && !result.includes('QUERY LENGTH LIMIT')) {
          return result;
        }
      }
    }
  } catch (_) {}

  return '';
}

const CACHE_FILE = 'scripts/translations_cache.json';
let cache = { sentences: {}, words: {} };
if (fs.existsSync(CACHE_FILE)) {
  try {
    cache = JSON.parse(fs.readFileSync(CACHE_FILE, 'utf8'));
  } catch (_) {}
}
if (!cache.sentences) cache.sentences = {};
if (!cache.words) cache.words = {};

const sentencesToTranslate = JSON.parse(fs.readFileSync('scripts/unique_sentences_to_translate.json', 'utf8'));
const wordsToTranslate = JSON.parse(fs.readFileSync('scripts/unique_words_to_translate.json', 'utf8'));

console.log(`Processing ${sentencesToTranslate.length} sentences and ${wordsToTranslate.length} words...`);

async function processList(list, cacheCategory) {
  let count = 0;
  for (let i = 0; i < list.length; i++) {
    const item = list[i];
    const rawMeaning = (item.meaning || '').trim();
    if (!rawMeaning) continue;

    const key = rawMeaning.toLowerCase();
    const existing = cache[cacheCategory][key];

    if (!existing || !existing.bn || !existing.hi || !existing.or) {
      try {
        const bn = (existing && existing.bn) ? existing.bn : await translateText(rawMeaning, 'bn');
        await new Promise(r => setTimeout(r, 60));
        const hi = (existing && existing.hi) ? existing.hi : await translateText(rawMeaning, 'hi');
        await new Promise(r => setTimeout(r, 60));
        const or = (existing && existing.or) ? existing.or : await translateText(rawMeaning, 'or');
        await new Promise(r => setTimeout(r, 60));

        if (bn && hi && or) {
          cache[cacheCategory][key] = { bn, hi, or, en: rawMeaning };

          const strippedKey = key.replace(/[?.!,]+$/, '').trim();
          if (strippedKey && strippedKey !== key) {
            cache[cacheCategory][strippedKey] = {
              bn: bn.replace(/[।?.!,| ]+$/, '').trim(),
              hi: hi.replace(/[।?.!,| ]+$/, '').trim(),
              or: or.replace(/[।?.!,| ]+$/, '').trim(),
              en: rawMeaning.replace(/[?.!,]+$/, '').trim(),
            };
          }
        }

        count++;
        if (count % 10 === 0 || i === list.length - 1) {
          console.log(`[${i + 1}/${list.length}] Translated: "${rawMeaning.slice(0, 30)}" -> BN: "${(bn || '').slice(0, 25)}"`);
          fs.writeFileSync(CACHE_FILE, JSON.stringify(cache, null, 2), 'utf8');
        }
      } catch (err) {
        console.error(`Error translating "${rawMeaning}":`, err.message);
      }
    }
  }
}

console.log('--- Translating Sentences ---');
await processList(sentencesToTranslate, 'sentences');

console.log('--- Translating Words ---');
await processList(wordsToTranslate, 'words');

fs.writeFileSync(CACHE_FILE, JSON.stringify(cache, null, 2), 'utf8');
console.log('✅ Translation cache fully updated!');
