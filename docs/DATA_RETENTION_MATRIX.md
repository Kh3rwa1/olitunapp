# Data Retention & Privacy Matrix

Documents the retention schedules, automated pruning cron jobs, and permanent deletion flows for all data stored in Olitun.

| Data Domain | Storage Location | Retention Period | Deletion Mechanism | Legal / Compliance Basis |
|---|---|---|---|---|
| **Account Identity** | Appwrite Auth Users | Active session life | Immediate upon user deletion request (`delete-account`) | User Consent / GDPR Right to Erasure |
| **User Learning Progress** | `user_preferences`, `user_mistakes`, `bakhed_listening_progress` | Active user life | Immediate upon user deletion request | User Consent / Right to Erasure |
| **Learning Analytics Events** | `learning_analytics_events` | 90 days rolling | Automated daily cron (`cleanupAnalyticsEvents`) | Operational Aggregation / Analytics Pruning |
| **Analytics Daily Rollups** | `learning_analytics_daily` | 365 days | Rolling aggregate summaries | Product Quality & Retention Metrics |
| **Rate Limit Counters** | `rate_limits` | 2 hours rolling | Replaced on window boundary / TTL | DDoS & Abuse Prevention |
| **Payment Ledger (Completed)** | `course_purchases` | 7 years | Retained for tax & financial compliance (PII decoupled) | Tax & Financial Compliance |
| **Payment Attempts (Abandoned)** | `payment_attempts` | 30 days | Automated monthly cleanup job | Fraud Prevention & Order Reconciliation |
| **Course Waitlist Submissions** | `binti_guru_waitlist` | 180 days | Manually or periodically purged upon course launch | Marketing / Waitlist Management |
| **Database Weekly Backups** | `admin_backups` bucket | 12 weeks rolling (12 files) | Automated weekly backup prune in `backupCollections` | Disaster Recovery & Business Continuity |
| **Local Client Storage** | Hive, SharedPreferences | Active installation | Cleared on logout, account deletion, or app uninstallation | User Privacy |
