#!/usr/bin/env bash
# Remove large build artifacts from git history.
#
# WHY THIS IS A SCRIPT AND NOT AUTO-RUN BY CI/AGENTS
# ------------------------------------------------
# `git filter-repo` rewrites EVERY commit SHA in the repository. That means:
#   * your `origin` remote config is removed (to stop an accidental push),
#   * every branch/tag must be force-pushed,
#   * existing clones stop being fast-forwardable,
#   * released GitHub tags and the SHAs referenced in release notes change.
#
# So this must be a deliberate, maintainer-run operation during a quiet window.
# It is safe to run: it makes a backup bundle first and refuses to run on a
# dirty working tree.
#
# USAGE
#   scripts/clean_history_remove_build_artifacts.sh                 # dry run
#   scripts/clean_history_remove_build_artifacts.sh --apply         # rewrite
#
# AFTER --apply  (all four steps are required)
#   git remote add origin git@github.com:Kh3rwa1/olitunapp.git
#   git push --force-with-lease origin main
#   git push --force origin --tags
#   # then ask every collaborator to re-clone (do NOT let them pull)

set -euo pipefail

THRESHOLD="5M"
APPLY=0
[[ "${1:-}" == "--apply" ]] && APPLY=1

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo "==> Repo: $REPO_ROOT"

if ! command -v git-filter-repo >/dev/null 2>&1; then
  cat <<'EOF'
ERROR: git-filter-repo is not installed.

Install it without touching your system Python (recommended):

  python3 -m venv /tmp/gfr && /tmp/gfr/bin/pip install git-filter-repo
  export PATH="/tmp/gfr/bin:$PATH"

or, system-wide:

  brew install git-filter-repo
EOF
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: working tree is dirty. Commit or stash first." >&2
  git status --short | head -20
  exit 1
fi

TREE_BEFORE="$(git rev-parse HEAD^{tree})"
SIZE_BEFORE="$(du -sh .git | cut -f1)"
echo "==> .git size before: $SIZE_BEFORE"
echo "==> HEAD tree before: $TREE_BEFORE"

echo "==> Largest blobs currently reachable in history:"
git rev-list --objects --all \
  | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' \
  | awk '$1=="blob" && $3 > 1048576 {printf "  %6.1f MB  %s\n", $3/1048576, $4}' \
  | sort -rn | head -15

if [[ "$APPLY" -eq 0 ]]; then
  cat <<EOF

DRY RUN — nothing changed.

Would run:
  git filter-repo --force \\
    --strip-blobs-bigger-than $THRESHOLD \\
    --invert-paths --path build --path mapping.txt --path sites

Re-run with --apply to perform the rewrite.
EOF
  exit 0
fi

BACKUP="$HOME/olitun-history-backup-$(date +%Y%m%d-%H%M%S).bundle"
echo "==> Writing backup bundle to $BACKUP"
git bundle create "$BACKUP" --all

echo "==> Rewriting history (stripping blobs > $THRESHOLD and generated dirs)"
# --prune-empty defaults to `auto`, which drops commits that become empty once
# build/, mapping.txt and sites/ are removed (48 such commits on this repo).
# Pass --prune-empty never instead to retain those commit objects.
git filter-repo --force \
  --strip-blobs-bigger-than "$THRESHOLD" \
  --invert-paths \
  --path build \
  --path mapping.txt \
  --path sites

TREE_AFTER="$(git rev-parse HEAD^{tree})"
SIZE_AFTER="$(du -sh .git | cut -f1)"

echo
echo "==> .git size after:  $SIZE_AFTER"
echo "==> HEAD tree after:  $TREE_AFTER"

if [[ "$TREE_BEFORE" != "$TREE_AFTER" ]]; then
  echo "ERROR: HEAD tree changed! Content was modified, not just history." >&2
  echo "Restore from $BACKUP with: git clone $BACKUP" >&2
  exit 1
fi

echo "==> OK: HEAD content is byte-identical; only history was rewritten."
cat <<EOF

NEXT STEPS (required):
  git remote add origin git@github.com:Kh3rwa1/olitunapp.git
  git push --force-with-lease origin main
  git push --force origin --tags

Then tell collaborators to re-clone. Rollback:
  git clone $BACKUP restored-repo
EOF