import type { Hono } from 'hono';
import type { AuthEnv, AuthVariables } from './auth';

export type RateLimit = { limit(options: { key: string }): Promise<{ success: boolean }> };

export type Bindings = AuthEnv & {
  DB: D1Database;
  ASSETS: R2Bucket;
  AI: any;
  // Secrets (wrangler secret put). Never hardcode provider keys here.
  BODHAN_API_KEYS?: string; // comma-separated
  SARVAM_API_KEY?: string;
  RAZORPAY_KEY_ID?: string;
  RAZORPAY_KEY_SECRET?: string;
  RAZORPAY_WEBHOOK_SECRET?: string;
  RAZORPAY_API_BASE?: string; // test override only; defaults to Razorpay
  BODHAN_API_BASE?: string; // test override only; defaults to Bodhan
  // Appwrite server key with users.write, used only to delete the login
  // during account deletion.
  APPWRITE_API_KEY?: string;
  ANALYTICS_LIMITER?: RateLimit;
  WAITLIST_LIMITER?: RateLimit;
};

export type AppEnv = { Bindings: Bindings; Variables: AuthVariables };
export type App = Hono<AppEnv>;

// The caller's user id, as verified by the auth middleware. Empty for
// anonymous requests on optionalUser routes.
export function getRequestUserId(c: any, _body?: any): string {
  return c.get('userId') || '';
}

export async function stableId(value: string): Promise<string> {
  const msgUint8 = new TextEncoder().encode(value);
  const hashBuffer = await crypto.subtle.digest('SHA-256', msgUint8);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('').slice(0, 32);
}
