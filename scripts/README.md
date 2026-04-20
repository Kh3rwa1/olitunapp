# Olitun Scripts & Utilities

Developer scripts for database setup, data migration, and seeding.

## Quick Reference

| Script | Language | Purpose |
|--------|----------|---------|
| `appwrite_setup.mjs` | Node.js | Creates Appwrite database, collections, attributes, indexes, and storage buckets |
| `appwrite_seed.mjs` | Node.js | Imports seed data (categories, letters, numbers, rhyme categories) into Appwrite |
| `appwrite_import.mjs` | Node.js | Migrates MySQL data (exported as JSON) into Appwrite collections with field mapping |
| `export_data.php` | PHP | Exports all MySQL tables from Hostinger as a single JSON file |
| `seed_data.py` | Python | **Legacy** — Seeds data into Firebase/Firestore (pre-Appwrite migration) |
| `seed_via_api.sh` | Bash | Bulk seed via curl API calls |

## Prerequisites

```bash
cd scripts
npm install   # installs node-appwrite SDK
```

## Usage

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

### 3. Migrate from MySQL

Two-step process to move data from the old Hostinger MySQL database to Appwrite:

```bash
# Step 1: Export from MySQL (run on Hostinger or via curl)
curl "https://olitun.in/admin-panel/api/export_data.php?key=olitun_export_2025" > scripts/exported_data.json

# Step 2: Import into Appwrite
APPWRITE_API_KEY=your_server_api_key node scripts/appwrite_import.mjs
```

### 4. Legacy Firebase Seed (Deprecated)

```bash
# Only if you're still using Firebase (you're not)
pip install firebase-admin==7.1.0
python3 scripts/seed_data.py
```

## Environment Variables

| Variable | Required By | Description |
|----------|-------------|-------------|
| `APPWRITE_API_KEY` | All `.mjs` scripts | Server API key from Appwrite Console → API Keys |
| `EXPORT_API_KEY` | `export_data.php` | Auth key for the export endpoint |
| `DB_PASSWORD` | `export_data.php` | MySQL password on Hostinger |

## Notes

- All `.mjs` scripts use `fetch()` (Node.js 18+) — no external HTTP dependencies
- Scripts are idempotent — re-running skips existing documents (409 conflict → skip)
- The `exported_data.json` file is gitignored and should not be committed
