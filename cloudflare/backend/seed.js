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

// 7. Rhymes (Bakhed Prayers)
const rhymesPath = path.join(seedDir, 'rhymes.json');
if (fs.existsSync(rhymesPath)) {
  const rhymes = JSON.parse(fs.readFileSync(rhymesPath, 'utf8'));
  for (let idx = 0; idx < rhymes.length; idx++) {
    const r = rhymes[idx];
    const rawJson = JSON.stringify(r);
    sql += `INSERT OR REPLACE INTO rhymes (id, title_ol_chiki, title_latin, content_ol_chiki, content_latin, audio_url, thumbnail_url, category, is_premium, order_index, raw_json) VALUES (${escapeSql(r.id || r.$id)}, ${escapeSql(r.titleOlChiki)}, ${escapeSql(r.titleLatin)}, ${escapeSql(r.contentOlChiki)}, ${escapeSql(r.contentLatin)}, ${escapeSql(r.audioUrl)}, ${escapeSql(r.thumbnailUrl)}, ${escapeSql(r.category)}, ${r.isPremium ? 1 : 0}, ${r.orderIndex ?? r.order ?? idx}, ${escapeSql(rawJson)});\n`;
  }
}

// 8. Banners
const bannersPath = path.join(seedDir, 'banners.json');
if (fs.existsSync(bannersPath)) {
  const banners = JSON.parse(fs.readFileSync(bannersPath, 'utf8'));
  for (let idx = 0; idx < banners.length; idx++) {
    const b = banners[idx];
    const rawJson = JSON.stringify(b);
    sql += `INSERT OR REPLACE INTO banners (id, title, order_index, is_active, raw_json) VALUES (${escapeSql(b.id || b.$id)}, ${escapeSql(b.title)}, ${b.orderIndex ?? b.order ?? idx}, ${b.isActive !== false ? 1 : 0}, ${escapeSql(rawJson)});\n`;
  }
}

// 9. Quizzes
const quizzesPath = path.join(seedDir, 'quizzes.json');
if (fs.existsSync(quizzesPath)) {
  const quizzes = JSON.parse(fs.readFileSync(quizzesPath, 'utf8'));
  for (let idx = 0; idx < quizzes.length; idx++) {
    const q = quizzes[idx];
    const rawJson = JSON.stringify(q);
    sql += `INSERT OR REPLACE INTO quizzes (id, category_id, level, order_index, is_active, raw_json) VALUES (${escapeSql(q.id || q.$id)}, ${escapeSql(q.categoryId || q.category)}, ${escapeSql(q.level || 'beginner')}, ${q.orderIndex ?? q.order ?? idx}, ${q.isActive !== false ? 1 : 0}, ${escapeSql(rawJson)});\n`;
  }
}

// 10. App Settings
const settingsPath = path.join(seedDir, 'app_settings.json');
if (fs.existsSync(settingsPath)) {
  const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
  for (const s of settings) {
    const key = s.settingKey || s.setting_key || s.key;
    const val = s.settingValue || s.setting_value || s.value || '';
    const rawJson = JSON.stringify(s);
    if (key) {
      sql += `INSERT OR REPLACE INTO app_settings (setting_key, setting_value, raw_json) VALUES (${escapeSql(key)}, ${escapeSql(val)}, ${escapeSql(rawJson)});\n`;
    }
  }
}

// 11. Gamification Content
const gamificationPath = path.join(seedDir, 'gamification_content.json');
if (fs.existsSync(gamificationPath)) {
  const gamification = JSON.parse(fs.readFileSync(gamificationPath, 'utf8'));
  const rawJson = JSON.stringify(gamification);
  sql += `INSERT OR REPLACE INTO gamification_content (id, raw_json) VALUES ('default', ${escapeSql(rawJson)});\n`;
}

// 12. Bakhed Content
const bakhedPath = path.join(seedDir, 'bakhed_content.json');
if (fs.existsSync(bakhedPath)) {
  const bakheds = JSON.parse(fs.readFileSync(bakhedPath, 'utf8'));
  for (const b of bakheds) {
    const id = b.id || b.bakhedId;
    if (id) {
      const rawJson = JSON.stringify(b);
      sql += `INSERT OR REPLACE INTO bakhed_content (bakhed_id, raw_json) VALUES (${escapeSql(id)}, ${escapeSql(rawJson)});\n`;
    }
  }
}

// 13-15. Learner audio tracks, localizations, story segments (Appwrite
// exports of audio_tracks / localized_contents / story_segments).
function readSeed(name) {
  const file = path.join(seedDir, name);
  return fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, 'utf8')) : [];
}

for (const t of readSeed('audio_tracks.json')) {
  const id = t.id || t.$id;
  if (!id || !t.contentKind || !t.contentId) continue;
  sql += `INSERT OR REPLACE INTO content_audio_tracks (id, content_kind, content_id, segment_id, language_code, track_type, review_status, created_at, raw_json) VALUES (${escapeSql(id)}, ${escapeSql(t.contentKind)}, ${escapeSql(t.contentId)}, ${escapeSql(t.segmentId)}, ${escapeSql(t.languageCode || '')}, ${escapeSql(t.trackType || '')}, ${escapeSql(t.reviewStatus || 'needsReview')}, ${escapeSql(t.createdAt || t.$createdAt)}, ${escapeSql(JSON.stringify(t))});\n`;
}

for (const l of readSeed('localized_contents.json')) {
  const id = l.id || l.$id;
  if (!id || !l.contentKind || !l.contentId || !l.languageCode) continue;
  sql += `INSERT OR REPLACE INTO content_localizations (id, content_kind, content_id, language_code, review_status, raw_json) VALUES (${escapeSql(id)}, ${escapeSql(l.contentKind)}, ${escapeSql(l.contentId)}, ${escapeSql(l.languageCode)}, ${escapeSql(l.reviewStatus || 'needsReview')}, ${escapeSql(JSON.stringify(l))});\n`;
}

for (const s of readSeed('story_segments.json')) {
  const id = s.id || s.$id;
  if (!id || !s.storyId) continue;
  sql += `INSERT OR REPLACE INTO story_segments (id, story_id, order_index, raw_json) VALUES (${escapeSql(id)}, ${escapeSql(s.storyId)}, ${Number(s.order) || 0}, ${escapeSql(JSON.stringify(s))});\n`;
}

fs.writeFileSync(sqlFile, sql, 'utf8');
console.log(`Generated ${sqlFile} (${(sql.length / 1024).toFixed(1)} KB)`);
