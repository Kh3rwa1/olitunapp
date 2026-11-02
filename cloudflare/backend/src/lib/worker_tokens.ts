import { base64ToBytes } from '../base64';

// Signing and hashing helpers for Worker-owned sign-in. Access tokens are
// HS256 JWTs carrying `kid: olitun-1`, so the auth middleware can tell them
// apart from Appwrite JWTs without trying both verifiers.

export const WORKER_TOKEN_KID = 'olitun-1';
export const ACCESS_TOKEN_TTL_SECONDS = 60 * 60;

export type AccessClaims = {
  sub: string;
  sid: string;
  iat: number;
  exp: number;
};

const encoder = new TextEncoder();

export function bytesToBase64Url(bytes: Uint8Array): string {
  let binary = '';
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

const textToBase64Url = (text: string) => bytesToBase64Url(encoder.encode(text));
const base64UrlToText = (value: string) => new TextDecoder().decode(base64ToBytes(value));

async function hmacKey(secret: string): Promise<CryptoKey> {
  return crypto.subtle.importKey('raw', encoder.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, [
    'sign',
    'verify',
  ]);
}

export async function hmac(secret: string, data: string): Promise<string> {
  const sig = await crypto.subtle.sign('HMAC', await hmacKey(secret), encoder.encode(data));
  return bytesToBase64Url(new Uint8Array(sig));
}

async function hmacVerify(secret: string, data: string, signature: string): Promise<boolean> {
  let sig: Uint8Array<ArrayBuffer>;
  try {
    sig = base64ToBytes(signature);
  } catch (_) {
    return false;
  }
  return crypto.subtle.verify('HMAC', await hmacKey(secret), sig, encoder.encode(data));
}

export async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', encoder.encode(value));
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

/** URL-safe random token with [bytes] bytes of entropy. */
export function randomToken(bytes = 32): string {
  return bytesToBase64Url(crypto.getRandomValues(new Uint8Array(bytes)));
}

/** 20-character lowercase id, the same shape as an Appwrite $id. */
export function newUserId(): string {
  const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
  const bytes = crypto.getRandomValues(new Uint8Array(20));
  return Array.from(bytes, (b) => alphabet[b % alphabet.length]).join('');
}

/** Uniformly random 6-digit code. */
export function randomDigits(length = 6): string {
  let out = '';
  while (out.length < length) {
    const [n] = crypto.getRandomValues(new Uint32Array(1));
    // Reject the top sliver so every digit is equally likely.
    if (n >= 4_294_967_290) continue;
    out += String(n % 10);
  }
  return out;
}

export async function signAccessToken(secret: string, claims: AccessClaims): Promise<string> {
  const header = textToBase64Url(JSON.stringify({ alg: 'HS256', typ: 'JWT', kid: WORKER_TOKEN_KID }));
  const payload = textToBase64Url(JSON.stringify(claims));
  const signature = await hmac(secret, `${header}.${payload}`);
  return `${header}.${payload}.${signature}`;
}

/** True when [token] is shaped like a Worker access token (by its header). */
export function isWorkerToken(token: string): boolean {
  const [header] = token.split('.');
  if (!header) return false;
  try {
    return JSON.parse(base64UrlToText(header))?.kid === WORKER_TOKEN_KID;
  } catch (_) {
    return false;
  }
}

/** Verified claims, or null for a bad signature, shape or expiry. */
export async function verifyAccessToken(secret: string, token: string, nowSeconds: number): Promise<AccessClaims | null> {
  const parts = token.split('.');
  if (parts.length !== 3) return null;
  const [header, payload, signature] = parts;
  if (!(await hmacVerify(secret, `${header}.${payload}`, signature))) return null;
  let claims: any;
  try {
    const head = JSON.parse(base64UrlToText(header));
    if (head?.alg !== 'HS256' || head?.kid !== WORKER_TOKEN_KID) return null;
    claims = JSON.parse(base64UrlToText(payload));
  } catch (_) {
    return null;
  }
  if (typeof claims?.sub !== 'string' || !claims.sub) return null;
  if (typeof claims?.sid !== 'string' || !claims.sid) return null;
  if (typeof claims?.exp !== 'number' || claims.exp <= nowSeconds) return null;
  return claims as AccessClaims;
}

/** Signs a small JSON value (OAuth state) as `payload.signature`. */
export async function signState(secret: string, value: Record<string, unknown>): Promise<string> {
  const payload = textToBase64Url(JSON.stringify(value));
  return `${payload}.${await hmac(secret, `state:${payload}`)}`;
}

export async function verifyState<T>(secret: string, state: string): Promise<T | null> {
  const [payload, signature, extra] = state.split('.');
  if (!payload || !signature || extra !== undefined) return null;
  if (!(await hmacVerify(secret, `state:${payload}`, signature))) return null;
  try {
    return JSON.parse(base64UrlToText(payload)) as T;
  } catch (_) {
    return null;
  }
}
