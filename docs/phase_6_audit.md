# Phase 6 Audit: Stories & Offline

This document presents the detailed audit of the Phase 6 feature set — segment-based stories, segment highlighting, bilingual playback mode, offline audio downloads, and download cache management — as specified in the master spec ("Stories and offline — Segment-based stories, Highlighting, Bilingual mode, Downloads, Cache management").

---

## 1. Table A — Phase 6 Component Audit

Below is the audit of every Phase 6 deliverable, its location, its dependency surface, and its verdict.

| Component | File(s) | Layer | Feature Flag Gate | Verdict |
|---|---|---|---|---|
| Story segment entity | `lib/features/content/domain/entities/story_segment_entity.dart` | Domain | Read-only (always safe) | **KEEP**. Pure entity: 1-based `order`, `textOlChiki`, optional `textLatin`, `translations` map, `audioTracks`, `translationFor(lang)` fallback chain (`translations[lang]` → `en` → `textLatin` → `textOlChiki`), `narrationTrack` (Santali story narration), `translationTrackFor(lang)` (teaching-audio translation). |
| Segment repository contract | `lib/features/content/domain/repositories/story_segment_repository.dart` | Domain | Read-only | **KEEP**. Single `getSegments(storyId)` contract. |
| Segment model + mapping | `lib/features/content/data/models/story_segment_model.dart` | Data | Read-only | **KEEP**. Appwrite `story_segments` document mapping (see Table B); `fromJson` tolerant of missing optional fields — no crash on partial data. |
| Segment remote datasource | `lib/features/content/data/datasources/story_segment_remote_datasource.dart` | Data | Read-only | **KEEP**. Appwrite query ordered by `order`; wraps errors into `ServerException`. |
| Segment repository impl | `lib/features/content/data/repositories/story_segment_repository_impl.dart` | Data | Read-only | **KEEP**. Offline-first: Hive `CacheService` with stale-allowed fallback (existing pattern reused — no second state framework). |
| Segment providers | `lib/features/content/presentation/providers/story_segment_providers.dart` | Presentation | `FutureProvider.autoDispose.family` | **KEEP**. `storySegmentsProvider(storyId)` → ordered segments; empty list when none (drives fallback). |
| Story player body | `lib/features/content/presentation/widgets/story_player_body.dart` | Presentation | `multilingualAudioEnabled` | **KEEP**. Segment-based player: per-segment cards with both scripts, current-segment highlighting, Prev/Play/Next controls, speed cycling (persisted across clips), translation-text toggle (fallback text when translation missing — `translationFallbackUsed` event), translation-audio playback (`translationAudioPlayed` event), bilingual narration→translation chaining (reuses `PlaybackRequest.chain` — no duplicate audio service), resume position persistence via `CacheService` (`story_resume:<storyId>` → `{'segmentIndex': n}`), offline download button. When flag off or no segments: falls back to existing `PremiumBakhedBody` — existing experience preserved. |
| Wire-up | `lib/features/content/presentation/content_detail_screen.dart` | Presentation | `multilingualAudioEnabled` | **KEEP**. Rhyme-kind detail route renders `StoryPlayerBody` when segments exist; unchanged otherwise. |
| Download store (abstract) | `lib/features/content/data/offline/audio_download_store.dart` | Data | n/a | **KEEP**. Platform-agnostic contract: `isSupported`, `absolutePath`, `writeFile`, `fileExists`, `readBytes`, `deleteFile`, `deleteAllFiles`, plus manifest key-value persistence. |
| Download store (IO) | `lib/features/content/data/offline/audio_download_store_io.dart` | Data | n/a | **KEEP**. `dart:io` implementation (mobile/desktop): files under `tracks/`, manifest via `CacheService`-style SharedPreferences-free JSON file. |
| Download store (web stub) | `lib/features/content/data/offline/audio_download_store_stub.dart` | Data | n/a | **KEEP**. Web stub: `isSupported == false` — every download API degrades to a no-op/`unsupportedPlatform` skip reason. Web stays functional (§27). |
| Download manager | `lib/features/content/data/offline/audio_download_manager.dart` | Data | n/a | **KEEP**. Batch downloads with per-item and batch progress, **dedupe** (fresh files skipped, byte-count preserved), **integrity verification** (SHA-256 per file, `verifyIntegrity`, `contentHash` invalidation re-download), cancellation, manifest persistence after each item, storage usage with pruning of missing files, `downloadStoryPack` filtering non-downloadable tracks (`skipReasonFor`: missingUrl / notPlayable / unsupportedPlatform). |
| Download providers | `lib/features/content/presentation/providers/audio_download_providers.dart` | Presentation | `audioDownloadsEnabled` | **KEEP**. `downloadsAvailableProvider` (flag AND platform support), `audioDownloadProvider` notifier (story batches: `courseDownloadStarted` / `courseDownloadCompleted` / `courseDownloadFailed` analytics, per-track states, cancel), `storyDownloadStateProvider` family, `downloadStorageUsageProvider`, `downloadCountProvider`, `downloadableTracksFromSegments` (narration + playable translation per segment). Flag off → all no-ops, zero state. |
| Downloads management card | `lib/features/profile/presentation/widgets/downloads_management_card.dart` | Presentation | `audioDownloadsEnabled` | **KEEP**. Cache management UI in Settings: storage usage (formatted bytes), download count, verify integrity, delete single / delete all. |
| Settings wire-up | `lib/features/profile/presentation/settings_screen.dart` | Presentation | `audioDownloadsEnabled` | **KEEP**. `DownloadsManagementCard` inserted at index 5 in both settings layouts. |
| Analytics events | `lib/core/analytics/analytics_service.dart` | Core | n/a | **KEEP**. New `LearningAnalyticsEvents`: `storyStarted`, `storySegmentPlayed`, `bilingualModeEnabled`, `courseDownloadStarted/Completed/Failed`, `translationFallbackUsed`, `translationAudioPlayed`. |

