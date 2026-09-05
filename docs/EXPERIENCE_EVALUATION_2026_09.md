# UX, performance, and accessibility evaluation

## Scope and evidence

Baseline: `3f4010ddb727063929f5b089625455d5e52e683f` (main after PR #247).
This change targets learning-path discovery and shared actions/motion. It is not a whole-app WCAG conformance claim or a 10/10 certification.

### Implemented

- Learning paths use one lazy sliver viewport instead of an eager shrink-wrapped grid inside a scroll view. The regression fixture contains 200 categories and bounds mounted category cards before and after scrolling.
- The catalog has an explicit empty state, working error retry, labelled back navigation, stable category keys, and preserved destination routing.
- Large text and narrow viewports switch to naturally sized list cards; primary and Duo buttons wrap labels and grow vertically instead of clipping them into fixed heights.
- The app no longer replaces the OS text scaler with a 1.5x cap. The original scaler and bold-text setting are preserved. This is app-wide: unreviewed routes must be checked for newly exposed layout constraints before release.
- Shared pressable controls support Tab, Enter, Space, semantic actions, visible focus, disabled-state enforcement, and minimum 48dp targets when parent constraints permit.
- Primary buttons no longer render white labels on bright green. Duo foregrounds use the actual opaque background; category labels use high-contrast text rather than white over bright gradients. Focus/press overlays preserve contrast.
- User and OS reduced-motion preferences reach shared motion components. Bento entrance delays are bounded. The lesson hero no longer runs perpetual decorative animation while idle.

### Automated evidence

- 31 new Flutter regressions cover controls, semantic tap targets, contrast samples, text scaling, motion preferences, responsive lesson layouts, lazy mounting, retry recovery, and navigation. The existing Flutter CI discovers them automatically.
- The separate physical-device performance target is not part of the ordinary widget-test count.
- 10 Node tests for the measurement validator passed locally. These are synthetic validator fixtures, not evidence of actual app speed.
- Flutter/Dart and the user-visible browser were unavailable in the editing sandbox. No local Flutter run, visual inspection, screen-reader session, user study, or device trace is represented as completed.
- Existing coverage, security, backend, build-size, and release gates remain unchanged. The additional workflow tests the measurement validator and reports targeted Flutter diagnostics, not device performance. For same-repository PRs only, its reporter can post a diagnostic comment; it cannot commit, merge, or deploy, and checkout credentials are not persisted.

## Reproducible device profiling

Use a connected physical Android device, with a documented OS, display refresh rate, power/thermal state, and device model. Use the same settings across repeated runs. Profile mode is required; debug timings are rejected.

```sh
flutter pub get
flutter drive --profile \
  -d YOUR_DEVICE_ID \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/experience_performance_test.dart \
  --dart-define=BUILD_SHA="$(git rev-parse HEAD)" \
  --dart-define=PROFILE_DEVICE="device model / OS / power mode"

node tool/experience_frame_budget.mjs \
  build/integration_response_data.json \
  build/experience_summary.json
```

The fixture renders the actual LessonsScreen with 200 local categories, real theme/widgets, and ads/backend disabled. It warms the renderer, collects engine FrameTiming samples during repeated scrolling, and records provenance. It does not call app startup, payments, production analytics, or the live content backend. It does not benchmark videos, images, ads, or full navigation journeys.

The evaluator requires at least 120 valid samples and the measured display refresh rate. It reports nearest-rank p95 build and raster durations, and the percentage of samples where either phase exceeds `1000 / refreshHz` milliseconds. The default target is p95 within one refresh interval for each phase and at most 1% over-budget samples. Build and raster are pipelined and are not added together.

This is an engine phase-budget proxy, not directly observed display jank. A passing fixture is not proof of fast startup or a responsive network-backed app. Compare repeated same-device measurements, not emulator timings or unlike devices. Keep raw traces, summaries, and the tested commit together; never label validator unit-test data as a device run.

## Required manual evaluation before release

Every item below remains **not run** until an evaluator records evidence. CI green is not a substitute.

### UX

- New learner: find an appropriate path, open a lesson, complete one activity, and explain the progress state without coaching.
- Recovery: reproduce a failed content load, use Retry, and verify recovery; check empty content and offline cached content separately.
- First-use usability: observe representative learners, including an Ol Chiki reader and a learner unfamiliar with the app. Record task completion, errors, confusing labels, and concrete follow-up fixes rather than inventing a satisfaction score.
- Review actual screenshots at 320px, 390px, tablet, and desktop widths in both themes. Check real, long localized content. No overlapping, clipped, or unreachable content is acceptable.

### Accessibility

- TalkBack on Android and VoiceOver on iOS: named actions, sensible reading order, correct loading/disabled feedback, and no duplicate action announcements.
- Keyboard: Tab/Shift+Tab, Enter/Space, visible focus, back navigation, and focus recovery after errors and route changes.
- System text at 200% and the largest supported device setting, bold text, and high contrast. Audit auth, home, quizzes, settings, paywalls, and shared loading/offline states, not just the changed catalog.
- Reduced motion: verify both OS and in-app settings, including changes while a screen is open.
- Check actual rendered contrast in normal, hovered, focused, pressed, and disabled states. Automated sampled token checks do not constitute a complete WCAG audit.

### Performance

- Run the profile target repeatedly on a representative lower-end physical device; preserve raw samples and commit metadata.
- Measure cold/warm startup, real images/video lists, memory after repeated navigation, and network-backed loading separately with Flutter DevTools in profile/release builds.
- Test default motion and reduced-motion settings, thermal throttling, and slow/offline/reconnect conditions. Record actual measurements before claiming a performance gain.

## Merge/release boundary

Keep this PR draft until automated checks and visual review are satisfactory. Do not infer that prior authorization to merge PR #247 authorizes merging this new work. No payment/backend changes are part of this patch. A production-readiness decision still requires the manual evidence above, especially routes affected by removing the text-scale cap.
