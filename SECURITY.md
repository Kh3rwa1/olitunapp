# Olitun Security Policy & Threat Model

## 1. Reporting a Vulnerability

Email **security@olitun.app** with a comprehensive description of the issue and reproducible steps. Please do not file public GitHub issues for security vulnerabilities. We acknowledge reports within 72 hours.

---

## 2. Threat Model & Security Guarantees

### A. Admin Authorization & Team Isolation
- Admin access is enforced by the Cloudflare Worker (`requireAdmin` on `/api/v1/admin/*` and the maintenance routes): the caller's Appwrite JWT must belong to a member of the Appwrite Team whose immutable **ID** is `ADMIN_TEAM_ID` (default `admins`). A self-created team that is merely *named* "admins" grants nothing.
- Scheduled maintenance callers may instead present `CRON_SECRET` in `x-cron-secret` (constant-time comparison).
- Client routes (`/admin/*`) use dual enforcement for UX — GoRouter redirects check team membership and `AdminShell` re-checks before rendering — but the Worker is the authority.

### B. Identity: Appwrite JWT Verified at the Edge
- Appwrite is used only for sign-in (account, sessions, OAuth, JWT, Teams). All data lives in Cloudflare D1/R2 behind the Worker.
- Every per-user route takes the user id only from the verified JWT: the Worker calls Appwrite `GET /account` with the presented token (cached per isolate for 5 minutes, keyed by a SHA-256 of the token). Client-supplied `userId` fields, headers or query parameters are never trusted.
- If Appwrite cannot be reached the Worker answers `503 AUTH_UNAVAILABLE`; it never falls back to an unauthenticated identity.
- `scripts/check_appwrite_auth_only.mjs` fails CI if `lib/` uses any Appwrite API beyond authentication.

### C. Paid AI, Translation & Voice
- Translation, voice synthesis, audio generation and AI Studio routes require a signed-in user and are rate limited per user and per IP (`AI_USER_LIMITER`, `AI_IP_LIMITER`).
- Provider keys (Bodhan, Sarvam, Razorpay) are Worker secrets (`wrangler secret put`), never shipped in the app. Bodhan keys rotate round-robin with failing keys parked (`src/key_rotation.ts`; state is keyed by a hash of each key).

### D. Fail-Closed Production Release Signing
- Android release builds enforce cryptographic signing credentials in `android/app/build.gradle.kts`.
- If `key.properties` is missing, release builds fail with a fatal `GradleException`.
- Debug-signed release artifacts are permitted strictly for CI build verification when `ALLOW_DEBUG_RELEASE_SIGNING=true` is explicitly configured.

### E. Supply Chain Security & Immutable Action Pinning
- 100% of GitHub Actions in `.github/workflows/` are immutably pinned to full 40-character commit SHAs.
- Automated security audits (`scripts/verify_pinned_actions.mjs`) execute in CI Security Gates to prevent dependency poisoning and mutable tag hijacking.

### F. Payments & Purchase Integrity
- Orders are created server-side with the price from D1; `/api/v1/payments/verify` checks the Razorpay HMAC-SHA256 signature with the Worker secret and re-fetches the payment from Razorpay, requiring the amount, currency and order binding to match the stored order before granting an entitlement.
- Webhooks (`/api/v1/payments/webhook`) are accepted only with a valid `x-razorpay-signature`.
- Paid lesson media in R2 (`paid_media/`) is never public: `/api/v1/lessons/authorize` checks entitlement and the lesson-file association, then returns a short-lived URL signed with `MEDIA_SIGNING_SECRET`.
- The incentivized review-for-unlock flow was **removed** from the client (Google Play incentivized-review policy risk). Legacy `play_store_review` entitlement records remain valid server-side; new unlocks are paid only.

### G. Content Security Policy (CSP) & Web Permissions Policy
The web app is served by Cloudflare Pages (proxied at `olitun.in` by the Worker). Headers live in `web/_headers`, copied into `build/web` by `scripts/build_web.sh`, and are checked by `test/web/csp_policy_test.mjs`.
- **`script-src`:** Restricted strictly to `'self' 'wasm-unsafe-eval' https://checkout.razorpay.com`. Broad `'unsafe-inline'` and `'unsafe-eval'` are completely eliminated. All runtime scripts (boot helpers, PWA install/update flow, auth callback) are externalized files (`web/pwa_runtime.js`, `web/pwa_install.js`, `web/auth_redirect.js`).
- **`style-src`:** Set to `'self' 'unsafe-inline' https://fonts.googleapis.com` to accommodate Flutter Web engine layout mutations.
- **`font-src`:** Set to `'self' https://fonts.gstatic.com`.
- **`img-src`:** `'self' data: blob: https://olitun.in https://olitun-api.dulalkisku0.workers.dev https://sgp.cloud.appwrite.io https://*.razorpay.com`.
- **`media-src`:** `'self' blob: https://olitun.in https://olitun-api.dulalkisku0.workers.dev https://sgp.cloud.appwrite.io` (R2 media through the Worker; Appwrite only for the Worker's redirect of files not yet copied to R2).
- **`connect-src`:** `'self' https://olitun.in https://olitun-api.dulalkisku0.workers.dev https://sgp.cloud.appwrite.io https://*.sentry.io https://*.ingest.sentry.io https://*.ingest.us.sentry.io https://api.razorpay.com`.
- **`frame-src`:** Restricted to `'self' https://api.razorpay.com https://checkout.razorpay.com` for verified checkout modals.
- **Additional directives:** `worker-src 'self'` (service worker), `base-uri 'self'`, `object-src 'none'`, `frame-ancestors 'self'`.
- **`Permissions-Policy`:** Set strictly to `camera=(self), microphone=(self), geolocation=()`. Camera and microphone access are allowed solely for the same origin to power in-app voice recording and OCR scanning in AI Studio without allowing third-party origin delegation. Geolocation remains globally disabled `()`.
- Also set on every path: `X-Content-Type-Options: nosniff`, `X-Frame-Options: SAMEORIGIN`, `Strict-Transport-Security`, `Referrer-Policy: strict-origin-when-cross-origin`.

---

## 3. Data Redaction & Logging Standards

The codebase uses `RedactionHelper` and `AppLogger` across all platforms:
- Authentication tokens, passwords, JWTs, OAuth codes, payment signatures, and session cookies are scrubbed before logging.
- Telemetry never records raw translation text, student personal data, or network IP addresses.

---

## 4. Supported Versions

Only the `main` branch receives active security updates and vulnerability patches.
