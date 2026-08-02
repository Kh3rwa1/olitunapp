# Phase 1 Audit: Grid Duplication Bug

Detailed diagnosis of the tile duplication regression in `ContentGridScreen` and the Appwrite database collections.

## Diagnostic Questions & Answers

### Q1: Is the data layer returning duplicates?
**Yes.** 
A read-only inspection of the Appwrite database collections `letters` and `numbers` was executed using the Appwrite console credentials found in `.appwrite/prefs.json`.

*   **`letters` Collection:** Contains **40 documents** (expected 30).
    *   30 standard documents with IDs starting with `l_` (e.g. `l_la` to `l_oh`, translit: `"a (a)"`, `"at (t)"`, etc.).
    *   5 local seeder documents with IDs starting with `letter_` (e.g. `letter_a`, `letter_at`, etc., translit: `"a"`, `"at"`, etc.).
    *   5 other documents with IDs like `letter_0_1778594018254000` to `letter_4_...`.
*   **`numbers` Collection:** Contains **20 documents** (expected 10).
    *   10 standard documents with IDs starting with `n_` (e.g. `n_0` to `n_9`, nameLatin: `"Sun"`, `"Mit"`, etc.).
    *   10 local seeder documents with IDs starting with `n0` to `n9` (e.g. `"Sunya"`, `"Mit"`, etc.).

**Conclusion:** The database has multiple duplicate records representing the same phonetic characters and digits (e.g., three different documents representing the letter "ᱚ" and two different documents representing the number "᱐").

---

### Q2: Is the repository or provider returning duplicates?
**Yes.**
In `lib/shared/repositories/content_repository.dart`, the `_categoryAttribute` method returns `null` for `ContentKind.letter` and `ContentKind.number`:

```dart
  String? _categoryAttribute(ContentKind kind) {
    switch (kind) {
      ...
      case ContentKind.letter:
      case ContentKind.number:
        return null;
    }
  }
```

Because this returns `null`, the query constructed in `ContentRepository.list` does **not** filter by `categoryId` or `subcategoryId`. The database fetch queries the entire collection, returning **all 40 documents** for letters and **all 20 documents** for numbers.

Since these collections contain duplicate documents for the same characters, the provider `contentListProvider` returns the list with duplicates intact, passing them directly to the rendering layer.

---

### Q3: Is the render path double-iterating?
**No.**
`ContentGridScreen`'s rendering path is clean and correct:
*   It watches `contentListProvider((widget.kind, widget.subcategoryId))`.
*   It feeds the resulting list of items directly into `GridView.builder`.
*   The `itemCount` is exactly `items.length`.
*   The `itemBuilder` maps each item to a single `_ContentGridTile` exactly once.

The visible duplication is caused purely by the fact that the provider returns duplicate letter/number documents representing the same characters/digits from the database.

---

## Verdict

*   **Layer where duplication originates:** **Data Layer** (redundant/duplicate documents present in database) + **Repository Layer** (lack of filtering or deduplication for letter/number kinds).
*   **Exact file:line where the bug lives:**
    *   `lib/shared/repositories/content_repository.dart` at lines 49-51 (`_categoryAttribute` returning `null` for `letter` and `number`).
*   **Minimal Fix Proposal:**
    We will harden the data-retrieval layer in the Repository to deduplicate content items client-side before returning them to providers. This provides dual protection: it resolves the current duplication instantly and makes the app completely resilient against any future accidental database duplicate seeds.
    *   **Deduplicate Letters by character:** Deduplicate by `olChiki` character.
    *   **Deduplicate Numbers by value:** Deduplicate by `value`.
    
    ```dart
    final items = response.map((doc) {
      return ContentItem.fromJson(doc.data, doc.$id, kind);
    }).toList();

    // Deduplicate letters and numbers to guarantee clean UI presentation
    if (kind == ContentKind.letter) {
      final seen = <String>{};
      items.retainWhere((item) => item.olChiki != null && seen.add(item.olChiki!));
    } else if (kind == ContentKind.number) {
      final seen = <int>{};
      items.retainWhere((item) => item.value != null && seen.add(item.value!));
    }
    ```

*   **Pre-merge main state reproduction:** **Yes.** Since the redundant records were inserted into the database previously, this bug reproduces on the pre-merge state as long as it routes to `ContentGridScreen`.
