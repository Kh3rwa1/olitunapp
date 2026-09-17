import { Account, Client, Databases, Storage } from 'node-appwrite';
import { createHash } from 'node:crypto';
import { fail, StudioError, validateBody, INPUT_BUCKET, MAX_BYTES, wavDuration, identifyDocument } from './validation.js';
import { Store, digest, limits } from './store.js';
import { Sarvam, TERMINAL } from './sarvam.js';

export function config(env) {
  const endpoint = env.APPWRITE_FUNCTION_API_ENDPOINT || env.APPWRITE_ENDPOINT;
  const projectId = env.APPWRITE_FUNCTION_PROJECT_ID || env.APPWRITE_PROJECT_ID;
  const apiKey = env.APPWRITE_FUNCTION_API_KEY || env.APPWRITE_API_KEY;
  if (!endpoint || !projectId || !apiKey || !env.SARVAM_API_KEY || (env.AI_STUDIO_HMAC_SECRET || '').length < 32 || env.AI_STUDIO_ENABLED !== 'true') fail('SERVICE_UNAVAILABLE', 'AI Studio is unavailable.', 503);
  if (new URL(endpoint).protocol !== 'https:') fail('CONFIGURATION_ERROR', 'AI Studio is unavailable.', 503);
  return { endpoint, projectId, apiKey, policy: limits(env), databaseId: env.APPWRITE_DATABASE_ID || 'olitun_db', secret: env.AI_STUDIO_HMAC_SECRET };
}
export async function authenticate(req, cfg, makeAccount = client => new Account(client)) {
  const headers = Object.fromEntries(Object.entries(req.headers || {}).map(([k, v]) => [k.toLowerCase(), v]));
  const bearer = typeof headers.authorization === 'string' && /^Bearer /i.test(headers.authorization) ? headers.authorization.slice(7) : '';
  const jwt = bearer || headers['x-appwrite-user-jwt'];
  if (typeof jwt !== 'string' || !jwt.trim() || jwt.length > 8192) fail('UNAUTHENTICATED', 'Sign in to use AI Studio.', 401);
  const client = new Client().setEndpoint(cfg.endpoint).setProject(cfg.projectId).setJWT(jwt.trim());
  try {
    const user = await makeAccount(client).get();
    if (!user?.$id || user.status === false) fail('UNAUTHENTICATED', 'Sign in to use AI Studio.', 401);
    return { userId: user.$id, client };
  } catch { fail('UNAUTHENTICATED', 'Sign in to use AI Studio.', 401); }
}
export async function privateInput({ storage, userStorage, userId, fileId }) {
  const bucket = await storage.getBucket({ bucketId: INPUT_BUCKET });
  if (!bucket.fileSecurity || !bucket.enabled || bucket.maximumFileSize > MAX_BYTES || !Array.isArray(bucket.$permissions) || bucket.$permissions.some(p => p !== 'create("users")')) fail('STORAGE_UNAVAILABLE', 'Private input storage is unavailable.', 503);
  const params = { bucketId: INPUT_BUCKET, fileId };
  let file;
  try { file = await userStorage.getFile(params); } catch { fail('FILE_NOT_FOUND', 'Private input file not found.', 404); }
  const allowed = ['read', 'update', 'delete'].map(p => `${p}("user:${userId}")`);
  if (!Array.isArray(file.$permissions) || !file.$permissions.includes(allowed[0]) || !file.$permissions.includes(allowed[2]) || file.$permissions.some(p => !allowed.includes(p))) fail('FILE_NOT_OWNED', 'Use your own private input file.', 403);
  if (!Number.isSafeInteger(file.sizeOriginal) || file.sizeOriginal < 1 || file.sizeOriginal > MAX_BYTES || file.chunksUploaded !== file.chunksTotal) fail('INVALID_FILE', 'Upload a complete file no larger than 10 MB.');
  const bytes = Buffer.from(await userStorage.getFileDownload(params));
  if (bytes.length !== file.sizeOriginal || bytes.length > MAX_BYTES) fail('INVALID_FILE', 'Input file changed or exceeds the size limit.');
  return bytes;
}
function publicJob(job) {
  return { jobId: job.$id, status: job.status, language: job.language,
    ...(['completed', 'partially_completed'].includes(job.status) ? { text: job.text } : {}) };
}

