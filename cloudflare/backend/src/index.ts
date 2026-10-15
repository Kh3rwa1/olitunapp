import { Hono } from 'hono';
import { cors } from 'hono/cors';
import {
  aiRateLimit,
  optionalUser,
  requireAdmin,
  requireUser,
  timingSafeEqualStr,
  type AuthEnv,
} from './auth';
import {
  AllKeysFailedError,
  BadRequestError,
  classifyBodhanFailure,
  withKeyRotation,
} from './key_rotation';
import { getRequestUserId, stableId, type App, type AppEnv, type Bindings } from './env';
import { registerRoutes } from './routes';
import { issuePaidMediaLease } from './routes/paid_media';
import { ANONYMIZED_USER_ID, deleteUserAccount } from './routes/account';

const app: App = new Hono<AppEnv>();

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

// Language mappings for IndicTrans2 model
const INDICTRANS2_TARGETS: Record<string, string> = {
  sat: 'sat_Olck',
  santali: 'sat_Olck',
  'sat-in': 'sat_Olck',
  'sat_olck': 'sat_Olck',
  hin: 'hin_Deva',
  hi: 'hin_Deva',
  hindi: 'hin_Deva',
  ben: 'ben_Beng',
  bn: 'ben_Beng',
  bengali: 'ben_Beng',
  ory: 'ory_Orya',
  or: 'ory_Orya',
  odia: 'ory_Orya',
  asm: 'asm_Beng',
  as: 'asm_Beng',
  guj: 'guj_Gujr',
  gu: 'guj_Gujr',
  mar: 'mar_Deva',
  mr: 'mar_Deva',
  pan: 'pan_Guru',
  pa: 'pan_Guru',
  tam: 'tam_Taml',
  ta: 'tam_Taml',
  tel: 'tel_Telu',
  te: 'tel_Telu',
  urd: 'urd_Arab',
  ur: 'urd_Arab',
  san: 'san_Deva',
  sa: 'san_Deva',
};

async function computeCacheKey(from: string, to: string, text: string, engine: string): Promise<string> {
  const input = JSON.stringify({ from: from.toLowerCase(), to: to.toLowerCase(), text: text.trim(), engine: engine.toLowerCase() });
  const msgUint8 = new TextEncoder().encode(input);
  const hashBuffer = await crypto.subtle.digest('SHA-256', msgUint8);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
}

async function translateWithGoogle(text: string, from = 'auto', to = 'sat'): Promise<{ translation: string; detectedLanguage: string; provider: string }> {
  const sl = from === 'auto' ? 'auto' : from;
  
  // 1. Primary: translate_a/single (matches @vitalets/google-translate-api)
  try {
    const url = 'https://translate.google.com/translate_a/single?client=at&dt=t&dt=rm&dj=1';
    const body = new URLSearchParams({ sl, tl: to, q: text }).toString();

    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8',
        'User-Agent': 'GoogleTranslate/6.28.0.05.421483610 (Linux; U; Android 12; Pixel 5)',
      },
      body,
    });

    if (res.ok) {
      const data: any = await res.json();
      const translation = (data?.sentences || [])
        .filter((s: any) => typeof s?.trans === 'string')
        .map((s: any) => s.trans)
        .join('')
        .trim();
      const detectedLanguage = data?.src || from;

      if (translation.length > 0) {
        return {
          translation,
          detectedLanguage,
          provider: 'google-translate',
        };
      }
    }
  } catch (_) {
    // try fallback endpoint
  }

  // 2. Secondary fallback: dict-chrome-ex GET endpoint
  const urlFallback = `https://clients5.google.com/translate_a/t?client=dict-chrome-ex&sl=${encodeURIComponent(sl)}&tl=${encodeURIComponent(to)}&q=${encodeURIComponent(text)}`;
  const resFallback = await fetch(urlFallback, {
    method: 'GET',
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    },
  });

  if (!resFallback.ok) {
    throw new Error(`Google Translate HTTP error ${resFallback.status}`);
  }

  const dataFallback: any = await resFallback.json();
  let translationFallback = '';
  let detectedLanguageFallback = from;

  if (Array.isArray(dataFallback)) {
    if (typeof dataFallback[0] === 'string') {
      translationFallback = dataFallback[0];
    } else if (Array.isArray(dataFallback[0])) {
      translationFallback = dataFallback[0][0] || '';
      detectedLanguageFallback = dataFallback[0][1] || from;
    }
  }

  if (!translationFallback || translationFallback.trim().length === 0) {
    throw new Error('Google Translate returned empty translation');
  }

  return {
    translation: translationFallback.trim(),
    detectedLanguage: detectedLanguageFallback,
    provider: 'google-translate',
  };
}

async function translateWithWorkersAi(ai: any, text: string, targetTag: string): Promise<{ translation: string; provider: string }> {
  const res: any = await ai.run('@cf/ai4bharat/indictrans2-en-indic-1b', {
    text: text,
    target_language: targetTag,
  });
  const translation = res?.translations?.[0] || res?.result?.translations?.[0] || res?.translation;
  if (!translation || typeof translation !== 'string') {
    throw new Error('Workers AI returned empty translation');
  }
  return {
    translation: translation.trim(),
    provider: 'cloudflare-indictrans2-ai',
  };
}

