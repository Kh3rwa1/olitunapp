import fs from 'fs';

const cache = JSON.parse(fs.readFileSync('scripts/translations_cache.json', 'utf8'));

function getTranslation(meaning, lang, isWord = false) {
  if (!meaning) return '';
  const key = meaning.trim().toLowerCase();
  const strippedKey = key.replace(/[?.!,]+$/, '').trim();

  const source = isWord ? cache.words : cache.sentences;
  const altSource = isWord ? cache.sentences : cache.words;

  const found = source[key] || source[strippedKey] || altSource[key] || altSource[strippedKey];
  if (found && found[lang]) return found[lang];
  return '';
}

// 1. Enrich sentence_lessons.json
const slFile = 'assets/seed/sentence_lessons.json';
const sl = JSON.parse(fs.readFileSync(slFile, 'utf8'));

sl.forEach(lesson => {
  (lesson.blocks || []).forEach(block => {
    const rawMeaning = (block.data?.meaning || '').trim();
    if (rawMeaning) {
      if (!block.data) block.data = {};
      block.data.meaning_bn = getTranslation(rawMeaning, 'bn') || block.data.meaning_bn || '';
      block.data.meaning_hi = getTranslation(rawMeaning, 'hi') || block.data.meaning_hi || '';
      block.data.meaning_or = getTranslation(rawMeaning, 'or') || block.data.meaning_or || '';
      block.data.meaning_en = rawMeaning;
    }
  });
});

fs.writeFileSync(slFile, JSON.stringify(sl, null, 2), 'utf8');
console.log('✅ Enriched sentence_lessons.json');

// 2. Enrich vocab_lessons.json
const vlFile = 'assets/seed/vocab_lessons.json';
const vl = JSON.parse(fs.readFileSync(vlFile, 'utf8'));

vl.forEach(lesson => {
  (lesson.blocks || []).forEach(block => {
    const rawMeaning = (block.data?.meaning || '').trim();
    if (rawMeaning) {
      if (!block.data) block.data = {};
      block.data.meaning_bn = getTranslation(rawMeaning, 'bn', true) || block.data.meaning_bn || '';
      block.data.meaning_hi = getTranslation(rawMeaning, 'hi', true) || block.data.meaning_hi || '';
      block.data.meaning_or = getTranslation(rawMeaning, 'or', true) || block.data.meaning_or || '';
      block.data.meaning_en = rawMeaning;
    }
  });
});

fs.writeFileSync(vlFile, JSON.stringify(vl, null, 2), 'utf8');
console.log('✅ Enriched vocab_lessons.json');

// 3. Enrich sentences.json
const sFile = 'assets/seed/sentences.json';
const s = JSON.parse(fs.readFileSync(sFile, 'utf8'));

s.forEach(item => {
  const rawMeaning = (item.meaning || '').trim();
  if (rawMeaning) {
    item.meaning_bn = getTranslation(rawMeaning, 'bn') || item.meaning_bn || '';
    item.meaning_hi = getTranslation(rawMeaning, 'hi') || item.meaning_hi || '';
    item.meaning_or = getTranslation(rawMeaning, 'or') || item.meaning_or || '';
  }
});

fs.writeFileSync(sFile, JSON.stringify(s, null, 2), 'utf8');
console.log('✅ Enriched sentences.json');

// 4. Enrich words.json
const wFile = 'assets/seed/words.json';
const w = JSON.parse(fs.readFileSync(wFile, 'utf8'));

w.forEach(item => {
  const rawMeaning = (item.meaning || '').trim();
  if (rawMeaning) {
    item.meaning_bn = getTranslation(rawMeaning, 'bn', true) || item.meaning_bn || '';
    item.meaning_hi = getTranslation(rawMeaning, 'hi', true) || item.meaning_hi || '';
    item.meaning_or = getTranslation(rawMeaning, 'or', true) || item.meaning_or || '';
  }
});

fs.writeFileSync(wFile, JSON.stringify(w, null, 2), 'utf8');
console.log('✅ Enriched words.json');
