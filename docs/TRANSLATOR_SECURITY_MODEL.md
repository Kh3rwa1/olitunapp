# Olitun Translator Security & Rate Limiting Model

## 1. Concurrency-Safe Rate Limiting Architecture

The Olitun translator backend (`functions/translator`) enforces strict multi-tier rate limiting designed for distributed serverless workers executing against Appwrite.

### Key Architectural Invariants:
1. **Deterministic Window Partitioning:** Time windows are split into fixed deterministic epoch intervals:
   - **Minute Burst Window:** `Math.floor(now / 60000)`
   - **Hourly Sustained Window:** `Math.floor(now / 3600000)`
2. **Deterministic Slot Reservation:**
   - For a configured limit $L$, slots $1 \dots L$ have deterministic document IDs: `generateSlotDocId(prefix, identifier, windowIndex, slot)`.
   - Each allowed request claims an available slot via `databases.createDocument(...)`.
   - Primary key uniqueness on `documentId` guarantees that concurrent workers competing for the same slot receive `409 Conflict`, with exactly one winner per slot.
   - If all slots $1 \dots L$ are occupied, the request is deterministically rejected with `burst_limit_exceeded` or `hourly_limit_exceeded` and calculated `retryAfterSeconds`.
3. **Dual-Window Partial Accounting Rollback:**
   - Minute burst limit is checked first; on success, hourly sustained limit is checked.
   - If hourly quota is exhausted, the claimed minute slot is automatically rolled back to prevent burning burst quota on an rejected request.
4. **Fail-Closed Safety:** If the rate limiting collection experiences an outage or storage error, requests fail closed with HTTP 503 `RATE_LIMIT_ERROR` to protect upstream translation providers from unmetered access during database downtime.
5. **Automated Retention Pruning:** Expired rate limit window records are systematically cleaned via `pruneExpiredRateLimits()` using indexed `windowStart` queries.

---

## 2. Quota Matrix

| Identity Tier | 1-Minute Burst Quota | 1-Hour Sustained Quota | Max Character Count |
| :--- | :---: | :---: | :---: |
| **Anonymous / Guest** | 5 requests / min | 20 requests / hour | 5,000 chars / request |
| **Authenticated User** | 15 requests / min | 60 requests / hour | 5,000 chars / request |

---

## 3. Privacy-Preserving Rate Limit Identifiers

Rate limit identifiers are cryptographically hashed using domain separation and a secret HMAC salt:
- **Authenticated Verified Users:** `usr_` + `HMAC-SHA256(RATE_LIMIT_SALT, "translator-rate-limit:user:v1:" + verifiedUserId)[0..32]`
- **Anonymous Network Callers:** `net_` + `HMAC-SHA256(RATE_LIMIT_SALT, "translator-rate-limit:network:v1:" + normalizedIp)[0..32]`

Neither raw IP addresses nor raw user IDs are stored in the rate limits collection or printed in server logs.

---

## 4. Translation Cache Security

- **Cache Keys:** Derived via `SHA-256(JSON.stringify({ from, to, text }))`.
- **Text Privacy:** Translation text is stored strictly within the Appwrite cache collection and never logged in operational telemetry or error logs.
