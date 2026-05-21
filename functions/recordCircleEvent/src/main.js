import { Client, Databases, Query, ID } from 'node-appwrite';

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
  const eventType = body.eventType;
  const sourceId = body.sourceId;
  const metadata = body.metadata || {};

  if (!userId || !weekId || !eventType || !sourceId) {
    return res.json({ ok: false, message: 'Missing required parameters' }, 400);
  }

  // Scoring rules
  const scores = {
    lesson_completed: 40,
    quiz_completed: 25,
    quiz_high_score_90: 10,
    bakhed_completed_80_percent: 20,
    daily_mission_completed: 30,
    mistake_review_completed: 15,
    streak_maintained: 10,
    quick_win_completed: 10
  };

  const points = scores[eventType] || 0;

  try {
    // 1. Get member document to verify user is in a circle and to get current points
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

    const memberDoc = memberQueryResult.documents[0];
    const circleId = memberDoc.circleId;

    // 2. Prevent duplicate scoring
    // Lesson: once per week per lessonId
    // Others: once per day
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayEnd = new Date();
    todayEnd.setHours(23, 59, 59, 999);

    const duplicateQueries = [
      Query.equal('userId', userId),
      Query.equal('weekId', weekId),
      Query.equal('eventType', eventType),
      Query.equal('sourceId', sourceId)
    ];

    if (eventType !== 'lesson_completed') {
      duplicateQueries.push(Query.greaterThanEqual('createdAt', todayStart.toISOString()));
      duplicateQueries.push(Query.lessThanEqual('createdAt', todayEnd.toISOString()));
    }

    const duplicateCheck = await databases.listDocuments(
      databaseId,
      'circle_events',
      duplicateQueries
    );

    if (duplicateCheck.total > 0) {
      return res.json({ ok: true, message: 'Event already recorded, skipping points' });
    }

    // 3. Create Circle Event
    const now = new Date();
    await databases.createDocument(
      databaseId,
      'circle_events',
      ID.unique(),
      {
        circleId: circleId,
        userId: userId,
        weekId: weekId,
        eventType: eventType,
        sourceId: sourceId,
        points: points,
        metadata: JSON.stringify(metadata),
        createdAt: now.toISOString()
      }
    );

    // 4. Update member points and stats
    const updatePayload = {
      circlePoints: memberDoc.circlePoints + points,
      lastActiveAt: now.toISOString()
    };

    if (eventType === 'lesson_completed') {
      updatePayload.lessonsCompleted = memberDoc.lessonsCompleted + 1;
    } else if (eventType === 'quiz_completed') {
      updatePayload.quizzesTaken = memberDoc.quizzesTaken + 1;
    } else if (eventType === 'bakhed_completed_80_percent') {
      updatePayload.bakhedListened = memberDoc.bakhedListened + 1;
    } else if (eventType === 'daily_mission_completed') {
      updatePayload.missionDaysCompleted = memberDoc.missionDaysCompleted + 1;
    } else if (eventType === 'mistake_review_completed') {
      updatePayload.mistakeReviewsCompleted = memberDoc.mistakeReviewsCompleted + 1;
    }

    const updatedMember = await databases.updateDocument(
      databaseId,
      'circle_members',
      memberDoc.$id,
      updatePayload
    );

    return res.json({
      ok: true,
      pointsAwarded: points,
      currentPoints: updatedMember.circlePoints
    });
  } catch (err) {
    error('recordCircleEvent error: ' + err.message);
    return res.json({ ok: false, message: err.message }, 500);
  }
};
