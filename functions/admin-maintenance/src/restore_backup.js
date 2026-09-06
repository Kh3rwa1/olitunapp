// Runtime validation shared by the destructive restore path and its tests.
// A valid backup must describe every collection that restore will replace.
const own = (value, key) => Object.prototype.hasOwnProperty.call(value, key);
const object = value => value !== null && typeof value === 'object' && !Array.isArray(value);

function invalid(message) {
  throw Object.assign(new Error(`Invalid restore backup: ${message}`), { status: 400 });
}

export function validateRestorePayload(payload, { databaseId, collectionIds }) {
  if (!object(payload)) invalid('payload must be an object.');
  if (payload.schemaVersion !== 1) invalid('unsupported schemaVersion.');
  if (typeof payload.createdAt !== 'string' || !Number.isFinite(Date.parse(payload.createdAt))) {
    invalid('createdAt must be a valid timestamp.');
  }
  if (payload.databaseId !== databaseId) invalid('databaseId does not match the restore target.');
  if (!object(payload.collections)) invalid('collections must be an object.');
  if (!object(payload.counts)) invalid('counts must be an object.');

  for (const collectionId of collectionIds) {
    if (!own(payload.collections, collectionId) || !Array.isArray(payload.collections[collectionId])) {
      invalid(`collection ${collectionId} must be explicitly present as an array.`);
    }
    const documents = payload.collections[collectionId];
    if (!own(payload.counts, collectionId) || !Number.isSafeInteger(payload.counts[collectionId]) ||
        payload.counts[collectionId] !== documents.length) {
      invalid(`document count mismatch for ${collectionId}.`);
    }
    const ids = new Set();
    for (const doc of documents) {
      if (!object(doc) || typeof doc.$id !== 'string' || !/^[a-zA-Z0-9][a-zA-Z0-9._-]{0,35}$/.test(doc.$id)) {
        invalid(`invalid document ID in ${collectionId}.`);
      }
      if (ids.has(doc.$id)) invalid(`duplicate document ID in ${collectionId}.`);
      ids.add(doc.$id);
      if (!Array.isArray(doc.$permissions) || doc.$permissions.some(permission => typeof permission !== 'string')) {
        invalid(`missing or invalid permissions for ${collectionId}/${doc.$id}.`);
      }
    }
  }
  return payload;
}

export async function restoreValidatedContent({
  databases, storage, fileId, databaseId, bucketId, collectionIds,
  deleteCollection, sanitizeDocument,
}) {
  const download = await storage.getFileDownload(bucketId, fileId);
  let payload;
  try {
    // Appwrite may return an ArrayBuffer, Uint8Array, or Node Buffer.
    payload = JSON.parse(Buffer.from(download).toString('utf8'));
  } catch {
    invalid('file is not valid UTF-8 JSON.');
  }
  validateRestorePayload(payload, { databaseId, collectionIds });

  // Materialize every restore record before the first destructive operation.
  // In particular, a malformed later collection must not wipe earlier ones.
  const plan = collectionIds.map(collectionId => ({
    collectionId,
    documents: payload.collections[collectionId].map(doc => ({
      id: doc.$id,
      data: sanitizeDocument(doc),
      permissions: [...doc.$permissions],
    })),
  }));

  const deleted = {};
  for (const { collectionId } of plan) {
    deleted[collectionId] = await deleteCollection(collectionId);
  }
  const restored = {};
  for (const { collectionId, documents } of plan) {
    restored[collectionId] = 0;
    for (const doc of documents) {
      await databases.createDocument(databaseId, collectionId, doc.id, doc.data, doc.permissions);
      restored[collectionId]++;
    }
  }
  return { restored, deleted };
}