---

## 2. Table B — Data Model & Storage Audit

| Store | Key / Shape | Written When | Read When | Cleanup |
|---|---|---|---|---|
| Appwrite `story_segments` collection (new; created by `scripts/appwrite_setup.mjs` extension if not present — see migration notes in PR) | Documents: `storyId`, `order` (1-based), `textOlChiki`, `textLatin?`, `translations` (map lang→text), `audioTracks` (inline track docs), `startMs?`/`endMs?`, `imageUrl?`, `vocabularyRefs?` | Admin/seed | `storySegmentsProvider` via repository | Admin-managed |
| Hive cache (existing `CacheService`) | Segment list cache per story (standard repository pattern) | After successful fetch | Offline/stale reads | Existing TTL/eviction policy |
| Hive cache — resume | `story_resume:<storyId>` → `{'segmentIndex': int}` | Segment change / player close | Player open | Overwritten per story |
| Download manifest (JSON via store) | `{trackId, relativePath, contentHash?, bytes, sha256?, downloadedAt}` per entry | After **each** item (crash-safe) | `isDownloaded`, `storageUsageBytes`, `refreshTrackStates` | Pruned on missing file; `deleteTrack`/`deleteAll` remove manifest + file |

No schema changes to existing collections; the `story_segments` collection is additive. No new env vars. No backfill required (segments are optional — stories without segments keep the existing body).

---

## 3. Test Coverage Audit

| Suite | File | Covers |
|---|---|---|
| Manager unit tests | `test/features/content/data/offline/audio_download_manager_test.dart` | Path derivation & extension parsing; all skip reasons; batch success + manifest + final progress (isDone, fraction 1.0); dedupe (fresh → skipped, no refetch); `contentHash` invalidation re-download; HTTP failure ('HTTP 404'); network-error batch survival; un-downloadable excluded from totals; `cancelBatch`; unsupported platform (all-failed, storage untouched); manifest persistence across manager instances; corrupt manifest tolerance; storage usage sum + prune; deleteTrack / deleteAll; `verifyIntegrity` pass / tampered byte / missing file; `localFileUrlFor`; `downloadStoryPack` batchId + filtering |
| Provider/notifier tests | `test/features/content/presentation/providers/audio_download_providers_test.dart` | `downloadsAvailableProvider` gating (flag off / platform off); `downloadableTracksFromSegments` selection (draft + wrong-type excluded); `downloadStory` success (state, started+completed analytics, per-track hydration, usage/count); failure (500 → failed state + `courseDownloadFailed`); flag-off no-op (no state, no events, no files); deleteAll/deleteTrack; `refreshTrackStates` re-hydration from disk; `storyDownloadStateProvider` defaults |
| Widget tests | `test/features/content/presentation/widgets/story_player_body_test.dart` | Renders both scripts of every segment; tap segment plays narration (`storyStarted` + `storySegmentPlayed`); bilingual mode chains narration-first + `bilingualModeEnabled`; text-only segment no-crash (icon, no playback); translation toggle fallback text + `translationFallbackUsed`; resume restore from cache; download button → 'Saved'; flag off → `PremiumBakhedBody` fallback (existing experience preserved); speed cycling; Next navigation |

All suites inject fakes at the seams (`AudioDownloadStore`, `http.Client` via `MockClient`, `AudioService`, analytics `remoteWriter`) — no network, no platform channels, deterministic.

---

## 4. Engineering-Constraint Compliance (spec §27)

- **Reuse, no duplication**: playback goes through the existing `PlaybackController`/`PlaybackRequest.chain`; caching through the existing Hive `CacheService`; analytics through the existing `LearningAnalyticsService`. No second audio service, no second state framework.
- **Flags off = old behavior**: `StoryPlayerBody` renders `PremiumBakhedBody` when `multilingualAudioEnabled` is false or no segments exist; download UI/providers are inert when `audioDownloadsEnabled` is false.
- **Web functional**: web download store is a safe stub (`isSupported == false`); every path checks support before touching IO.
- **No crashes on missing data**: `translationFor` falls back through the chain to Ol Chiki text; segments with no playable audio render text-only and disable audio controls; partial documents map tolerantly; corrupt manifests are skipped, not fatal.
- **Audio-first**: Santali narration is the authoritative target audio; teaching-language translations are secondary audio and text, per spec.

---

## 5. Verdict

Phase 6 is **fully implemented and test-covered**; nothing in this phase is flagged for deletion or restructuring. Deferred to Phase 7 (per approved order): audio quizzes, learning paths, and analytics emission wiring beyond the events added here.
