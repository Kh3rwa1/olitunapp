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
  'read("any")',
  `create("team:${ADMIN_TEAM_ID}")`,
  `update("team:${ADMIN_TEAM_ID}")`,
  `delete("team:${ADMIN_TEAM_ID}")`,
];

const functionOnlyCollections = new Set(['translation_cache', 'rate_limits']);

function permissionsForCollection(collectionId) {
  if (functionOnlyCollections.has(collectionId)) {
    return [];
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
      { type: 'string', key: 'categoryId', size: 36, required: false },
      { type: 'string', key: 'subcategoryId', size: 36, required: false },
      { type: 'string', key: 'difficulty', size: 10, required: false, default: 'easy' },
      { type: 'integer', key: 'durationSeconds', required: false, default: 0 },
      { type: 'boolean', key: 'isPremium', required: false, default: false },
    ],
    indexes: [
      { key: 'idx_category', type: 'key', attributes: ['categoryId'] },
    ],
  },
  {
    id: 'rhyme_categories',
    name: 'Rhyme Categories',
    attrs: [
      { type: 'string', key: 'nameOlChiki', size: 255, required: true },
      { type: 'string', key: 'nameLatin', size: 255, required: true },
      { type: 'string', key: 'iconName', size: 50, required: false, default: 'child_care' },
      { type: 'integer', key: 'order', required: false, default: 0 },
    ],
    indexes: [],
  },
  {
    id: 'rhyme_subcategories',
    name: 'Rhyme Subcategories',
    attrs: [
      { type: 'string', key: 'categoryId', size: 36, required: true },
      { type: 'string', key: 'nameOlChiki', size: 255, required: true },
      { type: 'string', key: 'nameLatin', size: 255, required: true },
      { type: 'integer', key: 'order', required: false, default: 0 },
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
      { type: 'string', key: 'cacheKey', size: 1024, required: true },
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
      { type: 'integer', key: 'count', required: true, default: 0 },
      { type: 'integer', key: 'windowStart', required: true, default: 0 },
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
    allowedExtensions: ['mp4', 'webm', 'mov'],
    maxFileSize: 104857600, // 100MB
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
    await api('POST', `/databases/${DATABASE_ID}/collections`, {
      collectionId: col.id,
      name: col.name,
      documentSecurity: false,
      permissions,
    });
    await api('PATCH', `/databases/${DATABASE_ID}/collections/${col.id}`, {
      name: col.name,
      documentSecurity: false,
      permissions,
    });

    // Create attributes
    for (const attr of col.attrs) {
      const path = `/databases/${DATABASE_ID}/collections/${col.id}/attributes`;
      console.log(`  📌 Attr: ${attr.key} (${attr.type})`);

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
    const permissions = [
      'read("any")',
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
    await api('PATCH', `/storage/buckets/${bucket.id}`, {
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