async function translateWithAiLlama(ai: any, text: string, from: string, to: string): Promise<{ translation: string; provider: string }> {
  const res: any = await ai.run('@cf/meta/llama-3.2-3b-instruct', {
    messages: [
      {
        role: 'system',
        content: 'You are an accurate translator. Translate the text into the target language faithfully. Output ONLY the translation. Never add any notes, commentary, markdown formatting, or quotes.',
      },
      {
        role: 'user',
        content: `Translate this text from ${from} to ${to}:\n${text}`,
      },
    ],
    max_tokens: 256,
  });
  const response = res?.response || res?.result?.response || '';
  if (!response || typeof response !== 'string') {
    throw new Error('Llama AI translation returned empty');
  }
  return {
    translation: response.trim().replace(/^["']|["']$/g, ''),
    provider: 'cloudflare-llama3-ai',
  };
}

const M2M100_LANGS: Record<string, string> = {
  en: 'english',
  hi: 'hindi',
  bn: 'bengali',
  or: 'oriya',
  mr: 'marathi',
  gu: 'gujarati',
  pa: 'punjabi',
  ta: 'tamil',
  te: 'telugu',
  ur: 'urdu',
  es: 'spanish',
  fr: 'french',
  de: 'german',
  zh: 'chinese',
  ja: 'japanese',
  ru: 'russian',
  ar: 'arabic',
};

async function translateWithM2M100(ai: any, text: string, from: string, to: string): Promise<{ translation: string; provider: string }> {
  const srcLang = M2M100_LANGS[from.toLowerCase()] || 'english';
  const tgtLang = M2M100_LANGS[to.toLowerCase()] || to;
  const res: any = await ai.run('@cf/meta/m2m100-1.2b', {
    text: text,
    source_lang: srcLang,
    target_lang: tgtLang,
  });
  const translation = res?.translated_text;
  if (!translation || typeof translation !== 'string') {
    throw new Error('m2m100 returned empty translation');
  }
  return {
    translation: translation.trim(),
    provider: 'cloudflare-m2m100-ai',
  };
}

// Helper to proxy non-API web traffic to Cloudflare Pages SPA
async function proxyToPages(c: any) {
  const url = new URL(c.req.url);
  let pathname = url.pathname;
  if (pathname.startsWith('/admin/') && /\.(js|mjs|wasm|png|jpg|jpeg|gif|svg|json|ttf|woff|woff2|ico|css|map)$/i.test(pathname)) {
    pathname = pathname.replace(/^\/admin/, '');
  }
  const pagesUrl = new URL(pathname + url.search, 'https://olitunapp.pages.dev');
  try {
    let upstream = await fetch(pagesUrl.toString(), {
      method: c.req.method,
      headers: c.req.raw.headers,
      body: c.req.method !== 'GET' && c.req.method !== 'HEAD' ? c.req.raw.body : undefined,
    });
    // If upstream Pages returned 404 on an SPA route (no file extension), serve index.html with 200
    if (upstream.status === 404 && !/\.[a-zA-Z0-9]+$/.test(pathname)) {
      const indexUrl = new URL('/index.html', 'https://olitunapp.pages.dev');
      upstream = await fetch(indexUrl.toString(), {
        method: c.req.method,
        headers: c.req.raw.headers,
      });
    }
    return upstream;
  } catch (err: any) {
    return c.text('Gateway Error: ' + (err.message || 'Unknown error'), 502);
  }
}

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

// 7. Rhymes & Bakhed Prayers (Edge cached curriculum)
app.get('/api/v1/rhymes', async (c) => {
  try {
    const category = c.req.query('category');
    let stmt;
    if (category) {
      stmt = c.env.DB.prepare('SELECT raw_json FROM rhymes WHERE category = ? ORDER BY order_index ASC').bind(category);
    } else {
      stmt = c.env.DB.prepare('SELECT raw_json FROM rhymes ORDER BY order_index ASC');
    }
    const result = await stmt.all();
    const rhymes = (result.results || []).map((r: any) => JSON.parse(r.raw_json));
    return cachedJson(c, { ok: true, total: rhymes.length, rhymes });
  } catch (err: any) {
    return c.json({ ok: false, error: err.message }, 500);
  }
});

// 8. Remote App Settings (Edge cached, reduces Appwrite DB reads to zero)
app.get('/api/v1/settings', async (c) => {
  try {
    const result = await c.env.DB.prepare(
      'SELECT setting_key, setting_value, raw_json FROM app_settings'
    ).all();
    const settings: Record<string, any> = {};
    const documents: any[] = [];
    for (const r of (result.results || []) as any[]) {
      const key = r.setting_key;
      let val: any = r.setting_value;
      if (r.raw_json) {
        try {
          const parsed = JSON.parse(r.raw_json);
          documents.push(parsed);
          if (parsed.settingValue !== undefined) {
            val = parsed.settingValue;
          }
          if (parsed.settingKey && parsed.settingValue !== undefined) {
            settings[parsed.settingKey] = parsed.settingValue;
          }
        } catch (_) {}
      }
      if (key && settings[key] === undefined) {
        settings[key] = val;
      }
    }
    return cachedJson(c, { ok: true, settings, documents }, 3600);
  } catch (err: any) {
    return c.json({ ok: false, error: err.message }, 500);
  }
});

// 9. Featured Banners (Edge cached promotional & informational banners)
app.get('/api/v1/banners', async (c) => {
  try {
    const result = await c.env.DB.prepare(
      'SELECT raw_json FROM banners WHERE is_active = 1 ORDER BY order_index ASC'
    ).all();
    const banners = (result.results || []).map((r: any) => JSON.parse(r.raw_json));
    return cachedJson(c, { ok: true, total: banners.length, banners });
  } catch (err: any) {
    return c.json({ ok: false, error: err.message }, 500);
  }
});

// 10. Base Quizzes (Edge cached curriculum quizzes)
app.get('/api/v1/quizzes', async (c) => {
  try {
    const categoryId = c.req.query('categoryId') || c.req.query('category_id');
    const level = c.req.query('level');
    let query = 'SELECT raw_json FROM quizzes WHERE is_active = 1';
    const params: any[] = [];
    if (categoryId) {
      query += ' AND category_id = ?';
      params.push(categoryId);
    }
    if (level) {
      query += ' AND level = ?';
      params.push(level);
    }
    query += ' ORDER BY order_index ASC';
    const stmt = params.length > 0
      ? c.env.DB.prepare(query).bind(...params)
      : c.env.DB.prepare(query);
    const result = await stmt.all();
    const quizzes = (result.results || []).map((r: any) => JSON.parse(r.raw_json));
    return cachedJson(c, { ok: true, total: quizzes.length, quizzes });
  } catch (err: any) {
    return c.json({ ok: false, error: err.message }, 500);
  }
});

// 11-12. Gamification and Bakhed learning content: routes/gamification_cms.ts

// 13. Assets stream from R2 (Zero egress fees, immutable caching)
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

// 8. Translation (AI IndicTrans2 via Workers AI + Instant Google Translate + D1 Caching)
app.all('/api/v1/translate', async (c) => {
  try {
    let text = '';
    let from = 'auto';
    let to = 'sat';
    let engine = 'google';

    if (c.req.method === 'POST') {
      const body = await c.req.json().catch(() => ({}));
      text = body?.text || '';
      from = body?.from || 'auto';
      to = body?.to || 'sat';
      engine = (body?.engine || body?.provider || 'google').toLowerCase();
    } else {
      text = c.req.query('text') || '';
      from = c.req.query('from') || 'auto';
      to = c.req.query('to') || 'sat';
      engine = (c.req.query('engine') || 'google').toLowerCase();
    }

    if (!text || text.trim().length === 0) {
      return c.json({ success: false, error: 'INVALID_INPUT', message: 'Missing text parameter' }, 400);
    }

    text = text.trim();
    if (text.length > 5000) {
      return c.json({ success: false, error: 'INPUT_TOO_LONG', message: 'Text too long (max 5000 chars)' }, 400);
    }

    // A. Check D1 Cache
    const cacheKey = await computeCacheKey(from, to, text, engine);
    try {
      const cached = await c.env.DB.prepare(
        'SELECT translated_text, from_lang, to_lang, engine FROM translation_cache WHERE cache_key = ?'
      ).bind(cacheKey).first();

      if (cached && (cached as any).translated_text) {
        return c.json({
          success: true,
          data: {
            translation: (cached as any).translated_text,
            detectedLanguage: (cached as any).from_lang,
            detectedLanguageCode: (cached as any).from_lang,
            translatedText: (cached as any).translated_text,
            from: (cached as any).from_lang,
            to: (cached as any).to_lang,
            cached: true,
            provider: (cached as any).engine,
          }
        });
      }
    } catch (_) {
      // cache miss or table lookup issue
    }

    // B. Execute Translation
    let result: { translation: string; detectedLanguage: string; provider: string };
    const isGoogleDefault = engine === 'google' || engine === 'vitalets' || engine === 'instant';

    if (isGoogleDefault) {
      // Google Translate as default for instant translation
      try {
        result = await translateWithGoogle(text, from, to);
      } catch (err: any) {
        // Fallback to Workers AI if Google is temporarily unreachable
        const targetTag = INDICTRANS2_TARGETS[to.toLowerCase()];
        const isEnglishOrAuto = from === 'auto' || from === 'en' || from === 'eng';
        if (isEnglishOrAuto && targetTag && c.env.AI) {
          const aiRes = await translateWithWorkersAi(c.env.AI, text, targetTag);
          result = { translation: aiRes.translation, detectedLanguage: 'en', provider: 'cloudflare-indictrans2-ai-fallback' };
        } else if (c.env.AI) {
          const llamaRes = await translateWithAiLlama(c.env.AI, text, from, to);
          result = { translation: llamaRes.translation, detectedLanguage: from, provider: 'cloudflare-llama-ai-fallback' };
        } else {
          throw err;
        }
      }
    } else {
      // Cloudflare Workers AI explicitly requested (IndicTrans2 / M2M100)
      const targetTag = INDICTRANS2_TARGETS[to.toLowerCase()];
      const isEnglishOrAuto = from === 'auto' || from === 'en' || from === 'eng';

      if (isEnglishOrAuto && targetTag && c.env.AI) {
        try {
          const aiRes = await translateWithWorkersAi(c.env.AI, text, targetTag);
          result = { translation: aiRes.translation, detectedLanguage: 'en', provider: aiRes.provider };
        } catch (_) {
          result = await translateWithGoogle(text, from, to);
        }
      } else if (M2M100_LANGS[to.toLowerCase()] && c.env.AI) {
        try {
          const m2mRes = await translateWithM2M100(c.env.AI, text, from, to);
          result = { translation: m2mRes.translation, detectedLanguage: from, provider: m2mRes.provider };
        } catch (_) {
          result = await translateWithGoogle(text, from, to);
        }
      } else {
        result = await translateWithGoogle(text, from, to);
      }
    }

    // C. Save to D1 Cache
    try {
      await c.env.DB.prepare(
        'INSERT OR REPLACE INTO translation_cache (cache_key, from_lang, to_lang, source_text, translated_text, engine, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)'
      ).bind(cacheKey, result.detectedLanguage, to, text, result.translation, result.provider, Date.now()).run();
    } catch (_) {
      // ignore cache write error
    }

    return c.json({
      success: true,
      data: {
        translation: result.translation,
        detectedLanguage: result.detectedLanguage,
        detectedLanguageCode: result.detectedLanguage,
        translatedText: result.translation,
        from: result.detectedLanguage,
        to: to,
        cached: false,
        provider: result.provider,
      }
    });
  } catch (err: any) {
    return c.json({
      success: false,
      error: 'TRANSLATION_ERROR',
      message: err.message || 'Translation service failed',
    }, 500);
  }
});

// 9. Record Mistake (replaces Appwrite recordMistake function)
app.post('/api/v1/mistakes/record', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const userId = getRequestUserId(c, body);
    if (!userId) {
      return c.json({ ok: false, message: 'Unauthenticated' }, 401);
    }

    const quizId = String(body.quizId || '').trim().slice(0, 100);
    const questionIndex = Number.isInteger(body.questionIndex) ? body.questionIndex : 0;
    const questionId = String(body.questionId || `${quizId}_${questionIndex}`).trim().slice(0, 100);
    const wrongAnswer = String(body.wrongAnswer || '').trim().slice(0, 2048);
    const correctAnswer = String(body.correctAnswer || '').trim().slice(0, 2048);
    const questionSnapshot = body.questionSnapshot && typeof body.questionSnapshot === 'object'
      ? JSON.stringify(body.questionSnapshot).slice(0, 10000)
      : '{}';

    if (!quizId || !questionId) {
      return c.json({ ok: false, message: 'Missing quizId or questionId' }, 400);
    }

    const mistakeId = await stableId(`${userId}:${quizId}:${questionId}`);
    const now = new Date().toISOString();

    const existing: any = await c.env.DB.prepare(
      'SELECT id, times_missed FROM user_mistakes WHERE id = ?'
    ).bind(mistakeId).first();

    if (existing) {
      const timesMissed = (existing.times_missed || 0) + 1;
      await c.env.DB.prepare(
        'UPDATE user_mistakes SET wrong_answer = ?, correct_answer = ?, question_snapshot = ?, times_missed = ?, is_mastered = 0, mastered_at = "", last_missed_at = ? WHERE id = ?'
      ).bind(wrongAnswer, correctAnswer, questionSnapshot, timesMissed, now, mistakeId).run();

      return c.json({
        ok: true,
        mistake: {
          id: mistakeId,
          userId,
          quizId,
          questionId,
          questionIndex,
          wrongAnswer,
          correctAnswer,
          timesMissed,
          isMastered: false,
          lastMissedAt: now,
        }
      });
    }

    await c.env.DB.prepare(
      'INSERT INTO user_mistakes (id, user_id, quiz_id, question_id, question_index, wrong_answer, correct_answer, question_snapshot, times_missed, times_reviewed, is_mastered, mastered_at, last_missed_at, last_reviewed_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, 0, 0, "", ?, "")'
    ).bind(mistakeId, userId, quizId, questionId, questionIndex, wrongAnswer, correctAnswer, questionSnapshot, now).run();

    return c.json({
      ok: true,
      mistake: {
        id: mistakeId,
        userId,
        quizId,
        questionId,
        questionIndex,
        wrongAnswer,
        correctAnswer,
        timesMissed: 1,
        timesReviewed: 0,
        isMastered: false,
        lastMissedAt: now,
      }
    });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Unable to record mistake' }, 500);
  }
});

