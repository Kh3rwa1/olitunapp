# Production-hardening implementation — 5 September 2026

This is a first hardening pass, not a production-readiness or “10/10” certification. The existing aggressive reminder schedule is deliberately unchanged. No merge, deployment, payment, or real account deletion was performed.

## Implemented in this pull request

- **Deletion safety:** `del_` plus the full 32-character pseudonymous digest fits Appwrite's 36-character ID constraint. Non-404 storage failures preserve the asset registry and Auth user. A failed page stops retrying within the same invocation; a later request resumes cleanup. Storage 404 remains idempotent success.
- **Payment contract:** canonical provider/payment/order/paid-amount/date fields are decoded with legacy compatibility. Canonical zero remains authoritative; null additive attributes remain compatible with legacy rows. Fractional, negative, or malformed paid amounts are rejected rather than silently rounded. Expected price is not paid revenue.
- **Admin queries:** use system creation time instead of nullable legacy purchase dates. Canonical provider values take precedence; legacy filtering is used only for null/empty canonical provider values. Existing refund and export behavior is otherwise preserved.
- **Quiz correctness:** completion is guarded against duplicate calls and unanswered steps. Reward amounts are captured before asynchronous persistence, so resetting the screen cannot change a previous session's reward. Out-of-hearts failures record results without awarding stars, matching the existing stated rule.
- **Learning recovery:** category loading has back navigation; errors and missing categories have retry/back actions rather than indefinite spinners. Recovery content scrolls at large text sizes. Lesson and script providers are not loaded until the category exists.

## Verification actually performed

- JavaScript syntax check passed for the modified deletion handler.
- Eight new handler regression tests passed locally using injected DB/Storage/Auth doubles and a local SDK-construction/query-serialization stand-in. This was **not** a live Appwrite test and did not validate the installed SDK or deployed schema.
- The same tests failed 8/8 against the original source, failed 5/8 with only the ID fix, and passed 8/8 with the complete deletion patch.
- Added Flutter payment-contract, quiz concurrency/reset, and category recovery/large-text tests. Flutter/Dart are unavailable locally; these tests and formatting/static analysis must pass in CI before merge.
- No CI thresholds, security checks, or release gates were weakened. The draft must remain unmerged while any required check fails or is pending.

## Required staging and release checks

1. Run existing backend tests plus `functions/test/delete_account_asset_retry.test.js` with the real locked dependencies. Exercise storage failure -> later retry -> success and >100 assets using disposable staging users only.
2. Run targeted Flutter tests, the full suite/coverage, formatter, and static analysis. Validate the integrated branch, not just individual commits.
3. Confirm Appwrite canonical and legacy payment attributes/indexes support the grouped provider filters. Inspect historical malformed amounts before enabling strict parsing broadly.
4. Test the learning recovery flow and quiz double taps on representative devices, with screen readers and 200% text. New recovery copy still needs inclusion in the app's comprehensive localization pass.

## Not fixed or certified by this PR

- Multi-device progress merging, reset epochs and durable reward-event idempotency. The quiz guard is session-local, not a transactional backend reward ledger.
- Offline outbox scheduling/durability and reactive cross-device entitlement revocation.
- Paid lesson/media authorization. Test direct Appwrite access as a nonbuyer; a client paywall is not backend authorization. Any permission migration needs staged compatibility and rollback planning.
- Reconciliation manifest parity and required Auth scopes in the deployed backend.
- Whole-home grid semantics/adaptive layout, comprehensive localization, learner usability testing and measured physical-device performance.

These remain release gates and follow-up implementation work. Keeping aggressive reminders is an explicit product choice, not an unresolved reduction recommendation.
