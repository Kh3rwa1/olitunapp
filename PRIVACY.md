# Olitun Privacy Policy

**Last updated:** September 17, 2026

Olitun is an educational platform for learning Ol Chiki and Santali language and culture. This privacy policy transparently details how data is handled across our offline-first Flutter application, backend serverless functions, and persistence layers.

---

## 1. Data Collection, Retention & Purpose

| Data Category | Purpose | Storage Location | Retention / Deletion Policy |
| :--- | :--- | :--- | :--- |
| **Account Credentials** | Sign-in, session maintenance, cross-device sync | Appwrite Auth | Purged immediately upon account deletion. |
| **Learning Progress & Streaks** | Offline lesson tracking, quiz scores, mistake reviews | Local Hive Storage & Appwrite DB | Retained while active; wiped on account deletion or local cache clear. |
| **Translation Requests** | English-to-Santali & multi-lingual translation | Appwrite Cache (`translation_cache`) | Keyed strictly by SHA-256 hash. Text is retained for 90 days for cache acceleration; never linked to user profiles. |
| **AI Studio Inputs** | Uploaded audio/documents for transcription & OCR | Appwrite Storage & DB (`ai_studio_inputs`) | Auto-pruned after **24 hours** by scheduled cleanup; deleted immediately on account deletion. |
| **AI Studio Jobs & Reviews** | OCR and translation job metadata and review progress | Appwrite DB (`ai_studio_jobs`, `review_states`) | Auto-pruned after **30 days**; purged on account deletion. |
| **Santali Voice Audio Cache** | Audio clips synthesized with Bodhan TTS | Appwrite DB (`tts_cache`) & Storage (`voice_clips`) | Keyed strictly by SHA-256 parameter hash without user identity. Retained for **90 days** for shared cache acceleration across learners; pruned after 90 days. Not per-user deletable because clips are impersonal. |
| **Santali Voice Quota Claims** | Durable quota reservations & abuse prevention | Appwrite DB (`voice_claims`) | Auto-pruned after **7 days**; purged on account deletion. |
| **Learning Analytics Events** | Feature usage telemetry & progress rollups | Appwrite DB (`learning_analytics_events`) | Raw events auto-pruned after **90 days**; aggregated into daily statistics. Purged on account deletion. |
| **Rate Limiting Telemetry** | Preventing DDoS & quota exhaustion | Appwrite DB (`rate_limits`) | Cryptographic HMAC hashes only (`usr_<hash>`, `net_<hash>`). Expired windows auto-pruned after 2 hours. |
| **Payment Records** | Premium content purchases | Razorpay & Appwrite DB (`course_purchases`) | Anonymized (`anonymized_deleted_user`) on account deletion for statutory audit & 7-year fiscal records. |
| **Binti Guru Waitlist** | Matching learners with cultural recitation experts | Appwrite DB (`binti_waitlist`) | Deleted upon request or after booking completion. |
| **Crash & Diagnostic Logs** | Error tracking and bug resolution | Local Logger & optional Sentry | Sanitized of all PII, tokens, and secrets via `RedactionHelper`. Raw telemetry purged after 90 days. |

---

## 2. AI Translation, Studio & Voice Synthesis Privacy

When you use Olitun's AI-assisted features:
- **Encrypted Transmission:** All AI requests transmit over TLS directly to serverless backends; external AI provider credentials never reach user devices.
- **Translation Cache:** Queries are indexed using impersonal SHA-256 cryptographic hashes (`sha256(JSON.stringify({ from, to, text }))`). Text is never associated with user profiles, email, or device identifiers.
- **AI Studio Lifecycle:** Source documents, camera captures, and microphone audio uploaded to AI Studio are retained for a maximum of **24 hours** before being permanently expunged by daily retention pruning jobs (`cleanupAnalyticsEvents`). Scan jobs and review drafts are retained for **30 days**.
- **Voice Synthesis Cache (`tts_cache`):** Synthesized speech is keyed by SHA-256 hash of synthesis parameters (`text`, `voice`, `speed`, `style`). Audio clips in the `voice_clips` storage bucket and `tts_cache` collection are retained for **90 days** to provide instant replays without re-billing. Because cache entries contain no user identifier, they are shared across learners and are not per-user deletable.

---

## 3. Rate Limiting Privacy & Network Safety

To protect backend translation and voice synthesis infrastructure against abuse:
- Rate limits and quotas are tracked using domain-separated HMAC-SHA256 digests (`translator-rate-limit:user:v1:` for verified users; `translator-rate-limit:network:v1:` for anonymous networks) and durable voice claims (`usr_<hash>_<timestamp>`).
- Raw IP addresses and user credentials are never stored in rate limit tables or printed in logs.

---

## 4. Offline Storage & Local Data Ownership

Olitun operates offline-first:
- **Local Application Sandbox:** All offline lesson progress, quiz attempts, vocabulary cache, and mutation outboxes reside locally in Hive boxes within the operating-system-protected application sandbox.
- **Encryption at Rest:** Local Hive storage is unencrypted at rest by default, relying on the host operating system's sandbox isolation (Android, iOS, macOS, Windows, Linux).
- **User Control:** You can clear local data and cache at any time from app **Settings > Storage & Cache**, or by uninstalling the application.

---

## 5. Account Deletion & Rights

You have the unconditional right to delete your account:
- Navigating to **Profile > Settings > Delete Account** triggers our multi-collection cascade deletion engine (`functions/delete-account` and `delete_account_core.js`).
- **Complete Deletion Inventory:** All user-associated documents across `user_preferences`, `user_mistakes`, `mistake_review_sessions`, `bakhed_listening_progress`, `user_assets`, `learning_analytics_events`, `ai_studio_jobs`, `review_states`, and `voice_claims` are permanently deleted, along with any user-uploaded files in `ai_studio_inputs` and `user_assets`.
- **Statutory & Impersonal Exceptions:** For statutory tax and fiscal reporting compliance, purchase receipts in `course_purchases` retain only anonymized order identifiers. Impersonal SHA-256 audio and translation caches (`tts_cache`, `translation_cache`) expire on their standard 90-day retention schedule.

---

## 6. Contact & Support

For privacy inquiries or data removal requests, contact the project maintainers via the GitHub repository: https://github.com/Kh3rwa1/olitunapp
