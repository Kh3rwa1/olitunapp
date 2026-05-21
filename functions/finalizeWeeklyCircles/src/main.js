import { createHash } from 'crypto';
import { Client, Databases, Query, Users, ID } from 'node-appwrite';

function stableId(value) {
  return createHash('sha256').update(value).digest('hex').slice(0, 32);
}

function sortMembers(members) {
  return [...members].sort((a, b) => {
    if ((b.circlePoints || 0) !== (a.circlePoints || 0)) {
      return (b.circlePoints || 0) - (a.circlePoints || 0);
    }
    if ((b.missionDaysCompleted || 0) !== (a.missionDaysCompleted || 0)) {
      return (b.missionDaysCompleted || 0) - (a.missionDaysCompleted || 0);
    }
    if ((b.quizzesTaken || 0) !== (a.quizzesTaken || 0)) {
      return (b.quizzesTaken || 0) - (a.quizzesTaken || 0);
    }
    return new Date(a.joinedAt || 0) - new Date(b.joinedAt || 0);
  });
}

async function createAuditLog(databases, databaseId, action, targetType, targetId, metadata = {}) {
  try {
    await databases.createDocument(databaseId, 'admin_audit_logs', ID.unique(), {
      actorUserId: 'system',
      action,
      targetType,
      targetId,
      metadata: JSON.stringify(metadata),
      success: true,
      createdAt: new Date().toISOString()
    });
  } catch (_) {
    // Audit logging should not block finalization retries.
  }
}

async function createRewardEvent(databases, databaseId, member, sourceId, starsAwarded, badgeId, reason) {
  if (starsAwarded <= 0 && !badgeId) return;
  const rewardEventId = stableId(`${member.userId}:${sourceId}:${badgeId || 'stars'}:${starsAwarded}`);
  try {
    await databases.createDocument(databaseId, 'reward_events', rewardEventId, {
      rewardEventId,
      userId: member.userId,
      sourceType: 'weekly_circle',
      sourceId,
      starsAwarded,
      badgeId: badgeId || '',
      reason,
      createdAt: new Date().toISOString()
    });
  } catch (err) {
    if (err.code !== 409) throw err;
  }
}

async function upsertBadgeProgress(databases, databaseId, userId, badgeId, target = 1) {
  if (!badgeId) return null;
  const docId = stableId(`${userId}:${badgeId}`);
  const now = new Date().toISOString();

  try {
    const existing = await databases.getDocument(databaseId, 'user_badges', docId);
    const progress = (existing.progress || 0) + 1;
    const resolvedTarget = existing.target || target;
    const isUnlocked = progress >= resolvedTarget;
    return databases.updateDocument(databaseId, 'user_badges', docId, {
      progress,
      target: resolvedTarget,
      isUnlocked,
      unlockedAt: isUnlocked && !existing.isUnlocked ? now : existing.unlockedAt,
      updatedAt: now
    });
  } catch (_) {
    const isUnlocked = target <= 1;
    return databases.createDocument(databaseId, 'user_badges', docId, {
      userId,
      badgeId,
      progress: 1,
      target,
      isUnlocked,
      unlockedAt: isUnlocked ? now : '',
      updatedAt: now
    });
  }
}

async function activeDayCount(databases, databaseId, circleId, userId, weekId) {
  try {
    const result = await databases.listDocuments(databaseId, 'circle_events', [
      Query.equal('circleId', circleId),
      Query.equal('userId', userId),
      Query.equal('weekId', weekId),
      Query.limit(100)
    ]);
    const days = new Set(
      result.documents
        .map((event) => event.dateKey || String(event.createdAt || '').slice(0, 10))
        .filter(Boolean)
    );
    return days.size;
  } catch (_) {
    return 0;
  }
}

