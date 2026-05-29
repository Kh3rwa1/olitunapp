# Phase 1 Audit: Subcategory Drilldown Fallback Regression

This document provides a comprehensive root cause audit of the subcategory drilldown regression on the `diagnose/subcategory-grid-fallback-regression` branch, including the Phase 1.5 product intent alignment.

---

## 1. Route Wiring Inspection

### Declarations in `lib/app/router/app_router.dart`
The following routes match the pattern `/letter/...` and `/number/...` in declaration order:

1. **`/letter/:lessonId/:letterId`** (line 305):
   ```dart
   GoRoute(
     path: '/letter/:lessonId/:letterId',
     redirect: (context, state) {
       final id = state.pathParameters['letterId'];
       return '/content/letter/$id';
     },
   ),
   ```
2. **`/number/:lessonId/:numberId`** (line 319):
   ```dart
   GoRoute(
     path: '/number/:lessonId/:numberId',
     redirect: (context, state) {
       final id = state.pathParameters['numberId'];
       return '/content/number/$id';
     },
   ),
   ```
3. **`/letter/standalone/:subcategoryId`** (line 350):
   ```dart
   _drillRoute(
     path: '/letter/standalone/:subcategoryId',
     child: (_, state) {
       final pathParam = state.pathParameters['subcategoryId'];
       final subcategoryId = pathParam == 'all' ? null : pathParam;
       return ContentGridScreen(
         kind: ContentKind.letter,
         subcategoryId: subcategoryId,
       );
     },
   ),
   ```
4. **`/number/standalone/:subcategoryId`** (line 361):
   ```dart
   _drillRoute(
     path: '/number/standalone/:subcategoryId',
     child: (_, state) {
       final pathParam = state.pathParameters['subcategoryId'];
       final subcategoryId = pathParam == 'all' ? null : pathParam;
       return ContentGridScreen(
         kind: ContentKind.number,
         subcategoryId: subcategoryId,
       );
     },
   ),
   ```

### Findings
- **Distinct Routes Added:** Yes, `/letter/standalone/:subcategoryId` and `/number/standalone/:subcategoryId` were indeed added as distinct routes.
- **Widget and Params:** Both routes correctly instantiate the `ContentGridScreen` widget, passing `ContentKind.letter` or `ContentKind.number` and extracting `subcategoryId` (mapping `'all'` to `null`).
- **Interception (GoRouter Declaration Order):** Yes, `/letter/:lessonId/:letterId` and `/number/:lessonId/:numberId` are declared **before** the standalone variants. 
  - GoRouter matches in declaration order (first match wins).
  - A path such as `/letter/standalone/lesson_alphabet_1` has 3 segments: `['letter', 'standalone', 'lesson_alphabet_1']`.
  - The pattern `/letter/:lessonId/:letterId` also has 3 segments: `['letter', ':lessonId', ':letterId']`.
  - Therefore, `/letter/standalone/lesson_alphabet_1` matches `/letter/:lessonId/:letterId` perfectly, binding `lessonId` to `'standalone'` and `letterId` to `'lesson_alphabet_1'`.
  - As a result, the standalone routes were **never** reached; they were always intercepted by the earlier catch-all routes.

---

## 2. Navigation Call Site Inspection

In `lib/features/lessons/presentation/category_lessons_screen.dart` from commit `8179318b`:

```dart
// Line 500 onTap callback for subcategory list items
if (isAlphabet) {
  context.push(
    '/letter/standalone/${lesson.id}',
  );
} else if (isNumber) {
  context.push(
    '/number/standalone/${lesson.id}',
  );
} else {
  context.push('/lesson/${lesson.id}');
}
```

- **Path Pushed:** `/letter/standalone/${lesson.id}` or `/number/standalone/${lesson.id}`
- **Substituted Value:** `lesson.id` (e.g., `'lesson_alphabet_1'` or `'lesson_numbers_0_9'`) is substituted for the path parameter.

---

## 3. Fallback UI Source

### Codebase Inspection
- **Literal String `"Offline fallback content for"`:** 
  Located in `lib/shared/repositories/content_repository.dart` at line 197:
  ```dart
  subtitle: 'Offline fallback content for $title',
  ```
- **Badge Texts `"offline"` and `"fallback"`:**
  Returned as a list of tags in `lib/shared/repositories/content_repository.dart` at line 201:
  ```dart
  tags: const ['offline', 'fallback'],
  ```
  And rendered as badges in `lib/shared/widgets/content_hero.dart` at lines 183–187:
  ```dart
  if (widget.item.tags.isNotEmpty) ...[
    const SizedBox(width: 8),
    ...widget.item.tags.take(3).map((tag) => _buildBadge(tag, context)),
  ]
  ```
