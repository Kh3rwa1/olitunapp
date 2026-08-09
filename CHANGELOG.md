# Changelog

All notable changes to Olitun will be documented in this file.

This project uses conventional commits and release-please to keep release notes
and tags consistent.

## [Unreleased]

### Added
- **Production Hardening (10/10)**:
  - Appwrite explicit permissions model (`createPublicContent`, `createOwnerPrivateRow`, `createAdminOnlyRow`, `createFunctionManagedRow`, `updateDataPreservingPermissions`).
  - Server-authoritative account deletion function with multi-collection data purge and financial ledger anonymization (`functions/delete-account/`).
  - Durable, non-expiring mutation outbox (`MutationOutboxService`) with dedicated Hive storage and backoff jitter.
  - Stale-while-revalidate fallback protection (`StaleWhileRevalidateRepository`) to preserve cached entitlements during offline/network failure.
  - Production error screen sanitization and fail-soft startup for non-essential audio and crash reporting services.
  - Hardened open-redirect protection on web routing.
  - Decoupled CI/CD workflows (`flutter-ci.yml` and `staging-health.yml`).
  - Comprehensive documentation (`PRODUCTION_HARDENING_REPORT.md`, `APPWRITE_PERMISSIONS.md`, `ACCOUNT_DELETION.md`, `PAYMENT_STATE_MACHINE.md`, `DATA_CLASSIFICATION.md`, `INCIDENT_RESPONSE.md`, `ROLLBACK.md`, `STAGING_SETUP.md`).
- Daily Affirmations system: Appwrite `daily_affirmations` collection, dynamic CMS panel for CRUD, deterministic daily selection, play/listen audio, mark-as-read analytics, and Watermarked WhatsApp Share.
- Course Unlock and Paywall infrastructure: `course_purchases` collection, local `razorpay_flutter` payments, `in_app_review` feedback integration, custom course preview bounds, and dynamic pricing.
- Binti Guru booking/waitlist: `binti_guru_waitlist` collection, segmented tab switch in Bakhed screen, booking form sheet, user dashboard bookings view, and admin marketplace lead dashboard with quick Call/WhatsApp integrations.
- Dynamic Onboarding Goals: Admin goals editor CMS with title customization, custom icons list, dynamic retrieval from Appwrite `app_settings` setting `onboarding_goals`, and user preferences persistence via `learning_goals` array.
- Scheduled daily cleanup function `cleanupAnalyticsEvents` to automatically prune learning analytics older than 90 days.
- Scheduled weekly backup function `backupCollections` to export core curriculum and config collections to `admin_backups` bucket with 12-file rolling retention.

### Changed
- Home screen simplified to three core blocks: `TodayAffirmationCard`, `NextBestActionCard`, and `TodayMissionCard` to reduce visual noise.
- Mistake review card relocated from Home to post-quiz Quiz Result screen.
- Global `app_colors.dart` slimmed from ~14KB to under 5KB, retaining semantic tokens.
- Standard categories upgraded to structured unlockable courses.
- Verification & OTP screen redirects optimized to transition to `/onboarding`.
- Flattened rhyme subcategories into tag arrays/chips on the rhymes collection and UI.
- Reorganized Admin sidebar into exactly 4 semantic groups (Overview, Content, Monetization, Operations, Media) to consolidate administration operations.

### Removed
- Legacy collections creation logic: `weekly_circles`, `circle_members`, `circle_events`, `weekly_circle_recaps`, and `streak_shields` are no longer created.
- Weekly Learning Circles feature
- Streak Shield gamification
- Decorative home glows (performance)
- Notifications placeholder
- Rhymes subcategory CRUD/UI forms and providers.
- Video players, dependencies (`video_player`, `cached_video_player_plus`), and video media field uploads.
- Unused dependencies `path`, `record`, and `permission_handler`.
- Unused Premium translation hub (`ai_magic_hub.dart`).
- Bento stats layout (`home_bento_widgets.dart` shim and directory).
- Legacy mobile learning preview card slider (`learning_path_preview.dart`).
- Deprecated `rhyme_categories` collection, repositories, providers, CRUD screens, seeding scripts, and sidebar entries.
- Dedicated CRUD sub-screens from Gamification panel for seed-only collections (`bravo_messages`, `reward_messages`, `quiz_feedback_messages`, `mission_templates`).

### Kept
- Protected the Translate feature (`magic_translate_dialog.dart` explicitly preserved across mobile, backend, and admin, including Admin translation tool and backend caches/rate-limits).

## 1.1.1

- Hardened the learning product with production gamification, admin operations,
  analytics, Bakhed learning content, and Android/web release checks.
