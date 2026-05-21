import { createHash } from 'crypto';
import { Client, Databases, Query, ID, Users } from 'node-appwrite';

const TARGET_CIRCLE_SIZE = 20;
const DEFAULT_TEMPLATE = {
  templateId: 'starter-circle',
  name: 'Starter Circle',
  theme: 'leaf',
  icon: '🌱'
};
const AVATAR_EMOJIS = ['🌿', '🔥', '⭐', '🌊', '🌞', '🌳', '🌸', '🏆'];

function jsonBody(req) {
  try {
    return JSON.parse(req.body || '{}');
  } catch (_) {
    return {};
  }
}

function authenticatedUserId(req) {
  return req.headers['x-appwrite-user-id'];
}

function stableId(value) {
  return createHash('sha256').update(value).digest('hex').slice(0, 32);
}

function currentWeekId(now = new Date()) {
  const date = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const day = date.getUTCDay() || 7;
  date.setUTCDate(date.getUTCDate() + 4 - day);
  const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
  const week = Math.ceil((((date - yearStart) / 86400000) + 1) / 7);
  return `${date.getUTCFullYear()}-W${String(week).padStart(2, '0')}`;
}

function weekWindow(now = new Date()) {
  const start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const day = start.getUTCDay() || 7;
  start.setUTCDate(start.getUTCDate() - day + 1);
  start.setUTCHours(0, 0, 0, 0);
  const end = new Date(start);
  end.setUTCDate(start.getUTCDate() + 7);
  return { startsAt: start.toISOString(), endsAt: end.toISOString() };
}

function normalizeLevel(value) {
  const raw = String(value || 'beginner').toLowerCase();
  if (raw.includes('master')) return 'master';
  if (raw.includes('advanced')) return 'advanced';
  if (raw.includes('intermediate')) return 'intermediate';
  return 'beginner';
}

function deriveLearnerLevel(prefs = {}) {
  try {
    const progress = JSON.parse(prefs.user_progress_data || '{}');
    const completedLessons = Array.isArray(progress.completedLessons)
      ? progress.completedLessons.length
      : 0;
    const mastery = progress.categoryMastery && typeof progress.categoryMastery === 'object'
      ? Object.values(progress.categoryMastery)
      : [];
    const averageMastery = mastery.length
      ? mastery.reduce((sum, value) => sum + Number(value || 0), 0) / mastery.length
      : 0;

    if (averageMastery >= 75 && completedLessons >= 20) return 'master';
    if (averageMastery >= 50 && completedLessons >= 10) return 'advanced';
    if (averageMastery >= 20 && completedLessons >= 3) return 'intermediate';
  } catch (_) {
    // Fall through to safe default.
  }
  return 'beginner';
}

function normalizeScriptMode(value) {
  const raw = String(value || 'latin').toLowerCase();
  if (raw === 'olchiki' || raw === 'ol_chiki') return 'olchiki';
  if (raw === 'both') return 'both';
  return 'latin';
}

function deriveActivityTier(prefs = {}) {
  try {
    const progress = JSON.parse(prefs.user_progress_data || '{}');
    const stars = Number(progress.totalStars || 0);
    const lessons = Array.isArray(progress.completedLessons)
      ? progress.completedLessons.length
      : 0;
    if (stars >= 500 || lessons >= 20) return 'high';
    if (stars >= 100 || lessons >= 5) return 'medium';
  } catch (_) {
    // Fall through to safe default.
  }
  return 'low';
}

function publicMember(member, userId) {
  return {
    circleId: member.circleId,
    weekId: member.weekId,
    displayName: member.userId === userId ? 'You' : (member.displayName || member.anonymousName || 'Learner'),
    anonymousName: member.anonymousName || 'Learner',
    avatarEmoji: member.avatarEmoji || '🌿',
    learnerLevel: member.learnerLevel || 'beginner',
    circlePoints: member.circlePoints || 0,
    starsThisWeek: member.starsThisWeek || 0,
    lessonsCompleted: member.lessonsCompleted || 0,
    quizzesTaken: member.quizzesTaken || 0,
    bakhedListened: member.bakhedListened || 0,
    missionDaysCompleted: member.missionDaysCompleted || 0,
    mistakeReviewsCompleted: member.mistakeReviewsCompleted || 0,
    rank: member.rank || 0,
    joinedAt: member.joinedAt,
    lastActiveAt: member.lastActiveAt,
    isCurrentUser: member.userId === userId
  };
}

async function getPublishedTemplate(databases, databaseId, learnerLevel) {
  try {
    const result = await databases.listDocuments(
      databaseId,
      'learning_circle_templates',
      [
        Query.equal('status', 'published'),
        Query.equal('isActive', true),
        Query.equal('learnerLevel', learnerLevel)
      ]
    );
    if (result.total > 0) {
      const sorted = result.documents.sort((a, b) => (a.sortOrder || 0) - (b.sortOrder || 0));
      return sorted[0];
    }
  } catch (_) {
    // Collection may not exist yet during rollout; use safe fallback.
  }
  return DEFAULT_TEMPLATE;
}

async function findOpenCircle(databases, databaseId, weekId, learnerLevel, activityTier, scriptMode) {
  const result = await databases.listDocuments(
    databaseId,
    'weekly_circles',
    [
      Query.equal('weekId', weekId),
      Query.equal('status', 'open')
    ]
  );

  return result.documents
    .filter((circle) =>
      (circle.memberCount || 0) < (circle.maxMembers || TARGET_CIRCLE_SIZE) &&
      normalizeLevel(circle.learnerLevel) === learnerLevel &&
      String(circle.activityTier || activityTier) === activityTier &&
      normalizeScriptMode(circle.scriptMode) === scriptMode
    )
    .sort((a, b) => (b.memberCount || 0) - (a.memberCount || 0))[0];
}

