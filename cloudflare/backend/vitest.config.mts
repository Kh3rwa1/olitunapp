import { readFileSync } from 'node:fs';
import { cloudflareTest } from '@cloudflare/vitest-pool-workers';
import { defineConfig } from 'vitest/config';

// schema.sql stays the single source of truth: the setup file applies it to
// the local test D1 before each test file runs.
const schemaSql = readFileSync(new URL('./schema.sql', import.meta.url), 'utf8');

export default defineConfig({
  plugins: [
    cloudflareTest({
      wrangler: { configPath: './wrangler.json' },
      // Never reach real Cloudflare resources from tests.
      remoteBindings: false,
      miniflare: {
        bindings: {
          TEST_SCHEMA_SQL: schemaSql,
          // Outbound hosts are fake; test/helpers.ts mocks fetch for them.
          APPWRITE_ENDPOINT: 'https://appwrite.test/v1',
          APPWRITE_PROJECT_ID: 'test-project',
          ADMIN_TEAM_ID: 'admins',
          CRON_SECRET: 'test-cron-secret',
          RAZORPAY_KEY_ID: 'rzp_test_key',
          RAZORPAY_KEY_SECRET: 'rzp_test_secret',
          RAZORPAY_WEBHOOK_SECRET: 'rzp_webhook_secret',
          RAZORPAY_API_BASE: 'https://razorpay.test',
          MEDIA_SIGNING_SECRET: 'test-media-signing-secret',
          BODHAN_API_KEYS: 'bodhan-key-a,bodhan-key-b,bodhan-key-c',
          BODHAN_API_BASE: 'https://bodhan.test',
        },
      },
    }),
  ],
  test: {
    include: ['test/**/*.test.ts'],
    setupFiles: ['./test/setup.ts'],
  },
});
