# Olitun Product-Quality Plan (concise, living)

**Base:** `main` at `c363d2f0` (clean tree, 2026-09-05). Reference `d0ab2339` is
historical only. This plan reuses existing reports instead of replacing them:
`docs/PRODUCTION_READINESS_REPORT.md`, `docs/EXPERIENCE_EVALUATION_2026_09.md`,
`docs/IMPLEMENTATION_STATUS_2026_09_05.md`, `docs/ENGINEERING_BASELINE.md`,
`docs/PRIORITY_HARDENING_2026_09_05.md`.

## Baseline (verified by inspection 2026-09-05)

**What already works**
- Origin-sequenced progress events wired into real writers
  (`user_stats_provider.dart:206,360,391` via `ProgressOriginIdentity`); refund
  crash-window recovery via `lastRefundClaimId` + idempotent `audit_<claimId>`
  (`functions/admin-maintenance/src/main.js:302-436`). Both have regression
  tests (`progress_merge_concurrency_test.dart`,
  `functions/test/payment_dispute_recovery.test.js`). Status: IMPLEMENTED —
  full suite must still pass in CI before any release claim.
- First-session skeleton exists: onboarding (6 steps, teaching-language gate) →
  home `NextBestActionCard` → lesson blocks → quiz → completion actions.
- Lesson load errors already show retry/back (`DetailLoadErrorBlock`); quiz
  completion guards duplicates; category recovery + large-text fixes landed.

**Demonstrated defects (this milestone)**
1. `NextBestActionCard` default "continue" branch + field initializers use
   hardcoded English (`'CONTINUE LEARNING'`, `'Next step in your journey'`,
   `'Consistent daily practice…'`, `'Choose one small practice step…'`,
   `'Continue'`) — untranslated for hi/bn/or/sat users; violates the 100%
   arb-parity contract and §6 localization rule.
2. `LessonBlockItemView` quiz branch returns `SizedBox.shrink()` for empty
   `quizId`, missing quiz, empty listening quiz, and quiz-load errors — a blank
   page with no explanation or action (§3C violation: dead end, no next step).
3. `QuizEmptyView` hardcodes `'Quiz not found'` (test asserts it) — same class
   of defect on the standalone quiz route.

**Important unverified assumptions** — no production reliability, device,
educator, or learning-effectiveness claims are made. Manual AT testing,
200% text audit of changed routes, profile-build performance, and staging paid
verification are all NOT RUN (see docs above for protocols).

## Work items (each: problem → evidence → change → acceptance → verification)

### 1. Localized continue action (this change)
- Problem: mid-journey learners see English-only "continue" copy.
- Evidence: `next_best_action_card.dart:33-36,119-122`.
- Change: reuse existing keys in all 5 locales — `resumeJourney`,
  `continueLearning`, `readyToLearn`, `continueButton`. No new keys (avoids
  fabricated translations; parity script stays green).
- Acceptance: no hardcoded user-visible strings in the card; card renders
  localized copy in en + one additional locale.
- Verification: new widget test; `flutter test test/features/home/widgets/
  next_best_action_card_test.dart`; `node scripts/check_l10n_parity.mjs`.

### 2. Visible inline-quiz unavailable/error states (this change)
- Problem: blank page when an embedded quiz can't load.
- Evidence: `lesson_block_item_view.dart:52,57,95,97-98`.
- Change: compact unavailable card (localized title via `noQuestionsYet` /
  `somethingWentWrong`, `skip` → `onDismiss`, `retry` → invalidate quiz
  provider). Preserves glass-card visuals, 48dp targets, semantics.
- Acceptance: every quiz branch shows loading, content, or an explained state
  with an action; no `SizedBox.shrink()` dead ends.
- Verification: new widget test for empty-quizId / error / missing-quiz states.

### 3. Standalone quiz not-found copy (this change, trivial)
- Problem/evidence: `quiz_empty_view.dart:31` hardcodes `'Quiz not found'`.
- Change: reuse localized `somethingWentWrong` + keep `goBack`; update test.
- Verification: existing `quiz_empty_view_test.dart` updated + passing.

### Deferred (release dependencies, NOT STARTED)
- Onboarding interruption loses in-memory choices (step/language/level/goals);
  persist partial state → recovery test. Dependency for §3B "preserve progress".
- Staging paid verification, device performance, AT manual passes, learner
  pilot protocol execution — all BLOCKED on hardware/credentials/humans; harness
  docs already exist (`docs/STAGING_SETUP.md`, `docs/EXPERIENCE_EVALUATION_2026_09.md`).
- New "up next: <lesson>" rationale copy needs fluent hi/bn/or/sat translations
  first — do not ship English placeholders as translations.

## Execution order
1. Items 1–3 now (small, independently reviewable, no auth/payment impact).
2. Onboarding persistence next. 3. Offline/accessibility passes per existing docs.
