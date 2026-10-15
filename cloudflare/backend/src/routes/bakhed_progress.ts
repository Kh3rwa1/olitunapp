import { getRequestUserId, stableId, type App } from '../env';

export function registerBakhedProgressRoutes(app: App): void {
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
}
