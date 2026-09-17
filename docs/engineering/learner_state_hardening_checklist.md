# Learner-State Forensic Hardening — Audit Checklist

Audited HEAD (baseline): `a43349dd50c2f863fb06a5761e8d002f59a0cece`
Default branch: `main`
App version at baseline: `1.3.1+30`
Latest release at baseline: `olitun v1.3.1` (2026-09-12)
CI status at baseline (branch `main`): all green
  (Flutter CI, Security Scanning, Release Please, pages-build-deployment,
  Staging & Infrastructure Health Check — all `success`)
Open PRs that may overlap (non-exhaustive, dependabot-only at baseline):
  no open feature PR overlaps this work; ~30 dependabot bumps
  (setup-node, setup-java, path_provider, appwrite, razorpay_flutter,
  node-appwrite x N, checkout) plus release-please 1.4.0 — none touch
  learner-state semantics.

Last independently audited commit: `a43349dd` (= baseline; PR #370
"P0 learner-state repair"). Its 18-file change set is the starting point.
Inventory of files changed since that commit at start of this hardening:
  none (HEAD == audited commit; trees verified identical to the merged PR
  branch tip `37639978`).

Baseline gates (recorded 2026-09-17, HEAD `a43349dd`):
- `dart format --output=none --set-exit-if-changed .` → 1 pre-existing
  drift: `test/ai_studio_sdk_temporary_test.dart` (unrelated, reported
  separately; not touched by this hardening unless required).
