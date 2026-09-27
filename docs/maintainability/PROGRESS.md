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

### Owner Decisions Recorded
- **`SecureHttpOverrides` + `ALLOW_SELF_SIGNED`**: **DELETE** approved (no self-signed dev flow exists). Scheduled for Phase 1.
- **Phase 2 Web Build in GitHub Actions**: **APPROVED**. Build Flutter web in CI and deploy pre-built artifacts to unblock capped dependencies.
- **Application ID & Security Email**: Awaiting confirmation on published Google Play ID and contact mailbox.

---

## Phase 0 Completion & Sign-Off Checklist
- [x] Dart LOC & layer distribution measured
- [x] 20 largest files and >500 line files tracked
- [x] Flutter unit, widget, and coverage measured
- [x] Appwrite functions test coverage and untested function list compiled
- [x] Hardcoded strings baseline & CI wiring status confirmed
- [x] Direct dependencies and builder caps documented
- [x] `node-appwrite` version fragmentation mapped
- [x] 29 open Dependabot PRs triaged by ecosystem and risk
- [x] Riverpod usage census compiled
- [x] Repository and git history bloat identified
- [x] 13 CI gate scripts and `custom_lint` verified
- [x] `BASELINE.md` committed and verified
- [x] PR #410 merged to `main`

---

## Phase 1 — Quick Wins & Critical Fixes

### 1. Checkout Lockout Hotfix (`PROTECTED`)
- **Server Fix (`PR #411`, branch `fix/checkout-lockout-server-hotfix`)**:
  - Implemented recovery logic for payment attempts stuck in `status: 'failed'` or stale `in_progress` (>30s) with `providerOrderId: null`.
  - Named constants defined: `LEASE_DURATION_MS = 30000` and `STALE_RESERVATION_TIMEOUT_MS = 30000` (derived from 2x 12s gateway network timeout and 15s function budget).
  - Concurrency safe: pre-check on document state, candidate lease owner election, 10ms settling delay, and verification read before proceeding to Razorpay API.
  - Marked attempt as `failed` on rate-limit ceiling (429) to prevent permanent lockout after window reset.
  - Expanded test suite `functions/test/create_razorpay_order.test.js` with tests 8a–8e covering 5xx retry, stale recovery, active lease 409 rejection, rate limit recovery, and 20 simultaneous concurrent retries creating exactly one Razorpay order.
  - Deployment note included with Appwrite CLI deploy command and query to audit stuck attempts in production.
- **Client Fix (`fix/client-checkout-idempotency`)**:
  - In `lib/shared/widgets/paywall_bottom_sheet.dart`, generate a UUID v4 `_idempotencyKey` on sheet mount.
  - Pass `idempotencyKey: _idempotencyKey` to `createRazorpayOrder`.
  - Transient retries of the same intent (tapping button again on same sheet) reuse the same `_idempotencyKey`.
  - Opening a fresh bottom sheet generates a new UUID.
  - Added comprehensive `functions/createRazorpayOrder/README.md` documenting the idempotency contract, state machine, and concurrency rules.
  - Added widget tests in `test/shared/widgets/paywall/paywall_bottom_sheet_test.dart` verifying intent-scoped key lifecycle.

