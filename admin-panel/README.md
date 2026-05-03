# Admin Panel — Deployment & Translator Function

> **Status (May 2026):** the legacy PHP translator at
> `admin-panel/api/v1/translate.php` has been **superseded** by the
> Appwrite Function in `functions/translator/`. Flutter no longer falls
> back to `olitun.in/api`. This document describes both the legacy
> Hostinger deployment (still serving file uploads + audio) and the new
> Appwrite Function deployment for translation.

---

## 1. Appwrite Function — Translator (NEW, primary path)

The Flutter app's `AiService` now reads `--dart-define=TRANSLATE_URL=…`
and posts to an Appwrite Function. Source lives at
`functions/translator/`.

### One-time Appwrite setup
1. Provision the database, collections, admin team, and storage buckets
   in one shot by running `node scripts/appwrite_setup.mjs` from the repo
   root (see the **Provisioning Appwrite** section in the top-level
   [README.md](../README.md)). The script creates:
   - `translation_cache` — attributes: `cacheKey` (string, unique index),
     `translation` (string), `detectedLanguage` (string), `targetLang`
     (string).
   - `rate_limits` — attributes: `clientIp` (string, indexed), `count`
     (integer), `windowStart` (integer).
   - the `admins` team (override via `ADMIN_TEAM_ID=<id>`).
2. Create a server **API key** with `databases.read` and
   `databases.write` scopes. Keep it server-side only — it will be set
   as the function's `APPWRITE_API_KEY` env var below.

### Deploy the function
```bash
appwrite functions create \
  --functionId translator \
  --name "Translator" \
  --runtime node-20 \
  --execute users

appwrite functions createDeployment \
  --functionId translator \
  --code functions/translator \
  --activate true
```

### Configure environment variables
In **Function Settings → Variables**:
- `APPWRITE_API_KEY` — the server API key created above
- `RATE_LIMIT_PER_HOUR` — optional, default `20`

The function deliberately ignores any `x-appwrite-key` request header —
only the server-side env var is trusted.

### Wire the Flutter app
Pass the function execution URL at build time:
```bash
flutter build web --release \
  --dart-define=APPWRITE_ENDPOINT=https://sgp.cloud.appwrite.io/v1 \
  --dart-define=APPWRITE_PROJECT_ID=<id> \
  --dart-define=ADMIN_TEAM_ID=<your_admin_team_id> \
  --dart-define=TRANSLATE_URL=https://<region>.appwrite.network/v1/functions/translator/executions \
  --dart-define=API_BASE_URL=<https-base-url> \
  --dart-define=UPLOAD_BASE_URL=<https-host-for-uploads>
```
The build will refuse to translate at runtime if `TRANSLATE_URL` is
missing — there is no `olitun.in` fallback.

---

## 2. Hostinger Folder Structure (legacy upload path)
```
public_html/
├── index.html          (Flutter web build)
├── main.dart.js
├── flutter.js
├── manifest.json
├── assets/
├── api/
│   └── upload.php      (Audio / media upload API — still in use)
│   └── v1/
│       └── translate.php  (DEPRECATED — replaced by Appwrite Function)
└── audio/
    ├── letters/        (Letter pronunciations)
    └── lessons/        (Lesson audio)
```

## 3. Deployment Steps (legacy)

### Build Flutter Web
```bash
flutter build web --release \
  --dart-define=APPWRITE_ENDPOINT=… \
  --dart-define=APPWRITE_PROJECT_ID=… \
  --dart-define=TRANSLATE_URL=… \
  --dart-define=UPLOAD_BASE_URL=https://your-host
```

### Upload to Hostinger
1. Login to Hostinger hPanel
2. Go to **File Manager** → **public_html**
3. Upload contents of `build/web/` to `public_html/`
4. Upload `api/upload.php` to `public_html/api/` (do NOT re-upload
   `translate.php` — it is being decommissioned)
5. Create `audio/letters/` and `audio/lessons/` folders

### Set Permissions
```
api/upload.php → 644
audio/ → 755 (writable)
```

## 4. Decommissioning notes

Once the Appwrite Function is deployed and the new build has been
running in production for one release cycle:

1. Delete `admin-panel/api/v1/translate.php` from the Hostinger host.
2. Remove the `translate_cache` MySQL table.
3. Track follow-up Task #4 ("Retire the legacy PHP admin panel").
