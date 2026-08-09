# Schema Migrations and Rollback Procedures

## Overview
This document specifies the idempotent database migration protocol and zero-downtime rollback procedures for Olitun's Appwrite backend collections (`payment_attempts`, `deletion_requests`, `user_assets`, `course_purchases`).

---

## 1. Idempotent Migration Tooling

All collection attributes, indexes, and permission rule updates are executed via `scripts/appwrite_setup.mjs`.

### Execution Command:
```bash
node scripts/appwrite_setup.mjs --apply
```

### Safety & Idempotency Rules:
1. **Attribute Creation Safeguard**: Before creating any attribute or index, `scripts/appwrite_setup.mjs` checks if the attribute/index already exists. Existing attributes are skipped safely without throwing errors.
2. **Schema Drift Detection**: In CI/CD, `node scripts/snapshot_appwrite_schema.mjs` validates that live database schemas strictly match checked-in fixture declarations in `test/fixtures/schema/`.
3. **No Destructive Drops**: Destructive attribute deletion or collection dropping is strictly prohibited during automated migrations.

---

## 2. Collection Schemas & Indexes

### `payment_attempts`
- **Purpose**: Concurrency lock election for Razorpay order generation.
- **Attributes**:
  - `userId` (string, required, min: 1, max: 255)
  - `categoryId` (string, required, min: 1, max: 255)
  - `idempotencyKey` (string, required, min: 1, max: 255)
  - `razorpayOrderId` (string, nullable, min: 1, max: 255)
  - `status` (string, required, enum: `initiated`, `order_created`, `completed`, `failed`)
  - `createdAt` (datetime, required)
- **Permissions**: `read("user:{userId}")`, `write("user:{userId}")`
- **Indexes**:
  - `idx_user_category` (key: `userId`, `categoryId`)

### `deletion_requests`
- **Purpose**: Mandatory state machine tracking for GDPR/account deletion compliance.
- **Attributes**:
  - `userId` (string, required, min: 1, max: 255)
  - `status` (string, required, enum: `initiated`, `cleaning_up`, `completed`, `failed`)
  - `hmacSignature` (string, required, min: 1, max: 255)
  - `initiatedAt` (datetime, required)
  - `completedAt` (datetime, nullable)
- **Permissions**: `read("user:{userId}")`, `write("user:{userId}")`

---

## 3. Zero-Downtime Rollback Protocol

If a release deployment must be rolled back:

1. **Client Deployment Rollback**:
   - Web: Re-point Cloudflare Pages / App Hosting DNS CNAME to the prior tagged release.
   - Android: Publish the hotfix patch build to Google Play Console with incremented `versionCode`.

2. **Serverless Functions Rollback**:
   - Use Appwrite CLI or Console to activate the previous deployed function execution tag.

3. **Database Schema Rollback**:
   - Backward-compatible additions (new nullable attributes or indexes) do NOT need to be dropped during rollback.
   - Legacy app versions ignore newer optional attributes gracefully.
