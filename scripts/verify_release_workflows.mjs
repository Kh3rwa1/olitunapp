#!/usr/bin/env node
import { pathToFileURL } from 'node:url';

export const REQUIRED_WORKFLOWS = ['flutter-ci.yml', 'security-scan.yml'];

// Select the latest PUSH run, not an older green run or a PR's merge commit.
export function verifyReleaseWorkflowRuns(sha, runsByWorkflow) {
  const verified = [];
  for (const workflow of REQUIRED_WORKFLOWS) {
    const runs = runsByWorkflow[workflow];
    if (!Array.isArray(runs)) throw new Error(`Missing workflow evidence: ${workflow}`);
    const matching = runs.filter(run => run.head_sha === sha && run.event === 'push');
    matching.sort((a, b) => Number(b.id) - Number(a.id) || Number(b.run_attempt || 1) - Number(a.run_attempt || 1));
    const latest = matching[0];
    if (!latest || latest.status !== 'completed' || latest.conclusion !== 'success') {
      throw new Error(`Release blocked: latest ${workflow} push run for the selected commit must succeed.`);
    }
    verified.push({ workflow, runId: latest.id, attempt: latest.run_attempt || 1 });
  }
  return verified;
}

export async function requireReleaseWorkflows({ repository, sha, token, fetchImpl = fetch }) {
  if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repository || '') ||
      !/^[a-f0-9]{40}$/.test(sha || '') || !token) {
    throw new Error('Release verification requires repository, exact commit SHA, and GitHub token.');
  }
  const runsByWorkflow = {};
  for (const workflow of REQUIRED_WORKFLOWS) {
    const url = new URL(`{{https://api.github.com/repos/${repository}}}/actions/workflows/${workflow}/runs`);
    url.searchParams.set('head_sha', sha);
    url.searchParams.set('event', 'push');
    url.searchParams.set('per_page', '100');
    const response = await fetchImpl(url, {
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
      signal: AbortSignal.timeout(15000),
    });
    if (!response.ok) throw new Error(`Cannot verify ${workflow}: GitHub HTTP ${response.status}.`);
    const payload = await response.json();
    if (!Array.isArray(payload.workflow_runs) || payload.total_count > payload.workflow_runs.length) {
      // Fail closed instead of approving from incomplete evidence.
      throw new Error(`Incomplete workflow evidence for ${workflow}.`);
    }
    runsByWorkflow[workflow] = payload.workflow_runs;
  }
  return verifyReleaseWorkflowRuns(sha, runsByWorkflow);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    const verified = await requireReleaseWorkflows({
      repository: process.env.GITHUB_REPOSITORY,
      sha: process.env.GITHUB_SHA,
      token: process.env.GITHUB_TOKEN,
    });
    for (const run of verified) console.log(`Verified ${run.workflow} run ${run.runId}, attempt ${run.attempt}.`);
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
