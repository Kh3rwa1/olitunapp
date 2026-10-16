#!/usr/bin/env bash
# Installs the Android NDK that Flutter's Gradle plugin expects, with retries.
#
# Without this, the NDK (~600 MB) is downloaded by Gradle mid-build, and a
# truncated download ("Error on ZipFile unknown archive") fails the whole
# Android job. Installing it up front with retries makes CI deterministic.
set -euo pipefail

FLUTTER_BIN="$(command -v flutter)"
FLUTTER_ROOT="${FLUTTER_ROOT:-$(cd "$(dirname "$(readlink -f "$FLUTTER_BIN")")/.." && pwd)}"
EXT="$FLUTTER_ROOT/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt"
NDK_VERSION="$(sed -n 's/.*val ndkVersion: String = "\([0-9.]*\)".*/\1/p' "$EXT" | head -1)"
if [ -z "$NDK_VERSION" ]; then
  echo "Could not read the NDK version from $EXT; leaving the install to Gradle."
  exit 0
fi

SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-/usr/local/lib/android/sdk}}"
SDKMANAGER="$SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"
TARGET="$SDK_ROOT/ndk/$NDK_VERSION"

if [ -f "$TARGET/source.properties" ]; then
  echo "NDK $NDK_VERSION already installed."
  exit 0
fi

for attempt in 1 2 3; do
  echo "Installing NDK $NDK_VERSION (attempt $attempt)..."
  if yes | "$SDKMANAGER" --sdk_root="$SDK_ROOT" "ndk;$NDK_VERSION" >/tmp/ndk_install.log 2>&1 \
     && [ -f "$TARGET/source.properties" ]; then
    echo "NDK $NDK_VERSION installed."
    exit 0
  fi
  tail -5 /tmp/ndk_install.log || true
  # Drop any partial download so the next attempt starts clean.
  rm -rf "$TARGET" "$SDK_ROOT/.temp" 2>/dev/null || true
  sleep $((attempt * 15))
done

echo "NDK $NDK_VERSION could not be installed after 3 attempts."
exit 1
