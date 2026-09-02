import { Client, Databases, Query } from 'node-appwrite';

export default async ({ req, res, error }) => {
  if (req.method !== 'POST') {
    return res.json({ ok: false, message: 'Method not allowed' }, 405);
  }

  const userId = req.headers['x-appwrite-user-id'];
  if (!userId) {
    return res.json({ ok: false, message: 'Unauthenticated' }, 401);
  }

  const endpoint = process.env.APPWRITE_FUNCTION_API_ENDPOINT;
  const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID;
  const apiKey = process.env.APPWRITE_FUNCTION_API_KEY || process.env.APPWRITE_API_KEY;

  if (!endpoint || !projectId || !apiKey) {
    error('Missing environment variables');
    return res.json({ ok: false, message: 'Server misconfiguration' }, 500);
  }

  const client = new Client()
    .setEndpoint(endpoint)
    .setProject(projectId)
    .setKey(apiKey);
  const databases = new Databases(client);
  const databaseId = process.env.APPWRITE_DATABASE_ID || 'olitun_db';

  try {
    const [badgesResult, userBadgesResult, rewardsResult] =
      await Promise.all([
        databases.listDocuments(databaseId, 'badges', [
          Query.equal('status', 'published'),
          Query.equal('isActive', true),
          Query.orderAsc('sortOrder'),
          Query.limit(500)
        ]),
        databases.listDocuments(databaseId, 'user_badges', [
          Query.equal('userId', userId),
          Query.limit(500)
        ]),
        databases.listDocuments(databaseId, 'reward_events', [
          Query.equal('userId', userId),
          Query.limit(100)
        ])
      ]);

    const progressByBadge = new Map(
      userBadgesResult.documents.map((doc) => [doc.badgeId, doc])
    );

    const badges = badgesResult.documents.map((badge) => {
      const progress = progressByBadge.get(badge.badgeId) || {};
      const target = progress.target || badge.target || 1;
      return {
        badgeId: badge.badgeId,
        name: badge.name || 'Learning badge',
        description: badge.description || 'Keep learning to unlock this badge.',
        category: badge.category || 'learning',
        icon: badge.icon || '🏆',
        rewardStars: Math.max(0, Math.min(badge.rewardStars || 0, 100)),
        progress: progress.progress || 0,
        target,
        isUnlocked: progress.isUnlocked === true,
        unlockedAt: progress.unlockedAt || '',
        updatedAt: progress.updatedAt || ''
      };
    });

    const recentRewards = rewardsResult.documents
      .sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0))
      .slice(0, 20)
      .map((reward) => ({
        rewardEventId: reward.rewardEventId || reward.$id,
        sourceType: reward.sourceType || '',
        sourceId: reward.sourceId || '',
        starsAwarded: reward.starsAwarded || 0,
        badgeId: reward.badgeId || '',
        reason: reward.reason || '',
        createdAt: reward.createdAt || ''
      }));

    return res.json({ ok: true, badges, recentRewards });
  } catch (err) {
    error('getUserGamificationSummary error: ' + err.message);
    return res.json({ ok: false, message: 'Unable to load summary. Please try again.' }, 500);
  }
};
