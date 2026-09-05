# Conservative dispute safety patch

## Behavior and trade-off

Dispute webhook delivery order is not proof of dispute identity or finality. The payment transaction guard now refuses restorative dispute writes (`status: verified`) while retaining terminal refund/revocation protections and all existing capture/binding/transaction checks.

This is a containment measure, NOT complete dispute reconciliation. A legitimate won dispute also stays blocked until an operator uses a reviewed, server-authoritative reconciliation process. A delayed created event can still block access. Do not deploy without an operational recovery process and customer-support handling for these cases. A webhook acknowledgement is not evidence that entitlement was restored.

The canonical guard and all three deployed copies are byte-identical; unrelated code and comments are preserved.

## Verification

Local Node 24: `node --test functions/test/dispute_ordering_regression.test.js` — 7 passed, 0 failed. Tests reuse the existing optimistic transaction test double and cover ordering, legitimate-win containment, refund/revocation finality, failed-commit rollback, repurchase binding, and deployed-copy equality.

These are not real Appwrite transactions or Razorpay staging tests. Full Node/runtime tests and CI remain required. No production actions or money transfers were performed.

## Still required

- Server-side dispute reconciliation against authoritative Razorpay data with payment/dispute identity, state versioning and idempotency.
- Safe server-authorized external-refund recording with fresh operator membership, transactional binding, audit trail and idempotency. Client-side read/update is not sufficient.
- Staging lifecycle tests, including concurrent repurchase/refund/dispute races, actual SDK transaction support and replay/retry behavior.

## Client refund containment

The unsafe client-side ledger update is disabled. `recordExternalRefund` returns a failed outcome without reading providers or writing data, and its legacy boolean alias returns false. The admin dialog explicitly explains the pause, distinguishes gateway refunds from recording, and warns against duplicate refunds. Existing pagination/export tests are retained; former client-refund-success tests now assert zero ledger reads/writes/cache invalidations for each relevant state.

This is intentionally a temporary loss of manual-recording functionality, not a server-side authorization boundary. Deploy an authorized transactional recording endpoint and restrict direct client write permissions before restoring it. No refund has been executed by this change.
