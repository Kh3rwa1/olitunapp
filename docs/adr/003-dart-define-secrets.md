# ADR-003: Build-time Secret Injection via --dart-define

**Status:** Accepted
**Date:** 2026-04-20

## Context

The app requires configuration values that vary between environments: Appwrite endpoint, project ID, admin secret key, and translation API URLs. Early versions hardcoded these in source files, creating security risks and making multi-environment builds impossible.

## Decision

Inject all environment-specific values at **build time** using `--dart-define` flags:

```bash
flutter run \
  --dart-define=APPWRITE_ENDPOINT=https://sgp.cloud.appwrite.io/v1 \
  --dart-define=APPWRITE_PROJECT_ID=<id> \
  --dart-define=ADMIN_SECRET_KEY=<key>
```

Values are accessed via `String.fromEnvironment()` / `bool.fromEnvironment()` in Dart, which are resolved at compile time and tree-shaken into the binary.

A local `run.sh` script (gitignored) wraps these flags for developer convenience.

## Consequences

- ✅ Zero secrets in source control
- ✅ Same codebase builds for dev, staging, and production
- ✅ CI/CD can inject values via environment variables
- ✅ `run.sh` is gitignored — each developer manages their own
- ⚠️ Every build command must include all `--dart-define` flags
- ⚠️ `String.fromEnvironment` is compile-time only — cannot change at runtime
