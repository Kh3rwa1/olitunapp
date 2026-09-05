# Olitun Production Hardening Plan

**Date:** 2026-09-05  
**Baseline Git Commit:** `d8ae5aed5567540194b6f09429838ccb0d4f1210`  
**Toolchain:** Flutter 3.35.7 (stable) • Dart 3.9.4 • Node.js v22.22.3  
**Branch:** `fix/premium-content-boundary-20260905`

---

## 1. Priority 0A — Complete Premium Content Security Boundary

### 1.1 Authorized Lesson Retrieval Endpoint
- **Verified Current Behavior:**
  - Client retrieves lesson documents directly via `databases.getDocument('lessons', id)` and `listDocuments('lessons')` using client session (`LessonRemoteDataSourceImpl`).
  - Serialization blocks client publication of premium lessons (`ContentItem.toAppwrite()`), but does not protect reads once document permissions are tightened.
  - If Appwrite document security is enabled without collection-level read grants, non-buyers cannot read protected lessons, but authenticated buyers also cannot read them because no server-side authorized retrieval endpoint exists.
- **Risk / User Impact:**
  - Critical: either premium content remains exposed to any caller (if collection has `read("any")`), or legitimate paying learners are completely locked out of purchased courses (if document security is turned on).
- **Proposed Change:**
  - Implement a new serverless Appwrite function: `getAuthorizedLesson` (`functions/getAuthorizedLesson`).
  - Derive caller identity strictly from Appwrite verified execution context (`x-appwrite-user-id` validated via caller JWT or function session headers; never trust client-supplied userId or `isPremiumUnlocked` flag).
  - Server-side read of lesson and its parent category using admin/server SDK.
  - Decision engine evaluates access:
    1. If category is free (`unlockMode == 'free'`), or lesson is an explicit preview (`previewIndex` or legacy valid order window `order > 0 && order <= previewLessonCount`), return lesson body.
    2. If category requires purchase (`unlockMode == 'paid'`), query `course_purchases` ledger for caller `userId` and `categoryId` with `status == 'verified'`. Deny if missing, refunded, disputed, revoked, or ambiguous.
    3. Return only the requested authorized lesson body. For locked lessons requested by unauthorized users, return metadata with redacted/empty blocks and an explicit `{ "locked": true, "reason": "purchase_required" }` payload.
  - Add client remote data source method `getAuthorizedLesson(lessonId)` calling the function via `functions.createExecution`, preserving offline cached access and failing closed without insecure direct database fallbacks.
- **Acceptance Tests:**
  - Anonymous caller cannot retrieve protected lesson body.
  - Authenticated non-buyer receives locked metadata with no body/blocks.
  - Authenticated buyer with verified purchase receives complete lesson blocks.
  - Buyer with refunded/disputed purchase is denied lesson body.
  - Spoofed user ID or client-side entitlement claim in payload is ignored.
  - Free category lessons and explicit previews remain accessible to all users.
  - Node function unit/integration tests and Flutter client data source tests pass.
- **Dependencies:**
  - `course_purchases` collection with `userId` and `categoryId` index.
- **Deployment / Migration Requirements:**
  - Register `getAuthorizedLesson` in `appwrite.json` and deploy.
  - Client deployed with function invocation support before document security permission lockdown.

---

### 1.2 Private Paid-Media Access & Migration
- **Verified Current Behavior:**
  - Storage buckets (`audio`, `images`, `videos`) have `$permissions: ["read(\"any\")"]` and `fileSecurity: false`. Any direct URL to a paid audio/video asset is accessible publicly on the internet.
- **Risk / User Impact:**
  - Leaks proprietary paid recordings and video lessons; long-lived CDN links can be shared outside the application.
- **Proposed Change:**
  - Create a designated private storage bucket `paid_media` in `appwrite.json` with `fileSecurity: true` and no public `read("any")`.
  - Authorized media delivery: `getAuthorizedLesson` returns short-lived media access tokens / authorized delivery stream URLs generated server-side for authenticated buyers.
  - Safe migration script `scripts/migrate_paid_media_assets.mjs` that runs in dry-run mode by default, copies paid media assets from public buckets to `paid_media`, updates protected lesson block URLs, and leaves public buckets intact for free content.
