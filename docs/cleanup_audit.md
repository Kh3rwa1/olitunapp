# Cleanup Audit

Date: 2026-05-22

## Scope

`appwrite.json` and `appwrite.config.json` define functions/sites for this repo, not database collection schemas. The active Appwrite schema source in this codebase is `scripts/appwrite_setup.mjs`, so this audit treats that script as the collection source of truth and cross-checks it against `lib/`, `lib/features/admin/`, `functions/`, and `scripts/`.

No additional collections or admin screens were deleted in this audit.

## Collections

| Collection | Active Flutter provider/read | Admin CRUD or admin visibility | Notes |
| --- | --- | --- | --- |
| `categories` | Yes, category providers and learner navigation | Yes | Active core content |
| `lessons` | Yes, lesson providers and lesson flows | Yes | Active core content |
| `quizzes` | Yes, quiz list/session flows | Yes | Active core content |
| `letters` | Yes, `lettersProvider` | Yes | Active core content |
| `numbers` | Yes, `numbersProvider` | Yes | Active core content |
| `words` | Yes, vocabulary providers/seeders | Yes | Active core content |
| `sentences` | Yes, sentence providers/seeders | Yes | Active core content |
| `rhymes` | Yes, Bakhed/rhyme providers | Yes | Active Bakhed content |
| `rhyme_categories` | Yes, rhyme category provider | Yes | Active Bakhed taxonomy |
| `rhyme_subcategories` | Yes, rhyme subcategory provider | No dedicated CRUD found | Keep for app taxonomy; consider adding admin CRUD before deleting |
| `banners` | Yes, featured banner provider | Yes | Active home content |
| `translation_cache` | No direct Flutter provider | No | Backend translation support; protected |
| `rate_limits` | No direct Flutter provider | No | Backend translation/rate-limit support; protected |
| `app_settings` | Yes, app settings provider | Yes | Active runtime settings |
| `bravo_messages` | Yes, gamification content provider | Yes | Active CMS copy |
| `badges` | Yes, gamification content provider | Yes | Active badge definitions |
| `user_badges` | No direct Flutter collection read | Admin metrics/health | Backend-trusted user badge state |
| `mission_templates` | Yes, gamification content provider | Yes | Active mission CMS |
| `reward_messages` | Yes, gamification content provider | Yes | Active reward copy |
| `quiz_feedback_messages` | Yes, gamification content provider | Yes | Active quiz copy |
| `gamification_config` | Yes, gamification content provider | Yes | Active product config |
| `admin_audit_logs` | No learner read | Yes | Admin-only audit trail |
| `learning_analytics_events` | Yes, analytics service writes | Yes | Active analytics ingestion |
| `learning_analytics_daily_rollups` | No learner read | Yes, analytics dashboard | Active analytics rollups |
| `reward_events` | No learner collection read | Admin health/summary backend | Backend reward ledger |
| `user_mistakes` | Yes, mistake provider/function flow | Admin health | Active mistake sync |
| `mistake_review_sessions` | No direct Flutter collection read | Admin health | Backend review session ledger |
| `bakhed_lyrics` | Yes, Bakhed content provider | Yes | Active Bakhed learning content |
| `bakhed_vocabulary` | Yes, Bakhed content provider | Yes | Active Bakhed learning content |
| `bakhed_cultural_notes` | Yes, Bakhed content provider | Yes | Active cultural content |
| `bakhed_listening_progress` | No direct Flutter collection read | Admin health | Backend/user progress support |

## Storage Buckets

| Bucket | Active app usage | Admin visibility | Notes |
| --- | --- | --- | --- |
| `audio` | Yes, media fields/audio content | Yes | Active media bucket |
| `images` | Yes, upload service and image content | Yes | Active media bucket |
| `animations` | Yes, upload service and Lottie/media fields | Yes | Active media bucket |
| `videos` | Yes, upload service supports video | Partial | Keep unless video uploads are intentionally removed |
| `admin_backups` | No learner usage | Yes, maintenance backup flow | Admin-only backups |

## Recommended Deletions

Do not delete any active collection above without a product decision. The current app still has a plausible reader, writer, admin surface, or backend support role for each configured collection.

Recommended manual cleanup candidates in Appwrite Console, after export/backup and confirmation:

- `weekly_circles`
- `circle_members`
- `circle_events`
- `weekly_circle_recaps`
- `streak_shields`

These legacy collections are no longer created by `scripts/appwrite_setup.mjs` after the cleanup and should only be dropped manually once existing production data is no longer needed.

## Follow-Up

- Add dedicated admin CRUD for `rhyme_subcategories` if editors need to manage Bakhed taxonomy deeply.
- Decide whether video uploads are a near-term feature; if not, hide video upload UI before removing the `videos` bucket.
