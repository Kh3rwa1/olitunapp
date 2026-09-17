# Staging Release Gate (WS10)

PR CI is deterministic and credential-free. The authenticated staging gate
below is REQUIRED for release candidates and fails closed when credentials
are missing (a skipped live check is NOT VERIFIED, never passed).

## Environment

- Dedicated staging Appwrite project (never production).
- Required env: staging endpoint/project/api-key, Razorpay TEST-mode keys,
  staging signing config. Any missing credential aborts the gate as failed.

## Journeys (each bound to the candidate SHA with redacted artifacts)

1. Fresh guest install. 2. Learn offline. 3. Kill process. 4. Restart
   offline. 5. Verify review state. 6. Sign in. 7. Verify idempotent guest
   migration (rerun converges). 8. Switch account. 9. Verify isolation.
2. Answer on device A offline. 11. Answer on device B. 12. Reconnect in
   different orders. 13. Verify both operations preserved (counters exact).
3. Record mistake. 15. Recover item. 16. Reinstall. 17. Verify no
   resurrection of resolved/mastered items.
4. Purchase in Razorpay test mode. 19. Verify entitlement. 20. Refund/revoke
   and verify revocation + bounded offline grace expiry.
5. Generate TTS. 22. Force provider failure. 23. Verify quota refund and
   non-replayable claim. 24. Delete account. 25. Verify cascade across all
   user-owned collections/files (incl. `review_operations`, `voice_claims`,
   `user_assets` files).
6. Verify scheduled cleanup configuration. 27. Verify CSP and
   Permissions-Policy. 28. Verify web boot and service worker. 29. Verify
   notification scheduling on supported real devices. 30. Verify ad-consent
   fail-closed behavior where legally applicable.

## Evidence manifest (per candidate SHA)

Source SHA, artifact checksums, dependency lockfiles, schema snapshot
(`review_states` + `review_operations` verified via
`create_review_collection.mjs --verify-only`), deployed function versions,
environment name, journey results, mobile signing verification, web security
headers, rollback version.

## Current status

No authenticated staging run has been executed in this hardening pass
(no staging credentials in this environment). All 30 journeys: NOT VERIFIED
(see final report). Unit/contract coverage for the same invariants is green
in PR CI.
