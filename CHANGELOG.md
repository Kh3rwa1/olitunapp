# Changelog

All notable changes to Olitun will be documented in this file.

This project uses conventional commits and release-please to keep release notes
and tags consistent.

## [Unreleased]

### Added
- Scheduled daily cleanup function `cleanupAnalyticsEvents` to automatically prune learning analytics older than 90 days.
- Scheduled weekly backup function `backupCollections` to export core curriculum and config collections to `admin_backups` bucket with 12-file rolling retention.

### Changed
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
