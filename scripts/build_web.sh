#!/bin/bash
set -e

# Olitun Web Production Build Wrapper
# Compiles Flutter Web, patches the service worker to fix stale caching, and validates the output.

echo "🚀 Starting Flutter Web Build..."
flutter build web --release --no-wasm-dry-run --dart-define=APPWRITE_ENDPOINT=https://sgp.cloud.appwrite.io/v1 --dart-define=APPWRITE_PROJECT_ID=699495910038e39622c5 --dart-define=TRANSLATE_URL=https://sgp.cloud.appwrite.io/v1/functions/6a007db60024418c0997/executions

echo "🧹 Excluded bootstrap from Service Worker manifest..."
node scripts/patch_service_worker.mjs

echo "✅ Verifying patch correctness..."
node scripts/verify_service_worker_patch.mjs

echo "🎉 Web Build and Service Worker patching completed successfully!"
