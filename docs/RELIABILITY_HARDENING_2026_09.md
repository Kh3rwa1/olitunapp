# Reliability hardening — September 2026

This is a reviewable reliability patch, not a claim of production readiness or a “10/10” certification. Based on main at `b0c9ab25358a6765d61466602d03513c32ebe386`.

## Changes

### Checkout ledger correctness

- Publish the initial canonical user/category ledger with an atomic create instead of an unconditional update.
- When another device/key already published a payable order, return that canonical order and its stored price. Do not replace the order a learner already received.
- Never downgrade a verified purchase while another checkout is completing.
- Repair a missing ledger before returning an idempotent retry's order; retain the original price if the catalog changes.
- Keep known gateway orders in a reconciliation-required state until ledger publication succeeds. Mark rejected state conflicts as blocked, not eligible for automatic granting.
- Do not reactivate a refunded order through its old idempotency key. A new repurchase uses an Appwrite transaction and clears the prior refund total; there is no unsafe plain-update fallback.
- Validate the gateway order's amount and currency and bound the order HTTP request with a timeout.

Different client keys can still create extra *unreturned* gateway orders. The patch guarantees a single canonical order returned by these checkout paths, not globally exactly-once provider-order creation. Further reduce unused orders with a server-side checkout reservation in a follow-up. The webhook, reconciliation worker, and purchase verifier still need a shared, fully audited payment state machine and real concurrency tests.

### Account deletion confirmation

- A 401 requires reauthentication; it is not successful deletion.
- A 404 from function execution propagates as an error and does not clear a valid local session.
- Require completed execution plus explicit deletion confirmation. Both the existing server's `code: account_deleted` and an explicit `authDeleted: true` are supported; generic `ok: true`, contradictory `authDeleted: false`, and unfinished execution are not confirmation.
- Preserve the distinction between confirmed partial deletion/reconciliation pending and successful full deletion.

### Durable offline outbox

- Do not retain a failed open Future or reuse the Future for an externally closed Hive box.
- Validate the JSON record's exact owner when reading or clearing queues; a user-ID prefix alone is not ownership.
- Add persistence, retry, completion, and prefix-sharing account-isolation tests using on-disk Hive storage.

## Validation

Local environment limitations: GitHub MCP source access works, but the sandbox has no Flutter/Dart SDK, direct GitHub DNS access, or installed node-appwrite package.

- The targeted checkout regression suite was executed locally using injected in-memory database/gateway dependencies and a local-only SDK/rate-limiter adapter. The adapter is not committed. This is isolated behavior testing, not live Appwrite or Razorpay validation.
- Run the committed suite with the real pinned SDK in CI: `npm ci && node --test functions/test/checkout_ledger_regression.test.js`.
- New Flutter tests: `test/core/auth/account_deletion_regression_test.dart` and `test/core/offline/mutation_outbox_regression_test.dart`. These were authored and reviewed but could not be executed locally.
- Existing `npm run test:backend` and `flutter test` discover the new tests automatically. Existing gates are not disabled, weakened, or bypassed.

## Required before merge/release

- [ ] `dart format --output=none --set-exit-if-changed .`
- [ ] `flutter analyze --fatal-infos`
- [ ] `flutter test --coverage`
- [ ] `npm ci && npm run test:backend`
- [ ] Exercise refunded repurchase against the deployed Appwrite version and function key scopes. The pinned node-appwrite 25.1.0 SDK exposes the transaction methods used here; deployed server support and authorization are not verified by mocks.
- [ ] Concurrent two-device checkout, provider callback, refund, and reconciliation tests in staging. Confirm only captured, correctly priced payments grant access and old refund callbacks cannot alter a new purchase.
- [ ] Real account deletion: expired session, missing function, partial cleanup, successful deletion, and independent server-side verification.
- [ ] Android offline lesson completion, process termination, restart, account switch, and reconnect/sync, including a low-end device.
- [ ] Replace the rendering-only assertions in `integration_test/journeys_integration_test.dart` with full workflow assertions. The new tests here do not turn those smoke tests into end-to-end tests.
- [ ] Audit the coverage allow-invisible list and measure whole-app coverage before changing its thresholds. The October 1 untested-file enforcement date and existing exclusions are not changed by this patch.

Do not auto-merge or deploy based only on the isolated local regression results.
