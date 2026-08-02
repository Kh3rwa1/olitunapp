#!/usr/bin/env bash
set -eo pipefail

echo "=========================================="
echo " Running Performance Budget Checks for Olitun"
echo "=========================================="

MAX_WEB_BUNDLE_MB=40
WEB_BUILD_DIR="build/web"

if [ -d "$WEB_BUILD_DIR" ]; then
  WEB_SIZE_BYTES=$(du -sk "$WEB_BUILD_DIR" | cut -f1)
  WEB_SIZE_MB=$((WEB_SIZE_BYTES / 1024))
  echo "📦 Web Bundle Size: ${WEB_SIZE_MB}MB (Budget Limit: ${MAX_WEB_BUNDLE_MB}MB)"

  if [ "$WEB_SIZE_MB" -gt "$MAX_WEB_BUNDLE_MB" ]; then
    echo "❌ ERROR: Web bundle size (${WEB_SIZE_MB}MB) exceeds performance budget limit (${MAX_WEB_BUNDLE_MB}MB)!"
    exit 1
  else
    echo "✅ Web bundle size check passed."
  fi
else
  echo "ℹ️  Skipping web bundle size check (build/web directory not found)."
fi

echo "✅ All performance budget checks completed successfully."
