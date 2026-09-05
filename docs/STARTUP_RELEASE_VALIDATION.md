# Startup reliability release validation

This change improves recoverability; it does not certify overall app quality, production deployment, or a 10/10 rating.

## Runtime behavior

- Show a provider/storage-independent loading shell before asynchronous startup. The shell has no Navigator and must not rewrite incoming web routes.
- Keep binding initialization, application rendering, and retry callbacks in one error zone. Retry does not call main or configure URL strategy again.
- Wait at most 15 seconds per attempt for required storage initialization. A timeout does not cancel initialization; retry reuses the pending operation. A real failure can start a new attempt, while success is cached.
- Start display configuration, crash reporting, ads, and notifications independently. Each optional wait has an 8-second budget. Startup logs report outcomes before launching the main app; optional failure does not prevent launch when required prerequisites have completed.
- Background audio setup must finish before constructing the real application and its players. An 8-second audio timeout shows the retry shell. Retry waits on the same pending audio future. Completed audio errors retain the previous best-effort foreground fallback behavior.
- SDK timeout does not cancel platform work. Optional tasks are attempted once per process; late completion can still enable a service. A genuinely stuck storage/audio operation may require restarting the app.
- Ads require both SDK/native-factory readiness and current UMP authorization. Both readiness and consent changes update ad eligibility; consent alone cannot enable ads while the SDK is still starting.
- The error screen scrolls on narrow/large-text displays, uses theme colors, and avoids presenting every configuration/storage error as an internet outage.

Budgets bound asynchronous waiting, not synchronous plugin execution or operating-system scheduling. They are not measured cold-start performance claims.

## Automated evidence

The focused run recorded in STARTUP_DIAGNOSTICS.txt used Flutter 3.47.2 / Dart 3.13.2 against source b4f06469f4d308301041202613d3a5f1ade3da2e:

- 20 focused tests passed, including 13 new regressions and 7 existing ad/consent tests.
- flutter analyze --fatal-infos: no issues found.
- Color-token gate: passed; the obsolete main.dart exception was removed rather than relaxed.

The first run found a nullable-error type mismatch and an unnecessary test import. Both were corrected before the successful rerun. The branch-scoped preparation workflow and edit script removed themselves; they are not part of the final source tree. The normal CI/release gates must independently pass at the final PR head.

New tests cover optional success, synchronous/asynchronous failure, independent tasks, timeout with late error, duplicate-attempt prevention, cached required success, real-failure retry, pending-storage retry, loading without providers/Navigator, retry action, narrow large-text rendering, and both orders of SDK/consent readiness.

These are helper/provider/widget regressions, not live backend E2E tests. Existing honest screen-rendering smoke tests are not relabelled as end-to-end coverage.

## Required device and browser validation

- [ ] Android and iOS cold start with fast, slow, unavailable, and resumed network conditions; record first-frame and time-to-learning, not only build sizes.
- [ ] Storage failure and pending-operation timeout; tap Retry repeatedly and confirm there is only one storage operation.
- [ ] Delay background-audio initialization beyond the budget; confirm no player is constructed before it settles. Retry after it completes and test foreground/background/lock-screen playback.
- [ ] Delay or fail crash reporting, display configuration, notifications, and ads independently; healthy services and the app must remain usable where their prerequisites have completed.
- [ ] UMP required/denied/error/granted/revoked and slow SDK initialization, using test ad units. Exercise banner, native, interstitial, and rewarded formats.
- [ ] Incoming path, query, hash, OAuth callback, and payment-return URLs on web survive the startup shell and reach the production router. Do not use production payment operations for testing.
- [ ] Notification opt-out stays respected if settings change before delayed initialization finishes; verify notification permissions, scheduling, and timezone behavior on devices.
- [ ] Screen reader, 200% text, small viewport, and long error messages; retry must remain reachable.

## Separate release gates still required

Follow PAYMENT_STATE_RELEASE_VALIDATION.md and PRIORITY_HARDENING_VALIDATION.md for separate staging Appwrite credentials/scopes, real transaction support, Razorpay test-mode lifecycle races, deletion/recovery, offline process restart, entitlement enforcement and paid-resource permissions. Use disposable test accounts and keep secrets out of source and chat.

Do not infer deployment, real-device performance, content/localization accuracy, or learner usability from green CI alone.
