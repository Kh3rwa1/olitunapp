import { Client, Databases, Query } from 'node-appwrite';

export default async ({ req, res, log, error }) => {
  if (req.method !== 'POST') {
    return res.json({ ok: false, message: 'Method not allowed' }, 405);
  }

  const endpoint = process.env.APPWRITE_FUNCTION_API_ENDPOINT;
  const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID;
  const apiKey = process.env.APPWRITE_API_KEY;

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

  let body = {};
  try {
    body = JSON.parse(req.body || '{}');
  } catch (e) {
    body = {};
  }

  const userId = body.userId || req.headers['x-appwrite-user-id'];
  const weekId = body.weekId;

  if (!userId || !weekId) {
    return res.json({ ok: false, message: 'Missing userId or weekId' }, 400);
  }

  try {
    // 1. Get current user's member document
    const memberQueryResult = await databases.listDocuments(
      databaseId,
      'circle_members',
      [
        Query.equal('userId', userId),
        Query.equal('weekId', weekId)
      ]
    );

    if (memberQueryResult.total === 0) {
      return res.json({ ok: false, message: 'User is not in a circle for this week' }, 404);
    }

    const currentUserMember = memberQueryResult.documents[0];
    const circleId = currentUserMember.circleId;

    // 2. Fetch all members in the same circle
    const allMembersResult = await databases.listDocuments(
      databaseId,
      'circle_members',
      [
        Query.equal('circleId', circleId),
        Query.equal('weekId', weekId)
      ]
    );

    const members = allMembersResult.documents;

    // 3. Sort by points desc, then details (following brief sort order)
    members.sort((a, b) => {
      if (b.circlePoints !== a.circlePoints) {
        return b.circlePoints - a.circlePoints;
      }
      if (b.missionDaysCompleted !== a.missionDaysCompleted) {
        return b.missionDaysCompleted - a.missionDaysCompleted;
      }
      if (b.quizzesTaken !== a.quizzesTaken) {
        return b.quizzesTaken - a.quizzesTaken;
      }
      return new Date(a.joinedAt) - new Date(b.joinedAt);
    });

    // 4. Update/assign ranks based on sorted list
    let userRank = 1;
    for (let i = 0; i < members.length; i++) {
      members[i].rank = i + 1;
      if (members[i].userId === userId) {
        userRank = i + 1;
      }
    }

    // 5. Calculate points needed to reach the next higher rank
    const pointsToNextRank = userRank > 1
      ? members[userRank - 2].circlePoints - currentUserMember.circlePoints
      : 0;

    const circle = await databases.getDocument(databaseId, 'weekly_circles', circleId);

    return res.json({
      ok: true,
      circle: circle,
      currentUserMember: currentUserMember,
      leaderboard: members,
      pointsToNextRank: pointsToNextRank,
      rank: userRank,
      totalMembers: members.length,
      endsAt: circle.endsAt
    });
  } catch (err) {
    error('getCircleLeaderboard error: ' + err.message);
    return res.json({ ok: false, message: err.message }, 500);
  }
};
