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

function text(value, max = 2048) {
  return String(value || '').trim().slice(0, max);
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
  const quizId = text(body.quizId, 100);
  const questionIndex = Number.isInteger(body.questionIndex) ? body.questionIndex : 0;
  const questionId = text(body.questionId || `${quizId}_${questionIndex}`, 100);
  const wrongAnswer = text(body.wrongAnswer);
  const correctAnswer = text(body.correctAnswer);
  const questionSnapshot = body.questionSnapshot && typeof body.questionSnapshot === 'object'
    ? JSON.stringify(body.questionSnapshot).slice(0, 10000)
    : '{}';

  if (!quizId || !questionId) {
    return res.json({ ok: false, message: 'Missing quizId or questionId' }, 400);
  }

  const client = new Client()
    .setEndpoint(endpoint)
    .setProject(projectId)
    .setKey(apiKey);
  const databases = new Databases(client);
  const databaseId = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
  const mistakeId = stableId(`${userId}:${quizId}:${questionId}`);
  const now = new Date().toISOString();

  try {
    try {
      const existing = await databases.getDocument(databaseId, 'user_mistakes', mistakeId);
      const updated = await databases.updateDocument(databaseId, 'user_mistakes', mistakeId, {
        wrongAnswer,
        correctAnswer,
        questionSnapshot,
        timesMissed: (existing.timesMissed || 0) + 1,
        isMastered: false,
        masteredAt: '',
        lastMissedAt: now
      });
      return res.json({ ok: true, mistake: updated });
    } catch (_) {
      const created = await databases.createDocument(databaseId, 'user_mistakes', mistakeId, {
        userId,
        quizId,
        questionId,
        questionIndex,
        wrongAnswer,
        correctAnswer,
        questionSnapshot,
        timesMissed: 1,
        timesReviewed: 0,
        isMastered: false,
        masteredAt: '',
        lastMissedAt: now,
        lastReviewedAt: ''
      });
      return res.json({ ok: true, mistake: created });
    }
  } catch (err) {
    error('recordMistake error: ' + err.message);
    return res.json({ ok: false, message: 'Unable to record mistake. Please try again.' }, 500);
  }
};
