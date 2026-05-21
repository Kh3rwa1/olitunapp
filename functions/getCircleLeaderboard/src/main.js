import { createHash } from 'crypto';
import { Client, Databases, Query } from 'node-appwrite';

const MIN_REAL_MEMBERS_BEFORE_LEADERBOARD = 8;

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

function publicMember(member, userId, rank) {
  const isCurrentUser = member.userId === userId;
  return {
    circleId: member.circleId,
    weekId: member.weekId,
    displayName: isCurrentUser ? 'You' : (member.displayName || member.anonymousName || 'Learner'),
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
    rank,
    joinedAt: member.joinedAt,
    lastActiveAt: member.lastActiveAt,
    isCurrentUser,
    isBenchmark: false
  };
}

function benchmarkRows(circle, weekId) {
  const now = new Date().toISOString();
  return [
    {
      circleId: circle.circleId || circle.$id,
      weekId,
      displayName: 'Weekly Target',
      anonymousName: 'Weekly Target',
      avatarEmoji: '🏆',
      learnerLevel: circle.learnerLevel || 'beginner',
      circlePoints: 500,
      starsThisWeek: 0,
      lessonsCompleted: 4,
      quizzesTaken: 2,
      bakhedListened: 1,
      missionDaysCompleted: 3,
      mistakeReviewsCompleted: 1,
      joinedAt: now,
      lastActiveAt: now,
      isCurrentUser: false,
      isBenchmark: true
    },
    {
      circleId: circle.circleId || circle.$id,
      weekId,
      displayName: 'Average Learner',
      anonymousName: 'Average Learner',
      avatarEmoji: '🌿',
      learnerLevel: circle.learnerLevel || 'beginner',
      circlePoints: 260,
      starsThisWeek: 0,
      lessonsCompleted: 2,
      quizzesTaken: 1,
      bakhedListened: 0,
      missionDaysCompleted: 1,
      mistakeReviewsCompleted: 0,
      joinedAt: now,
      lastActiveAt: now,
      isCurrentUser: false,
      isBenchmark: true
    },
    {
      circleId: circle.circleId || circle.$id,
      weekId,
      displayName: 'Starter Goal',
      anonymousName: 'Starter Goal',
      avatarEmoji: '🌱',
      learnerLevel: circle.learnerLevel || 'beginner',
      circlePoints: 150,
      starsThisWeek: 0,
      lessonsCompleted: 1,
      quizzesTaken: 0,
      bakhedListened: 0,
      missionDaysCompleted: 1,
      mistakeReviewsCompleted: 0,
      joinedAt: now,
      lastActiveAt: now,
      isCurrentUser: false,
      isBenchmark: true
    }
  ];
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
  const databaseId = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
  const weekId = currentWeekId();

  try {
    const memberId = stableId(`${userId}:${weekId}`);
    let currentUserMember;
    try {
      currentUserMember = await databases.getDocument(databaseId, 'circle_members', memberId);
    } catch (_) {
      return res.json({ ok: false, message: 'User is not in a circle for this week' }, 404);
    }

    const circleId = currentUserMember.circleId;
    const circle = await databases.getDocument(databaseId, 'weekly_circles', circleId);

    const allMembersResult = await databases.listDocuments(
      databaseId,
      'circle_members',
      [
        Query.equal('circleId', circleId),
        Query.equal('weekId', weekId)
      ]
    );

    const realMembers = sortMembers(allMembersResult.documents);
    const publicRealMembers = realMembers.map((member, index) => publicMember(member, userId, index + 1));
    const isStarterCircle = realMembers.length < MIN_REAL_MEMBERS_BEFORE_LEADERBOARD;

    let leaderboard = publicRealMembers;
    if (isStarterCircle) {
      leaderboard = sortMembers([
        ...publicRealMembers,
        ...benchmarkRows(circle, weekId)
      ]).map((member, index) => ({ ...member, rank: index + 1 }));
    }

    const currentPublicMember = leaderboard.find((member) => member.isCurrentUser) ||
      publicMember(currentUserMember, userId, 1);
    const userRank = currentPublicMember.rank || 1;
    const previousMember = leaderboard[userRank - 2];
    const pointsToNextRank = previousMember
      ? Math.max(0, (previousMember.circlePoints || 0) - (currentPublicMember.circlePoints || 0))
      : 0;

    return res.json({
      ok: true,
      circle,
      currentUserMember: currentPublicMember,
      leaderboard,
      pointsToNextRank,
      rank: userRank,
      totalMembers: realMembers.length,
      realMemberCount: realMembers.length,
      minRealMembersBeforeLeaderboard: MIN_REAL_MEMBERS_BEFORE_LEADERBOARD,
      isStarterCircle,
      starterCircleMessage: isStarterCircle
        ? 'You’re warming up while more learners join.'
        : '',
      endsAt: circle.endsAt
    });
  } catch (err) {
    error('getCircleLeaderboard error: ' + err.message);
    return res.json({ ok: false, message: err.message }, 500);
  }
};
