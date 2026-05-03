# Legacy Hostinger / PHP Admin — Decommissioned

> **Status (May 2026):** the PHP admin panel has been retired as part of
> Task #4. Translation runs on the Appwrite Function in
> `functions/translator/`, all CRUD has moved to direct Appwrite SDK
> calls from the Flutter app, and the MySQL schema has been migrated to
> Appwrite Database / Storage.
>
> The only file that survives in this directory is
> `api/upload.php` — see "Remaining legacy dependency" below.

## What was removed

| Removed | Replacement |
|---|---|
| `api/v1/translate.php`, `api/v1/translate_from_olchiki.php` | `functions/translator/` (Appwrite Function) |
| `api/v1/{banners,categories,lessons,letters,numbers,rhymes,rhyme_categories,rhyme_subcategories,sentences,settings,words}.php` | Direct Appwrite SDK calls from `lib/features/admin/**` |
| `api/setup/{seed,seed_lessons_full,setup_ai_tables,pre_translate,debug_schema}.php` | `scripts/appwrite_setup.mjs` + `scripts/appwrite_seed.mjs` |
| `api/core/{db,response,field_mapper}.php` | n/a (no consumers) |
| `delete-account.html` | Canonical copy lives at `web/delete-account.html` (served by the Flutter web build) |
| `lib/core/api/api_service.dart` | Removed — class had no remaining call sites |

The MySQL database (`u236276440_olitun`) and the Hostinger
`public_html/admin-panel/` deployment can be torn down once the
remaining `upload.php` dependency below is migrated.

## Remaining legacy dependency

`api/upload.php` is still the destination of every admin media upload
in the Flutter app:

- Consumed by `lib/core/storage/upload_service.dart`
  (`HostingerUploadService` + `uploadServiceProvider`).
- Used by 7 admin screens under `lib/features/admin/presentation/`
  (banners, categories, letters, lesson content, media, settings, and
  the shared `widgets/admin_upload_field.dart`).
- Configured at build time via
  `--dart-define=UPLOAD_BASE_URL=https://<your-host>` — there is no
  hardcoded fallback, so a missing flag fails loudly at the first
  upload.

**Owner:** admin tooling maintainers (same group that owns
`lib/features/admin/`). Tracked as a follow-up: migrate
`HostingerUploadService` to Appwrite Storage buckets, then delete
`admin-panel/` entirely and tear down the Hostinger account.

Until that migration ships, keep `api/upload.php` deployed at
`public_html/api/upload.php` on Hostinger with `audio/` (755,
writable) underneath it. Do **not** redeploy any of the files listed
in the "What was removed" table.

## DNS / Hostinger decommissioning checklist

1. ✅ Stop deploying `admin-panel/api/v1/*` and `admin-panel/api/setup/*`
   — they no longer exist in the repo.
2. ✅ Drop the legacy MySQL tables (`translate_cache`, plus all CRUD
   tables under `u236276440_olitun`) — data lives in Appwrite now.
3. ☐ Migrate `HostingerUploadService` → Appwrite Storage (follow-up).
4. ☐ Remove `api/upload.php` from Hostinger and delete the
   `audio/letters/` + `audio/lessons/` folders once existing media has
   been re-uploaded to Appwrite Storage.
5. ☐ Cancel the Hostinger plan / release the `olitun.in` DNS records
   that point at it (keep the apex pointing at the production Appwrite
   / static host).
