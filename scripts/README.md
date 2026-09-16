# Olitun Scripts & Utilities

Developer scripts for database setup, data migration, and seeding.

## Quick Reference

| Script | Language | Purpose |
|--------|----------|---------|
| `appwrite_setup.mjs` | Node.js | Creates Appwrite database, collections, attributes, indexes, and storage buckets |
| `create_review_collection.mjs` | Node.js | Provisions and verifies Appwrite `review_states` table, columns, indexes, and row security |
| `check_review_corpus_ids.mjs` | Node.js | Validates bundled corpus items and review ID migrations (`assets/seed/review_item_id_migrations.json`) |
| `appwrite_seed.mjs` | Node.js | Imports seed data (categories, letters, numbers, rhyme categories) into Appwrite |
| `appwrite_import.mjs` | Node.js | Imports a MySQL JSON snapshot into Appwrite collections with field mapping |
| `post-merge.sh` | Bash | Post-merge setup hook |

> The import script works against an existing `scripts/exported_data.json`
> snapshot. Generate any fresh snapshot directly from a database backup before
> re-running it.

## Prerequisites

```bash
cd scripts
npm install   # installs node-appwrite SDK
```

## Usage

All Appwrite scripts read:

```bash
APPWRITE_ENDPOINT=https://sgp.cloud.appwrite.io/v1 # optional, defaults to Appwrite Singapore
APPWRITE_PROJECT_ID=<project-id>                  # optional if appwrite.config.json has projectId
APPWRITE_API_KEY=<server-api-key>                 # required
ADMIN_TEAM_ID=admins                              # optional, setup only
```

The setup script grants public read access to learning content, but create,
update, and delete permissions are restricted to `team:$ADMIN_TEAM_ID`. The
translator support collections (`translation_cache` and `rate_limits`) are
function-only: they are created with no public/client permissions and are
accessed by the Appwrite Function through its server API key.

### 1. First-time Appwrite Setup

Creates the entire database schema from scratch:

```bash
APPWRITE_API_KEY=your_server_api_key node scripts/appwrite_setup.mjs
```

### 2. Seed Demo Data

Populates collections with initial content (4 categories, 30 letters, 10 numbers, rhyme categories):

```bash
APPWRITE_API_KEY=your_server_api_key node scripts/appwrite_seed.mjs
```

### 3. Re-run the MySQL to Appwrite Import

Place the JSON snapshot at `scripts/exported_data.json` and:

```bash
APPWRITE_API_KEY=your_server_api_key node scripts/appwrite_import.mjs
```

Generate fresh data from a database backup before running this command.

### 4. Review States Table Provisioning and Verification

Provisions or verifies the `review_states` Appwrite table (with row-level security, 7 columns, and 2 indexes):

```bash
# Verify schema against remote without mutating
APPWRITE_API_KEY=your_server_api_key node scripts/create_review_collection.mjs --verify-only

# Apply schema idempotently to staging/development
APPWRITE_API_KEY=your_server_api_key node scripts/create_review_collection.mjs --apply

# Apply schema to production (requires explicit --confirm-prod)
APPWRITE_API_KEY=your_server_api_key node scripts/create_review_collection.mjs --apply --confirm-prod
```

### 5. Review Corpus ID Integrity Check

Validates bundled corpus files (`words.json`, `sentences.json`) and review item ID migrations (`assets/seed/review_item_id_migrations.json`):

```bash
node scripts/check_review_corpus_ids.mjs
node --test scripts/check_review_corpus_ids.test.mjs
```

### 6. Legacy Firebase Seed (Removed)

The pre-Appwrite Firebase seeding script (`seed_data.py`) was removed from
the repository — the project no longer uses Firebase. History remains
available in git if ever needed.

## Premium lesson permission cutover

`check_premium_content_permissions.mjs` is hard-bound to the production
Appwrite project and endpoint. It is dry-run only unless `--apply` is provided
with an exact project confirmation. Run the phases in order:

1. `node scripts/check_premium_content_permissions.mjs`
2. `node scripts/check_premium_content_permissions.mjs --phase=rows`
3. Re-run phase 2 with `--apply --confirm-project=<project-id>`.
4. After the authorization function and Flutter site are active from the same
   protected-main commit, run `--phase=boundary --expected-release-commit=<sha>`.
5. Apply the boundary only with both exact project and release confirmations.

The boundary phase uses the active `deploymentId` (never a newer inactive
preview), validates function variables and `appwrite.json`, verifies the
private entitlement table and `lessons.isPreview`, then writes a local rollback
record before enabling row security and removing broad table reads.

