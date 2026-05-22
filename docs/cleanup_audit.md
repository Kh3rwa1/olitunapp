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

Recommended deletions completed in Phase 3 pre-launch cleanup:

- `weekly_circles` (fully removed from codebase)
- `circle_members` (fully removed from codebase)
- `circle_events` (fully removed from codebase)
- `weekly_circle_recaps` (fully removed from codebase)
- `streak_shields` (fully removed from codebase)
- `rhyme_subcategories` (fully flattened into tag chips in `rhymes` collection and removed from codebase)

Video infrastructure has been completely pruned (video player widgets deleted, dependencies `video_player` and `cached_video_player_plus` removed, and video upload logic removed).

## Data Retention & Backups

### Analytics Data Retention
- The `cleanupAnalyticsEvents` Appwrite function runs daily at `0 3 * * *` (3 AM UTC).
- It automatically prunes detailed learning analytics events (`learning_analytics_events`) older than 90 days.
- Aggregated daily rollups are kept for admin dashboard metrics.

### Content Backups
- The `backupCollections` Appwrite function runs weekly on Sundays at `0 4 * * 0` (4 AM UTC).
- It exports all core curriculum and configuration collections to the `admin_backups` storage bucket in JSON format.
- The function automatically maintains a rolling retention window, keeping only the last 12 backups.

## Phase 4 Cleanup — Home Simplification & Dead Code Removal

- **Goal:** Simplified the Home Screen to 3 core blocks: `TodayAffirmationCard`, `NextBestActionCard`, and `TodayMissionCard` to reduce visual noise.
- **Removed (Home Widgets):**
  - Deleted unused Premium translation hub (`ai_magic_hub.dart`).
  - Deleted Bento stats layout (`home_bento_widgets.dart` shim and directory layout).
  - Deleted legacy mobile learning preview card slider (`learning_path_preview.dart`).
- **Relocated:**
  - Moved mistake review card (`mistake_review_card.dart`) from `lib/features/home/presentation/widgets/` to `lib/features/quiz/presentation/widgets/` to decouple it from home and wire it post-quiz in the quiz results screen.
- **Slimmed Theme Tokens:**
  - Slimmed `app_colors.dart` from ~14KB to under 5KB by completely deleting 40+ unused/redundant colors while maintaining full design tokens for `admin_tokens.dart` and `app_theme.dart`.
- **Performance Sanity:**
  - Added `RepaintBoundary` around all 3 core blocks (`TodayAffirmationCard`, `NextBestActionCard`, `TodayMissionCard`) to avoid unnecessary repaints, keeping their constructors `const` where possible.
- **State Separation:**
  - Extracted cross-cutting gamification/streak state listener logic from `home_screen.dart` into `DailyMissionsObserver` registered in `main.dart`.
- **Preserved:**
  - Protected the Translate feature (`magic_translate_dialog.dart` explicitly preserved).
