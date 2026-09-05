# Progress & Refund Verification Report

Single verification record for the progress-compaction and refund-recovery
work. No prior report is superseded: `docs/PRODUCT_QUALITY_PLAN.md` remains
the product plan; this file records evidence only. Nothing here claims
production readiness, device testing, educator approval, or staging results.

## 1. Working state

- Base: `main` at `9751711a` (clean tree at start; no reset performed).
- Branches (local, unpushed — no remote changes performed):
  - `fix/progress-compaction-ledger` (2 commits: implementation, tests).
  - `fix/refund-operation-recovery` (2 commits: server/tests, admin/tests).
- Toolchain: Flutter 3.35.7 / Dart 3.9.2 / Node v22.22.3 (repo-pinned).

## 2. Progress compaction: repro outcomes (VERIFIED)

Reproduced against current code with the REAL `mergeProgressStats`, before
any fix, in `test/features/profile/progress_compaction_cases_test.dart`:

| Case | Required | Observed pre-fix | Observed post-fix |
|------|----------|------------------|-------------------|
| A: two disjoint 101-event compacted legacy histories merged | 202 | 201 | 202 |
| B: 601 events, compact, replay earliest-100 twice | 601 → 601 → 601 | 601 → 602 → 603 | 601 → 601 → 601 |
| C: seqs 2..103 compacted, late seq 1 same origin | 103 | 102 | 103 |

Root causes (all demonstrated, not assumed): shared `__discrete__` base
merged with max() (A); 500-entry compacted-tracking prune plus refold
ratchet (B); checkpoint advanced over unseen sequences (C); numeric-suffix
sequence inference (`star_123` parsed as sequenced, regex fallback).

## 3. Progress fix: what changed and why (VERIFIED)

- `lib/features/profile/data/repositories/progress_merge_crdt.dart`:
  folded ledger (`key -> value`, union-with-max, counted in totals);
  checkpoints advance only over contiguous folded runs from the previous
  frontier; live events included iff absent from the ledger and uncovered
  by a checkpoint; ledger eviction only for checkpoint-covered entries;
  shared `__legacy__`/`__discrete__` keys are frozen read-only (never
  written by merge); numeric-suffix inference removed (underscore form
  sequenced only for counter-backed `c_*` installation origins; explicit
  `origin:seq` form kept). Full invariants documented in the file header.
- `user_stats_entity.dart`: `compactedStarEvents`/`compactedMinuteEvents`
  (lossy ID sets) replaced by `foldedStarEvents`/`foldedMinuteEvents`
  (value-carrying ledgers).
- `user_stats_model.dart`: wire keys unchanged (`compactedStarEvents`);
  reads accept legacy lists (migrating to zero-valued exclusion markers,
  totals and stale-protection preserved exactly) and new maps; old readers
  iterate map keys and degrade gracefully.
- `user_stats_provider.dart`: serialized mutation chain (`_runSerialized`)
  around the seven read-modify-write entry points — overlapping `addStars`
  calls were demonstrably dropping earnings (got 4, lost 3; now 7).
- No changes to quiz/lessons/mastery/streak/epoch semantics, guards, or
  total-recomputation discipline.

## 4. Progress regression evidence (VERIFIED)

- `flutter test test/features/profile/` — all pass, including 12 new case
  tests (A/B/C, minutes parity, mixtures, serialization both shapes,
  restart round-trip, groupings, idempotence, generations, 1200-event
  scale) and the concurrent-notifier test.
- Existing `progress_merge_concurrency_test.dart` passes with
  representation-mapped assertions (old internals such as
  `starCheckpoints['devA'] == 500` replaced by ledger equivalents;
  every total/behavior assertion preserved or strengthened — no coverage
  removed).
- Full `flutter test` suite: 1908 passed, 0 failed.
- `flutter analyze`: no issues. `dart format`: clean. File-length gate:
  pass. No coverage thresholds, security checks, or release gates touched.

## 5. Legacy migration honesty (IMPLEMENTED, NOT VERIFIED in production)

- Recoverable exactly: live keys, ledger entries, contiguous prefixes.
- Ambiguous: unattributed remainder totals and pre-migration folds the old
  shared-base representation already max-merged. Preserved verbatim, never
  reconstructed or overwritten.
- Policy: migration invents no events and never reduces a stored total.
  Any stronger reconciliation (e.g. attributing ambiguous remainders to a
  device) requires explicit owner approval — NOT STARTED.

## 6. Refund recovery: repro + fix (VERIFIED locally, BLOCKED live)

- Demonstrated pre-fix: a keyless `record_refund` call committed a FULL
  refund with zero claim record; a failed audit write on that path could
  never be repaired (retry short-circuits as already-refunded).