export async function execute({ body, userId, store, provider, input, policy, secret, now = Date.now }) {
  await store.requestLimit(userId);
  if (body.action === 'ocrStatus') {
    const job = await store.get(body.jobId);
    if (!job || job.userId !== userId || job.action !== 'ocrStart') fail('JOB_NOT_FOUND', 'OCR job not found.', 404);
    if (TERMINAL.includes(job.status) || !job.providerJobId || now() - job.checkedAt < 12000) return publicJob(job);
    await store.ocrLimit();
    const result = await provider.ocrStatus(job.providerJobId);
    if (
      Array.isArray(result?.documents) &&
      result.documents.every(
        (document) => document?.status === 'failed' && (document?.error ?? document?.message) !== undefined,
      )
    ) {
      fail('PROVIDER_UNAVAILABLE', 'Sarvam could not read this document. Please retry with a clearer page.', 502);
    }
    const updated = await store.update(job.$id, { ...result, checkedAt: now() });
    return publicJob(updated);
  }
  let bytes; let file; let duration;
  if (body.action !== 'translate') {
    bytes = await input(body.fileId);
    if (body.action === 'transcribe') duration = wavDuration(bytes);
    else file = identifyDocument(bytes);
  }
  const fingerprint = bytes ? createHash('sha256').update(bytes).digest('hex') : body.text;
  // request-v2: the v1 OCR parser stored completed records with empty text
  // for the old provider schema; bumping the version bypasses poisoned rows.
  const id = digest(secret, ['request-v2', userId, body.action, body.language, fingerprint]);
  const claimed = await store.claim(id, userId, body.action, body.language, bytes ? { fileFingerprint: fingerprint } : {});
  if (!claimed) {
    const old = await store.get(id);
    if (!old || old.userId !== userId) fail('SERVICE_UNAVAILABLE', 'AI Studio is unavailable.', 503);
    if (body.action === 'ocrStart') return publicJob(old);
    if (old.status === 'completed') return { text: old.text, language: body.action === 'translate' ? 'sat-IN' : body.language, cached: true };
    fail('REQUEST_NOT_REPLAYABLE', 'This request is pending or could not be confirmed. It will not be submitted again automatically.', 409);
  }
  try {
    await store.reserve(userId, policy[body.action], policy);
    if (body.action === 'ocrStart') {
      await store.ocrLimit();
      const providerJobId = await provider.ocrStart(bytes, body.language, file);
      const job = await store.update(id, { providerJobId, status: 'processing', checkedAt: now() });
      return publicJob(job);
    }
    const text = body.action === 'translate' ? await provider.translate(body.text, body.language) : await provider.transcribe(bytes, body.language);
    await store.update(id, { status: 'completed', text });
    return { text, language: body.action === 'translate' ? 'sat-IN' : body.language, ...(duration ? { durationSeconds: duration } : {}), cached: false };
  } catch (e) {
    // Never reset a claim or refund: timeout/crash may have occurred after a paid submission.
    await store.update(id, { status: 'failed' }).catch(() => {});
    throw e;
  }
}
export function createHandler({ env = process.env, fetchImpl = fetch, authenticateImpl = authenticate, services } = {}) {
  return async ({ req, res }) => {
    try {
      if (req.method !== 'POST') fail('METHOD_NOT_ALLOWED', 'Use POST.', 405);
      const body = validateBody(req.bodyJson || req.body);
      const cfg = config(env);
      const identity = await authenticateImpl(req, cfg);
      const client = new Client().setEndpoint(cfg.endpoint).setProject(cfg.projectId).setKey(cfg.apiKey);
      const deps = services ? services(cfg, identity) : {
        store: new Store(new Databases(client), cfg.databaseId, cfg.secret),
        provider: new Sarvam(env.SARVAM_API_KEY, fetchImpl),
        input: fileId => privateInput({ storage: new Storage(client), userStorage: new Storage(identity.client), userId: identity.userId, fileId }),
      };
      const data = await execute({ body, userId: identity.userId, ...deps, policy: cfg.policy, secret: cfg.secret });
      return res.json({ success: true, data }, 200);
    } catch (e) {
      const known = e instanceof StudioError;
      return res.json({ success: false, message: known ? e.message : 'AI Studio could not complete the request.', error: known ? e.code : 'SERVICE_UNAVAILABLE' }, known ? e.status : 503);
    }
  };
}
export default createHandler();
