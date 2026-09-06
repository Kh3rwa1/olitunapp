import { createHash } from 'node:crypto';
import { validateRestorePayload } from './restore_backup.js';

const id = value => createHash('sha256').update(value).digest('hex').slice(0, 32);
const fail = (message, status = 409) => Object.assign(new Error(message), { status, code: status });
const notFound = error => error.code === 404 || error.status === 404;
const phases = new Set(['prepare', 'deleting', 'restoring', 'complete']);

// Each content batch and its checkpoint commit together. The shared journal
// document is the optimistic concurrency fence, not a process-local lock or
// an expiring lease that a paused worker can outlive.
export async function runResumableRestore({
  databases, storage, fileId, restoreId, actorUserId, databaseId, bucketId,
  collectionIds, sanitizeDocument, ensureSafetyBackup, pageQueries,
  journalCollectionId = 'admin_restore_jobs', batchSize = 20,
  maxSteps = 50, budgetMs = 6000,
}) {
  if (!fileId || typeof fileId !== 'string') throw fail('Missing backup file ID.', 400);
  if (restoreId !== undefined &&
      (typeof restoreId !== 'string' || !/^[a-zA-Z0-9][a-zA-Z0-9._-]{0,35}$/.test(restoreId))) {
    throw fail('Invalid restore operation ID.', 400);
  }
  if (!Number.isInteger(batchSize) || batchSize < 1 || batchSize > 20) {
    throw fail('Invalid restore batch size.', 400);
  }
  if (typeof databases.createTransaction !== 'function' ||
      typeof databases.updateTransaction !== 'function') {
    throw fail('Restore requires Appwrite transactions and a private restore journal.', 503);
  }
  const raw = Buffer.from(await storage.getFileDownload(bucketId, fileId));
  let payload;
  try { payload = JSON.parse(raw.toString('utf8')); }
  catch { throw fail('Invalid restore backup: file is not valid JSON.', 400); }
  validateRestorePayload(payload, { databaseId, collectionIds });
  const digest = createHash('sha256').update(raw).digest('hex');
  const jobId = restoreId || id(`restore:${databaseId}:${bucketId}:${fileId}`);
  const plan = collectionIds.map(collectionId => ({
    collectionId,
    documents: payload.collections[collectionId].map(doc => ({
      id: doc.$id, data: sanitizeDocument(doc), permissions: [...doc.$permissions],
    })),
  }));
  const address = { databaseId, collectionId: journalCollectionId, documentId: 'active' };
  const historyId = id(`restore-job:${jobId}`);

  function decode(document) {
    let state;
    try { state = JSON.parse(document.payload); }
    catch { throw fail('Restore journal is unreadable; do not restart the restore.'); }
    if (state.version !== 1 || !phases.has(state.phase) ||
        typeof state.jobId !== 'string' || typeof state.fileId !== 'string' ||
        typeof state.digest !== 'string' || typeof state.safetyFileId !== 'string' ||
        !Number.isInteger(state.collectionIndex) || state.collectionIndex < 0 ||
        state.collectionIndex > plan.length || !Number.isInteger(state.offset) || state.offset < 0 ||
        !state.deleted || !state.restored) {
      throw fail('Restore journal is invalid; manual investigation is required.');
    }
    for (const collectionId of collectionIds) {
      if (!Number.isSafeInteger(state.deleted[collectionId]) || state.deleted[collectionId] < 0 ||
          !Number.isSafeInteger(state.restored[collectionId]) || state.restored[collectionId] < 0) {
        throw fail('Restore journal counters are invalid.');
      }
    }
    if (state.phase !== 'prepare' && state.backup?.fileId !== state.safetyFileId) {
      throw fail('Restore safety backup reference is missing or invalid.');
    }
    return state;
  }
  function bind(state) {
    if (state.jobId !== jobId || state.fileId !== fileId || state.digest !== digest ||
        state.databaseId !== databaseId || state.bucketId !== bucketId ||
        state.safetyFileId !== id(`restore-safety:${databaseId}:${jobId}`)) {
      throw fail('Another restore or a changed backup owns the checkpoint. Resume the original operation.');
    }
    for (const { collectionId, documents } of plan) {
      if (state.restored[collectionId] > documents.length) throw fail('Restore count exceeds backup.');
    }
    if (state.phase === 'restoring' && state.collectionIndex < plan.length &&
        state.offset > plan[state.collectionIndex].documents.length) {
      throw fail('Restore checkpoint exceeds the validated backup.');
    }
  }
  async function transaction(work) {
    const tx = await databases.createTransaction({ ttl: 15 });
    if (!tx?.$id) throw fail('Restore transaction could not be established.', 503);
    let committed = false;
    try {
      const txAddress = { ...address, transactionId: tx.$id };
      const result = await work(txAddress, tx.$id);
      await databases.updateTransaction({ transactionId: tx.$id, commit: true });
      committed = true;
      return result;
    } finally {
      if (!committed) {
        try { await databases.updateTransaction({ transactionId: tx.$id, rollback: true }); }
        catch { /* A commit may have succeeded before its response was lost. Retry reads the checkpoint. */ }
      }
    }
  }
  async function save(txAddress, state) {
    const data = { payload: JSON.stringify(state) };
    await databases.updateDocument({ ...txAddress, data });
    await databases.updateDocument({ ...txAddress, documentId: historyId, data });
    return state;
  }

  let state = await transaction(async txAddress => {
    let previous;
    try { previous = decode(await databases.getDocument(txAddress)); }
    catch (error) { if (!notFound(error)) throw error; }
    let history;
    try { history = decode(await databases.getDocument({ ...txAddress, documentId: historyId })); }
    catch (error) { if (!notFound(error)) throw error; }
    if (history) {
      bind(history);
      if (previous?.jobId !== jobId) {
        throw fail('This operation already ended or lost its active fence. Use a new restore ID only for a new restore.');
      }
      bind(previous);
      if (JSON.stringify(history) !== JSON.stringify(previous)) {
        throw fail('Restore history and active checkpoint disagree. Do not reset either record.');
      }
      return save(txAddress, previous);
    }
    if (previous?.jobId === jobId) throw fail('Restore history is missing; do not reset its checkpoint.');
    if (previous && previous.phase !== 'complete') {
      throw fail(`Restore ${previous.jobId} is unfinished. Resume backup ${previous.fileId} first.`);
    }
    const fresh = {
      version: 1, jobId, fileId, digest, databaseId, bucketId, actorUserId,
      phase: 'prepare', collectionIndex: 0, offset: 0,
      safetyFileId: id(`restore-safety:${databaseId}:${jobId}`),
      createdAt: new Date().toISOString(),
      deleted: Object.fromEntries(collectionIds.map(key => [key, 0])),
      restored: Object.fromEntries(collectionIds.map(key => [key, 0])),
    };
    await databases.createDocument({ ...txAddress, documentId: historyId,
      data: { payload: JSON.stringify(fresh) }, permissions: [] });
    if (previous) return save(txAddress, fresh);
    await databases.createDocument({ ...txAddress, data: { payload: JSON.stringify(fresh) }, permissions: [] });
    return fresh;
  });

  const deadline = Date.now() + budgetMs;
  for (let step = 0; step < maxSteps && Date.now() < deadline && state.phase !== 'complete'; step++) {
    // Deterministic create-only safety backup: an ambiguous upload response
    // cannot cause a later retry to replace the original with partial data.
    let backup;
    if (state.phase === 'prepare') {
      backup = await ensureSafetyBackup({ fileId: state.safetyFileId, actorUserId });
      if (backup?.fileId !== state.safetyFileId) throw fail('Safety backup identity mismatch.', 503);
    }
    state = await transaction(async (txAddress, transactionId) => {
      const current = decode(await databases.getDocument(txAddress));
      bind(current);
      if (current.phase === 'prepare') {
        if (!backup) throw fail('Safety backup has not been confirmed.', 503);
        current.backup = backup;
        current.phase = 'deleting';
      } else if (current.phase === 'deleting') {
        if (current.collectionIndex === plan.length) {
          current.phase = 'restoring';
          current.collectionIndex = 0;
          current.offset = 0;
        } else {
          const { collectionId } = plan[current.collectionIndex];
          const page = await databases.listDocuments({
            databaseId, collectionId, transactionId, queries: pageQueries(batchSize),
          });
          if (!Array.isArray(page.documents) || page.documents.length > batchSize) {
            throw fail('Invalid restore deletion page.', 503);
          }
          for (const doc of page.documents) {
            await databases.deleteDocument({ databaseId, collectionId, documentId: doc.$id, transactionId });
          }
          current.deleted[collectionId] += page.documents.length;
          if (page.documents.length === 0) current.collectionIndex++;
        }
      } else if (current.phase === 'restoring') {
        if (current.collectionIndex === plan.length) {
          current.phase = 'complete';
          current.completedAt = new Date().toISOString();
        } else {
          const { collectionId, documents } = plan[current.collectionIndex];
          const batch = documents.slice(current.offset, current.offset + batchSize);
          for (const doc of batch) {
            await databases.createDocument({ databaseId, collectionId,
              documentId: doc.id, data: doc.data, permissions: doc.permissions, transactionId });
          }
          current.offset += batch.length;
          current.restored[collectionId] += batch.length;
          if (current.offset === documents.length) {
            current.collectionIndex++;
            current.offset = 0;
          }
        }
      }
      return save(txAddress, current);
    });
  }
  return {
    complete: state.phase === 'complete', jobId, fileId,
    phase: state.phase, collectionIndex: state.collectionIndex, offset: state.offset,
    backup: state.backup, restored: state.restored, deleted: state.deleted,
  };
}
