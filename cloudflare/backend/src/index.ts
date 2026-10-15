import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { aiRateLimit, optionalUser, requireAdmin, requireUser } from './auth';
import type { App, AppEnv } from './env';
import { registerRoutes } from './routes';
import { proxyToPages } from './lib/pages';
import { scheduled } from './scheduled';

const app: App = new Hono<AppEnv>();

// Entry point: global middleware, then every route module (src/routes), then
// the SPA fallback. Hono matches in registration order, so all auth
// middleware below is registered before any handler it guards.

// Global CORS middleware for Flutter Web & Mobile
app.use('*', cors());

// --- Authentication -------------------------------------------------------
// Every per-user route derives the user from a verified Appwrite JWT.
for (const path of [
  '/api/v1/mistakes',
  '/api/v1/mistakes/record',
  '/api/v1/mistakes/master',
  '/api/v1/mistakes/review/complete',
  '/api/v1/bakhed/progress',
  '/api/v1/gamification/summary',
  '/api/v1/payments/order',
  '/api/v1/payments/verify',
  '/api/v1/payments/entitlements',
  '/api/v1/payments/entitlements/sync',
]) {
  app.use(path, requireUser);
}

// Paid AI / TTS routes: signed-in users only, rate limited per user and IP.
for (const path of [
  '/api/v1/translate',
  '/api/v1/voice/synthesize',
  '/api/v1/audio/generate',
  '/api/v1/studio/transcribe',
  '/api/v1/studio/process',
]) {
  app.use(path, requireUser, aiRateLimit);
}

app.use('/api/v1/lessons/authorize', optionalUser);

app.use('/api/v1/admin/*', requireAdmin);
// Only the admin analytics jobs; /api/v1/analytics/events is public ingest
// (routes/analytics.ts).
app.use('/api/v1/analytics/aggregate', requireAdmin);
app.use('/api/v1/analytics/cleanup', requireAdmin);
app.use('/api/v1/payments/reconcile', requireAdmin);

// Route modules, in the original registration order (see routes/index.ts).
registerRoutes(app);

// ==========================================
// SPA & STATIC ASSETS PROXY (CLOUDFLARE PAGES)
// ==========================================
app.notFound(async (c) => {
  const url = new URL(c.req.url);
  // Explicit API 404
  if (url.pathname.startsWith('/api/')) {
    return c.json({ ok: false, error: 'NOT_FOUND', message: 'API route not found' }, 404);
  }

  // Proxy non-API requests (web SPA, HTML, JS, CSS, assets) to Cloudflare Pages
  return proxyToPages(c);
});

// The Hono app handles fetch; Cron Triggers (wrangler.json) go to scheduled.
// `app` is exported too so tests can call app.fetch directly.
export { app };
export default {
  fetch: app.fetch,
  scheduled,
} satisfies ExportedHandler<AppEnv['Bindings']>;
