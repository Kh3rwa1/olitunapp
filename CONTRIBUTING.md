# Contributing to Olitun

Thanks for your interest in improving Olitun.

## Local setup

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=APPWRITE_ENDPOINT=https://<region>.cloud.appwrite.io/v1 \
  --dart-define=APPWRITE_PROJECT_ID=<your-project-id>
```

The app **will not boot** without those two `--dart-define` values. See
`lib/core/config/appwrite_config.dart` for the full list of optional flags
(admin team, translator URL, Sentry DSN, etc.).

## Tests

```bash
flutter test --coverage
```

Coverage is uploaded to Codecov from `main` only. New features should ship
with at least one test that exercises the happy path and one error path.
Repository-layer tests use `mocktail` to stub the remote data source —
see `test/features/auth/auth_repository_impl_test.dart` for the pattern.

## Static analysis

```bash
flutter analyze --no-fatal-infos
```

Both `flutter test` and `flutter analyze` run in CI on every PR
(`.github/workflows/ci.yml`). PRs that fail either step will not be merged.

## Commit style

- Keep commits focused; one logical change per commit.
- Reference an issue number in the subject when applicable.
- Do not commit generated files (`*.g.dart`, build artifacts) other than
  `build/web/` for hosted previews.
