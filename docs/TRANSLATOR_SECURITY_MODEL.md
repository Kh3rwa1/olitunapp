# Olitun Translator Security & Rate Limiting Model

## 1. Concurrency-Safe Rate Limiting Architecture

The Olitun translator backend (`functions/translator`) enforces strict multi-tier rate limiting designed for distributed serverless workers executing against Appwrite.

### Key Architectural Invariants:
1. **Deterministic Window Partitioning:** Time windows are split into fixed deterministic epoch intervals:
   - **Minute Burst Window:** `Math.floor(now / 60000)`
   - **Hourly Sustained Window:** `Math.floor(now / 3600000)`
2. **Deterministic Document IDs:** Document IDs are derived using SHA-256: `generateWindowDocId(prefix, identifier, windowIndex)`.
3. **Optimistic Concurrency Control (OCC) / CAS:**
   - Attempt 1: Call `createDocument(docId)` with count = 1.
   - If document already exists (HTTP 409 Conflict): The worker reads the current counter document and revision.
   - If count is below quota: Worker increments count with revision verification (`_expectedRevision`) and exponential jittered backoff across bounded retry attempts (up to 12 retries).
   - If count meets or exceeds quota: Reject immediately with `burst_limit_exceeded` or `hourly_limit_exceeded` and calculated `retryAfterSeconds`.
4. **Fail-Closed Safety:** If the rate limiting collection or database experiences an outage, requests fail closed with HTTP 503 `RATE_LIMIT_ERROR` to protect upstream translation quotas from abuse during database downtime.
5. **Automated Pruning:** Expired rate limit windows carry an `expiresAt` timestamp and are systematically cleaned via `pruneExpiredRateLimits()`.

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
