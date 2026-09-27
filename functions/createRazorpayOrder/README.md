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
- **`in_progress`**: An order creation request is currently being processed by a worker. Protected by a 30-second lease window (`LEASE_DURATION_MS = 30000`). Concurrent requests during this lease receive `409 in_progress`.
- **`failed`**: The attempt failed (e.g., payment gateway returned 5xx, or hourly rate limit was exceeded) without a `providerOrderId`.
  - **Re-reservation Allowed**: Subsequent requests with the same `idempotencyKey` are allowed to re-reserve the attempt and proceed with order creation.
- **`reconciliation_required`**: Gateway connection timed out or returned an ambiguous response. Requires automated reconciliation before reuse.
- **`verified`**: The order was successfully completed, paid, and verified. Future requests with the same `idempotencyKey` return the existing canonical order (`isDuplicateRetry: true`) without calling Razorpay again.

### 4. Concurrency Guard
- Relies on database-level unique document constraints on initial creation.
- For re-reserving failed or stale (`>30s`) attempts, an atomic election protocol is executed:
  1. Pre-check for existing active lease or order ID.
  2. Candidate worker token written to `leaseOwner`.
  3. Settling pause (10ms) to allow concurrent writers to complete.
  4. Verification read to confirm the elected lease winner.
  5. Only the elected winner calls the Razorpay API; all others yield `409 in_progress` or return the canonical order.

### 5. Rate Limiting
- Enforced per-user hourly ceiling (`PAYMENT_ORDERS_PER_HOUR`, default 10).
- Rate limits are evaluated after the idempotency lease election, ensuring deduplicated requests do not consume user quota.
- Rate-limited requests mark the attempt as `failed` so users are not locked out after the hourly window resets.
