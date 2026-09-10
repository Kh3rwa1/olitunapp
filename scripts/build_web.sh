#!/usr/bin/env bash
set -euo pipefail

# Olitun Web Production Build Wrapper
# Compiles Flutter Web, patches the service worker, and validates the output.

: "${APPWRITE_ENDPOINT:?Set APPWRITE_ENDPOINT for the production build}"
: "${APPWRITE_PROJECT_ID:?Set APPWRITE_PROJECT_ID for the production build}"
: "${TRANSLATE_URL:?Set TRANSLATE_URL for the production build}"

APP_ENV="${APP_ENV:-production}"
BUILD_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  BUILD_SHA="${BUILD_SHA}-dirty"
fi
BUILT_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo "Building Olitun web artifact"
echo "  environment: $APP_ENV"
echo "  revision:    $BUILD_SHA"
echo "  built at:    $BUILT_AT"

flutter build web --release --no-wasm-dry-run \
  --dart-define=APP_ENV="$APP_ENV" \
  --dart-define=APPWRITE_ENDPOINT="$APPWRITE_ENDPOINT" \
  --dart-define=APPWRITE_PROJECT_ID="$APPWRITE_PROJECT_ID" \
  --dart-define=ADMIN_TEAM_ID="${ADMIN_TEAM_ID:-admins}" \
  --dart-define=TRANSLATE_URL="$TRANSLATE_URL" \
  --dart-define=SENTRY_DSN="${SENTRY_DSN:-}" \
  --dart-define=SENTRY_ENV="${SENTRY_ENV:-production}" \
  --dart-define=BUILD_SHA="$BUILD_SHA" \
  --dart-define=BUILT_AT="$BUILT_AT"

cat <<EOF > build/web/build-info.json
{
  "sha": "$BUILD_SHA",
  "builtAt": "$BUILT_AT",
  "environment": "$APP_ENV"
}
EOF

node scripts/patch_service_worker.mjs
node scripts/verify_service_worker_patch.mjs

echo "Web build and service-worker verification completed."
