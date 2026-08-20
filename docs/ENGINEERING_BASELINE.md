# Olitun Engineering Baseline (Phase 1)

Date: 2026-08-20
Environment: Flutter 3.35.7 (stable), Dart 3.9.2, Node 22.x
Target Platforms: Android, iOS, Web

## 1. Quality Gates & Checks Baseline

| Check | Command | Baseline Status | Execution Time |
|---|---|---|---|
| **Code Formatting** | `dart format --output=none --set-exit-if-changed .` | 0 changed files (540 total) | ~4.5s |
| **Static Analysis** | `flutter analyze --fatal-infos` | 0 issues found | ~4.6s |
| **Flutter Test Suite** | `flutter test --coverage` | **689 passed, 0 failed, 2 skipped** | ~165s |
| **Smoke Tests** | `flutter test test/smoke` | **6 passed, 0 failed** | ~6.5s |
| **Backend & Function Tests** | `npm test` | **49 passed, 0 failed** | ~0.7s |
| **Gitleaks Scan Test Fixtures**| `node scripts/test_gitleaks_rules.mjs` | **Passed** | ~0.2s |

## 2. Test & Coverage Metrics

- **Total Automated Test Count:** 738 tests (689 Flutter tests + 49 Node backend unit/integration tests).
- **Line Coverage (lcov):** 36.83% across entire application (high density in core auth, payments, permissions, motion, accessibility, quiz engine, and offline storage).
- **Domain/Security-Critical Coverage:** >90% on payment claims, token extraction, permissions invariants, and durable mutation outbox.

## 3. Versioning & Release Alignment

- **pubspec.yaml:** `1.3.0+20`
- **CHANGELOG.md:** `1.3.0` (2026-08-09)
- **Target Single Source of Truth:** `pubspec.yaml` with automated CI verification.

## 4. Initial Architectural Inventory

- **Frontend:** Flutter Material 3 with Riverpod, GoRouter, Hive caching, and JustAudio.
- **Backend:** Appwrite BaaS (sgp cloud) with 20 serverless cloud functions (`functions/`).
- **Offline Strategy:** Hive-backed CacheService with TTL envelopes and dedicated durable MutationOutboxService.
- **Payment Verification:** Serverless two-phase commit on `payment_claims` with cryptographic idempotency keys.
