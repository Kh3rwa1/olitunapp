#!/bin/bash
set -e

# Olitun Web Production Build Wrapper
# Compiles Flutter Web, patches the service worker to fix stale caching, and validates the output.

echo "🔍 Capturing Build Metadata..."
# Capture git short SHA
BUILD_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Append -dirty if the working tree has uncommitted changes
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  BUILD_SHA="${BUILD_SHA}-dirty"
fi

# Capture build timestamp
BUILT_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo "  - BUILD_SHA: $BUILD_SHA"
echo "  - BUILT_AT:  $BUILT_AT"

echo "🚀 Starting Flutter Web Build..."
flutter build web --release --no-wasm-dry-run \
  --dart-define=APPWRITE_ENDPOINT=https://sgp.cloud.appwrite.io/v1 \
  --dart-define=APPWRITE_PROJECT_ID=699495910038e39622c5 \
  --dart-define=TRANSLATE_URL=https://sgp.cloud.appwrite.io/v1/functions/6a007db60024418c0997/executions \
  --dart-define=BUILD_SHA=$BUILD_SHA \
  --dart-define=BUILT_AT=$BUILT_AT

echo "📝 Generating build-info.json..."
cat <<EOF > build/web/build-info.json
{
  "sha": "$BUILD_SHA",
  "builtAt": "$BUILT_AT"
}
EOF

echo "🧹 Excluded bootstrap from Service Worker manifest..."
node scripts/patch_service_worker.mjs

echo "✅ Verifying patch correctness..."
node scripts/verify_service_worker_patch.mjs

echo "🎉 Web Build and Service Worker patching completed successfully!"
