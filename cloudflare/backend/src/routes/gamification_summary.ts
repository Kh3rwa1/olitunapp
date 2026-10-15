import { getRequestUserId, type App } from '../env';

export function registerGamificationSummaryRoutes(app: App): void {
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
}