- `flutter analyze --fatal-infos` → clean.
- `flutter test --concurrency=4 test/features/review/p0_learner_state_repair_test.dart`
  → 33/33 pass (the P0 suite from #370).
- `npm run test:backend` → 433 pass, 0 fail, 2 skipped.
- `check_architecture_boundaries.mjs` → pass (749 files, 0 violations).
- `check_l10n_parity.mjs` → pass (373 keys, 5 locales 100%).
- `check_review_corpus_ids.mjs` → pass.
- `verify_pinned_actions.mjs` → pass (67 refs pinned).
- `verify_node_dependency_alignment.mjs` → pass.
- `check_dependency_freshness.mjs` → pass.

> Do-not-proceed rule: no unrelated pre-existing failures were found, so
> hardening proceeds. The single `dart format` drift is pre-existing and
> unrelated; it is left untouched and reported separately.

## Invariant index

| # | Issue | Invariant | Files / classes / functions |
|---|-------|-----------|------------------------------|
| 1.1 | `persist()` calls `setString` before chaining onto `_persistQueue` — queue serializes waiting, not invocation | WS1: one unambiguous persistence boundary; serialized mutation operations | `lib/features/review/data/review_store.dart` — `ReviewStore.persist`, `_persistQueue`, `_persist` |
| 1.2 | `recordRecall`/`ensureIntroduced` persist internally AND notifier calls `persist()` again → duplicate full-map writes per mutation | WS1: one durable write per logical mutation | `ReviewStore.recordRecall`, `ensureIntroduced`, `recordRecallDurable`, `ensureIntroducedDurable`, `ReviewStoreNotifier.recordRecall`, `ensureIntroduced` |
| 1.3 | Full-map JSON rewrite per mutation; SharedPreferences as mutable DB | WS1/WS11: no full-map rewrite per answer; item-level storage | `ReviewStore.persist`, new `ReviewStateLocalRepository` |
| 1.4 | 2000-item cap can evict arbitrary active item (`_evictAndIntroduce` falls back to `values.first`); eviction not reflected remotely | WS1: never silently evict fresh/learning/review | `ReviewStore.maxItems`, `_evictAndIntroduce` |
| 1.5 | Persistence failure does not propagate deterministically; fire-and-forget `_persist()` swallows durability | WS1: awaited local durability before success; observable failures | `ReviewStore._persist`, `adoptRemote`, `reconcile` |
| 1.6 | No local repository interface → tests use SharedPreferences mocks, cannot reproduce delayed/out-of-order native persistence | WS1: replaceable storage interface + delayed fake | new `review_state_local_repository.dart` |
| 1.7 | Account switch mid-write can publish stale state / write into new account | WS1: capture scope → compute → persist under captured scope → re-verify → publish | `ReviewStoreNotifier` transaction sequence, new `AccountScopeError` |
| 2.1 | Legacy `review_states_v1` importable by >1 account; no claim marker | WS2: claim once, quarantine ambiguous | `review_store.dart` `load`, new `review_migration_ledger.dart` |
| 2.2 | Guest migration adds counters; crash between account write and guest clear double-counts on rerun | WS2: idempotent, resumable, crash-safe at every step | `review_state_migration.dart` `migrateGuestToAccount` |
| 2.3 | No durable migration metadata (only timestamps) | WS2: migration ID, source/dest scope, schema versions, fingerprint, status, startedAt/updatedAt, failure reason | new `review_migration_ledger.dart` |
| 3.1 | Snapshot merge uses `max()` for counters — loses independent recalls from shared base; claims "all evidence preserved" | WS3: operation-based idempotent sync; no false claims | `review_state_merge_policy.dart`, new `review_recall_operation.dart`, `functions/mutateReviewState/src/main.js` |
| 3.2 | Merge claims commutativity/associativity; equal timestamps make `lastExerciseType`/`nextReviewAt`/`itemType` argument-order dependent | WS3: deterministic order, no argument-order dependence | `ReviewStateMergePolicy.merge` |
| 3.3 | Item-type mismatch not rejected; scheduler failure transitions order-sensitive; comments/tests still say LWW in places | WS3: reject cross-type merge; deterministic failure ordering; remove false LWW claims | `review_state_merge_policy.dart`, `review_state_sync.dart` header |
| 3.4 | Outbox enqueues snapshots keyed `review_<item>_<ts>` — replay pushes same current state repeatedly; timeout retry double-counts | WS3/WS7: stable recall operations, idempotent by `operationId`, coalesced snapshot compat | `review_state_sync.dart` `enqueueLocalMutation`, new operation path |
| 4.1 | `validateQuestionIdentity` only checks non-empty; fake/tombstoned IDs pass; both IDs silently prioritize word; legacy unattributed; admin-only enforcement | WS4: domain+admin+repo+backend+CI+runtime layers; exactly-one source ID; corpus resolution; tombstone/alias/collision checks | `quiz_model.dart`, `quiz_memory_resolver.dart`, `quiz_validation.dart`, `question_editor.dart`, `scripts/check_review_corpus_ids.mjs`, backend publish boundary |
| 5.1 | Local mistake keys global (`user_mistakes_list`, `user_mistakes_mastered_count`, `user_mistakes_resolved_audit_v1`); cross-account suppression; Review treated as mastered; remote failure swallowed; two mastery lifecycles | WS5: SRS authority; account-scoped audit; derived recovery queue; idempotent durable operations; rename misleading APIs | `mistake_provider.dart`, `review_store.dart`, `review_item.dart`, `functions/{recordMistake,markMistakeMastered,completeMistakeReview,getUserMistakes}` |
| 6.1 | Overlapping meanings of progress (lessons, quiz, stars, SRS, mistakes, missions, analytics) with no documented authority | WS6: ADR `docs/architecture/learner_state_authority.md` | new ADR + contract tests |
| 7.1 | Per-recall snapshot upserts; replay repeats current state; full-map writes; parallel sync triggers; no dead-letter visibility | WS7: stable operation enqueue; safe coalescing; backoff/DLQ preserved; metrics | `review_state_sync.dart`, `mutation_outbox_service` metrics |
| 8.1 | santaliVoice falls back to `x-appwrite-user-id`; quota reserved before synthesis; failure billing ambiguous; cache/retention/deletion unverified | WS8: verified JWT identity, fail closed; explicit quota state machine; privacy/retention; platform journeys or NOT VERIFIED | `functions/santaliVoice/*`, `lib/features/voice/*`, setup scripts |
| 9.1 | Client-grantable entitlement; webhook replay/verify retry double-grant; refund/revocation; offline grace; account scoping; log hygiene | WS9: server-authoritative price/currency/product/owner; signed webhooks; idempotent reconcile; bounded grace | `functions/{createRazorpayOrder,razorpayWebhook,verifyCoursePurchase,reconcilePaymentAttempts}`, premium providers |
| 10.1 | Green repo CI ≠ live Appwrite/functions/payments/TTS/ads/notifications/real-device proof | WS10: PR CI vs authenticated staging gate split; fail-closed staging journeys with SHA-bound evidence | `.github/workflows/*`, `RELEASE_CHECKLIST.md`, staging scripts |
| 11.1 | No measured budgets; full-map rewrite per answer; duplicate persist per answer; unbounced replay; unpaginated reads | WS11: measured before/after budgets; bounded replay; pagination; indexes | benchmarks + code |
| 12.1 | Stale affirmations refs; stale LWW descriptions; undocumented authority/sync/migration/scoping/TTS/gates/rollback; overlapping functions (`generateAudio` vs `santaliVoice`, mistake fns) | WS12: doc corrections; dead-code process (active/compat/deprecated/removable) | `ARCHITECTURE.md`, `README.md`, `RELEASE_CHECKLIST.md`, function READMEs, deletion inventory, privacy/schema docs |

## Per-issue tracking columns (filled as work lands)

- reproduction test → implementation status → verification status →
  migration impact → rollback impact.
- See sections below; each closed finding in the final report cites exact
  file, class/function, test file, test name, commit SHA, and the
  enforcement mechanism (never "fixed" for stubs/comments/TODOs/mocks only).
