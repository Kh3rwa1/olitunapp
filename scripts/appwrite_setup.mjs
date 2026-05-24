/**
 * Appwrite Setup Script for Olitun
 * Creates database, collections, attributes, indexes, and storage buckets.
 * Run: node scripts/appwrite_setup.mjs
 */

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
const DATABASE_NAME = 'Olitun Database';

// Admin team — must match `--dart-define=ADMIN_TEAM_ID` at build time.
// The ID is matched server-side by `AdminAuthService`; team name is ignored.
const ADMIN_TEAM_ID = process.env.ADMIN_TEAM_ID || 'admins';
const ADMIN_TEAM_NAME = 'Olitun Admins';

if (!PROJECT_ID) {
  console.error('❌ Set APPWRITE_PROJECT_ID or appwrite.config.json projectId');
  process.exit(1);
}

if (!API_KEY) {
  console.error('❌ Set APPWRITE_API_KEY environment variable');
  process.exit(1);
}

const headers = {
  'Content-Type': 'application/json',
  'X-Appwrite-Project': PROJECT_ID,
  'X-Appwrite-Key': API_KEY,
};

const adminWritePermissions = [
  'read("users")',
  `create("team:${ADMIN_TEAM_ID}")`,
  `update("team:${ADMIN_TEAM_ID}")`,
  `delete("team:${ADMIN_TEAM_ID}")`,
];

const adminReadOnlyPermissions = [
  `read("team:${ADMIN_TEAM_ID}")`,
];

const adminOnlyPermissions = [
  `read("team:${ADMIN_TEAM_ID}")`,
  `create("team:${ADMIN_TEAM_ID}")`,
  `update("team:${ADMIN_TEAM_ID}")`,
  `delete("team:${ADMIN_TEAM_ID}")`,
];

const userCreateAdminReadPermissions = [
  `read("team:${ADMIN_TEAM_ID}")`,
  'create("users")',
];

const functionOnlyCollections = new Set([
  'translation_cache',
  'rate_limits',
  'reward_events',
  'course_purchases',
]);

const adminReadBackendWriteCollections = new Set([
  'user_badges',
  'user_mistakes',
  'mistake_review_sessions',
  'bakhed_listening_progress',
  'learning_analytics_daily_rollups',
]);

const adminOnlyCollections = new Set([
  'admin_audit_logs',
  'gamification_config',
]);

const userCreateAdminReadCollections = new Set([
  'learning_analytics_events',
]);

function permissionsForCollection(collectionId) {
  if (functionOnlyCollections.has(collectionId)) {
    return [];
  }
  if (collectionId === 'binti_guru_waitlist') {
    return [
      'create("any")',
      `read("team:${ADMIN_TEAM_ID}")`,
      `update("team:${ADMIN_TEAM_ID}")`,
      `delete("team:${ADMIN_TEAM_ID}")`,
    ];
  }
  if (userCreateAdminReadCollections.has(collectionId)) {
    return userCreateAdminReadPermissions;
  }
  if (adminReadBackendWriteCollections.has(collectionId)) {
    return adminReadOnlyPermissions;
  }
  if (adminOnlyCollections.has(collectionId)) {
    return adminOnlyPermissions;
  }
  return adminWritePermissions;
}

async function api(method, path, body = null) {
  const opts = { method, headers };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(`${ENDPOINT}${path}`, opts);
  const text = await res.text();
  if (!res.ok) {
    // 409 = already exists, skip gracefully
    if (res.status === 409) {
      console.log(`  ⏭  Already exists, skipping: ${path}`);
      return null;
    }
    throw new Error(`${res.status} ${method} ${path}: ${text}`);
  }
  return text ? JSON.parse(text) : null;
}

// Helper to wait for attribute to be available
async function waitForAttribute(collectionId, key, maxWait = 15000) {
  const start = Date.now();
  while (Date.now() - start < maxWait) {
    try {
      const attr = await api('GET', `/databases/${DATABASE_ID}/collections/${collectionId}/attributes/${key}`);
      if (attr && attr.status === 'available') return;
    } catch (_) { /* still processing */ }
    await new Promise(r => setTimeout(r, 1000));
  }
}

