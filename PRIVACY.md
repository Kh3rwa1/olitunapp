# Olitun Privacy Policy

**Last updated:** August 20, 2026

Olitun is an educational platform for learning Ol Chiki and Santali language and culture. This privacy policy transparently details how data is handled across our offline-first Flutter application, backend serverless functions, and persistence layers.

---

## 1. Data Collection & Purpose

| Data Category | Purpose | Storage Location | Retention / Deletion Policy |
| :--- | :--- | :--- | :--- |
| **Account Credentials** | Sign-in, session maintenance, cross-device sync | Appwrite Auth | Purged immediately upon account deletion. |
| **Learning Progress & Streaks** | Offline lesson tracking, quiz scores, mistake reviews | Local Hive Storage & Appwrite DB | Retained while active; wiped on account deletion or local cache clear. |
| **Translation Requests** | English-to-Santali & multi-lingual translation | Appwrite Cache (`translation_cache`) | Keyed strictly by SHA-256 hash. Text is retained for 90 days for cache acceleration; never linked to user profiles. |
| **Rate Limiting Telemetry** | Preventing DDoS & quota exhaustion | Appwrite DB (`rate_limits`) | Cryptographic HMAC hashes only (`usr_<hash>`, `net_<hash>`). Expired windows auto-pruned after 2 hours. |
| **Payment Records** | Premium content purchases | Razorpay & Appwrite DB | Anonymized (`anonymized_deleted_user`) on account deletion for statutory audit & accounting records. |
| **Binti Guru Waitlist** | Matching learners with cultural recitation experts | Appwrite DB | Deleted upon request or after booking completion. |
| **Crash & Diagnostic Logs** | Error tracking and bug resolution | Local Logger & optional Sentry | Sanitized of all PII, tokens, and secrets via `RedactionHelper`. Raw telemetry purged after 90 days. |

---

## 2. Translation Privacy & Cryptographic Cache

When you use the Olitun AI Translator:
- Your query is processed over encrypted TLS by our serverless translation backend.
- Cache entries are indexed using SHA-256 cryptographic hashes (`sha256(JSON.stringify({ from, to, text }))`).
- Translation text is never associated with your user ID, name, email, or device identifier in analytics or application logs.

---

## 3. Rate Limiting Privacy & Network Safety

To protect backend translation infrastructure against abuse:
- Rate limits are tracked using domain-separated HMAC-SHA256 digests (`translator-rate-limit:user:v1:` for verified users; `translator-rate-limit:network:v1:` for anonymous networks).
- Raw IP addresses and raw user IDs are never stored in the rate limiting database or printed in server logs.

---

## 4. Offline Storage & Local Data Ownership

Olitun operates offline-first. All lesson progress, quiz attempts, and downloaded media reside locally on your device in secure Hive boxes. You can clear local data at any time from the app Settings or initiate permanent account deletion from your Profile.

---

## 5. Account Deletion & Rights

You have the unconditional right to delete your account:
- Navigating to **Profile > Settings > Delete Account** permanently removes your account, personal data, progress history, and uploaded media.
- For statutory tax and fiscal reporting compliance, payment receipts retain only anonymized order IDs.

---

## 6. Contact & Support

For privacy inquiries or data removal requests, contact the project maintainers via the GitHub repository: https://github.com/Kh3rwa1/olitunapp
