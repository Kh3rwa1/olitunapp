import { enforceWindowRateLimit } from './shared/rate_limiter.js';

export function positiveLimit(value, fallback) {
  if (value === undefined || value === '') return fallback;
  if (!/^\d+$/.test(String(value))) throw new Error('Invalid translation resource limit');
  const n = Number(value);
  if (!Number.isSafeInteger(n) || n < 1 || n > 500) throw new Error('Translation resource limit must be 1..500');
  return n;
}

export function createTranslationBudget({ reserve = enforceWindowRateLimit, now = Date.now, env = process.env } = {}) {
  let failures = 0;
  let openUntil = 0;
  return {
    async acquire(databases, { upstream = false } = {}) {
      if (env.TRANSLATION_ENABLED === 'false') return { allowed: false, reason: 'disabled', retryAfterSeconds: 60 };
      if (upstream && now() < openUntil) return { allowed: false, reason: 'circuit_open', retryAfterSeconds: Math.ceil((openUntil - now()) / 1000) };
      let limit;
      try { limit = positiveLimit(upstream ? env.TRANSLATION_UPSTREAM_PER_MINUTE : env.TRANSLATION_REQUESTS_PER_MINUTE, upstream ? 30 : 120); }
      catch { return { allowed: false, reason: 'configuration_error', retryAfterSeconds: 60 }; }
      const result = await reserve({ databases, dbId: 'olitun_db', collectionId: 'rate_limits',
        identifier: upstream ? 'translation_upstream_global_v1' : 'translation_requests_global_v1',
        windowType: 'm', windowMs: 60000, limit, now: now() });
      return result;
    },
    failed() { if (++failures >= 5) openUntil = now() + 30000; },
    succeeded() { failures = 0; openUntil = 0; },
  };
}
