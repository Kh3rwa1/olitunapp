# Phase 1 Audit Report: Grid Duplication Regression Analysis

Detailed read-only audit investigating the reported ~3x tile duplication regression on the Alphabets and Numbers grids following the recent merge of `fix/grid-duplication-and-responsive-layout`.

---

## Verdict Summary

*   **Current DB Document Counts:** 
    *   `letters` collection: **40 documents** (30 canonical `l_` keepers, 5 legacy `letter_` duplicates, 5 legacy timestamped `letter_X_` duplicates).
    *   `numbers` collection: **20 documents** (10 canonical `n_` keepers, 10 legacy `n[digit]` duplicates).
*   **Cleanup Script Execution Status:** **NO.** The cleanup script was **never executed** on the production database. The `scripts/backups/` directory contains no `cleanup_log_*.json` files (which are generated unconditionally on execute), and the database document counts are identical to their pre-cleanup state.
*   **Active Bleeding Status:** **STOPPED.** The production database has **not** received a single new document write since **May 13, 2026**. No seeder has executed against production post-merge. The production guard is 100% correct and active.
*   **Root Cause Statement:** 
    > The ~3x duplication regression is not caused by new writes to the database, but is the visual revealing of pre-existing legacy duplicates (waves seeded on May 12 and May 13) because the UI was successfully migrated in the recent PR to the unified `contentListProvider`, which correctly removed the temporary client-side deduplication logic that was previously masking this garbage database data.
*   **Stop-the-Bleed Recommendation:** 
    The bleeding is already completely stopped. The database contains only old residual garbage from early May. We recommend immediately executing the safe cleanup script `scripts/cleanup_duplicate_letters_and_numbers.mjs` with `--execute --confirm-prod` to perform the automatic spelling corrections and delete the legacy duplicates.

---

## Detailed Answers to Diagnostic Questions

### Q1: Cleanup Script Execution Status
*   **Audit Finding:** The cleanup script `cleanup_duplicate_letters_and_numbers.mjs` was **not executed** prior to building the APK.
*   **Evidence:**
    1.  No logs matching `cleanup_log_*.json` exist in the `scripts/backups/` directory or anywhere else in the workspace.
    2.  The live database count remains at **40 letters** and **20 numbers**, which exactly matches the pre-cleanup state.

---

### Q2: Current Database State (Read-Only Analysis)

We fetched and audited all documents from the live `letters` and `numbers` collections:

#### 1. Letters Collection (40 Documents Total)
*   **Prefix Breakdown:**
    *   `l_` (Canonical Keepers): **30 documents** (created 2026-03-12)
    *   `letter_` (Legacy Client Seeder wave 1): **5 documents** (created 2026-05-13)
    *   `letter_X_` (Legacy Timestamped wave 2): **5 documents** (created 2026-05-12)
*   **Duplication Group Details (Vowels):**
    *   **Char "ᱚ" (3 docs):**
        *   `l_la` (Created: 2026-03-12T04:55:57Z) | Label: `a (a)`
        *   `letter_0_1778594018254000` (Created: 2026-05-12T13:53:38Z) | Label: `a`
        *   `letter_a` (Created: 2026-05-13T04:26:08Z) | Label: `a`
    *   **Char "ᱛ" (3 docs):**
        *   `l_at` (Created: 2026-03-12T04:55:58Z) | Label: `At (t)`
        *   `letter_1_1778594018255000` (Created: 2026-05-12T13:53:38Z) | Label: `at`
        *   `letter_at` (Created: 2026-05-13T04:26:08Z) | Label: `at`
    *   **Char "ᱜ" (3 docs):**
        *   `l_ag` (Created: 2026-03-12T04:55:58Z) | Label: `Ag (g)`
        *   `letter_2_1778594018255000` (Created: 2026-05-12T13:53:38Z) | Label: `ag`
        *   `letter_ag` (Created: 2026-05-13T04:26:08Z) | Label: `ag`
    *   **Char "ᱝ" (3 docs):**
        *   `l_ang` (Created: 2026-03-12T04:55:58Z) | Label: `Ang (ng)`
        *   `letter_3_1778594018255000` (Created: 2026-05-12T13:53:38Z) | Label: `ang`
        *   `letter_ang` (Created: 2026-05-13T04:26:08Z) | Label: `ang`
    *   **Char "ᱞ" (3 docs):**
        *   `l_al` (Created: 2026-03-12T04:55:58Z) | Label: `Al (l)`
        *   `letter_4_1778594018255000` (Created: 2026-05-12T13:53:38Z) | Label: `al`
        *   `letter_al` (Created: 2026-05-13T04:26:08Z) | Label: `al`
    *   **Other 25 Consonants (1 doc each):** All have exactly **1** canonical keeper starting with `l_` (created 2026-03-12).

#### 2. Numbers Collection (20 Documents Total)
*   **Prefix Breakdown:**
    *   `n_` (Canonical Keepers): **10 documents** (created 2026-03-12)
    *   `n[digit]` (Legacy Client Seeder): **10 documents** (created 2026-05-12)
