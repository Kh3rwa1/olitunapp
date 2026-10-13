const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const seedDir = path.resolve(__dirname, '../../assets/seed');
const sqlFile = path.resolve(__dirname, 'seed.sql');

function escapeSql(val) {
  if (val === null || val === undefined) return 'NULL';
  if (typeof val === 'number') return val;
  if (typeof val === 'boolean') return val ? 1 : 0;
  return "'" + String(val).replace(/'/g, "''") + "'";
}

let sql = '-- Auto-generated seed data for Olitun D1\n\n';

// 1. Categories
const categoriesPath = path.join(seedDir, 'categories.json');
if (fs.existsSync(categoriesPath)) {
  const categories = JSON.parse(fs.readFileSync(categoriesPath, 'utf8'));
  for (const c of categories) {
    const rawJson = JSON.stringify(c);
    sql += `INSERT OR REPLACE INTO categories (id, title_ol_chiki, title_latin, icon_name, gradient_preset, order_index, is_active, unlock_mode, raw_json) VALUES (${escapeSql(c.id)}, ${escapeSql(c.titleOlChiki)}, ${escapeSql(c.titleLatin)}, ${escapeSql(c.iconName)}, ${escapeSql(c.gradientPreset)}, ${c.orderIndex ?? c.order ?? 0}, ${c.isActive ? 1 : 0}, ${escapeSql(c.unlockMode || 'free')}, ${escapeSql(rawJson)});\n`;
  }
}

// 2. Letters
const lettersPath = path.join(seedDir, 'letters.json');
if (fs.existsSync(lettersPath)) {
  const letters = JSON.parse(fs.readFileSync(lettersPath, 'utf8'));
  for (const l of letters) {
    const rawJson = JSON.stringify(l);
    sql += `INSERT OR REPLACE INTO letters (id, letter_ol_chiki, letter_latin, audio_url, order_index, raw_json) VALUES (${escapeSql(l.id || l.$id)}, ${escapeSql(l.letterOlChiki || l.olChiki)}, ${escapeSql(l.letterLatin || l.latin)}, ${escapeSql(l.audioUrl)}, ${l.orderIndex ?? 0}, ${escapeSql(rawJson)});\n`;
  }
}

// 3. Numbers
const numbersPath = path.join(seedDir, 'numbers.json');
if (fs.existsSync(numbersPath)) {
  const numbers = JSON.parse(fs.readFileSync(numbersPath, 'utf8'));
  for (const n of numbers) {
    const rawJson = JSON.stringify(n);
    sql += `INSERT OR REPLACE INTO numbers (id, number_ol_chiki, number_latin, val, audio_url, raw_json) VALUES (${escapeSql(n.id || n.$id)}, ${escapeSql(n.numberOlChiki || n.olChiki)}, ${escapeSql(n.numberLatin || n.latin)}, ${n.value ?? n.val ?? 0}, ${escapeSql(n.audioUrl)}, ${escapeSql(rawJson)});\n`;
  }
}

// 4. Words
const wordsPath = path.join(seedDir, 'words.json');
if (fs.existsSync(wordsPath)) {
  const words = JSON.parse(fs.readFileSync(wordsPath, 'utf8'));
  for (const w of words) {
    const rawJson = JSON.stringify(w);
    sql += `INSERT OR REPLACE INTO words (id, word_ol_chiki, word_latin, meaning, category, audio_url, order_index, raw_json) VALUES (${escapeSql(w.id || w.$id)}, ${escapeSql(w.wordOlChiki)}, ${escapeSql(w.wordLatin)}, ${escapeSql(w.meaning)}, ${escapeSql(w.category)}, ${escapeSql(w.audioUrl)}, ${w.orderIndex ?? w.order ?? 0}, ${escapeSql(rawJson)});\n`;
  }
}

// 5. Sentences
const sentencesPath = path.join(seedDir, 'sentences.json');
if (fs.existsSync(sentencesPath)) {
  const sentences = JSON.parse(fs.readFileSync(sentencesPath, 'utf8'));
  for (const s of sentences) {
    const rawJson = JSON.stringify(s);
    sql += `INSERT OR REPLACE INTO sentences (id, sentence_ol_chiki, sentence_latin, translation, category, audio_url, order_index, raw_json) VALUES (${escapeSql(s.id || s.$id)}, ${escapeSql(s.sentenceOlChiki || s.santaliOlChiki)}, ${escapeSql(s.sentenceLatin || s.santaliLatin)}, ${escapeSql(s.translation || s.englishMeaning)}, ${escapeSql(s.category)}, ${escapeSql(s.audioUrl)}, ${s.orderIndex ?? 0}, ${escapeSql(rawJson)});\n`;
  }
}

// 6. Lessons
const lessonsPath = path.join(seedDir, 'lessons.json');
if (fs.existsSync(lessonsPath)) {
  const lessons = JSON.parse(fs.readFileSync(lessonsPath, 'utf8'));
  for (const l of lessons) {
    const rawJson = JSON.stringify(l);
    sql += `INSERT OR REPLACE INTO lessons (id, category_id, title_ol_chiki, title_latin, lesson_type, order_index, raw_json) VALUES (${escapeSql(l.id || l.$id)}, ${escapeSql(l.categoryId || l.category)}, ${escapeSql(l.titleOlChiki)}, ${escapeSql(l.titleLatin)}, ${escapeSql(l.type || l.lessonType)}, ${l.orderIndex ?? l.order ?? 0}, ${escapeSql(rawJson)});\n`;
  }
}

fs.writeFileSync(sqlFile, sql, 'utf8');
console.log(`Generated ${sqlFile} (${(sql.length / 1024).toFixed(1)} KB)`);