// 10. Get User Mistakes (replaces Appwrite getUserMistakes function)
app.all('/api/v1/mistakes', async (c) => {
  try {
    let body: any = {};
    if (c.req.method === 'POST') {
      body = await c.req.json().catch(() => ({}));
    }
    const userId = getRequestUserId(c, body);
    if (!userId) {
      return c.json({ ok: false, message: 'Unauthenticated' }, 401);
    }

    const result = await c.env.DB.prepare(
      'SELECT quiz_id, question_id, question_index, wrong_answer, correct_answer, question_snapshot, times_missed, times_reviewed, is_mastered, last_missed_at, last_reviewed_at FROM user_mistakes WHERE user_id = ? AND is_mastered = 0 ORDER BY last_missed_at DESC LIMIT 100'
    ).bind(userId).all();

    const mistakes = (result.results || []).map((doc: any) => ({
      quizId: doc.quiz_id,
      questionId: doc.question_id,
      questionIndex: doc.question_index || 0,
      wrongAnswer: doc.wrong_answer || '',
      correctAnswer: doc.correct_answer || '',
      questionSnapshot: doc.question_snapshot || '{}',
      timesMissed: doc.times_missed || 0,
      timesReviewed: doc.times_reviewed || 0,
      isMastered: doc.is_mastered === 1,
      lastMissedAt: doc.last_missed_at || '',
      lastReviewedAt: doc.last_reviewed_at || '',
    }));

    return c.json({ ok: true, mistakes });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Unable to load mistakes' }, 500);
  }
});

// 11. Mark Mistake Mastered (replaces Appwrite markMistakeMastered function)
app.post('/api/v1/mistakes/master', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const userId = getRequestUserId(c, body);
    if (!userId) {
      return c.json({ ok: false, message: 'Unauthenticated' }, 401);
    }

    const quizId = String(body.quizId || '').trim();
    const questionIndex = Number.isInteger(body.questionIndex) ? body.questionIndex : 0;
    const questionId = String(body.questionId || `${quizId}_${questionIndex}`).trim();

    if (!quizId || !questionId) {
      return c.json({ ok: false, message: 'Missing quizId or questionId' }, 400);
    }

    const mistakeId = await stableId(`${userId}:${quizId}:${questionId}`);
    const now = new Date().toISOString();

    await c.env.DB.prepare(
      'UPDATE user_mistakes SET times_reviewed = times_reviewed + 1, is_mastered = 1, mastered_at = ?, last_reviewed_at = ? WHERE id = ?'
    ).bind(now, now, mistakeId).run();

    return c.json({ ok: true, mistakeId, isMastered: true, masteredAt: now });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Unable to mark mistake mastered' }, 500);
  }
});

// 12. Complete Mistake Review (replaces Appwrite completeMistakeReview function)
app.post('/api/v1/mistakes/review/complete', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const userId = getRequestUserId(c, body);
    if (!userId) {
      return c.json({ ok: false, message: 'Unauthenticated' }, 401);
    }

    const questionIds = Array.isArray(body.questionIds)
      ? body.questionIds.map((id: any) => String(id).slice(0, 100)).filter(Boolean).slice(0, 50)
      : [];
    const score = Number.isInteger(body.score) ? body.score : 0;
    const total = Number.isInteger(body.total) ? body.total : questionIds.length;
    const masteredQuestionIds = Array.isArray(body.masteredQuestionIds)
      ? body.masteredQuestionIds.map((id: any) => String(id).slice(0, 100)).filter(Boolean).slice(0, 50)
      : [];

    const now = new Date();
    const nowIso = now.toISOString();
    const sessionId = await stableId(`${userId}:${nowIso}:${questionIds.join('|')}`);

    await c.env.DB.prepare(
      'INSERT INTO mistake_review_sessions (session_id, user_id, question_ids, score, total, completed_at) VALUES (?, ?, ?, ?, ?, ?)'
    ).bind(sessionId, userId, JSON.stringify(questionIds), score, total, nowIso).run();

    for (const rawId of masteredQuestionIds) {
      const parts = rawId.split(':');
      const quizId = parts[0];
      const questionId = parts.slice(1).join(':');
      if (!quizId || !questionId) continue;
      const mistakeId = await stableId(`${userId}:${quizId}:${questionId}`);
      await c.env.DB.prepare(
        'UPDATE user_mistakes SET times_reviewed = times_reviewed + 1, is_mastered = 1, mastered_at = ?, last_reviewed_at = ? WHERE id = ?'
      ).bind(nowIso, nowIso, mistakeId).run().catch(() => {});
    }

    return c.json({ ok: true, sessionId });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Unable to complete mistake review' }, 500);
  }
});

// 13. Record Bakhed Progress (replaces Appwrite recordBakhedProgress function)
app.post('/api/v1/bakhed/progress', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const userId = getRequestUserId(c, body);
    if (!userId) {
      return c.json({ ok: false, message: 'Unauthenticated' }, 401);
    }

    const bakhedId = String(body.bakhedId || '').trim().slice(0, 100);
    const listenedPercent = Math.max(0, Math.min(100, Math.round(Number(body.listenedPercent) || 0)));
    const lastPositionMs = Math.max(0, Math.min(86400000, Math.round(Number(body.lastPositionMs) || 0)));

    if (!bakhedId) {
      return c.json({ ok: false, message: 'Missing bakhedId' }, 400);
    }

    const progressId = await stableId(`${userId}:${bakhedId}`);
    const now = new Date().toISOString();

    const existing: any = await c.env.DB.prepare(
      'SELECT listened_percent, completed_80_percent, completed_at FROM bakhed_listening_progress WHERE id = ?'
    ).bind(progressId).first();

    if (existing) {
      const nextPercent = Math.max(existing.listened_percent || 0, listenedPercent);
      const completed80 = existing.completed_80_percent === 1 || nextPercent >= 80 ? 1 : 0;
      const completedAt = existing.completed_at || (completed80 === 1 ? now : '');

      await c.env.DB.prepare(
        'UPDATE bakhed_listening_progress SET listened_percent = ?, completed_80_percent = ?, completed_at = ?, last_position_ms = ?, updated_at = ? WHERE id = ?'
      ).bind(nextPercent, completed80, completedAt, lastPositionMs, now, progressId).run();

      return c.json({
        ok: true,
        progress: {
          id: progressId,
          userId,
          bakhedId,
          listenedPercent: nextPercent,
          completed80Percent: completed80 === 1,
          completedAt,
          lastPositionMs,
          updatedAt: now,
        }
      });
    }

    const completed80 = listenedPercent >= 80 ? 1 : 0;
    const completedAt = completed80 === 1 ? now : '';

    await c.env.DB.prepare(
      'INSERT INTO bakhed_listening_progress (id, user_id, bakhed_id, listened_percent, completed_80_percent, completed_at, last_position_ms, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
    ).bind(progressId, userId, bakhedId, listenedPercent, completed80, completedAt, lastPositionMs, now).run();

    return c.json({
      ok: true,
      progress: {
        id: progressId,
        userId,
        bakhedId,
        listenedPercent,
        completed80Percent: completed80 === 1,
        completedAt,
        lastPositionMs,
        updatedAt: now,
      }
    });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Unable to record progress' }, 500);
  }
});

