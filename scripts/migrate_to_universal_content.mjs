/**
 * Idempotent Migration Script for Olitun Universal Content System
 * Maps legacy database documents to updated universal attributes.
 * Run: node scripts/migrate_to_universal_content.mjs [--dry-run]
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

const DRY_RUN = process.argv.includes('--dry-run');

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

// Pre-defined fallback bounding-box strokes tracing template for letters & numbers
function getFallbackTracing(char) {
  return {
    glyph: char,
    guide: 'dotted',
    strokeWidth: 12.0,
    tolerance: 0.6,
    showDirectionArrows: true,
    playAudioOnComplete: true,
    requiredCompletions: 1,
    strokes: [
      {
        id: 'stroke_fallback',
        order: 0,
        direction: 'custom',
        path: [
          { x: 0.2, y: 0.2, isControlPoint: false },
          { x: 0.8, y: 0.2, isControlPoint: false },
          { x: 0.8, y: 0.8, isControlPoint: false },
          { x: 0.2, y: 0.8, isControlPoint: false },
          { x: 0.2, y: 0.2, isControlPoint: false }
        ]
      }
    ]
  };
}

async function migrateCollection(collectionId, mapper) {
  console.log(`\n=================== Migrating ${collectionId} ===================`);
  try {
    const listRes = await api('GET', `/databases/${DATABASE_ID}/collections/${collectionId}/documents?limit=1000`);
    const docs = listRes.documents || [];
    console.log(`Found ${docs.length} documents in ${collectionId}`);

    let migratedCount = 0;
    for (const doc of docs) {
      const payload = mapper(doc);
      if (!payload) continue;

      if (DRY_RUN) {
        console.log(`[DRY-RUN] Would update doc ID: ${doc.$id}`);
        console.log(JSON.stringify(payload, null, 2));
      } else {
        await api('PATCH', `/databases/${DATABASE_ID}/collections/${collectionId}/documents/${doc.$id}`, {
          data: payload
        });
        migratedCount++;
      }
    }
    console.log(`Successfully migrated ${migratedCount}/${docs.length} documents in ${collectionId}`);
  } catch (e) {
    console.error(`❌ Migration failed for ${collectionId}: ${e.message}`);
  }
}

async function run() {
  console.log(`Starting migration... (Dry Run: ${DRY_RUN})`);

  // 1. Migrate Letters
  await migrateCollection('letters', (doc) => {
    // If already has tracing or hero_media, we might still want to refresh blocks
    const mediaUrl = doc.animationUrl || doc.imageUrl;
    let heroMedia = null;
    if (mediaUrl) {
      heroMedia = {
        url: mediaUrl,
        fileId: '',
        kind: doc.animationUrl ? 'lottie' : 'image'
      };
    }

    const blocks = [];
    blocks.add = (block) => blocks.push(block);

    blocks.add({
      id: 'glyph_block',
      order: 0,
      type: 'glyph',
      olChiki: doc.charOlChiki || '',
      latin: doc.transliterationLatin || '',
      audioUrl: doc.audioUrl
    });

    if (doc.exampleWordLatin || doc.exampleWordOlChiki) {
      blocks.add({
        id: 'example_text',
        order: 1,
        type: 'text',
        markdown: `**Example Word:** ${doc.exampleWordOlChiki || ''} (${doc.exampleWordLatin || ''})`
      });
    }

    const tracing = getFallbackTracing(doc.charOlChiki || 'ᱚ');

    return {
      hero_media: heroMedia ? JSON.stringify(heroMedia) : null,
      blocks: JSON.stringify(blocks),
      tracing: JSON.stringify(tracing)
    };
  });

  // 2. Migrate Numbers
  await migrateCollection('numbers', (doc) => {
    const mediaUrl = doc.animationUrl || doc.imageUrl;
    let heroMedia = null;
    if (mediaUrl) {
      heroMedia = {
        url: mediaUrl,
        fileId: '',
        kind: doc.animationUrl ? 'lottie' : 'image'
      };
    }

    const blocks = [
      {
        id: 'glyph_block',
        order: 0,
        type: 'glyph',
        olChiki: doc.numeral || '',
        latin: doc.nameLatin || '',
        audioUrl: doc.audioUrl
      }
    ];

    const tracing = getFallbackTracing(doc.numeral || '᱐');

    return {
      hero_media: heroMedia ? JSON.stringify(heroMedia) : null,
      blocks: JSON.stringify(blocks),
      tracing: JSON.stringify(tracing)
    };
  });

  // 3. Migrate Words
  await migrateCollection('words', (doc) => {
    const mediaUrl = doc.animationUrl || doc.imageUrl;
    let heroMedia = null;
    if (mediaUrl) {
      heroMedia = {
        url: mediaUrl,
        fileId: '',
        kind: doc.animationUrl ? 'lottie' : 'image'
      };
    }

    const blocks = [];
    if (doc.meaning) {
      blocks.push({
        id: 'meaning_block',
        order: 0,
        type: 'text',
        markdown: `### Meaning\n${doc.meaning}`
      });
    }
    if (doc.usage) {
      blocks.push({
        id: 'usage_block',
        order: blocks.length,
        type: 'text',
        markdown: `### Usage\n${doc.usage}`
      });
    }
    if (doc.audioUrl) {
      blocks.push({
        id: 'audio_block',
        order: blocks.length,
        type: 'audio',
        media: {
          url: doc.audioUrl,
          fileId: '',
          kind: 'audio'
        },
        transcript: doc.pronunciation
      });
    }

    return {
      hero_media: heroMedia ? JSON.stringify(heroMedia) : null,
      blocks: JSON.stringify(blocks)
    };
  });

  // 4. Migrate Sentences
  await migrateCollection('sentences', (doc) => {
    const mediaUrl = doc.animationUrl || doc.imageUrl;
    let heroMedia = null;
    if (mediaUrl) {
      heroMedia = {
        url: mediaUrl,
        fileId: '',
        kind: doc.animationUrl ? 'lottie' : 'image'
      };
    }

    const blocks = [];
    if (doc.meaning) {
      blocks.push({
        id: 'meaning_block',
        order: 0,
        type: 'text',
        markdown: `### Translation\n${doc.meaning}`
      });
    }
    if (doc.usage) {
      blocks.push({
        id: 'usage_block',
        order: blocks.length,
        type: 'text',
        markdown: `### Context / Usage\n${doc.usage}`
      });
    }
    if (doc.audioUrl) {
      blocks.push({
        id: 'audio_block',
        order: blocks.length,
        type: 'audio',
        media: {
          url: doc.audioUrl,
          fileId: '',
          kind: 'audio'
        },
        transcript: doc.pronunciation
      });
    }

    return {
      hero_media: heroMedia ? JSON.stringify(heroMedia) : null,
      blocks: JSON.stringify(blocks)
    };
  });

  // 5. Migrate Lessons (Legacy Blocks transformation)
  await migrateCollection('lessons', (doc) => {
    const mediaUrl = doc.heroMediaUrl || doc.videoUrl || doc.animationUrl || doc.imageUrl || doc.thumbnailUrl;
    let heroMedia = null;
    if (mediaUrl) {
      heroMedia = {
        url: mediaUrl,
        fileId: '',
        kind: doc.heroMediaType || 'image',
        posterUrl: doc.heroPosterUrl
      };
    }

    // Parse existing blocks and map them
    let legacyBlocks = [];
    if (doc.blocks) {
      try {
        legacyBlocks = typeof doc.blocks === 'string' ? JSON.parse(doc.blocks) : doc.blocks;
      } catch (_) {}
    }

    const mappedBlocks = [];
    if (Array.isArray(legacyBlocks)) {
      for (let i = 0; i < legacyBlocks.length; i++) {
        const b = legacyBlocks[i];
        if (b.type === 'text') {
          mappedBlocks.push({
            id: b.id || `text_${i}`,
            order: i,
            type: 'text',
            markdown: b.textLatin || b.markdown || ''
          });
        } else if (b.type === 'image') {
          mappedBlocks.push({
            id: b.id || `image_${i}`,
            order: i,
            type: 'image',
            media: {
              url: b.imageUrl || '',
              fileId: '',
              kind: 'image'
            },
            caption: b.textLatin
          });
        } else if (b.type === 'audio') {
          mappedBlocks.push({
            id: b.id || `audio_${i}`,
            order: i,
            type: 'audio',
            media: {
              url: b.audioUrl || '',
              fileId: '',
              kind: 'audio'
            },
            transcript: b.textLatin
          });
        }
      }
    }

    return {
      hero_media: heroMedia ? JSON.stringify(heroMedia) : null,
      blocks: JSON.stringify(mappedBlocks)
    };
  });

  // 6. Migrate Rhymes
  await migrateCollection('rhymes', (doc) => {
    let heroMedia = null;
    if (doc.thumbnailUrl) {
      heroMedia = {
        url: doc.thumbnailUrl,
        fileId: '',
        kind: 'image'
      };
    }

    const blocks = [];
    if (doc.contentOlChiki) {
      blocks.push({
        id: 'lyric_ol_chiki',
        order: 0,
        type: 'text',
        markdown: `### ᱚᱞ ᱪᱤᱠᱤ\n${doc.contentOlChiki}`
      });
    }
    if (doc.contentLatin) {
      blocks.push({
        id: 'lyric_latin',
        order: blocks.length,
        type: 'text',
        markdown: `### Transliteration / English\n${doc.contentLatin}`
      });
    }
    if (doc.audioUrl) {
      blocks.push({
        id: 'audio_block',
        order: blocks.length,
        type: 'audio',
        media: {
          url: doc.audioUrl,
          fileId: '',
          kind: 'audio'
        }
      });
    }

    return {
      hero_media: heroMedia ? JSON.stringify(heroMedia) : null,
      blocks: JSON.stringify(blocks)
    };
  });

  console.log('\nMigration complete! 🎉');
}

run().catch((e) => console.error('❌ Migration failed:', e));
