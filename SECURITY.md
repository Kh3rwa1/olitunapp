# Security Policy

## Reporting a vulnerability

Email **security@olitun.app** with a description of the issue and reproduction
steps. Please do not file a public GitHub issue for security reports. We aim to
acknowledge within 72 hours.

## Threat model & guarantees

### Admin access

Admin access is gated server-side by membership in the Appwrite Team named
`admins` (or whatever `ADMIN_TEAM_ID` is set to at build time).

- There is **no** client-side admin secret. The previous admin-secret
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
- The Appwrite provisioning script grants public read access to learning
  content, but create/update/delete permissions only to the configured admin
  Team. Translator support collections are created without client permissions
  and are accessed only by the Appwrite Function server key.
- The Flutter checks are a UX layer on top of those permissions, not the
  security boundary.

### Configuration

The app refuses to boot without `APPWRITE_ENDPOINT` and `APPWRITE_PROJECT_ID`
build flags (`AppwriteConfig.validate`). There are no hardcoded fallback
project IDs in the codebase. The same applies to the translation function URL
(`TRANSLATE_URL`). Media uploads go directly to Appwrite Storage buckets through
the Appwrite SDK.

### Translation function

User-submitted text is sent to an Appwrite Function (`functions/translator`) which proxies translation requests through a pluggable provider interface (`TranslationProvider`) with strict privacy protections:
- **Privacy-Preserving Rate Limiting:** Primary limiting uses authenticated `userId`. Unauthenticated requests derive a one-way HMAC-SHA256 hash using a server-side salt (`RATE_LIMIT_SALT`). Raw IP addresses are **never** stored in the database or written to logs.
- **Tiered Multi-Window Limits:** Enforces both short burst limits (1-minute window) and sustained limits (1-hour window) with a fail-closed security policy.
- **Cryptographic Cache Keys:** Responses are cached under deterministic SHA-256 hashes of the normalized request parameters, preventing plaintext database storage of user queries.
- **Input Validation:** Enforces strict 5000-character payload limits and explicit supported language code allowlists.

### Crash reporting

If `SENTRY_DSN` is provided, crashes are reported to Sentry in release builds
only (`!kDebugMode`). No reports are sent in development. PII scrubbing
follows Sentry SDK defaults; review your project's data scrubbing settings
before enabling in production.

### Backups & Data Integrity

- Core curriculum and configuration content (categories, lessons, quizzes, etc.) are automatically backed up weekly via a scheduled Appwrite Function (`functions/backupCollections`).
- Backups are stored as versioned JSON schemas in the `admin_backups` storage bucket.
- Retention is capped at the last 12 backups to conserve storage.
- Storage bucket access is restricted exclusively to members of the `admins` team.

### Payments & Review Unlocks

- **Server-Side Verification:** Course purchases are verified strictly server-side using the `verifyCoursePurchase` Appwrite Function. The Razorpay HMAC-SHA256 signature (`razorpay_signature`) is calculated and matched against the secret key in the function environment. No client-side payment confirmation is trusted.
- **Race Condition Prevention:** The `course_purchases` collection enforces a unique dual-attribute index on `user_id` + `category_id`. This prevents race conditions and double-unlock exploits from duplicate payment payloads.
- **One-Review-Per-User Enforcement:** Play Store review unlocks are capped at a maximum of one course per user. The verification function queries the database to confirm that the user has not previously redeemed a review-unlock transaction.
- **Secure Purchases Collection:** The `course_purchases` collection has zero public client permissions. Direct document creation is forbidden. Document read access is explicitly restricted on a per-document basis: the verification function creates documents with read permissions granted only to the owning user (`Permission.read(Role.user(userId))`), preventing cross-user data leakage.

## Supported versions

Only the `main` branch receives security fixes.

### TLS / self-signed certificates

Self-signed Appwrite certificates are disabled by default. Only enable them for local/self-hosted development with:

```bash
--dart-define=ALLOW_SELF_SIGNED=true
```

Production builds should keep this unset or false.

### Content Security Policy (CSP) & Web Engine Compatibility

The web application Content Security Policy is defined in `vercel.json`:
- **`script-src`:** Restricted to `'self' 'wasm-unsafe-eval'`. Broad `'unsafe-inline'` and `'unsafe-eval'` are completely eliminated to prevent XSS script injection. `'wasm-unsafe-eval'` is permitted strictly for Flutter Web WebAssembly module initialization.
- **`style-src`:** Set to `'self' 'unsafe-inline' https://fonts.googleapis.com`. The Flutter Web engine dynamically mutates element inline styles (`flt-glass-pane`, layout metrics) and injects `<style>` blocks for text layout and Google Fonts rendering. `'unsafe-inline'` is retained narrowly for CSS styling as required by Flutter Web engine architecture.

### Credential Revocation & Coordinated Git History Sanitization Protocol

Whenever credential material (such as session secrets or cookie files) is exposed:
1. **Server-Side Revocation (Immediate):**
   - Compromised sessions or keys must be invalidated on the Appwrite backend immediately via Appwrite Admin Console or API. Removing files from current branch HEAD does not terminate active sessions on the server.
2. **Coordinated Git History Sanitization:**
   - Removing files from the latest commit does not purge historical Git commit objects.
   - Run `git-filter-repo` across all branches and tags to completely scrub sensitive paths (e.g., `cookies.txt`):
     ```bash
     git-filter-repo --invert-paths --path cookies.txt
     ```
   - Coordinate force-pushes across all remotes and branches (`git push origin --force --all`).