- **Acceptance Tests:**
  - Public HTTP GET to `paid_media` bucket file without authorization returns 401/403.
  - Authorized user gets time-bounded access URL or proxy payload.
  - Free content in `audio`/`images` continues loading with zero disruption.
- **Dependencies:**
  - Appwrite Storage permissions configuration.
- **Deployment / Migration Requirements:**
  - Create `paid_media` bucket with file security before migrating media links.

---

### 1.3 Preview Policy Determinism
- **Verified Current Behavior:**
  - Legacy check relies on `order > 0 && order <= previewLessonCount`. Duplicate, zero, or edited order numbers can unintentionally expose or hide previews.
- **Risk / User Impact:**
  - Course reorganizations can accidentally leak premium lessons as previews or hide introductory preview lessons.
- **Proposed Change:**
  - Add an explicit `isPreview` boolean attribute and deterministic `previewRank` to lesson models and schemas.
  - Support fallback to legacy order window with strict validation (must be positive integer, deduplicated) and log warnings when legacy fallback is triggered.
  - Audit script to flag anomalous preview orders in existing datasets.
- **Acceptance Tests:**
  - Explicit `isPreview: true` always grants preview status regardless of order.
  - Gapped or duplicate orders with `isPreview: false` are never exposed as previews.
  - Legacy fallback functions correctly for un-migrated datasets.
- **Dependencies:**
  - `lessons` collection schema attribute addition.

---

## 2. Priority 0B — Finish Payments and Dispute Recovery

### 2.1 Server-Authoritative Dispute Reconciliation & Safe Recovery
- **Verified Current Behavior:**
  - PR #257 contained dispute handling by preventing dispute callbacks from writing `status: verified` (`nextState` in `payment_state.js`), protecting against stale/out-of-order dispute webhooks.
  - Client-side manual refund recording was disabled to prevent unsafe unauthenticated ledger mutations.
  - Legitimate won disputes or manual reconciliations currently have no automated or authoritative recovery path without developer database intervention.
- **Risk / User Impact:**
  - A customer who rightfully wins a chargeback or dispute remains permanently locked out without a documented and safe reconciliation mechanism.
  - Support operators cannot safely record verified offline or gateway refunds.
- **Proposed Change:**
  - Implement server-side dispute reconciliation in `functions/reconcilePaymentAttempts` or a dedicated `reconcilePaymentDispute` function:
    - Queries the Razorpay Disputes API (`/v1/disputes/{id}`) using server credentials.
    - Validates gateway dispute status (`won`, `lost`, `under_review`).
    - Only if gateway status is authoritatively `won` and payment is verified and not refunded, updates ledger to `verified` via optimistic transaction with idempotency key and operator audit log.
  - Implement an authenticated server-side admin function `recordAdminRefund`:
    - Checks caller Appwrite team membership (`team:admins`) server-side.
    - Enforces idempotency via `idempotencyKey`.
    - Updates purchase ledger transactionally with before/after audit entry in an `audit_logs` collection.
- **Acceptance Tests:**
  - Dispute won status on gateway correctly restores entitlement via server reconciliation.
  - Dispute lost/under-review status never restores entitlement.
  - Admin refund endpoint rejects non-admin users with 403.
  - Idempotent repeated calls execute once and return identical state without duplicate balance/refund changes.
  - All shared payment code copies remain byte-identical (`scripts/sync_shared_modules.mjs --check`).
- **Dependencies:**
  - Razorpay Disputes API access; Appwrite admin team membership.

---

## 3. Priority 1A — Correct Multi-Device Progress

### 3.1 Concurrency-Safe Deduplicated Progress Aggregation
- **Verified Current Behavior:**
  - `ProfileRepositoryImpl._mergeStats` merges `totalStars` and `totalLearningMinutes` using `math.max(a, b)`.
  - If a user earns +10 stars on Device A and +20 stars on Device B, `max(10, 20)` yields 20 instead of 30, losing 10 stars of legitimate effort.
  - Local stats in `SharedPreferences` use a single static key `user_stats` without scoping to `userId`, risking cross-user contamination on account logout/switch.
  - Streaks are merged with `max(a.currentStreak, b.currentStreak)` rather than evaluated from consecutive activity dates and timezone.
- **Risk / User Impact:**
  - Learner progress lost across phone and tablet/web.
  - Switching accounts on a shared family device leaks or overwrites progress.
  - Artificial or inaccurate streak counts.
