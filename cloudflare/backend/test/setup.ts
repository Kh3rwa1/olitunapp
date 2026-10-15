import { env } from 'cloudflare:workers';
import { afterEach, beforeAll, beforeEach, vi } from 'vitest';
import { installFetchMock, restoreFetch } from './helpers';

// Splits schema.sql into statements. The schema has no triggers or string
// literals containing ';' or '--', so line comments and ';' are safe cuts.
function schemaStatements(sql: string): string[] {
  return sql
    .split('\n')
    .map((line) => line.replace(/--.*$/, ''))
    .join('\n')
    .split(';')
    .map((s) => s.trim())
    .filter(Boolean);
}

beforeAll(async () => {
  const statements = schemaStatements(env.TEST_SCHEMA_SQL);
  // Applied twice: schema.sql must stay idempotent (it is re-run on deploy).
  for (let pass = 0; pass < 2; pass++) {
    await env.DB.batch(statements.map((s) => env.DB.prepare(s)));
  }
});

beforeEach(() => {
  installFetchMock();
});

afterEach(() => {
  restoreFetch();
  vi.restoreAllMocks();
  vi.useRealTimers();
});