async function createCircle(databases, databaseId, weekId, learnerLevel, activityTier, scriptMode, template) {
  const now = new Date();
  const window = weekWindow(now);
  const created = await databases.createDocument(
    databaseId,
    'weekly_circles',
    ID.unique(),
    {
      circleId: '',
      weekId,
      circleName: template.name || DEFAULT_TEMPLATE.name,
      circleTemplateId: template.templateId || template.$id || DEFAULT_TEMPLATE.templateId,
      learnerLevel,
      activityTier,
      scriptMode,
      theme: template.theme || DEFAULT_TEMPLATE.theme,
      icon: template.icon || DEFAULT_TEMPLATE.icon,
      memberCount: 0,
      targetMembers: TARGET_CIRCLE_SIZE,
      maxMembers: TARGET_CIRCLE_SIZE,
      status: 'open',
      createdAt: now.toISOString(),
      startsAt: window.startsAt,
      endsAt: window.endsAt
    }
  );

  return databases.updateDocument(databaseId, 'weekly_circles', created.$id, {
    circleId: created.$id
  });
}

async function joinCircle(databases, databaseId, circle, userId, profile) {
  const now = new Date();
  const memberId = stableId(`${userId}:${profile.weekId}`);
  const avatarEmoji = AVATAR_EMOJIS[parseInt(stableId(userId).slice(0, 2), 16) % AVATAR_EMOJIS.length];
  const anonymousName = `Learner ${stableId(userId).slice(0, 4).toUpperCase()}`;

  let memberDoc;
  try {
    memberDoc = await databases.createDocument(
      databaseId,
      'circle_members',
      memberId,
      {
        circleId: circle.circleId || circle.$id,
        userId,
        weekId: profile.weekId,
        displayName: profile.displayName || anonymousName,
        anonymousName,
        avatarEmoji,
        learnerLevel: profile.learnerLevel,
        circlePoints: 0,
        starsThisWeek: 0,
        lessonsCompleted: 0,
        quizzesTaken: 0,
        bakhedListened: 0,
        missionDaysCompleted: 0,
        mistakeReviewsCompleted: 0,
        rank: (circle.memberCount || 0) + 1,
        joinedAt: now.toISOString(),
        lastActiveAt: now.toISOString()
      }
    );
  } catch (err) {
    if (err.code === 409) {
      const existing = await databases.getDocument(databaseId, 'circle_members', memberId);
      return { circle, member: existing };
    }
    throw err;
  }

  const members = await databases.listDocuments(
    databaseId,
    'circle_members',
    [
      Query.equal('circleId', circle.circleId || circle.$id),
      Query.equal('weekId', profile.weekId)
    ]
  );
  const actualMemberCount = members.total;

  if (actualMemberCount > (circle.maxMembers || TARGET_CIRCLE_SIZE)) {
    await databases.deleteDocument(databaseId, 'circle_members', memberDoc.$id);
    await databases.updateDocument(databaseId, 'weekly_circles', circle.$id, {
      memberCount: actualMemberCount - 1,
      status: 'full'
    });
    return null;
  }

  const updatedCircle = await databases.updateDocument(
    databaseId,
    'weekly_circles',
    circle.$id,
    {
      memberCount: actualMemberCount,
      status: actualMemberCount >= (circle.maxMembers || TARGET_CIRCLE_SIZE) ? 'full' : 'open'
    }
  );

  return { circle: updatedCircle, member: memberDoc };
}

export default async ({ req, res, log, error }) => {
  if (req.method !== 'POST') {
    return res.json({ ok: false, message: 'Method not allowed' }, 405);
  }

  jsonBody(req);
  const userId = authenticatedUserId(req);
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
  const users = new Users(client);
  const databaseId = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
  const weekId = currentWeekId();

  try {
    const memberId = stableId(`${userId}:${weekId}`);
    try {
      const existingMember = await databases.getDocument(databaseId, 'circle_members', memberId);
      const circle = await databases.getDocument(databaseId, 'weekly_circles', existingMember.circleId);
      return res.json({
        ok: true,
        circle,
        member: publicMember(existingMember, userId)
      });
    } catch (_) {
      // Not assigned yet.
    }

    let displayName = '';
    let prefs = {};
    try {
      const user = await users.get(userId);
      displayName = user.name || '';
      prefs = user.prefs || {};
    } catch (_) {
      // Keep privacy-safe anonymous fallback.
    }

    const learnerLevel = deriveLearnerLevel(prefs);
    const activityTier = deriveActivityTier(prefs);
    const scriptMode = normalizeScriptMode(prefs.script_mode);
    const profile = { weekId, displayName, learnerLevel, activityTier, scriptMode };

    for (let attempt = 0; attempt < 3; attempt++) {
      let circle = await findOpenCircle(
        databases,
        databaseId,
        weekId,
        learnerLevel,
        activityTier,
        scriptMode
      );

      if (!circle) {
        const template = await getPublishedTemplate(databases, databaseId, learnerLevel);
        circle = await createCircle(
          databases,
          databaseId,
          weekId,
          learnerLevel,
          activityTier,
          scriptMode,
          template
        );
      }

      const joined = await joinCircle(databases, databaseId, circle, userId, profile);
      if (joined) {
        return res.json({
          ok: true,
          circle: joined.circle,
          member: publicMember(joined.member, userId)
        });
      }
    }

    return res.json({ ok: false, message: 'Could not assign circle safely' }, 409);
  } catch (err) {
    error('assignUserToWeeklyCircle error: ' + err.message);
    return res.json({ ok: false, message: err.message }, 500);
  }
};
