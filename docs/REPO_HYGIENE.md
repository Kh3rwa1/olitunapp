# Repository Hygiene

Operational notes for keeping the Olitun repository lean, reproducible, and
free of build residue. Companion to [`tech_debt.md`](tech_debt.md).

---

## 1. Why: git history carries ~370 MB of build output

The repository's `.git` directory had grown to **472 MB** because generated
build artifacts were committed before `.gitignore` covered them. The largest
blobs reachable in history were:

| Size | Path | Class |
| --- | --- | --- |
| 71.6 MB | `build/dabf21cbd4f3da7d57aed22daf3344d1.cache.dill.track.dill` | Dart incremental cache |
| 68.3 MB ×3 | `build/*.cache.dill.track.dill` | Dart incremental cache |
| 54.6 MB | `mapping.txt` | R8/ProGuard symbolication output |
| 14.8 MB ×2 | `build_web_v7.zip`, `build_web_v8.zip` | Web build export |
| 12.0 MB | `deployment.tar.gz` | Deployment bundle |
| 6.7 MB | `build/web/canvaskit/canvaskit.wasm` | Flutter web engine |
| 5.4 MB | `build/web/canvaskit/chromium/canvaskit.wasm` | Flutter web engine |

These are all reproducible build outputs. None of them belong in version
control, and their presence makes every clone and CI checkout slower.

**`.gitignore` and `.gitattributes` now prevent recurrence, but they cannot
retroactively shrink history.** That requires the rewrite below.

---

## 2. Preventing recurrence (already applied)

* `.gitattributes` classifies binaries, pins `eol=lf` for source, and marks
  generated/vendored trees so they stay out of diffs and language stats.
* `.gitignore` was de-duplicated and now ignores release artifacts by **global
  glob** (`*.apk`, `*.aab`, `*.zip`, `*.tar.gz`, `mapping.txt`) rather than by
  exact root path, so a stray export cannot re-enter the repo from any folder.

### Keeping release artifacts without polluting the repo

Symbolication files and release binaries must be retained — `mapping.txt` is
required to deobfuscate crash reports from an already-shipped build — but they
should live **outside** the working tree. They were moved to:

```
~/olitun-release-artifacts/
```

A one-time renormalization may be required after `.gitattributes` lands:

```bash
git add --renormalize .
git commit -m "chore: normalize line endings"
```

---

## 3. Rewriting history to drop the blobs (maintainer-run, deliberate)

Use [`scripts/clean_history_remove_build_artifacts.sh`](../scripts/clean_history_remove_build_artifacts.sh).

```bash
# 1. install git-filter-repo without touching system Python
python3 -m venv /tmp/gfr && /tmp/gfr/bin/pip install git-filter-repo
export PATH="/tmp/gfr/bin:$PATH"

# 2. preview (makes no changes)
scripts/clean_history_remove_build_artifacts.sh

# 3. perform the rewrite (makes a backup bundle first)
scripts/clean_history_remove_build_artifacts.sh --apply
```

The script refuses to run on a dirty working tree, writes a full backup bundle
to `~/olitun-history-backup-<timestamp>.bundle`, and **verifies that the HEAD
tree hash is byte-identical before and after** — proving only history changed,
never content.

### Blast radius — read before running

`git filter-repo` rewrites **every commit SHA**:

* the `origin` remote config is removed (to prevent an accidental push);
* all branches and tags must be force-pushed;
* existing clones cannot fast-forward and must be re-cloned;
* GitHub release tags and any SHA referenced in release notes change.

Therefore this is a *deliberate maintenance-window* operation, not something a
CI job or an automated agent should trigger.

---

## 4. Verification

After a rewrite, confirm:

```bash
du -sh .git                                   # expect a large reduction
git rev-list --all --count                    # commit count unchanged
git rev-parse HEAD^{tree}                     # must match the pre-rewrite hash
git log --oneline -5                          # history still intact
```

Measured result of the dry run against a mirror clone is recorded in
[§5](#5-measured-result).

---

## 5. Measured result

Verified against a throwaway `--mirror` clone (local hardlink clone, so the
source repository was never touched):

| Metric | Before | After |
| --- | --- | --- |
| `.git` size | **471 MB** | **41 MB** (−91%) |
| Commits | 2081 | 2033 |
| `HEAD^{tree}` | `9f8e25a7618206fed983fa91efaadbec55f87355` | *identical* |

The identical tree hash is the important line: it proves the rewrite changed
**only history**, and not a single byte of the current tree.

### About the commit count (2081 → 2033)

`git filter-repo` prunes commits that become empty once the filtered paths are
removed (`--prune-empty` defaults to `auto`). 48 commits consisted *entirely* of
`build/`, `mapping.txt`, or `sites/` changes, so they are dropped. Their content
is preserved in the backup bundle, and the edits they represent are dead build
output. If you would rather keep those commit objects:

```bash
git filter-repo --force --prune-empty never \
  --strip-blobs-bigger-than 5M \
  --invert-paths --path build --path mapping.txt --path sites
```

### Rollback

The script writes `~/olitun-history-backup-<timestamp>.bundle` before rewriting:

```bash
git clone ~/olitun-history-backup-<timestamp>.bundle restored-repo
```