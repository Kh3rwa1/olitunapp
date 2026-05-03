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
admin-panel/                   # Legacy PHP admin (being phased out)
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
- `API_BASE_URL` — base URL for the legacy REST API (`ApiService`)
- `UPLOAD_BASE_URL` — base URL for the upload endpoint
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
- `branded_refresh.dart` — `RefreshIndicator` wrapper drawing a spinning
  Ol Chiki glyph behind the standard spinner.
- `focus_glow_field.dart` — focus-glow border + imperative `shake()`
  for forms.
- `motion.dart` — single barrel import.

Hero tags follow `MotionTokens.heroTag(namespace, id)` (e.g. `lesson`,
`category`, `letter`, `word`, `number`, `sentence`, `quiz`). Currently
wired between `category_lessons_screen` cards and `lesson_detail_screen`.
The main shell uses an `AnimatedSwitcher` cross-fade in place of
`IndexedStack` for tab swaps. Quiz answers fire crisp/heavy haptics on
correct/wrong and a confetti burst on celebratory completion.

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
