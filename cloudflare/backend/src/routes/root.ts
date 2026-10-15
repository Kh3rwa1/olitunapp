import type { App } from '../env';
import { proxyToPages } from '../lib/pages';

export function registerRootRoutes(app: App): void {
  // Root landing page
  app.get('/', async (c) => {
    const url = new URL(c.req.url);
    const hostname = url.hostname.toLowerCase();

    // If request is on a custom web domain (olitun.in, admin.olitun.in, app.olitun.in, etc.), serve web app
    if (hostname.endsWith('olitun.in') || hostname === 'localhost') {
      return proxyToPages(c);
    }

    const accept = c.req.header('Accept') || '';
    if (accept.includes('text/html')) {
      return c.html(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Olitun Cloudflare Edge API</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0f172a; color: #f8fafc; margin: 0; padding: 40px 20px; display: flex; justify-content: center; }
    .card { background: #1e293b; border: 1px solid #334155; border-radius: 16px; max-width: 600px; width: 100%; padding: 32px; box-shadow: 0 10px 25px rgba(0,0,0,0.3); }
    h1 { margin-top: 0; color: #38bdf8; font-size: 24px; display: flex; align-items: center; gap: 10px; }
    .badge { background: #065f46; color: #34d399; padding: 4px 10px; border-radius: 999px; font-size: 12px; font-weight: 600; }
    p { color: #94a3b8; line-height: 1.6; }
    .endpoints { margin-top: 24px; display: flex; flex-direction: column; gap: 12px; }
    .endpoint { display: flex; align-items: center; justify-content: space-between; background: #0f172a; padding: 12px 16px; border-radius: 8px; border: 1px solid #334155; text-decoration: none; color: #e2e8f0; transition: all 0.2s; }
    .endpoint:hover { border-color: #38bdf8; transform: translateY(-1px); }
    .method { background: #0284c7; color: white; padding: 2px 8px; border-radius: 4px; font-size: 11px; font-weight: bold; }
    .path { font-family: monospace; font-size: 14px; }
    .stat { display: inline-block; background: #334155; color: #f1f5f9; padding: 2px 8px; border-radius: 6px; font-size: 12px; margin-right: 6px; }
  </style>
</head>
<body>
  <div class="card">
    <h1><span>⚡</span> Olitun Cloudflare Edge API <span class="badge">ONLINE</span></h1>
    <p>Powered by Cloudflare Workers, D1 Serverless Database, Workers AI, and global Edge Caching across 300+ cities worldwide.</p>
    <div style="margin: 16px 0;">
      <span class="stat">D1 SQLite</span>
      <span class="stat">Workers AI</span>
      <span class="stat">R2 Media</span>
      <span class="stat">Global Edge Cache</span>
    </div>
    <div class="endpoints">
      <a class="endpoint" href="/api/v1/translate?text=Hello+friend&to=sat" target="_blank">
        <span class="path">/api/v1/translate (AI & Instant)</span>
        <span class="method">POST / GET</span>
      </a>
      <a class="endpoint" href="/api/v1/categories" target="_blank">
        <span class="path">/api/v1/categories</span>
        <span class="method">GET</span>
      </a>
      <a class="endpoint" href="/api/v1/words" target="_blank">
        <span class="path">/api/v1/words</span>
        <span class="method">GET</span>
      </a>
      <a class="endpoint" href="/api/v1/letters" target="_blank">
        <span class="path">/api/v1/letters</span>
        <span class="method">GET</span>
      </a>
      <a class="endpoint" href="/api/v1/numbers" target="_blank">
        <span class="path">/api/v1/numbers</span>
        <span class="method">GET</span>
      </a>
      <a class="endpoint" href="/api/v1/sentences" target="_blank">
        <span class="path">/api/v1/sentences</span>
        <span class="method">GET</span>
      </a>
      <a class="endpoint" href="/api/v1/lessons" target="_blank">
        <span class="path">/api/v1/lessons</span>
        <span class="method">GET</span>
      </a>
      <a class="endpoint" href="/health" target="_blank">
        <span class="path">/health</span>
        <span class="method">GET</span>
      </a>
    </div>
  </div>
</body>
</html>`);
    }
    return c.json({
      status: 'ok',
      service: 'olitun-api',
      edge: true,
      endpoints: {
        translate: '/api/v1/translate',
        categories: '/api/v1/categories',
        words: '/api/v1/words',
        letters: '/api/v1/letters',
        numbers: '/api/v1/numbers',
        sentences: '/api/v1/sentences',
        lessons: '/api/v1/lessons',
        health: '/health'
      }
    });
  });

  // Health check endpoint
  app.get('/health', (c) => c.json({ status: 'ok', service: 'olitun-api', edge: true }));
}
