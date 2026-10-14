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

CREATE TABLE IF NOT EXISTS rhymes (
  id TEXT PRIMARY KEY,
  title_ol_chiki TEXT,
  title_latin TEXT,
  content_ol_chiki TEXT,
  content_latin TEXT,
  audio_url TEXT,
  thumbnail_url TEXT,
  category TEXT,
  is_premium INTEGER DEFAULT 0,
  order_index INTEGER DEFAULT 0,
  raw_json TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_rhymes_category ON rhymes(category);
CREATE INDEX IF NOT EXISTS idx_rhymes_order ON rhymes(order_index);

CREATE TABLE IF NOT EXISTS banners (
  id TEXT PRIMARY KEY,
  title TEXT,
  order_index INTEGER DEFAULT 0,
  is_active INTEGER DEFAULT 1,
  raw_json TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_banners_order ON banners(order_index);

CREATE TABLE IF NOT EXISTS quizzes (
  id TEXT PRIMARY KEY,
  category_id TEXT,
  level TEXT,
  order_index INTEGER DEFAULT 0,
  is_active INTEGER DEFAULT 1,
  raw_json TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_quizzes_order ON quizzes(order_index);

CREATE TABLE IF NOT EXISTS app_settings (
  setting_key TEXT PRIMARY KEY,
  setting_value TEXT NOT NULL,
  raw_json TEXT NOT NULL
);

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

-- User Mistakes
CREATE TABLE IF NOT EXISTS user_mistakes (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  quiz_id TEXT NOT NULL,
  question_id TEXT NOT NULL,
  question_index INTEGER DEFAULT 0,
  wrong_answer TEXT,
  correct_answer TEXT,
  question_snapshot TEXT,
  times_missed INTEGER DEFAULT 1,
  times_reviewed INTEGER DEFAULT 0,
  is_mastered INTEGER DEFAULT 0,
  mastered_at TEXT,
  last_missed_at TEXT,
  last_reviewed_at TEXT
);
CREATE INDEX IF NOT EXISTS idx_user_mistakes_user ON user_mistakes(user_id, is_mastered);

-- Mistake Review Sessions
CREATE TABLE IF NOT EXISTS mistake_review_sessions (
  session_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  question_ids TEXT,
  score INTEGER,
  total INTEGER,
  completed_at TEXT
);
CREATE INDEX IF NOT EXISTS idx_mistake_review_user ON mistake_review_sessions(user_id);

-- Bakhed Listening Progress
CREATE TABLE IF NOT EXISTS bakhed_listening_progress (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  bakhed_id TEXT NOT NULL,
  listened_percent INTEGER DEFAULT 0,
  completed_80_percent INTEGER DEFAULT 0,
  completed_at TEXT,
  last_position_ms INTEGER DEFAULT 0,
  updated_at TEXT
);
CREATE INDEX IF NOT EXISTS idx_bakhed_progress_user ON bakhed_listening_progress(user_id);

-- Badges & Gamification
CREATE TABLE IF NOT EXISTS badges (
  badge_id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT DEFAULT 'learning',
  icon TEXT DEFAULT '🏆',
  reward_stars INTEGER DEFAULT 10,
  target INTEGER DEFAULT 1,
  sort_order INTEGER DEFAULT 0,
  is_active INTEGER DEFAULT 1,
  status TEXT DEFAULT 'published'
);

CREATE TABLE IF NOT EXISTS user_badges (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  badge_id TEXT NOT NULL,
  progress INTEGER DEFAULT 0,
  target INTEGER DEFAULT 1,
  is_unlocked INTEGER DEFAULT 0,
  unlocked_at TEXT,
  updated_at TEXT
);
CREATE INDEX IF NOT EXISTS idx_user_badges_user ON user_badges(user_id);

CREATE TABLE IF NOT EXISTS reward_events (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  source_type TEXT,
  source_id TEXT,
  stars_awarded INTEGER DEFAULT 0,
  badge_id TEXT,
  reason TEXT,
  created_at TEXT
);
CREATE INDEX IF NOT EXISTS idx_reward_events_user ON reward_events(user_id);

CREATE TABLE IF NOT EXISTS learning_analytics_events (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  event_name TEXT NOT NULL,
  date_key TEXT NOT NULL,
  source_id TEXT,
  occurred_at TEXT,
  created_at TEXT
);
CREATE INDEX IF NOT EXISTS idx_analytics_date_event ON learning_analytics_events(date_key, event_name);
CREATE INDEX IF NOT EXISTS idx_analytics_user ON learning_analytics_events(user_id);

-- Waitlist
CREATE TABLE IF NOT EXISTS binti_waitlist (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  full_name TEXT NOT NULL,
  phone_number TEXT NOT NULL,
  ceremony_type TEXT NOT NULL,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  event_date TEXT,
  notes TEXT,
  submitted_at TEXT NOT NULL,
  status TEXT DEFAULT 'new'
);
CREATE INDEX IF NOT EXISTS idx_binti_waitlist_phone ON binti_waitlist(phone_number, ceremony_type);

-- Course Purchases & Entitlements
CREATE TABLE IF NOT EXISTS course_purchases (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  category_id TEXT NOT NULL,
  course_id TEXT,
  amount_in_cents INTEGER,
  currency TEXT DEFAULT 'INR',
  status TEXT DEFAULT 'completed',
  order_id TEXT,
  payment_id TEXT,
  created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_course_purchases_user ON course_purchases(user_id, category_id);

-- Payment Orders
CREATE TABLE IF NOT EXISTS payment_orders (
  order_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  category_id TEXT NOT NULL,
  amount INTEGER NOT NULL,
  currency TEXT DEFAULT 'INR',
  status TEXT DEFAULT 'created',
  receipt TEXT,
  payment_id TEXT,
  signature TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_payment_orders_user ON payment_orders(user_id);

-- Analytics Rollups
CREATE TABLE IF NOT EXISTS learning_analytics_daily_rollups (
  id TEXT PRIMARY KEY,
  date_key TEXT NOT NULL,
  total_events INTEGER DEFAULT 0,
  unique_users INTEGER DEFAULT 0,
  event_counts_json TEXT NOT NULL,
  created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_rollups_date ON learning_analytics_daily_rollups(date_key);

-- Voice & Audio Cache
CREATE TABLE IF NOT EXISTS tts_cache (
  cache_key TEXT PRIMARY KEY,
  text_hash TEXT NOT NULL,
  voice_id TEXT NOT NULL,
  audio_url TEXT NOT NULL,
  duration_ms INTEGER DEFAULT 0,
  created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_tts_cache_key ON tts_cache(cache_key);

CREATE TABLE IF NOT EXISTS audio_tracks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  language TEXT DEFAULT 'sat',
  category TEXT DEFAULT 'general',
  audio_url TEXT NOT NULL,
  duration_seconds REAL DEFAULT 0,
  status TEXT DEFAULT 'pending_review',
  reviewed_by TEXT,
  reviewed_at TEXT,
  created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_audio_tracks_status ON audio_tracks(status);

CREATE TABLE IF NOT EXISTS localized_contents (
  id TEXT PRIMARY KEY,
  content_key TEXT NOT NULL,
  locale TEXT NOT NULL,
  translated_text TEXT NOT NULL,
  status TEXT DEFAULT 'pending_review',
  reviewed_by TEXT,
  reviewed_at TEXT,
  created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_localized_contents_key ON localized_contents(content_key, locale);

-- Admin Audit Logs
CREATE TABLE IF NOT EXISTS admin_audit_logs (
  id TEXT PRIMARY KEY,
  admin_user_id TEXT NOT NULL,
  action TEXT NOT NULL,
  target_id TEXT,
  details_json TEXT,
  timestamp TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_admin_audit_user ON admin_audit_logs(admin_user_id);

-- Account Deletion Requests
CREATE TABLE IF NOT EXISTS deletion_requests (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  last_error TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_deletion_requests_user ON deletion_requests(user_id);
