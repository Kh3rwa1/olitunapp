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

  const body = parseBody(req);
  const quizId = String(body.quizId || '').trim();
  const questionIndex = Number.isInteger(body.questionIndex) ? body.questionIndex : 0;
  const questionId = String(body.questionId || `${quizId}_${questionIndex}`).trim();

  if (!quizId || !questionId) {
    return res.json({ ok: false, message: 'Missing quizId or questionId' }, 400);
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
  const mistakeId = stableId(`${userId}:${quizId}:${questionId}`);
  const now = new Date().toISOString();

  try {
    const existing = await databases.getDocument(databaseId, 'user_mistakes', mistakeId);
    const updated = await databases.updateDocument(databaseId, 'user_mistakes', mistakeId, {
      timesReviewed: (existing.timesReviewed || 0) + 1,
      isMastered: true,
      masteredAt: now,
      lastReviewedAt: now
    });
    return res.json({ ok: true, mistake: updated });
  } catch (err) {
    error('markMistakeMastered error: ' + err.message);
    return res.json({ ok: false, message: err.message }, 500);
  }
};
