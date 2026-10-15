import { describe, expect, it } from 'vitest';
import { call, callJson, makeUser } from './helpers';

const AI_ROUTES = ['/api/v1/translate', '/api/v1/voice/synthesize', '/api/v1/audio/generate', '/api/v1/studio/transcribe', '/api/v1/studio/process'];

function limiter(allow: boolean) {
  const keys: string[] = [];
  return {
    keys,
    binding: {
      async limit({ key }: { key: string }) {
        keys.push(key);
        return { success: allow };
      },
    },
  };
}

describe('AI rate limits', () => {
  it.each(AI_ROUTES)('%s answers 429 when the per-user limit is exhausted', async (path) => {
    const user = makeUser();
    const userLimiter = limiter(false);
    const { status, body } = await callJson(path, { as: user, json: { text: 'johar' }, env: { AI_USER_LIMITER: userLimiter.binding } });
    expect(status).toBe(429);
    expect(body.error).toBe('RATE_LIMITED');
    expect(userLimiter.keys).toEqual([`user:${user.id}`]);
  });

  it('answers 429 when the per-IP limit is exhausted', async () => {
    const ipLimiter = limiter(false);
    const res = await call('/api/v1/translate', {
      as: makeUser(),
      json: { text: 'johar' },
      headers: { 'cf-connecting-ip': '203.0.113.9' },
      env: { AI_IP_LIMITER: ipLimiter.binding },
    });
    expect(res.status).toBe(429);
    expect(ipLimiter.keys).toEqual(['ip:203.0.113.9']);
  });

  it('authenticates before spending limiter quota', async () => {
    const userLimiter = limiter(true);
    const res = await call('/api/v1/translate', { json: { text: 'johar' }, env: { AI_USER_LIMITER: userLimiter.binding } });
    expect(res.status).toBe(401);
    expect(userLimiter.keys).toHaveLength(0);
  });

  it('enforces the configured 20/min user limit with the real binding', async () => {
    const user = makeUser();
    const statuses: number[] = [];
    for (let i = 0; i < 21; i++) {
      // Empty text: the handler answers 400 without calling any provider.
      statuses.push((await call('/api/v1/translate', { as: user, json: { text: '' } })).status);
    }
    expect(statuses.slice(0, 20).every((s) => s === 400)).toBe(true);
    expect(statuses[20]).toBe(429);
  });
});
