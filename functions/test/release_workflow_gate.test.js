import assert from 'node:assert/strict';
import test from 'node:test';
import { REQUIRED_WORKFLOWS, verifyReleaseWorkflowRuns, requireReleaseWorkflows } from '../../scripts/verify_release_workflows.mjs';

const sha = 'a'.repeat(40);
const success = { id: 100, head_sha: sha, event: 'push', status: 'completed', conclusion: 'success', run_attempt: 1 };
const evidence = () => Object.fromEntries(REQUIRED_WORKFLOWS.map(workflow => [workflow, [{ ...success }]]));

test('release requires successful canonical CI and security on the exact commit', () => {
  assert.equal(verifyReleaseWorkflowRuns(sha, evidence()).length, 2);
});
for (const conclusion of ['failure', 'cancelled', 'skipped', 'neutral', 'timed_out', null]) {
  test(`release rejects ${conclusion} rather than selecting an older successful run`, () => {
    const runs = evidence();
    runs['flutter-ci.yml'].push({ ...success, id: 101, conclusion });
    assert.throws(() => verifyReleaseWorkflowRuns(sha, runs), /Release blocked/);
  });
}
test('release rejects a running rerun even if another workflow has passed', () => {
  const runs = evidence();
  runs['security-scan.yml'] = [{ ...success, run_attempt: 2, status: 'in_progress', conclusion: null }];
  assert.throws(() => verifyReleaseWorkflowRuns(sha, runs), /Release blocked/);
});
test('release rejects evidence from another commit or a PR event', () => {
  for (const change of [{ head_sha: 'b'.repeat(40) }, { event: 'pull_request' }]) {
    const runs = evidence();
    runs['flutter-ci.yml'] = [{ ...success, ...change }];
    assert.throws(() => verifyReleaseWorkflowRuns(sha, runs), /Release blocked/);
  }
});
test('release rejects absent workflow results', () => {
  assert.throws(() => verifyReleaseWorkflowRuns(sha, {}), /Missing workflow evidence/);
});
test('workflow API requests are commit-scoped and both required workflows are checked', async () => {
  const urls = [];
  const result = await requireReleaseWorkflows({ repository: 'owner/repo', sha, token: 'test-only',
    fetchImpl: async url => {
      urls.push(String(url));
      assert.equal(url.searchParams.get('head_sha'), sha);
      assert.equal(url.searchParams.get('event'), 'push');
      return { ok: true, json: async () => ({ total_count: 1, workflow_runs: [{ ...success }] }) };
    },
  });
  assert.equal(urls.length, 2);
  assert.equal(result.length, 2);
});
test('API failures and truncated evidence block the release', async () => {
  for (const response of [
    { ok: false, status: 403 },
    { ok: true, json: async () => ({ total_count: 2, workflow_runs: [{ ...success }] }) },
    { ok: true, json: async () => ({ total_count: 0 }) },
  ]) {
    await assert.rejects(() => requireReleaseWorkflows({ repository: 'owner/repo', sha, token: 'test-only', fetchImpl: async () => response }));
  }
});