- Server (`functions/admin-maintenance/src/main.js`, function-local —
  canonical shared `payment_state.js` untouched, sync check passes):
  durable operation identity required (400) before any bookkeeping;
  `operationKey`/`idempotencyKey` (identity) distinguished from optional
  informational `gatewayRefundId`; `amountPaise` documented as the
  cumulative total under preserved max-floor semantics; unique-`refundId`
  collisions fail closed with a recovery directive; ledger-write conflicts
  resume when the operation's own claim shows progress, else rethrow.
- All five interruption points plus concurrent same-key retries,
  conflicting payloads, multi-operation purchases, partial/full
  bookkeeping, legacy already-refunded rows, K1-after-K2 recovery, and
  audit-409 convergence are covered by 12 new tests in
  `functions/test/admin_refund_operation_identity.test.js` (real handler,
  fault injection) — all pass; full Node suite 199/199 pass.
- Admin client (`purchases_provider.dart`, `purchases_actions_helper.dart`):
  server-authorized recording with deterministic per-(purchase, amount)
  keys, all six result states, duplicate-submit prevention, list refresh,
  small-screen coverage — 14 Flutter tests pass; pre-existing hang-prone
  tests rewritten to the new contract (fail-closed without identity;
  unreachable function service).

## 7. Deployment and staging contracts

- Schema: NO migration required — every attribute the new code reads or
  writes (`refund_claims.*`, `course_purchases.lastRefundClaimId`, audit
  fields) already exists in `test/fixtures/schema/` and
  `scripts/appwrite_setup.mjs` (verified by inspection).
- Deploy: redeploy the `admin-maintenance` function bundle only; no other
  function changed. Rollback: redeploy the previous bundle (old clients
  sending `externalRefundId`-only keep working via the documented
  fallback chain; new audit metadata fields are additive).
- Staging verification: BLOCKED — missing `STAGING_APPWRITE_API_KEY`,
  `APPWRITE_API_KEY`, `RAZORPAY_KEY_ID/SECRET`, `RAZORPAY_WEBHOOK_SECRET`
  (verified via secret-name listing; no values requested or handled).
  The paid-journey checklist (§8-equivalent: buyer grant, non-buyer
  denial, media binding, refund propagation, restore, pending/failed
  states, deletion) is prepared in `docs/STAGING_SETUP.md` but NOT RUN.
  Release gates stay fail-closed.

## 8. Product spot-checks (VERIFIED where stated)

- New refund dialog: small-screen (320px) completion without overflow
  (automated); all result states covered (automated). 200% text, manual
  screen-reader pass, and keyboard/focus review: NOT RUN (need humans).
- Prior journeys (onboarding recovery, continue action, quiz states,
  offline indicators) unchanged by this work; full suite green.
- Performance: NOT MEASURED (no device; debug timings not claimed).

## 9. Human validation handoff (NOT STARTED — package ready)

Reuse `docs/LEARNER_VALIDATION_PACKAGE.md` (proposal, never run). Owner
checklist:
1. Fluent-speaker/educator review of lesson content AND the new
   refund-dialog/admin copy (admin copy is English-only by convention;
   confirm that convention still holds).
2. Moderated pilot (10–15 learners) incl. first-session completion and
   confusion observations.
3. Immediate + delayed learning checks per the package outline.
4. Physical low-end-device testing (cold start, lesson load, offline kill,
   200% text, TalkBack/VoiceOver).
5. Controlled-rollout monitoring (stars-totals distribution for
   compaction anomalies; refund claim/audit lag alerts).
6. Backup restoration and rollback exercises (content + function bundle).

## 10. Known residual risks

- Multi-partial refunds accumulate by max-floor, not sum: `amountPaise`
  must be the cumulative total. A sum-based contract needs compare-and-swap
  primitives Appwrite does not offer — owner decision required.
- Concurrent distinct-key operations may share a refund epoch (amounts
  still converge; epoch is a marker, not a lock).
- Uncovered ledger entries are retained without a numeric cap; the bound
  argument is the finite legacy universe plus reorder windows (documented
  in code). Steady-state for well-formed streams is tiny (verified by
  test); pathological reorder beyond thousands is untested.
- Shared pre-migration history across devices stays ambiguous (see §5).

## 11. Status summary

- Progress repro/fix/regression: VERIFIED (evidence §§2–4).
- Refund server/admin implementation + tests: VERIFIED locally
  (evidence §6); live behavior: BLOCKED (§7).
- Migration policy: IMPLEMENTED, NOT VERIFIED in production (§5).
- Staging/device/educator/learner validation: BLOCKED or NOT STARTED
  (§§7–9).
- Remote/production changes performed: NONE. No pushes, merges, deploys,
  permission/data changes, credentials handled, or financial operations.
