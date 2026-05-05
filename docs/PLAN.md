# Production Readiness Plan

## Goal

Bring Olitun to a production-grade release posture across Flutter Web, Android,
and the Appwrite backend.

## Current Gates

- `flutter analyze` must pass with no issues.
- `flutter test` must pass across unit, widget, repository, router, and
  security-focused tests.
- `flutter build web --release` must pass with real Appwrite dart-defines.
- Android release builds must use the release signing configuration when
  `android/key.properties` is present.
- Appwrite collections and storage buckets must grant public read access only
  where needed, with write/delete restricted to the configured admin Team.

## Release Checklist

- Verify Appwrite project, database, collections, indexes, teams, and buckets
  with `scripts/appwrite_setup.mjs`.
- Seed or import content with `scripts/appwrite_seed.mjs` or
  `scripts/appwrite_import.mjs`.
- Deploy the translator Appwrite Function and pass its execution URL via
  `TRANSLATE_URL`.
- Build web with `APPWRITE_ENDPOINT`, `APPWRITE_PROJECT_ID`, `ADMIN_TEAM_ID`,
  and optional `SENTRY_DSN`.
- Build Android APK/AAB with the same dart-defines and release signing.
- Smoke test onboarding, email auth, Google OAuth redirect, lessons, quizzes,
  progress, admin login, media upload, and translator flows.
