import { createHash } from 'crypto';
import { Client, Databases } from 'node-appwrite';

function stableId(value) {
  return createHash('sha256').update(value).digest('hex').slice(0, 32);
}

function parseBody(req) {
  try {
    return JSON.parse(req.body || '{}');
  } catch (_) {
    return {};
  }
}

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

  const body = parseBody(req);
  const questionIds = Array.isArray(body.questionIds)
    ? body.questionIds.map((id) => String(id).slice(0, 100)).filter(Boolean).slice(0, 50)
    : [];
  const score = Number.isInteger(body.score) ? body.score : 0;
  const total = Number.isInteger(body.total) ? body.total : questionIds.length;
  const masteredQuestionIds = Array.isArray(body.masteredQuestionIds)
    ? body.masteredQuestionIds.map((id) => String(id).slice(0, 100)).filter(Boolean).slice(0, 50)
    : [];

  const client = new Client()
    .setEndpoint(endpoint)
    .setProject(projectId)
    .setKey(apiKey);
  const databases = new Databases(client);
  const databaseId = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
  const now = new Date();
  const sessionId = stableId(`${userId}:${now.toISOString()}:${questionIds.join('|')}`);

  try {
    await databases.createDocument(databaseId, 'mistake_review_sessions', sessionId, {
      sessionId,
      userId,
      questionIds: JSON.stringify(questionIds),
      score: Math.max(0, Math.min(score, total)),
      total: Math.max(0, total),
      completedAt: now.toISOString()
    });

    for (const rawId of masteredQuestionIds) {
      const [quizId, ...rest] = rawId.split(':');
      const questionId = rest.join(':');
      if (!quizId || !questionId) continue;
      const mistakeId = stableId(`${userId}:${quizId}:${questionId}`);
      try {
        const existing = await databases.getDocument(databaseId, 'user_mistakes', mistakeId);
        await databases.updateDocument(databaseId, 'user_mistakes', mistakeId, {
          timesReviewed: (existing.timesReviewed || 0) + 1,
          isMastered: true,
          masteredAt: now.toISOString(),
          lastReviewedAt: now.toISOString()
        });
      } catch (_) {
        // A stale local mistake may not exist on the backend yet.
      }
    }

    return res.json({
      ok: true,
      sessionId
    });
  } catch (err) {
    error('completeMistakeReview error: ' + err.message);
    return res.json({ ok: false, message: 'Unable to complete review. Please try again.' }, 500);
  }
};
