import test from 'node:test';
import assert from 'node:assert/strict';
import { createTranslationBudget, positiveLimit } from '../src/resource_budget.js';

test('resource configuration rejects invalid and unbounded values', () => {
  for (const n of ['0', '-1', 'NaN', '12x', '501', '1.5']) assert.throws(() => positiveLimit(n, 30));
  assert.equal(positiveLimit(undefined, 30), 30);
  assert.equal(positiveLimit('42', 30), 42);
});
test('disabled service never reserves a slot', async () => {
  const budget = createTranslationBudget({ env: { TRANSLATION_ENABLED: 'false' }, reserve: () => assert.fail('called storage') });
  assert.equal((await budget.acquire({})).allowed, false);
});
test('request and upstream budgets use independent global identities', async () => {
  const calls = [];
  const budget = createTranslationBudget({ env: {}, reserve: async args => { calls.push(args); return { allowed: true }; } });
  await budget.acquire({}); await budget.acquire({}, { upstream: true });
  assert.notEqual(calls[0].identifier, calls[1].identifier);
  assert.equal(calls[0].limit, 120); assert.equal(calls[1].limit, 30);
});
test('storage outage fails closed and repeated failures open the circuit', async () => {
  let time = 1000;
  let reservations = 0;
  const budget = createTranslationBudget({ env: {}, now: () => time, reserve: async () => { reservations++; return { allowed: false, reason: 'rate_limit_storage_error' }; } });
  assert.equal((await budget.acquire({})).allowed, false);
  for (let i = 0; i < 5; i++) budget.failed();
  assert.equal((await budget.acquire({}, { upstream: true })).reason, 'circuit_open');
  assert.equal(reservations, 1);
  time += 30001;
  await budget.acquire({}, { upstream: true });
  assert.equal(reservations, 2);
});