*   **Duplication Group Details (0-9):**
    *   Every number from 0 to 9 has exactly **2** documents (1 keeper starting with `n_`, 1 duplicate starting with `n` followed by digit).
    *   **Val "0":** `n_0` (2026-03-12) | Label: `Sun` vs. `n0` (2026-05-12) | Label: `Sunya`
    *   **Val "1":** `n_1` (2026-03-12) | Label: `Mit` vs. `n1` (2026-05-12) | Label: `Mit`
    *   **Val "4":** `n_4` (2026-03-12) | Label: `Pon` vs. `n4` (2026-05-12) | Label: `Pun`
    *   **Val "5":** `n_5` (2026-03-12) | Label: `More` vs. `n5` (2026-05-12) | Label: `Mone`
    *   **Val "8":** `n_8` (2026-03-12) | Label: `Irel` vs. `n8` (2026-05-12) | Label: `Iral`

---

### Q3: Build and Environment Identification
*   **Compiled Constants:** `lib/core/config/appwrite_config.dart` reads `APPWRITE_ENDPOINT` and `APPWRITE_PROJECT_ID` strictly via `--dart-define` with no local fallbacks.
*   **Build Target:** The APK build was target-configured to point directly to the production Appwrite project:
    *   `APPWRITE_PROJECT_ID=699495910038e39622c5` (Production Project ID)
*   **Production Guard Value:** The production guard in `seed_provider.dart` blocks on the exact matching string `'699495910038e39622c5'`.
*   **Active Branch:** The APK was compiled directly from the local feature branch `fix/grid-duplication-and-responsive-layout` which has not yet been merged into remote `origin/main` (but contains all our completed duplication fix commits).

---

### Q4: Did Seeders Run Post-Merge?
*   **Audit Finding:** **NO.** No seeders have run against production post-merge.
*   **Evidence:**
    1.  **Creation Timestamps:** The youngest legacy document in `letters` was created on **May 13, 2026**. The youngest duplicate in `numbers` was created on **May 12, 2026**. There is **no** document created on or after the merge date (May 29, 2026).
    2.  **Seeder Invocation:** `seedAppContent` is **only** triggered from user action in the Admin Panel settings, categories, and dashboard screens. It is never called automatically on app boot.
    3.  **Active Production Guard:** The production guard in `seed_provider.dart` is present and correctly early-returns:
        ```dart
        if (AppwriteConfig.projectId == '699495910038e39622c5') {
          AppLogger.debug('🚫 Client-side seeding is disabled on the production Appwrite project.');
          return;
        }
        ```
    4.  **Write Paths:** The only other `createDocument` calls are in the deprecated `letters_provider.dart` and `numbers_provider.dart` classes, which are no longer called in the main application flow (now fully migrated to the read-only `contentListProvider`).

---

### Q5: Label Format Forensics

Three distinct formats of display labels are present, corresponding to three distinct historical seeding waves:

*   **Format A (Capitalized Parenthetical):** `a (a)`, `At (t)`, `Ang (ng)`, `Al (l)`
    *   **Source Seeder:** Backend canonical seeder (`scripts/appwrite_seed.mjs`).
    *   **Generation:** Seeded on **March 12, 2026** during database initialization. Represents the official, rich, canonical keepers.
*   **Format B (Lowercase Plain):** `a`, `at`, `ang`, `al`
    *   **Source Seeder:** Old client-side local seeder (`AlphabetSeeder` in `lib/shared/providers/seeders/alphabet_seeder.dart` at line 25).
    *   **Generation:** Seeded on **May 12, 2026** (using timestamped IDs like `letter_0_...`) and on **May 13, 2026** (using plain IDs like `letter_a`). Represents legacy duplicates.
*   **Format C (Numbers Spelling Diffs):** `Sunya` / `Sun`, `Mone` / `More`, `Iral` / `Irel`
    *   **Source Seeder:** Old client-side seeder (`numbers_provider.dart`) seeded `Sunya` / `Mone` on **May 12, 2026** under the non-canonical IDs (`n0` to `n9`). The canonical backend seeder seeded `Sun` / `More` on **March 12, 2026** under the canonical IDs (`n_0` to `n_9`).

---

## Verdict & Final Recommendation

The duplicate tiles visible in the app are **residual garbage** from early May. The bleeding has completely stopped.

Because we successfully migrated the mobile app to `contentListProvider` in our feature branch, the app no longer executes client-side deduplication. As a result, the pre-existing duplicate documents (which were previously masked) are now shown on screen.

### Recommendation
Proceed with:
1.  **Merge** the PR `fix/grid-duplication-and-responsive-layout` to `main`.
2.  **Execute the safe cleanup script** on production to apply the spelling updates and delete the legacy stubs:
    ```bash
    node scripts/cleanup_duplicate_letters_and_numbers.mjs --execute --confirm-prod
    ```