// ─── COLLECTION DEFINITIONS ───
const collections = [
  {
    id: 'categories',
    name: 'Categories',
    attrs: [
      { type: 'string', key: 'titleOlChiki', size: 255, required: true },
      { type: 'string', key: 'titleLatin', size: 255, required: true },
      { type: 'string', key: 'iconName', size: 50, required: false },
      { type: 'string', key: 'iconUrl', size: 512, required: false },
      { type: 'string', key: 'animationUrl', size: 512, required: false },
      { type: 'string', key: 'gradientPreset', size: 50, required: false, default: 'skyBlue' },
      { type: 'integer', key: 'order', required: false, default: 0 },
      { type: 'boolean', key: 'isActive', required: false, default: true },
      { type: 'integer', key: 'totalLessons', required: false, default: 0 },
      { type: 'string', key: 'description', size: 2048, required: false },
      { type: 'string', key: 'unlockMode', size: 30, required: false, default: 'free' },
      { type: 'integer', key: 'priceInr', required: false, default: 0 },
      { type: 'integer', key: 'previewLessonCount', required: false, default: 3 },
      { type: 'string', key: 'courseDescription', size: 2048, required: false },
      { type: 'string', key: 'courseOutcome', size: 500, required: false },
      { type: 'string', key: 'courseHeroImageUrl', size: 1024, required: false },
    ],
    indexes: [
      { key: 'idx_order', type: 'key', attributes: ['order'], orders: ['ASC'] },
    ],
  },
  {
    id: 'lessons',
    name: 'Lessons',
    attrs: [
      { type: 'string', key: 'categoryId', size: 36, required: true },
      { type: 'string', key: 'titleOlChiki', size: 255, required: true },
      { type: 'string', key: 'titleLatin', size: 255, required: true },
      { type: 'string', key: 'level', size: 20, required: false, default: 'beginner' },
      { type: 'integer', key: 'order', required: false, default: 0 },
      { type: 'boolean', key: 'isActive', required: false, default: true },
      { type: 'integer', key: 'estimatedMinutes', required: false, default: 5 },
      { type: 'string', key: 'thumbnailUrl', size: 512, required: false },
      { type: 'string', key: 'heroMediaUrl', size: 1024, required: false },
      { type: 'string', key: 'heroMediaType', size: 40, required: false },
      { type: 'string', key: 'heroPosterUrl', size: 1024, required: false },
      { type: 'string', key: 'description', size: 2048, required: false },
      { type: 'string', key: 'audioUrl', size: 512, required: false },
      { type: 'boolean', key: 'isPremium', required: false, default: false },
      // blocks stored as JSON string (Appwrite has no native JSON array attribute)
      { type: 'string', key: 'blocks', size: 1000000, required: false },
    ],
    indexes: [
      { key: 'idx_category', type: 'key', attributes: ['categoryId'] },
      { key: 'idx_order', type: 'key', attributes: ['order'], orders: ['ASC'] },
    ],
  },
  {
    id: 'quizzes',
    name: 'Quizzes',
    attrs: [
      { type: 'string', key: 'categoryId', size: 36, required: false },
      { type: 'string', key: 'title', size: 255, required: false },
      { type: 'string', key: 'level', size: 20, required: false, default: 'beginner' },
      { type: 'integer', key: 'order', required: false, default: 0 },
      { type: 'boolean', key: 'isActive', required: false, default: true },
      { type: 'integer', key: 'passingScore', required: false, default: 70 },
      // questions stored as JSON string so Appwrite, admin web, and mobile share one source.
      { type: 'string', key: 'questions', size: 1000000, required: false },
    ],
    indexes: [
      { key: 'idx_category', type: 'key', attributes: ['categoryId'] },
      { key: 'idx_order', type: 'key', attributes: ['order'], orders: ['ASC'] },
    ],
  },
  {
    id: 'letters',
    name: 'Letters',
    attrs: [
      { type: 'string', key: 'charOlChiki', size: 20, required: true },
      { type: 'string', key: 'transliterationLatin', size: 50, required: true },
      { type: 'string', key: 'exampleWordOlChiki', size: 255, required: false },
      { type: 'string', key: 'exampleWordLatin', size: 255, required: false },
      { type: 'string', key: 'imageUrl', size: 512, required: false },
      { type: 'string', key: 'audioUrl', size: 512, required: false },
      { type: 'string', key: 'animationUrl', size: 512, required: false },
      { type: 'integer', key: 'order', required: false, default: 0 },
      { type: 'boolean', key: 'isActive', required: false, default: true },
      { type: 'string', key: 'pronunciation', size: 100, required: false },
      { type: 'string', key: 'themeColor', size: 50, required: false },
    ],
    indexes: [
      { key: 'idx_order', type: 'key', attributes: ['order'], orders: ['ASC'] },
    ],
  },
  {
    id: 'numbers',
    name: 'Numbers',
    attrs: [
      { type: 'string', key: 'numeral', size: 20, required: true },
      { type: 'integer', key: 'value', required: true },
      { type: 'string', key: 'nameOlChiki', size: 255, required: true },
      { type: 'string', key: 'nameLatin', size: 255, required: true },
      { type: 'string', key: 'imageUrl', size: 512, required: false },
      { type: 'string', key: 'audioUrl', size: 512, required: false },
      { type: 'string', key: 'animationUrl', size: 512, required: false },
      { type: 'string', key: 'pronunciation', size: 100, required: false },
      { type: 'integer', key: 'order', required: false, default: 0 },
      { type: 'boolean', key: 'isActive', required: false, default: true },
      { type: 'string', key: 'themeColor', size: 50, required: false },
    ],
    indexes: [
      { key: 'idx_order', type: 'key', attributes: ['order'], orders: ['ASC'] },
    ],
  },
  {
    id: 'words',
    name: 'Words',
    attrs: [
      { type: 'string', key: 'wordOlChiki', size: 255, required: true },
      { type: 'string', key: 'wordLatin', size: 255, required: true },
      { type: 'string', key: 'meaning', size: 255, required: true },
      { type: 'string', key: 'usage', size: 1024, required: false },
      { type: 'string', key: 'category', size: 50, required: false },
      { type: 'string', key: 'imageUrl', size: 512, required: false },
      { type: 'string', key: 'audioUrl', size: 512, required: false },
      { type: 'string', key: 'animationUrl', size: 512, required: false },
      { type: 'string', key: 'pronunciation', size: 100, required: false },
      { type: 'integer', key: 'order', required: false, default: 0 },
      { type: 'boolean', key: 'isActive', required: false, default: true },
      { type: 'string', key: 'themeColor', size: 50, required: false },
    ],
    indexes: [
      { key: 'idx_order', type: 'key', attributes: ['order'], orders: ['ASC'] },
    ],
  },
  {
    id: 'sentences',
    name: 'Sentences',
    attrs: [
      { type: 'string', key: 'sentenceOlChiki', size: 1024, required: true },
      { type: 'string', key: 'sentenceLatin', size: 1024, required: true },
      { type: 'string', key: 'meaning', size: 1024, required: true },
      { type: 'string', key: 'usage', size: 1024, required: false },
      { type: 'string', key: 'category', size: 50, required: false },
      { type: 'string', key: 'imageUrl', size: 512, required: false },
      { type: 'string', key: 'audioUrl', size: 512, required: false },
      { type: 'string', key: 'animationUrl', size: 512, required: false },
      { type: 'string', key: 'pronunciation', size: 255, required: false },
      { type: 'integer', key: 'order', required: false, default: 0 },
      { type: 'boolean', key: 'isActive', required: false, default: true },
      { type: 'string', key: 'themeColor', size: 50, required: false },
    ],
    indexes: [
      { key: 'idx_order', type: 'key', attributes: ['order'], orders: ['ASC'] },
    ],
  },
  {
    id: 'rhymes',
    name: 'Rhymes',
    attrs: [
      { type: 'string', key: 'titleOlChiki', size: 255, required: true },
      { type: 'string', key: 'titleLatin', size: 255, required: true },
      { type: 'string', key: 'contentOlChiki', size: 10000, required: false },
      { type: 'string', key: 'contentLatin', size: 10000, required: false },
      { type: 'string', key: 'audioUrl', size: 512, required: false },
      { type: 'string', key: 'thumbnailUrl', size: 512, required: false },
      { type: 'string', key: 'category', size: 50, required: false },
      { type: 'string', key: 'categoryId', size: 36, required: false },
      { type: 'string', key: 'tags', size: 50, required: false, array: true },
      { type: 'string', key: 'difficulty', size: 10, required: false, default: 'easy' },
      { type: 'integer', key: 'durationSeconds', required: false, default: 0 },
      { type: 'boolean', key: 'isPremium', required: false, default: false },
    ],
    indexes: [
      { key: 'idx_category', type: 'key', attributes: ['categoryId'] },
    ],
  },
  {
    id: 'banners',
    name: 'Banners',
    attrs: [
      { type: 'string', key: 'title', size: 255, required: true },
      { type: 'string', key: 'subtitle', size: 255, required: false },
      { type: 'string', key: 'imageUrl', size: 512, required: false },
      { type: 'string', key: 'animationUrl', size: 512, required: false },
      { type: 'string', key: 'gradientPreset', size: 50, required: false, default: 'skyBlue' },
      { type: 'string', key: 'targetRoute', size: 255, required: false },
      { type: 'integer', key: 'order', required: false, default: 0 },
      { type: 'boolean', key: 'isActive', required: false, default: true },
    ],
    indexes: [
      { key: 'idx_order', type: 'key', attributes: ['order'], orders: ['ASC'] },
    ],
  },
  // ── Translator function support collections ──
  // Used by `functions/translator/src/main.js` for cache + per-IP rate limit.
  {
    id: 'translation_cache',
    name: 'Translation Cache',
    attrs: [
      // SHA-256 of `{from,to,text}`; never store raw source text as an index key.
      { type: 'string', key: 'cacheKey', size: 64, required: true },
      { type: 'string', key: 'translation', size: 10000, required: true },
      { type: 'string', key: 'detectedLanguage', size: 16, required: false },
      { type: 'string', key: 'targetLang', size: 16, required: false },
    ],
    indexes: [
      { key: 'idx_cache_key', type: 'unique', attributes: ['cacheKey'] },
    ],
  },
  {
    id: 'rate_limits',
    name: 'Translator Rate Limits',
    attrs: [
      { type: 'string', key: 'clientIp', size: 64, required: true },
      { type: 'integer', key: 'count', required: false, default: 0 },
      { type: 'integer', key: 'windowStart', required: false, default: 0 },
    ],
    indexes: [
      { key: 'idx_client_ip', type: 'key', attributes: ['clientIp'] },
    ],
  },
  {
    id: 'app_settings',
    name: 'App Settings',
    attrs: [
      { type: 'string', key: 'settingKey', size: 100, required: true },
      { type: 'string', key: 'settingValue', size: 4096, required: false },
    ],
    indexes: [
      { key: 'idx_key', type: 'unique', attributes: ['settingKey'] },
    ],
  },
  // ── Admin-controlled gamification CMS ──
  {
    id: 'bravo_messages',
    name: 'Bravo Messages',
    attrs: [
      { type: 'string', key: 'messageId', size: 100, required: true },
      { type: 'string', key: 'trigger', size: 80, required: true },
      { type: 'string', key: 'title', size: 255, required: true },
      { type: 'string', key: 'body', size: 2048, required: true },
      { type: 'string', key: 'language', size: 20, required: false, default: 'en' },
      { type: 'string', key: 'scriptMode', size: 20, required: false, default: 'both' },
      { type: 'string', key: 'learnerLevel', size: 20, required: false, default: 'all' },
      { type: 'integer', key: 'weight', required: false, default: 1, min: 0, max: 100 },
      { type: 'string', key: 'status', size: 20, required: false, default: 'draft' },
      { type: 'boolean', key: 'isActive', required: false, default: true },
      { type: 'string', key: 'startsAt', size: 30, required: false },
      { type: 'string', key: 'endsAt', size: 30, required: false },
      { type: 'integer', key: 'version', required: false, default: 1 },
      { type: 'string', key: 'updatedBy', size: 100, required: false },
      { type: 'string', key: 'createdAt', size: 30, required: false },
      { type: 'string', key: 'updatedAt', size: 30, required: false },
    ],
    indexes: [
      { key: 'idx_trigger_status', type: 'key', attributes: ['trigger', 'status'] },
      { key: 'idx_active_status', type: 'key', attributes: ['isActive', 'status'] },
    ],
  },
  {
    id: 'badges',
    name: 'Badges',
    attrs: [
      { type: 'string', key: 'badgeId', size: 100, required: true },
      { type: 'string', key: 'name', size: 255, required: true },
      { type: 'string', key: 'description', size: 2048, required: true },
      { type: 'string', key: 'category', size: 40, required: false, default: 'learning' },
      { type: 'string', key: 'icon', size: 20, required: false, default: '🏆' },
      { type: 'integer', key: 'target', required: false, default: 1, min: 1, max: 10000 },
      { type: 'integer', key: 'rewardStars', required: false, default: 0, min: 0, max: 100 },
      { type: 'string', key: 'unlockRule', size: 4096, required: false },
      { type: 'string', key: 'status', size: 20, required: false, default: 'draft' },
      { type: 'boolean', key: 'isActive', required: false, default: true },
      { type: 'integer', key: 'sortOrder', required: false, default: 0 },
      { type: 'integer', key: 'version', required: false, default: 1 },
      { type: 'string', key: 'updatedBy', size: 100, required: false },
      { type: 'string', key: 'createdAt', size: 30, required: false },
      { type: 'string', key: 'updatedAt', size: 30, required: false },
    ],
    indexes: [
      { key: 'idx_badge_id', type: 'unique', attributes: ['badgeId'] },
      { key: 'idx_category_status', type: 'key', attributes: ['category', 'status'] },
      { key: 'idx_sort', type: 'key', attributes: ['sortOrder'], orders: ['ASC'] },
    ],
  },
  {
    id: 'user_badges',
    name: 'User Badges',
    attrs: [
      { type: 'string', key: 'userId', size: 36, required: true },
      { type: 'string', key: 'badgeId', size: 100, required: true },
      { type: 'integer', key: 'progress', required: false, default: 0 },
      { type: 'integer', key: 'target', required: false, default: 1 },
      { type: 'boolean', key: 'isUnlocked', required: false, default: false },
      { type: 'string', key: 'unlockedAt', size: 30, required: false },
      { type: 'string', key: 'updatedAt', size: 30, required: false },
    ],
    indexes: [
      { key: 'idx_user_badge', type: 'unique', attributes: ['userId', 'badgeId'] },
      { key: 'idx_user_unlocked', type: 'key', attributes: ['userId', 'isUnlocked'] },
    ],
  },
  {
    id: 'mission_templates',
    name: 'Mission Templates',
    attrs: [
      { type: 'string', key: 'missionId', size: 100, required: true },
      { type: 'string', key: 'title', size: 255, required: true },
      { type: 'string', key: 'description', size: 2048, required: true },
      { type: 'string', key: 'type', size: 60, required: true },
      { type: 'integer', key: 'targetCount', required: false, default: 1, min: 1, max: 10 },
      { type: 'integer', key: 'rewardStars', required: false, default: 0, min: 0, max: 100 },
      { type: 'string', key: 'learnerLevel', size: 20, required: false, default: 'all' },
      { type: 'boolean', key: 'isQuickWin', required: false, default: false },
      { type: 'string', key: 'status', size: 20, required: false, default: 'draft' },
      { type: 'boolean', key: 'isActive', required: false, default: true },
      { type: 'integer', key: 'sortOrder', required: false, default: 0 },
      { type: 'integer', key: 'version', required: false, default: 1 },
      { type: 'string', key: 'updatedBy', size: 100, required: false },
      { type: 'string', key: 'createdAt', size: 30, required: false },
      { type: 'string', key: 'updatedAt', size: 30, required: false },
    ],
    indexes: [
      { key: 'idx_mission_id', type: 'unique', attributes: ['missionId'] },
      { key: 'idx_mission_publish', type: 'key', attributes: ['status', 'isActive'] },
      { key: 'idx_mission_type', type: 'key', attributes: ['type'] },
    ],
  },
  {
    id: 'reward_messages',
    name: 'Reward Messages',
    attrs: [
      { type: 'string', key: 'messageId', size: 100, required: true },
      { type: 'string', key: 'trigger', size: 80, required: true },
      { type: 'string', key: 'title', size: 255, required: true },
      { type: 'string', key: 'body', size: 2048, required: true },
      { type: 'string', key: 'rewardLabel', size: 255, required: false },
      { type: 'string', key: 'icon', size: 20, required: false, default: '⭐' },
      { type: 'string', key: 'status', size: 20, required: false, default: 'draft' },
      { type: 'boolean', key: 'isActive', required: false, default: true },
      { type: 'integer', key: 'version', required: false, default: 1 },
      { type: 'string', key: 'updatedBy', size: 100, required: false },
      { type: 'string', key: 'createdAt', size: 30, required: false },
      { type: 'string', key: 'updatedAt', size: 30, required: false },
    ],
    indexes: [
      { key: 'idx_reward_trigger', type: 'key', attributes: ['trigger', 'status'] },
      { key: 'idx_reward_active', type: 'key', attributes: ['isActive', 'status'] },
    ],
  },
  {
    id: 'quiz_feedback_messages',
    name: 'Quiz Feedback Messages',
    attrs: [
      { type: 'string', key: 'messageId', size: 100, required: true },
      { type: 'string', key: 'type', size: 50, required: true },
      { type: 'string', key: 'title', size: 255, required: true },
      { type: 'string', key: 'body', size: 2048, required: true },
      { type: 'string', key: 'status', size: 20, required: false, default: 'draft' },
      { type: 'boolean', key: 'isActive', required: false, default: true },
      { type: 'integer', key: 'version', required: false, default: 1 },
      { type: 'string', key: 'updatedBy', size: 100, required: false },
      { type: 'string', key: 'createdAt', size: 30, required: false },
      { type: 'string', key: 'updatedAt', size: 30, required: false },
    ],
    indexes: [
      { key: 'idx_feedback_type', type: 'key', attributes: ['type', 'status'] },
      { key: 'idx_feedback_active', type: 'key', attributes: ['isActive', 'status'] },
    ],
  },
  {
    id: 'gamification_config',
    name: 'Gamification Config',
    attrs: [
      { type: 'string', key: 'configId', size: 40, required: true },
      { type: 'integer', key: 'bakhedCompletionThreshold', required: false, default: 80, min: 50, max: 95 },
      { type: 'boolean', key: 'quickWinEnabled', required: false, default: true },
      { type: 'boolean', key: 'badgesEnabled', required: false, default: true },
      { type: 'boolean', key: 'mistakeReviewEnabled', required: false, default: true },
      { type: 'string', key: 'updatedBy', size: 100, required: false },
      { type: 'string', key: 'updatedAt', size: 30, required: false },
    ],
    indexes: [
      { key: 'idx_config_id', type: 'unique', attributes: ['configId'] },
    ],
  },
  {
    id: 'admin_audit_logs',
    name: 'Admin Audit Logs',
    attrs: [
      { type: 'string', key: 'actorUserId', size: 100, required: false },
      { type: 'string', key: 'action', size: 100, required: true },
      { type: 'string', key: 'targetType', size: 100, required: true },
      { type: 'string', key: 'targetId', size: 120, required: false },
      { type: 'string', key: 'metadata', size: 10000, required: false },
      { type: 'boolean', key: 'success', required: false, default: true },
      { type: 'string', key: 'createdAt', size: 30, required: false },
    ],
    indexes: [
      { key: 'idx_audit_action', type: 'key', attributes: ['action'] },
      { key: 'idx_audit_target', type: 'key', attributes: ['targetType', 'targetId'] },
      { key: 'idx_audit_created', type: 'key', attributes: ['createdAt'], orders: ['DESC'] },
    ],
  },
  {
    id: 'learning_analytics_events',
    name: 'Learning Analytics Events',
    attrs: [
      { type: 'string', key: 'eventId', size: 36, required: true },
      { type: 'string', key: 'eventName', size: 80, required: true },
      { type: 'integer', key: 'eventVersion', required: false, default: 1 },
      { type: 'string', key: 'userId', size: 80, required: false },
      { type: 'string', key: 'sessionId', size: 36, required: true },
      { type: 'string', key: 'source', size: 80, required: false },
      { type: 'string', key: 'sourceId', size: 120, required: false },
      { type: 'string', key: 'learnerLevel', size: 40, required: false },
      { type: 'string', key: 'scriptMode', size: 40, required: false },
      { type: 'string', key: 'platform', size: 20, required: false },
      { type: 'string', key: 'dateKey', size: 10, required: true },
      { type: 'string', key: 'occurredAt', size: 30, required: true },
      { type: 'string', key: 'metadata', size: 4096, required: false },
    ],
    indexes: [
      { key: 'idx_event_id', type: 'unique', attributes: ['eventId'] },
      { key: 'idx_event_name', type: 'key', attributes: ['eventName'] },
      { key: 'idx_event_name_date', type: 'key', attributes: ['eventName', 'dateKey'] },
      { key: 'idx_occurred', type: 'key', attributes: ['occurredAt'], orders: ['DESC'] },
      { key: 'idx_user_date', type: 'key', attributes: ['userId', 'dateKey'] },
    ],
  },
  {
    id: 'learning_analytics_daily_rollups',
    name: 'Learning Analytics Daily Rollups',
    attrs: [
      { type: 'string', key: 'rollupId', size: 36, required: true },
      { type: 'string', key: 'dateKey', size: 10, required: true },
      { type: 'string', key: 'eventName', size: 80, required: true },
      { type: 'integer', key: 'totalEvents', required: false, default: 0 },
      { type: 'integer', key: 'uniqueUsers', required: false, default: 0 },
      { type: 'string', key: 'platformBreakdown', size: 2048, required: false },
      { type: 'string', key: 'sourceBreakdown', size: 2048, required: false },
      { type: 'string', key: 'updatedAt', size: 30, required: false },
    ],
    indexes: [
      { key: 'idx_rollup_id', type: 'unique', attributes: ['rollupId'] },
      { key: 'idx_rollup_date', type: 'key', attributes: ['dateKey'], orders: ['DESC'] },
      { key: 'idx_rollup_event_date', type: 'key', attributes: ['eventName', 'dateKey'] },
    ],
  },
  {
    id: 'reward_events',
    name: 'Reward Events',
    attrs: [
      { type: 'string', key: 'rewardEventId', size: 100, required: true },
      { type: 'string', key: 'userId', size: 36, required: true },
      { type: 'string', key: 'sourceType', size: 80, required: true },
      { type: 'string', key: 'sourceId', size: 120, required: true },
      { type: 'integer', key: 'starsAwarded', required: false, default: 0, min: 0, max: 100 },
      { type: 'string', key: 'badgeId', size: 100, required: false },
      { type: 'string', key: 'reason', size: 2048, required: false },
      { type: 'string', key: 'createdAt', size: 30, required: false },
    ],
    indexes: [
      { key: 'idx_reward_event', type: 'unique', attributes: ['rewardEventId'] },
      { key: 'idx_reward_user', type: 'key', attributes: ['userId'] },
      { key: 'idx_reward_source', type: 'key', attributes: ['sourceType', 'sourceId'] },
    ],
  },
  // ── Mistake review, streak shields, and Bakhed cultural learning ──
  {
    id: 'user_mistakes',
    name: 'User Mistakes',
    attrs: [
      { type: 'string', key: 'userId', size: 36, required: true },
      { type: 'string', key: 'quizId', size: 100, required: true },
      { type: 'string', key: 'questionId', size: 100, required: true },
      { type: 'integer', key: 'questionIndex', required: false, default: 0 },
      { type: 'string', key: 'wrongAnswer', size: 2048, required: false },
      { type: 'string', key: 'correctAnswer', size: 2048, required: false },
      { type: 'string', key: 'questionSnapshot', size: 10000, required: false },
      { type: 'integer', key: 'timesMissed', required: false, default: 1 },
      { type: 'integer', key: 'timesReviewed', required: false, default: 0 },
      { type: 'boolean', key: 'isMastered', required: false, default: false },
      { type: 'string', key: 'masteredAt', size: 30, required: false },
      { type: 'string', key: 'lastMissedAt', size: 30, required: false },
      { type: 'string', key: 'lastReviewedAt', size: 30, required: false },
    ],
    indexes: [
      { key: 'idx_mistake_user_question', type: 'unique', attributes: ['userId', 'quizId', 'questionId'] },
      { key: 'idx_mistake_user_mastered', type: 'key', attributes: ['userId', 'isMastered'] },
    ],
  },
  {
    id: 'mistake_review_sessions',
    name: 'Mistake Review Sessions',
    attrs: [
      { type: 'string', key: 'sessionId', size: 100, required: true },
      { type: 'string', key: 'userId', size: 36, required: true },
      { type: 'string', key: 'questionIds', size: 4096, required: true },
      { type: 'integer', key: 'score', required: false, default: 0 },
      { type: 'integer', key: 'total', required: false, default: 0 },
      { type: 'string', key: 'completedAt', size: 30, required: false },
    ],
    indexes: [
      { key: 'idx_session_id', type: 'unique', attributes: ['sessionId'] },
      { key: 'idx_session_user', type: 'key', attributes: ['userId'] },
    ],
  },
  {
    id: 'bakhed_lyrics',
    name: 'Bakhed Lyrics',
    attrs: [
      { type: 'string', key: 'bakhedId', size: 100, required: true },
      { type: 'integer', key: 'lineIndex', required: true },
      { type: 'integer', key: 'startMs', required: false, default: 0 },
      { type: 'integer', key: 'endMs', required: false, default: 0 },
      { type: 'string', key: 'olChiki', size: 2048, required: false },
      { type: 'string', key: 'latin', size: 2048, required: false },
      { type: 'string', key: 'meaning', size: 2048, required: false },
    ],
    indexes: [
      { key: 'idx_bakhed_lyric', type: 'key', attributes: ['bakhedId', 'lineIndex'], orders: ['ASC', 'ASC'] },
    ],
  },
  {
    id: 'bakhed_vocabulary',
    name: 'Bakhed Vocabulary',
    attrs: [
      { type: 'string', key: 'bakhedId', size: 100, required: true },
      { type: 'string', key: 'olChiki', size: 255, required: false },
      { type: 'string', key: 'latin', size: 255, required: false },
      { type: 'string', key: 'meaning', size: 2048, required: false },
      { type: 'string', key: 'audioFileId', size: 100, required: false },
      { type: 'integer', key: 'sortOrder', required: false, default: 0 },
    ],
    indexes: [
      { key: 'idx_bakhed_vocab', type: 'key', attributes: ['bakhedId', 'sortOrder'], orders: ['ASC', 'ASC'] },
    ],
  },
  {
    id: 'bakhed_cultural_notes',
    name: 'Bakhed Cultural Notes',
    attrs: [
      { type: 'string', key: 'noteId', size: 100, required: true },
      { type: 'string', key: 'bakhedId', size: 100, required: true },
      { type: 'string', key: 'title', size: 255, required: true },
      { type: 'string', key: 'body', size: 10000, required: true },
      { type: 'string', key: 'source', size: 2048, required: false },
      { type: 'boolean', key: 'isPublished', required: false, default: false },
    ],
    indexes: [
      { key: 'idx_bakhed_note', type: 'key', attributes: ['bakhedId', 'isPublished'] },
    ],
  },
  {
    id: 'bakhed_listening_progress',
    name: 'Bakhed Listening Progress',
    attrs: [
      { type: 'string', key: 'userId', size: 36, required: true },
      { type: 'string', key: 'bakhedId', size: 100, required: true },
      { type: 'integer', key: 'listenedPercent', required: false, default: 0, min: 0, max: 100 },
      { type: 'boolean', key: 'completed80Percent', required: false, default: false },
      { type: 'string', key: 'completedAt', size: 30, required: false },
      { type: 'integer', key: 'lastPositionMs', required: false, default: 0 },
      { type: 'string', key: 'updatedAt', size: 30, required: false },
    ],
    indexes: [
      { key: 'idx_bakhed_progress', type: 'unique', attributes: ['userId', 'bakhedId'] },
      { key: 'idx_bakhed_completed', type: 'key', attributes: ['userId', 'completed80Percent'] },
    ],
  },
  {
    id: 'daily_affirmations',
    name: 'Daily Affirmations',
    attrs: [
      { type: 'string', key: 'olChikiText', size: 500, required: true },
      { type: 'string', key: 'santaliPhonetic', size: 500, required: true },
      { type: 'string', key: 'englishMeaning', size: 500, required: true },
      { type: 'string', key: 'audioUrl', size: 1024, required: false },
      { type: 'string', key: 'category', size: 50, required: true },
      { type: 'boolean', key: 'isPremium', required: false, default: false },
      { type: 'integer', key: 'order', required: true },
      { type: 'string', key: 'publishedAt', size: 30, required: true },
    ],
    indexes: [
      { key: 'idx_order', type: 'key', attributes: ['order'], orders: ['ASC'] },
      { key: 'idx_category_published', type: 'key', attributes: ['category', 'publishedAt'] },
    ],
  },
  {
    id: 'course_purchases',
    name: 'Course Purchases',
    documentSecurity: true,
    attrs: [
      { type: 'string', key: 'userId', size: 36, required: true },
      { type: 'string', key: 'categoryId', size: 36, required: true },
      { type: 'string', key: 'unlockMethod', size: 30, required: true },
      { type: 'integer', key: 'amountPaidInr', required: true },
      { type: 'string', key: 'razorpayPaymentId', size: 255, required: false },
      { type: 'string', key: 'razorpayOrderId', size: 255, required: false },
      { type: 'string', key: 'razorpaySignature', size: 512, required: false },
      { type: 'string', key: 'reviewCompletedAt', size: 30, required: false },
      { type: 'string', key: 'reviewPlatform', size: 20, required: false },
      { type: 'string', key: 'status', size: 20, required: false, default: 'pending' },
      { type: 'string', key: 'purchasedAt', size: 30, required: true },
      { type: 'string', key: 'verifiedAt', size: 30, required: false },
    ],
    indexes: [
      { key: 'idx_user_category', type: 'unique', attributes: ['userId', 'categoryId'] },
      { key: 'idx_user_id', type: 'key', attributes: ['userId'] },
    ],
  },
  {
    id: 'binti_guru_waitlist',
    name: 'Binti Guru Waitlist',
    documentSecurity: true,
    attrs: [
      { type: 'string', key: 'userId', size: 36, required: false },
      { type: 'string', key: 'fullName', size: 100, required: true },
      { type: 'string', key: 'phoneNumber', size: 20, required: true },
      { type: 'string', key: 'ceremonyType', size: 50, required: true },
      { type: 'string', key: 'eventDate', size: 30, required: false },
      { type: 'string', key: 'city', size: 100, required: true },
      { type: 'string', key: 'state', size: 100, required: true },
      { type: 'string', key: 'notes', size: 1000, required: false },
      { type: 'string', key: 'submittedAt', size: 30, required: true },
      { type: 'string', key: 'contactedAt', size: 30, required: false },
      { type: 'string', key: 'status', size: 20, required: false, default: 'new' },
    ],
    indexes: [
      { key: 'idx_submitted', type: 'key', attributes: ['submittedAt'], orders: ['DESC'] },
      { key: 'idx_status', type: 'key', attributes: ['status'] },
    ],
  },
];

