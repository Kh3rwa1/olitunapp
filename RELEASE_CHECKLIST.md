# Olitun Production Release Checklist

Every release must complete and verify the following gates before distributing artifacts to Google Play, Vercel, or end users.

---

## 1. Pre-Release Verification Gates

- [ ] **Version Alignment:**
  - Verify that `version:` in `pubspec.yaml` matches `CHANGELOG.md` exactly:
    ```bash
    dart run tool/verify_version_consistency.dart
    ```
- [ ] **Static Code Analysis & Architecture Boundaries:**
  - Verify formatting, lint, analysis, and clean architecture boundaries:
    ```bash
    dart format --output=none --set-exit-if-changed .
    flutter analyze --fatal-infos
    dart run custom_lint
    node scripts/check_architecture_boundaries.mjs
    ```
- [ ] **Localization Parity:**
  - Verify 100% key and placeholder parity across all 5 languages (`en`, `bn`, `hi`, `or`, `sat`):
    ```bash
    node scripts/check_l10n_parity.mjs
    ```
- [ ] **Action Pinning Audit:**
  - Ensure all GitHub Actions are pinned to immutable 40-char commit SHAs:
    ```bash
    node scripts/verify_pinned_actions.mjs
    ```
- [ ] **Automated Test Suites:**
  - Flutter unit, widget, golden, accessibility, and performance tests pass:
    ```bash
    flutter test --coverage
    ```
  - Backend Serverless function test suites (translator, santaliVoice, cleanup, delete-account):
    ```bash
    npm run test:backend
    ```
  - Web security & data privacy regression checks:
    ```bash
    node --test test/web/permissions_policy_test.mjs
    node --test test/account_deletion/collection_inventory_test.mjs
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
- [ ] **Environment Secrets & Functions In Place:**
  - `APPWRITE_ENDPOINT`
  - `APPWRITE_PROJECT_ID`
  - `TRANSLATE_URL`
  - `RATE_LIMIT_SALT` (Production HMAC salt)
  - `SARVAM_API_KEY` (AI Studio backend processing)
  - `BODHAN_API_KEY` (Santali Voice synthesis backend)
  - `ANDROID_KEYSTORE_BASE64`
  - `ANDROID_KEY_ALIAS`
  - `ANDROID_KEY_PASSWORD`
  - `ANDROID_STORE_PASSWORD`

---

## 3. Schema & Retention Pruning Readiness

- [ ] **Schema & Permission Verification:**
  - Dry-run verify AI Studio & Voice database collections and storage buckets:
    ```bash
    node scripts/setup_ai_studio.mjs --dry-run
    node scripts/setup_santali_voice.mjs --dry-run
    node scripts/create_review_collection.mjs --verify-only
    ```
- [ ] **Scheduled Pruning Configuration (`cleanupAnalyticsEvents`):**
  - Verify `cleanupAnalyticsEvents` function is deployed with `0 3 * * *` (03:00 UTC) schedule.
  - Confirm function has `files.read` and `files.write` scopes for storage audio cleanup.
  - Verify retention policies:
    - `ai_studio_inputs`: 24-hour retention.
    - `ai_studio_jobs`: 30-day retention.
    - `tts_cache`: 90-day retention + storage file deletion.
    - `voice_claims`: 7-day retention.
    - `learning_analytics_events`: 90-day retention.

---

## 4. Build & Performance Budget Verification

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

## 5. Post-Release Smoke Testing

- [ ] Web application boots cleanly over HTTPS with valid CSP and Permissions-Policy headers (`camera=(self), microphone=(self), geolocation=()`).
- [ ] Offline lesson progression, quiz scoring, and audio playback functional without active network.
- [ ] AI Studio and Santali Voice operations function properly and report honest quota states.
- [ ] Complete account deletion cascade verified against all user-data collections.
