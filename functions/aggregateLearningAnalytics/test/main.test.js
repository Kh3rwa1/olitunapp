import test from 'node:test';
import assert from 'node:assert/strict';

import {
  aggregateEvents,
  defaultDateKey,
  parseBody,
  stableId,
} from '../src/main.js';

test('parseBody tolerates empty and invalid input', () => {
  assert.deepEqual(parseBody(''), {});
  assert.deepEqual(parseBody('{nope'), {});
  assert.deepEqual(parseBody('{"dateKey":"2026-05-22"}'), {
    dateKey: '2026-05-22',
  });
});

test('defaultDateKey returns previous UTC day', () => {
  assert.equal(defaultDateKey(new Date('2026-05-22T01:00:00Z')), '2026-05-21');
});

test('stableId is deterministic and Appwrite-safe length', () => {
  assert.equal(stableId('a:b'), stableId('a:b'));
  assert.equal(stableId('a:b').length, 32);
});

test('aggregateEvents groups events without exposing raw user lists', () => {
  const rollups = aggregateEvents(
    [
      {
        eventName: 'lesson_completed',
        userId: 'u1',
        platform: 'android',
        source: 'lesson_detail',
      },
      {
        eventName: 'lesson_completed',
        userId: 'u1',
        platform: 'android',
        source: 'lesson_detail',
      },
      {
        eventName: 'quiz_completed',
        userId: 'u2',
        platform: 'web',
        source: 'quiz',
      },
    ],
    '2026-05-22',
  );

  const lesson = rollups.find((item) => item.eventName === 'lesson_completed');
  assert.equal(lesson.totalEvents, 2);
  assert.equal(lesson.uniqueUsers, 1);
  assert.equal(lesson.dateKey, '2026-05-22');
  assert.deepEqual(JSON.parse(lesson.platformBreakdown), { android: 2 });
  assert.deepEqual(JSON.parse(lesson.sourceBreakdown), { lesson_detail: 2 });
});
