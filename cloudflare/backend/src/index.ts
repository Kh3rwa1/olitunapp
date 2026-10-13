import { Hono } from 'hono';
import { cors } from 'hono/cors';

type Bindings = {
  DB: D1Database;
  ASSETS: R2Bucket;
};

const app = new Hono<{ Bindings: Bindings }>();

// Global CORS middleware for Flutter Web & Mobile
app.use('*', cors());

// Root landing page
app.get('/', (c) => {
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
    <p>Powered by Cloudflare Workers, D1 Serverless Database, and global Edge Caching across 300+ cities worldwide.</p>
    <div style="margin: 16px 0;">
      <span class="stat">D1 SQLite</span>
      <span class="stat">R2 Media</span>
      <span class="stat">Global Edge Cache</span>
    </div>
    <div class="endpoints">
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

// Helper for edge-cached JSON responses (reduces database reads to practically zero)
const cachedJson = (c: any, data: any, maxAge = 86400) => {
  return c.json(data, 200, {
    'Cache-Control': `public, max-age=${maxAge}, stale-while-revalidate=3600`,
  });
};

// 1. Categories
app.get('/api/v1/categories', async (c) => {
  try {
    const result = await c.env.DB.prepare(
      'SELECT raw_json FROM categories WHERE is_active = 1 ORDER BY order_index ASC'
    ).all();
    const categories = (result.results || []).map((r: any) => JSON.parse(r.raw_json));
    return cachedJson(c, { ok: true, total: categories.length, categories });
  } catch (err: any) {
    return c.json({ ok: false, error: err.message }, 500);
  }
});

app.get('/api/v1/categories/:id', async (c) => {
  try {
    const id = c.req.param('id');
    const result = await c.env.DB.prepare(
      'SELECT raw_json FROM categories WHERE id = ?'
    ).bind(id).first();
    if (!result) return c.json({ ok: false, error: 'Category not found' }, 404);
    return cachedJson(c, { ok: true, category: JSON.parse((result as any).raw_json) });
  } catch (err: any) {
    return c.json({ ok: false, error: err.message }, 500);
  }
});

// 2. Letters
app.get('/api/v1/letters', async (c) => {
  try {
    const result = await c.env.DB.prepare(
      'SELECT raw_json FROM letters ORDER BY order_index ASC'
    ).all();
    const letters = (result.results || []).map((r: any) => JSON.parse(r.raw_json));
    return cachedJson(c, { ok: true, total: letters.length, letters });
  } catch (err: any) {
    return c.json({ ok: false, error: err.message }, 500);
  }
});

// 3. Numbers
app.get('/api/v1/numbers', async (c) => {
  try {
    const result = await c.env.DB.prepare(
      'SELECT raw_json FROM numbers ORDER BY val ASC'
    ).all();
    const numbers = (result.results || []).map((r: any) => JSON.parse(r.raw_json));
    return cachedJson(c, { ok: true, total: numbers.length, numbers });
  } catch (err: any) {
    return c.json({ ok: false, error: err.message }, 500);
  }
});

// 4. Words
app.get('/api/v1/words', async (c) => {
  try {
    const category = c.req.query('category');
    let stmt;
    if (category) {
      stmt = c.env.DB.prepare('SELECT raw_json FROM words WHERE category = ? ORDER BY order_index ASC').bind(category);
    } else {
      stmt = c.env.DB.prepare('SELECT raw_json FROM words ORDER BY order_index ASC');
    }
    const result = await stmt.all();
    const words = (result.results || []).map((r: any) => JSON.parse(r.raw_json));
    return cachedJson(c, { ok: true, total: words.length, words });
  } catch (err: any) {
    return c.json({ ok: false, error: err.message }, 500);
  }
});

// 5. Sentences
app.get('/api/v1/sentences', async (c) => {
  try {
    const category = c.req.query('category');
    let stmt;
    if (category) {
      stmt = c.env.DB.prepare('SELECT raw_json FROM sentences WHERE category = ? ORDER BY order_index ASC').bind(category);
    } else {
      stmt = c.env.DB.prepare('SELECT raw_json FROM sentences ORDER BY order_index ASC');
    }
    const result = await stmt.all();
    const sentences = (result.results || []).map((r: any) => JSON.parse(r.raw_json));
    return cachedJson(c, { ok: true, total: sentences.length, sentences });
  } catch (err: any) {
    return c.json({ ok: false, error: err.message }, 500);
  }
});

// 6. Lessons
app.get('/api/v1/lessons', async (c) => {
  try {
    const categoryId = c.req.query('category_id') || c.req.query('categoryId');
    let stmt;
    if (categoryId) {
      stmt = c.env.DB.prepare('SELECT raw_json FROM lessons WHERE category_id = ? ORDER BY order_index ASC').bind(categoryId);
    } else {
      stmt = c.env.DB.prepare('SELECT raw_json FROM lessons ORDER BY order_index ASC');
    }
    const result = await stmt.all();
    const lessons = (result.results || []).map((r: any) => JSON.parse(r.raw_json));
    return cachedJson(c, { ok: true, total: lessons.length, lessons });
  } catch (err: any) {
    return c.json({ ok: false, error: err.message }, 500);
  }
});

// 7. Assets stream from R2 (Zero egress fees, immutable caching)
app.get('/api/v1/assets/*', async (c) => {
  try {
    const path = c.req.path.replace('/api/v1/assets/', '');
    const object = await c.env.ASSETS.get(path);
    if (!object) return c.text('Asset Not Found', 404);

    const headers = new Headers();
    object.writeHttpMetadata(headers);
    headers.set('etag', object.httpEtag);
    headers.set('Cache-Control', 'public, max-age=31536000, immutable');
    return new Response(object.body, { headers });
  } catch (err: any) {
    return c.json({ ok: false, error: err.message }, 500);
  }
});

export default app;
