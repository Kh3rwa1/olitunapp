# ADR: Learner-State Authority

Status: accepted (forensic hardening, HEAD `a43349dd` + follow-ups).
Scope: every learner-state field — semantic meaning, authoritative owner,
local/remote representation, conflict policy, idempotency, derived views,
migration, ownership, deletion, analytics relationship.

Rules (enforced, tested):
- Analytics is NEVER transactional product authority.
- SRS mastery is NEVER inferred from stars.
- Lesson completion NEVER means content mastery.
- Mistake count is NEVER a second mastery field.
- Dashboards derive from documented authorities only.
- Every reward mutation is idempotent; retry never duplicates stars,
  minutes, completions, or mastered counts.

## Field authority table

| Field | Meaning | Authority (owner) | Local | Remote | Conflict policy | Idempotency | Derived views | Migration | Ownership | Deletion |
|---|---|---|---|---|---|---|---|---|---|---|
| Lesson completion | learner opened/finished a lesson unit | Lesson progress store (per-account) | account-scoped prefs/Hive | user progress docs | newest-wins per lesson id; offline completions union on reconnect | stable completion op per (user, lesson) | dashboards, streak inputs | none (starts empty) | AccountScope-partitioned | cascade on account delete |
| Quiz attempt history | immutable record of attempts/scores | Quiz history store (per-account, append-only) | account-scoped | user quiz docs | append-only, no conflicts | stable attempt id | averages, history UI | none | partitioned | cascade |
| Quiz score (per attempt) | score of one attempt | same as attempt (part of the record) | same | same | immutable once written | same id | best/last derived | none | partitioned | cascade |
| Review mastery | SM-2 lifecycle per canonical item | ReviewStore/SRS (local) + `review_states` snapshot + `review_operations` ledger (remote) | `review_states_<scope>` doc + op outbox | snapshot row + op ledger rows, owner RLS | op log (exact) / deterministic snapshot merge (compat) | operationId ledger | due queue, retention, recovery queue | receipted guest/legacy migration | partitioned + claim marker | cascade incl. `review_operations` |
| Mistake history | immutable incorrect-answer events | Mistake audit (append-only, per-account) | `user_mistakes_resolved_audit_v1_<suffix>` | `user_mistakes` docs | append-only union | record idempotency key | — | union migration | partitioned + one-time legacy claim | cascade |
| Current recovery queue | what to re-practice now | DERIVED from SRS + recovery criterion (no second state machine) | derived in memory | — (backend audit is history, not queue) | — | — | mistake review screen | derived post-migration | derived per owner | derived |
| Stars/rewards | earned currency | Gamification backend (server-authoritative totals) + local pending ops | account-scoped pending + cached totals | reward ledger | server wins; local pending replayed once | stable reward op id per (user, source, sourceId) | dashboards, premium gates | none | partitioned | ledger retained per legal policy, anonymized |
| Streak | consecutive active days | Server-derived from activity ledger (local cache display only) | cached value + last-active date | activity ledger | server recompute wins | date-keyed | dashboard | none | partitioned | cascade |
| Daily missions | assigned + completed tasks | Mission service (server assigns; local completion ops) | account-scoped completion ops | mission docs | completion union per (user, day, mission) | stable completion id | home cards | none | partitioned | cascade |
| Learning time | minutes practiced | Activity ledger (server totals; local pending increments) | pending increments | ledger | additive, idempotent per session id | session id | dashboard, retention | none | partitioned | cascade |
| Retention metrics | D1/D7/D30 recall, lapse rates | DERIVED from SRS `firstRecallAt`/counters (never approximated from counts alone) | derived | derived from snapshots | — | — | analytics dashboards | derived | derived | derived |

## Cross-system transitions (contract-tested)

- learn → quiz correct: one recall op (correct) + quiz attempt record.
- learn → quiz wrong: one recall op (failure) + one mistake event.
- wrong → review: SRS schedules; queue derives the need.
- review → recovered: recovery criterion met (new successes after record).
- recovered → mastered: SM-2 thresholds only (never one answer).
- offline completion → reconnect: outbox replay, union/append semantics.
- duplicate mutation replay: ledger/idempotency-key dedupe, no double apply.
- account switch: scope capture → persist under captured owner → re-verify →
  publish; stale never published, never written into the new account.
- guest → account: receipted migration with per-item deltas; reruns converge.

## Alternatives considered

- Hive item-level review storage (preferred by the brief): deferred. The
  current single-doc-per-owner JSON behind `ReviewStateLocalRepository`
  satisfies serialization, durability-before-success, observability and
  testability; the interface allows a Hive item-level swap without caller
  changes. Full-map rewrite per answer is thereby contained to one
  serialized write per logical mutation (no duplicates), with item-level
  Hive tracked as follow-up work in the checklist (NOT VERIFIED as done).
- Max-based snapshot merge as the convergence story: rejected as the
  authority (kept only as the backward-compatible read path with honest
  lower-bound documentation). The operation log is the authority.
- Second mastery counter in mistakes: removed. `masteredCount` derives
  from SRS; the legacy key is read-only compat.
