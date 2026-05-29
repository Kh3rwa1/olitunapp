# Walkthrough: Subcategory Drilldown Route Order Fix

This walkthrough documents the technical changes, testing strategy, and validation results for resolving the subcategory drilldown route interception regression on the `fix/subcategory-grid-route-order` branch.

---

## 🛠️ Changes Implemented

We resolved the regression with a precise, pure routing fix that preserves full end-to-end carousel study context while cleanly rendering the global dictionary grid for Alphabet and Number subcategories:

### 1. Route Order Swapping & Protection
* **File:** [app_router.dart](file:///Users/dulorai/olitun/olitunapp/lib/app/router/app_router.dart) (lines 304–370)
* **Change:** Swapped the standalone grid route declarations (`/letter/standalone/:subcategoryId` and `/number/standalone/:subcategoryId`) **above** their corresponding catch-all patterns (`/letter/:lessonId/:letterId` and `/number/:lessonId/:numberId`).
* **Addition:** Added a prominent protection comment block explicitly warning developers of GoRouter's declaration-order matching semantics to prevent future regression.

### 2. Navigation site onTap Restoration
* **File:** [category_lessons_screen.dart](file:///Users/dulorai/olitun/olitunapp/lib/features/lessons/presentation/category_lessons_screen.dart) (lines 490–528)
* **Change:** Restored the strict category matches for `isAlphabet` and `isNumber` inside the lesson card `onTap`.
* **Parameter Preservation:** Ensured that tapping an Alphabet/Number subcategory pushes `/letter/standalone/${lesson.id}` or `/number/standalone/${lesson.id}` to preserve the subcategory ID context end-to-end.

### 3. AppBar Study Cards Carousel Button Restoration
* **File:** [content_grid_screen.dart](file:///Users/dulorai/olitun/olitunapp/lib/features/learn/presentation/screens/content_grid_screen.dart) (lines 112–126)
* **Change:** Restored the `Study Cards` carousel action button to the `AppBar`. This button parses the preserved `lesson.id` parameter to route the user straight to `/lesson/${widget.subcategoryId}` (loading the correct per-lesson swipe deck details carousel).

### 4. Technical Debt Registration
* **File:** [tech_debt.md](file:///Users/dulorai/olitun/olitunapp/docs/tech_debt.md) (lines 27–34)
* **Change:** Documented the scheduled Sprint 14 ticket for adding proper subcategory relations, database data backfills, and repository filter queries for the flat collections.

---

## 🧪 Testing & Verification Results

### 1. Automated Widget & Router Tests
* **File:** [content_grid_screen_test.dart](file:///Users/dulorai/olitun/olitunapp/test/features/learn/content_grid_screen_test.dart)
* **Verifications Added:**
  1. `ContentGridScreen shows Study Cards action button and navigates`: Asserts the Carousel action icon appears on the AppBar and successfully routes to `/lesson/lesson_123` with correct parameters.
  2. `Route /letter/standalone/:subcategoryId successfully mounts ContentGridScreen (Scenario D protection)`: Simulates the two competing patterns in corrected order, asserting that pushing the standalone pattern successfully mounts `ContentGridScreen` instead of falling back to detail interception.
  3. `Route /letter/:lessonId/:letterId successfully bypasses standalone route and mounts detail screen`: Asserts standard letter detail routes correctly bypass the standalone route and load their target detail screen.
* **Result:** **All 609 tests passed cleanly!**
  ```bash
  flutter test
  # Output: All 609 tests passed!
  ```

---

## 📱 Manual Verification Plan

To verify correctness in local or staging environments, perform the following smoke checks:
1. **Grid Drilldown Verification:** Open the **Learn** tab, select the **Alphabet** category, and click **Lesson Alphabet 1**. Verify that `ContentGridScreen` mounts successfully showing all 30 letters.
2. **Carousel Study Cards Validation:** From the grid screen, tap the **Study Cards** (Carousel) icon in the AppBar. Verify that the app mounts `LessonBlockDetailScreen` showing the swipe cards **specifically** for Lesson Alphabet 1.
3. **No Catch-All Detail Intrusion:** Verify that tapping a letter *inside* the swipe deck still successfully loads the correct drawing/practice detail screen without routing conflicts.
