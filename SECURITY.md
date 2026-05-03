# Security Policy

## Reporting a vulnerability

Email **security@olitun.app** with a description of the issue and reproduction
steps. Please do not file a public GitHub issue for security reports. We aim to
acknowledge within 72 hours.

## Threat model & guarantees

### Admin access

Admin access is gated server-side by membership in the Appwrite Team named
`admins` (or whatever `ADMIN_TEAM_ID` is set to at build time).

- There is **no** client-side admin secret. The previous `ADMIN_SECRET_KEY`
  build flag has been removed because any value bundled into the compiled
  Flutter Web JS or Android APK is trivially extractable and therefore not a
  secret.
- Admin team membership is matched against the team's **immutable Appwrite
  team ID** only. Matching by team name is deliberately not supported,
  because any user with team-create permission could otherwise escalate by
  creating a team named `admins`.
- The `/admin/*` routes are protected by two layers:
  1. The GoRouter redirect awaits `Teams(client).list()` and bounces
     non-members to `/admin/login`.
  2. `AdminShell` re-checks the same provider before rendering, so direct
     widget mounting (tests, deep links) is also gated.
- Every Appwrite collection used by the admin UI is expected to enforce
  Team-based permissions on the server. The Flutter checks are a UX layer
  on top of those permissions, not the security boundary.

### Configuration

The app refuses to boot without `APPWRITE_ENDPOINT` and `APPWRITE_PROJECT_ID`
build flags (`AppwriteConfig.validate`). There are no hardcoded fallback
project IDs in the codebase. The same applies to the translation function URL
(`TRANSLATE_URL`) and the legacy upload endpoint base (`UPLOAD_BASE_URL`,
the only surviving PHP dependency — see `admin-panel/README.md`).

### Translation function

User-submitted text is sent to an Appwrite Function (`functions/translator`)
which proxies Google Translate with per-IP rate limiting (default 20
requests/hour) and a key/value cache. The function never sees Appwrite user
sessions and stores no PII.

### Crash reporting

If `SENTRY_DSN` is provided, crashes are reported to Sentry in release builds
only (`!kDebugMode`). No reports are sent in development. PII scrubbing
follows Sentry SDK defaults; review your project's data scrubbing settings
before enabling in production.

## Supported versions

Only the `main` branch receives security fixes.
