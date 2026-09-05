# Premium content authorization boundary rollout

## What this change does

- Centralizes the publication decision for lesson bodies.
- Keeps free categories and explicitly configured positive-order previews public.
- Fails closed for premium items, unknown unlock modes, missing categories, and failed category lookups.
- Adds a dry-run-first checker for existing lesson document permissions.

## What this change does not do

- It does not make already downloaded, cached, or bundled content secret. Content shipped to a client cannot be revoked afterward.
- It does not change production Appwrite permissions, collection settings, buckets, or data.
- It does not make the existing public media buckets safe for paid assets.
- It does not by itself provide entitled learners with protected bodies. Direct client database access must not be re-enabled as a workaround.

## Required activation sequence

1. Confirm `lessons` has Appwrite document security enabled in a non-production environment. The checker refuses to apply when it is disabled.
2. Deploy an authenticated backend retrieval endpoint that:
   - derives the user from the Appwrite execution identity;
   - reads the category and lesson using server credentials;
   - grants free and configured preview lessons;
   - otherwise verifies an active entitlement using the existing payment source of truth;
   - returns only the requested entitled lesson body and short-lived/signed media references;
   - fails closed on missing, stale, refunded, disputed, or ambiguous entitlement state.
3. Add a separate private paid-media bucket with file security enabled. Copy paid assets, update protected lesson references, verify signed retrieval, and only then remove old public copies. Do not flip all existing buckets to private because free content depends on them.
4. Run the checker without write flags:

   ```bash
   APPWRITE_PROJECT_ID=... APPWRITE_API_KEY=... node scripts/check_premium_content_permissions.mjs
   ```

   Exit code `2` means drift was found; no writes were made.
5. Validate anonymous negative access, entitled access, refunds/disputes, preview access, free access, and offline behavior in staging.
6. During a controlled maintenance window, apply only after review:

   ```bash
   APPWRITE_PROJECT_ID=... APPWRITE_API_KEY=... node scripts/check_premium_content_permissions.mjs --apply --confirm=premium-content-permissions
   ```

7. Re-run dry-run mode and the staging negative-access suite. Keep rollback exports before deleting any old public media.

## Backend retrieval seam

The mobile repository now owns publication decisions only. The activation endpoint should expose a narrow `getAuthorizedLesson(lessonId)` contract to the learner data source. It must return public previews/free lessons without purchase and protected bodies only after server-side entitlement verification. The client may render locks, but UI state is never authorization.

## Current blocker

Until the backend retrieval endpoint, document security, permission migration, and private paid-media path are deployed together, premium content security is incomplete. This branch intentionally avoids a bypass flag and does not claim that current production data is protected.
