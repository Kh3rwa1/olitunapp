# 🧹 Olitun Technical Debt & Deprecation Tracker

This document catalogs deprecated API methods, legacy variables, and deferred cleanups that are preserved temporarily for backward compatibility but scheduled for removal in future sprints.

---

## 🎯 Active Deprecations & Cleanup Tracker

We maintain strict deprecation boundaries: **never delete a legacy method or schema field in the same sprint in which it is deprecated**. Always mark them as `@deprecated` (or equivalent documentation comment) and list them below with their targeted removal sprints.

### 1. `updateThumbnail` (Controller Method)
*   **Location:** `lib/features/admin/presentation/bakhed/controllers/bakhed_editor_controller.dart`
*   **Rationale:** Replaced by `updateCoverMedia` as part of the Phase 2d unified cover picker layout. Video covers and image covers are now handled by a single `ContentMedia` object in the editor state.
*   **Status:** **Removed** in Sprint 4 (PR 1.3).

### 2. `updateCategoryId` (Controller Method)
*   **Location:** `lib/features/admin/presentation/bakhed/controllers/bakhed_editor_controller.dart`
*   **Rationale:** Replaced by direct object assignment or modern unified state hooks.
*   **Status:** **Removed** in Sprint 4 (PR 1.3).

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

### 5. Legacy Client-Side Seeders (`AlphabetSeeder`, `NumberSeeder`, etc.)
*   **Location:** `lib/shared/providers/seeders/`
*   **Rationale:** Client-side seeders run inside the app and triggered duplicate writes with non-canonical IDs (e.g. `letter_a`, `n0`) on the production database.
*   **Transition Path:** Completely deprecated in favor of server-side seeding (`appwrite_seed.mjs`). Gated locally with strict project ID guards to prevent execution on production.
*   **Status:** Deprecated in Sprint 2.
*   **Target Removal Sprint:** **Sprint 4**.

### 6. Architectural File Scale & Storage Debt
*   **Large Presentation Screens & Admin Panels:** Several presentation screens (e.g. `lib/features/admin/presentation/screens/admin_content_screen.dart`, `admin_rhymes_screen.dart`, `bakhed_editor_screen.dart`) exceed 500+ lines. Refactoring into decomposed modular sub-widgets is scheduled for **Sprint 5**.
*   **Centralized App Router:** `lib/core/routing/app_router.dart` encapsulates all application route definitions, guards, and shell navigation in a single file. Modularizing into feature-scoped sub-routers is scheduled for **Sprint 5**.
*   **Web Session Storage Exposure**: Web sessions store session credentials in browser `SharedPreferences` (localStorage). Exposure risk is mitigated by our 24-hour TTL fail-closed eviction policy (`_isWebSessionValidTimestamp`). Full Web Crypto API / HttpOnly cookie isolation for web sessions is tracked for **Sprint 6**.

---

### 8. ReorderableListView `onReorder` (deprecated; replacement `onReorderItem` lands in Flutter 3.44)
*   **Location:** `lib/features/admin/presentation/widgets/tracing_stroke_editor.dart` (completed-strokes `ReorderableListView`, one call site).
*   **Context:** Flutter deprecated `onReorder` after v3.41.0-1.0.pre (stable in 3.44) in favour of `onReorderItem`, which applies the `newIndex` correction internally so the manual `if (oldIndex < newIndex) newIndex -= 1;` adjustment goes away. The pinned Appwrite Sites build runtime (**flutter-3.35**) predates it, so migrating now would break that runtime.
*   **Why a suppression remains:** A single line-scoped `// ignore: deprecated_member_use` with an inline rationale comment. The current callback keeps the manual index adjustment and is behaviour-preserving.
*   **Transition Path (blocked on the flutter-3.35 runtime upgrade):** switch `onReorder: (oldIndex, newIndex)` to `onReorderItem: (oldIndex, newIndex)` **and delete the manual `newIndex -= 1` correction**, exactly per https://docs.flutter.dev/release/breaking-changes/deprecate-onreorder-callback (Case 1; not covered by `dart fix`).
*   **Status:** Active debt (blocked on the builder runtime upgrade).
*   **Target Cleanup Sprint:** Same sprint as the builder runtime unpin.

---


### 7. Riverpod `.stream` on `FutureProvider` (deprecated; removed in 3.0.0)
*   **Location:** `test/core/version/build_version_checker_test.dart` (3 call sites using `skip(1).first` awaits).
*   **Context:** The suite awaits the first *non-loading* `AsyncValue` by reading `buildVersionStatusProvider.stream`. Riverpod 3.0.0 removes `.stream` in favour of listening to the provider itself or using `.future`.
*   **Why a suppression remains:** A file-level `deprecated_member_use` ignore is kept, scoped to this one test file and annotated inline with its rationale. It is the only `deprecated_member_use` suppression left in the repository.
*   **Transition Path:** Replace the three `container.read(provider.stream).skip(1).first` awaits with `container.listen(provider, ...)` filtered on `hasValue`, or assert through `.future` where the initial loading state is not part of the contract.
*   **Status:** Active debt (blocked on the `flutter_riverpod` 3.x upgrade).
*   **Target Cleanup Sprint:** Same sprint as the `flutter_riverpod` 3.x migration.

---


## 🛡️ Guidelines for Deprecating Code

1.  **Mark Clearly:** Always annotate the deprecated method in code using `@Deprecated('Use [newMethod] instead')`.
2.  **Add to Tracker:** Register the target method or field in this document immediately.
3.  **Hold Deletion:** Under no circumstances should deprecated features be deleted in the active sprint to prevent breaking parallel branches or stale clients.
