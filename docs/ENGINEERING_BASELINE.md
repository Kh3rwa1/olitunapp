# Olitun Engineering Baseline & Inventory

**Date:** 2026-08-20  
**Baseline Commit SHA:** `cd132026e23c9dc45a04cad01793616d49e38f0c`  
**Target Branch:** `main`

---

## 1. Toolchain & Runtime Versions

| Component | Version | Details / Architecture |
| :--- | :--- | :--- |
| **Flutter SDK** | `3.35.7` | Channel `stable`, Framework `adc9010625`, Engine `035316565a` |
| **Dart SDK** | `3.9.2` | DevTools `2.48.0` |
| **Node.js** | `v22.22.3` | Modern Node runtime (ESM native) |
| **npm** | `10.9.8` | Package manager |
| **Java JDK** | `17.0.15` | OpenJDK Runtime Environment Homebrew |
| **Appwrite Flutter SDK** | `21.1.0` | `package:appwrite` |
| **Appwrite Node SDK** | `^25.1.0` | `node-appwrite` in `functions/translator/` |
| **App Version** | `1.3.0+20` | Defined in `pubspec.yaml` and `CHANGELOG.md` |

---

## 2. Baseline Verification Measurements

| Metric / Check | Command | Exit Code | Result / Output |
| :--- | :--- | :---: | :--- |
| **Code Formatting** | `dart format --output=none --set-exit-if-changed .` | `0` | Formatted 545 files (0 changed) |
| **Static Analysis** | `flutter analyze --fatal-infos` | `0` | No issues found! (0 errors, 0 warnings) |
| **Flutter Test Suite** | `flutter test --coverage` | `0` | **696 tests passed**, 0 failed |
| **Raw Line Coverage** | Computed from `coverage/lcov.info` | `0` | `12,137 / 32,875` lines (**36.92%**) |
| **Node Function Tests** | `node --test functions/translator/test/*.test.js` | `0` | **9 tests passed**, 0 failed |
| **Service Worker Tests** | `node scripts/patch_service_worker.test.mjs` | `0` | **10 tests passed**, 0 failed |
| **Staging Invariant Tests** | `node scripts/staging_permission_test.test.mjs` | `0` | **2 tests passed**, 0 failed |
| **Gitleaks Rule Tests** | `node scripts/test_gitleaks_rules.mjs` | `0` | **2 tests passed**, 0 failed |
| **Version Drift Test** | `node scripts/verify_release_version.mjs` | `0` | **1 test passed**, 0 failed |
| **Web Release Build** | `flutter build web --release` | `0` | **36 MB** total asset bundle (`build/web`) |

---

## 3. GitHub Actions Workflows Inventory

| Workflow File | Purpose / Trigger | Third-Party Action References |
| :--- | :--- | :--- |
| `.github/workflows/flutter-ci.yml` | Full CI, static analysis, unit/widget tests, builds, release gate | `actions/checkout`, `subosito/flutter-action`, `actions/setup-node`, `actions/upload-artifact`, `actions/download-artifact`, `actions/setup-java` |
| `.github/workflows/security-scan.yml` | Security gate, Gitleaks, OSV scanner, CodeQL SAST | `actions/checkout`, `gitleaks/gitleaks-action`, `subosito/flutter-action`, `google/osv-scanner-action`, `github/codeql-action` |
| `.github/workflows/build-apk.yml` | Android APK release artifact build | `actions/checkout`, `actions/setup-java`, `subosito/flutter-action`, `actions/upload-artifact` |
| `.github/workflows/release-please.yml` | Automated changelog and version release management | `googleapis/release-please-action` |
| `.github/workflows/release-checklist.yml` | Manual / release verification checklist runner | `actions/checkout`, `actions/setup-java`, `subosito/flutter-action`, `actions/upload-artifact`, `actions/download-artifact` |
| `.github/workflows/staging-health.yml` | Staging environment health and permission checks | `actions/checkout`, `subosito/flutter-action` |

---

## 4. Architectural Baseline & Identified Gaps

1. **Phase 1 (Atomic Rate Limiting):** The rate limiter currently uses `listDocuments` followed by `createDocument` / `updateDocument`. Under high concurrency, simultaneous requests can interleave and bypass quotas. Needs compare-and-swap (CAS) with revision checks or atomic increment with bounded retries and fail-closed behavior.
2. **Phase 2 (Cryptographically Verified Identity):** The translator endpoint accepted `x-appwrite-user-id` header or body parameters without verifying cryptographically via Appwrite session / JWT. Needs explicit cryptographic validation via Appwrite `Account.get()` / JWT context, domain-separated HMAC identifiers (`translator-rate-limit:user:v1:`, `translator-rate-limit:network:v1:`), and mandatory `RATE_LIMIT_SALT` in production.
3. **Phase 3 (True Stale-While-Revalidate):** Lesson repository was network-first with offline fallback. Needs immediate cache-first SWR with background revalidation, deduplicated refresh operations, atomic cache updates, and typed content states.
4. **Phase 4 (Real Integration & E2E CI):** Integration tests need reliable web and Android verification pipelines integrated with the Release Gate.
5. **Phase 5 (Fail-Closed Release Signing):** `android/app/build.gradle.kts` lacked fail-closed enforcement for missing signing credentials in production mode. Needs explicit `ALLOW_DEBUG_RELEASE_SIGNING=true` requirement for CI verification mode.
6. **Phase 6 (Immutable GitHub Action Pinning):** Workflows used mutable tags (`@v4`, `@v5`, `@v2`). Needs 40-character full commit SHAs and an automated pinning verification script.
7. **Phase 7 (Privacy & Data Retention):** Transparent disclosures in `SECURITY.md`, `PRIVACY.md`, and `docs/DATA_RETENTION.md` regarding translation caching, rate limiting hashes, and retention cycles.
8. **Phase 8-10 (Documentation & Accessibility):** Evidence-linked scorecard in `docs/PRODUCTION_READINESS_REPORT.md` and automated accessibility test suite.
