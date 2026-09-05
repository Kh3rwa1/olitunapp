# Payment-state hardening: release validation

## Change and compatibility

The deployed verification, webhook and scheduled payment-recovery entrypoints wrap Appwrite Databases with the shared payment-state adapter. The adapter re-reads and validates the purchase inside a 15-second optimistic transaction and never falls back to a plain update. All three function packages pin node-appwrite 25.1.0, matching the root test SDK.

Capture/recovery cannot restore refunded, disputed, revoked or unknown states. A committed payment claim cannot be used to re-verify a non-verified ledger. Late failed events cannot downgrade terminal states; partial refunds preserve a dispute; full refunds remain monotonic; stale refunds cannot affect a replacement order. Legitimate dispute-won processing can restore a non-refunded disputed purchase.

Missing ledgers are deliberately NOT recreated as verified by scheduled recovery: an old attempt cannot distinguish a lost initial write from a deleted purchase. Such attempts remain unresolved for manual reconciliation. Monitor the recovery failed count after deployment.

Existing factory-injection tests remain transport/schema tests. payment_runtime_guard.test.js calls the actual default entrypoints and mocks only SDK I/O, testing that the state adapter is wired into production. This is not a live Appwrite or Razorpay E2E suite.

## Evidence

- Local: node --test functions/test/payment_state.test.js — 30 passed, 0 failed, 0 skipped.
- GitHub CI: consult this PR's checks for the full backend suite, the additional 8 default-entrypoint tests, builds and security checks. These were not executed locally: sandbox DNS prevents installing the SDK dependencies, and Flutter is unavailable.
- No merge, deployment, live payment, refund, account deletion or device test was performed by this patch.

## Mandatory before deployment

1. Use a separate staging Appwrite project, never the production project. Configure STAGING_APPWRITE_ENDPOINT, STAGING_APPWRITE_PROJECT_ID and STAGING_APPWRITE_API_KEY in GitHub Actions secrets; never paste keys into chat or source control.
2. Confirm the deployed Appwrite version and each function's real execution key support transaction create/read/update/commit/rollback. Unsupported or denied transactions fail closed and will prevent payment grants. Verify the SDK installation in each isolated function package, not only root npm tests.
3. In Razorpay test mode with disposable staging users, prove capture -> verified, duplicate capture -> no duplicate grant, dispute/refund -> revoked access, late verification/capture -> no restoration, and partial refund during dispute -> still disputed.
4. Exercise simultaneous verification/refund/dispute requests against the real database. Require a transaction conflict rather than a lost update, successful webhook retry, and the correct final ledger and claim states.
5. Verify legitimate dispute-won processing, new checkout after refund, and late events from the old payment cannot modify the new purchase. Do not infer ordering guarantees for distinct dispute IDs from these tests; validate gateway event ordering or add explicit dispute identity/version persistence if the integration requires it.
6. Confirm scheduled recovery leaves blocked/missing purchases unresolved and alerts an operator, rather than repeatedly granting them.
7. Complete the existing mandatory staging/schema/concurrency workflow, actual account deletion/recovery, and physical-device consent/offline-restart checks from PRIORITY_HARDENING_VALIDATION.md.

Record the commit, deployment IDs, workflow/run links, disposable test IDs, expected/observed states and screenshots before approving release. Retain existing deployment permissions and do not weaken release gates to obtain a green result.
