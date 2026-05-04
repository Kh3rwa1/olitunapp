# Olitun Scripts & Utilities

Developer scripts for database setup, data migration, and seeding.

## Quick Reference

| Script | Language | Purpose |
|--------|----------|---------|
| `appwrite_setup.mjs` | Node.js | Creates Appwrite database, collections, attributes, indexes, and storage buckets |
| `appwrite_seed.mjs` | Node.js | Imports seed data (categories, letters, numbers, rhyme categories) into Appwrite |
| `appwrite_import.mjs` | Node.js | Imports a MySQL JSON snapshot into Appwrite collections with field mapping |
| `seed_data.py` | Python | **Legacy** — Seeds data into Firebase/Firestore (pre-Appwrite migration) |
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

### 4. Legacy Firebase Seed (Deprecated)

```bash
# Only if you're still using Firebase (you're not)
pip install firebase-admin==7.1.0
python3 scripts/seed_data.py
```