- **Proposed Change:**
  - Redesign progress tracking to use **deduplicated learning event logs / delta journals**:
    - Each learning reward / star award generates a unique deterministic event ID: `evt_<userId>_<type>_<sourceId>_<timestamp>`.
    - Store recent event ledger in stats entity/model (capped/compacted with cumulative baseline counter).
    - Merging computes: `mergedStars = baselineStars + deduplicatedEventDeltas`.
    - Starting at 100, independent +10 (event E1) and +20 (event E2) merge to 130; replaying E1 or E2 does not double count.
  - Derive `currentStreak` dynamically from the union of `practiceDates` (`Set<String>` of `YYYY-MM-DD`) evaluated against user's local timezone calendar days, rather than blindly taking the max integer.
  - Scope local storage keys to the authenticated user: `user_stats_${userId}` with an isolated guest key `user_stats_guest`, clearing or migrating guest progress explicitly on login.
- **Acceptance Tests:**
  - Multi-device divergence test: 100 stars + 10 (device A) and + 20 (device B) merges to 130 stars.
  - Event replay idempotency: repeating an existing event ID does not increase stars.
  - Streak derivation: 3 consecutive days in `practiceDates` produces streak 3; a missed day resets streak to 0 or 1 based on today's activity.
  - Account switch: logging out user A and logging in user B loads strictly user B's stats without user A's data.
- **Dependencies:**
  - `UserStatsEntity` and `UserStatsModel` schema expansion with backward compatibility for legacy JSON.

---

## 4. Priority 1B — CI & Release Gate Integrity

### 4.1 Real Pipeline Gates & Coverage Visibility
- **Verified Current Behavior:**
  - `.github/workflows/flutter-ci.yml` uses Flutter `stable` channel without exact revision pinning.
  - Coverage enforcement allows 24 exemptions and selected path thresholds (`--min=70`, `--path-min=/data/:40`).
  - Staging integration tests skip when credentials are missing, which can give a false sense of verification if treated as a pass.
- **Risk / User Impact:**
  - Upstream Flutter breaking changes can break CI unpredictably.
  - Critical security and payment paths could slip below acceptable testing rigor.
- **Proposed Change:**
  - Pin Flutter SDK version to exact verified stable release (`3.35.7`) or specific commit in workflows.
  - Ensure CI separates unit/widget smoke tests from backend journey tests.
  - Require staging workflow to explicitly mark missing credentials as `BLOCKED` / failed gate in release candidate pipelines.
- **Acceptance Tests:**
  - Workflows parse and validate successfully.
  - All static checks (`check_file_length`, `check_typography`, `check_color_literals`, `check_l10n_parity`) continue to pass.

---

## 5. Priority 2 — Accessibility, Localization & Operational Recovery

### 5.1 Accessibility (A11y) & Localization (L10n)
- **Verified Current Behavior:**
  - 100% ARB parity achieved across English, Bengali, Hindi, Odia, and Santali (258 keys).
  - Home content grid accessibility restored in #255.
- **Proposed Enhancements:**
  - Audit lesson reader screens for screen-reader labels, high contrast scaling (200% text), and keyboard navigation focus rings.
  - Check Ol Chiki typography rendering with bundled font fallback across all platforms.
  - Verify error dialogs, empty states, and payment modals announce assistive labels clearly.

### 5.2 Observability & Incident Response
- **Proposed Enhancements:**
  - Structured error logging with zero PII/secret leaks (sanitize payment IDs, tokens, emails).
  - Correlation IDs linking payment attempts to webhook events and entitlement activations.
  - Automated health check / diagnostics runbook in `docs/INCIDENT_RESPONSE.md`.

---

## 6. Execution Milestones & Sequence

1. **Milestone A (Current Focus):** Implement Priority 0A — Authorized Lesson Retrieval Function (`functions/getAuthorizedLesson`), client remote data source integration, and comprehensive negative/positive authorization test suite.
2. **Milestone B:** Implement Priority 1A — Multi-Device Concurrency-Safe Progress (deduplicated event aggregation, streak derivation from dates, user-scoped cache).
3. **Milestone C:** Implement Priority 0B — Payment dispute server reconciliation path and idempotent admin refund interface with audit trail.
4. **Milestone D:** CI and staging health gate improvements; update documentation and validation evidence.