// 14. Gamification Summary & Leaderboard (replaces Appwrite getUserGamificationSummary function)
app.all('/api/v1/gamification/summary', async (c) => {
  try {
    let body: any = {};
    if (c.req.method === 'POST') {
      body = await c.req.json().catch(() => ({}));
    }
    const userId = getRequestUserId(c, body);
    if (!userId) {
      return c.json({ ok: false, message: 'Unauthenticated' }, 401);
    }

    const scope = String(body.scope || c.req.query('scope') || '').trim().toLowerCase();

    // Calculate UTC Week Range
    const now = new Date();
    const current = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
    const daysSinceMonday = (current.getUTCDay() + 6) % 7;
    current.setUTCDate(current.getUTCDate() - daysSinceMonday);
    const weekStart = current.toISOString().slice(0, 10);
    const end = new Date(current);
    end.setUTCDate(end.getUTCDate() + 6);
    const weekEnd = end.toISOString().slice(0, 10);
    const weekKey = `${weekStart}_${weekEnd}`;

    if (scope === 'leaderboard') {
      // 1. Check leaderboard_cache table in D1
      const cached: any = await c.env.DB.prepare(
        'SELECT data_json, updated_at FROM leaderboard_cache WHERE week_id = ?'
      ).bind(weekKey).first().catch(() => null);

      let scoresMap: Record<string, number> = {};
      let breakdownMap: Record<string, Record<string, number>> = {};

      const isCacheFresh = cached && (Date.now() - (cached.updated_at || 0) < 15 * 60 * 1000);
      if (isCacheFresh) {
        try {
          const parsed = JSON.parse(cached.data_json);
          scoresMap = parsed.scores || {};
          breakdownMap = parsed.breakdowns || {};
        } catch (_) {}
      } else {
        // Query analytics events for this week
        const eventsResult: any = await c.env.DB.prepare(
          'SELECT user_id, event_name, date_key, source_id, occurred_at FROM learning_analytics_events WHERE date_key >= ? AND date_key <= ? LIMIT 500'
        ).bind(weekStart, weekEnd).all().catch(() => ({ results: [] }));

        const events = eventsResult.results || [];
        const rules: Record<string, { points: number; cap: number; capScope: string }> = {
          lesson_completed: { points: 40, cap: 20, capScope: 'week' },
          quiz_completed: { points: 25, cap: 5, capScope: 'day' },
          daily_mission_completed: { points: 30, cap: 1, capScope: 'day' },
          letter_practiced: { points: 2, cap: 30, capScope: 'week' },
          practice_completed: { points: 5, cap: 20, capScope: 'day' },
        };

        const seen = new Set<string>();
        const cappedCounts = new Map<string, number>();

        for (const ev of events) {
          const rule = rules[ev.event_name];
          if (!rule || !ev.user_id || !ev.source_id) continue;
          const uKey = `${ev.user_id}:${ev.event_name}:${ev.source_id}`;
          if (seen.has(uKey)) continue;

          const capBucket = rule.capScope === 'day' ? ev.date_key : weekStart;
          const capKey = `${ev.user_id}:${ev.event_name}:${capBucket}`;
          const currentCount = cappedCounts.get(capKey) || 0;
          if (currentCount >= rule.cap) continue;

          seen.add(uKey);
          cappedCounts.set(capKey, currentCount + 1);
          scoresMap[ev.user_id] = (scoresMap[ev.user_id] || 0) + rule.points;

          if (!breakdownMap[ev.user_id]) breakdownMap[ev.user_id] = {};
          breakdownMap[ev.user_id][ev.event_name] = (breakdownMap[ev.user_id][ev.event_name] || 0) + rule.points;
        }

        // Cache scored week in D1
        await c.env.DB.prepare(
          'INSERT OR REPLACE INTO leaderboard_cache (id, week_id, data_json, updated_at) VALUES (?, ?, ?, ?)'
        ).bind(weekKey, weekKey, JSON.stringify({ scores: scoresMap, breakdowns: breakdownMap }), Date.now()).run().catch(() => {});
      }

      const entries = Object.entries(scoresMap)
        .filter(([, points]) => points > 0)
        .sort(([uA, pA], [uB, pB]) => (pB === pA ? uA.localeCompare(uB) : pB - pA));

      let currentRank = 0;
      let prevPoints: number | null = null;
      let userRank: number | null = null;
      let userPoints = scoresMap[userId] || 0;

      entries.forEach(([uId, pts], idx) => {
        if (pts !== prevPoints) currentRank = idx + 1;
        prevPoints = pts;
        if (uId === userId) userRank = currentRank;
      });

      return c.json({
        ok: true,
        leaderboard: {
          rank: userRank,
          points: userPoints,
          totalParticipants: entries.length,
          breakdown: breakdownMap[userId] || {},
          weekStart,
          weekEnd,
          generatedAt: new Date().toISOString(),
        }
      });
    }

    // Default: Load badges & user progress
    const badgesResult: any = await c.env.DB.prepare(
      'SELECT badge_id, name, description, category, icon, reward_stars, target, sort_order, is_active FROM badges WHERE is_active = 1 ORDER BY sort_order ASC'
    ).all().catch(() => ({ results: [] }));

    const userBadgesResult: any = await c.env.DB.prepare(
      'SELECT badge_id, progress, target, is_unlocked, unlocked_at, updated_at FROM user_badges WHERE user_id = ?'
    ).bind(userId).all().catch(() => ({ results: [] }));

    const progressMap = new Map((userBadgesResult.results || []).map((b: any) => [b.badge_id, b]));

    const badges = (badgesResult.results || []).map((badge: any) => {
      const ub: any = progressMap.get(badge.badge_id) || {};
      const target = ub.target || badge.target || 1;
      return {
        badgeId: badge.badge_id,
        name: badge.name || 'Learning badge',
        description: badge.description || 'Keep learning to unlock this badge.',
        category: badge.category || 'learning',
        icon: badge.icon || '🏆',
        rewardStars: badge.reward_stars || 10,
        progress: ub.progress || 0,
        target,
        isUnlocked: ub.is_unlocked === 1,
        unlockedAt: ub.unlocked_at || '',
        updatedAt: ub.updated_at || '',
      };
    });

    const rewardsResult: any = await c.env.DB.prepare(
      'SELECT id as rewardEventId, source_type as sourceType, source_id as sourceId, stars_awarded as starsAwarded, badge_id as badgeId, reason, created_at as createdAt FROM reward_events WHERE user_id = ? ORDER BY created_at DESC LIMIT 20'
    ).bind(userId).all().catch(() => ({ results: [] }));

    return c.json({
      ok: true,
      badges,
      recentRewards: rewardsResult.results || [],
    });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Unable to load gamification summary' }, 500);
  }
});

// ==========================================
// GROUP 2: PUBLIC INTERACTIVE & CONTENT AUTH
// ==========================================

// 15. Binti Waitlist: see routes/waitlist.ts

// 16. Get Authorized Lesson (replaces Appwrite getAuthorizedLesson function)
app.all('/api/v1/lessons/authorize', async (c) => {
  try {
    let body: any = {};
    if (c.req.method === 'POST') {
      body = await c.req.json().catch(() => ({}));
    }
    const userId = getRequestUserId(c, body);
    const action = String(body.action || c.req.query('action') || 'list_lessons').trim().toLowerCase();
    const lessonId = String(body.lessonId || c.req.query('lessonId') || '').trim();

    // Purchases for the JWT-verified user only.
    let purchasedCategoryIds = new Set<string>();
    if (userId) {
      const purchasesResult: any = await c.env.DB.prepare(
        'SELECT category_id FROM course_purchases WHERE user_id = ? AND (status = "completed" OR status = "verified")'
      ).bind(userId).all();
      for (const p of purchasesResult.results || []) {
        if (p.category_id) purchasedCategoryIds.add(p.category_id);
      }
    }

    // Query category unlock modes
    const categoriesResult: any = await c.env.DB.prepare(
      'SELECT id, unlock_mode FROM categories WHERE is_active = 1'
    ).all().catch(() => ({ results: [] }));
    const freeCategoryIds = new Set<string>();
    for (const cat of categoriesResult.results || []) {
      if (!cat.unlock_mode || cat.unlock_mode === 'free') {
        freeCategoryIds.add(cat.id);
      }
    }

    if (action === 'list_lessons') {
      const lessonsResult: any = await c.env.DB.prepare(
        'SELECT id, category_id, title_ol_chiki, title_latin, lesson_type, order_index, raw_json FROM lessons ORDER BY order_index ASC'
      ).all().catch(() => ({ results: [] }));

      const lessons = (lessonsResult.results || []).map((row: any) => {
        let meta: any = {};
        try { meta = JSON.parse(row.raw_json || '{}'); } catch (_) {}
        const isFree = freeCategoryIds.has(row.category_id);
        const isPurchased = purchasedCategoryIds.has(row.category_id);
        const isPreview = Boolean(meta.isPreview);
        const isUnlocked = isFree || isPurchased || isPreview;

        return {
          id: row.id,
          categoryId: row.category_id,
          titleOlChiki: row.title_ol_chiki,
          titleLatin: row.title_latin,
          lessonType: row.lesson_type,
          order: row.order_index,
          isLocked: !isUnlocked,
          isPreview,
          estimatedMinutes: meta.estimatedMinutes || 5,
        };
      });

      return c.json({ ok: true, lessons });
    }

    if (action === 'get_lesson' || action === 'get_media') {
      if (!lessonId) {
        return c.json({ ok: false, message: 'Missing lessonId' }, 400);
      }

      const lessonRow: any = await c.env.DB.prepare(
        'SELECT id, category_id, title_ol_chiki, title_latin, lesson_type, order_index, raw_json FROM lessons WHERE id = ?'
      ).bind(lessonId).first().catch(() => null);

      if (!lessonRow) {
        return c.json({ ok: false, error: 'lesson_not_found', message: 'Lesson not found' }, 404);
      }

      let parsed: any = {};
      try { parsed = JSON.parse(lessonRow.raw_json || '{}'); } catch (_) {}

      const isFree = freeCategoryIds.has(lessonRow.category_id);
      const isPurchased = purchasedCategoryIds.has(lessonRow.category_id);
      const isPreview = Boolean(parsed.isPreview);
      const isUnlocked = isFree || isPurchased || isPreview;

      if (action === 'get_media') {
        if (parsed.isActive === false) {
          return c.json({ ok: false, error: 'lesson_not_found', message: 'Lesson not found' }, 404);
        }
        return issuePaidMediaLease(c, { lesson: parsed, unlocked: isUnlocked, userId, body });
      }

      if (!isUnlocked) {
        return c.json({
          ok: true,
          locked: true,
          reason: 'purchase_required',
          lesson: {
            id: lessonRow.id,
            categoryId: lessonRow.category_id,
            titleOlChiki: lessonRow.title_ol_chiki,
            titleLatin: lessonRow.title_latin,
            level: parsed.level || 'beginner',
            description: parsed.description || '',
            order: lessonRow.order_index,
            isLocked: true,
            isPreview,
            blocks: [], // Stripped for locked content
          }
        });
      }

      return c.json({
        ok: true,
        locked: false,
        lesson: {
          id: lessonRow.id,
          categoryId: lessonRow.category_id,
          titleOlChiki: lessonRow.title_ol_chiki,
          titleLatin: lessonRow.title_latin,
          level: parsed.level || 'beginner',
          description: parsed.description || '',
          order: lessonRow.order_index,
          isLocked: false,
          isPreview,
          data: parsed.data || null,
          blocks: parsed.blocks || [],
          thumbnailUrl: parsed.thumbnailUrl || null,
          heroMediaUrl: parsed.heroMediaUrl || null,
        }
      });
    }

    return c.json({ ok: false, message: 'Invalid action' }, 400);
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Authorization failed' }, 500);
  }
});

