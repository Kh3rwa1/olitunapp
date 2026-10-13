-- Olitun Cloudflare D1 Database Schema
-- Provides sub-millisecond edge reads for curriculum and gamification

CREATE TABLE IF NOT EXISTS categories (
  id TEXT PRIMARY KEY,
  title_ol_chiki TEXT,
  title_latin TEXT,
  icon_name TEXT,
  gradient_preset TEXT,
  order_index INTEGER DEFAULT 0,
  is_active INTEGER DEFAULT 1,
  unlock_mode TEXT DEFAULT 'free',
  raw_json TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_categories_active_order ON categories(is_active, order_index);

CREATE TABLE IF NOT EXISTS letters (
  id TEXT PRIMARY KEY,
  letter_ol_chiki TEXT,
  letter_latin TEXT,
  audio_url TEXT,
  order_index INTEGER DEFAULT 0,
  raw_json TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_letters_order ON letters(order_index);

CREATE TABLE IF NOT EXISTS numbers (
  id TEXT PRIMARY KEY,
  number_ol_chiki TEXT,
  number_latin TEXT,
  val INTEGER,
  audio_url TEXT,
  raw_json TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_numbers_val ON numbers(val);

CREATE TABLE IF NOT EXISTS words (
  id TEXT PRIMARY KEY,
  word_ol_chiki TEXT,
  word_latin TEXT,
  meaning TEXT,
  category TEXT,
  audio_url TEXT,
  order_index INTEGER DEFAULT 0,
  raw_json TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_words_category ON words(category);

CREATE TABLE IF NOT EXISTS sentences (
  id TEXT PRIMARY KEY,
  sentence_ol_chiki TEXT,
  sentence_latin TEXT,
  translation TEXT,
  category TEXT,
  audio_url TEXT,
  order_index INTEGER DEFAULT 0,
  raw_json TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_sentences_category ON sentences(category);

CREATE TABLE IF NOT EXISTS lessons (
  id TEXT PRIMARY KEY,
  category_id TEXT,
  title_ol_chiki TEXT,
  title_latin TEXT,
  lesson_type TEXT,
  order_index INTEGER DEFAULT 0,
  raw_json TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_lessons_category ON lessons(category_id);

CREATE TABLE IF NOT EXISTS leaderboard_cache (
  id TEXT PRIMARY KEY,
  week_id TEXT NOT NULL,
  data_json TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS translation_cache (
  cache_key TEXT PRIMARY KEY,
  from_lang TEXT NOT NULL,
  to_lang TEXT NOT NULL,
  source_text TEXT NOT NULL,
  translated_text TEXT NOT NULL,
  engine TEXT NOT NULL,
  created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_translation_cache_key ON translation_cache(cache_key);
