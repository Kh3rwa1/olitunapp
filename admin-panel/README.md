# Legacy Hostinger / PHP Admin — Decommissioned

> **Status (May 2026):** the PHP admin panel is no longer part of the live
> Olitun runtime. Translation runs on the Appwrite Function in
> `functions/translator/`, all CRUD uses direct Appwrite SDK calls from the
> Flutter app, media uploads use Appwrite Storage buckets, and the old MySQL
> schema has been migrated to Appwrite Database.

## Current Admin Stack

| Capability | Current home |
|---|---|
| Admin UI | Flutter app under `/admin` |
| Admin auth | Appwrite Auth + Appwrite Team from `ADMIN_TEAM_ID` |
| Content CRUD | Appwrite TablesDB via `lib/core/api/appwrite_db_service.dart` |
| Media uploads | Appwrite Storage via `lib/core/storage/upload_service.dart` |
| Translation | Appwrite Function in `functions/translator/` |

## What Hostinger Used To Serve

| Removed/retired | Replacement |
|---|---|
| `api/upload.php` | Appwrite Storage buckets: `audio`, `images`, `animations`, `videos` |
| `api/v1/translate.php`, `api/v1/translate_from_olchiki.php` | `functions/translator/` |
| `api/v1/{banners,categories,lessons,letters,numbers,rhymes,rhyme_categories,rhyme_subcategories,sentences,settings,words}.php` | Direct Appwrite SDK calls from `lib/features/admin/**` |
| `api/setup/{seed,seed_lessons_full,setup_ai_tables,pre_translate,debug_schema}.php` | `scripts/appwrite_setup.mjs` + `scripts/appwrite_seed.mjs` |
| `api/core/{db,response,field_mapper}.php` | n/a (no consumers) |
| `delete-account.html` | Canonical copy lives at `web/delete-account.html` |
| `lib/core/api/api_service.dart` | Removed — class had no remaining call sites |

## Hostinger Decommissioning Checklist

1. ✅ Stop deploying `admin-panel/api/v1/*` and `admin-panel/api/setup/*`.
2. ✅ Drop the legacy MySQL tables under `u236276440_olitun`; data lives in
   Appwrite now.
3. ✅ Move Flutter admin uploads from `HostingerUploadService` /
   `UPLOAD_BASE_URL` to Appwrite Storage.
4. ☐ Re-upload or archive any existing files that only live under Hostinger
   `public_html/audio/`.
5. ☐ Remove `api/upload.php` and old media folders from Hostinger.
6. ☐ Cancel the Hostinger plan or release DNS records that point at it, keeping
   `olitun.in` pointed at the production static/Appwrite-backed app.
