// Round-robin rotation across provider API keys (e.g. several Bodhan
// accounts). Each request starts at the key after the last one that
// succeeded, so load spreads evenly. A key that runs out of credit or is
// rejected is parked for a while and skipped; parked keys are probed again
// once the park expires, so a topped-up account rejoins automatically.
//
// State lives in D1 keyed by a hash of each key, never the key itself.

export type KeyFailureReason = 'credit_ended' | 'invalid_key' | 'rate_limited' | 'upstream_error';

export class BadRequestError extends Error {}

export class KeyFailure extends Error {
  constructor(readonly reason: KeyFailureReason, message: string) {
    super(message);
  }
}

export class AllKeysFailedError extends Error {
  constructor(readonly reasons: KeyFailureReason[]) {
    super('All provider keys failed');
  }
  get creditEnded(): boolean {
    return this.reasons.length > 0 && this.reasons.every((r) => r === 'credit_ended' || r === 'invalid_key');
  }
}

const PARK_MS: Record<KeyFailureReason, number> = {
  credit_ended: 6 * 60 * 60 * 1000,
  invalid_key: 24 * 60 * 60 * 1000,
  rate_limited: 60 * 1000,
  upstream_error: 0,
};

type RotationState = {
  cursor: number;
  parked: Record<string, { until: number; reason: KeyFailureReason }>;
};

async function keyHash(key: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(key));
  return Array.from(new Uint8Array(digest).slice(0, 8)).map((b) => b.toString(16).padStart(2, '0')).join('');
}

async function loadState(db: D1Database, provider: string): Promise<RotationState> {
  try {
    const row: any = await db.prepare('SELECT cursor, state_json FROM provider_key_rotation WHERE provider = ?')
      .bind(provider).first();
    if (!row) return { cursor: 0, parked: {} };
    const parsed = JSON.parse(row.state_json || '{}');
    return { cursor: Number(row.cursor) || 0, parked: parsed.parked || {} };
  } catch (_) {
    // Table missing or unreadable: rotate statelessly rather than fail.
    return { cursor: Math.floor(Math.random() * 1_000_000), parked: {} };
  }
}

async function saveState(db: D1Database, provider: string, state: RotationState): Promise<void> {
  await db.prepare(
    'INSERT INTO provider_key_rotation (provider, cursor, state_json, updated_at) VALUES (?, ?, ?, ?) ' +
    'ON CONFLICT(provider) DO UPDATE SET cursor = excluded.cursor, state_json = excluded.state_json, updated_at = excluded.updated_at'
  ).bind(provider, state.cursor, JSON.stringify({ parked: state.parked }), new Date().toISOString()).run();
}

/**
 * Order in which to try keys for this request: round-robin from the cursor,
 * available keys first. Parked keys come last, so if every key is parked the
 * request still probes them instead of failing outright.
 */
export function rotationOrder(count: number, cursor: number, isParked: (index: number) => boolean): number[] {
  const start = ((cursor % count) + count) % count;
  const ring = Array.from({ length: count }, (_, i) => (start + i) % count);
  return [...ring.filter((i) => !isParked(i)), ...ring.filter((i) => isParked(i))];
}

/**
 * Runs [attempt] with keys in round-robin order until one succeeds.
 * [attempt] throws KeyFailure to move on to the next key, or
 * BadRequestError to stop (the request itself is invalid).
 */
export async function withKeyRotation<T>(
  db: D1Database,
  provider: string,
  keys: string[],
  attempt: (key: string) => Promise<T>,
  waitUntil?: (p: Promise<unknown>) => void,
): Promise<T> {
  const state = await loadState(db, provider);
  const hashes = await Promise.all(keys.map(keyHash));
  const now = Date.now();

  // Drop park entries for keys that expired or were removed from the secret.
  for (const h of Object.keys(state.parked)) {
    if (!hashes.includes(h) || state.parked[h].until <= now) delete state.parked[h];
  }

  const persist = () => {
    const p = saveState(db, provider, state).catch((err) => console.error('key rotation state save failed', err));
    if (waitUntil) waitUntil(p); else return p;
  };

  const reasons: KeyFailureReason[] = [];
  for (const index of rotationOrder(keys.length, state.cursor, (i) => Boolean(state.parked[hashes[i]]))) {
    try {
      const result = await attempt(keys[index]);
      delete state.parked[hashes[index]];
      state.cursor = index + 1;
      await persist();
      return result;
    } catch (err) {
      if (err instanceof BadRequestError) throw err;
      const reason: KeyFailureReason = err instanceof KeyFailure ? err.reason : 'upstream_error';
      reasons.push(reason);
      if (PARK_MS[reason] > 0) {
        state.parked[hashes[index]] = { until: Date.now() + PARK_MS[reason], reason };
        console.warn(`${provider} key ${hashes[index]} parked: ${reason}`);
      }
    }
  }

  state.cursor += 1;
  await persist();
  throw new AllKeysFailedError(reasons);
}

/** Maps a failed Bodhan response to a rotation decision. */
export function classifyBodhanFailure(status: number, bodyText: string): KeyFailure | BadRequestError {
  const lowered = bodyText.toLowerCase();
  if (status === 422) return new BadRequestError('The voice service could not synthesize this text.');
  if (status === 401 || status === 403 || lowered.includes('invalid api key') || lowered.includes('authentication error')) {
    return new KeyFailure('invalid_key', 'Voice service authentication failure.');
  }
  if (status === 402 || ['insufficient', 'quota', 'credit', 'billing', 'payment', 'budget'].some((w) => lowered.includes(w))) {
    return new KeyFailure('credit_ended', 'Voice service credits exhausted.');
  }
  if (status === 429) return new KeyFailure('rate_limited', 'Voice service rate limit reached.');
  return new KeyFailure('upstream_error', 'Voice service provider error.');
}
