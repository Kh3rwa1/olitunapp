export const LEADERBOARD_RULES = Object.freeze({
  lesson_completed: Object.freeze({ points: 40, cap: 20, capScope: 'week' }),
  quiz_completed: Object.freeze({ points: 25, cap: 5, capScope: 'day' }),
  daily_mission_completed: Object.freeze({
    points: 30,
    cap: 1,
    capScope: 'day',
  }),
  letter_practiced: Object.freeze({ points: 2, cap: 30, capScope: 'week' }),
  practice_completed: Object.freeze({ points: 5, cap: 20, capScope: 'day' }),
});

const MAX_UPLOAD_DELAY_MS = 7 * 24 * 60 * 60 * 1000;

export function parseBody(body) {
  if (!body) return {};
  if (typeof body === 'object') return body;
  try {
    const parsed = JSON.parse(body);
    return parsed && typeof parsed === 'object' && !Array.isArray(parsed)
      ? parsed
      : {};
  } catch (_) {
    return {};
  }
}

function dateKey(date) {
  return date.toISOString().slice(0, 10);
}

export function utcWeekRange(now = new Date()) {
  const current = new Date(now);
  if (Number.isNaN(current.getTime())) {
    throw new TypeError('A valid date is required.');
  }
  const start = new Date(
    Date.UTC(
      current.getUTCFullYear(),
      current.getUTCMonth(),
      current.getUTCDate(),
    ),
  );
  const daysSinceMonday = (start.getUTCDay() + 6) % 7;
  start.setUTCDate(start.getUTCDate() - daysSinceMonday);
  const end = new Date(start);
  end.setUTCDate(end.getUTCDate() + 6);
  return { start: dateKey(start), end: dateKey(end) };
}

export function eventOwnerUserId(event) {
  const permissions = Array.isArray(event?.$permissions)
    ? event.$permissions
    : [];
  const owners = new Set();
  for (const permission of permissions) {
    const match = String(permission).match(
      /^(?:read|update|delete|write)\("user:([^"/]+)"\)$/,
    );
    if (match) owners.add(match[1]);
  }
  if (owners.size !== 1) return null;
  const [owner] = owners;
  return String(event?.userId || '') === owner ? owner : null;
}

function validEventDate(event, weekStart, weekEnd) {
  const key = String(event?.dateKey || '');
  if (!/^\d{4}-\d{2}-\d{2}$/.test(key)) return false;
  if (key < weekStart || key > weekEnd) return false;

  const occurredAt = new Date(event?.occurredAt || '');
  const createdAt = new Date(event?.$createdAt || '');
  if (Number.isNaN(occurredAt.getTime()) || Number.isNaN(createdAt.getTime())) {
    return false;
  }
  if (dateKey(occurredAt) !== key) return false;

  const uploadDelay = createdAt.getTime() - occurredAt.getTime();
  return uploadDelay >= -5 * 60 * 1000 && uploadDelay <= MAX_UPLOAD_DELAY_MS;
}

function sourceIdFor(event) {
  const value = String(event?.sourceId || '').trim();
  return value.length > 0 && value.length <= 120 ? value : null;
}

function dedupeKey(eventName, owner, event, sourceId) {
  const day = event.dateKey;
  switch (eventName) {
    case 'lesson_completed':
    case 'letter_practiced':
      return `${owner}:${eventName}:week:${sourceId}`;
    case 'daily_mission_completed':
      return sourceId === day ? `${owner}:${eventName}:${day}` : null;
    case 'quiz_completed':
    case 'practice_completed':
      return `${owner}:${eventName}:${day}:${sourceId}`;
    default:
      return null;
  }
}

export function scoreWeeklyEvents(events, weekStart, weekEnd) {
  const scores = new Map();
  const breakdowns = new Map();
  const seen = new Set();
  const cappedCounts = new Map();

  for (const event of events) {
    const eventName = String(event?.eventName || '');
    const rule = LEADERBOARD_RULES[eventName];
    if (!rule || !validEventDate(event, weekStart, weekEnd)) continue;

    const owner = eventOwnerUserId(event);
    const sourceId = sourceIdFor(event);
    if (!owner || !sourceId) continue;

    const uniqueKey = dedupeKey(eventName, owner, event, sourceId);
    if (!uniqueKey || seen.has(uniqueKey)) continue;

    const capBucket = rule.capScope === 'day' ? event.dateKey : weekStart;
    const capKey = `${owner}:${eventName}:${capBucket}`;
    const currentCount = cappedCounts.get(capKey) || 0;
    if (currentCount >= rule.cap) continue;

    seen.add(uniqueKey);
    cappedCounts.set(capKey, currentCount + 1);
    scores.set(owner, (scores.get(owner) || 0) + rule.points);

    const breakdown = breakdowns.get(owner) || {};
    breakdown[eventName] = (breakdown[eventName] || 0) + rule.points;
    breakdowns.set(owner, breakdown);
  }

  return { scores, breakdowns };
}

export function leaderboardForUser(scored, userId) {
  const entries = [...scored.scores.entries()]
    .filter(([, points]) => points > 0)
    .sort(([userA, pointsA], [userB, pointsB]) =>
      pointsB === pointsA ? userA.localeCompare(userB) : pointsB - pointsA,
    );

  let previousPoints = null;
  let currentRank = 0;
  const ranked = entries.map(([entryUserId, points], index) => {
    if (points !== previousPoints) currentRank = index + 1;
    previousPoints = points;
    return { userId: entryUserId, points, rank: currentRank };
  });
  const current = ranked.find((entry) => entry.userId === userId);

  return {
    rank: current?.rank ?? null,
    points: current?.points ?? 0,
    totalParticipants: ranked.length,
    breakdown: scored.breakdowns.get(userId) || {},
  };
}