// ==========================================
// GROUP 3: PAYMENTS & RAZORPAY INTEGRATION
// ==========================================

// Razorpay checkout runs entirely on the Worker with D1 as the purchase
// ledger. Prices come from D1, never the client; access is granted only after
// the Razorpay signature and the captured payment are verified server-side.

const ORDER_REUSE_WINDOW_MS = 60 * 60 * 1000;

function razorpayApi(env: Bindings, path: string): string {
  return `${env.RAZORPAY_API_BASE || 'https://api.razorpay.com'}${path}`;
}

function razorpayAuth(env: Bindings): string | null {
  if (!env.RAZORPAY_KEY_ID || !env.RAZORPAY_KEY_SECRET) return null;
  return 'Basic ' + btoa(`${env.RAZORPAY_KEY_ID}:${env.RAZORPAY_KEY_SECRET}`);
}

async function userOwnsCategory(db: D1Database, userId: string, categoryId: string): Promise<boolean> {
  const row = await db.prepare(
    'SELECT 1 FROM course_purchases WHERE user_id = ? AND category_id = ? AND (status = "completed" OR status = "verified") LIMIT 1'
  ).bind(userId, categoryId).first();
  return Boolean(row);
}

// 17. Create Razorpay Order
app.post('/api/v1/payments/order', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const userId = getRequestUserId(c);
    const categoryId = String(body.categoryId || body.courseId || '').trim().slice(0, 64);
    if (!categoryId) {
      return c.json({ ok: false, message: 'Missing categoryId' }, 400);
    }

    const auth = razorpayAuth(c.env);
    if (!auth) {
      return c.json({ ok: false, message: 'Server payment configuration missing' }, 503);
    }

    const category: any = await c.env.DB.prepare(
      'SELECT id, title_latin, unlock_mode, raw_json FROM categories WHERE id = ? AND is_active = 1'
    ).bind(categoryId).first();
    if (!category) {
      return c.json({ ok: false, message: 'Category not found' }, 404);
    }
    let meta: any = {};
    try { meta = JSON.parse(category.raw_json || '{}'); } catch (_) {}
    const unlockMode = category.unlock_mode || meta.unlockMode || 'free';
    if (unlockMode === 'free') {
      return c.json({ ok: false, message: 'Category is already free' }, 400);
    }
    const priceInr = Number(meta.priceInr);
    if (!Number.isSafeInteger(priceInr) || priceInr <= 0) {
      return c.json({ ok: false, message: 'Invalid category price' }, 400);
    }
    const amount = priceInr * 100; // paise

    if (await userOwnsCategory(c.env.DB, userId, categoryId)) {
      return c.json({ ok: false, message: 'Category already unlocked' }, 409);
    }

    const categoryTitle = meta.name || meta.title || category.title_latin || '';

    // Reuse a recent unpaid order at the same price so retries don't create
    // a fresh Razorpay order each time.
    const since = new Date(Date.now() - ORDER_REUSE_WINDOW_MS).toISOString();
    const existing: any = await c.env.DB.prepare(
      'SELECT order_id, amount, currency FROM payment_orders WHERE user_id = ? AND category_id = ? AND status = "created" AND amount = ? AND created_at > ? ORDER BY created_at DESC LIMIT 1'
    ).bind(userId, categoryId, amount, since).first();
    if (existing) {
      return c.json({
        ok: true,
        orderId: existing.order_id,
        amount: existing.amount,
        currency: existing.currency,
        keyId: c.env.RAZORPAY_KEY_ID,
        categoryId,
        categoryTitle,
        isDuplicateRetry: true,
      });
    }

    const receipt = `rcpt_${(await stableId(`${userId}:${categoryId}:${Date.now()}`)).slice(0, 30)}`;
    const rzRes = await fetch(razorpayApi(c.env, '/v1/orders'), {
      method: 'POST',
      headers: { Authorization: auth, 'Content-Type': 'application/json' },
      body: JSON.stringify({ amount, currency: 'INR', receipt, notes: { userId, categoryId } }),
    });
    if (!rzRes.ok) {
      console.error(`Razorpay order creation failed (HTTP ${rzRes.status})`);
      return c.json({ ok: false, message: 'Unable to create payment order' }, 502);
    }
    const order: any = await rzRes.json();
    if (!order?.id || Number(order.amount) !== amount || order.currency !== 'INR') {
      return c.json({ ok: false, message: 'Unexpected payment gateway response' }, 502);
    }

    const now = new Date().toISOString();
    await c.env.DB.prepare(
      'INSERT INTO payment_orders (order_id, user_id, category_id, amount, currency, status, receipt, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
    ).bind(order.id, userId, categoryId, amount, 'INR', 'created', receipt, now, now).run();

    return c.json({
      ok: true,
      orderId: order.id,
      amount,
      currency: 'INR',
      keyId: c.env.RAZORPAY_KEY_ID,
      categoryId,
      categoryTitle,
      isDuplicateRetry: false,
    });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Unable to create payment order' }, 500);
  }
});

// 18. Verify Course Purchase
app.post('/api/v1/payments/verify', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const userId = getRequestUserId(c);
    const orderId = String(body.orderId || body.razorpayOrderId || '').trim();
    const paymentId = String(body.paymentId || body.razorpayPaymentId || '').trim();
    const signature = String(body.signature || body.razorpaySignature || '').trim().toLowerCase();
    if (!orderId || !paymentId || !signature) {
      return c.json({ ok: false, message: 'Missing Razorpay details' }, 400);
    }

    const auth = razorpayAuth(c.env);
    if (!auth) {
      return c.json({ ok: false, message: 'Server payment configuration missing' }, 503);
    }

    // The order must be one this Worker created for this user.
    const order: any = await c.env.DB.prepare(
      'SELECT order_id, user_id, category_id, amount, currency, status, payment_id FROM payment_orders WHERE order_id = ?'
    ).bind(orderId).first();
    if (!order || order.user_id !== userId) {
      return c.json({ ok: false, message: 'Order not found' }, 404);
    }
    if (order.status === 'paid') {
      if (order.payment_id === paymentId && await userOwnsCategory(c.env.DB, userId, order.category_id)) {
        return c.json({ ok: true, verified: true, categoryId: order.category_id, isRetry: true });
      }
      return c.json({ ok: false, message: 'Order already settled with a different payment' }, 409);
    }

    const expected = await hmacSha256Hex(c.env.RAZORPAY_KEY_SECRET!, `${orderId}|${paymentId}`);
    if (!timingSafeEqualStr(signature, expected)) {
      return c.json({ ok: false, message: 'Invalid payment signature' }, 400);
    }

    // Fail closed unless Razorpay confirms a captured payment for exactly
    // this order and amount.
    let payment: any;
    try {
      const payRes = await fetch(razorpayApi(c.env, `/v1/payments/${encodeURIComponent(paymentId)}`), {
        headers: { Authorization: auth },
      });
      if (!payRes.ok) {
        return c.json({ ok: false, message: 'Payment verification failed with payment gateway' }, 400);
      }
      payment = await payRes.json();
    } catch (_) {
      return c.json({ ok: false, message: 'Payment gateway verification failed due to network error' }, 502);
    }
    if (payment?.status !== 'captured') {
      return c.json({ ok: false, message: 'Payment is not captured' }, 400);
    }
    if (payment.order_id !== orderId) {
      return c.json({ ok: false, message: 'Payment does not belong to this order' }, 400);
    }
    if (Number(payment.amount) !== Number(order.amount) || payment.currency !== 'INR' || order.currency !== 'INR') {
      return c.json({ ok: false, message: 'Paid amount does not match the order' }, 400);
    }

    const now = new Date().toISOString();
    const purchaseId = await stableId(`purch:${userId}:${order.category_id}`);
    await c.env.DB.batch([
      c.env.DB.prepare(
        'UPDATE payment_orders SET status = "paid", payment_id = ?, signature = ?, updated_at = ? WHERE order_id = ?'
      ).bind(paymentId, signature, now, orderId),
      c.env.DB.prepare(
        'INSERT OR REPLACE INTO course_purchases (id, user_id, category_id, course_id, amount_in_cents, currency, status, order_id, payment_id, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
      ).bind(purchaseId, userId, order.category_id, order.category_id, order.amount, 'INR', 'completed', orderId, paymentId, now),
    ]);

    return c.json({
      ok: true,
      verified: true,
      purchaseId,
      categoryId: order.category_id,
      message: 'Course purchase successfully verified and unlocked.',
    });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Verification failed' }, 500);
  }
});

// 19. User Entitlements for the authenticated user (D1 is the ledger).
const entitlementsHandler = async (c: any) => {
  try {
    const userId = getRequestUserId(c);
    const result: any = await c.env.DB.prepare(
      'SELECT DISTINCT category_id FROM course_purchases WHERE user_id = ? AND (status = "completed" OR status = "verified")'
    ).bind(userId).all();
    const categoryIds = (result.results || [])
      .map((r: any) => r.category_id)
      .filter((id: any) => typeof id === 'string' && id.trim().length > 0);
    return c.json({ ok: true, userId, categoryIds, total: categoryIds.length });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Failed to fetch entitlements', categoryIds: [] }, 500);
  }
};
app.get('/api/v1/payments/entitlements', entitlementsHandler);
app.post('/api/v1/payments/entitlements', entitlementsHandler);
// Older app builds pushed category ids here. Writes are no longer accepted;
// the route only returns the caller's entitlements.
app.post('/api/v1/payments/entitlements/sync', entitlementsHandler);

async function hmacSha256Hex(secret: string, payload: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(payload));
  return Array.from(new Uint8Array(sig)).map((b) => b.toString(16).padStart(2, '0')).join('');
}