async function createRecap(databases, databaseId, circle, member, rank, totalMembers, starsAwarded, badgesAwarded) {
  const recapId = stableId(`${member.userId}:${circle.weekId}`);
  const summary = rank === 1
    ? 'You led your circle with steady practice.'
    : 'Your weekly practice was counted. Come back tomorrow for the next step.';
  const payload = {
    recapId,
    circleId: circle.circleId || circle.$id,
    userId: member.userId,
    weekId: circle.weekId,
    rank,
    totalMembers,
    circlePoints: member.circlePoints || 0,
    starsAwarded,
    badgesAwarded: JSON.stringify(badgesAwarded),
    summary,
    createdAt: new Date().toISOString()
  };

  try {
    await databases.createDocument(databaseId, 'weekly_circle_recaps', recapId, payload);
  } catch (err) {
    if (err.code === 409) {
      await databases.updateDocument(databaseId, 'weekly_circle_recaps', recapId, payload);
      return;
    }
    throw err;
  }
}

export default async ({ req, res, log, error }) => {
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
  const users = new Users(client);
  const databaseId = process.env.APPWRITE_DATABASE_ID || 'olitun_db';

  try {
    const now = new Date();
    const endedCirclesResult = await databases.listDocuments(
      databaseId,
      'weekly_circles',
      [
        Query.lessThan('endsAt', now.toISOString()),
        Query.equal('status', ['open', 'full', 'locked'])
      ]
    );

    log(`Found ${endedCirclesResult.total} circles to finalize`);

    for (const circle of endedCirclesResult.documents) {
      const circleId = circle.circleId || circle.$id;
      log(`Finalizing circle ${circleId}`);
      await databases.updateDocument(databaseId, 'weekly_circles', circle.$id, {
        status: 'locked'
      });

      const membersResult = await databases.listDocuments(
        databaseId,
        'circle_members',
        [
          Query.equal('circleId', circleId),
          Query.equal('weekId', circle.weekId),
          Query.limit(100)
        ]
      );

      const members = sortMembers(membersResult.documents);

      for (let i = 0; i < members.length; i++) {
        const member = members[i];
        const rank = i + 1;
        let starsAwarded = 0;
        const badgesAwarded = [];

        if (rank === 1) {
          starsAwarded = 100;
          badgesAwarded.push('circle_champion');
        } else if (rank <= 3) {
          starsAwarded = 50;
          badgesAwarded.push('top_3_learner');
        } else if (rank <= 5) {
          starsAwarded = 25;
          badgesAwarded.push('weekly_climber');
        }

        const daysActive = await activeDayCount(
          databases,
          databaseId,
          circleId,
          member.userId,
          circle.weekId
        );
        if (daysActive >= 3) badgesAwarded.push('consistency');
        if (daysActive >= 7) badgesAwarded.push('perfect_week');

        await databases.updateDocument(databaseId, 'circle_members', member.$id, {
          rank,
          starsThisWeek: starsAwarded
        });

        for (const badgeId of badgesAwarded) {
          await upsertBadgeProgress(databases, databaseId, member.userId, badgeId);
        }

        await createRewardEvent(
          databases,
          databaseId,
          member,
          `${circleId}:${circle.weekId}`,
          starsAwarded,
          badgesAwarded[0] || '',
          `Weekly circle rank ${rank}`
        );

        await createRecap(
          databases,
          databaseId,
          circle,
          member,
          rank,
          members.length,
          starsAwarded,
          badgesAwarded
        );

        if (starsAwarded > 0) {
          try {
            const user = await users.get(member.userId);
            const prefs = user.prefs || {};
            let progressData = {};
            try {
              progressData = JSON.parse(prefs.user_progress_data || '{}');
            } catch (_) {
              progressData = {};
            }
            progressData.totalStars = (progressData.totalStars || 0) + starsAwarded;
            prefs.user_progress_data = JSON.stringify(progressData);
            await users.updatePrefs(member.userId, prefs);
          } catch (e) {
            log(`Failed to update preferences for user ${member.userId}: ${e.message}`);
          }
        }
      }

      await databases.updateDocument(databaseId, 'weekly_circles', circle.$id, {
        status: 'closed',
        memberCount: members.length
      });
      await createAuditLog(databases, databaseId, 'circle_finalized', 'weekly_circles', circleId, {
        weekId: circle.weekId,
        memberCount: members.length
      });
      log(`Circle ${circleId} finalized successfully`);
    }

    return res.json({ ok: true, finalizedCirclesCount: endedCirclesResult.total });
  } catch (err) {
    error('finalizeWeeklyCircles error: ' + err.message);
    return res.json({ ok: false, message: err.message }, 500);
  }
};
