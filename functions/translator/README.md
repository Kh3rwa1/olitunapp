# Translator (Appwrite Function)

Replacement for the legacy `admin-panel/api/v1/translate.php` PHP proxy.
Wraps Google Translate with per-IP rate limiting and a key/value cache,
exactly like the PHP version, but runs on Appwrite Functions so the rest
of the platform (auth, secrets, deployment, observability) is unified.

## Endpoints

The function exposes one HTTP entrypoint that accepts JSON `POST` bodies:

```jsonc
// to Ol Chiki (default)
{ "text": "Hello", "from": "auto", "to": "sat" }

// from Ol Chiki
{ "text": "ᱚᱞ ᱪᱤᱠᱤ", "to": "en" }
```

Successful response:

```json
{
  "success": true,
  "data": {
    "translation": "ᱚᱞ ᱪᱤᱠᱤ",
    "detectedLanguage": "en",
    "cached": false
  }
}
```

`429` is returned when the per-IP rate limit (default: 20/hour) is exceeded.

## Setup

1. Create an Appwrite Database with collections:
   - `translation_cache` (attributes: `cacheKey` string, `translation` string,
     `detectedLanguage` string, `targetLang` string)
   - `rate_limits` (attributes: `clientIp` string, `count` integer,
     `windowStart` integer)
2. From the project root:
   ```bash
   cd functions/translator
   appwrite deploy function
   ```
3. Copy the function execution URL printed by the CLI and set it on the
   Flutter build:
   ```bash
   flutter build web \
     --dart-define=APPWRITE_ENDPOINT=https://<region>.cloud.appwrite.io/v1 \
     --dart-define=APPWRITE_PROJECT_ID=<id> \
     --dart-define=TRANSLATE_URL=<exec-url>
   ```

## Required environment variables (set in Appwrite Console)

- `APPWRITE_FUNCTION_PROJECT_ID` — provided automatically by Appwrite
- `APPWRITE_API_KEY` — server key with database read/write
- `RATE_LIMIT_PER_HOUR` — optional, defaults to `20`

## Why this replaces the PHP proxy

The PHP proxy ran on shared Hostinger hosting with its own MySQL DB and a
separate deployment story. Moving to an Appwrite Function:

- removes the Hostinger dependency,
- centralises secrets in Appwrite,
- applies Appwrite's auth and rate-limit layers on top of the function's
  own per-IP limiter,
- and is deployable from the same repo as the Flutter app.