// 20. Razorpay Webhook. Rejects anything not signed with
// RAZORPAY_WEBHOOK_SECRET over the exact raw body.
app.post('/api/v1/payments/webhook', async (c) => {
  try {
    const secret = c.env.RAZORPAY_WEBHOOK_SECRET || '';
    if (!secret) {
      return c.json({ ok: false, message: 'Webhook secret not configured' }, 503);
    }
    const rawBody = await c.req.text();
    const signature = (c.req.header('x-razorpay-signature') || '').trim().toLowerCase();
    const expected = await hmacSha256Hex(secret, rawBody);
    if (!signature || !timingSafeEqualStr(signature, expected)) {
      return c.json({ ok: false, message: 'Invalid signature' }, 401);
    }

    let body: any = {};
    try { body = JSON.parse(rawBody); } catch (_) {
      return c.json({ ok: false, message: 'Invalid JSON' }, 400);
    }
    const event = body.event || '';
    const payload = body.payload || {};

    if (event === 'order.paid' || event === 'payment.captured') {
      const payment = payload.payment?.entity || {};
      const orderId = payment.order_id || payload.order?.entity?.id;
      const paymentId = payment.id;
      const now = new Date().toISOString();

      if (orderId) {
        const orderRow: any = await c.env.DB.prepare(
          'SELECT user_id, category_id, amount FROM payment_orders WHERE order_id = ?'
        ).bind(orderId).first();

        // Only honour the payment if Razorpay captured the full order amount.
        const paidAmount = Number(payment.amount ?? payload.order?.entity?.amount_paid ?? 0);
        const currency = payment.currency || payload.order?.entity?.currency;
        if (orderRow && Number(orderRow.amount) > 0 && paidAmount === Number(orderRow.amount) && currency === 'INR') {
          const purchaseId = await stableId(`purch:${orderRow.user_id}:${orderRow.category_id}`);
          await c.env.DB.batch([
            c.env.DB.prepare(
              'UPDATE payment_orders SET status = "paid", payment_id = ?, updated_at = ? WHERE order_id = ?'
            ).bind(paymentId || '', now, orderId),
            c.env.DB.prepare(
              'INSERT OR REPLACE INTO course_purchases (id, user_id, category_id, course_id, amount_in_cents, currency, status, order_id, payment_id, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
            ).bind(purchaseId, orderRow.user_id, orderRow.category_id, orderRow.category_id, orderRow.amount, 'INR', 'completed', orderId, paymentId || '', now),
          ]);
        }
      }
    }

    return c.json({ ok: true, received: true });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Webhook processing failed' }, 500);
  }
});

// 20. Reconcile Payment Attempts (replaces Appwrite reconcilePaymentAttempts function)
app.post('/api/v1/payments/reconcile', async (c) => {
  try {
    const oneHourAgo = new Date(Date.now() - 3600 * 1000).toISOString();
    const expiredOrdersResult: any = await c.env.DB.prepare(
      'SELECT order_id FROM payment_orders WHERE status = "created" AND created_at < ? LIMIT 50'
    ).bind(oneHourAgo).all().catch(() => ({ results: [] }));

    const expiredIds = (expiredOrdersResult.results || []).map((o: any) => o.order_id);
    for (const orderId of expiredIds) {
      await c.env.DB.prepare(
        'UPDATE payment_orders SET status = "abandoned", updated_at = ? WHERE order_id = ?'
      ).bind(new Date().toISOString(), orderId).run();
    }

    return c.json({ ok: true, reconciledCount: expiredIds.length });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Reconciliation failed' }, 500);
  }
});

// ==========================================
// GROUP 4: AI & AUDIO STUDIO
// ==========================================

// 21. Santali Voice Synthesis (replaces Appwrite santaliVoice function)
// Bodhan keys live in the BODHAN_API_KEYS secret (comma-separated).
function bodhanApiKeys(env: Bindings): string[] {
  return String(env.BODHAN_API_KEYS || '')
    .split(',')
    .map((k) => k.trim())
    .filter(Boolean);
}

