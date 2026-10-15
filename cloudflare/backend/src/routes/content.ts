import type { App } from '../env';
import { cachedJson } from '../lib/cache';
import { serveAsset } from './media';

export function registerContentRoutes(app: App): void {
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
      // This list is public and cached, so paid lessons are listed without
      // their content; /lessons/authorize serves bodies after an entitlement
      // check.
      const categories: any = await c.env.DB.prepare('SELECT id, unlock_mode FROM categories').all();
      const freeCategoryIds = new Set(
        (categories.results || [])
          .filter((cat: any) => !cat.unlock_mode || cat.unlock_mode === 'free')
          .map((cat: any) => cat.id),
      );
      const lessons = (result.results || []).map((r: any) => {
        const lesson = JSON.parse(r.raw_json);
        const categoryOf = lesson.categoryId || lesson.category;
        if (freeCategoryIds.has(categoryOf) || lesson.isPreview) return lesson;
        const { blocks: _b, data: _d, heroMediaUrl: _h, ...meta } = lesson;
        return { ...meta, blocks: [], isLocked: true };
      });
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
      return cachedJson(c, { ok: true, settings, documents });
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

  // 13. Assets stream from R2 (Range/HEAD, private prefixes blocked): routes/media.ts
  app.get('/api/v1/assets/*', serveAsset);
}
