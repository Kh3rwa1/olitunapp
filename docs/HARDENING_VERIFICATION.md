# Learning-first hardening verification

This change set addresses concrete findings from the review of `f0a779e`.
It is not a certification of security, learning effectiveness, or production readiness.

## Changes

- Remove the app-owned plaintext session-secret preference on all platforms.
  Remove legacy values at startup and during session restoration. Preserve
  non-secret metadata, account scope, learning progress, and SDK session behavior.
  The old native preference was not used by native restoration, so no replacement
  credential store or new plugin dependency is introduced.
- Expose a cache-only content repository read. Keep the existing FutureProvider
  interface, show usable cached/bundled content first, then refresh in the
  background. Preserve cached data on refresh errors and ignore results from
  invalidated/disposed provider generations. Bound cold network loading.
- Require every mandatory CI prerequisite to succeed. Missing, malformed,
  failed, skipped, and cancelled results block the release gate. Test the CLI
  exit status as well as the decision function and workflow wiring.
- Keep one optional native Home ad after the learning actions and content grid;
  remove the two earlier native placements and the Home banner. Ad consent and
  premium/ad eligibility logic remain unchanged. This intentionally reduces
  Home ad inventory; retention and revenue effects have not been measured.

## Automated checks

Run in a checkout with the project Flutter SDK and dependencies available:

```sh
node --test scripts/check_release_gate.test.mjs
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test test/core/auth/session_persistence_test.dart
flutter test test/core/auth/appwrite_auth_service_test.dart
flutter test test/shared/providers/content_list_provider_test.dart
flutter test test/shared/providers/content_list_cache_first_test.dart
flutter test test/shared/repositories/content_repository_cached_list_test.dart
flutter test test/features/home/home_screen_test.dart
flutter test --coverage --concurrency=4
```

The new Dart tests exercise provider/repository and widget behavior. They are
not real-backend end-to-end tests. Existing smoke suites must not be reported
as proof that the production purchase/deletion/restart journeys work.

## Required pre-merge and release verification

Use an isolated Appwrite staging project and Razorpay test mode. Do not run
account deletion or payment experiments against production accounts.

- [ ] All required PR checks pass, including Dart formatting, static analysis,
      Flutter tests, security checks, and Android/web builds. Resolve failures;
      do not weaken coverage gates or regenerate goldens without reviewing them.
- [ ] Upgrade an existing Android/iOS installation with a legacy session
      preference. Confirm the plaintext preference disappears, sign-in remains
      correct, and progress survives online and offline restarts.
- [ ] Verify email and Google OAuth sign-in, cancellation, sign-out, and
      account switching on real devices. Confirm credentials do not remain in
      URLs or app-owned preferences. Separately audit the Appwrite SDK's own
      cookie/session persistence and OS backup behavior; this patch does not
      claim to encrypt SDK-managed storage.
- [ ] Load a previously cached lesson with a stalled network. Confirm initial
      content does not wait for the server, a successful refresh reaches the
      screen, failures retain usable content, and explicit retry still works.
- [ ] Exercise purchase creation, test payment capture, entitlement verification,
      cancellation, duplicate callbacks, restart recovery, and access from a
      second account. Assert persisted server state, not just screen presence.
- [ ] Exercise account deletion with partial backend cleanup failure. Confirm
      the user is not told deletion completed when reconciliation is pending.
- [ ] Review Home on approximately 390 px mobile width and desktop, in light
      and dark modes, with large text, reduced motion, ads enabled/disabled,
      loading, empty, and error states. Verify no overlaps, overflow, or unusable
      spacing; inspect screenshots rather than only generating them.
- [ ] Review changed goldens where applicable. Measure first useful content,
      scrolling, memory, crash-free sessions, and lesson completion on a low-end
      Android device and constrained networks. Record baselines and results.

## Known scope limits

No production environment, payment setting, content entitlement rule, database
permission, dependency version, or release version is changed. Real backend
journey automation and device/visual QA are still required before declaring
this release ready. A code review alone cannot justify a "10/10" product rating.
