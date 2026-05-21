import { createHash } from 'crypto';
import { Client, Databases, Query } from 'node-appwrite';

const DEFAULT_SCORES = {
  lesson_completed: 40,
  quiz_completed: 25,
  quiz_high_score_90: 10,
  bakhed_completed_80_percent: 20,
  daily_mission_completed: 30,
  mistake_review_completed: 15,
  streak_maintained: 10,
  quick_win_completed: 10
};

const DAILY_EVENTS = new Set([
  'quiz_completed',
  'quiz_high_score_90',
  'bakhed_completed_80_percent',
  'daily_mission_completed',
  'mistake_review_completed',
  'streak_maintained',
  'quick_win_completed'
]);

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

function dateKey(now = new Date()) {
  return now.toISOString().slice(0, 10);
}

function dedupeScope(eventType, weekId, dayKey) {
  return eventType === 'lesson_completed' ? weekId : dayKey;
}

function integer(value) {
  return Number.isFinite(Number(value)) ? Number(value) : 0;
}

async function getGamificationConfig(databases, databaseId) {
  const fallback = {
    bakhedCompletionThreshold: 80,
    scores: DEFAULT_SCORES
  };

  try {
    const config = await databases.getDocument(databaseId, 'gamification_config', 'default');
    const threshold = integer(config.bakhedCompletionThreshold);
    return {
      bakhedCompletionThreshold: Math.min(95, Math.max(50, threshold || 80)),
      scores: DEFAULT_SCORES
    };
  } catch (_) {
    return fallback;
  }
}

function validateEvent(body, config) {
  const eventType = String(body.eventType || '').trim();
  const sourceId = String(body.sourceId || '').trim();
  const metadata = body.metadata && typeof body.metadata === 'object' && !Array.isArray(body.metadata)
    ? body.metadata
    : {};

  if (!Object.prototype.hasOwnProperty.call(DEFAULT_SCORES, eventType)) {
    return { ok: false, message: 'Unsupported circle event type' };
  }

  if (!sourceId || sourceId.length > 100) {
    return { ok: false, message: 'Missing or invalid sourceId' };
  }

  if (eventType === 'bakhed_completed_80_percent') {
    const listenedPercent = integer(metadata.listenedPercent);
    if (listenedPercent < config.bakhedCompletionThreshold) {
      return {
        ok: false,
        message: `Bakhed completion requires at least ${config.bakhedCompletionThreshold}% listened`
      };
    }
  }

  return { ok: true, eventType, sourceId, metadata };
}

export default async ({ req, res, log, error }) => {
  if (req.method !== 'POST') {
    return res.json({ ok: false, message: 'Method not allowed' }, 405);
  }

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
  const dayKey = dateKey();

  try {
    const body = jsonBody(req);
    const config = await getGamificationConfig(databases, databaseId);
    const validated = validateEvent(body, config);
    if (!validated.ok) {
      return res.json({ ok: false, message: validated.message }, 400);
    }

    const { eventType, sourceId, metadata } = validated;
    const points = Math.min(100, Math.max(0, DEFAULT_SCORES[eventType]));

    const memberId = stableId(`${userId}:${weekId}`);
    let memberDoc;
    try {
      memberDoc = await databases.getDocument(databaseId, 'circle_members', memberId);
    } catch (_) {
      return res.json({ ok: false, message: 'User is not in a circle for this week' }, 404);
    }

    const scope = dedupeScope(eventType, weekId, dayKey);
    const dedupeKey = stableId(`${userId}:${scope}:${eventType}:${sourceId}`);
    const now = new Date();

    try {
      await databases.createDocument(
        databaseId,
        'circle_events',
        dedupeKey,
        {
          circleId: memberDoc.circleId,
          userId,
          weekId,
          dateKey: dayKey,
          eventType,
          sourceId,
          dedupeKey,
          points,
          metadata: JSON.stringify(metadata),
          createdAt: now.toISOString()
        }
      );
    } catch (err) {
      if (err.code === 409) {
        return res.json({
          ok: true,
          duplicate: true,
          pointsAwarded: 0,
          currentPoints: memberDoc.circlePoints || 0,
          message: 'Event already recorded, skipping points'
        });
      }
      throw err;
    }

    const updatePayload = {
      circlePoints: integer(memberDoc.circlePoints) + points,
      lastActiveAt: now.toISOString()
    };

    if (eventType === 'lesson_completed') {
      updatePayload.lessonsCompleted = integer(memberDoc.lessonsCompleted) + 1;
    } else if (eventType === 'quiz_completed') {
      updatePayload.quizzesTaken = integer(memberDoc.quizzesTaken) + 1;
    } else if (eventType === 'bakhed_completed_80_percent') {
      updatePayload.bakhedListened = integer(memberDoc.bakhedListened) + 1;
    } else if (eventType === 'daily_mission_completed') {
      updatePayload.missionDaysCompleted = integer(memberDoc.missionDaysCompleted) + 1;
    } else if (eventType === 'mistake_review_completed') {
      updatePayload.mistakeReviewsCompleted = integer(memberDoc.mistakeReviewsCompleted) + 1;
    }

    const updatedMember = await databases.updateDocument(
      databaseId,
      'circle_members',
      memberDoc.$id,
      updatePayload
    );

    return res.json({
      ok: true,
      duplicate: false,
      pointsAwarded: points,
      currentPoints: updatedMember.circlePoints
    });
  } catch (err) {
    error('recordCircleEvent error: ' + err.message);
    return res.json({ ok: false, message: err.message }, 500);
  }
};
