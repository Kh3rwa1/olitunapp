# Web media and category accessibility hardening

Baseline: 72d7b56361b84123bc6d18f7e999fb494a65b339.

## Implemented

- Explicit `media-src` for same-origin/blob and HTTPS Appwrite media. Previously media fell back to `default-src 'self'`, despite Appwrite being permitted in `connect-src`. Script, frame, object and default policies remain unchanged.
- Home category labels and actions now belong to the same `PressableScale` semantics node. Removed the outer `ExcludeSemantics` that hid its activation and focus semantics. Routing for alphabet aliases and ordinary categories is preserved. Visual styling and layout are unchanged.
- Added media-policy contract tests and category semantic-action/keyboard navigation regression tests.

## Verification performed

- `node --test functions/test/web_media_policy.test.js`: 4 passed, 0 failed locally on Node 24. A negative control against the original CSP correctly failed.
- A local headless Chromium probe using the exact policy loaded same-origin and blob WAV metadata, and emitted a media-src policy violation for a disallowed cross-origin media URL. This tests browser policy enforcement, not deployed Appwrite playback or autoplay.
- Original home and Vercel sources were checked against their GitHub blob hashes. Vercel has only the intended media-src addition; home navigation destinations are unchanged.
- Flutter and Dart are unavailable in the editing sandbox. Widget tests, Dart formatting and static analysis have NOT been executed locally. CI is required; do not merge a failing or pending branch.
- No deployment, live data/permission mutation, actual device test, or whole-app accessibility certification was performed.

## Required before release

1. Verify actual staging response headers, and play real lesson audio/video under them. Test trusted Appwrite media and rejected untrusted origins; a policy unit test is not a playback E2E test.
2. Run the targeted home-category tests plus existing Flutter suite, formatting, analysis and unchanged coverage gates.
3. Verify Tab/Enter/Space and TalkBack/VoiceOver category activation in both script modes. Check label quality and duplicate announcements on actual devices.
4. Complete the separate progress/payment/content authorization fixes. This change does not turn public storage into premium authorization.

## Remaining scope

Fixed-height/eager home layout, broader localization, startup profiling and complete large-text/contrast audits remain follow-up work. This patch is not a 10/10 or production-readiness claim.
