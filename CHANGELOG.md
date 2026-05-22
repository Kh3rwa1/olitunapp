# Changelog

All notable changes to Olitun will be documented in this file.

This project uses conventional commits and release-please to keep release notes
and tags consistent.

## [Unreleased]

### Added
- Daily Affirmations system: Appwrite `daily_affirmations` collection, dynamic CMS panel for CRUD, deterministic daily selection, play/listen audio, mark-as-read analytics, and Watermarked WhatsApp Share.
- Course Unlock and Paywall infrastructure: `course_purchases` collection, local `razorpay_flutter` payments, `in_app_review` feedback integration, custom course preview bounds, and dynamic pricing.
- Binti Guru booking/waitlist: `binti_guru_waitlist` collection, segmented tab switch in Bakhed screen, booking form sheet, user dashboard bookings view, and admin marketplace lead dashboard with quick Call/WhatsApp integrations.
- Dynamic Onboarding Goals: Admin goals editor CMS with title customization, custom icons list, dynamic retrieval from Appwrite `app_settings` setting `onboarding_goals`, and user preferences persistence via `learning_goals` array.
- Scheduled daily cleanup function `cleanupAnalyticsEvents` to automatically prune learning analytics older than 90 days.
- Scheduled weekly backup function `backupCollections` to export core curriculum and config collections to `admin_backups` bucket with 12-file rolling retention.

### Changed
- Standard categories upgraded to structured unlockable courses.
- Verification & OTP screen redirects optimized to transition to `/onboarding`.
- Flattened rhyme subcategories into tag arrays/chips on the rhymes collection and UI.

### Removed
- Legacy collections creation logic: `weekly_circles`, `circle_members`, `circle_events`, `weekly_circle_recaps`, and `streak_shields` are no longer created.
- Weekly Learning Circles feature
- Streak Shield gamification
- Decorative home glows (performance)
- Notifications placeholder
- Rhymes subcategory CRUD/UI forms and providers.
- Video players, dependencies (`video_player`, `cached_video_player_plus`), and video media field uploads.
- Unused dependencies `path`, `record`, and `permission_handler`.

## 1.1.1

- Hardened the learning product with production gamification, admin operations,
  analytics, Bakhed learning content, and Android/web release checks.
