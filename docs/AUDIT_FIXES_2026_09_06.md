# Audit follow-up: restore, release evidence, and startup

Base: `0e0730f66c2e596305b7fca1a255255f6adcf7de`.

## Status of the five technical findings

1. **Restore validation:** the production `restoreContent` entry point now delegates to a validated runtime path. The entire replacement set is checked and materialized before any deletion. Required collections cannot silently default to empty. Validation checks the envelope version/date/database, per-collection counts, unique document IDs, and permission array shapes. Explicit empty arrays with matching zero counts remain supported.
2. **Progress mixed-version format:** already merged in #270 before this branch. No progress code is modified here. Keep upgrade, rollback, and mixed-version regression coverage, including any intermediate map-shaped payloads written by the preceding build.
3. **Refund audit recovery:** already merged in #270 before this branch. The new subsumed-resume logic is preserved unchanged; no financial state-machine changes are made here.
4. **Release evidence:** release validation now requires the latest successful push runs of both canonical Flutter CI and security scanning for the exact selected commit. Missing, failed, pending, cancelled, or incomplete evidence blocks release. The existing mandatory live-staging dependency is unchanged. The release critical-learning coverage threshold now matches CI's 70%; this is not a whole-app coverage claim. Artifact verification is labelled as such, not a live deployment.
5. **Optional-startup delay:** ads, notifications, telemetry, and display setup are initiated after the first usable app frame rather than awaited before the app is mounted. Required storage and audio-platform readiness remain guarded. Optional failures/timeouts are still isolated by the existing startup runner, and normal widget rebuilds do not repeat initialization.

## Automated verification

- Executed locally in the editing sandbox: 30 new focused Node tests passed (18 production restore-path tests and 12 release-gate tests), using Node 24.14.1 and mocked I/O. No Appwrite/Razorpay/production mutations were performed.
- Added three Flutter widget tests for post-frame start ordering, rebuild deduplication, and a hung/late-failing optional SDK.
- Full Node Serverless Function Tests passed on GitHub CI with Node 22 at `34bdb98a8a26b4358dc4f74b80ee9740bbb602a5`, after correcting API URL construction and adding explicit request-target assertions. CI job: https://github.com/Kh3rwa1/olitunapp/actions/runs/34005804668/job/101412667690 .
- Applied the Flutter formatter's reported change to the new widget test. A temporary same-repository diagnostics workflow was removed after diagnosis; its report is retained on PR #271.
- Flutter/Dart and a full checkout were unavailable in the editing sandbox. The final branch head still requires green repository CI for formatting, static analysis, Flutter tests/coverage, security, and platform builds before merge. The successful Node job above is scoped to its recorded commit, not an assertion that all final-head checks passed.

## Important remaining limits

- Restore is **not transactional**. Structural validation prevents malformed backups from wiping data, but network failures, backend schema rejection, or a process timeout after deletion may still leave a partial restore. Preserve the outer handler's safety backup and rehearse recovery in isolated staging. This change does not claim atomic replacement, field-by-field live-schema validation, or completed disaster-recovery testing.
- Complete legacy restore files must include the metadata, counts, and explicit permissions emitted by the current backup builder. Partial exports are intentionally rejected by destructive restore; do not synthesize missing collections as empty.
- Live buyer/non-buyer authorization, media isolation, refund propagation, account deletion, and real backend concurrency remain unverified here. Provision staging through the existing `docs/STAGING_SETUP.md` process; do not paste credentials into chat or substitute production.
- Device performance, 200% text, TalkBack/VoiceOver, educator review, and learner pilots are not completed by this PR. Use `docs/EXPERIENCE_EVALUATION_2026_09.md` and `docs/LEARNER_VALIDATION_PACKAGE.md` for the existing procedures.
- The separate review suggestions concerning large-media delivery, broader localization, configuration defaults, and content-list error presentation are not claimed fixed by this focused PR.

## Review and release

Keep the PR draft until automated checks and the startup behavior review pass. No merge, deployment, signing operation, permission migration, or production-data change is authorized or performed by these commits. After approval, deploy the admin-maintenance bundle and rebuild the client through the normal release process; do not relax staging or security gates to ship the changes.
