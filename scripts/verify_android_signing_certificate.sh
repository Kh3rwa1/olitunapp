#!/usr/bin/env bash
set -euo pipefail

APK_PATH="${1:-}"
EXPECTED_CERT="${2:-${ANDROID_EXPECTED_CERT_SHA256:-}}"

if [ -z "$APK_PATH" ]; then
  echo "❌ ERROR: Path to APK file is required as first argument."
  exit 1
fi

if [ ! -f "$APK_PATH" ]; then
  echo "❌ ERROR: APK file not found at '$APK_PATH'."
  exit 1
fi

if [ -z "$EXPECTED_CERT" ]; then
  echo "❌ ERROR: ANDROID_EXPECTED_CERT_SHA256 is required for production release certificate verification."
  exit 1
fi

# Normalize expected SHA-256: remove colons, whitespace, dashes, uppercase
NORMALIZED_EXPECTED=$(echo "$EXPECTED_CERT" | tr -d ' :\r\n\t-' | tr '[:lower:]' '[:upper:]')

if [[ ! "$NORMALIZED_EXPECTED" =~ ^[0-9A-F]{64}$ ]]; then
  echo "❌ ERROR: ANDROID_EXPECTED_CERT_SHA256 is malformed. Expected exactly 64 hexadecimal characters."
  exit 1
fi

echo "🔍 Verifying APK signature and certificate for '$APK_PATH'..."

# Verify signature validity
if ! apksigner verify --verbose "$APK_PATH" > /tmp/apksigner_verify.log 2>&1; then
  echo "❌ ERROR: APK signature verification failed!"
  cat /tmp/apksigner_verify.log
  exit 1
fi

# Extract signer certs
if ! apksigner verify --print-certs "$APK_PATH" > /tmp/apksigner_certs.log 2>&1; then
  echo "❌ ERROR: Failed to extract certificates from APK."
  cat /tmp/apksigner_certs.log
  exit 1
fi

# Parse SHA-256 fingerprints from apksigner output
SIGNER_CERTS=$(grep -i "certificate SHA-256 digest:" /tmp/apksigner_certs.log | awk '{print $NF}' || true)

if [ -z "$SIGNER_CERTS" ]; then
  echo "❌ ERROR: No SHA-256 certificate digest found in apksigner output."
  cat /tmp/apksigner_certs.log
  exit 1
fi

SIGNER_COUNT=$(echo "$SIGNER_CERTS" | wc -l | tr -d ' ')
if [ "$SIGNER_COUNT" -ne 1 ]; then
  echo "❌ ERROR: Expected exactly 1 signer certificate, but found $SIGNER_COUNT signers."
  exit 1
fi

NORMALIZED_ACTUAL=$(echo "$SIGNER_CERTS" | tr -d ' :\r\n\t-' | tr '[:lower:]' '[:upper:]')

if [[ ! "$NORMALIZED_ACTUAL" =~ ^[0-9A-F]{64}$ ]]; then
  echo "❌ ERROR: Extracted actual certificate SHA-256 digest is malformed."
  exit 1
fi

if [ "$NORMALIZED_ACTUAL" != "$NORMALIZED_EXPECTED" ]; then
  ACTUAL_PREFIX="${NORMALIZED_ACTUAL:0:8}...${NORMALIZED_ACTUAL: -8}"
  EXPECTED_PREFIX="${NORMALIZED_EXPECTED:0:8}...${NORMALIZED_EXPECTED: -8}"
  echo "❌ ERROR: APK signing certificate mismatch!"
  echo "   Expected: $EXPECTED_PREFIX"
  echo "   Actual:   $ACTUAL_PREFIX"
  exit 1
fi

echo "✅ APK production signing certificate verified successfully (Signer SHA-256 matches expected production certificate)."
