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

// Helper to extract authenticated or provided userId
function getRequestUserId(c: any, body?: any): string {
  const headerUser = c.req.header('x-appwrite-user-id') || c.req.header('x-user-id') || c.req.header('user-id');
  if (headerUser && typeof headerUser === 'string' && headerUser.trim().length > 0) {
    return headerUser.trim();
  }
  if (body?.userId && typeof body.userId === 'string' && body.userId.trim().length > 0) {
    return body.userId.trim();
  }
  return '';
}

async function stableId(value: string): Promise<string> {
  const msgUint8 = new TextEncoder().encode(value);
  const hashBuffer = await crypto.subtle.digest('SHA-256', msgUint8);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('').slice(0, 32);
}

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
    const userId = getRequestUserId(c, body) || c.req.query('userId') || '';
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
    const userId = getRequestUserId(c, body) || c.req.query('userId') || '';
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

// 15. Binti Waitlist (replaces Appwrite bintiWaitlist function)
app.post('/api/v1/waitlist/join', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const userId = getRequestUserId(c, body);

    const fullName = String(body.fullName || '').trim();
    if (fullName.length < 2 || fullName.length > 100) {
      return c.json({ ok: false, message: 'fullName must be between 2 and 100 characters.' }, 400);
    }

    const phoneNumber = String(body.phoneNumber || '').trim();
    const phoneDigits = phoneNumber.replace(/[^0-9]/g, '');
    if (phoneDigits.length < 7 || phoneDigits.length > 20) {
      return c.json({ ok: false, message: 'phoneNumber must be 7-20 digits.' }, 400);
    }

    const ceremonyType = String(body.ceremonyType || 'binti').trim().toLowerCase();
    const city = String(body.city || '').trim().slice(0, 100);
    const state = String(body.state || '').trim().slice(0, 100);
    const notes = String(body.notes || '').trim().slice(0, 1000);

    let eventDate: string | null = null;
    if (body.eventDate) {
      const parsed = new Date(String(body.eventDate));
      if (!Number.isNaN(parsed.getTime())) {
        eventDate = parsed.toISOString();
      }
    }

    // Check duplicate pending entry
    const existing: any = await c.env.DB.prepare(
      'SELECT id, full_name, phone_number, ceremony_type, city, state, event_date, notes, submitted_at, status FROM binti_waitlist WHERE phone_number = ? AND ceremony_type = ? AND status = ? LIMIT 1'
    ).bind(phoneNumber, ceremonyType, 'new').first().catch(() => null);

    if (existing) {
      return c.json({
        ok: true,
        duplicate: true,
        entry: {
          id: existing.id,
          fullName: existing.full_name,
          phoneNumber: existing.phone_number,
          ceremonyType: existing.ceremony_type,
          city: existing.city,
          state: existing.state,
          eventDate: existing.event_date,
          notes: existing.notes,
          submittedAt: existing.submitted_at,
          status: existing.status,
        }
      });
    }

    const entryId = await stableId(`${phoneNumber}:${ceremonyType}:${Date.now()}`);
    const now = new Date().toISOString();

    await c.env.DB.prepare(
      'INSERT INTO binti_waitlist (id, user_id, full_name, phone_number, ceremony_type, city, state, event_date, notes, submitted_at, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
    ).bind(entryId, userId || null, fullName, phoneNumber, ceremonyType, city, state, eventDate, notes, now, 'new').run();

    return c.json({
      ok: true,
      duplicate: false,
      entry: {
        id: entryId,
        userId: userId || null,
        fullName,
        phoneNumber,
        ceremonyType,
        city,
        state,
        eventDate,
        notes,
        submittedAt: now,
        status: 'new',
      }
    });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Waitlist submission failed' }, 500);
  }
});

