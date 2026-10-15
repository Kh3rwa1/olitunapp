import type { Bindings } from '../env';

// Bodhan keys live in the BODHAN_API_KEYS secret (comma-separated).
export function bodhanApiKeys(env: Bindings): string[] {
  return String(env.BODHAN_API_KEYS || '')
    .split(',')
    .map((k) => k.trim())
    .filter(Boolean);
}