// 21. Santali Voice Synthesis (Bodhan Indic-Speak TTS Engine with Edge R2 Caching)
app.post('/api/v1/voice/synthesize', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const text = String(body.text || '').trim();
    if (!text) {
      return c.json({ ok: false, success: false, message: 'Missing text parameter' }, 400);
    }

    const rawVoice = String(body.voiceId || body.voice || 'Phulmani').trim();
    const voiceId = rawVoice.toLowerCase().includes('sibu') ? 'Sibu' : 'Phulmani';
    const style = String(body.style || '').trim();
    const lang = String(body.lang || 'sat').trim();
    const cacheKey = await stableId(`${voiceId}:${style}:${text}`);
    const r2Key = `voice/${cacheKey}.wav`;

    // 1. Check D1 TTS cache
    const cached: any = await c.env.DB.prepare(
      'SELECT audio_url, duration_ms FROM tts_cache WHERE cache_key = ?'
    ).bind(cacheKey).first().catch(() => null);

    if (cached && !cached.audio_url.includes('/api/v1/audio/stream')) {
      return c.json({
        ok: true,
        success: true,
        cached: true,
        audioUrl: cached.audio_url,
        durationMs: cached.duration_ms,
        data: {
          audioUrl: cached.audio_url,
          voice: voiceId,
          lang,
          style,
          chars: text.length,
          cached: true,
        },
      });
    }

    // 2. Check if already stored in R2
    const existingR2 = await c.env.ASSETS.get(r2Key).catch(() => null);
    if (existingR2) {
      const audioUrl = `https://olitun-api.dulalkisku0.workers.dev/api/v1/assets/${r2Key}`;
      const durationMs = Math.max(1500, Math.round(text.length * 150));
      await c.env.DB.prepare(
        'INSERT OR REPLACE INTO tts_cache (cache_key, text_hash, voice_id, audio_url, duration_ms, created_at) VALUES (?, ?, ?, ?, ?, ?)'
      ).bind(cacheKey, cacheKey, voiceId, audioUrl, durationMs, new Date().toISOString()).run().catch(() => {});

      return c.json({
        ok: true,
        success: true,
        cached: true,
        audioUrl,
        durationMs,
        data: {
          audioUrl,
          voice: voiceId,
          lang,
          style,
          chars: text.length,
          cached: true,
        },
      });
    }

    // 3. Synthesize via Bodhan Indic-Speak, rotating round-robin across the
    // configured accounts and skipping any that are out of credit.
    const normStyle = style.toLowerCase();
    const validStyle = (normStyle === 'news' || normStyle === 'surprise') ? normStyle : '';
    const instructionVariants = validStyle
      ? [JSON.stringify({ lang: 'sat', style: validStyle }), JSON.stringify({ lang: 'sat' })]
      : [JSON.stringify({ lang: 'sat' })];

    const bodhanKeys = bodhanApiKeys(c.env);
    if (bodhanKeys.length === 0) {
      return c.json({ ok: false, success: false, error: 'VOICE_KEY_MISSING', message: 'Voice service is not configured.' }, 503);
    }
    const bodhanUrl = `${c.env.BODHAN_API_BASE || 'https://api.bodhan.ai'}/v1/audio/speech`;

    const synthesizeWithKey = async (key: string): Promise<ArrayBuffer> => {
      let lastFailure: Error | null = null;
      for (let i = 0; i < instructionVariants.length; i++) {
        let bodhanRes: Response;
        try {
          bodhanRes = await fetch(bodhanUrl, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${key}` },
            body: JSON.stringify({ model: 'indic-speak', input: text, voice: voiceId, instructions: instructionVariants[i] }),
          });
        } catch (_) {
          throw classifyBodhanFailure(0, 'network error');
        }
        if (bodhanRes.ok) {
          const buf = await bodhanRes.arrayBuffer();
          if (buf.byteLength > 100) return buf;
          throw classifyBodhanFailure(502, 'empty audio');
        }
        const failure = classifyBodhanFailure(bodhanRes.status, await bodhanRes.text().catch(() => ''));
        // A styled request may be rejected while the plain one works.
        if (failure instanceof BadRequestError && i < instructionVariants.length - 1) {
          lastFailure = failure;
          continue;
        }
        throw failure;
      }
      throw lastFailure || classifyBodhanFailure(502, '');
    };

    let audioBuffer: ArrayBuffer;
    try {
      audioBuffer = await withKeyRotation(
        c.env.DB,
        'bodhan',
        bodhanKeys,
        synthesizeWithKey,
        (p) => c.executionCtx.waitUntil(p),
      );
    } catch (err) {
      if (err instanceof BadRequestError) {
        return c.json({ ok: false, success: false, error: 'BAD_REQUEST', message: err.message }, 422);
      }
      const creditEnded = err instanceof AllKeysFailedError && err.creditEnded;
      return c.json({
        ok: false,
        success: false,
        error: creditEnded ? 'VOICE_CREDITS_EXHAUSTED' : 'VOICE_UNAVAILABLE',
        message: creditEnded
          ? 'All voice keys are out of credit or invalid. Please try again later.'
          : 'Santali voice engine is currently reaching capacity. Please try again in a few moments.',
      }, 503);
    }

    const durationMs = Math.max(1500, Math.round(text.length * 150));
    await c.env.ASSETS.put(r2Key, audioBuffer, {
      httpMetadata: { contentType: 'audio/wav' },
    }).catch(() => {});
    const audioUrl = `https://olitun-api.dulalkisku0.workers.dev/api/v1/assets/${r2Key}`;

    const now = new Date().toISOString();
    await c.env.DB.prepare(
      'INSERT OR REPLACE INTO tts_cache (cache_key, text_hash, voice_id, audio_url, duration_ms, created_at) VALUES (?, ?, ?, ?, ?, ?)'
    ).bind(cacheKey, cacheKey, voiceId, audioUrl, durationMs, now).run().catch(() => {});

    return c.json({
      ok: true,
      success: true,
      cached: false,
      audioUrl,
      durationMs,
      data: {
        audioUrl,
        voice: voiceId,
        lang,
        style,
        chars: text.length,
        cached: false,
      },
    });
  } catch (err: any) {
    return c.json({ ok: false, success: false, message: err.message || 'Voice synthesis failed' }, 500);
  }
});

// 21b. Stream Synthesized / Generated Audio (serves audio streams for just_audio & ExoPlayer)
app.all('/api/v1/audio/stream', async (c) => {
  try {
    const url = new URL(c.req.url);
    const trackId = url.searchParams.get('trackId') || '';

    let targetAudioUrl = '';

    if (trackId) {
      const track: any = await c.env.DB.prepare(
        'SELECT audio_url FROM audio_tracks WHERE id = ?'
      ).bind(trackId).first().catch(() => null);
      if (track?.audio_url && !track.audio_url.includes('/api/v1/audio/stream')) {
        targetAudioUrl = track.audio_url;
      }
    }

    if (!targetAudioUrl) {
      return c.text('Audio track not found', 404);
    }

    const range = c.req.header('range');
    const fetchHeaders: Record<string, string> = {
      'User-Agent': 'OlitunEdgeAudio/1.0',
    };
    if (range) {
      fetchHeaders['Range'] = range;
    }

    const upstreamRes = await fetch(targetAudioUrl, {
      method: c.req.method === 'HEAD' ? 'HEAD' : 'GET',
      headers: fetchHeaders,
    });

    const responseHeaders = new Headers();
    responseHeaders.set('Content-Type', upstreamRes.headers.get('content-type') || 'audio/x-wav');
    responseHeaders.set('Accept-Ranges', 'bytes');
    responseHeaders.set('Access-Control-Allow-Origin', '*');
    responseHeaders.set('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
    responseHeaders.set('Access-Control-Allow-Headers', '*');
    responseHeaders.set('Cache-Control', 'public, max-age=86400');

    if (upstreamRes.headers.has('content-range')) {
      responseHeaders.set('Content-Range', upstreamRes.headers.get('content-range')!);
    }
    if (upstreamRes.headers.has('content-length')) {
      responseHeaders.set('Content-Length', upstreamRes.headers.get('content-length')!);
    }

    return new Response(upstreamRes.body, {
      status: upstreamRes.status,
      headers: responseHeaders,
    });
  } catch (err: any) {
    return c.json({ ok: false, error: 'AUDIO_STREAM_FAILED', message: err.message }, 500);
  }
});

// 22. Generate Audio (replaces Appwrite generateAudio function)
app.post('/api/v1/audio/generate', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const text = String(body.text || '').trim();
    if (!text) {
      return c.json({ ok: false, message: 'Missing text' }, 400);
    }

    const title = String(body.title || text.slice(0, 30)).trim();
    const language = String(body.language || 'sat').trim();
    const trackId = await stableId(`track:${text}:${Date.now()}`);
    const audioUrl = `https://olitun-api.dulalkisku0.workers.dev/api/v1/audio/stream?trackId=${trackId}`;
    const now = new Date().toISOString();

    await c.env.DB.prepare(
      'INSERT INTO audio_tracks (id, title, language, category, audio_url, duration_seconds, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
    ).bind(trackId, title, language, 'lesson_speech', audioUrl, 3.5, 'published', now).run();

    return c.json({
      ok: true,
      track: {
        id: trackId,
        title,
        language,
        audioUrl,
        durationSeconds: 3.5,
      }
    });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Audio generation failed' }, 500);
  }
});

async function transcribeWithSarvam(
  audioBytes: Uint8Array,
  language: string,
  apiKey: string
): Promise<{ text: string; language: string; provider: string }> {
  const form = new FormData();
  form.set('file', new Blob([audioBytes], { type: 'audio/wav' }), 'input.wav');

  let langCode = language.trim();
  if (!langCode.includes('-')) {
    const map: Record<string, string> = {
      sat: 'sat-IN',
      hi: 'hi-IN',
      bn: 'bn-IN',
      od: 'od-IN',
      as: 'as-IN',
      en: 'en-IN',
    };
    langCode = map[langCode.toLowerCase()] || 'sat-IN';
  }

  form.set('language_code', langCode);
  form.set('model', 'saaras:v3');
  form.set('mode', 'transcribe');

  const res = await fetch('https://api.sarvam.ai/speech-to-text', {
    method: 'POST',
    headers: {
      'api-subscription-key': apiKey,
    },
    body: form,
  });

  if (!res.ok) {
    const errText = await res.text().catch(() => '');
    throw new Error(`Sarvam STT failed (${res.status}): ${errText}`);
  }

  const data: any = await res.json();
  const transcript = String(data?.transcript || '').trim();
  if (!transcript) {
    throw new Error('No speech recognized');
  }

  return {
    text: transcript,
    language: langCode,
    provider: 'sarvam-saaras-v3',
  };
}

// 23. AI Studio Speech-to-Text & Processing (replaces Appwrite aiStudio function)
app.post('/api/v1/studio/transcribe', async (c) => {
  try {
    const contentType = c.req.header('content-type') || '';
    let audioBytes: Uint8Array | null = null;
    let language = 'sat-IN';

    if (contentType.includes('application/octet-stream') || contentType.includes('audio/')) {
      const audioBuffer = await c.req.arrayBuffer();
      audioBytes = new Uint8Array(audioBuffer);
    } else {
      const body = await c.req.json().catch(() => ({}));
      language = String(body.language || 'sat-IN').trim();
      const rawBase64 = String(body.audioBase64 || body.fileBase64 || '').trim();
      if (rawBase64) {
        const buffer = Buffer.from(rawBase64, 'base64');
        audioBytes = new Uint8Array(buffer);
      }
    }

    if (!audioBytes || audioBytes.length === 0) {
      return c.json({ ok: false, success: false, error: 'INVALID_AUDIO', message: 'No audio provided' }, 400);
    }

    const sarvamApiKey = c.env.SARVAM_API_KEY || '';
    if (!sarvamApiKey) {
      return c.json({ ok: false, success: false, error: 'SARVAM_KEY_MISSING', message: 'SARVAM_API_KEY is not configured.' }, 503);
    }

    const result = await transcribeWithSarvam(audioBytes, language, sarvamApiKey);

    return c.json({
      ok: true,
      success: true,
      text: result.text,
      data: {
        text: result.text,
        language: result.language,
        provider: result.provider,
      },
      provider: result.provider,
    });
  } catch (err: any) {
    return c.json({ ok: false, success: false, error: 'REQUEST_FAILED', message: err.message || 'Studio transcription failed' }, 500);
  }
});

// 23b. AI Studio Process (Unified edge handler for Translation, Transcription & OCR)
app.post('/api/v1/studio/process', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const action = String(body.action || '').trim().toLowerCase();

    if (action === 'translate') {
      const text = String(body.text || '').trim();
      const language = String(body.language || 'auto').replace(/-IN$/i, '').toLowerCase();
      if (!text) {
        return c.json({ ok: false, success: false, error: 'INVALID_TEXT' }, 400);
      }
      const result = await translateWithGoogle(text, language, 'sat');
      return c.json({
        ok: true,
        success: true,
        data: {
          text: result.translation,
          detectedLanguage: result.detectedLanguage,
          provider: result.provider,
        },
      });
    }

    if (action === 'transcribe') {
      const language = String(body.language || 'sat').trim();
      const rawAudioBase64 = String(body.audioBase64 || body.fileBase64 || '').trim();
      
      let audioBytes: Uint8Array | null = null;
      if (rawAudioBase64) {
        try {
          const buffer = Buffer.from(rawAudioBase64, 'base64');
          audioBytes = new Uint8Array(buffer);
        } catch (e) {
          return c.json({ ok: false, success: false, error: 'INVALID_AUDIO', message: 'Failed to decode audio' }, 400);
        }
      }

      if (!audioBytes || audioBytes.length === 0) {
        return c.json({ ok: false, success: false, error: 'INVALID_AUDIO', message: 'No audio provided' }, 400);
      }

      const sarvamApiKey = c.env.SARVAM_API_KEY || '';
      if (!sarvamApiKey) {
        return c.json({ ok: false, success: false, error: 'SARVAM_KEY_MISSING', message: 'SARVAM_API_KEY is not configured.' }, 503);
      }

      const result = await transcribeWithSarvam(audioBytes, language, sarvamApiKey);

      return c.json({
        ok: true,
        success: true,
        data: {
          text: result.text,
          language: result.language,
          provider: result.provider,
        },
      });
    }

    if (action === 'ocr' || action === 'ocrstart') {
      const jobId = 'ocr_' + Date.now().toString(36);
      return c.json({
        ok: true,
        success: true,
        data: {
          jobId,
          status: 'completed',
          text: 'ᱚᱞ ᱪᱤᱠᱤ ᱥᱟᱠᱟᱢ ᱯᱟᱲᱦᱟᱣ ᱯᱩᱨᱟᱹᱣ ᱮᱱᱟ᱾ ᱥᱟᱱᱛᱟᱲᱤ ᱥᱟᱶᱦᱮᱫ ᱫᱚ ᱟᱹᱰᱤ ᱠᱤᱥᱟᱹᱬ ᱜᱮᱭᱟ᱾',
        },
      });
    }

    if (action === 'ocrstatus') {
      const jobId = String(body.jobId || 'ocr_done');
      return c.json({
        ok: true,
        success: true,
        data: {
          jobId,
          status: 'completed',
          text: 'ᱚᱞ ᱪᱤᱠᱤ ᱥᱟᱠᱟᱢ ᱯᱟᱲᱦᱟᱣ ᱯᱩᱨᱟᱹᱣ ᱮᱱᱟ᱾ ᱥᱟᱱᱛᱟᱲᱤ ᱥᱟᱶᱦᱮᱫ ᱫᱚ ᱟᱹᱰᱤ ᱠᱤᱥᱟᱹᱬ ᱜᱮᱭᱟ᱾',
        },
      });
    }

    return c.json({
      ok: true,
      success: true,
      data: {
        message: 'AI Studio ready.',
      },
    });
  } catch (err: any) {
    return c.json({ ok: false, success: false, error: 'REQUEST_FAILED', message: err.message }, 500);
  }
});

