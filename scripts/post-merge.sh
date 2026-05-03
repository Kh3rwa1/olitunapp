#!/bin/bash
# Runs after a task merges. Keep idempotent, fast, and non-interactive.
# This project's runtime is `node server.js` serving the prebuilt
# `build/web/` directory — no Node deps to install at the repo root.
# Auxiliary scripts under `scripts/` have their own package.json and
# are only run by maintainers manually, so we don't install them here.
set -e

echo "[post-merge] no automated steps required (static server, no root deps)"
