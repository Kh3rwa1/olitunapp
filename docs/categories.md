# 🏷️ Category Separation Architecture

This document defines the category modeling, decoupling strategy, and architectural boundaries between **Learn Home Tab** categories and **Bakhed (Rhymes/Stories)** categories in Olitun.

---

## ⚙️ Architectural Overview

Olitun operates two fundamentally distinct category systems designed for different UI surfaces and user behaviors:

| System | Learn Category System | Bakhed Category System |
|---|---|---|
| **UI Surface** | Learn Home Tab Grid Tiles | Bakhed Tab Filter Chips & Admin Hub |
| **Data Source** | `categories` Collection | Dynamic derivation from `RhymeModel.category` |
| **Format** | Document reference (`categoryId`) | Human-readable String field (`category`) |
| **Provider** | `categoryNotifierProvider` | `rhymeCategoriesProvider` |
| **Editing** | Hardcoded standard categories | Standalone text field (Autocomplete combo box) |

---

## 🔒 The Learn Category Collection (Learn Tab Only)

The `categories` collection in Appwrite is designed **exclusively** to serve the primary home tab grid tiles:
- **Valid Categories:** `Alphabets` (`cat_alphabets_*`), `Numbers` (`cat_numbers_*`), `Vocabulary` (`cat_vocab_*`), `Sentences` (`cat_sentences_*`), `Greetings` (`cat_phrases_*`).
- **Surface Constraint:** The mobile app fetches all documents from this collection to render the primary learning grid.
- **Rule:** **DO NOT** add Bakhed-specific subcategories or labels (such as `Sohrai` or `Baha`) to this collection. Doing so will immediately cause them to leak onto the Learn home tab as top-level learning grid tiles.

---

## 🌾 The Bakhed Category System (Rhymes & Stories)

Bakhed categories are decoupled from the Learn categories collection to support rapid content administration:
- **Field:** Category names live directly as a String value under the `category` attribute on rhyme documents in the `rhymes` collection (e.g., `category: "Sohrai"`).
- **Dynamic Derivation:** The filter chips in the Bakhed mobile tab are compiled dynamically on-the-fly by `rhymeCategoriesProvider`, which reads distinct category strings from all loaded rhymes.
- **Admin Editor:** The admin editor uses a premium autocomplete combo box (`BakhedCategoryField`) that reads distinct category strings from `rhymeCategoriesProvider` and allows admins to type a new category string inline (or choose an existing one) without needing to populate any auxiliary collections.

---

## ⚠️ Stale Category Leak Failure Mode (Historical Context)

During Phase 2a, a severe category leak bug occurred where the `Sohrai` category appeared on the Learn home tab:
1. **The Core Issue:** The Bakhed admin editor previously reused the Learn-collection `categoryNotifierProvider` for its category dropdown.
2. **The Cause:** To select `Sohrai` in the rhyme editor, administrators were forced to create a new `cat_sohrai` document in the shared `categories` collection.
3. **The Symptom:** Because the Learn home tab fetched all documents from `categories` without filtering, `Sohrai` leaked onto the home tab as a learning grid tile.
4. **The Fix:** We completely decoupled the systems:
   - Added the `category` string field to rhymes in Appwrite.
   - Refactored the admin editor to use a custom autocomplete `BakhedCategoryField` populated by `rhymeCategoriesProvider`.
   - Backfilled all existing rhymes with their category names (e.g., `category: "Sohrai"`).
   - Deleted the orphaned `cat_sohrai` and `test category` documents from the `categories` collection.
