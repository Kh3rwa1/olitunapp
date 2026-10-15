# Contributing to Olitun

Thanks for your interest in improving Olitun.

## Local setup

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=APPWRITE_ENDPOINT=https://<region>.cloud.appwrite.io/v1 \
  --dart-define=APPWRITE_PROJECT_ID=<your-project-id> \
  --dart-define=CLOUDFLARE_API_URL=http://localhost:8787
```

Appwrite is used only for sign-in; all data comes from the Cloudflare Worker
at `CLOUDFLARE_API_URL` (defaults to the deployed Worker). To run the Worker
locally (`wrangler dev`, local D1/R2) see "Local backend" in the
[README](README.md#local-backend-worker). Optional flags are documented in
`lib/core/config/appwrite_config.dart` and `cloudflare_config.dart`.

## Tests

```bash
flutter test --coverage
npm run test:backend          # gate scripts, web headers, build scripts
```

Worker changes (`cloudflare/backend`) must pass Worker CI (`worker-ci.yml`):
typecheck, Worker tests, and `npx wrangler deploy --dry-run`.

Coverage is uploaded to Codecov from `main` only. New features should ship
with at least one test that exercises the happy path and one error path.
Repository-layer tests use `mocktail` to stub the remote data source —
see `test/features/auth/auth_repository_impl_test.dart` for the pattern.

## Static analysis

```bash
flutter analyze --no-fatal-infos
```

Both `flutter test` and `flutter analyze` run in CI on every PR
(`.github/workflows/flutter-ci.yml`). PRs that fail either step will not be merged.

## Commit style

- Keep commits focused; one logical change per commit.
- Reference an issue number in the subject when applicable.
- Do not commit generated files (`*.g.dart`, build artifacts, `node_modules`,
  `.wrangler/`).
