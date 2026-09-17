# Olitun Release Checklist

Use this checklist before every production release.

## Code Quality

- Run `dart format --set-exit-if-changed .`
- Run `flutter analyze --fatal-infos`
- Run `dart run custom_lint`
- Run `node scripts/check_architecture_boundaries.mjs`
- Run `node scripts/check_l10n_parity.mjs`
- Run `flutter test --coverage`
- Run `flutter test test/smoke`
- Run `npm run test:backend`
- Run `node --test test/web/permissions_policy_test.mjs`
- Run `node --test test/account_deletion/collection_inventory_test.mjs`
- Run `flutter test integration_test -d <device-id>` on a real device for release smoke coverage.
- Run `node --check scripts/appwrite_setup.mjs scripts/create_review_collection.mjs scripts/check_review_corpus_ids.mjs scripts/appwrite_seed.mjs scripts/appwrite_import.mjs functions/translator/src/main.js`
- Run `node scripts/check_review_corpus_ids.mjs && node --test scripts/check_review_corpus_ids.test.mjs`
- Run `node --test scripts/create_review_collection.test.mjs`

## Appwrite & Backend Functions

- Confirm `APPWRITE_ENDPOINT`, `APPWRITE_PROJECT_ID`, `ADMIN_TEAM_ID`, and `TRANSLATE_URL` are set for the target environment.
- Confirm provider credentials `SARVAM_API_KEY` and `BODHAN_API_KEY` are configured for serverless functions.
- Run `scripts/appwrite_setup.mjs` with a server API key after schema or permission changes.
- Verify schemas via dry-runs:
  - `node scripts/create_review_collection.mjs --verify-only`
  - `node scripts/setup_ai_studio.mjs --dry-run`
  - `node scripts/setup_santali_voice.mjs --dry-run`
- Confirm table permissions:
  - `review_states`: `create("users")`, `rowSecurity: true`, no guest access.
  - `ai_studio_jobs`, `voice_claims`: user-bound or function-only.
  - `translation_cache`, `tts_cache`, and `rate_limits`: function-only write permissions.
- Confirm scheduled jobs:
  - `cleanupAnalyticsEvents` runs daily at `0 3 * * *` (03:00 UTC) with `files.read` & `files.write` scopes, pruning `ai_studio_inputs` (24h), `ai_studio_jobs` (30d), `tts_cache` (90d + audio storage), `voice_claims` (7d), and `learning_analytics_events` (90d).

## Web Deployment

- Confirm Vercel has the required build variables:
  - `APPWRITE_ENDPOINT`
  - `APPWRITE_PROJECT_ID`
  - `TRANSLATE_URL`
  - `ADMIN_TEAM_ID`
  - optional `SENTRY_DSN` and `SENTRY_ENV`
- Run a release web build with the same dart-defines used by production.
- Smoke test `/`, `/welcome`, `/privacy`, `/terms`, `/translate`, and `/admin/login`.
- Verify refresh/deep links work through the SPA rewrite.
- Open `https://admin.olitun.in` and confirm it redirects to `/admin`.
- Sign in as an Appwrite team admin and create or update a draft quiz/category.
- Confirm the Flutter mobile app is built with the same `APPWRITE_ENDPOINT`, `APPWRITE_PROJECT_ID`, and `ADMIN_TEAM_ID`, then verify the admin content change appears after refresh.

## Android Release

- Run `flutter build apk --release` with production dart-defines.
- Install the release APK on a physical device and smoke test onboarding, lesson browsing, quiz, settings, and account flows.

## Legal And Store Readiness

- Confirm `PRIVACY.md`, `TERMS.md`, and in-app Legal links are current.
- Confirm the root `LICENSE` still reflects the intended distribution model.
- Refresh screenshots from the actual release build when UI changes are visible.
