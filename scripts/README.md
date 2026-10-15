# Olitun Scripts & Utilities

Build scripts and CI gates. The backend is the Cloudflare Worker in
`cloudflare/backend` (its own scripts live in `cloudflare/backend/scripts/`);
Appwrite is used only for sign-in, so nothing here provisions or seeds
Appwrite.

## Build & deploy

| Script | Purpose |
|--------|---------|
| `build_web.sh` | Production web build (Worker-only defines), service-worker patch + verification, copies `web/_headers` and `web/_redirects`. Used by `deploy-web.yml`. |
| `deploy_web_cloudflare.sh` | Manual fallback: `build_web.sh` + `wrangler pages deploy`. |
| `build_playstore_bundle.sh` | Signed Play Store `.aab` (needs `android/key.properties`). |
| `patch_service_worker.{dart,mjs}`, `verify_service_worker_patch.{dart,mjs}`, `verify_pwa_offline.dart` | Service-worker patching and offline checks for `build/web`. |
| `verify_android_signing_certificate.sh` | Compares an APK's signing certificate with the expected SHA-256. |
| `verify_release_artifacts.sh` | Checksums and non-empty checks for CI release artifacts. |

## CI gates (`.github/workflows/flutter-ci.yml`)

| Script | Enforces |
|--------|----------|
| `check_file_length.mjs`, `check_typography.mjs`, `check_color_literals.mjs`, `check_sheets_above_nav.mjs` | Code-style gates |
| `check_architecture_boundaries.mjs` | Layering and `package:appwrite` isolation |
| `check_appwrite_auth_only.mjs` | `lib/` uses Appwrite only for authentication |
| `check_l10n_parity.mjs`, `check_hardcoded_strings.mjs` (+ `hardcoded_strings_baseline.json`) | Localization |
| `check_review_corpus_ids.mjs` | Bundled corpus items and review ID migrations (`assets/seed/review_item_id_migrations.json`) |
| `check_environment_isolation.mjs` | No production identifiers in runtime config or CI builds |
| `verify_pinned_actions.mjs` | Every GitHub Action pinned to a commit SHA |
| `verify_signing_configuration.mjs` | Android signing configuration consistency |
| `check_dependency_freshness.mjs` | Flutter dependency freshness and `npm audit` of the Worker |
| `check_release_gate.mjs` | Release gate: every required CI job succeeded |
| `verify_release_workflows.mjs`, `verify_release_version.mjs` | Release Checklist evidence and version consistency |
| `test_gitleaks_rules.mjs` | Gitleaks rule regression tests |

Run the Node unit tests for all of the above with `npm run test:backend` from
the repo root (also covers `test/web/` and `test/scripts/`).

## Other

- `validate_sentence_quizzes.mjs` — validates bundled sentence lessons for quiz generation.
- `check_performance_budgets.sh`, `preview_coverage_gate.sh` — local previews of CI budgets/coverage gates.
- `oneoff/` — historical one-off content and repo-maintenance tools kept for
  reference (translation corpus builders, l10n key merge, git-history
  cleanup). Nothing references them and they are not maintained; read before
  running.
