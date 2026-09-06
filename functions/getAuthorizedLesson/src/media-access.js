// File bytes never pass through the function. Appwrite Storage serves the
// authorized file (including Range requests) using a short-lived bearer token.
export const MEDIA_TTL_MS = 5 * 60 * 1000;
export const MEDIA_HEADERS = { 'cache-control': 'no-store, private', 'pragma': 'no-cache' };

export async function createMediaAccess({ tokens, storage, bucketId, fileId,
  publicEndpoint, projectId, now = Date.now() }) {
  const endpoint = new URL(publicEndpoint);
  if (endpoint.protocol !== 'https:' || endpoint.username || endpoint.password ||
      endpoint.search || endpoint.hash || endpoint.pathname.replace(/\/$/, '') !== '/v1' || !projectId) {
    throw new Error('Invalid public media endpoint configuration');
  }
  // Metadata only: do not call getFileDownload/getFileView (SDK buffers bytes).
  const file = await storage.getFile({ bucketId, fileId });
  const expire = new Date(now + MEDIA_TTL_MS).toISOString();
  const token = await tokens.createFileToken({ bucketId, fileId, expire });
  const expiresAt = Date.parse(token.expire);
  if (typeof token.secret !== 'string' || !token.secret ||
      !Number.isFinite(expiresAt) || expiresAt <= now || expiresAt > now + MEDIA_TTL_MS) {
    throw new Error('Invalid file token response');
  }
  const url = new URL(`${endpoint.toString().replace(/\/$/, '')}/storage/buckets/${encodeURIComponent(bucketId)}/files/${encodeURIComponent(fileId)}/view`);
  url.searchParams.set('project', projectId);
  url.searchParams.set('token', token.secret);
  return {
    ok: true, protocolVersion: 2, transport: 'appwrite-file-token',
    bucketId, fileId, url: url.toString(), expiresAt: token.expire,
    mimeType: file.mimeType, size: file.sizeOriginal,
  };
}

// Only non-secret identities are returned with lesson bodies or cached offline.
export function scopeLessonMedia(value, lessonId, bucketId) {
  if (Array.isArray(value)) return value.map(v => scopeLessonMedia(v, lessonId, bucketId));
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, scopeLessonMedia(v, lessonId, bucketId)]));
  }
  if (typeof value !== 'string') return value;
  const rest = value.match(/\/storage\/buckets\/([a-zA-Z0-9._-]+)\/files\/([a-zA-Z0-9._-]+)(?:[/?]|$)/);
  const custom = value.match(/^appwrite-(?:storage:\/\/|file:)([a-zA-Z0-9._-]+)[/:]([a-zA-Z0-9._-]+)(?:\?.*)?$/);
  const match = rest || custom;
  if (match && match[1] === bucketId) {
    return `appwrite-storage://${bucketId}/${match[2]}?lessonId=${encodeURIComponent(lessonId)}`;
  }
  if (/^\s*[\[{]/.test(value)) {
    try { return JSON.stringify(scopeLessonMedia(JSON.parse(value), lessonId, bucketId)); } catch (_) {}
  }
  return value;
}
