# Data Classification & Sensitivity Matrix

This document provides Olitun's data classification scheme and handling rules across all application modules.

---

## 1. Classification Levels

| Level | Definition | Target Collections / Storage | Access Constraints | Retention Policy |
|---|---|---|---|---|
| **Public** | Information intended for public distribution | `categories`, `lessons`, `words`, `sentences`, `letters`, `numbers`, `rhymes`, `bakhed_*`, `app_settings`, `banners` | Readable by `Role.any()`; Writable by Admin/Function | Permanent |
| **Authenticated** | Accessible to any signed-in user | `badges`, general media assets | Readable by `Role.users()` | Permanent |
| **Owner-Private** | User-specific personal data | `user_preferences`, `user_mistakes`, `mistake_review_sessions`, `bakhed_listening_progress` | Readable/Writable strictly by `Role.user(userId)` | Purged upon account deletion |
| **Admin-Only** | Privileged administration metrics & audit logs | `admin_audit_logs`, system backups | Readable/Writable strictly by `Team:admin` / Server Functions | Permanent audit retention |
| **Function-Only** | Server operation state & locks | `payment_claims`, `refund_claims`, `rate_limits` | Readable/Writable strictly by Server API Key | Operationally managed |
| **Financial / Legal** | Razorpay purchase receipts & payment ledgers | `course_purchases` | Owner Read / Function Write; PII stripped on user deletion | 7 years statutory tax retention |
