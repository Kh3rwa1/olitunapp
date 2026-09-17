#!/usr/bin/env node
import { Client, Databases, Storage, Permission, Role } from 'node-appwrite';
import { pathToFileURL } from 'node:url';
import { INPUT_BUCKET, MAX_BYTES } from '../functions/aiStudio/src/validation.js';
import { JOBS, QUOTAS } from '../functions/aiStudio/src/store.js';

export const schema = {
  [JOBS]: {
    strings: {
      userId: 36,
      action: 20,
      language: 10,
      status: 24,
      providerJobId: 128,
      fileFingerprint: 64,
      text: 100000,
    },
    integers: ['checkedAt'],
  },
  [QUOTAS]: { strings: { period: 32 }, integers: ['used'] },
};
export async function setup({ db, storage, databaseId }) {
  const bucketParams = { bucketId: INPUT_BUCKET, name: 'AI Studio private inputs', permissions: [Permission.create(Role.users())],
    fileSecurity: true, enabled: true, maximumFileSize: MAX_BYTES, allowedFileExtensions: ['wav', 'png', 'jpg', 'jpeg', 'pdf'],
    compression: 'none', encryption: true, antivirus: true };
  try { await storage.createBucket(bucketParams); }
  catch (e) {
    if (e.code !== 409) throw e;
    const bucket = await storage.getBucket({ bucketId: INPUT_BUCKET });
    if (!bucket.fileSecurity || bucket.maximumFileSize !== MAX_BYTES || JSON.stringify([...bucket.$permissions].sort()) !== JSON.stringify(bucketParams.permissions)) throw new Error('Existing bucket privacy differs; review it manually.');
  }
  for (const [collectionId, spec] of Object.entries(schema)) {
    const base = { databaseId, collectionId };
    try { await db.createCollection({ ...base, name: collectionId, permissions: [], documentSecurity: false, enabled: true }); }
    catch (e) {
      if (e.code !== 409) throw e;
      const collection = await db.getCollection(base);
      if (collection.$permissions.length || collection.documentSecurity) throw new Error('Existing collection privacy differs; review it manually.');
    }
    for (const [key, size] of Object.entries(spec.strings)) {
      try { await db.createStringAttribute({ ...base, key, size, required: true }); }
      catch (e) { if (e.code !== 409) throw e; }
      await verifyAttribute(db, base, key, 'string', size);
    }
    for (const key of spec.integers) {
      try { await db.createIntegerAttribute({ ...base, key, required: true, min: 0 }); }
      catch (e) { if (e.code !== 409) throw e; }
      await verifyAttribute(db, base, key, 'integer');
    }
  }
}
// Existing collections keep working: an attribute missing from a pre-update
// deployment is created here; a conflicting definition fails closed.

async function verifyAttribute(db, base, key, type, size) {
  for (let attempt = 0; attempt < 30; attempt++) {
    const attr = await db.getAttribute({ ...base, key });
    if (attr.type !== type || !attr.required || (size && attr.size !== size)) throw new Error('Existing attribute definition differs; review it manually.');
    if (attr.status === 'available') return;
    if (['failed', 'stuck'].includes(attr.status)) throw new Error('Attribute creation failed.');
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
  throw new Error('Attribute is not available; rerun setup after inspection.');
}
async function main() {
  if (!process.argv.includes('--apply')) {
    console.log(JSON.stringify({ dryRun: true, bucket: INPUT_BUCKET, maximumFileSize: MAX_BYTES, collections: schema, note: 'No service calls. Use --apply with explicit Appwrite environment to provision.' }, null, 2));
    return;
  }
  const { APPWRITE_ENDPOINT: endpoint, APPWRITE_PROJECT_ID: project, APPWRITE_API_KEY: key, APPWRITE_DATABASE_ID: databaseId } = process.env;
  if (!endpoint || !project || !key || !databaseId || new URL(endpoint).protocol !== 'https:') throw new Error('Explicit HTTPS endpoint, project, key and existing database ID required.');
  const client = new Client().setEndpoint(endpoint).setProject(project).setKey(key);
  await setup({ db: new Databases(client), storage: new Storage(client), databaseId });
  console.log('AI Studio schema verified. Function remains disabled until configured separately.');
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch(() => { console.error('AI Studio setup failed. Check schema, permissions and environment; no credentials or provider data logged.'); process.exitCode = 1; });
}
