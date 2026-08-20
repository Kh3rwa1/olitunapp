# Olitun Production Release Checklist

Every release must complete and verify the following gates before distributing artifacts to Google Play, Vercel, or end users.

---

## 1. Pre-Release Verification Gates

- [ ] **Version Alignment:**
  - Verify that `version:` in `pubspec.yaml` matches `CHANGELOG.md` exactly:
    ```bash
    dart run tool/verify_version_consistency.dart
    ```
- [ ] **Static Code Analysis:**
  - Verify formatting and static analysis with zero fatal warnings or infos:
    ```bash
    dart format --output=none --set-exit-if-changed .
    flutter analyze --fatal-infos
    ```
- [ ] **Action Pinning Audit:**
  - Ensure all GitHub Actions are pinned to immutable 40-char commit SHAs:
    ```bash
    node scripts/verify_pinned_actions.mjs
    ```
- [ ] **Automated Test Suites:**
  - Flutter unit, widget, golden, and performance tests pass (690+ tests):
    ```bash
    flutter test --coverage
    ```
  - Backend Serverless function tests pass:
    ```bash
    node --test functions/translator/test/*.test.js
    ```
  - Staging and service worker invariant tests pass:
    ```bash
    node scripts/patch_service_worker.test.mjs
    node scripts/staging_permission_test.test.mjs
    ```

---

## 2. Security & Secrets Verification

- [ ] **Gitleaks Secret Scan:**
  - Zero hardcoded API keys, JWTs, private keys, or passwords in Git history:
    ```bash
    node scripts/test_gitleaks_rules.mjs
    ```
- [ ] **Fail-Closed Release Signing:**
  - Verify that `android/key.properties` contains valid release upload credentials.
  - Verify that building without release credentials fails closed with `GradleException`.
- [ ] **Environment Secrets In Place:**
  - `APPWRITE_ENDPOINT`
  - `APPWRITE_PROJECT_ID`
  - `TRANSLATE_URL`
  - `RATE_LIMIT_SALT` (Production HMAC salt)
  - `ANDROID_KEYSTORE_BASE64`
  - `ANDROID_KEY_ALIAS`
  - `ANDROID_KEY_PASSWORD`
  - `ANDROID_STORE_PASSWORD`

---

## 3. Build & Performance Budget Verification

- [ ] **Web Release Build:**
  - Build optimized release web bundle and verify size budget:
    ```bash
    flutter build web --release
    node scripts/patch_service_worker.mjs
    node scripts/verify_service_worker_patch.mjs
    dart run tool/check_size_budget.dart --path=build/web --budget-key=webBuildBytes
    ```
- [ ] **Android APK / AAB Build:**
  - Build release artifact and verify size budget:
    ```bash
    flutter build apk --release
    dart run tool/check_size_budget.dart --path=build/app/outputs/flutter-apk/app-release.apk --budget-key=apkReleaseBytes
    ```

---

## 4. Post-Release Smoke Testing

- [ ] Web application boots cleanly over HTTPS with valid CSP headers.
- [ ] Offline lesson progression, quiz scoring, and audio playback functional without active network.
- [ ] Translation features operate within quota and respect privacy disclaimers.
- [ ] Account deletion and cache purging work as expected.