// ─── STORAGE BUCKETS ───
const buckets = [
  {
    id: 'audio',
    name: 'Audio Files',
    allowedExtensions: ['mp3', 'wav', 'ogg', 'm4a', 'aac'],
    maxFileSize: 52428800, // 50MB
  },
  {
    id: 'images',
    name: 'Images',
    allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'],
    maxFileSize: 10485760, // 10MB
  },
  {
    id: 'animations',
    name: 'Lottie Animations',
    allowedExtensions: ['json', 'lottie'],
    maxFileSize: 5242880, // 5MB
  },
  {
    id: 'videos',
    name: 'Videos',
    allowedExtensions: ['mp4', 'webm', 'mov', 'm4v'],
    maxFileSize: 104857600, // 100MB
  },
  {
    id: 'admin_backups',
    name: 'Admin Backups',
    allowedExtensions: ['json'],
    maxFileSize: 104857600, // 100MB
    permissions: [
      `read("team:${ADMIN_TEAM_ID}")`,
      `create("team:${ADMIN_TEAM_ID}")`,
      `update("team:${ADMIN_TEAM_ID}")`,
      `delete("team:${ADMIN_TEAM_ID}")`,
    ],
  },
];

// ─── MAIN ───
async function main() {
  console.log('🚀 Olitun Appwrite Setup\n');

  // 1. Create Database
  console.log('📦 Creating database...');
  await api('POST', '/databases', {
    databaseId: DATABASE_ID,
    name: DATABASE_NAME,
  });
  console.log(`  ✅ Database: ${DATABASE_NAME}\n`);

  // 2. Create Collections + Attributes + Indexes
  for (const col of collections) {
    console.log(`📋 Creating collection: ${col.name} (${col.id})`);
    const permissions = permissionsForCollection(col.id);
    const docSecurity = col.documentSecurity || false;
    await api('POST', `/databases/${DATABASE_ID}/collections`, {
      collectionId: col.id,
      name: col.name,
      documentSecurity: docSecurity,
      permissions,
    });
    await api('PUT', `/databases/${DATABASE_ID}/collections/${col.id}`, {
      name: col.name,
      documentSecurity: docSecurity,
      permissions,
    });

    // Create attributes
    for (const attr of col.attrs) {
      const path = `/databases/${DATABASE_ID}/collections/${col.id}/attributes`;
      console.log(`  📌 Attr: ${attr.key} (${attr.type})`);

      try {
        if (attr.type === 'string') {
          await api('POST', `${path}/string`, {
            key: attr.key,
            size: attr.size,
            required: attr.required,
            default: attr.default || null,
          });
        } else if (attr.type === 'integer') {
          await api('POST', `${path}/integer`, {
            key: attr.key,
            required: attr.required,
            default: attr.default ?? null,
            min: attr.min ?? null,
            max: attr.max ?? null,
          });
        } else if (attr.type === 'boolean') {
          await api('POST', `${path}/boolean`, {
            key: attr.key,
            required: attr.required,
            default: attr.default ?? null,
          });
        }
      } catch (err) {
        // Double check if it actually exists
        try {
          const existing = await api('GET', `/databases/${DATABASE_ID}/collections/${col.id}/attributes/${attr.key}`);
          if (existing) {
            console.log(`  ⏭  Already exists (verified): ${attr.key}`);
            continue;
          }
        } catch (_) {}
        throw err;
      }
    }

    // Wait for attributes to be ready before creating indexes
    if (col.indexes.length > 0) {
      console.log(`  ⏳ Waiting for attributes to be available...`);
      for (const attr of col.attrs) {
        await waitForAttribute(col.id, attr.key);
      }

      // Create indexes
      for (const idx of col.indexes) {
        console.log(`  🔗 Index: ${idx.key}`);
        await api('POST', `/databases/${DATABASE_ID}/collections/${col.id}/indexes`, {
          key: idx.key,
          type: idx.type,
          attributes: idx.attributes,
          orders: idx.orders || [],
        });
      }
    }

    console.log(`  ✅ Done: ${col.name}\n`);
  }

  // 3. Create the admin Team (idempotent — 409 = already exists)
  console.log('👥 Creating admin team...');
  await api('POST', '/teams', {
    teamId: ADMIN_TEAM_ID,
    name: ADMIN_TEAM_NAME,
  });
  console.log(`  ✅ Team: ${ADMIN_TEAM_NAME} (${ADMIN_TEAM_ID})`);
  console.log(`     Add admins via Console → Auth → Teams → "${ADMIN_TEAM_NAME}" → Add member.\n`);

  // 4. Create Storage Buckets
  console.log('🗂️  Creating storage buckets...');
  for (const bucket of buckets) {
    console.log(`  📁 Bucket: ${bucket.name} (${bucket.id})`);
    const permissions = bucket.permissions || [
      'read("users")',
      `create("team:${ADMIN_TEAM_ID}")`,
      `update("team:${ADMIN_TEAM_ID}")`,
      `delete("team:${ADMIN_TEAM_ID}")`,
    ];
    await api('POST', '/storage/buckets', {
      bucketId: bucket.id,
      name: bucket.name,
      permissions,
      fileSecurity: false,
      maximumFileSize: bucket.maxFileSize,
      allowedFileExtensions: bucket.allowedExtensions,
      enabled: true,
    });
    await api('PUT', `/storage/buckets/${bucket.id}`, {
      name: bucket.name,
      permissions,
      fileSecurity: false,
      maximumFileSize: bucket.maxFileSize,
      allowedFileExtensions: bucket.allowedExtensions,
      enabled: true,
    });
    console.log(`  ✅ Done: ${bucket.name}`);
  }

  console.log('\n🎉 Setup complete! All collections and buckets created.');
  console.log(`\n📊 Summary:`);
  console.log(`   Database: ${DATABASE_NAME} (${DATABASE_ID})`);
  console.log(`   Collections: ${collections.length}`);
  console.log(`   Admin Team: ${ADMIN_TEAM_NAME} (${ADMIN_TEAM_ID})`);
  console.log(`   Storage Buckets: ${buckets.length}`);
  console.log(`\n💡 Next: Run the data migration script to import your existing data.`);
}

main().catch(err => {
  console.error('\n❌ Setup failed:', err.message);
  process.exit(1);
});
