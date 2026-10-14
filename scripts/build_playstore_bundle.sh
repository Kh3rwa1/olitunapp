#!/usr/bin/env bash
set -euo pipefail

# Ensure Flutter and Dart are in PATH
if ! command -v flutter &>/dev/null; then
  export PATH="/opt/homebrew/share/flutter/bin:/opt/homebrew/bin:$PATH"
fi

echo "=================================================="
echo "  Building Olitun Production Play Store App Bundle"
echo "=================================================="

# Check signing keystore
if [ ! -f "android/app/upload-keystore.jks" ]; then
  echo "❌ Error: android/app/upload-keystore.jks not found!"
  exit 1
fi

if [ ! -f "android/key.properties" ]; then
  echo "❌ Error: android/key.properties not found!"
  exit 1
fi

APPWRITE_ENDPOINT="${APPWRITE_ENDPOINT:-https://sgp.cloud.appwrite.io/v1}"
APPWRITE_PROJECT_ID="${APPWRITE_PROJECT_ID:-699495910038e39622c5}"
TRANSLATE_URL="${TRANSLATE_URL:-https://sgp.cloud.appwrite.io/v1/functions/6a007db60024418c0997/executions}"
CLOUDFLARE_API_URL="${CLOUDFLARE_API_URL:-https://olitun.in}"
ADMIN_TEAM_ID="${ADMIN_TEAM_ID:-admins}"
SANTALI_VOICE_FUNCTION_ID="${SANTALI_VOICE_FUNCTION_ID:-santaliVoice}"
AI_STUDIO_FUNCTION_ID="${AI_STUDIO_FUNCTION_ID:-aiStudio}"
SENTRY_DSN="${SENTRY_DSN:-https://84bebaf2d902ae3f5326d29727aa6635@o4510882921709568.ingest.us.sentry.io/4512026738229248}"
SENTRY_ENV="${SENTRY_ENV:-production}"
BUILD_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILT_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)

flutter build appbundle --release \
  --dart-define=APP_ENV=production \
  --dart-define=APPWRITE_ENDPOINT="$APPWRITE_ENDPOINT" \
  --dart-define=APPWRITE_PROJECT_ID="$APPWRITE_PROJECT_ID" \
  --dart-define=TRANSLATE_URL="$TRANSLATE_URL" \
  --dart-define=CLOUDFLARE_API_URL="$CLOUDFLARE_API_URL" \
  --dart-define=ADMIN_TEAM_ID="$ADMIN_TEAM_ID" \
  --dart-define=SANTALI_VOICE_FUNCTION_ID="$SANTALI_VOICE_FUNCTION_ID" \
  --dart-define=AI_STUDIO_FUNCTION_ID="$AI_STUDIO_FUNCTION_ID" \
  --dart-define=SENTRY_DSN="$SENTRY_DSN" \
  --dart-define=SENTRY_ENV="$SENTRY_ENV" \
  --dart-define=BUILD_SHA="$BUILD_SHA" \
  --dart-define=BUILT_AT="$BUILT_AT"

echo "=================================================="
echo "  Play Store App Bundle Built Successfully!"
echo "  Output: build/app/outputs/bundle/release/app-release.aab"
echo "=================================================="
