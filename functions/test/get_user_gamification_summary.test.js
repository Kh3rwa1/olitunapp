import assert from 'node:assert/strict';
import test from 'node:test';

import {
  eventOwnerUserId,
  leaderboardForUser,
  parseBody,
  scoreWeeklyEvents,
  utcWeekRange,
} from '../getUserGamificationSummary/src/leaderboard.js';

function event({
  id,
  userId = 'user-a',
  name = 'quiz_completed',
  sourceId = 'quiz-1',
  date = '2026-09-10',
  createdAt = '2026-09-10T10:00:01.000Z',
  occurredAt = '2026-09-10T10:00:00.000Z',
  permissions,
}) {
  return {
    $id: id,
    $createdAt: createdAt,
    $permissions:
      permissions || [
        `read("user:${userId}")`,
        `update("user:${userId}")`,
        `delete("user:${userId}")`,
      ],
    userId,
    eventName: name,
    sourceId,
    dateKey: date,
    occurredAt,
  };
}

test('parseBody accepts objects and valid object JSON only', () => {
  assert.deepEqual(parseBody({ scope: 'leaderboard' }), {
    scope: 'leaderboard',
  });
  assert.deepEqual(parseBody('{"scope":"leaderboard"}'), {
    scope: 'leaderboard',
  });
  assert.deepEqual(parseBody('[1,2]'), {});
  assert.deepEqual(parseBody('bad json'), {});
});

test('utcWeekRange uses a Monday-to-Sunday UTC week across years', () => {
  assert.deepEqual(utcWeekRange(new Date('2026-09-10T05:00:00Z')), {
    start: '2026-09-07',
    end: '2026-09-13',
  });
  assert.deepEqual(utcWeekRange(new Date('2027-01-01T05:00:00Z')), {
    start: '2026-12-28',
    end: '2027-01-03',
  });
});

test('event ownership must match Appwrite-created row permissions', () => {
  assert.equal(eventOwnerUserId(event({ id: 'owned' })), 'user-a');
  assert.equal(
    eventOwnerUserId(
      event({
        id: 'spoofed',
        userId: 'user-b',
        permissions: ['read("user:user-a")'],
      }),
    ),
    null,
  );
  assert.equal(
    eventOwnerUserId(event({ id: 'public', permissions: ['read("any")'] })),
    null,
  );
});

test('weekly scoring uses real owned events and removes duplicates', () => {
  const events = [
    event({ id: 'quiz-1' }),
    event({ id: 'quiz-duplicate' }),
    event({ id: 'lesson', name: 'lesson_completed', sourceId: 'lesson-1' }),
    event({
      id: 'mission',
      name: 'daily_mission_completed',
      sourceId: '2026-09-10',
    }),
    event({ id: 'letter', name: 'letter_practiced', sourceId: 'ᱚ' }),
    event({
      id: 'spoofed',
      userId: 'user-b',
      permissions: ['read("user:user-a")'],
    }),
    event({
      id: 'outside-week',
      date: '2026-09-06',
      createdAt: '2026-09-06T10:00:01.000Z',
      occurredAt: '2026-09-06T10:00:00.000Z',
    }),
  ];

  const scored = scoreWeeklyEvents(events, '2026-09-07', '2026-09-13');
  assert.equal(scored.scores.get('user-a'), 97);
  assert.deepEqual(scored.breakdowns.get('user-a'), {
    quiz_completed: 25,
    lesson_completed: 40,
    daily_mission_completed: 30,
    letter_practiced: 2,
  });
  assert.equal(scored.scores.has('user-b'), false);
});

test('rejects stale uploads and malformed mission source IDs', () => {
  const scored = scoreWeeklyEvents(
    [
      event({
        id: 'stale',
        createdAt: '2026-09-18T10:00:01.000Z',
      }),
      event({
        id: 'bad-mission',
        name: 'daily_mission_completed',
        sourceId: 'not-the-date',
      }),
    ],
    '2026-09-07',
    '2026-09-13',
  );
  assert.equal(scored.scores.size, 0);
});

test('daily caps prevent event spam from inflating points', () => {
  const quizzes = Array.from({ length: 8 }, (_, index) =>
    event({ id: `quiz-${index}`, sourceId: `quiz-${index}` }),
  );
  const scored = scoreWeeklyEvents(quizzes, '2026-09-07', '2026-09-13');
  assert.equal(scored.scores.get('user-a'), 125);
});

test('ranking is deterministic and gives equal scores equal ranks', () => {
  const scored = {
    scores: new Map([
      ['user-a', 100],
      ['user-b', 80],
      ['user-c', 80],
    ]),
    breakdowns: new Map([['user-b', { quiz_completed: 80 }]]),
  };
  assert.deepEqual(leaderboardForUser(scored, 'user-b'), {
    rank: 2,
    points: 80,
    totalParticipants: 3,
    breakdown: { quiz_completed: 80 },
  });
  assert.deepEqual(leaderboardForUser(scored, 'user-missing'), {
    rank: null,
    points: 0,
    totalParticipants: 3,
    breakdown: {},
  });
});
