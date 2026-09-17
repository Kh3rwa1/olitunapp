# markMistakeMastered — recovery-task resolution (compat name)

> **Naming notice (WS5):** despite its name, this function does NOT award SRS
> mastery. It resolves a mistake *recovery task* (audit bookkeeping) when the
> learner explicitly completes review. Only `MasteryState.mastered` in the
> SRS scheduler is mastery. The Flutter client renamed its API to
> `resolveMistake`; `masterMistake` remains as a deprecated adapter
> (removal: v1.5.0). This function id is retained for deployed compatibility
> (older clients, outbox entries); a rename would require a function
> migration with dual-write, which is tracked but not scheduled.

- Identity is server-derived (`x-appwrite-user-id`, execute `["users"]`).
- Resolution is idempotent per `(userId, questionId)`.
- Failures must stay queued client-side (durable mistake outbox) and be
  retried; the server never fabricates SRS progress.
