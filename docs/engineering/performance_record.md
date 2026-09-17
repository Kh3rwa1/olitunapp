# Performance Record (WS11)

Method: `test/features/review/review_performance_test.dart` (repeatable,
asserted budgets) plus structural before/after counts enforced by tests.

## Measured (after, this hardening)

Environment: flutter test (macOS, mock storage backend).

| Budget | Result |
|---|---|
| One recall local persist latency (incl. JSON encode + write) | well under 2s budget (mock; asserts `<2000ms`) |
| 2000-item store load + 20-due selection | under 2s budget for selection |
| 20-card review session (20 recalls) | 20 writes total, under 10s budget |
| Writes per logical mutation | exactly 1 (`saveCallCount`, asserted) |

## Before/after (structural, test-enforced)

| Metric | Before (`a43349dd`) | After |
|---|---|---|
| Durable writes per `recordRecall` via notifier | 2 (implicit `_persist` + explicit `persist`) | 1 |
| Durable writes per `ensureIntroduced` via notifier | 2 | 1 |
| Full-map rewrites per pull adoption of N rows | N (fire-and-forget per adopt) | 1 (single batch persist) |
| Write serialization | waiting-only (invocation raced) | invocation-ordered (fake-timing tests) |
| Fixed-cap eviction risk | arbitrary active eviction at 2000 | removed (2100-item test retains all) |
| Outbox entries per answered question (new path) | 1 snapshot upsert | 1 stable recall op; duplicate delivery coalesced |
| Replay with 100 pending | unbounded re-push of current state per entry | single-flight, backoff-aware, dead-letter-skipping, metrics-observed |

## NOT VERIFIED (no devices/production in this environment)

Cold/warm startup, Home first render, real-device lesson/audio/review
memory, web bundle size, Android artifact size, Appwrite indexed-query
latency, 10k-operation event-store load. Mark all platform/production
performance claims NOT VERIFIED until measured on target hardware. The
`review_operations` indexes (`idx_ops_user_item`, `idx_ops_user_occurred`)
and existing `review_states` indexes cover the queried fields by design
(staging must confirm index build status).
