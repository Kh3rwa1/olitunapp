# Data Classification & Sensitivity Matrix

This document provides Olitun's data classification scheme and handling rules across all application modules.

---

## 1. Classification Levels

| Level | Definition | Target Collections / Storage | Access Constraints | Retention Policy |
|---|---|---|---|---|
| **Public** | Information intended for public distribution | `categories`, `lessons`, `words`, `sentences`, `letters`, `numbers`, `rhymes`, `bakhed_*`, `app_settings`, `banners` | Readable by `Role.any()`; Writable by Admin/Function | Permanent |
| **Authenticated** | Accessible to any signed-in user | `badges`, general media assets | Readable by `Role.users()` | Permanent |
| **Owner-Private** | User-specific personal data | `user_preferences`, `user_mistakes`, `mistake_review_sessions`, `bakhed_listening_progress`, `user_assets`, `learning_analytics_events` | Readable/Writable strictly by `Role.user(userId)` | Purged upon account deletion; raw analytics auto-pruned after 90 days |
| **AI Studio Ephemeral** | Uploaded user media for OCR & transcription | Storage bucket `ai_studio_inputs` | Owner Read/Write via secure server function | Auto-pruned after **24 hours** by `cleanupAnalyticsEvents`; wiped on account deletion |
| **AI Studio Jobs & Reviews** | Metadata & text drafts for AI tasks | `ai_studio_jobs`, `review_states` | Owner Read/Write via server function | Auto-pruned after **30 days** by `cleanupAnalyticsEvents`; purged on account deletion |
| **Shared Impersonal Cache** | Accelerates multi-lingual translation and voice synthesis | `translation_cache`, `tts_cache`, storage bucket `voice_clips` | Keyed strictly by SHA-256 parameter hash without user ID | Auto-pruned after **90 days**; not per-user deletable because entries contain no PII |
| **Admin-Only** | Privileged administration metrics & audit logs | `admin_audit_logs`, system backups | Readable/Writable strictly by `Team:admin` / Server Functions | Permanent audit retention |
| **Function-Only** | Server operation state, locks, and quota claims | `payment_claims`, `refund_claims`, `rate_limits`, `voice_claims` | Readable/Writable strictly by Server API Key | Operationally managed; `voice_claims` auto-pruned after **7 days**; purged on account deletion |
| **Financial / Legal** | Razorpay purchase receipts & payment ledgers | `course_purchases` | Owner Read / Function Write; PII stripped on user deletion | 7 years statutory tax retention |

---

## 2. Local Storage & Application Sandbox Security

Olitun operates as an offline-first mobile and desktop application:
- **Storage Mechanism:** Hive boxes (`cache`, `mutation_outbox`, `progress`, `settings`) and `SharedPreferences`.
- **Sandbox Boundary:** All local data is isolated within the host operating system's application sandbox (iOS sandbox, Android internal storage, macOS app container).
- **Encryption Status:** Local storage is unencrypted at rest by default. It relies on device-level OS protection, full-disk encryption (FileVault, Android FBE, iOS Data Protection), and passcode locks.
- **User Purge:** Users can wipe all local application data at any time via **Settings > Clear Cache** or by deleting the app. Account deletion cascade additionally instructs the client to clear all local persistent caches.
