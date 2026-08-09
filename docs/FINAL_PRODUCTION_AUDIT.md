# Final Production Audit

This document records the baseline audit for Olitun on branch `hardening/final-production-10-of-10`.

---

## 1. Audit Metadata

- **Baseline Branch**: `hardening/production-10-of-10`
- **Starting SHA**: `4d8b398727b7effbb5c6f31a1cb690b3f2a4a59f`
- **Target Branch**: `hardening/final-production-10-of-10`
- **Audit Date**: August 9, 2026

---

## 2. Findings Matrix

| Finding ID | Severity | Affected Component / File | Problem Description | Remediation Plan | Verification Command | Final Status |
|---|---|---|---|---|---|:---:|
| **FINDING-01** | P0 (Critical) | `functions/delete-account/src/main.js` | Single-page document listing (max 100 docs) leaves unpurged data for users with >100 records. Invalid storage file listing using unsupported `Query.equal('userId')`. Hardcoded fallback `databaseId = 'main'`. No persistent state machine. Auth user deleted before cleanup finishes. | Implement cursor pagination across all user collections. Introduce `user_assets` ownership registry for storage. Require explicit `APPWRITE_DATABASE_ID`. Implement server-authoritative `deletion_requests` state machine (`requested` -> `in_progress` -> `cleanup_complete` -> `auth_deleted` -> `completed`). | `node --test functions/test/delete_account.test.js` | PENDING |
| **FINDING-02** | P0 (Critical) | `functions/createRazorpayOrder/src/main.js`, `scripts/appwrite_setup.mjs` | Lack of durable `payment_attempts` collection and client idempotency key verification allows concurrent order creation races and double-charging risks under network retries or gateway timeouts. | Introduce `payment_attempts` schema and unique indexes (`userId`, `categoryId`, `idempotencyKey`). Implement server-side lease reservation and gateway timeout reconciliation state (`reconciliation_required`). | `node --test functions/test/payment_functions.test.js` | PENDING |
| **FINDING-03** | P1 (High) | `test/core/api/appwrite_permission_invariants_test.dart` | Permission tests previously asserted on local mock arrays rather than calling public service methods directly. Missing staging integration script. | Refactor permission tests to invoke public `AppwriteDbService` helpers directly. Create `scripts/staging_permission_test.mjs` for multi-user authorization isolation checks. | `flutter test test/core/api/appwrite_permission_invariants_test.dart` & `node scripts/staging_permission_test.mjs --dry-run` | PENDING |
| **FINDING-04** | P1 (High) | `lib/core/payments/purchase_repository.dart` | Entitlement fetch converts server errors into an empty entitlement set (`[]`). Raw exception strings (`$e`) exposed to client UI. Cache not cleared on user logout/switch. | Implement typed `PurchaseResult` state (`verified`, `cached`, `staleCached`, `unauthenticated`, `permissionDenied`, `networkUnavailable`, `serverError`). Preserve last-known-good entitlement cache. Clear cache on logout/user switch. Sanitize error messages. | `flutter test test/core/payments/purchase_repository_test.dart` | PENDING |
| **FINDING-05** | P1 (High) | `test/core/offline/mutation_outbox_test.dart`, `test/core/storage/stale_while_revalidate_test.dart` | Outbox and SWR tests focus primarily on data models rather than end-to-end repository persistence, retry backoff, jitter, deduplication, and user switching. | Expand unit and integration tests to execute actual `MutationOutboxService` and `StaleWhileRevalidateRepository` methods across lifecycle states, Hive persistence restarts, and user switches. | `flutter test test/core/offline/ test/core/storage/` | PENDING |
| **FINDING-06** | P2 (Medium) | `.github/workflows/flutter-ci.yml` | Flutter CI single monolithic job risk of hanging during coverage runs due to unclosed timers or stream listeners. | Split Flutter CI into dedicated, parallel jobs (format, analyze, unit-tests, node-tests, permission-tests, security-scan, web-build, apk-build). Enforce job timeouts and concurrency cancellations. | GitHub Actions Workflow Check | PENDING |
