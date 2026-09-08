import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import test from 'node:test';
import { requiredJobs, releaseGateFailures, runReleaseGate } from './check_release_gate.mjs';

const successfulNeeds = () => Object.fromEntries(
  requiredJobs.map((job) => [job, { result: 'success' }]),
);
const silentOutput = { log() {}, error() {} };

// This reads the real workflow, so adding a prerequisite cannot silently
// leave it out of the release decision.
test('required jobs match the workflow prerequisites exactly', () => {
  const workflow = readFileSync(new URL('../.github/workflows/flutter-ci.yml', import.meta.url), 'utf8');
  const releaseJob = workflow.slice(workflow.indexOf('\n  release-gate:'));
  const match = releaseJob.match(/\bneeds:\s*\[([^\]]+)\]/);
  assert.ok(match, 'release-gate.needs must be present');
  const jobs = match[1].split(',').map((job) => job.trim()).sort();
  assert.deepEqual(jobs, [...requiredJobs].sort());
  assert.match(releaseJob, /node scripts\/check_release_gate\.mjs/);
  assert.match(releaseJob, /NEEDS_JSON:\s*\$\{\{\s*toJSON\(needs\)\s*\}\}/);
  assert.match(workflow, /node --test scripts\/check_release_gate\.test\.mjs/);
});

test('passes only when all mandatory jobs succeed', () => {
  assert.deepEqual(releaseGateFailures(successfulNeeds()), []);
  assert.equal(runReleaseGate(JSON.stringify(successfulNeeds()), silentOutput), 0);
});

for (const result of ['failure', 'cancelled', 'skipped', 'timed_out', 'neutral', 'unknown', '', null]) {
  test(`blocks ${JSON.stringify(result)} in every required job`, () => {
    for (const job of requiredJobs) {
      const needs = successfulNeeds();
      needs[job].result = result;
      const failures = releaseGateFailures(needs);
      assert.equal(failures.length, 1);
      assert.ok(failures[0].startsWith(`${job}:`));
      assert.equal(runReleaseGate(JSON.stringify(needs), silentOutput), 1);
    }
  });
}

test('a cancellation cannot conceal a different failing job', () => {
  const needs = successfulNeeds();
  needs[requiredJobs[0]].result = 'cancelled';
  needs[requiredJobs[1]].result = 'failure';
  assert.equal(releaseGateFailures(needs).length, 2);
  assert.equal(runReleaseGate(JSON.stringify(needs), silentOutput), 1);
});

test('blocks missing jobs and malformed job records', () => {
  for (const job of requiredJobs) {
    const needs = successfulNeeds();
    delete needs[job];
    assert.equal(releaseGateFailures(needs).length, 1);
    for (const record of [null, {}, { result: true }]) {
      needs[job] = record;
      assert.equal(releaseGateFailures(needs).length, 1);
    }
  }
});

test('blocks absent, invalid, and non-object input', () => {
  for (const raw of [undefined, '', 'not-json', 'null', '[]', 'true', '42', '{}']) {
    assert.equal(runReleaseGate(raw, silentOutput), 1);
  }
});

test('CLI returns a nonzero exit status for cancellation and missing input', () => {
  const path = fileURLToPath(new URL('./check_release_gate.mjs', import.meta.url));
  const needs = successfulNeeds();
  needs[requiredJobs[0]].result = 'cancelled';
  const { NEEDS_JSON: _ignored, ...cleanEnv } = process.env;
  for (const env of [cleanEnv, { ...cleanEnv, NEEDS_JSON: JSON.stringify(needs) }]) {
    const result = spawnSync(process.execPath, [path], { env, encoding: 'utf8' });
    assert.equal(result.status, 1);
    assert.match(result.stderr, /Release gate blocked/);
  }
  const result = spawnSync(process.execPath, [path], {
    env: { ...cleanEnv, NEEDS_JSON: JSON.stringify(successfulNeeds()) },
    encoding: 'utf8',
  });
  assert.equal(result.status, 0);
  assert.match(result.stdout, /every required job succeeded/);
});
