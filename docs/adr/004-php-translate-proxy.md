# ADR-004: PHP Translation Proxy

**Status:** Superseded (May 2026) — replaced by the Appwrite Function in
`functions/translator/`. The PHP files described below
(`admin-panel/api/v1/translate.php`,
`admin-panel/api/v1/translate_from_olchiki.php`) were removed from the
repo as part of Task #4 ("Retire the legacy PHP admin panel"). See
`admin-panel/README.md` for the decommissioning checklist.
**Date:** 2025-03-01

## Context

The app needs to translate text between Santali (Ol Chiki) and other languages. Google Translate supports Santali (`sat` language code) via its free `gtx` endpoint, but calling it directly from a mobile app has problems:

1. **CORS** — browser blocks cross-origin requests to `translate.googleapis.com`
2. **Rate limiting** — Google throttles direct client IPs aggressively
3. **API key exposure** — official Translate API key would be visible in client code

## Decision

Deploy a **PHP proxy** on the existing Hostinger shared hosting at `olitun.in/admin-panel/api/v1/`:

- `translate.php` — translates any language → Santali (or any target)
- `translate_from_olchiki.php` — translates Santali → any language

The proxy:
1. Receives POST `{text, from, to}` from the Flutter app
2. Calls Google Translate's `gtx` endpoint server-side
3. Returns a clean JSON response `{success, data: {translation, detectedLanguage}}`

## Consequences

- ✅ No CORS issues — app talks to our own domain
- ✅ No API key needed — uses Google's free `gtx` client
- ✅ Can add server-side caching and rate limiting
- ✅ Single point to swap translation backends later
- ⚠️ Depends on Hostinger uptime
- ⚠️ Free `gtx` endpoint is undocumented — could change without notice
- 📌 **Future:** An Appwrite Function (Dart) is ready in `functions/translate/` for migration when needed
