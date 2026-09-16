import { BODHAN_MODEL, BODHAN_TTS_URL } from './validation.js';

/**
 * Calls Bodhan indic-speak once with a single API key.
 *
 * Returns `{ audio: Buffer }` on success, otherwise throws a classified
 * error with a machine-readable `reason`:
 * - `invalid_key`   — 401/403 or explicit auth failure. The key is dead.
 * - `credit_ended`  — 402/quota/billing failure. The key needs a top-up.
 * - `bad_request`   — 422 validation failure. Never rotate on this;
 *                     the request itself is wrong, not the key.
 * - `rate_limited`  — 429 without a quota signal. Transient; next key ok.
 * - `upstream_error`— 5xx/network/timeout. Transient; next key ok.
 */
export async function synthesizeWithKey({
  text,
  voice,
  lang,
  style,
  apiKey,
  fetchImpl = fetch,
  timeoutMs = 45000,
}) {
  if (!apiKey) throw classifiedError('invalid_key', 'Empty Bodhan API key.');

  const instructions = style ? { lang, style } : { lang };
  let res;
  try {
    res = await fetchImpl(BODHAN_TTS_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: BODHAN_MODEL,
        input: text,
        voice,
        instructions: JSON.stringify(instructions),
      }),
      signal: AbortSignal.timeout(timeoutMs),
    });
  } catch (networkErr) {
    throw classifiedError(
      'upstream_error',
      `Bodhan request failed: ${networkErr?.message || 'network error'}`
    );
  }

  if (res.ok) {
    const contentType = res.headers?.get?.('content-type') || '';
    const buffer = Buffer.from(await res.arrayBuffer());
    if (buffer.length === 0) {
      throw classifiedError('upstream_error', 'Bodhan returned empty audio.');
    }
    if (contentType.includes('application/json')) {
      // Some gateways wrap audio in JSON on odd paths; treat as failure
      // so rotation can try the next key rather than saving garbage.
      throw classifiedError(
        'upstream_error',
        `Bodhan returned JSON instead of audio: ${buffer.toString('utf8').slice(0, 300)}`
      );
    }
    return { audio: buffer };
  }

  const errText = await res.text().catch(() => '');
  const snippet = errText.slice(0, 500);
  const lowered = errText.toLowerCase();

  if (res.status === 422) {
    throw classifiedError('bad_request', `Bodhan rejected the request (422): ${snippet}`);
  }
  if (res.status === 401 || res.status === 403 || lowered.includes('invalid api key') || lowered.includes('authentication error')) {
    throw classifiedError('invalid_key', `Bodhan auth failed (${res.status}): ${snippet}`);
  }
  if (
    res.status === 402 ||
    lowered.includes('insufficient') ||
    lowered.includes('quota') ||
    lowered.includes('credit') ||
    lowered.includes('billing') ||
    lowered.includes('payment')
  ) {
    throw classifiedError('credit_ended', `Bodhan key out of credit (${res.status}): ${snippet}`);
  }
  if (res.status === 429) {
    throw classifiedError('rate_limited', `Bodhan rate limited (429): ${snippet}`);
  }
  throw classifiedError('upstream_error', `Bodhan failed (${res.status}): ${snippet}`);
}

function classifiedError(reason, message) {
  const err = new Error(message);
  err.reason = reason;
  return err;
}

/**
 * Decides whether a failed key should be auto-disabled in the database.
 * - invalid_key / credit_ended: disable (stops burning requests on it).
 * - rate_limited / upstream_error / bad_request: keep (transient or caller fault).
 */
export function shouldDisableKey(reason) {
  return reason === 'invalid_key' || reason === 'credit_ended';
}
