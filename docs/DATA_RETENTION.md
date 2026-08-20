# Olitun Data Retention & Disposal Schedule

## 1. Retention Matrix

| Data Collection / Asset | Storage Target | Active Retention Period | Disposal / Cleanup Mechanism |
| :--- | :--- | :--- | :--- |
| **User Account & Auth Sessions** | Appwrite Auth & Local Storage | Active lifespan of user account | **Instant Deletion:** Account deletion completely removes credentials, session cookies, and tokens. |
| **Learning Progress & Mistake History** | Appwrite DB & Local Hive Boxes | Active lifespan of user account | **Cascade Deletion:** Deleted upon account removal or local cache reset. |
| **Translation Cache** | Appwrite DB (`translation_cache`) | 90 days from creation | **Auto-Purge:** Cached responses keyed by SHA-256 hash are pruned periodically; no user link. |
| **Rate Limit Windows** | Appwrite DB (`rate_limits`) | 2 hours (1 hour window + 1h buffer) | **Automated CAS Pruning:** `pruneExpiredRateLimits()` deletes documents where `expiresAt < now`. |
| **Course Purchase Receipts** | Appwrite DB (`course_purchases`) | 7 years (Statutory tax compliance) | **Anonymization:** User identifiers replaced with `anonymized_deleted_user` upon account deletion. |
| **Curriculum Backups** | Appwrite Storage (`admin_backups`) | 12 weeks (Rolling snapshot) | **FIFO Rotation:** `backupCollections` function caps total retained snapshots to the 12 most recent. |
| **Diagnostics & Telemetry** | Local Logger / Sentry | 90 days maximum | **Automated Aging:** Sanitized event logs aged out automatically. |

---

## 2. Automated Cleanup Implementation

1. **Rate Limit Pruning:** Serverless workers execute `pruneExpiredRateLimits({ databases, now })` during background maintenance cycles, deleting expired window records in batches.
2. **Weekly Automated Backups:** Scheduled Appwrite cron functions back up educational content (lessons, quizzes, words, rhymes) to encrypted storage buckets and enforce the 12-snapshot retention ceiling.
3. **Local Cache Cleansing:** When a user logs out or selects "Clear Cache" in Settings, local Hive boxes are closed and wiped immediately.
