# Appwrite Permission Matrix

Authoritative access control matrix across all database collections, storage buckets, and Appwrite functions.

## 1. Database Collections Access Matrix

| Collection ID | Resource Type | Client Read | Client Write | Server / Function | Description |
|---|---|---|---|---|---|
| `categories` | Public Content | Public (`Role.any()`) | Admin Team Only | Full Admin | Learning topic categories |
| `lessons` | Public Content | Public (`Role.any()`) | Admin Team Only | Full Admin | Curriculum lessons & blocks |
| `letters` | Public Content | Public (`Role.any()`) | Admin Team Only | Full Admin | Alphabet characters & strokes |
| `numbers` | Public Content | Public (`Role.any()`) | Admin Team Only | Full Admin | Ol Chiki numerical glyphs |
| `words` | Public Content | Public (`Role.any()`) | Admin Team Only | Full Admin | Vocabulary entries |
| `sentences` | Public Content | Public (`Role.any()`) | Admin Team Only | Full Admin | Interactive sentence blocks |
| `rhymes` | Public Content | Public (`Role.any()`) | Admin Team Only | Full Admin | Cultural rhymes & media |
| `banners` | Public Content | Public (`Role.any()`) | Admin Team Only | Full Admin | Home screen banners |
| `affirmations` | Public Content | Public (`Role.any()`) | Admin Team Only | Full Admin | Daily motivation quotes |
| `user_preferences` | User Data | Owner (`Role.user(id)`) | Owner (`Role.user(id)`) | Full Access | User settings, theme, audio |
| `user_mistakes` | User Data | Owner (`Role.user(id)`) | Owner (`Role.user(id)`) | Full Access | Quiz mistake review notebook |
| `bakhed_listening_progress`| User Data | Owner (`Role.user(id)`) | Owner (`Role.user(id)`) | Full Access | Audio playback milestones |
| `learning_analytics_events`| Analytics | Forbidden | Function Only | Full Access | User learning events |
| `course_purchases` | Financial Ledger | Owner (`Role.user(id)`) | Forbidden | Function Only | Verified entitlements |
| `payment_claims` | Idempotency | Forbidden | Forbidden | Function Only | Two-phase payment locks |
| `refund_claims` | Idempotency | Forbidden | Forbidden | Function Only | Dispute & refund locks |
| `payment_attempts` | Telemetry | Forbidden | Forbidden | Function Only | Ephemeral checkout records |
| `rate_limits` | Security | Forbidden | Forbidden | Function Only | Privacy-hashed rate limits |
| `binti_guru_waitlist`| Waitlist | Forbidden | Function Only | Admin Read | Sanitized course applications |
| `admin_audit_logs` | Audit | Forbidden | Forbidden | Admin Read | Admin actions audit trail |
| `account_deletion_queue` | Compliance | Forbidden | Forbidden | Function Only | Deletion staging records |

## 2. Storage Buckets Access Matrix

| Bucket ID | Resource Type | Client Read | Client Write | Server Access | Allowed Extensions / Limits |
|---|---|---|---|---|---|
| `content_media` | Public Media | Public (`Role.any()`) | Admin Team Only | Full Access | PNG, JPEG, SVG, WebP (<5MB) |
| `audio_pronunciations` | Public Audio | Public (`Role.any()`) | Admin Team Only | Full Access | MP3, M4A, AAC (<15MB) |
| `bakhed_audio` | Cultural Audio | Public (`Role.any()`) | Admin Team Only | Full Access | MP3, M4A (<50MB) |
| `cover_videos` | Media Video | Public (`Role.any()`) | Admin Team Only | Full Access | MP4, WebM (<30MB) |
| `admin_backups` | System Backup | Forbidden | Forbidden | Server / Cron Only | JSON Gzip (<100MB) |

## 3. Appwrite Functions Execution Scopes

| Function ID | Trigger / Schedule | Execution Role | Required Scopes |
|---|---|---|---|
| `translator` | HTTP POST | `any` | `databases.read`, `databases.write` |
| `delete-account` | HTTP POST | `users` | `users.write`, `databases.read`, `databases.write`, `files.read`, `files.write` |
| `reconcileOrphanedDeletions`| Cron `0 2 * * *`| Server Cron | `users.read`, `databases.read`, `databases.write` |
| `verifyCoursePurchase` | HTTP POST | `users` | `databases.read`, `databases.write` |
| `razorpayWebhook` | HTTP POST (HMAC)| `any` | `databases.read`, `databases.write` |
| `createRazorpayOrder` | HTTP POST | `users` | `databases.read`, `databases.write` |
| `backupCollections` | Cron `0 4 * * 0`| Server Cron | `databases.read`, `files.write` |
| `cleanupAnalyticsEvents` | Cron `0 3 * * *`| Server Cron | `databases.read`, `databases.write` |
| `aggregateLearningAnalytics`| Cron `30 0 * * *`| Server Cron | `databases.read`, `databases.write` |
| `manageAdminAccess` | HTTP POST | `teams:admins` | `teams.read`, `teams.write` |
