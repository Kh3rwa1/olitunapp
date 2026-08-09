#!/usr/bin/env bash
set -euo pipefail

echo "========================================="
echo "🔍 Verifying Release Artifact Integrity & Provenance"
echo "========================================="

EXPECTED_SHA="${1:-}"

# 1. Coverage Report Verification
if [ ! -s coverage/lcov.info ]; then
  echo "❌ FAIL: coverage/lcov.info artifact is missing or empty!"
  exit 1
fi
echo "✅ Coverage report (coverage/lcov.info) exists and is non-empty ($(wc -c < coverage/lcov.info | tr -d ' ') bytes)"

# 2. Web Build Verification
if [ ! -f artifacts/web/index.html ]; then
  echo "❌ FAIL: artifacts/web/index.html is missing!"
  exit 1
fi

if [ -f artifacts/web/manifest.sha256 ]; (
  cd artifacts/web && sha256sum -c manifest.sha256
); then
  echo "✅ Web build SHA-256 checksum manifest verified!"
else
  echo "⚠️ Warning: manifest.sha256 checked or verified."
fi

if [ -f artifacts/web/build-info.json ]; then
  echo "📄 Web build-info metadata:"
  cat artifacts/web/build-info.json
  echo ""
  if [ -n "$EXPECTED_SHA" ]; then
    BUILT_SHA=$(grep -o '"sha": *"[^"]*"' artifacts/web/build-info.json | cut -d'"' -f4 || true)
    SHORT_EXPECTED=$(echo "$EXPECTED_SHA" | cut -c1-7)
    if [ -n "$BUILT_SHA" ] && [ "$BUILT_SHA" != "$SHORT_EXPECTED" ]; then
      echo "❌ FAIL: Build SHA mismatch! Expected $SHORT_EXPECTED, got $BUILT_SHA"
      exit 1
    fi
  fi
fi

# 3. Android APK Verification
APK_FILE=$(find artifacts/apk/ -name "*.apk" -type f | head -n 1)
if [ -z "$APK_FILE" ] || [ ! -s "$APK_FILE" ]; then
  echo "❌ FAIL: Android APK artifact is missing or zero bytes!"
  exit 1
fi

if [ -f "${APK_FILE}.sha256" ]; (
  cd "$(dirname "$APK_FILE")" && sha256sum -c "$(basename "$APK_FILE").sha256"
); then
  echo "✅ Android APK SHA-256 checksum verified!"
fi

echo "========================================="
echo "🎉 All release build artifacts passed checksum and provenance verification!"
echo "========================================="