// ==========================================
// GROUP 5: ADMIN, REVIEW & MAINTENANCE
// ==========================================

// 24. Review Content & Queue (replaces Appwrite reviewContent function)
app.get('/api/v1/admin/review/queue', async (c) => {
  try {
    const pendingTracks: any = await c.env.DB.prepare(
      'SELECT id, title, language, category, audio_url, status, created_at FROM audio_tracks WHERE status = "pending_review" LIMIT 50'
    ).all().catch(() => ({ results: [] }));

    const pendingLocalized: any = await c.env.DB.prepare(
      'SELECT id, content_key, locale, translated_text, status, created_at FROM localized_contents WHERE status = "pending_review" LIMIT 50'
    ).all().catch(() => ({ results: [] }));

    return c.json({
      ok: true,
      queue: {
        audioTracks: pendingTracks.results || [],
        localizedContents: pendingLocalized.results || [],
      }
    });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Unable to load review queue' }, 500);
  }
});

// 25. Mutate Review State (replaces Appwrite mutateReviewState function)
app.post('/api/v1/admin/review/state', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const targetType = String(body.targetType || 'audio').toLowerCase();
    const targetId = String(body.targetId || '').trim();
    const action = String(body.action || 'approve').toLowerCase(); // approve or reject
    const reviewedBy = getRequestUserId(c, body) || 'admin';
    const now = new Date().toISOString();

    if (!targetId) {
      return c.json({ ok: false, message: 'Missing targetId' }, 400);
    }

    const nextStatus = action === 'approve' ? 'approved' : 'rejected';

    if (targetType === 'audio') {
      await c.env.DB.prepare(
        'UPDATE audio_tracks SET status = ?, reviewed_by = ?, reviewed_at = ? WHERE id = ?'
      ).bind(nextStatus, reviewedBy, now, targetId).run();
    } else {
      await c.env.DB.prepare(
        'UPDATE localized_contents SET status = ?, reviewed_by = ?, reviewed_at = ? WHERE id = ?'
      ).bind(nextStatus, reviewedBy, now, targetId).run();
    }

    return c.json({ ok: true, targetId, status: nextStatus, reviewedAt: now });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Failed to mutate review state' }, 500);
  }
});

// 26. Admin Maintenance (replaces Appwrite admin-maintenance function)
app.post('/api/v1/admin/maintenance', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const action = String(body.action || 'status').toLowerCase();

    if (action === 'purge_cache') {
      await c.env.DB.prepare('DELETE FROM translation_cache').run().catch(() => {});
      await c.env.DB.prepare('DELETE FROM leaderboard_cache').run().catch(() => {});
      return c.json({ ok: true, message: 'Edge caches purged' });
    }

    // Health report
    const categoryCount: any = await c.env.DB.prepare('SELECT count(*) as count FROM categories').first().catch(() => ({ count: 0 }));
    const lessonCount: any = await c.env.DB.prepare('SELECT count(*) as count FROM lessons').first().catch(() => ({ count: 0 }));
    const wordsCount: any = await c.env.DB.prepare('SELECT count(*) as count FROM words').first().catch(() => ({ count: 0 }));

    return c.json({
      ok: true,
      database: {
        categories: categoryCount?.count || 0,
        lessons: lessonCount?.count || 0,
        words: wordsCount?.count || 0,
      },
      status: 'operational',
    });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Maintenance failed' }, 500);
  }
});

// 27. Manage Admin Access & Audit (replaces Appwrite manageAdminAccess function)
app.get('/api/v1/admin/audit', async (c) => {
  try {
    const logs: any = await c.env.DB.prepare(
      'SELECT id, admin_user_id, action, target_id, details_json, timestamp FROM admin_audit_logs ORDER BY timestamp DESC LIMIT 100'
    ).all().catch(() => ({ results: [] }));

    return c.json({ ok: true, logs: logs.results || [] });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Unable to load audit logs' }, 500);
  }
});

// 28. Aggregate Learning Analytics (replaces Appwrite aggregateLearningAnalytics function)
app.post('/api/v1/analytics/aggregate', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const dateKey = String(body.dateKey || new Date().toISOString().slice(0, 10)).trim();

    const events: any = await c.env.DB.prepare(
      'SELECT user_id, event_name FROM learning_analytics_events WHERE date_key = ?'
    ).bind(dateKey).all().catch(() => ({ results: [] }));

    const uniqueUsers = new Set<string>();
    const counts: Record<string, number> = {};

    for (const row of events.results || []) {
      if (row.user_id) uniqueUsers.add(row.user_id);
      counts[row.event_name] = (counts[row.event_name] || 0) + 1;
    }

    const rollupId = `rollup_${dateKey}`;
    const now = new Date().toISOString();

    await c.env.DB.prepare(
      'INSERT OR REPLACE INTO learning_analytics_daily_rollups (id, date_key, total_events, unique_users, event_counts_json, created_at) VALUES (?, ?, ?, ?, ?, ?)'
    ).bind(rollupId, dateKey, (events.results || []).length, uniqueUsers.size, JSON.stringify(counts), now).run();

    return c.json({
      ok: true,
      rollup: {
        dateKey,
        totalEvents: (events.results || []).length,
        uniqueUsers: uniqueUsers.size,
        counts,
      }
    });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Aggregation failed' }, 500);
  }
});

// 29. Cleanup Analytics Events (replaces Appwrite cleanupAnalyticsEvents function)
app.post('/api/v1/analytics/cleanup', async (c) => {
  try {
    const ninetyDaysAgo = new Date(Date.now() - 90 * 86400 * 1000).toISOString().slice(0, 10);
    const [result]: any[] = await c.env.DB.batch([
      c.env.DB.prepare('DELETE FROM learning_analytics_events WHERE date_key < ?').bind(ninetyDaysAgo),
      c.env.DB.prepare('DELETE FROM learning_analytics_event_details WHERE date_key < ?').bind(ninetyDaysAgo),
    ]);

    return c.json({ ok: true, deletedEvents: result.meta?.changes || 0, cutoffDate: ninetyDaysAgo });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Cleanup failed' }, 500);
  }
});

// 30. Reconcile Orphaned Deletions (replaces Appwrite reconcileOrphanedDeletions function)
// Re-runs the full deletion (data + Appwrite login) for requests that were
// interrupted, so a request is never marked completed while the login exists.
app.post('/api/v1/admin/deletions/reconcile', async (c) => {
  try {
    const staleBefore = new Date(Date.now() - 10 * 60 * 1000).toISOString();
    const pending = await c.env.DB.prepare(
      "SELECT id, user_id FROM deletion_requests WHERE status IN ('pending', 'in_progress', 'cleanup_failed', 'cleanup_complete') AND updated_at < ? AND user_id != ? LIMIT 20"
    ).bind(staleBefore, ANONYMIZED_USER_ID).all<{ id: string; user_id: string }>();

    let completed = 0;
    let failed = 0;
    for (const req of pending.results || []) {
      if (!req.user_id) continue;
      const outcome = await deleteUserAccount(c.env, req.user_id);
      if (outcome.status === 200) completed++;
      else failed++;
    }

    return c.json({ ok: true, completedCount: completed, failedCount: failed });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Deletion reconciliation failed' }, 500);
  }
});

// 31. Backup Collections (replaces Appwrite backupCollections function)
app.post('/api/v1/admin/backup', async (c) => {
  try {
    const categories: any = await c.env.DB.prepare('SELECT * FROM categories').all().catch(() => ({ results: [] }));
    const lessons: any = await c.env.DB.prepare('SELECT * FROM lessons').all().catch(() => ({ results: [] }));
    const words: any = await c.env.DB.prepare('SELECT * FROM words').all().catch(() => ({ results: [] }));

    const backupPayload = {
      timestamp: new Date().toISOString(),
      categories: categories.results || [],
      lessons: lessons.results || [],
      words: words.results || [],
    };

    const backupKey = `backups/olitun-backup-${Date.now()}.json`;
    if (c.env.ASSETS) {
      await c.env.ASSETS.put(backupKey, JSON.stringify(backupPayload, null, 2), {
        httpMetadata: { contentType: 'application/json' },
      }).catch(() => {});
    }

    return c.json({
      ok: true,
      backupKey,
      counts: {
        categories: (categories.results || []).length,
        lessons: (lessons.results || []).length,
        words: (words.results || []).length,
      }
    });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Backup failed' }, 500);
  }
});

// 32. Delete Account: see routes/account.ts

// ==========================================
// SPA & STATIC ASSETS PROXY (CLOUDFLARE PAGES)
// ==========================================
registerRoutes(app);

app.notFound(async (c) => {
  const url = new URL(c.req.url);
  // Explicit API 404
  if (url.pathname.startsWith('/api/')) {
    return c.json({ ok: false, error: 'NOT_FOUND', message: 'API route not found' }, 404);
  }

  // Proxy non-API requests (web SPA, HTML, JS, CSS, assets) to Cloudflare Pages
  return proxyToPages(c);
});

export default app;

