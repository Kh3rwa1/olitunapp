# 🧹 Olitun Technical Debt & Deprecation Tracker

This document catalogs deprecated API methods, legacy variables, and deferred cleanups that are preserved temporarily for backward compatibility but scheduled for removal in future sprints.

---

## 🎯 Active Deprecations & Cleanup Tracker

We maintain strict deprecation boundaries: **never delete a legacy method or schema field in the same sprint in which it is deprecated**. Always mark them as `@deprecated` (or equivalent documentation comment) and list them below with their targeted removal sprints.

### 1. `updateThumbnail` (Controller Method)
*   **Location:** `lib/features/admin/presentation/bakhed/controllers/bakhed_editor_controller.dart`
*   **Rationale:** Replaced by `updateCoverMedia` as part of the Phase 2d unified cover picker layout. Video covers and image covers are now handled by a single `ContentMedia` object in the editor state.
*   **Status:** Deprecated in Sprint 2 (Phase 2d).
*   **Target Removal Sprint:** **Sprint 4** (Allowing full client migration across any local/cached dev panels).

### 2. `updateCategoryId` (Controller Method)
*   **Location:** `lib/features/admin/presentation/bakhed/controllers/bakhed_editor_controller.dart`
*   **Rationale:** Replaced by direct object assignment or modern unified state hooks.
*   **Status:** Deprecated in Sprint 2.
*   **Target Removal Sprint:** **Sprint 4**.

### 3. Six `// TODO(orphan-bug):` Markers
*   **Location:** `lib/features/admin/presentation/content/widgets/content_form.dart`
*   **Context:** These markers isolate legacy, ad-hoc file-deletion calls. These inline deletions bypass the central in-flight state tracking and can occasionally fail silently or trigger orphan files if the user aborts an edit session midway.
*   **Transition Path:** Move all media deletions to the central **deferred-deletion queue** managed by the editor controller (matching the `bakhed_editor_controller.dart` deferred delete model implemented in Phase 2e). The central Node media cleanup cron job (`cleanup_orphaned_media.mjs`) acts as our fail-safe backup.
*   **Status:** Active debt.
*   **Target Cleanup Sprint:** **Sprint 3** (Next sprint).

### 4. Per-subcategory Letter/Number Filtering (Universal Content System)
*   **Goal:** Add a true subcategorization relation (`subcategoryId` / `categoryId`) to the `letters` and `numbers` databases in Appwrite, perform a database data backfill, and update `ContentRepository.list` queries to selectively filter these collections.
*   **Rationale:** Tapping a subcategory under Alphabets or Numbers currently loads all items globally due to the database schema omitting a subcategory field. Proper modeling is scheduled for Sprint 14 to allow granular learning grid layouts per-lesson.
*   **Audit Reference:** [phase1_subcategory_fallback_regression_audit.md](file:///Users/dulorai/olitun/olitunapp/phase1_subcategory_fallback_regression_audit.md)
*   **Status:** Scheduled tech debt.
*   **Target Implementation Sprint:** **Sprint 14**.

---

## 🛡️ Guidelines for Deprecating Code

1.  **Mark Clearly:** Always annotate the deprecated method in code using `@Deprecated('Use [newMethod] instead')`.
2.  **Add to Tracker:** Register the target method or field in this document immediately.
3.  **Hold Deletion:** Under no circumstances should deprecated features be deleted in the active sprint to prevent breaking parallel branches or stale clients.
