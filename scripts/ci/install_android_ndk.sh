#!/usr/bin/env bash
# Installs the Android NDK that Flutter's Gradle plugin expects.
#
# Without this, Gradle downloads the NDK (~700 MB) mid-build through
# sdkmanager, which on GitHub runners repeatedly fails with "Error on ZipFile
# unknown archive" and red-flags unrelated PRs. Here the archive named in
# Google's official repository index is fetched with curl (resumable, with
# retries), its SHA-1 from that index is verified, and it is unpacked into
# the SDK exactly where sdkmanager would put it.
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
TARGET="$SDK_ROOT/ndk/$NDK_VERSION"
if [ -f "$TARGET/source.properties" ]; then
  echo "NDK $NDK_VERSION already installed."
  exit 0
fi

REPO="https://dl.google.com/android/repository"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

curl -fsSL --retry 5 --retry-all-errors -o "$WORK/index.xml" "$REPO/repository2-3.xml"
read -r ARCHIVE SHA1 < <(python3 - "$WORK/index.xml" "$NDK_VERSION" <<'PY'
import sys, xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
for pkg in root.iter():
    if pkg.tag.endswith('remotePackage') and pkg.get('path') == f'ndk;{sys.argv[2]}':
        for archive in pkg.iter():
            if not archive.tag.endswith('archive'):
                continue
            host = next((e.text for e in archive.iter() if e.tag.endswith('host-os')), None)
            if host not in (None, 'linux'):
                continue
            url = next(e.text for e in archive.iter() if e.tag.endswith('url'))
            sha1 = next(e.text for e in archive.iter() if e.tag.endswith('checksum'))
            print(url, sha1)
            sys.exit(0)
sys.exit(1)
PY
)
echo "NDK $NDK_VERSION -> $ARCHIVE (sha1 $SHA1)"

for attempt in 1 2 3; do
  # -C - resumes a partial file instead of starting over.
  curl -fSL --retry 5 --retry-all-errors --retry-delay 5 -C - -o "$WORK/ndk.zip" "$REPO/$ARCHIVE" || true
  if echo "$SHA1  $WORK/ndk.zip" | sha1sum -c --status; then
    break
  fi
  echo "Checksum mismatch on attempt $attempt; downloading again."
  rm -f "$WORK/ndk.zip"
  [ "$attempt" = 3 ] && { echo "NDK download failed checksum 3 times."; exit 1; }
done

unzip -q "$WORK/ndk.zip" -d "$WORK/unpacked"
mkdir -p "$SDK_ROOT/ndk"
rm -rf "$TARGET"
mv "$WORK"/unpacked/* "$TARGET"
test -f "$TARGET/source.properties"
echo "NDK $NDK_VERSION installed at $TARGET"
