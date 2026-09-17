#!/usr/bin/env node
import { Client, Databases, Storage } from 'node-appwrite';
import { pathToFileURL } from 'node:url';
import { VOICE_CLAIMS, VOICE_QUOTAS } from '../functions/santaliVoice/src/store.js';
import { TTS_CACHE_COLLECTION, AUDIO_BUCKET_ID } from '../functions/santaliVoice/src/main.js';

export const voiceSchema = {
  [VOICE_CLAIMS]: {
    strings: {
      userId: 36,
      cacheKey: 64,
      status: 24,
      audioUrl: 2048,
      storageFileId: 64,
    },
    integers: ['chars', 'checkedAt'],
  },
  [VOICE_QUOTAS]: {
    strings: { period: 32 },
    integers: ['used'],
  },
};

export async function setupVoiceSchema({ db, storage, databaseId }) {
  // Ensure audio bucket exists and supports wav
  try {
    const bucket = await storage.getBucket(AUDIO_BUCKET_ID);
    if (!bucket.enabled) throw new Error('Audio bucket is disabled; review it manually.');
  } catch (e) {
    if (e.code === 404) {
      console.log(`Audio bucket ${AUDIO_BUCKET_ID} not found; please create it in Appwrite console.`);
    }
  }

  for (const [collectionId, spec] of Object.entries(voiceSchema)) {
    const base = { databaseId, collectionId };
    try {
      await db.createCollection({
        ...base,
        name: collectionId,
        permissions: [],
        documentSecurity: false,
        enabled: true,
      });
    } catch (e) {
      if (e.code !== 409) throw e;
    }

    if (spec.strings) {
      for (const [key, size] of Object.entries(spec.strings)) {
        try {
          await db.createStringAttribute({
            ...base,
            key,
            size,
            required: key === 'userId' || key === 'status' || key === 'period' || key === 'cacheKey',
          });
        } catch (e) {
          if (e.code !== 409) throw e;
        }
      }
    }

    if (spec.integers) {
      for (const key of spec.integers) {
        try {
          await db.createIntegerAttribute({ ...base, key, required: false, min: 0 });
        } catch (e) {
          if (e.code !== 409) throw e;
        }
      }
    }
  }

  // Ensure index on tts_cache.createdAt for retention sweeps
  try {
    await db.createIndex({
      databaseId,
      collectionId: TTS_CACHE_COLLECTION,
      key: 'idx_tts_cache_created',
      type: 'key',
      attributes: ['createdAt'],
      orders: ['DESC'],
    });
  } catch (e) {
    if (e.code !== 409) {
      // Best-effort index creation
    }
  }

  // Ensure index on voice_claims.userId for account deletion
  try {
    await db.createIndex({
      databaseId,
      collectionId: VOICE_CLAIMS,
      key: 'idx_voice_claims_user',
      type: 'key',
      attributes: ['userId'],
      orders: ['ASC'],
    });
  } catch (e) {
    if (e.code !== 409) {
      // Best-effort index creation
    }
  }
}

async function main() {
  if (!process.argv.includes('--apply')) {
    console.log(
      JSON.stringify(
        {
          dryRun: true,
          collections: voiceSchema,
          audioBucketId: AUDIO_BUCKET_ID,
          ttsCacheCollection: TTS_CACHE_COLLECTION,
          note: 'No service calls. Use --apply with explicit Appwrite environment to provision.',
        },
        null,
        2
      )
    );
    return;
  }

  const {
    APPWRITE_ENDPOINT: endpoint,
    APPWRITE_PROJECT_ID: project,
    APPWRITE_API_KEY: key,
    APPWRITE_DATABASE_ID: databaseId,
  } = process.env;

  if (!endpoint || !project || !key || !databaseId || new URL(endpoint).protocol !== 'https:') {
    throw new Error('Explicit HTTPS endpoint, project, key, and existing database ID required.');
  }

  const client = new Client().setEndpoint(endpoint).setProject(project).setKey(key);
  await setupVoiceSchema({ db: new Databases(client), storage: new Storage(client), databaseId });
  console.log('Santali Voice schema verified.');
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((err) => {
    console.error('Santali Voice setup failed:', err?.message || err);
    process.exitCode = 1;
  });
}