- **Widget Rendering UI:** `ContentDetailScreen` (defined in `lib/features/content/presentation/content_detail_screen.dart`). It is **NOT** `ContentGridScreen`.
- **Trace Upward:**
  1. `GoRouter` redirects to `/content/letter/lesson_alphabet_1`.
  2. `/content/:kind/:id` builds `ContentDetailScreen(kind: ContentKind.letter, id: 'lesson_alphabet_1')`.
  3. `ContentDetailScreen` watches `contentDetailProvider((ContentKind.letter, 'lesson_alphabet_1'))`.
  4. `contentDetailProvider` invokes `ContentRepository.get(ContentKind.letter, 'lesson_alphabet_1')`.
  5. The Appwrite database lookup for ID `'lesson_alphabet_1'` in the `letters` collection fails (since it is a lesson ID, not a letter ID).
  6. On failure, `ContentRepository` falls back to `_getCachedItem`, which subsequently calls `_synthesizeFallbackItem` to generate a high-quality placeholder card to prevent application crashes.

---

## 4. `_synthesizeFallbackItem` Behavior

### Evaluation
Inside `lib/shared/repositories/content_repository.dart` (unchanged by commits `0d7cf400` or `2963c85a`):

When called with `(ContentKind.letter, "lesson_alphabet_1")`:
- **ID Prettification:** Yes, the function prettifies IDs:
  ```dart
  String title = id.replaceAll('_', ' ').replaceAll('-', ' ');
  title = title[0].toUpperCase() + title.substring(1);
  ```
  `'lesson_alphabet_1'` is converted to `"Lesson alphabet 1"`.
- **Return Value:** It returns a `ContentItem` containing:
  - `id`: `'lesson_alphabet_1'`
  - `kind`: `ContentKind.letter`
  - `categoryId`: `'cat_alphabets'`
  - `title`: `"Lesson alphabet 1"`
  - `subtitle`: `"Offline fallback content for Lesson alphabet 1"`
  - `tags`: `['offline', 'fallback']`
  - `blocks`: `[TextBlock(markdown: '# Lesson alphabet 1\n\nThis is a local offline fallback item...')]`
  - `tracing`: A synthesized clockwise bounding box tracing path (rendering the "tracing exercise card").

- **Behavior Modifications:** Neither `0d7cf400` nor `2963c85a` modified the repository file; they only refined matching sets in the screen layer. The repository's fallback synthesis has been stable and functioning as designed.

---

## 5. Data Model Check

### Appwrite Schema Analysis (`scripts/appwrite_setup.mjs`)
- **`letters` Collection Schema:**
  ```js
  {
    id: 'letters',
    name: 'Letters',
    attrs: [
      { type: 'string', key: 'charOlChiki', size: 20, required: true },
      { type: 'string', key: 'transliterationLatin', size: 50, required: true },
      { type: 'string', key: 'exampleWordOlChiki', size: 255, required: false },
      { type: 'string', key: 'exampleWordLatin', size: 255, required: false },
      { type: 'string', key: 'imageUrl', size: 512, required: false },
      { type: 'string', key: 'audioUrl', size: 512, required: false },
      { type: 'string', key: 'animationUrl', size: 512, required: false },
      { type: 'integer', key: 'order', required: false, default: 0 },
      { type: 'boolean', key: 'isActive', required: false, default: true },
      { type: 'string', key: 'pronunciation', size: 100, required: false },
      { type: 'string', key: 'themeColor', size: 50, required: false },
      { type: 'string', key: 'hero_media', size: 1000000, required: false },
      { type: 'string', key: 'blocks', size: 1000000, required: false },
      { type: 'string', key: 'tracing', size: 1000000, required: false },
    ],
  }
  ```
- **`numbers` Collection Schema:**
  Identical pattern; lacks `categoryId` or `subcategoryId` field.
- **`ContentRepository.list` Attribute Mapping:**
  ```dart
  String? _categoryAttribute(ContentKind kind) {
    switch (kind) {
      case ContentKind.lesson:
      case ContentKind.rhyme:
        return 'categoryId';
      case ContentKind.word:
      case ContentKind.sentence:
        return 'category';
      case ContentKind.letter:
      case ContentKind.number:
        return null;
    }
  }
  ```

