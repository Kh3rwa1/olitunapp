# Release-readiness acceptance criteria

This is an evidence checklist, not a declaration that the app is "10/10" or production-certified. Baseline: `a391f89` (PR #271). Mark a validation item complete only with a commit, environment, result, and reproducible evidence.

## Changes in this follow-up

- Guard progress-sync entry and both asynchronous completion points against provider disposal. Keep in-flight repository work intact; ignore its UI/provider updates after the scope ends. This addresses the `UserStatsNotifier.syncPendingStats` failure recorded in PR #271, rather than suppressing the Android test or adding retries.
- Add six deterministic lifecycle tests: disposed entry, late success/failure, late stats reload, live success, and live failure. These cover the sync path, not every asynchronous operation in the application.
- Preserve typed content-list failures in `AsyncValue.error` instead of reporting a successful empty catalog. Add seven provider tests for data, legitimate emptiness, typed failures, retry recovery, and unexpected exceptions. This changes the provider contract; it does not certify every consumer's visual error/retry presentation.
- Remove the completed one-off Android diagnostics workflow and extend the existing experience diagnostics to include these source files and regressions. No release, security, coverage, or integration gate is relaxed.
- Flutter/Dart are unavailable in the editing sandbox. Added Flutter tests are not claimed locally executed; the PR's exact-commit CI results are authoritative.

## Automated acceptance — required before merge

- [ ] Formatting and fatal-info static analysis pass on the final PR revision.
- [ ] Full Flutter tests and the existing coverage policy pass; the new regressions run, not skip.
- [ ] Backend tests, dependency/security scans, and permission checks pass.
- [ ] Android emulator journeys and Chrome journeys pass, with no late async exceptions.
- [ ] Android/web build budgets and artifact-integrity checks pass.
- [ ] Reviewer confirms the changed content-list consumers expose useful error/retry states.

A passing rerun is not proof that an intermittent race was repaired. Retain the failure trace and a deterministic regression for each identified race. PR status is separate from post-merge and deployed-release status.

## Staging acceptance — required before a production release

Use `docs/STAGING_SETUP.md` and the existing staging workflow. Use isolated staging accounts and test-mode payment credentials; do not substitute production or paste secrets into chat.

- [ ] Buyer/non-buyer premium-content and media authorization behave correctly.
- [ ] Purchase confirmation, duplicate callbacks, refunds, and delayed/retried recovery preserve ledger and entitlement invariants.
- [ ] Offline progress/edit replay survives network transitions, restarts, and mixed client versions without losing accepted changes.
- [ ] Account deletion and retry cleanup complete with no retained personal data outside the documented policy.
- [ ] Restore rehearsal verifies document counts, IDs, permissions, and recovery from interrupted operations.

**Restore remains non-transactional.** Structural prevalidation is not atomic replacement. Network failures, schema rejection, or process timeout after deletion may require the safety backup. Do not describe disaster recovery as complete until this is rehearsed; a transaction/shadow-restore design is a separate engineering task.

## Device, accessibility, and learning acceptance

Use `docs/EXPERIENCE_EVALUATION_2026_09.md` and `docs/LEARNER_VALIDATION_PACKAGE.md`.

- [ ] Record startup, frame, memory, and media-loading measurements on representative physical Android devices, including a lower-end device; meet the repository's performance budgets.
- [ ] Exercise 200% text, screen-reader navigation, focus order, reduced motion, and narrow screens on real devices.
- [ ] Review translated/Ol Chiki copy and content accuracy with educators; distinguish automated rendering checks from pedagogical review.
- [ ] Observe real learners completing core journeys and record comprehension, friction, and completion outcomes.

## Engineering follow-ups not completed here

- Remaining lifecycle paths outside `syncPendingStats` need a separate audit and regressions.
- Large protected-media delivery still needs measured streaming/caching improvements without weakening entitlement checks.
- Release/staging configuration defaults need an explicit environment-isolation review.
- Broader localization and every screen's visual error/retry behavior are not certified by provider tests.
- Restore atomicity and physical-device/learner validation are not solved by a green CI badge.

This follow-up does not merge, deploy, change production permissions/data, or run financial operations. A higher product-quality rating should follow verified outcomes, not be assigned as a side effect of merging code.
