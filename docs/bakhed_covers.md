# 🎬 Bakhed Rhymes: Image and Video Covers Architecture

This document describes the design patterns, visual expectations, and security defenses that support premium image and video cover layouts for Bakhed Rhymes in Olitun.

---

## 🌟 Visual & UX Playback Behaviors

We maintain strict visual standards across all surfaces to provide a premium feel while avoiding battery/network drain.

### 1. Card Lists & Bento Grids (`CoverThumbnail`)
To protect system performance and preserve butter-smooth scrolling:
*   **Image Covers:** Render statically using a responsive, rounded glassmorphic aspect ratio block.
*   **Video Covers:** Render as a **paused first-frame poster**. A visual overlay displaying a play-circle badge appears in the bottom right corner, immediately signaling that the card is playable.
*   **Deferred-Pause Rule:** In list contexts, initialization is kept highly responsive using a **5-second timeout**. If a video player is initialized within list cells or list picker tiles, it is immediately paused via `Future.microtask` to prevent race conditions on the rendering tree.

### 2. Rhyme Detail Screen Header (`CoverHero`)
When a user opens a rhyme, the layout blossoms into a immersive rich media view:
*   **Image Covers:** Render statically as a full-bleed background cover behind the enchantment visualizer.
*   **Video Covers:** Seamlessly start playing a **muted, looping, autoplaying cover video** immediately upon entry.
*   **Interactive Controls:** The detail screen has zero video controls. The video acts as a passive, premium atmospheric backdrop behind the visualizer and back buttons.
*   **App Lifecycle Sync:** The player listens to native App Lifecycle events. Going into the background immediately pauses playback to conserve CPU and device resources. Returning to the application resumes playback instantly.
*   **Navigation Guard Rails:** Rapid screen pops are fully guarded. Active `mounted` validations are enforced after every single asynchronous call (initialization, setting volume, setting looping, calling play) to completely eliminate race-condition crashes on fast back-navigation.

---

## 🛡️ Three-Layer Defense System

To prevent abandoned files and ensure storage efficiency across buckets, we enforce a strict three-layer defense boundary:

```
[Layer 1: Client Validation]
  → File extension (mp4, webm, mov)
  → File size (< 10 MB)
  → Video duration (< 5 mins)
      ↓
[Layer 2: Server Bucket Restrictions]
  → cover_videos storage bucket config (10 MB cap, restricted extensions)
  → team:admins write permissions only
      ↓
[Layer 3: Orphan Cleanup Script]
  → Scheduled node sweeping script
  → Verifies active DB document mappings (hero_media)
  → Safely purges unreferenced storage files
```

### 1. Layer 1: Client-Side CMS Validation
In `MediaUploader` and `bakhed_editor_controller.dart`, we enforce immediate client checks before any upload is dispatched:
*   **Size Limit:** Maximum `10 MB` size threshold.
*   **Duration Limit:** Maximum `5 minutes` video duration limit.
*   **Allowed MIMEs:** Restricts selection to `.mp4`, `.webm`, or `.mov` files.

### 2. Layer 2: Server Bucket Security
The `cover_videos` storage bucket is locked down natively via Appwrite permissions:
*   **Max Upload Limit:** Synchronized with the 10 MB client limit.
*   **Restricted Formats:** File extensions restricted to the allowed enum.
*   **Admin Write Guard:** Access control grants `create`, `update`, and `delete` privileges exclusively to authenticated members of the `team:admins` group.

### 3. Layer 3: Orphan Cleanup Script
A Node script (`scripts/cleanup_orphaned_media.mjs`) is configured to sweep both `audio` and `cover_videos` buckets regularly (run on CI/cron).
*   **Reference Check:** Scans the `rhymes` collection's `hero_media`/`heroMedia` JSON objects to resolve references.
*   **Safety Window:** Ignores any orphan file that is younger than **1 hour** to avoid deleting files that are actively in-flight during admin creation sessions.
*   **Safety-First Exec:** Defaults to `--dry-run` to log potential deletes; requires `--apply` for execution.

---

## 💻 Code Reference Cheat Sheet

*   **List Card Widget:** Promoted to [cover_thumbnail.dart](file:///Users/dulorai/olitun/olitunapp/lib/shared/widgets/cover_thumbnail.dart)
*   **Detail Hero Widget:** Found in [cover_hero.dart](file:///Users/dulorai/olitun/olitunapp/lib/features/rhymes/presentation/widgets/cover_hero.dart)
*   **Validation Rules:** Found in [media_uploader.dart](file:///Users/dulorai/olitun/olitunapp/lib/core/storage/media_uploader.dart)
*   **Cleanup Script:** Found in [cleanup_orphaned_media.mjs](file:///Users/dulorai/olitun/olitunapp/scripts/cleanup_orphaned_media.mjs)
