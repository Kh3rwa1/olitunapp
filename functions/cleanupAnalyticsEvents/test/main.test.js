import test from 'node:test';
import assert from 'node:assert/strict';

import {
  getCutoffDateKey,
} from '../src/main.js';

test('getCutoffDateKey calculates correct 90-day threshold', () => {
  const base = new Date('2026-05-22T12:00:00Z');
  // 90 days before May 22, 2026:
  // May has 22 days in this base -> goes back to May 0, i.e., April 30.
  // April has 30 days -> 22 + 30 = 52 days.
  // March has 31 days -> 52 + 31 = 83 days.
  // Feb has 28 days (2026 is not leap year) -> 83 + 7 = 90 days.
  // So 90 days before May 22, 2026 should be Feb 21, 2026.
  assert.equal(getCutoffDateKey(base, 90), '2026-02-21');
});
