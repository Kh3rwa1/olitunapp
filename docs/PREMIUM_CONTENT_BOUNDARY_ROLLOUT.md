# Premium content authorization boundary rollout

## What this change does

- Centralizes the publication decision for lesson bodies.
- Keeps free categories public and preserves the existing positive-order preview window only for known paid unlock modes.
- Fails closed for premium items, unknown unlock modes, missing categories, and failed category lookups.
- Adds a dry-run-first checker for existing lesson document permissions.

## Preview assumption

The current schema exposes `previewLessonCount`, but has no explicit per-lesson preview flag or stable preview rank. The compatibility rule `order > 0 && order <= previewLessonCount` is only a legacy order window. It does **not** reliably mean “the first N lessons” when orders are duplicated, gapped, zero, or edited. Operators must audit the resulting preview set. A future schema migration should add an explicit preview marker or stable rank before relying on exact first-N behavior.

## What this change does not do

- It does not make already downloaded, cached, or bundled content secret. Content shipped to a client cannot be revoked afterward.
- It does not change production Appwrite permissions, collection settings, buckets, or data.
- It does not make the existing public media buckets safe for paid assets.
- It does not by itself provide entitled learners with protected bodies. Direct client database access must not be re-enabled as a workaround.

## Required activation sequence

1. In a non-production environment, confirm `lessons` has Appwrite document security enabled **and no collection-level `read(...)` grants**. Appwrite collection and document permissions are additive, so any collection read grant bypasses protected document permissions. The checker refuses to apply until every collection read grant is removed in a separate, reviewed operator change.
2. Deploy an authenticated backend retrieval endpoint that:
   - derives the user from the Appwrite execution identity;
   - reads the category and lesson using server credentials;
   - grants free lessons and only the audited legacy order-window previews;
   - otherwise verifies an active entitlement using the existing payment source of truth;
   - returns only the requested entitled lesson body and short-lived/signed media references;
   - fails closed on missing, stale, refunded, disputed, or ambiguous entitlement state.
3. Add a separate private paid-media bucket with file security enabled. Copy paid assets, update protected lesson references, verify signed retrieval, and only then remove old public copies. Do not flip all existing buckets to private because free content depends on them.
4. Run the checker without write flags. The target project must be explicit; repository configuration is never used as a fallback:

   ```bash
   APPWRITE_PROJECT_ID=staging-project APPWRITE_API_KEY=... node scripts/check_premium_content_permissions.mjs
   ```

   Exit code `2` means drift was found; no writes were made. Requests time out after 10 seconds and the scan refuses to exceed 10,000 documents per collection.
5. Audit the preview set for duplicate, gapped, and zero orders. Validate anonymous denial, entitled access, refunds/disputes, free access, and offline behavior in staging.
6. During a controlled maintenance window, bind explicit confirmation to the exact target project:

   ```bash
   APPWRITE_PROJECT_ID=staging-project APPWRITE_API_KEY=... node scripts/check_premium_content_permissions.mjs --apply --confirm-project=staging-project
   ```

7. Re-run dry-run mode and the staging negative-access suite. Keep rollback exports before deleting any old public media.

## Backend retrieval seam

The mobile repository now owns publication decisions only. The activation endpoint should expose a narrow `getAuthorizedLesson(lessonId)` contract to the learner data source. It must return public previews/free lessons without purchase and protected bodies only after server-side entitlement verification. The client may render locks, but UI state is never authorization.

## Serializer scope

`ContentRepository.upsert` calls `ContentItem.toAppwrite()`. That model method now refuses lessons and explicitly premium items before the repository can assign its legacy anonymous read permission. `toJson()` remains available for local cache/outbox serialization, and free letter, number, word, sentence, and rhyme Appwrite serializers remain supported. Regression tests cover both sides of this boundary.

## Current blocker

Until the backend retrieval endpoint, removal of collection-level read grants, document security, permission migration, and private paid-media path are deployed together, premium content security is incomplete. This branch intentionally avoids a bypass flag and does not claim that current production data is protected.
