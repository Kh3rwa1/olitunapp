import { createHash } from 'crypto';
import { Client, Databases, Query } from 'node-appwrite';

export const DATABASE_ID =
  process.env.OLITUN_APPWRITE_DATABASE_ID ||
  process.env.APPWRITE_DATABASE_ID ||
  'olitun_db';
export const EVENTS_COLLECTION = 'learning_analytics_events';
export const ROLLUPS_COLLECTION = 'learning_analytics_daily_rollups';

export function parseBody(body) {
  if (!body) return {};
  if (typeof body === 'object') return body;
  try {
    return JSON.parse(body);
  } catch (_) {
    return {};
  }
}

export function defaultDateKey(now = new Date()) {
  const day = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
  );
  day.setUTCDate(day.getUTCDate() - 1);
  return day.toISOString().slice(0, 10);
}

export function stableId(value) {
  return createHash('sha256').update(value).digest('hex').slice(0, 32);
}

function safeDateKey(value) {
  const text = String(value || '').trim();
  return /^\d{4}-\d{2}-\d{2}$/.test(text) ? text : null;
}

function increment(map, key) {
  if (!key) return;
  map.set(key, (map.get(key) || 0) + 1);
}

function toCountsObject(map) {
  return Object.fromEntries([...map.entries()].sort(([a], [b]) => a.localeCompare(b)));
}

export function aggregateEvents(events, dateKey) {
  const groups = new Map();

  for (const event of events) {
    const eventName = String(event.eventName || '').trim();
    if (!eventName) continue;

    if (!groups.has(eventName)) {
      groups.set(eventName, {
        dateKey,
        eventName,
        totalEvents: 0,
        users: new Set(),
        platforms: new Map(),
        sources: new Map(),
      });
    }

    const group = groups.get(eventName);
    group.totalEvents += 1;
    if (event.userId) group.users.add(String(event.userId));
    increment(group.platforms, event.platform);
    increment(group.sources, event.source);
  }

  return [...groups.values()].map((group) => ({
    rollupId: stableId(`${dateKey}:${group.eventName}`),
    dateKey,
    eventName: group.eventName,
    totalEvents: group.totalEvents,
    uniqueUsers: group.users.size,
    platformBreakdown: JSON.stringify(toCountsObject(group.platforms)),
    sourceBreakdown: JSON.stringify(toCountsObject(group.sources)),
    updatedAt: new Date().toISOString(),
  }));
}

async function listAllAnalyticsEvents(databases, dateKey) {
  const documents = [];

  while (true) {
    const result = await databases.listDocuments(DATABASE_ID, EVENTS_COLLECTION, [
      Query.equal('dateKey', dateKey),
      Query.limit(100),
      Query.offset(documents.length),
    ]);

    documents.push(...result.documents);
    if (result.documents.length < 100) return documents;
  }
}

async function upsertRollup(databases, rollup) {
  try {
    await databases.updateDocument(
      DATABASE_ID,
      ROLLUPS_COLLECTION,
      rollup.rollupId,
      rollup,
    );
  } catch (err) {
    if (err.code !== 404) throw err;
    await databases.createDocument(
      DATABASE_ID,
      ROLLUPS_COLLECTION,
      rollup.rollupId,
      rollup,
    );
  }
}

function appwriteClient() {
  const endpoint =
    process.env.APPWRITE_FUNCTION_API_ENDPOINT ||
    process.env.OLITUN_APPWRITE_ENDPOINT;
  const projectId =
    process.env.APPWRITE_FUNCTION_PROJECT_ID ||
    process.env.OLITUN_APPWRITE_PROJECT_ID;
  const apiKey =
    process.env.OLITUN_APPWRITE_API_KEY ||
    process.env.APPWRITE_FUNCTION_API_KEY;

  if (!endpoint || !projectId || !apiKey) {
    throw new Error('Missing Appwrite endpoint, project ID, or API key.');
  }

  return new Client().setEndpoint(endpoint).setProject(projectId).setKey(apiKey);
}

export default async ({ req, res, log, error }) => {
  try {
    const body = parseBody(req.body);
    const dateKey = safeDateKey(body.dateKey) || defaultDateKey();
    const databases = new Databases(appwriteClient());

    const events = await listAllAnalyticsEvents(databases, dateKey);
    const rollups = aggregateEvents(events, dateKey);

    for (const rollup of rollups) {
      await upsertRollup(databases, rollup);
    }

    log(`Aggregated ${events.length} analytics events into ${rollups.length} rollups for ${dateKey}.`);
    return res.json({
      ok: true,
      dateKey,
      events: events.length,
      rollups: rollups.length,
    });
  } catch (err) {
    const message = err?.message || String(err);
    error(message);
    return res.json(
      { ok: false, message: 'Analytics aggregation failed.' },
      500,
    );
  }
};
