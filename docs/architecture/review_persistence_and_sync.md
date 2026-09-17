# ADR: Review Persistence Boundary (WS1)

Status: accepted.
Date: 2026-09-17.

## Context

`ReviewStore` persisted via `SharedPreferences.setString` invoked BEFORE
chaining onto a `_persistQueue` (serializing waiters, not invocations),
while `recordRecall`/`ensureIntroduced` persisted implicitly AND their
callers persisted again (two full-map writes per mutation). Failures were
fire-and-forget. The 2,000-item cap could evict an arbitrary active item.

## Decision

- ONE boundary: `ReviewStateLocalRepository` (`save`/`load`/`clear`).
  `SharedPreferencesReviewStateRepository` chains whole invocations
  (encode + write) in call order. `InMemoryDelayedReviewStateRepository`
  reproduces delayed/out-of-order native persistence in tests.
- `ReviewStore` mutations are pure in-memory; durability is explicit
  (`persist`/`persistOrThrow`, exactly one write per logical mutation).
- `ReviewStoreNotifier` owns the transaction: capture scope → validate →
  compute → persist under captured scope → re-verify scope → publish →
  enqueue cloud → replay. Scope change → `AccountScopeError`, no publish,
  original owner's write retained. Persist failure → `durable:false`, no
  cloud enqueue, observable failure, mastery not reported as durable.
- Fixed cap REMOVED. No fresh/learning/review item is ever evicted
  locally; future archival requires explicit remote coordination.
- Quarantine is account-scoped; `clear()` touches only the captured owner.

## Consequences

- Hive item-level storage remains a compatible future swap (interface
  seam); full-map single-doc writes continue but are serialized and
  single-per-mutation. Measured budgets in `docs/engineering/` track this.
- Existing tests encoding implicit persistence were migrated to explicit
  `persist()` (same assertions, new contract) — see commit history.

# ADR: Operation-Based Review Sync (WS3)

Status: accepted (client + function implemented; `review_operations`
table provision pending in staging/production setup — see transition plan).

## Context

Snapshot merge with `max()` counters loses independent recalls from a
shared base while claiming to preserve all evidence, commutativity and
associativity. Timestamp ties were argument-order dependent. Item-type
mismatch was not rejected.

## Decision

- `ReviewRecallOperation`: stable `operationId`, server-derived `userId`,
  item/exercise/correct/responseTime/occurredAt/deviceId/localSequence/
  schemaVersion/source. Deterministic server order
  `(occurredAt, deviceId, localSequence, operationId)`.
- Server (`mutateReviewState` action `applyRecall`): ledger row per
  (user, operationId) in `review_operations`; delta counter apply
  (typing correct counts 2, mirroring `MemoryScheduler`); newest-wins
  scheduling with lexicographic operationId tie-break; monotonic
  `lastReviewedAt`; bounded `recentOperationIds` (10) + verify-and-repair
  retry loop (max 3) for concurrent same-item writers; cross-type
  rejection; 400/403/413 validation parity with upsert.
- Snapshot merge kept as the backward-compatible read path with HONEST
  docs (monotonic lower bound, order-independent, no associativity claim,
  cross-type rejection).
- Outbox: recall ops preferred (one per answer); snapshot upserts remain
  for pull-adoption compat with single-write batching, duplicate-op
  coalescing, backoff/dead-letter preservation, and `ReviewSyncMetrics`
  (pending, oldest age, replay success/failure, dead-letter, duplicates,
  ops-per-answer, duration, bytes).

## Transition / rollback

- Old rows stay: snapshots are the baseline onto which op deltas apply.
- Setup: `scripts/create_review_collection.mjs --apply` provisions
  `review_operations` (indexes included); `appwrite_setup.mjs` calls it.
- Account deletion covers `review_operations` (same cascade).
- Rollback: stop sending `applyRecall` (clients fall back to snapshot
  upserts); ledger rows are inert history. Mixed-version clients are safe:
  old clients' snapshots merge via the compat path; their counters remain
  a lower bound until they upgrade.
- Old-client safety: unknown `stateJson` keys (`lastOperationId`,
  `recentOperationIds`) are ignored by `MemoryItemState.fromMap`.
