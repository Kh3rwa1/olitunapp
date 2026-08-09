# Appwrite Permissions & Security Model

This document outlines the authoritative security and permission architecture for Olitun's Appwrite database collections and storage buckets.

---

## 1. Permission Matrix by Collection

| Collection ID | Purpose | Client Read | Client Write | Server / Function | Notes |
|---|---|---|---|---|---|
| `categories` | Lesson categories | Public (`Role.any()`) | Forbidden | Admin / Setup | Read-only to clients |
| `lessons` | Lesson blocks & course items | Public (`Role.any()`) | Forbidden | Admin / Setup | Read-only to clients |
| `words`, `sentences`, `letters`, `numbers` | Vocabulary & stroke data | Public (`Role.any()`) | Forbidden | Admin / Setup | Read-only to clients |
| `rhymes`, `bakhed_*` | Audio & cultural literature | Public (`Role.any()`) | Forbidden | Admin / Setup | Read-only to clients |
| `user_preferences` | User settings & audio prefs | Owner Only (`Role.user(id)`) | Owner Only (`Role.user(id)`) | Full Access | Private user state |
| `user_mistakes` | Quiz mistake review records | Owner Only (`Role.user(id)`) | Owner Only (`Role.user(id)`) | Full Access | Private user state |
| `bakhed_listening_progress` | Literature playback progress | Owner Only (`Role.user(id)`) | Owner Only (`Role.user(id)`) | Full Access | Private user state |
| `user_badges`, `reward_events` | Gamification progress | Owner Only (`Role.user(id)`) | Forbidden | Function Only | Granted by backend function |
| `binti_guru_waitlist` | Course waitlist requests | Forbidden / Function | Function | Admin Read | Sanitized server submission |
| `course_purchases` | Financial purchase receipts | Owner Only (`Role.user(id)`) | Forbidden | Function Only | Ledger updated by server |
| `payment_claims` | Payment idempotency locks | Forbidden | Forbidden | Function Only | Function internal lock |
| `refund_claims` | Dispute & refund locks | Forbidden | Forbidden | Function Only | Function internal lock |
| `rate_limits` | API rate limiting counters | Forbidden | Forbidden | Function Only | Server function state |
| `admin_audit_logs` | Admin action audit log | Forbidden | Forbidden | Function Only / Admin Read | Audit trail |

---

## 2. Infrastructure Enforcement Rules

1. **No Implicit Public Access**:
   - `AppwriteDbService` MUST NOT set `Permission.read(Role.any())` as a default fallback on generic `createDocument` or `updateDocument` calls.
   - Public content must be created using `createPublicContent(...)`.

2. **Permission Preservation on Update**:
   - Updating document payload data MUST NOT replace or overwrite existing document permissions. Use `updateDataPreservingPermissions(...)` or pass `permissions: null`.

3. **Function-Managed Records**:
   - Sensitive operational ledgers (`course_purchases`, `payment_claims`, `refund_claims`, `rate_limits`, `admin_audit_logs`) are written exclusively using server API keys via Appwrite Functions.

---

## 3. Migration & Rollback Guidelines

- **Migration**:
  - Run `scripts/appwrite_setup.mjs` with `--update-permissions` to apply updated permissions to existing database collections non-destructively.
- **Rollback Plan**:
  - In case of permission deployment issues, run `node scripts/appwrite_setup.mjs --restore-backup` using the auto-generated pre-migration schema snapshot stored in `test/fixtures/schema/`.
