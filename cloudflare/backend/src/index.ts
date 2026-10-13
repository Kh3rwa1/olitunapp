import { Hono } from 'hono';
import { cors } from 'hono/cors';

type Bindings = {
  DB: D1Database;
  ASSETS: R2Bucket;
  AI: any;
};

const app = new Hono<{ Bindings: Bindings }>();

// Global CORS middleware for Flutter Web & Mobile
app.use('*', cors());

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
  const url = `https://clients5.google.com/translate_a/t?client=dict-chrome-ex&sl=${encodeURIComponent(sl)}&tl=${encodeURIComponent(to)}&q=${encodeURIComponent(text)}`;

  const res = await fetch(url, {
    method: 'GET',
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    },
  });

  if (!res.ok) {
    throw new Error(`Google Translate HTTP error ${res.status}`);
  }

  const data: any = await res.json();
  let translation = '';
  let detectedLanguage = from;

  if (Array.isArray(data)) {
    if (typeof data[0] === 'string') {
      translation = data[0];
    } else if (Array.isArray(data[0])) {
      translation = data[0][0] || '';
      detectedLanguage = data[0][1] || from;
    }
  }

  if (!translation) {
    throw new Error('Google Translate returned empty translation');
  }

  return {
    translation: translation.trim(),
    detectedLanguage,
    provider: 'google-nmt-instant',
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

// 8. Translation (AI IndicTrans2 via Workers AI + Instant Google Translate + D1 Caching)
app.all('/api/v1/translate', async (c) => {
  try {
    let text = '';
    let from = 'auto';
    let to = 'sat';
    let engine = 'cloudflare';

    if (c.req.method === 'POST') {
      const body = await c.req.json().catch(() => ({}));
      text = body?.text || '';
      from = body?.from || 'auto';
      to = body?.to || 'sat';
      engine = (body?.engine || body?.provider || 'cloudflare').toLowerCase();
    } else {
      text = c.req.query('text') || '';
      from = c.req.query('from') || 'auto';
      to = c.req.query('to') || 'sat';
      engine = (c.req.query('engine') || 'cloudflare').toLowerCase();
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
    const targetTag = INDICTRANS2_TARGETS[to.toLowerCase()];
    const isEnglishOrAuto = from === 'auto' || from === 'en' || from === 'eng';

    // 1. If English -> Indic/Santali, use IndicTrans2 (Best for Ol Chiki)
    if (isEnglishOrAuto && targetTag && c.env.AI) {
      try {
        const aiRes = await translateWithWorkersAi(c.env.AI, text, targetTag);
        result = {
          translation: aiRes.translation,
          detectedLanguage: 'en',
          provider: aiRes.provider,
        };
      } catch (_) {
        // Fallback to Llama or Google
        try {
          const llamaRes = await translateWithAiLlama(c.env.AI, text, from, to);
          result = { translation: llamaRes.translation, detectedLanguage: from, provider: llamaRes.provider };
        } catch (__2) {
          result = await translateWithGoogle(text, from, to);
        }
      }
    } else if (M2M100_LANGS[to.toLowerCase()] && c.env.AI) {
      // 2. Multilingual translation using Meta M2M100
      try {
        const m2mRes = await translateWithM2M100(c.env.AI, text, from, to);
        result = { translation: m2mRes.translation, detectedLanguage: from, provider: m2mRes.provider };
      } catch (_) {
        try {
          const llamaRes = await translateWithAiLlama(c.env.AI, text, from, to);
          result = { translation: llamaRes.translation, detectedLanguage: from, provider: llamaRes.provider };
        } catch (__2) {
          result = await translateWithGoogle(text, from, to);
        }
      }
    } else if (c.env.AI) {
      // 3. Ol Chiki to English or conversational languages using Llama 3
      try {
        const llamaRes = await translateWithAiLlama(c.env.AI, text, from, to);
        result = { translation: llamaRes.translation, detectedLanguage: from, provider: llamaRes.provider };
      } catch (_) {
        result = await translateWithGoogle(text, from, to);
      }
    } else {
      result = await translateWithGoogle(text, from, to);
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

export default app;
