# Database Seeding Architecture & Standards

This document establishes the standards and strategies for database seeding in the Olitun project to prevent data corruption, duplicate records, and out-of-sync environments.

## 1. Canonical Seeding Strategy (Server-Side)

The single source of truth for learning content (letters, numbers, categories, quizzes, and rhyme categories) is the server-side seed script located in the repository:

*   **File:** [`scripts/appwrite_seed.mjs`](file:///Users/dulorai/olitun/olitunapp/scripts/appwrite_seed.mjs)
*   **Purpose:** Bootstrapping a fresh Appwrite database instance or backfilling missing production-grade learning items with stable, ground-truth canonical document IDs.
*   **Canonical Document ID Conventions:**
    *   **Letters:** Prefix `l_` followed by Latin transliteration (e.g. `l_la` for "ᱚ", `l_at` for "ᱛ").
    *   **Numbers:** Prefix `n_` followed by numeric digit value (e.g. `n_0` for "᱐", `n_9` for "᱙").
*   **Idempotency:** The server-side seeder is designed to be fully idempotent (safe to re-run multiple times). If a document already exists under the canonical ID, the creation behaves safely and skips duplicate insertion.

---

## 2. Legacy Client-Side Seeders (Deprecated)

Historically, during early phases of development, local client-side seeders were used to write sample entries to the database directly from the running Flutter app:

*   **Files:** Located in [`lib/shared/providers/seeders/`](file:///Users/dulorai/olitun/olitunapp/lib/shared/providers/seeders/) (`AlphabetSeeder`, `NumberSeeder`, etc.).
*   **Trigger:** Invoked from the Admin Settings "Danger Zone" (`Wipe & Re-seed` or `Populate sample content` triggers).
*   **Status:** **DEPRECATED**. 

### Safety Safeguards on Client-Side Seeding:
To prevent accidental data corruption or duplicating non-canonical records on production, two layers of defense are implemented:
1.  **Production Guard:** Client-side seeders will strictly throw or return a no-op when executed against the production Appwrite project ID (`699495910038e39622c5`).
2.  **Canonical ID Alignment:** The client-side seeders have been retrofitted to write *only* canonical ground-truth IDs (e.g., `l_la` instead of `letter_a`, `n_0` instead of `n0`). They are fully idempotent and safe to execute in staging/local development without generating duplicates.
