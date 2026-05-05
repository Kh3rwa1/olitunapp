# Olitun Release Checklist

Use this checklist before every production release.

## Code Quality

- Run `dart format --set-exit-if-changed .`
- Run `flutter analyze --fatal-infos`
- Run `flutter test --coverage`
- Run `flutter test test/smoke`
- Run `flutter test integration_test -d <device-id>` on a real device for release smoke coverage.
- Run `node --check scripts/appwrite_setup.mjs scripts/appwrite_seed.mjs scripts/appwrite_import.mjs functions/translator/src/main.js`
- Run `npm --prefix functions/translator test`

## Appwrite

- Confirm `APPWRITE_ENDPOINT`, `APPWRITE_PROJECT_ID`, `ADMIN_TEAM_ID`, and `TRANSLATE_URL` are set for the target environment.
- Run `scripts/appwrite_setup.mjs` with a server API key after schema or permission changes.
- Confirm `translation_cache` and `rate_limits` have function-only permissions.
- Confirm public collections are read-only for clients and admin writes require the admin team.

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

## Android Release

- Run `flutter build apk --release` with production dart-defines.
- Install the release APK on a physical device and smoke test onboarding, lesson browsing, quiz, settings, and account flows.

## Legal And Store Readiness

- Confirm `PRIVACY.md`, `TERMS.md`, and in-app Legal links are current.
- Confirm the root `LICENSE` still reflects the intended distribution model.
- Refresh screenshots from the actual release build when UI changes are visible.
