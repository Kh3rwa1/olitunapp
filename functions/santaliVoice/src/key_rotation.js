import { Query } from 'node-appwrite';
import { synthesizeWithKey, shouldDisableKey } from './bodhan_client.js';

export const BODHAN_KEYS_COLLECTION = 'bodhan_api_keys';

/**
 * Parses Bodhan API keys from process.env.BODHAN_API_KEYS (JSON array or comma-separated).
 * Used when running on serverless environments where database read quotas are capped
 * or to eliminate database reads on every synthesis request.
 */
export function parseEnvKeys(envValue = process.env.BODHAN_API_KEYS) {
  if (!envValue || typeof envValue !== 'string') return [];
  try {
    const parsed = JSON.parse(envValue);
    if (Array.isArray(parsed)) {
      return parsed
        .map((k, i) => {
          const key = typeof k === 'string' ? k.trim() : (k?.key || '').trim();
          const label = typeof k === 'object' && k?.label ? k.label : `env-account-${i + 1}`;
          return key ? { $id: `env-key-${i + 1}`, key, label, priority: i, isActive: true } : null;
        })
        .filter(Boolean);
    }
  } catch (_) {
    return envValue
      .split(',')
      .map((k) => k.trim())
      .filter((k) => k.startsWith('sk-'))
      .map((key, i) => ({
        $id: `env-key-${i + 1}`,
        key,
        label: `env-account-${i + 1}`,
        priority: i,
        isActive: true,
      }));
  }
  return [];
}

/**
 * Loads active Bodhan keys ordered by priority (lowest first), then oldest.
 * If BODHAN_API_KEYS environment variable is set, uses it directly to save
 * database reads. Otherwise queries the Appwrite bodhan_api_keys collection.
 */
export async function loadActiveKeys(databases, dbId) {
  const envKeys = parseEnvKeys();
  if (envKeys.length > 0) {
    return envKeys;
  }
  const result = await databases.listDocuments(dbId, BODHAN_KEYS_COLLECTION, [
    Query.equal('isActive', true),
    Query.orderAsc('priority'),
    Query.orderAsc('$createdAt'),
    Query.limit(100),
  ]);
  return (result.documents || []).filter((d) => typeof d.key === 'string' && d.key.trim().length > 0);
}

/**
 * Tries each key in order until one synthesizes audio.
 *
 * - 422 bad_request: returned immediately, no rotation (request is wrong).
 * - invalid_key / credit_ended: key auto-disabled, rotation continues.
 * - rate_limited / upstream_error: rotation continues, key kept enabled.
 *
 * Key-stat writes are best-effort and never fail the request.
 * Returns `{ audio, keyId, keyLabel, attempts }` or throws:
 * - `bad_request` passthrough, or
 * - `all_keys_exhausted` aggregating per-key reasons.
 */
export async function synthesizeWithRotation({
  databases,
  dbId,
  keys,
  text,
  voice,
  lang,
  style,
  fetchImpl,
}) {
  if (!keys || keys.length === 0) {
    throw rotationExhausted('NO_KEYS_CONFIGURED', 'No Bodhan API keys are configured. Add one in the bodhan_api_keys collection.', []);
  }

  const failures = [];
  for (const keyDoc of keys) {
    try {
      const { audio } = await synthesizeWithKey({
        text,
        voice,
        lang,
        style,
        apiKey: keyDoc.key.trim(),
        fetchImpl,
      });
      recordKeySuccess(databases, dbId, keyDoc).catch(() => {});
      return {
        audio,
        keyId: keyDoc.$id,
        keyLabel: keyDoc.label || keyDoc.$id,
        attempts: failures.length + 1,
      };
    } catch (keyErr) {
      const reason = keyErr?.reason || 'upstream_error';
      failures.push({ keyId: keyDoc.$id, reason, message: String(keyErr?.message || '').slice(0, 300) });
      if (reason === 'bad_request') {
        // Caller fault — surface it directly, don't burn remaining keys.
        throw keyErr;
      }
      recordKeyFailure(databases, dbId, keyDoc, reason, keyErr).catch(() => {});
    }
  }

  const creditEnded = failures.some((f) => f.reason === 'credit_ended' || f.reason === 'invalid_key');
  throw rotationExhausted(
    'ALL_KEYS_EXHAUSTED',
    creditEnded
      ? 'All voice keys are out of credit or invalid. Please try again later.'
      : 'Voice service is busy. Please try again in a moment.',
    failures
  );
}

function rotationExhausted(code, message, failures) {
  const err = new Error(message);
  err.reason = 'all_keys_exhausted';
  err.code = code;
  err.failures = failures;
  return err;
}

async function recordKeySuccess(databases, dbId, keyDoc) {
  if (keyDoc?.$id?.startsWith('env-key-')) return;
  await databases.updateDocument(dbId, BODHAN_KEYS_COLLECTION, keyDoc.$id, {
    successCount: (keyDoc.successCount || 0) + 1,
    lastUsedAt: new Date().toISOString(),
    lastError: null,
  });
}

async function recordKeyFailure(databases, dbId, keyDoc, reason, keyErr) {
  if (keyDoc?.$id?.startsWith('env-key-')) return;
  const patch = {
    failCount: (keyDoc.failCount || 0) + 1,
    lastUsedAt: new Date().toISOString(),
    lastError: `${reason}: ${String(keyErr?.message || '').slice(0, 900)}`,
  };
  if (shouldDisableKey(reason)) {
    patch.isActive = false;
  }
  await databases.updateDocument(dbId, BODHAN_KEYS_COLLECTION, keyDoc.$id, patch);
}
