# Dead-Code / Overlap Inventory (WS12)

Rule: never delete an old implementation until repository-wide references,
deployed-function inventory, migration needs, and rollback requirements are
checked. Deployed webhooks, schedules, and older clients may use functions
that Flutter no longer references.

## Review/sync overlap

| Candidate | Refs (repo) | Deployed (`appwrite.config.json`) | Verdict |
|---|---|---|---|
| `ReviewStateMergePolicy.merge` (snapshot) | sync pull path, migration compat | n/a (client) | ACTIVE (compat read path; op log is authority) |
| `review_state.upsert` outbox type | sync enqueue/replay | n/a | ACTIVE (compat for pull-adoption + old clients) |
| `review_state.recall` outbox type | sync enqueue/replay, repo | needs `review_operations` table | ACTIVE (preferred path) |
| `ReviewStore.recordRecallDurable` / `ensureIntroducedDurable` | tests, migration compat | n/a | ACTIVE (single-write helpers) |

## TTS overlap

| Candidate | Refs | Deployed | Verdict |
|---|---|---|---|
| `santaliVoice` | Flutter voice feature, config, setup scripts | yes (`execute:["users"]`) | ACTIVE |
| `generateAudio` | NONE in `lib/`, `scripts/`, or other functions (docs-only mentions) | yes (`execute:["users"]`) | COMPATIBILITY-ONLY — do NOT delete without deployed-usage telemetry (older clients/schedules may call it) and a removal migration. Removal: NOT VERIFIED. |

## Mistake overlap

| Candidate | Refs | Deployed | Verdict |
|---|---|---|---|
| `recordMistake` | mistake outbox `record` | yes | ACTIVE |
| `markMistakeMastered` | mistake outbox `resolve` (compat id) | yes | ACTIVE (compat id; semantics documented as task resolution, client renamed to `resolveMistake`) |
| `completeMistakeReview` | mistake outbox `complete` | yes | ACTIVE |
| `getUserMistakes` | backend sync pull | yes | ACTIVE |
| `MistakeNotifier.masterMistake` | none (migrated to `resolveMistake`) | n/a | DEPRECATED adapter, removal v1.5.0 |

## Rollback notes

- `applyRecall`/`review_operations` are additive: rollback = stop sending
  `applyRecall`; ledger rows are inert. Snapshot-only clients unaffected.
- Migration ledger keys (`review_migration_ledger_*`, `review_legacy_claim_v1`)
  are additive; old builds ignore them. Guest migration in old builds uses
  the unreceipted single-shot (documented residual double-add risk on crash
  for pre-hardening clients — resolved by upgrading).
- Scoped mistake keys are additive; legacy global keys are claimed once and
  removed. Old builds with legacy keys still function until upgrade.
