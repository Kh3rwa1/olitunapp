# createRazorpayOrder Function

Appwrite serverless function that initializes Razorpay payment orders with atomic server-side price verification and concurrency-safe idempotency.

---

## Idempotency Contract

### 1. Request Payload
```json
{
  "categoryId": "string (required, max 36 chars)",
  "idempotencyKey": "string (optional, max 128 chars; recommended: UUID v4)"
}
```

### 2. Idempotency Key Semantics
- **Intent-Scoped**: Clients should generate a UUID v4 when the user initiates a checkout intent (e.g. when `PaywallBottomSheet` opens).
- **Transient Retries**: If checkout fails due to a network timeout, temporary payment gateway outage, or user re-click, the client **MUST reuse** the same `idempotencyKey`.
- **New Intent**: When the user opens a new checkout sheet or switches items/categories, a **new UUID v4** MUST be generated.
- **Legacy Fallback**: If `idempotencyKey` is omitted, the function derives a deterministic key:
  `${userId}:${categoryId}:checkout_default`.

### 3. Server Attempt Reservation & Lifecycle
Every checkout attempt is hashed to an Appwrite document ID in `payment_attempts`:
```javascript
attemptDocId = 'att_' + sha256(`${userId}:${categoryId}:${idempotencyKey}`).slice(0, 32);
```

#### Attempt Statuses:
- **`in_progress`**: An order creation request is currently being processed by a worker. Protected by a 60-second lease window (`LEASE_DURATION_MS = 60000`). Concurrent requests during this lease receive `409 in_progress`.
- **`failed`**: The attempt failed (e.g., payment gateway returned 5xx, or hourly rate limit was exceeded) without a `providerOrderId`.
  - **Re-reservation Allowed**: Subsequent requests with the same `idempotencyKey` are allowed to re-reserve the attempt and proceed with order creation.
- **`reconciliation_required`**: Gateway connection timed out or returned an ambiguous response. Requires automated reconciliation before reuse.
- **`verified`**: The order was successfully completed, paid, and verified. Future requests with the same `idempotencyKey` return the existing canonical order (`isDuplicateRetry: true`) without calling Razorpay again.

### 4. Concurrency Guard & Atomic Generation Primitive
- Initial checkout attempts rely on Appwrite's database-level unique document ID constraint on `attemptDocId`.
- For re-reserving failed or stale (`>60s`) attempts, an **atomic generation election lock** primitive guarantees mutual exclusion without sleeps or arbitrary settling delays:
  1. Contenders check for an existing canonical order or active unexpired lease.
  2. Contenders attempt to create an atomic election lock document `elc_${stableId(`${attemptDocId}:${currentGeneration}`)}` where `currentGeneration` is derived from `updatedAt || createdAt`.
  3. Appwrite's document ID uniqueness constraint guarantees **exactly one** worker succeeds.
  4. Losers catch the 409 conflict and exit cleanly with HTTP 409 (`code: 'in_progress'`), without calling Razorpay.
  5. The single winning worker updates the canonical attempt record with its candidate lease and proceeds to call Razorpay.
  6. Subsequent retries find the canonical order populated and return 200 OK without additional gateway calls.

### 5. Rate Limiting
- Enforced per-user hourly ceiling (`PAYMENT_ORDERS_PER_HOUR`, default 10).
- Rate limits are evaluated after the idempotency lease election, ensuring deduplicated requests do not consume user quota.
- Rate-limited requests mark the attempt as `failed` so users are not locked out after the hourly window resets.

### 6. Orphaned-Order Recovery & Ledger Safety
- **Gateway Crash Window**: If a worker creates a Razorpay order (`order_1`) at the gateway but crashes or experiences unrecoverable network failure before saving `providerOrderId` or publishing the canonical purchase ledger:
  - The attempt remains in `in_progress` with `providerOrderId: null`.
  - For 60 seconds (`LEASE_DURATION_MS = 60000`, `STALE_RESERVATION_TIMEOUT_MS = 60000`), client retries receive HTTP 409 `in_progress`, safely bounding clock skew and function execution timeouts.
  - After 60 seconds, subsequent retry re-reserves the attempt via the atomic election lock and creates a new canonical order (`order_2`).
  - Worker saves `order_2` to `payment_attempts` and writes `course_purchases`.
  - The unsaved `order_1` at the gateway remains orphaned and unpaid; it was never returned to the client and expires harmlessly at the payment gateway with zero financial consequence.
- **Verification Safety**: When the client completes payment for `order_2`, both `verifyCoursePurchase` (via client SDK) and `razorpayWebhook` (via server-to-server webhook) verify `order_2` against the canonical purchase ledger, commit the cryptographic payment claim in `payment_claims`, and set `course_purchases.status = 'verified'`.

### 7. Deployment & Rollback Runbook
- **Prerequisite Check**:
  ```bash
  node scripts/sync_shared_modules.mjs --check
  npm run test:backend
  ```
- **Rollback Target Deployment ID**:
  - `6a97b0c81c9bba0b313b` (active stable deployment prior to #411/#412)
- **Rollback Procedure**:
  - If any deployment anomaly is observed after release, do NOT modify code in production.
  - In Appwrite Console (or via CLI), navigate to `Functions` > `createRazorpayOrder` > `Deployments`.
  - Locate deployment `6a97b0c81c9bba0b313b` and click **Activate**.
  - Verify function health and execution logs.

