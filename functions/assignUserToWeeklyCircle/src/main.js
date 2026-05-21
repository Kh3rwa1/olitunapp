import { Client, Databases, Query, ID, Users } from 'node-appwrite';

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
    // 1. Check if user is already a member of a circle in this week
    const memberQueryResult = await databases.listDocuments(
      databaseId,
      'circle_members',
      [
        Query.equal('userId', userId),
        Query.equal('weekId', weekId)
      ]
    );

    if (memberQueryResult.total > 0) {
      const existingMember = memberQueryResult.documents[0];
      const circleId = existingMember.circleId;
      const circle = await databases.getDocument(databaseId, 'weekly_circles', circleId);
      return res.json({
        ok: true,
        circle: circle,
        member: existingMember
      });
    }

    // 2. Find open circles for this week
    const openCirclesResult = await databases.listDocuments(
      databaseId,
      'weekly_circles',
      [
        Query.equal('weekId', weekId),
        Query.equal('status', 'open'),
        Query.orderDesc('memberCount')
      ]
    );

    let selectedCircle;
    if (openCirclesResult.total > 0) {
      selectedCircle = openCirclesResult.documents[0];
    }

    const now = new Date();
    // If no open circle, create one
    if (!selectedCircle) {
      const weekStart = new Date();
      // compute Monday
      const day = weekStart.getDay();
      const diff = weekStart.getDate() - day + (day === 0 ? -6 : 1);
      weekStart.setDate(diff);
      weekStart.setHours(0,0,0,0);
      const weekEnd = new Date(weekStart);
      weekEnd.setDate(weekStart.getDate() + 7);

      selectedCircle = await databases.createDocument(
        databaseId,
        'weekly_circles',
        ID.unique(),
        {
          circleId: '', // Will be updated to match the document ID
          weekId: weekId,
          learnerLevel: 'beginner', // default level, updated as needed
          activityTier: 'medium',
          scriptMode: 'latin',
          memberCount: 0,
          targetMembers: 20,
          maxMembers: 20,
          status: 'open',
          createdAt: now.toISOString(),
          startsAt: weekStart.toISOString(),
          endsAt: weekEnd.toISOString()
        }
      );
      // update circleId same as documentId
      selectedCircle = await databases.updateDocument(
        databaseId,
        'weekly_circles',
        selectedCircle.$id,
        { circleId: selectedCircle.$id }
      );
    }

    // 3. Add user to the circle
    const avatarEmojis = ['🦚', '🌿', '🔥', '⭐', '🌊', '🌞', '🦅', '🦌', '🌳', '🌸'];
    const randomEmoji = avatarEmojis[Math.floor(Math.random() * avatarEmojis.length)];
    const anonymousName = `Learner_${Math.floor(1000 + Math.random() * 9000)}`;

    let displayName = anonymousName;
    try {
      // Look up displayName from the Appwrite user account record
      const users = new Users(client);
      const user = await users.get(userId);
      displayName = user.name || anonymousName;
    } catch (e) {
      // If user lookup fails, fall back to anonymousName
    }

    const memberDoc = await databases.createDocument(
      databaseId,
      'circle_members',
      ID.unique(),
      {
        circleId: selectedCircle.circleId,
        userId: userId,
        weekId: weekId,
        displayName: displayName,
        anonymousName: anonymousName,
        avatarEmoji: randomEmoji,
        learnerLevel: selectedCircle.learnerLevel,
        circlePoints: 0,
        starsThisWeek: 0,
        lessonsCompleted: 0,
        quizzesTaken: 0,
        bakhedListened: 0,
        missionDaysCompleted: 0,
        mistakeReviewsCompleted: 0,
        rank: selectedCircle.memberCount + 1,
        joinedAt: now.toISOString(),
        lastActiveAt: now.toISOString()
      }
    );

    // 4. Update memberCount of the circle
    const newMemberCount = selectedCircle.memberCount + 1;
    const isFull = newMemberCount >= selectedCircle.maxMembers;
    const updatedCircle = await databases.updateDocument(
      databaseId,
      'weekly_circles',
      selectedCircle.$id,
      {
        memberCount: newMemberCount,
        status: isFull ? 'full' : 'open'
      }
    );

    return res.json({
      ok: true,
      circle: updatedCircle,
      member: memberDoc
    });
  } catch (err) {
    error('assignUserToWeeklyCircle error: ' + err.message);
    return res.json({ ok: false, message: err.message }, 500);
  }
};
