# Maintainability Initiative Progress Log

Running log of work completed, verified findings, architectural decisions, skipped items, and owner questions.

---

## Phase 0 — Baseline & Forensic Audit

### Completed Actions
1. **Measured Comprehensive Baseline Metrics**:
   - Analyzed Dart LOC across all 18 features and 3 foundation layers (`core`, `shared`, `app`). Total: 775 Dart files, 156,924 LOC.
   - Identified the 20 largest files and tracked all 56 files > 500 lines against the 600-line limit.
   - Executed full test suites (`flutter test --coverage`, `npm run test:backend`) and measured line coverage by layer and per Appwrite function.
   - Audited the hardcoded strings gate, finding 1 stale baseline entry and 2 ungrandfathered violations.
   - Audited all direct/dev dependencies in `pubspec.yaml` and each `functions/*/package.json`, recording locked versions, latest versions, and existing builder caps.
   - Mapped `node-appwrite` versions across all 25 serverless functions (revealing 6 distinct major versions).
   - Grouped all 29 open Dependabot PRs by ecosystem and risk tier.
   - Conducted Riverpod usage census (3 `StateNotifierProvider`, 29 `StateProvider`, 0 `ChangeNotifierProvider`).
   - Analyzed repository size contributors in working tree (11 GB with build artifacts) and git history (~420 MB of old build caches).
   - Audited analyzer issues (0 errors/warnings) and lint ignores (31 in `lib/`, 21 in `test/`).
2. **Produced Canonical Baseline Document**:
   - Committed `docs/maintainability/BASELINE.md`.

### Verified Findings
- **Checkout Lockout (Finding 1)**: `functions/createRazorpayOrder/src/main.js:238` permanently blocks retries on failed/timed-out checkout attempts with 409 `reservation_conflict` because `failed` status has no recovery or re-reservation branch. Furthermore, the Flutter client `paywall_bottom_sheet.dart` passes no idempotency key, falling back to the single default key `${userId}:${categoryId}:checkout_default`.
- **Fail-Closed Secrets (Finding 2)**: `RATE_LIMIT_SALT` in `bintiWaitlist` and `createRazorpayOrder` falls back to `'olitun-dev-salt-do-not-use-in-production'`.
- **SecureHttpOverrides (Finding 3)**: `ALLOW_SELF_SIGNED=true` merely prints a message without modifying `HttpOverrides`, and `SecureHttpOverrides` only returns `false` (default behavior).
- **Stale `adminAuthProvider` (Finding 4)**: `adminAuthProvider` is not `autoDispose` and does not watch session/auth state; sign-out or account switch leaves cached `true`.
- **Security Contact Email (Finding 5)**: `SECURITY.md` specifies `security@olitun.app` while website is `olitun.in`.
- **Side Effects in `quiz_screen.dart`**: Starts quiz session and triggers audio inside `build()` via `whenData`.
- **Untested Functions**: 6 functions have 0 tests, including `manageAdminAccess` (a protected zone).

### Skipped / Clarified Findings
- **Shared Function Drift Check**: Finding stated that a sync or CI drift check was needed. Verification revealed `scripts/sync_shared_modules.mjs` and a `--check` gate in `npm run test:backend` **already exist** for 9 functions, but 16 functions are currently omitted from `functions/_shared/manifest.json`.

---

## Open Questions for the Owner

1. **Google Play Package & Application ID**:
   - In `android/app/build.gradle.kts`, `applicationId = "com.ol.itun"` has the Flutter template comment `// TODO: Specify your own unique Application ID`. Is `com.ol.itun` already the live, published production Application ID on Google Play?
2. **Security Vulnerability Reporting Address**:
   - `SECURITY.md` currently lists `security@olitun.app`, while the website and domain are `olitun.in`. Is `security@olitun.app` configured to receive emails, or should it be updated to `security@olitun.in`?
3. **`SecureHttpOverrides` Removal**:
   - `lib/core/network/secure_http_overrides.dart` provides no functional certificate override beyond platform defaults. Is there any active on-premise or local self-signed Appwrite testing environment that requires an override, or can this file and the `ALLOW_SELF_SIGNED` flag be completely deleted?
4. **Historical Git History Cleanup**:
   - Git history contains ~420 MB of cached `.dill` build files and release archives (`build_web_*.zip`, `mapping.txt`). `scripts/clean_history_remove_build_artifacts.sh` exists to purge them. Does the owner approve rewriting history on non-release branches or using Git LFS for remaining large media assets?
5. **Flutter Web Build Strategy (Phase 2 Pre-approval)**:
   - Several major packages (`lottie`, `image_picker`, `path_provider`, `record`) are capped strictly because the Appwrite Sites builder runtime is pinned to Flutter 3.35. We recommend switching to building Flutter Web in GitHub Actions with a single pinned version and deploying the pre-built web artifact. Does the owner approve this architectural shift?