### Conclusion
1. **No Field Exists:** Letter and number documents in Appwrite **do not** have a `subcategoryId` or `categoryId` field.
2. **Global Listing by Design:** Because `_categoryAttribute` returns `null` for letters and numbers, any call to `ContentRepository.list(ContentKind.letter, categoryId: ...)` omits the category equality filter and queries all documents in the collection.
3. **No Empty States or Backfill Required:** A query will not return empty; it always returns the full set of letters (30 items) or numbers (10 items). No data backfill is required.
4. **Cache & Title Issues:** Passing a lesson ID (like `'lesson_alphabet_1'`) causes the local cache key to segment separate from the global `'all'` cache. Furthermore, it breaks the category title lookup header since lesson IDs do not match category IDs.

---

## 6. Verdict Table

| Scenario | Status | File:Line Evidence | Rationale |
| :--- | :--- | :--- | :--- |
| **A: Missing Route** | **Ruled Out** | `lib/app/router/app_router.dart:350` | The `/letter/standalone/:subcategoryId` route was declared and present. |
| **B: Wired to Wrong Widget** | **Ruled Out** | `lib/app/router/app_router.dart:354` | The builder correctly wired the route to `ContentGridScreen`. |
| **C: Grid Reaches Fallback** | **Ruled Out** | `lib/app/router/app_router.dart:305` | The route never reached `ContentGridScreen`; it was intercepted earlier. |
| **D: Competing Route Interception** | **Confirmed** | `lib/app/router/app_router.dart:305` | `/letter/:lessonId/:letterId` matches the 3-segment pattern of `/letter/standalone/:subcategoryId` and is declared first, intercepting the request. |
| **E: Target Lookup Failure** | **Ruled Out** (in part) / **Confirmed** (in part) | `lib/shared/repositories/content_repository.dart:338` | The route was **not** correctly wired/reached (ruled out due to D), but the resulting parameter extraction indeed treated a lesson ID as a letter ID, triggering the fallback synthesis (confirmed). |

---

## 7. Phase 1.5 — Product Intent Clarification & UX Alignment

### The Tension Identified
Because letters and numbers are stored globally and lack database relationships to lessons, rendering a content grid for any tapped lesson/subcategory results in a visual redundancy—every subcategory click displays the exact same grid of all 30 letters or 10 numbers.

### Product Resolution & Decision
An interactive review and alignment session confirmed the following product direction:
* **The Global List Behavior is Intentional (For Now):** For letters and numbers, displaying a unified, complete interactive overview grid is the preferred presentation strategy for modern tablet/phone learning layouts. 
* **Swipe Deck as Deeper Access Path:** The deep per-lesson block layout (with detailed cards, tracing, and writing practice) remains easily accessible through a dedicated **"Study Cards" carousel action button** in the grid's AppBar.
* **Granular Database Subcategorization Deferred:** Implementing real database relations (either lesson-to-letter joins or schema updates) is scheduled as post-MVP technical debt for a future Sprint.

---

## 8. Fix Path Recommendation

Based on the Phase 1.5 product decision, we recommend a **Pure Routing Fix** to restore Option A cleanly and safely:

1. **Route Ordering Resolution:**
   Swap the declaration order in `lib/app/router/app_router.dart` so that the standalone routes precede the catch-all routes:
   ```dart
   // Swap standalone routes above catch-alls
   _drillRoute(
     path: '/letter/standalone/:subcategoryId',
     ...
   ),
   _drillRoute(
     path: '/number/standalone/:subcategoryId',
     ...
   ),
   GoRoute(
     path: '/letter/:lessonId/:letterId',
     ...
   ),
   GoRoute(
     path: '/number/:lessonId/:numberId',
     ...
   ),
   ```
2. **Add Protection Comments:**
   Annotate the route declarations in `app_router.dart` with a critical comment warning future developers that ordering is functionally significant, preventing GoRouter catch-all regressions during future cleanup:
   ```dart
   // ORDER MATTERS: Standalone grid routes MUST precede the :lessonId/:letterId catch-all
   // wildcard patterns to avoid path pattern interception by GoRouter.
   ```
3. **Correct Navigation Parameters:**
   Modify the navigation callbacks in `lib/features/lessons/presentation/category_lessons_screen.dart` to push `/letter/standalone/all` and `/number/standalone/all` (instead of using `lesson.id`). This aligns perfectly with `ContentGridScreen`'s category title resolutions and cache key mappings, preventing cached key segment fragmentation.
