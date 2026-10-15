# Olitun Production Release Checklist

Every release must complete and verify the following gates before distributing artifacts to Google Play, the web, or end users.

## 0. How releases ship

| Component | Path to production |
| --- | --- |
| Worker (`cloudflare/backend`) | Merge to `main` → `deploy-worker.yml` runs Worker CI (`worker-ci.yml`), applies `schema.sql` to D1, uploads a version, smoke-tests it, then promotes it. |
| Web | Merge to `main` → `deploy-web.yml` runs `scripts/build_web.sh` and deploys `build/web` to Cloudflare Pages (`olitunapp`). |
| Android (Play) | `scripts/build_playstore_bundle.sh` builds the signed `.aab` locally; upload to Play Console. |
| Tag | `release-checklist.yml` (manual) checks CI + security for the commit, runs the backend health check (`staging-health.yml`), builds web + APK, then tags `v<version>`; `build-apk.yml` builds the signed APK for the tag. |

Deploy the Worker before (or with) any app release that calls new routes.

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
  - Node tests: gate scripts, `web/_headers` CSP/Permissions-Policy, build scripts, service-worker patch:
    ```bash
    npm run test:backend
    ```
  - Worker CI green for the commit (typecheck, Worker tests, dry-run deploy):
    ```bash
    cd cloudflare/backend && npm ci && npx wrangler deploy --dry-run
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
- [ ] **Worker secrets in place** (`npx wrangler secret list` in `cloudflare/backend`):
  - `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET`
  - `MEDIA_SIGNING_SECRET` (paid media URLs)
  - `BODHAN_API_KEYS` (Santali Voice), `SARVAM_API_KEY` (AI Studio)
  - `APPWRITE_API_KEY` (users.write; account deletion only), `CRON_SECRET`
- [ ] **GitHub secrets in place:**
  - `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID` (Pages/Worker deploys)
  - `ANDROID_KEYSTORE_BASE64`
  - `ANDROID_KEY_ALIAS`
  - `ANDROID_KEY_PASSWORD`
  - `ANDROID_STORE_PASSWORD`

---

## 3. Schema & Retention Readiness

- [ ] **D1 schema:** `cloudflare/backend/schema.sql` changes are additive and idempotent (`CREATE ... IF NOT EXISTS`); `deploy-worker.yml` applies it before the new version takes traffic.
- [ ] **Media:** new public media is uploaded through the admin media screen (R2); paid media stays under `paid_media/`.
- [ ] **Maintenance jobs:** `/api/v1/analytics/aggregate` and `/api/v1/analytics/cleanup` (90-day raw analytics retention) are admin-only, or called by a scheduler presenting `CRON_SECRET`.
- [ ] **Workers Logs:** enabled in `wrangler.json`; check the new version's logs after promotion.

---

## 4. Build & Performance Budget Verification

- [ ] **Web Release Build:**
  - Build optimized release web bundle and verify size budget:
    ```bash
    APPWRITE_ENDPOINT=https://sgp.cloud.appwrite.io/v1 APPWRITE_PROJECT_ID=<project-id> \
      bash scripts/build_web.sh
    dart run tool/check_size_budget.dart --path=build/web --budget-key=webBuildBytes
    ```
- [ ] **Android APK / AAB Build:**
  - Build the Play bundle (`scripts/build_playstore_bundle.sh`) and/or a release APK, and verify size budget:
    ```bash
    bash scripts/build_playstore_bundle.sh
    flutter build apk --release --dart-define=APP_ENV=production \
      --dart-define=APPWRITE_ENDPOINT=... --dart-define=APPWRITE_PROJECT_ID=... \
      --dart-define=CLOUDFLARE_API_URL=https://olitun.in
    dart run tool/check_size_budget.dart --path=build/app/outputs/flutter-apk/app-release.apk --budget-key=apkReleaseBytes
    ```

---

## 5. Post-Release Smoke Testing

- [ ] Web application boots cleanly over HTTPS with valid CSP and Permissions-Policy headers (`camera=(self), microphone=(self), geolocation=()`).
- [ ] Offline lesson progression, quiz scoring, and audio playback functional without active network.
- [ ] AI Studio and Santali Voice operations function properly and report honest quota states.
- [ ] Account deletion removes the user's D1 rows and R2 objects and the Appwrite login (`POST /api/v1/user/delete`).
- [ ] Worker `/health` answers `ok` and Workers Logs show no new error spike.

---

## 6. Candidate-SHA Evidence

PR CI is deterministic and credential-free; it never proves live payments,
TTS, or real-device behavior. A skipped live check is recorded as NOT
VERIFIED, never as passed.

- [ ] Flutter CI, Security Scan and Worker CI passed for the exact candidate SHA.
- [ ] Backend health check (`staging-health.yml`) passed: Worker `/health`, a D1 content read, Appwrite auth reachable.
- [ ] Recorded: source SHA, artifact checksums, lockfiles, Worker version id, web deployment URL, mobile signing, web security headers, rollback version.
- [ ] Manual journeys on a real device: guest/offline/kill/restart, sign-in + account switch, review sync convergence, Razorpay test capture + refund, TTS provider failure and quota, account deletion, CSP/service-worker, notifications, ad consent.
- [ ] Razorpay evidence (test mode) linked to the candidate SHA; no production credentials touched.
- [ ] Rollback plan: previous Worker version (`wrangler rollback`), previous Pages deployment, previous Play release; review snapshot/ledger compatibility per `docs/architecture/review_persistence_and_sync.md`.
