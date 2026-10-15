import { describe, expect, it } from 'vitest';
import { MEDIA_PROTOCOL_VERSION } from '../src/routes/paid_media';
import { call, callJson, env, grantPurchase, insertCategory, insertLesson, makeUser, uid } from './helpers';

const SECRET = 'test-media-signing-secret';
const BYTES = Uint8Array.from({ length: 1000 }, (_, i) => i % 256);

async function sign(fileId: string, exp: number, uidValue: string) {
  const key = await crypto.subtle.importKey('raw', new TextEncoder().encode(SECRET), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(`olitun-media-v${MEDIA_PROTOCOL_VERSION}\n${fileId}\n${exp}\n${uidValue}`));
  let binary = '';
  for (const b of new Uint8Array(sig)) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

async function paidLessonWithMedia() {
  const fileId = uid('file');
  await env.ASSETS.put(`paid_media/${fileId}`, BYTES, { httpMetadata: { contentType: 'audio/mpeg' } });
  const categoryId = await insertCategory({ unlockMode: 'paid', priceInr: 99 });
  const lessonId = await insertLesson(categoryId, { blocks: [{ type: 'audio', fileId, bucketId: 'paid_media' }] });
  return { fileId, categoryId, lessonId };
}

const lease = (user: { jwt: string } | null, lessonId: string, body: Record<string, unknown>) =>
  callJson('/api/v1/lessons/authorize', {
    as: user,
    json: { action: 'get_media', lessonId, protocolVersion: MEDIA_PROTOCOL_VERSION, ...body },
  });

const relative = (url: string) => {
  const u = new URL(url);
  return `${u.pathname}${u.search}`;
};

describe('paid media lease', () => {
  it('is refused without an entitlement', async () => {
    const { fileId, lessonId } = await paidLessonWithMedia();
    const { status, body } = await lease(makeUser(), lessonId, { fileId });
    expect(status).toBe(403);
    expect(body.reason).toBe('purchase_required');
  });

  it('is refused to anonymous callers on a paid lesson', async () => {
    const { fileId, lessonId } = await paidLessonWithMedia();
    expect((await lease(null, lessonId, { fileId })).status).toBe(403);
  });

  it('issues a signed URL that streams the file once entitled', async () => {
    const user = makeUser();
    const { fileId, lessonId, categoryId } = await paidLessonWithMedia();
    await grantPurchase(user.id, categoryId);
    const { status, body, res } = await lease(user, lessonId, { fileId });
    expect(status).toBe(200);
    expect(res.headers.get('cache-control')).toContain('no-store');
    expect(body).toMatchObject({ ok: true, fileId, size: BYTES.length, mimeType: 'audio/mpeg' });
    expect(new URL(body.url).searchParams.get('uid')).toBe(user.id);

    const media = await call(relative(body.url));
    expect(media.status).toBe(200);
    expect(new Uint8Array(await media.arrayBuffer())).toEqual(BYTES);
  });

  it('refuses a file the lesson does not reference', async () => {
    const user = makeUser();
    const { lessonId, categoryId } = await paidLessonWithMedia();
    await grantPurchase(user.id, categoryId);
    const other = uid('file');
    await env.ASSETS.put(`paid_media/${other}`, BYTES);
    const { status, body } = await lease(user, lessonId, { fileId: other });
    expect(status).toBe(403);
    expect(body.error).toBe('media_not_associated');
  });

  it('asks old clients to upgrade instead of falling back', async () => {
    const user = makeUser();
    const { fileId, lessonId, categoryId } = await paidLessonWithMedia();
    await grantPurchase(user.id, categoryId);
    expect((await lease(user, lessonId, { fileId, protocolVersion: 2 })).status).toBe(426);
  });
});

describe('signed media URL', () => {
  async function signedUrl(overrides: { exp?: number; uid?: string; fileId?: string } = {}) {
    const fileId = overrides.fileId || uid('file');
    await env.ASSETS.put(`paid_media/${fileId}`, BYTES, { httpMetadata: { contentType: 'audio/mpeg' } });
    const exp = overrides.exp ?? Math.floor(Date.now() / 1000) + 120;
    const who = overrides.uid || 'u_owner';
    const sig = await sign(fileId, exp, who);
    return { fileId, exp, who, sig, path: `/api/v1/media/paid/${fileId}?exp=${exp}&uid=${who}&sig=${sig}` };
  }

  it('serves a valid signature', async () => {
    expect((await call((await signedUrl()).path)).status).toBe(200);
  });

  it('rejects a tampered signature, uid, expiry or file id', async () => {
    const { fileId, exp, who, sig } = await signedUrl();
    const flipped = (sig[0] === 'A' ? 'B' : 'A') + sig.slice(1);
    const other = uid('file');
    await env.ASSETS.put(`paid_media/${other}`, BYTES);
    for (const path of [
      `/api/v1/media/paid/${fileId}?exp=${exp}&uid=${who}&sig=${flipped}`,
      `/api/v1/media/paid/${fileId}?exp=${exp}&uid=u_attacker&sig=${sig}`,
      `/api/v1/media/paid/${fileId}?exp=${exp + 60}&uid=${who}&sig=${sig}`,
      `/api/v1/media/paid/${other}?exp=${exp}&uid=${who}&sig=${sig}`,
      `/api/v1/media/paid/${fileId}?exp=${exp}&uid=${who}`,
    ]) {
      expect((await call(path)).status, path).toBe(403);
    }
  });

  it('rejects an expired link', async () => {
    const { path } = await signedUrl({ exp: Math.floor(Date.now() / 1000) - 1 });
    expect((await call(path)).status).toBe(403);
  });

  it('rejects a link signed to live longer than any lease', async () => {
    const { path } = await signedUrl({ exp: Math.floor(Date.now() / 1000) + 24 * 3600 });
    expect((await call(path)).status).toBe(403);
  });

  it('serves byte ranges with 206', async () => {
    const { path } = await signedUrl();
    const res = await call(path, { headers: { range: 'bytes=10-19' } });
    expect(res.status).toBe(206);
    expect(res.headers.get('content-range')).toBe(`bytes 10-19/${BYTES.length}`);
    expect(new Uint8Array(await res.arrayBuffer())).toEqual(BYTES.slice(10, 20));

    const suffix = await call(path, { headers: { range: 'bytes=-5' } });
    expect(suffix.status).toBe(206);
    expect(new Uint8Array(await suffix.arrayBuffer())).toEqual(BYTES.slice(-5));

    expect((await call(path, { headers: { range: `bytes=${BYTES.length}-` } })).status).toBe(416);
  });
});

describe('public assets', () => {
  it('serves public objects with range support', async () => {
    const key = `images/${uid('img')}`;
    await env.ASSETS.put(key, BYTES, { httpMetadata: { contentType: 'image/png' } });
    const full = await call(`/api/v1/assets/${key}`);
    expect(full.status).toBe(200);
    expect(full.headers.get('x-content-type-options')).toBe('nosniff');
    const part = await call(`/api/v1/assets/${key}`, { headers: { range: 'bytes=0-3' } });
    expect(part.status).toBe(206);
    expect(new Uint8Array(await part.arrayBuffer())).toEqual(BYTES.slice(0, 4));
  });

  it.each(['paid_media', 'backups'])('never serves the private %s/ prefix', async (prefix) => {
    const key = `${prefix}/${uid('secret')}`;
    await env.ASSETS.put(key, BYTES);
    const res = await call(`/api/v1/assets/${key}`);
    expect(res.status).toBe(404);
    // Encoded variants of the same key must not slip past the prefix check.
    for (const variant of [key.replaceAll('_', '%5F'), key.replaceAll('/', '%2F'), `images/../${key}`, `images/%2e%2e/${key}`]) {
      expect((await call(`/api/v1/assets/${variant}`)).status, variant).toBe(404);
    }
  });

  it('sandboxes active content', async () => {
    const key = `images/${uid('svg')}`;
    await env.ASSETS.put(key, '<svg/>', { httpMetadata: { contentType: 'image/svg+xml' } });
    const res = await call(`/api/v1/assets/${key}`);
    expect(res.headers.get('content-security-policy')).toMatch(/^sandbox/);
  });
});
