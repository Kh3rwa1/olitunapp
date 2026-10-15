import type { Bindings } from './env';
import {
  aggregateAnalytics,
  cleanupAnalytics,
  expireCaches,
  previousUtcDay,
  reconcilePaymentOrders,
} from './lib/maintenance';
import { reconcileDeletions } from './routes/account';

// Cron Trigger schedules; must match "triggers.crons" in wrangler.json.
export const CRON_HOURLY = '7 * * * *';
export const CRON_DAILY = '17 3 * * *';

const HOUR_MS = 3600 * 1000;

type Job = { name: string; run: (env: Bindings, now: Date) => Promise<unknown> };

const HOURLY_JOBS: Job[] = [
  { name: 'payments.reconcile', run: (env, now) => reconcilePaymentOrders(env.DB, now) },
  { name: 'deletions.reconcile', run: (env, now) => reconcileDeletions(env, { staleMs: HOUR_MS, now }) },
];

const DAILY_JOBS: Job[] = [
  { name: 'analytics.aggregate', run: (env, now) => aggregateAnalytics(env.DB, previousUtcDay(now), now) },
  { name: 'analytics.cleanup', run: (env, now) => cleanupAnalytics(env.DB, now) },
  { name: 'caches.expire', run: (env, now) => expireCaches(env.DB, now) },
];

export function jobsFor(cron: string): Job[] {
  if (cron === CRON_HOURLY) return HOURLY_JOBS;
  if (cron === CRON_DAILY) return DAILY_JOBS;
  return [];
}

/**
 * Runs every job for [cron] in order. A failing job is logged and does not
 * stop the others. Returns a compact per-job summary (also logged).
 */
export async function runCron(cron: string, env: Bindings, now = new Date()): Promise<Record<string, unknown>> {
  const jobs = jobsFor(cron);
  const summary: Record<string, unknown> = {};
  if (jobs.length === 0) {
    console.warn(JSON.stringify({ msg: 'cron: unknown schedule', cron }));
    return summary;
  }
  for (const job of jobs) {
    const started = Date.now();
    try {
      const result = await job.run(env, now);
      summary[job.name] = { ok: true, ms: Date.now() - started, ...(compact(result) as object) };
    } catch (err: any) {
      summary[job.name] = { ok: false, ms: Date.now() - started, error: String(err?.message || err).slice(0, 200) };
    }
  }
  const failed = Object.values(summary).some((s: any) => !s.ok);
  (failed ? console.error : console.log)(JSON.stringify({ msg: 'cron summary', cron, jobs: summary }));
  return summary;
}

// Drops bulky fields (per-event counts) from the logged result.
function compact(result: unknown): unknown {
  if (!result || typeof result !== 'object') return {};
  const { counts: _counts, ...rest } = result as Record<string, unknown>;
  return rest;
}

export async function scheduled(controller: ScheduledController, env: Bindings, ctx: ExecutionContext): Promise<void> {
  ctx.waitUntil(runCron(controller.cron, env, new Date(controller.scheduledTime)));
}
