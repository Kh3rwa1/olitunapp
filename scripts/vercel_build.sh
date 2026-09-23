#!/usr/bin/env bash
set -euo pipefail

: "${APPWRITE_ENDPOINT:?Set APPWRITE_ENDPOINT in Vercel project settings}"
: "${APPWRITE_PROJECT_ID:?Set APPWRITE_PROJECT_ID in Vercel project settings}"
: "${TRANSLATE_URL:?Set TRANSLATE_URL in Vercel project settings}"

if ! command -v flutter >/dev/null 2>&1; then
  FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
  if [ ! -d "$FLUTTER_HOME/bin" ]; then
    git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_HOME"
  fi
  export PATH="$FLUTTER_HOME/bin:$PATH"
fi

flutter --version
flutter config --enable-web
flutter pub get

flutter build web --release --no-web-resources-cdn \
  --dart-define=APP_ENV=production \
  --dart-define=APPWRITE_ENDPOINT="$APPWRITE_ENDPOINT" \
  --dart-define=APPWRITE_PROJECT_ID="$APPWRITE_PROJECT_ID" \
  --dart-define=ADMIN_TEAM_ID="${ADMIN_TEAM_ID:-admins}" \
  --dart-define=TRANSLATE_URL="$TRANSLATE_URL" \
  --dart-define=SANTALI_VOICE_FUNCTION_ID="${SANTALI_VOICE_FUNCTION_ID:-santaliVoice}" \
  --dart-define=AI_STUDIO_FUNCTION_ID="${AI_STUDIO_FUNCTION_ID:-aiStudio}" \
  --dart-define=SENTRY_DSN="${SENTRY_DSN:-}" \
  --dart-define=SENTRY_ENV="${SENTRY_ENV:-production}"

dart run scripts/patch_service_worker.dart
dart run scripts/verify_service_worker_patch.dart
dart run scripts/verify_pwa_offline.dart
node scripts/verify_pwa_offline.mjs
