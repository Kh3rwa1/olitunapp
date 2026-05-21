import { createHash } from 'crypto';
import { Client, Databases, Query } from 'node-appwrite';

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

function currentWeekId(now = new Date()) {
  const date = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const day = date.getUTCDay() || 7;
  date.setUTCDate(date.getUTCDate() + 4 - day);
  const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
  const week = Math.ceil((((date - yearStart) / 86400000) + 1) / 7);
  return `${date.getUTCFullYear()}-W${String(week).padStart(2, '0')}`;
}

async function readMaxShields(databases, databaseId) {
  try {
    const result = await databases.listDocuments(databaseId, 'gamification_config', [
      Query.equal('configId', 'default'),
      Query.limit(1)
    ]);
    return Math.max(0, Math.min(result.documents[0]?.streakShieldMax || 2, 5));
  } catch (_) {
    return 2;
  }
}

async function getShieldDoc(databases, databaseId, userId, maxShields) {
  const docId = stableId(`${userId}:streak_shield`);
  try {
    return await databases.getDocument(databaseId, 'streak_shields', docId);
  } catch (_) {
    return databases.createDocument(databaseId, 'streak_shields', docId, {
      userId,
      availableShields: 0,
      maxShields,
      earnedAt: '',
      usedAt: '',
      source: ''
    });
  }
}

async function logReward(databases, databaseId, userId, sourceId, reason) {
  const rewardEventId = stableId(`${userId}:streak_shield:${sourceId}`);
  try {
    await databases.createDocument(databaseId, 'reward_events', rewardEventId, {
      rewardEventId,
      userId,
      sourceType: 'streak_shield',
      sourceId,
      starsAwarded: 0,
      badgeId: '',
      reason,
      createdAt: new Date().toISOString()
    });
  } catch (err) {
    if (err.code !== 409) throw err;
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
  const action = String(body.action || '').trim();
  const now = new Date();
  const weekId = currentWeekId(now);

  const client = new Client()
    .setEndpoint(endpoint)
    .setProject(projectId)
    .setKey(apiKey);
  const databases = new Databases(client);
  const databaseId = process.env.APPWRITE_DATABASE_ID || 'olitun_db';

  try {
    const maxShields = await readMaxShields(databases, databaseId);
    const shield = await getShieldDoc(databases, databaseId, userId, maxShields);

    if (action === 'earn_from_missions') {
      const source = `missions:${weekId}`;
      if (shield.source === source) {
        return res.json({ ok: true, changed: false, reason: 'Already earned this week', shield });
      }

      const events = await databases.listDocuments(databaseId, 'circle_events', [
        Query.equal('userId', userId),
        Query.equal('weekId', weekId),
        Query.equal('eventType', 'daily_mission_completed'),
        Query.limit(100)
      ]);
      const days = new Set(
        events.documents
          .map((event) => event.dateKey || String(event.createdAt || '').slice(0, 10))
          .filter(Boolean)
      );
      if (days.size < 3) {
        return res.json({
          ok: true,
          changed: false,
          reason: 'Need 3 daily mission days',
          completedDays: days.size,
          shield
        });
      }

      const availableShields = Math.min((shield.availableShields || 0) + 1, maxShields);
      const updated = await databases.updateDocument(databaseId, 'streak_shields', shield.$id, {
        availableShields,
        maxShields,
        earnedAt: now.toISOString(),
        source
      });
      await logReward(databases, databaseId, userId, source, 'Streak Shield earned from daily missions');
      return res.json({ ok: true, changed: true, shield: updated });
    }

    if (action === 'use_for_missed_day') {
      if ((shield.availableShields || 0) <= 0) {
        return res.json({ ok: true, changed: false, reason: 'No shields available', shield });
      }
      const source = `missed_day:${now.toISOString().slice(0, 10)}`;
      const updated = await databases.updateDocument(databaseId, 'streak_shields', shield.$id, {
        availableShields: Math.max((shield.availableShields || 0) - 1, 0),
        maxShields,
        usedAt: now.toISOString(),
        source
      });
      await logReward(databases, databaseId, userId, source, 'Streak Shield used');
      return res.json({ ok: true, changed: true, shield: updated });
    }

    return res.json({ ok: false, message: 'Unsupported action' }, 400);
  } catch (err) {
    error('updateStreakShield error: ' + err.message);
    return res.json({ ok: false, message: err.message }, 500);
  }
};
