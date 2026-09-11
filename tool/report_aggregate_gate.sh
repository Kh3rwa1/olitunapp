#!/usr/bin/env bash

set +e

report_failure() {
  local gate="$1"
  local status="$2"
  local output="$3"
  local report=/tmp/aggregate-gate.md

  {
    echo "<!-- aggregate-gate-diagnostics:${TESTED_HEAD} -->"
    echo "## Aggregate gate diagnostics — \`${TESTED_HEAD:0:12}\`"
    echo
    echo "First failing gate: **${gate}** (exit ${status})"
    echo
    echo '```text'
    printf '%s\n' "$output"
    if [[ "$gate" == "Format check" ]]; then
      git --no-pager diff -- .
    fi
    echo '```'
  } > "$report"

  jq -Rs '{body: .}' "$report" > /tmp/aggregate-gate-comment.json
  gh api --method POST \
    "repos/${REPOSITORY}/issues/${PR_NUMBER}/comments" \
    --input /tmp/aggregate-gate-comment.json
  exit 0
}

run_gate() {
  local name="$1"
  shift
  local output
  output=$("$@" 2>&1)
  local status=$?
  if [[ $status -ne 0 ]]; then
    report_failure "$name" "$status" "$output"
  fi
}

run_gate "Format check" dart format --output=none --set-exit-if-changed .
run_gate "File length" node scripts/check_file_length.mjs
run_gate "Typography" node scripts/check_typography.mjs
run_gate "Color tokens" node scripts/check_color_literals.mjs
run_gate "Localization parity" node scripts/check_l10n_parity.mjs
run_gate "Version consistency" dart run tool/verify_version_consistency.dart
run_gate "Action pinning" node scripts/verify_pinned_actions.mjs
run_gate "Signing consistency" node scripts/verify_signing_configuration.mjs
run_gate "Node dependency alignment" node scripts/verify_node_dependency_alignment.mjs
run_gate "Android certificate tests" node --test scripts/verify_android_signing_certificate.test.mjs
run_gate "Release-gate tests" node --test scripts/check_release_gate.test.mjs

report_failure "None" 0 "All pre-analyzer aggregate gates passed."
