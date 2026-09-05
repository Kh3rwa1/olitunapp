# Olitun Security Policy & Threat Model

## 1. Reporting a Vulnerability

Email **security@olitun.app** with a comprehensive description of the issue and reproducible steps. Please do not file public GitHub issues for security vulnerabilities. We acknowledge reports within 72 hours.

---

## 2. Threat Model & Security Guarantees

### A. Admin Authorization & Team Isolation
- Admin access is gated strictly server-side by membership in the immutable Appwrite Team ID `admins` (or configured `ADMIN_TEAM_ID`).
- Client-side bypasses or spoofed roles are structurally impossible because Appwrite collection security rules enforce permissions at the database engine level.
- Client routes (`/admin/*`) use dual enforcement: GoRouter redirects check team membership, and `AdminShell` verifies session validity before rendering.

### B. Cryptographic Identity & Zero-Trust Caller Headers
- The backend serverless functions never trust caller-supplied JSON `userId` fields; the caller identity comes from the Appwrite runtime-injected `x-appwrite-user-id` header (not readable by clients for authenticated executions).
- The `translator` function is a deliberate exception: **translation is free and public**, with deployment-wide request/upstream budgets and a fail-closed resource guard. It keeps JSON/text/language validation, a SHA-256 key/value cache (`translation_cache`), and per-deployment env secrets; resource safeguards are described in docs/PRIORITY_HARDENING_2026_09_05.md.
- Payment functions re-verify every payment amount and order binding against the gateway API and the server-side purchase ledger before granting entitlements.

### C. Translator Service Model
- Free public access does not imply unbounded infrastructure use. Distributed minute budgets reserve atomic Appwrite slots before requests/upstream work.
- Cache hits avoid the upstream budget. Configuration/storage failures fail closed; responses identify temporary saturation without logging submitted text.
- Five consecutive upstream failures open a per-instance 30-second circuit; deployment-wide budgets still bound aggregate work.
- Operators can pause translation with TRANSLATION_ENABLED=false and should alert on budget events and billing. See docs/PRIORITY_HARDENING_2026_09_05.md.

### D. Fail-Closed Production Release Signing
- Android release builds enforce cryptographic signing credentials in `android/app/build.gradle.kts`.
- If `key.properties` is missing, release builds fail with a fatal `GradleException`.
- Debug-signed release artifacts are permitted strictly for CI build verification when `ALLOW_DEBUG_RELEASE_SIGNING=true` is explicitly configured.

### E. Supply Chain Security & Immutable Action Pinning
- 100% of GitHub Actions in `.github/workflows/` are immutably pinned to full 40-character commit SHAs.
- Automated security audits (`scripts/verify_pinned_actions.mjs`) execute in CI Security Gates to prevent dependency poisoning and mutable tag hijacking.

### F. Payments & Purchase Integrity
- Course purchases are verified strictly server-side by `verifyCoursePurchase` using HMAC-SHA256 Razorpay signature validation against backend environment secrets.
- Double-spend and race condition exploits are prevented by unique composite database indexes on `(user_id, category_id)`.
- The incentivized review-for-unlock flow was **removed** from the client (Google Play incentivized-review policy risk). Legacy `play_store_review` entitlement records remain valid server-side; new unlocks are paid only.

### G. Content Security Policy (CSP) & Web Isolation
- **`script-src`:** Restricted strictly to `'self' 'wasm-unsafe-eval'`. Broad `'unsafe-inline'` and `'unsafe-eval'` are completely eliminated. All runtime scripts (boot helpers, PWA install/update flow, auth callback) are externalized files (`web/pwa_runtime.js`, `web/pwa_install.js`, `web/auth_redirect.js`) — no inline scripts exist in any HTML template.
- **`style-src`:** Set to `'self' 'unsafe-inline' https://fonts.googleapis.com` to accommodate Flutter Web engine layout mutations.
- **Additional directives:** `worker-src 'self'` (service worker), `base-uri 'self'`, `object-src 'none'`, `frame-ancestors 'self'`.
- **Host scope:** The CSP in `vercel.json` applies only to the Vercel-hosted deployment. The Appwrite Sites host (`olitunapp.appwrite.network`) applies its own headers — when promoting Appwrite Sites to the primary production host, mirror this CSP there.

---

## 3. Data Redaction & Logging Standards

The codebase uses `RedactionHelper` and `AppLogger` across all platforms:
- Authentication tokens, passwords, JWTs, OAuth codes, payment signatures, and session cookies are scrubbed before logging.
- Telemetry never records raw translation text, student personal data, or network IP addresses.

---

## 4. Supported Versions

Only the `main` branch receives active security updates and vulnerability patches.
