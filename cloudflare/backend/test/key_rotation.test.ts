import { describe, expect, it } from 'vitest';
import {
  AllKeysFailedError,
  BadRequestError,
  KeyFailure,
  classifyBodhanFailure,
  rotationOrder,
  withKeyRotation,
} from '../src/key_rotation';
import { callJson, env, makeUser, outbound, uid } from './helpers';

const KEYS = ['key-a', 'key-b', 'key-c'];

describe('rotationOrder', () => {
  it('starts at the cursor and wraps around', () => {
    expect(rotationOrder(3, 0, () => false)).toEqual([0, 1, 2]);
    expect(rotationOrder(3, 2, () => false)).toEqual([2, 0, 1]);
    expect(rotationOrder(3, 7, () => false)).toEqual([1, 2, 0]);
    expect(rotationOrder(3, -1, () => false)).toEqual([2, 0, 1]);
  });

  it('puts parked keys last instead of dropping them', () => {
    expect(rotationOrder(3, 0, (i) => i === 0)).toEqual([1, 2, 0]);
    expect(rotationOrder(3, 0, () => true)).toEqual([0, 1, 2]);
  });
});

describe('classifyBodhanFailure', () => {
  it.each([
    [402, '', 'credit_ended'],
    [400, 'Insufficient credits on account', 'credit_ended'],
    [401, '', 'invalid_key'],
    [400, 'Invalid API key', 'invalid_key'],
    [429, '', 'rate_limited'],
    [500, 'boom', 'upstream_error'],
  ])('HTTP %i %j -> %s', (status, text, reason) => {
    const failure = classifyBodhanFailure(status, text);
    expect(failure).toBeInstanceOf(KeyFailure);
    expect((failure as KeyFailure).reason).toBe(reason);
  });

  it('treats 422 as a bad request, not a key problem', () => {
    expect(classifyBodhanFailure(422, '')).toBeInstanceOf(BadRequestError);
  });
});

describe('withKeyRotation', () => {
  it('spreads successive requests round-robin across keys', async () => {
    const provider = uid('prov');
    const used: string[] = [];
    for (let i = 0; i < 4; i++) {
      await withKeyRotation(env.DB, provider, KEYS, async (key) => {
        used.push(key);
        return key;
      });
    }
    expect(used).toEqual(['key-a', 'key-b', 'key-c', 'key-a']);
  });

  it('fails over past a key whose credit ended and parks it', async () => {
    const provider = uid('prov');
    const tried: string[] = [];
    const attempt = async (key: string) => {
      tried.push(key);
      if (key === 'key-a') throw new KeyFailure('credit_ended', 'out of credit');
      return key;
    };
    expect(await withKeyRotation(env.DB, provider, KEYS, attempt)).toBe('key-b');
    // Next requests continue after b and skip the parked key a.
    expect(await withKeyRotation(env.DB, provider, KEYS, attempt)).toBe('key-c');
    expect(await withKeyRotation(env.DB, provider, KEYS, attempt)).toBe('key-b');
    expect(tried).toEqual(['key-a', 'key-b', 'key-c', 'key-b']);

    const row = await env.DB.prepare('SELECT state_json FROM provider_key_rotation WHERE provider = ?').bind(provider).first<any>();
    const parked = Object.values(JSON.parse(row.state_json).parked) as any[];
    expect(parked).toHaveLength(1);
    expect(parked[0].reason).toBe('credit_ended');
    // The secret itself is never stored.
    expect(row.state_json).not.toContain('key-a');
  });

  it('reports creditEnded when every key is out of credit or invalid', async () => {
    const provider = uid('prov');
    const err = await withKeyRotation(env.DB, provider, KEYS, async (key) => {
      throw new KeyFailure(key === 'key-c' ? 'invalid_key' : 'credit_ended', 'no');
    }).catch((e) => e);
    expect(err).toBeInstanceOf(AllKeysFailedError);
    expect(err.creditEnded).toBe(true);
  });

  it('does not report creditEnded for transient failures', async () => {
    const err = await withKeyRotation(env.DB, uid('prov'), KEYS, async () => {
      throw new Error('socket hang up');
    }).catch((e) => e);
    expect(err).toBeInstanceOf(AllKeysFailedError);
    expect(err.creditEnded).toBe(false);
    expect(err.reasons).toEqual(['upstream_error', 'upstream_error', 'upstream_error']);
  });

  it('stops at a bad request without trying other keys', async () => {
    const tried: string[] = [];
    const err = await withKeyRotation(env.DB, uid('prov'), KEYS, async (key) => {
      tried.push(key);
      throw new BadRequestError('bad text');
    }).catch((e) => e);
    expect(err).toBeInstanceOf(BadRequestError);
    expect(tried).toHaveLength(1);
  });
});

describe('POST /voice/synthesize key failover', () => {
  const synth = (text: string) => callJson('/api/v1/voice/synthesize', { as: makeUser(), json: { text } });

  it('moves to the next Bodhan key when one is out of credit', async () => {
    const seen: string[] = [];
    outbound.bodhan = (key) => {
      seen.push(key);
      return seen.length === 1
        ? new Response('{"error":"insufficient credits"}', { status: 402 })
        : new Response(new Uint8Array(512), { status: 200 });
    };
    const { status, body } = await synth(`johar ${uid('t')}`);
    expect(status).toBe(200);
    expect(body.cached).toBe(false);
    expect(seen).toHaveLength(2);
    expect(seen[0]).not.toBe(seen[1]);
  });

  it('answers VOICE_CREDITS_EXHAUSTED when every key is out of credit', async () => {
    outbound.bodhan = () => new Response('payment required', { status: 402 });
    const { status, body } = await synth(`johar ${uid('t')}`);
    expect(status).toBe(503);
    expect(body.error).toBe('VOICE_CREDITS_EXHAUSTED');
  });

  it('serves the R2 copy on a repeat request without calling Bodhan', async () => {
    const text = `johar ${uid('t')}`;
    await synth(text);
    const before = outbound.callsTo('bodhan.test').length;
    const again = await synth(text);
    expect(again.body.cached).toBe(true);
    expect(outbound.callsTo('bodhan.test').length).toBe(before);
  });
});
