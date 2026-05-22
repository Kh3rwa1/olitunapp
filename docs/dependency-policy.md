# Dependency Policy

Olitun is an application, not a published Dart package, so dependency
resolution must be reproducible for every release build.

## Doctrine

- Commit `pubspec.lock` and treat it as the release source of truth.
- Use conservative `pubspec.yaml` ranges for ordinary packages so security and
  patch updates can be reviewed without churn.
- Pin high-risk platform and backend SDKs exactly when a minor bump can change
  runtime behavior. Current examples: `appwrite` and `shared_preferences`.
- Update dependencies in dedicated `chore(deps): ...` commits or Dependabot PRs.
- Run `flutter pub get`, `flutter analyze`, `flutter test --coverage`, and
  `dart run tool/enforce_coverage.dart --min=65` before merging dependency
  updates.
- Do not upgrade protected translation configuration or payload behavior as
  part of dependency maintenance.

## Review Rules

Dependency PRs should include:

- The reason for the update.
- Any migration notes from the package changelog.
- Test evidence, including coverage status.
- Manual QA notes when the package touches auth, Appwrite, storage, media,
  audio/video, routing, or translation-adjacent UI.
