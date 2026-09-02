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

function clampNumber(value, min, max) {
  const number = Number(value);
  if (!Number.isFinite(number)) return min;
  return Math.max(min, Math.min(max, number));
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
  const bakhedId = String(body.bakhedId || '').trim().slice(0, 100);
  const listenedPercent = Math.round(clampNumber(body.listenedPercent, 0, 100));
  const lastPositionMs = Math.round(clampNumber(body.lastPositionMs, 0, 86400000));

  if (!bakhedId) {
    return res.json({ ok: false, message: 'Missing bakhedId' }, 400);
  }

  const client = new Client()
    .setEndpoint(endpoint)
    .setProject(projectId)
    .setKey(apiKey);
  const databases = new Databases(client);
  const databaseId = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
  const progressId = stableId(`${userId}:${bakhedId}`);
  const now = new Date().toISOString();

  try {
    try {
      const existing = await databases.getDocument(
        databaseId,
        'bakhed_listening_progress',
        progressId
      );
      const nextPercent = Math.max(existing.listenedPercent || 0, listenedPercent);
      const completed80Percent =
        existing.completed80Percent === true || nextPercent >= 80;
      const updated = await databases.updateDocument(
        databaseId,
        'bakhed_listening_progress',
        progressId,
        {
          listenedPercent: nextPercent,
          completed80Percent,
          completedAt:
            existing.completedAt || (completed80Percent ? now : ''),
          lastPositionMs,
          updatedAt: now
        }
      );
      return res.json({ ok: true, progress: updated });
    } catch (_) {
      const completed80Percent = listenedPercent >= 80;
      const created = await databases.createDocument(
        databaseId,
        'bakhed_listening_progress',
        progressId,
        {
          userId,
          bakhedId,
          listenedPercent,
          completed80Percent,
          completedAt: completed80Percent ? now : '',
          lastPositionMs,
          updatedAt: now
        }
      );
      return res.json({ ok: true, progress: created });
    }
  } catch (err) {
    error('recordBakhedProgress error: ' + err.message);
    return res.json({ ok: false, message: 'Unable to record progress. Please try again.' }, 500);
  }
};
