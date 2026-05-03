# Olitun — Learn Ol Chiki (Santali Script)

## Overview
Olitun is a premium Flutter-based learning platform for the Ol Chiki (Santali) script. It supports Android, iOS, and Web targets. The Replit environment serves the pre-built Flutter web app.

## Architecture
- **Frontend:** Flutter (Material 3) — compiled to web via `flutter build web`
- **State Management:** Riverpod
- **Backend-as-a-Service:** Appwrite
- **Offline Storage:** Hive
- **Navigation:** GoRouter

## Project Structure
```
lib/
├── app/router/      # GoRouter navigation
├── core/            # Theme, Auth, Config, Storage, API
├── features/        # Feature modules (admin, auth, home, lessons, quiz, etc.)
├── shared/          # Shared models, providers, widgets
└── main.dart        # App entry point

build/web/           # Pre-built Flutter web output (served by server.js)
admin-panel/         # PHP-based admin panel for Hostinger deployment
web/                 # Flutter web source files (index.html, manifest, etc.)
```

## How It Runs on Replit
Since Flutter SDK is not available in the Replit environment, the pre-built web output in `build/web/` is served via a simple Node.js HTTP server (`server.js`) on port 5000.

**Workflow:** `Start application` — runs `node server.js`

## Environment Variables (Runtime)
The Flutter app uses `--dart-define` compile-time variables:
- `APPWRITE_ENDPOINT` — Appwrite API endpoint
- `APPWRITE_PROJECT_ID` — Appwrite project ID
- `ADMIN_SECRET_KEY` — Admin panel secret key

These are baked into the compiled JS bundle at build time.

## Deployment
Configured as a **static** deployment serving `build/web/`.

## Dependencies
- Node.js 20 (for serving the static web app)
- Flutter SDK (needed only to rebuild — not available on Replit)
