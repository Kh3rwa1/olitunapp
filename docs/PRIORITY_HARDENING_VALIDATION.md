# Priority hardening verification

Validated implementation commit: `84560f8d9148fcffe7e979365e1e8252fdde9a21`.

- `flutter analyze --fatal-infos`: passed, no issues.
- `flutter test test/core/ads test/core/payments test/shared/offline`: 38 passed, zero failures.
- `npm test`: 150 backend tests passed, zero failures; one live staging test skipped because staging credentials were absent. Shared-module synchronization and secret-rule fixture checks passed.
- Function manifest, schedules, execution roles and required scopes: verified.

The final release-workflow changes and manifest regression entry point are subject to the pull request's normal CI checks. The implementation test results above are not a claim that every later workflow configuration or physical-device behavior was exercised.

## Still required before release
- Configure `STAGING_APPWRITE_ENDPOINT`, `STAGING_APPWRITE_PROJECT_ID` and `STAGING_APPWRITE_API_KEY` in GitHub repository Settings → Secrets and variables → Actions. The staging project must differ from production.
- Run mandatory staging smoke, concurrency and schema verification. Unlike the ordinary secretless unit suite, the release staging workflow fails if credentials are missing.
- Exercise actual Razorpay test-mode capture/refund and account deletion/recovery with disposable staging accounts, and verify offline restart and consent transitions on devices. Rendering smoke tests do not establish those outcomes.
- Deploy function scope/schedule changes and confirm translator retention cleanup/budget alerts. Nothing was merged or deployed by the patch author.

Raw validation output is retained in Git history at `93341dd9c23f4efc98ec04011e3cc5dc43a1ebd7:docs/PRIORITY_PATCH_DIAGNOSTICS.txt`; temporary editing workflows/scripts are removed from the final PR tree.
