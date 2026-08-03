/**
 * Snapshot Appwrite Schema.
 * Fetches collections and their attributes from Appwrite and saves them
 * to test/fixtures/schema/<collection_id>.json for conformance testing and drift detection.
 *
 * Usage:
 *   node scripts/snapshot_appwrite_schema.mjs
 */

import { readFileSync, writeFileSync, mkdirSync } from 'fs';
import { join } from 'path';

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

if (!PROJECT_ID) {
  console.error('❌ Error: Set APPWRITE_PROJECT_ID or specify projectId in appwrite.config.json');
  process.exit(1);
}

if (!API_KEY) {
  console.error('❌ Error: Set APPWRITE_API_KEY environment variable');
  process.exit(1);
}

const headers = {
  'Content-Type': 'application/json',
  'X-Appwrite-Project': PROJECT_ID,
  'X-Appwrite-Key': API_KEY,
};

async function api(method, path, body = null) {
  const opts = { method, headers };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(`${ENDPOINT}${path}`, opts);
  const text = await res.text();
  if (!res.ok) {
    throw new Error(`${res.status} ${method} ${path}: ${text}`);
  }
  return text ? JSON.parse(text) : null;
}

async function run() {
  console.log('🚀 Snapshotting Appwrite Database Schema...');
  
  // Create output directory
  const schemaDir = './test/fixtures/schema';
  try {
    mkdirSync(schemaDir, { recursive: true });
  } catch (_) {}

  // Complete list of database collections
  const collections = [
    { id: 'categories', name: 'Categories' },
    { id: 'rhyme_subcategories', name: 'Rhyme Subcategories' },
    { id: 'lessons', name: 'Lessons' },
    { id: 'quizzes', name: 'Quizzes' },
    { id: 'letters', name: 'Letters' },
    { id: 'numbers', name: 'Numbers' },
    { id: 'words', name: 'Words' },
    { id: 'sentences', name: 'Sentences' },
    { id: 'rhymes', name: 'Rhymes' },
    { id: 'banners', name: 'Banners' },
    { id: 'circle_events', name: 'Circle Events' },
    { id: 'circle_members', name: 'Circle Members' },
    { id: 'weekly_circles', name: 'Weekly Circles' },
    { id: 'learning_circle_templates', name: 'Learning Circle Templates' },
    { id: 'translation_cache', name: 'Translation Cache' },
    { id: 'rate_limits', name: 'Translator Rate Limits' },
    { id: 'app_settings', name: 'App Settings' },
    { id: 'bravo_messages', name: 'Bravo Messages' },
    { id: 'badges', name: 'Badges' },
    { id: 'user_badges', name: 'User Badges' },
    { id: 'mission_templates', name: 'Mission Templates' },
    { id: 'reward_messages', name: 'Reward Messages' },
    { id: 'quiz_feedback_messages', name: 'Quiz Feedback Messages' },
    { id: 'gamification_config', name: 'Gamification Config' },
    { id: 'admin_audit_logs', name: 'Admin Audit Logs' },
    { id: 'learning_analytics_events', name: 'Learning Analytics Events' },
    { id: 'learning_analytics_daily_rollups', name: 'Learning Analytics Daily Rollups' },
    { id: 'reward_events', name: 'Reward Events' },
    { id: 'user_mistakes', name: 'User Mistakes' },
    { id: 'mistake_review_sessions', name: 'Mistake Review Sessions' },
    { id: 'bakhed_lyrics', name: 'Bakhed Lyrics' },
    { id: 'bakhed_vocabulary', name: 'Bakhed Vocabulary' },
    { id: 'bakhed_cultural_notes', name: 'Bakhed Cultural Notes' },
    { id: 'bakhed_listening_progress', name: 'Bakhed Listening Progress' },
    { id: 'daily_affirmations', name: 'Daily Affirmations' },
    { id: 'course_purchases', name: 'Course Purchases' },
    { id: 'payment_claims', name: 'Payment Claims' },
    { id: 'refund_claims', name: 'Refund Claims' },
    { id: 'binti_guru_waitlist', name: 'Binti Guru Waitlist' }
  ];


  for (const col of collections) {
    const colId = col.id;
    console.log(`Snapshotting attributes for collection: ${colId} ("${col.name}")`);

    // Fetch attributes
    const attrsRes = await api('GET', `/databases/${DATABASE_ID}/collections/${colId}/attributes`);
    const rawAttributes = attrsRes.attributes || [];

    // Fetch indexes (fail closed on index retrieval errors)
    const idxRes = await api('GET', `/databases/${DATABASE_ID}/collections/${colId}/indexes`);
    const rawIndexes = idxRes.indexes || [];
    const mappedIndexes = rawIndexes.map(idx => {
      const spec = {
        key: idx.key,
        type: idx.type,
        attributes: idx.attributes || []
      };
      if (idx.orders && idx.orders.length > 0) {
        spec.orders = idx.orders;
      }
      return spec;
    });

    // Map attributes to clean spec
    const mappedAttributes = rawAttributes.map(attr => {
      const spec = {
        key: attr.key,
        type: attr.type,
      };
      if (attr.size !== undefined && attr.size !== null) {
        spec.size = attr.size;
      }
      spec.array = attr.array || false;
      spec.required = attr.required || false;
      
      // Handle enum elements
      if (attr.elements && attr.elements.length > 0) {
        spec.elements = attr.elements;
      }
      
      // Handle min/max for integer/float
      if (attr.min !== undefined && attr.min !== null) {
        spec.min = attr.min;
      }
      if (attr.max !== undefined && attr.max !== null) {
        spec.max = attr.max;
      }

    });

    // Write fixture JSON
    const fixturePath = join(schemaDir, `${colId}.json`);
    const output = {
      collectionId: colId,
      attributes: mappedAttributes,
    };
    if (mappedIndexes.length > 0) {
      output.indexes = mappedIndexes;
    }

    writeFileSync(fixturePath, JSON.stringify(output, null, 2), 'utf8');
    console.log(`  ✓ Wrote schema to: ${fixturePath}`);
  }

  console.log('\n🎉 Database schema snapshot completed successfully!');
}

run().catch(err => {
  console.error('❌ Schema snapshot failed:', err);
  process.exit(1);
});
