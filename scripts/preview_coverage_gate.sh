#!/usr/bin/env bash
# Preview the coverage gate EXACTLY as CI runs it, but with the
# "never-imported file" gate forced into the past so it reports as BLOCKING.
#
# Why: `.github/workflows/flutter-ci.yml` passes
#   --enforce-untested-after=2026-10-01
# so today the untested-files check only WARNS. On 2026-10-01 it starts failing
# the build. This script lets you see that future failure now.
#
# Usage:
#   flutter test --coverage        # produce a FRESH coverage/lcov.info first
#   scripts/preview_coverage_gate.sh
#
# The lcov denominator only contains files imported by at least one test, so a
# stale lcov.info gives a misleading list. Always regenerate before reading it.
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -f coverage/lcov.info ]]; then
  echo "coverage/lcov.info not found. Run: flutter test --coverage" >&2
  exit 1
fi

echo "==> lcov.info last modified: $(date -r coverage/lcov.info '+%Y-%m-%d %H:%M')"

ARGS=$(awk '/dart run tool\/enforce_coverage.dart/,/Smoke tests/' \
        .github/workflows/flutter-ci.yml \
      | sed 's/^[[:space:]]*//' \
      | sed '/^$/d' \
      | sed '/^- name:/d' \
      | tr -d '\\' \
      | sed '1d' \
      | sed 's/--enforce-untested-after=2026-10-01/--enforce-untested-after=2020-01-01/' \
      | tr '\n' ' ')

echo "==> replaying gate with untested-files enforcement active"
eval "dart run tool/enforce_coverage.dart $ARGS"