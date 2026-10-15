import { getRequestUserId, type App } from '../env';
import { issuePaidMediaLease } from './paid_media';

export function registerLessonAuthorizeRoutes(app: App): void {
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
        // A category's learning path must contain only that category's
        // lessons; mixing in others made its first lesson look locked.
        const categoryId = String(body.categoryId || c.req.query('categoryId') || '').trim();
        const columns = 'id, category_id, title_ol_chiki, title_latin, lesson_type, order_index, raw_json';
        const lessonsQuery = categoryId
          ? c.env.DB.prepare(`SELECT ${columns} FROM lessons WHERE category_id = ? ORDER BY order_index ASC`).bind(categoryId)
          : c.env.DB.prepare(`SELECT ${columns} FROM lessons ORDER BY order_index ASC`);
        const lessonsResult: any = await lessonsQuery.all().catch(() => ({ results: [] }));

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
}
