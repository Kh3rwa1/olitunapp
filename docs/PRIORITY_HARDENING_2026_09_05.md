# Priority hardening: code and evidence boundaries

## Changes
- Ad SDK requests require positively established UMP eligibility. Errors and unknown consent fail closed; changing eligibility updates visible placements.
- Offline content saves commit the durable outbox before returning success. Replay is single-flight, awaits bookkeeping, respects retry times, and cannot acknowledge a re-queued offline operation as a remote success.
- Entitlement refresh notifies active consumers. Authorization failures clear access; network-only offline grace is bounded to 24 hours since last verification. This is an explicit policy limit, not DRM.
- appwrite.json is authoritative for function deployment entries. CI requires matching entries in appwrite.config.json, scheduled recovery jobs are not user-callable, and deletion recovery has users.write.
- Screen-only tests are labelled smoke tests. The release workflow requires live staging checks; missing credentials are failures, never evidence of a successful backend check.
- Translation remains free/public. Defaults are 120 incoming requests/minute and 30 uncached upstream calls/minute per deployment, configurable within 1..500. A local circuit opens after five upstream failures for 30 seconds. The distributed budget remains authoritative across replicas. TRANSLATION_ENABLED=false pauses translation. Cache hits consume only the request budget.

## Operator setup before release
1. Deploy the function manifest and compare live scopes/schedules. This PR does not change production.
2. Configure STAGING_APPWRITE_ENDPOINT, STAGING_APPWRITE_PROJECT_ID and STAGING_APPWRITE_API_KEY in GitHub connection settings/secrets, not chat. Use a dedicated non-production project and its matching schema snapshot.
3. Provision translator rate_limits access and retention cleanup, then deploy translator. Alert on translation_budget_rejected, translation_budget_low, upstream failures and Appwrite billing. Rate budgets are not monetary spend measurements; external billing alerts remain operator-owned.
4. Run payment capture/refund and deletion/recovery with disposable staging users and Razorpay test mode; retain evidence for this exact commit. No live payment or destructive staging journey was run by the patch author.
5. Exercise offline process restart/reconnect and consent-required/error states on Android and iOS. Unit tests and rendering smoke tests are not substitutes for real-device E2E evidence.

## Rollback
Revert the code commit and redeploy the previous function version if needed. Do not remove users.write from active recovery jobs until their behavior no longer needs it. Translation can be paused independently with the kill switch.
