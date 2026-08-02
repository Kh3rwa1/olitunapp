# Implementation Plan - Fix Tile Duplication & Responsive Grid Layout

Detailed plan to clean duplicate/legacy documents from the database, safeguard and update seeder scripts to be idempotent, and implement a responsive grid layout in `ContentGridScreen`.

## User Review Required

> [!IMPORTANT]
> - We will **NOT** perform any database deletions automatically. A cleanup script `scripts/cleanup_duplicate_letters_and_numbers.mjs` will be created with **dry-run mode by default**. 
> - Running the script without `--execute` will only log what it *would* delete. 
> - You (Dulor) will execute this script manually after checking the dry-run output.
> - The script will refuse to delete if the number of targeted deletions exceeds 50% of the collection size (safety check).
> - The script will require `--confirm-prod` flag when running against production.
> - **Production Seeding Guard:** A hard check will be placed in `seedAppContent` blocking client-side seeding entirely on the production project ID (`699495910038e39622c5`).
> - **Cleanup Tiebreaker Strategy:** In case of ambiguous duplicate matches under the same prefix (e.g. `l_a` vs `l_la` both representing `'ᱚ'`), the script will apply an **oldest-wins (`$createdAt`)** tiebreaker strategy to preserve the original document.

## Ground Truth Canonical IDs

Verbatim canonical IDs retrieved from `appwrite_seed.mjs` and verified against the live database:
*   **Letters:** `l_la`, `l_at`, `l_ag`, `l_ang`, `l_al`, `l_laa`, `l_ak`, `l_aj`, `l_am`, `l_aw`, `l_li`, `l_is`, `l_ih`, `l_iny`, `l_ir`, `l_lu`, `l_uc`, `l_ud`, `l_unn`, `l_uy`, `l_le`, `l_ep`, `l_edd`, `l_en`, `l_err`, `l_lo`, `l_ott`, `l_obb`, `l_ov`, `l_oh` (30 total)
*   **Numbers:** `n_0`, `n_1`, `n_2`, `n_3`, `n_4`, `n_5`, `n_6`, `n_7`, `n_8`, `n_9` (10 total)

---

## Proposed Changes

### Component 1: Responsive Grid (Track C)

We will implement this track first to ship immediate, risk-free layout value.

#### [MODIFY] [content_grid_screen.dart](file:///Users/dulorai/olitun/olitunapp/lib/features/learn/presentation/screens/content_grid_screen.dart)
* Modify the `crossAxisCount` calculation in `build` to support responsive boundaries:
  ```dart
  final width = MediaQuery.of(context).size.width;
  final int crossAxisCount = width >= 600 ? 4 : 3;
  ```

#### [MODIFY] [content_grid_screen_test.dart](file:///Users/dulorai/olitun/olitunapp/test/features/learn/content_grid_screen_test.dart)
* Update the responsive grid columns widget test at line 134 to assert:
  * 3 columns on phone (width 400).
  * 4 columns on tablet (width 800).

---

### Component 2: Idempotent Seeders (Track B)

We will safeguard client-side seeders, align their document IDs to canonical ones, and ensure idempotency.

#### [MODIFY] [seed_provider.dart](file:///Users/dulorai/olitun/olitunapp/lib/shared/providers/seed_provider.dart)
* Add a strict project ID guard at the top of `seedAppContent` to block execution on the production database (`699495910038e39622c5`):
  ```dart
  if (AppwriteConfig.projectId == '699495910038e39622c5') {
    AppLogger.debug('🚫 Client-side seeding is disabled on the production Appwrite project.');
    return;
  }
  ```

#### [MODIFY] [alphabet_seeder.dart](file:///Users/dulorai/olitun/olitunapp/lib/shared/providers/seeders/alphabet_seeder.dart)
* Update seeded letter IDs to exactly match canonical values:
  * `letter_a` -> `l_la`
  * `letter_at` -> `l_at`
  * `letter_ag` -> `l_ag`
  * `letter_ang` -> `l_ang`
  * `letter_al` -> `l_al`
* Add standard comment headers certifying idempotency.

#### [MODIFY] [numbers_provider.dart](file:///Users/dulorai/olitun/olitunapp/lib/shared/providers/numbers_provider.dart)
* Update `_seedNumbers` list to match canonical `n_` prefix IDs and names (e.g. `n0 -> n_0`, `Sunya -> Sun`).
* Ensure `seed()` behaves idempotently: perform `updateDocument` or check existence before calling `createDocument`.

#### [MODIFY] [appwrite_seed.mjs](file:///Users/dulorai/olitun/olitunapp/scripts/appwrite_seed.mjs)
* Ensure `createDoc` behaves idempotently: it already handles 409 conflict appropriately, but add standard comment headers certifying idempotency.

#### [NEW] [seeding.md](file:///Users/dulorai/olitun/olitunapp/docs/seeding.md)
* Document canonical seeding strategies, deprecating direct client-side overrides and instructing developer workflows.

---

### Component 3: Database Cleanup Script (Track A)

#### [NEW] [cleanup_duplicate_letters_and_numbers.mjs](file:///Users/dulorai/olitun/olitunapp/scripts/cleanup_duplicate_letters_and_numbers.mjs)
* Create a Node script that runs against Appwrite to clean up non-canonical records.
* **Safety features:**
  * Runs in dry-run mode by default.
  * Requires `--execute` to perform deletions.
  * Requires `--confirm-prod` if targeting the production project `699495910038e39622c5`.
  * Fails safe if deletions exceed 50% of the collection.
  * Writes a backup log (`cleanup_log_<timestamp>.json`) containing the complete document payload of all deleted documents.
  * **Tiebreaker Strategy:** If there are multiple `l_` prefixed or `n_` prefixed duplicates matching the same character/value (e.g. `l_la` and `l_a`), the oldest one by `$createdAt` wins, and others are staged for deletion.

## Verification Plan

### Automated Tests
* Run full suite:
  ```bash
  flutter test
  ```

### Manual Verification
* Run the cleanup script in dry-run mode and inspect its output list.
* Validate grid presentation after DB cleanup:
  * Alphabets: 30 unique items, 3 per row on phone, 4 per row on tablet.
  * Numbers: 10 unique items, 3 per row on phone, 4 per row on tablet.
