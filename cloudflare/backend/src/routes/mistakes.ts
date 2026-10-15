import { getRequestUserId, stableId, type App } from '../env';

export function registerMistakeRoutes(app: App): void {
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
}
