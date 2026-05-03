# Olitun — Learn Ol Chiki (Santali Script)

## Overview
Olitun is a premium Flutter-based learning platform for the Ol Chiki (Santali) script. It supports Android, iOS, and Web targets. The Replit environment serves the pre-built Flutter web app — Flutter SDK itself is **not** installed here, so the app must be rebuilt elsewhere whenever Dart code changes.

## Architecture
- **Frontend:** Flutter (Material 3) — compiled to web via `flutter build web`
- **State Management:** Riverpod
- **Backend-as-a-Service:** Appwrite (auth, database, teams, functions, storage)
- **Offline Storage:** Hive
- **Navigation:** GoRouter
- **Crash reporting:** Sentry (release builds only, opt-in via `SENTRY_DSN`)

## Project Structure
```
lib/
├── app/router/                # GoRouter navigation
├── core/                      # Theme, auth, config, storage, API, observability
├── features/                  # Feature modules (admin, auth, home, lessons, quiz, …)
├── shared/                    # Shared models, providers, widgets
└── main.dart                  # App entry point + crash zone

functions/translator/          # Appwrite Function (Node.js) replacing the
                               # legacy PHP translate proxy
build/web/                     # Pre-built Flutter web output (served by server.js)
admin-panel/                   # Retired PHP admin (Task #4) — only
                               # api/upload.php remains; see its README
web/                           # Flutter web source (index.html, manifest, …)
test/                          # Dart tests (mocktail-based repo tests, model tests)
```

## How It Runs on Replit
Flutter SDK is not available here, so the pre-built web output in `build/web/` is served via `server.js` on port 5000. Code changes to `lib/` will not appear in the preview until you run `flutter build web` locally and commit the new `build/web/` artifact.

**Workflow:** `Start application` — runs `node server.js`

## Build flags (compile-time)
Required:
- `APPWRITE_ENDPOINT` — Appwrite API endpoint (validated at startup)
- `APPWRITE_PROJECT_ID` — Appwrite project ID (validated at startup)

Optional:
- `ADMIN_TEAM_ID` — Appwrite Team granting admin access (default: `admins`)
- `TRANSLATE_URL` / `REVERSE_TRANSLATE_URL` — execution URL of `functions/translator`
- `UPLOAD_BASE_URL` — base URL for the legacy `api/upload.php` endpoint
  (only remaining PHP dependency — see `admin-panel/README.md`)
- `SENTRY_DSN`, `SENTRY_ENV` — crash reporting

There are **no hardcoded fallbacks** for endpoint/project ID, translator URLs, or the API base URL. Builds without them will throw `StateError` at startup or at first call.

## Security model
Admin access is enforced server-side by Appwrite Team membership — the previous client-side `ADMIN_SECRET_KEY` model has been removed. See [SECURITY.md](SECURITY.md).

## Deployment
Configured as a **static** deployment serving `build/web/`.

## Motion system (Task #5)
A unified motion vocabulary lives under `lib/core/motion/` and is the
single source of truth for animations across the app. Pull from it
instead of hand-tuning new durations/curves per surface:
- `motion_tokens.dart` — durations, curves, hero-tag generator,
  `RespectMotion` helper for OS reduce-motion.
- `pressable_scale.dart` — drop-in tap wrapper with scale + haptic.
  Use this in place of bare `GestureDetector` for any tappable surface.
- `animated_counter.dart` — tween + scale-pulse for stat changes.
- `page_transitions.dart` — GoRouter `CustomTransitionPage` builders
  (`sharedAxisZ`, `fadeThrough`, `fadeUp`). Wired in `app_router.dart`.
- `confetti_overlay.dart` — `CustomPainter` confetti burst (no asset).
- `branded_refresh.dart` — thin `RefreshIndicator` wrapper styled in the
  app's primary color (state-driven; spinner only appears during pull).
- `focus_glow_field.dart` — focus-glow border + imperative `shake()`
  for forms (both bypass when reduce-motion is on).
- `motion.dart` — single barrel import.

All primitives (page transitions, `PressableScale`, `ConfettiBurst`,
`FocusGlowField`) honor the OS reduce-motion setting via
`RespectMotion.of(context)`.

Hero tags follow `MotionTokens.heroTag(namespace, id)` (namespaces in
use: `lesson`, `category`). Lesson cards pair with the lesson-detail
header; category cards on `lessons_screen` pair with the
`category_lessons_screen` AppBar title.

The main shell cross-fades tabs via a `Stack` + `IgnorePointer` +
`AnimatedOpacity` switcher (all tabs stay mounted, so per-tab state is
preserved). Quiz answers fire a crisp double-tap haptic on correct and
a single medium thump on wrong; correct options pulse-scale and wrong
options shake horizontally; the completion screen bursts confetti when
score >= 70%. Email auth fields glow on focus and shake on validation
failure.

Out of scope for this pass and tracked as follow-ups: broader
press-feedback / Hero coverage for letters/words/numbers/sentences/quizzes/rhymes
(#7), and sliver parallax detail headers + splash→onboarding chain (#8).

## Recent quality work (Task #1)
- Removed hardcoded Appwrite project ID fallback; `AppwriteConfig.validate()` at boot.
- Replaced client-side admin secret with Appwrite Teams membership check; double-gated via router redirect and `AdminShell`.
- Removed PHP-proxy fallback URLs in `AiService` / `ApiService`; both now require build flags.
- Replaced `cache_service_legacy.dart` with `cache_service.dart` (kept clean, updated consumers).
- Added Sentry crash reporting (`lib/core/observability/crash_reporting.dart`), wired through `runZonedGuarded`.
- Wrote real tests: repository (mocktail), AI config fail-fast, Appwrite config fail-fast, theme widget test.
- Added `functions/translator/` (Node.js Appwrite Function) as the production translator.
- Updated CI to pass all required `--dart-define`s; added `SECURITY.md`, refreshed `CONTRIBUTING.md`, README badges.

## Dependencies
- Node.js 20 (for serving the static web app and the Appwrite Function)
- Flutter SDK (needed only to rebuild — not available on Replit)
