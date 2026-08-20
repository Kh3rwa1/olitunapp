# Offline-First Architecture & Data Synchronization

Olitun is built on a resilient **Stale-While-Revalidate (SWR)** and **Offline-First** storage foundation. Learners can launch the application, read all previously downloaded lessons, complete quizzes, practice Ol Chiki calligraphy, and accumulate learning stats indefinitely without an active internet connection.

---

## 1. Storage & Caching Layer

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│      ConsumerWidget  <───  AsyncValue.when(data)            │
├─────────────────────────────────────────────────────────────┤
│                 State / Notifiers Layer                     │
│         CategoryNotifier / LessonNotifier / Stats           │
├─────────────────────────────────────────────────────────────┤
│                   Repository Layer (SWR)                    │
│      1. Yields Cached / Stale Data Immediately (<5ms)       │
│      2. Dispatches Background Async Refresh (if online)     │
│      3. Atomically Replaces Cache only on Valid Parse       │
├──────────────────────────────┬──────────────────────────────┤
│      Remote DataSource       │       Local DataSource       │
│        (Appwrite SDK)        │   (Hive Envelope Cache +     │
│                              │   Durable Mutation Outbox)   │
└──────────────────────────────┴──────────────────────────────┘
```

### Cache State Transitions

| State | Condition | User Experience |
|---|---|---|
| `loadingNoCache` | No cached entry on first launch | Shimmer skeleton placeholder / bundled seed fallback |
| `fresh` | Entry exists within active TTL | Instant render; no background network fetch needed |
| `stale` | Entry exists past TTL (e.g. 1d - 30d+) | Instant render of cached content; background refresh dispatched |
| `refreshing` | Background network request in-flight | User continues learning uninterrupted |
| `errorWithCache` | Background network fetch failed | Cached content retained; gentle non-blocking offline hint |
| `unrecoverable` | Cache corrupted & network unavailable | Fallback to bundled immutable seed catalog |

---

## 2. Key Invariants & Hardening Guarantees

1. **TTL Means Stale, Never Deleted:**
   - A TTL indicates when background revalidation should be attempted. Valid learning content is **never** deleted simply because of age. A user opening Olitun after 30 days offline has immediate access to all downloaded lessons and quizzes.
2. **Atomic Schema Invalidation:**
   - Caches are versioned (`cacheSchemaVersion = 4`). Only breaking schema format migrations trigger eviction.
3. **Corrupt Payload Defense:**
   - If an Appwrite response returns malformed data or fails validation, the repository discards the remote payload and **preserves the last-known-good cache**.
4. **Durable Mutation Outbox:**
   - Progress mutations completed while offline (stars earned, lessons finished, letters practiced) are written to a dedicated durable Hive box (`MutationOutboxService`) and synced with exponential backoff + jitter upon connection recovery.

---

## 3. Conflict Resolution Rules (Cross-Device Sync)

When resolving progress between multiple devices or reconciling local offline progress with cloud state:

| Progress Metric | Resolution Strategy | Rationale |
|---|---|---|
| **Completed Lessons** | Set Union (`local ∪ remote`) | A lesson finished on any device remains permanently completed |
| **Completed Quizzes** | Set Union (`local ∪ remote`) | Quizzes completed anywhere are recognized |
| **Best Quiz Score** | Maximum (`max(local, remote)`) | Learner retains their highest recorded mastery score |
| **Stars / Rewards** | Monotonic Idempotent Accumulator | Rewards bound to unique event IDs (`evt_star_*`) to prevent duplication |
| **Learning Minutes** | Additive Delta Accumulation | Minutes spent learning offline on Device A and Device B are both preserved |
| **Current Streak** | UTC Date Activity Validation | Computed from active consecutive activity dates |
| **Longest Streak** | Maximum (`max(local, remote)`) | Preserves historical milestone |