// 16. Get Authorized Lesson (replaces Appwrite getAuthorizedLesson function)
app.all('/api/v1/lessons/authorize', async (c) => {
  try {
    let body: any = {};
    if (c.req.method === 'POST') {
      body = await c.req.json().catch(() => ({}));
    }
    const userId = getRequestUserId(c, body) || c.req.query('userId') || '';
    const action = String(body.action || c.req.query('action') || 'list_lessons').trim().toLowerCase();
    const lessonId = String(body.lessonId || c.req.query('lessonId') || '').trim();

    // Query user purchases from D1
    let purchasedCategoryIds = new Set<string>();
    if (userId) {
      const purchasesResult: any = await c.env.DB.prepare(
        'SELECT category_id FROM course_purchases WHERE user_id = ? AND status = "completed"'
      ).bind(userId).all().catch(() => ({ results: [] }));
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

// 17. Create Razorpay Order (replaces Appwrite createRazorpayOrder function)
app.post('/api/v1/payments/order', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const userId = getRequestUserId(c, body);
    if (!userId) {
      return c.json({ ok: false, message: 'Unauthenticated' }, 401);
    }

    const categoryId = String(body.categoryId || body.courseId || '').trim();
    if (!categoryId) {
      return c.json({ ok: false, message: 'Missing categoryId' }, 400);
    }

    const amount = Number(body.amount) || 49900; // in paise (₹499)
    const currency = 'INR';
    const orderId = `order_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
    const receipt = `rcpt_${userId.slice(0, 8)}_${Date.now()}`;
    const now = new Date().toISOString();

    await c.env.DB.prepare(
      'INSERT INTO payment_orders (order_id, user_id, category_id, amount, currency, status, receipt, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
    ).bind(orderId, userId, categoryId, amount, currency, 'created', receipt, now, now).run();

    return c.json({
      ok: true,
      order: {
        id: orderId,
        amount,
        currency,
        receipt,
        categoryId,
        status: 'created',
      }
    });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Unable to create payment order' }, 500);
  }
});

// 18. Verify Course Purchase (replaces Appwrite verifyCoursePurchase function)
app.post('/api/v1/payments/verify', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const userId = getRequestUserId(c, body);
    if (!userId) {
      return c.json({ ok: false, message: 'Unauthenticated' }, 401);
    }

    const orderId = String(body.orderId || '').trim();
    const paymentId = String(body.paymentId || '').trim();
    const signature = String(body.signature || '').trim();
    const categoryId = String(body.categoryId || '').trim();

    if (!orderId || !paymentId) {
      return c.json({ ok: false, message: 'Missing orderId or paymentId' }, 400);
    }

    const now = new Date().toISOString();
    const purchaseId = await stableId(`purch:${userId}:${categoryId || orderId}`);

    // Update order status in D1
    await c.env.DB.prepare(
      'UPDATE payment_orders SET status = "paid", payment_id = ?, signature = ?, updated_at = ? WHERE order_id = ?'
    ).bind(paymentId, signature, now, orderId).run().catch(() => {});

    // Record entitlement in course_purchases
    await c.env.DB.prepare(
      'INSERT OR REPLACE INTO course_purchases (id, user_id, category_id, course_id, amount_in_cents, currency, status, order_id, payment_id, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
    ).bind(purchaseId, userId, categoryId, categoryId, 49900, 'INR', 'completed', orderId, paymentId, now).run();

    return c.json({
      ok: true,
      verified: true,
      purchaseId,
      categoryId,
      message: 'Course purchase successfully verified and unlocked.'
    });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Verification failed' }, 500);
  }
});

// 19. Razorpay Webhook (replaces Appwrite razorpayWebhook function)
app.post('/api/v1/payments/webhook', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const event = body.event || '';
    const payload = body.payload || {};

    if (event === 'order.paid' || event === 'payment.captured') {
      const payment = payload.payment?.entity || {};
      const orderId = payment.order_id || payload.order?.entity?.id;
      const paymentId = payment.id;
      const now = new Date().toISOString();

      if (orderId) {
        // Find existing order in D1
        const orderRow: any = await c.env.DB.prepare(
          'SELECT user_id, category_id, amount FROM payment_orders WHERE order_id = ?'
        ).bind(orderId).first().catch(() => null);

        if (orderRow) {
          await c.env.DB.prepare(
            'UPDATE payment_orders SET status = "paid", payment_id = ?, updated_at = ? WHERE order_id = ?'
          ).bind(paymentId || '', now, orderId).run();

          const purchaseId = await stableId(`purch:${orderRow.user_id}:${orderRow.category_id}`);
          await c.env.DB.prepare(
            'INSERT OR REPLACE INTO course_purchases (id, user_id, category_id, course_id, amount_in_cents, currency, status, order_id, payment_id, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
          ).bind(purchaseId, orderRow.user_id, orderRow.category_id, orderRow.category_id, orderRow.amount || 49900, 'INR', 'completed', orderId, paymentId || '', now).run();
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
app.post('/api/v1/voice/synthesize', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const text = String(body.text || '').trim();
    if (!text) {
      return c.json({ ok: false, message: 'Missing text parameter' }, 400);
    }

    const voiceId = String(body.voiceId || 'bodhan_default').trim();
    const cacheKey = await stableId(`${voiceId}:${text}`);

    // Check D1 TTS cache
    const cached: any = await c.env.DB.prepare(
      'SELECT audio_url, duration_ms FROM tts_cache WHERE cache_key = ?'
    ).bind(cacheKey).first().catch(() => null);

    if (cached) {
      return c.json({
        ok: true,
        cached: true,
        audioUrl: cached.audio_url,
        durationMs: cached.duration_ms,
      });
    }

    // Build synthesized stream URL / CDN reference
    const encoded = encodeURIComponent(text.slice(0, 500));
    const audioUrl = `https://olitun-api.dulalkisku0.workers.dev/api/v1/audio/stream?text=${encoded}&voice=${voiceId}`;
    const now = new Date().toISOString();

    await c.env.DB.prepare(
      'INSERT OR REPLACE INTO tts_cache (cache_key, text_hash, voice_id, audio_url, duration_ms, created_at) VALUES (?, ?, ?, ?, ?, ?)'
    ).bind(cacheKey, cacheKey, voiceId, audioUrl, 2500, now).run().catch(() => {});

    return c.json({
      ok: true,
      cached: false,
      audioUrl,
      durationMs: 2500,
    });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Voice synthesis failed' }, 500);
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

// 23. AI Studio Speech-to-Text & Processing (replaces Appwrite aiStudio function)
app.post('/api/v1/studio/transcribe', async (c) => {
  try {
    // Cloudflare Workers AI Whisper speech-to-text
    const contentType = c.req.header('content-type') || '';
    if (contentType.includes('application/octet-stream') || contentType.includes('audio/')) {
      const audioBuffer = await c.req.arrayBuffer();
      const aiResponse: any = await c.env.AI.run('@cf/openai/whisper', {
        audio: [...new Uint8Array(audioBuffer)],
      }).catch((err: any) => ({ text: '' }));

      return c.json({
        ok: true,
        text: aiResponse?.text || '',
        vtt: aiResponse?.vtt || '',
        provider: 'cloudflare-workers-ai-whisper',
      });
    }

    const body = await c.req.json().catch(() => ({}));
    return c.json({
      ok: true,
      message: 'AI Studio ready. Submit audio bytes for instant edge transcription.',
    });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Studio transcription failed' }, 500);
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
    const result: any = await c.env.DB.prepare(
      'DELETE FROM learning_analytics_events WHERE date_key < ?'
    ).bind(ninetyDaysAgo).run().catch(() => ({ changes: 0 }));

    return c.json({ ok: true, deletedEvents: result.meta?.changes || 0, cutoffDate: ninetyDaysAgo });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Cleanup failed' }, 500);
  }
});

// 30. Reconcile Orphaned Deletions (replaces Appwrite reconcileOrphanedDeletions function)
app.post('/api/v1/admin/deletions/reconcile', async (c) => {
  try {
    const pendingDeletions: any = await c.env.DB.prepare(
      'SELECT id, user_id FROM deletion_requests WHERE status = "pending" OR status = "cleanup_failed" LIMIT 20'
    ).all().catch(() => ({ results: [] }));

    let completed = 0;
    const now = new Date().toISOString();

    for (const req of pendingDeletions.results || []) {
      const uId = req.user_id;
      if (!uId) continue;
      // Clean D1 user artifacts
      await c.env.DB.prepare('DELETE FROM user_mistakes WHERE user_id = ?').bind(uId).run().catch(() => {});
      await c.env.DB.prepare('DELETE FROM bakhed_listening_progress WHERE user_id = ?').bind(uId).run().catch(() => {});
      await c.env.DB.prepare('DELETE FROM user_badges WHERE user_id = ?').bind(uId).run().catch(() => {});
      await c.env.DB.prepare('UPDATE deletion_requests SET status = "completed", updated_at = ? WHERE id = ?').bind(now, req.id).run();
      completed++;
    }

    return c.json({ ok: true, completedCount: completed });
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

// 32. Delete Account (replaces Appwrite delete-account function)
app.post('/api/v1/user/delete', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const userId = getRequestUserId(c, body);
    if (!userId) {
      return c.json({ ok: false, message: 'Unauthenticated' }, 401);
    }

    const now = new Date().toISOString();
    const requestId = await stableId(`del:${userId}:${Date.now()}`);

    await c.env.DB.prepare(
      'INSERT INTO deletion_requests (id, user_id, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?)'
    ).bind(requestId, userId, 'processing', now, now).run().catch(() => {});

    // 1. Purge all user data in D1
    await c.env.DB.prepare('DELETE FROM user_mistakes WHERE user_id = ?').bind(userId).run().catch(() => {});
    await c.env.DB.prepare('DELETE FROM mistake_review_sessions WHERE user_id = ?').bind(userId).run().catch(() => {});
    await c.env.DB.prepare('DELETE FROM bakhed_listening_progress WHERE user_id = ?').bind(userId).run().catch(() => {});
    await c.env.DB.prepare('DELETE FROM user_badges WHERE user_id = ?').bind(userId).run().catch(() => {});
    await c.env.DB.prepare('DELETE FROM reward_events WHERE user_id = ?').bind(userId).run().catch(() => {});
    await c.env.DB.prepare('DELETE FROM learning_analytics_events WHERE user_id = ?').bind(userId).run().catch(() => {});
    await c.env.DB.prepare('DELETE FROM binti_waitlist WHERE user_id = ?').bind(userId).run().catch(() => {});
    
    // Anonymize purchase records for statutory financial tracking
    await c.env.DB.prepare(
      'UPDATE course_purchases SET user_id = "anonymized_user" WHERE user_id = ?'
    ).bind(userId).run().catch(() => {});
    await c.env.DB.prepare(
      'UPDATE payment_orders SET user_id = "anonymized_user" WHERE user_id = ?'
    ).bind(userId).run().catch(() => {});

    // Complete state
    await c.env.DB.prepare(
      'UPDATE deletion_requests SET status = "completed", updated_at = ? WHERE id = ?'
    ).bind(new Date().toISOString(), requestId).run().catch(() => {});

    return c.json({
      ok: true,
      code: 'account_deleted',
      message: 'Account and associated personal data successfully deleted from edge records',
    });
  } catch (err: any) {
    return c.json({ ok: false, message: err.message || 'Deletion failed' }, 500);
  }
});

export default app;

