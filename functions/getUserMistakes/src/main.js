import { Client, Databases, Query } from 'node-appwrite';

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

  const client = new Client()
    .setEndpoint(endpoint)
    .setProject(projectId)
    .setKey(apiKey);
  const databases = new Databases(client);
  const databaseId = process.env.APPWRITE_DATABASE_ID || 'olitun_db';

  try {
    const result = await databases.listDocuments(databaseId, 'user_mistakes', [
      Query.equal('userId', userId),
      Query.equal('isMastered', false),
      Query.limit(100)
    ]);

    const mistakes = result.documents.map((doc) => ({
      quizId: doc.quizId,
      questionId: doc.questionId,
      questionIndex: doc.questionIndex || 0,
      wrongAnswer: doc.wrongAnswer || '',
      correctAnswer: doc.correctAnswer || '',
      questionSnapshot: doc.questionSnapshot || '{}',
      timesMissed: doc.timesMissed || 0,
      timesReviewed: doc.timesReviewed || 0,
      isMastered: doc.isMastered === true,
      lastMissedAt: doc.lastMissedAt || '',
      lastReviewedAt: doc.lastReviewedAt || ''
    }));

    return res.json({ ok: true, mistakes });
  } catch (err) {
    error('getUserMistakes error: ' + err.message);
    return res.json({ ok: false, message: err.message }, 500);
  }
};
