# santaliVoice — Santali AI Voice (Bodhan TTS) function

Turns learner text into Santali speech via [Bodhan indic-speak](https://console.bodhan.ai/api-docs/)
and returns a playable/downloadable audio URL. Powers the in-app
**Santali AI Voice** studio (`/voice`, promo card at the bottom of Home).

## Why a function (and not calling Bodhan from the app)

Bodhan bills per character. Calling it from the client would leak API keys
inside the app bundle. All keys live in the `bodhan_api_keys` collection;
this function rotates through them server-side.

## Key rotation (multi-key credit failover)

1. Admin pastes each Bodhan key as a document in `bodhan_api_keys`
   (`key`, `label`, `isActive: true`, `priority: 0` for the first key,
   `1` for the next, …). Lowest priority is tried first.
2. On each request the function tries keys in priority order:
   - **Success** → `successCount + 1`, audio returned. Repeat text reuses
     the `tts_cache` row and spends **zero** credits.
   - **401/403 (dead key)** → key auto-disabled (`isActive: false`),
     rotation continues with the next key.
   - **402 / quota / credit message (credit ended)** → key auto-disabled,
     rotation continues. Top the account up, then re-enable the row in
     the console (`isActive: true`).
   - **429 / 5xx / network (transient)** → key kept enabled, rotation
     continues.
   - **422 (bad request)** → returned immediately, other keys are NOT
     burned (the request itself is wrong).
3. All keys exhausted → `ALL_KEYS_EXHAUSTED` (503) with per-key reasons
   in the function logs.

## Collections

Database: `olitun_db`.

### `bodhan_api_keys` (admin-managed)

| Attribute      | Type     | Notes                                    |
| -------------- | -------- | ---------------------------------------- |
| `key`          | string(512), required | The `sk-…` Bodhan key            |
| `label`        | string(255) | e.g. `account-1`, for logs            |
| `isActive`     | boolean, default true | Auto-disabled on dead/exhausted |
| `priority`     | integer, default 0 | Lowest tried first                 |
| `successCount` | integer, default 0 |                                |
| `failCount`    | integer, default 0 |                                   |
| `lastUsedAt`   | datetime  |                                          |
| `lastError`    | string(1000) | Last failure reason (truncated)      |

Permissions: admins only (no `any`). The function uses an API key, so
collection permissions do not affect it — this only blocks console/API
reads from non-admins. **Live status: table `bodhan_api_keys` created
2026-09-16 with 4 keys (priorities 0–3).**

### `tts_cache` (function-managed)

| Attribute      | Type     | Notes                                    |
| -------------- | -------- | ---------------------------------------- |
| `cacheKey`     | string(64), required | SHA-256 of text+voice+lang+style |
| `text`         | string(2000) | Source text (truncated)              |
| `voice`        | string(64) |                                          |
| `lang`         | string(8) | e.g. `sat`                                |
| `style`        | string(64) | Empty = neutral                          |
| `audioUrl`     | string(2048) | Storage view URL                       |
| `storageFileId`| string(64) | File in the `audio` bucket              |
| `chars`        | integer  | Billable characters                       |
| `createdAt`    | datetime |                                          |

Add a **unique index on `cacheKey`**. Permissions: admins only — the
client never reads this table directly (the function returns the public
`audio`-bucket URL). **Live status: table `tts_cache` created 2026-09-16.**

Audio files are stored in the existing **`audio`** bucket (wav allowed).

## API

`POST` with a signed-in session (`execute: ["users"]` — voice spends real
credits, so guests must sign in; the app shows a login CTA on
`LOGIN_REQUIRED`).

Request:

```json
{ "text": "ᱟᱢᱟᱜ ᱧᱩᱛᱩᱢ ᱫᱚ ᱪᱮᱫ ᱠᱟᱱᱟ?", "voice": "Phulmani", "lang": "sat", "style": "" }
```

- `text`: 1–600 chars. Keep to a sentence or two (~30s audio, per Bodhan).
- `voice`: `Phulmani` (female) or `Sibu` (male) — the two native
  Santali voices. Anything else is rejected with `UNSUPPORTED_VOICE`,
  without spending credit or burning a key.
- `lang`: `sat` default; any Bodhan language code.
- `style`: empty (neutral) or one of the 14 Bodhan styles (`news`,
  `happy`, `children's stories`, …).

Success:

```json
{
  "success": true,
  "data": {
    "audioUrl": "https://…/storage/buckets/audio/files/…/view?project=…",
    "storageFileId": "…",
    "cached": false,
    "voice": "Phulmani",
    "lang": "sat",
    "style": "",
    "chars": 42
  }
}
```

Errors: `LOGIN_REQUIRED` (401), `INVALID_INPUT`/`INPUT_TOO_LONG`/
`UNSUPPORTED_VOICE`/`UNSUPPORTED_STYLE` (400), `UPSTREAM_REJECTED` (422),
`ALL_KEYS_EXHAUSTED` (503), `NO_KEYS_CONFIGURED` (500).

## Product boundary

Generated clips are **user creations** stored in `tts_cache` — they never
touch `audio_tracks`, so the human-recorded Santali lesson-audio policy
(`docs/MULTILINGUAL_FOUNDATION.md`, enforced in `generateAudio`) stays
intact.

## Deploy

```bash
appwrite deploy function --function-id santaliVoice
```

The function also needs an `APPWRITE_API_KEY` secret variable (a project
API key with `users.read`, `databases.read/write`, `documents.read/write`,
`files.read/write`). **Live status: key `santali-voice-key` created and
stored as secret variable `APPWRITE_API_KEY`; deployment
`6aaa9262a6baaf9c5384` is active and verified end-to-end 2026-09-16.**

> Gotcha: after adding/changing function variables, rebuild the
> deployment (duplicate it or redeploy) — fresh variables are not
> injected into an already-built deployment.

Mobile builds need the function id at compile time:

```bash
flutter run --dart-define=SANTALI_VOICE_FUNCTION_ID=santaliVoice
```

(Web already carries it via the Sites `buildCommand` in
`appwrite.json` / `appwrite.config.json`.)

## Tests

```bash
npm install
npm test   # node --test test/*.test.js
```

## Auth & quota state machine (hardened)

- **Identity**: verified JWT wins; a JWT bound to a different user than
  `x-appwrite-user-id` fails closed (401). Header-only requests are trusted
  because execute access is `["users"]` — Appwrite's gateway rejects
  unauthenticated direct-HTTP calls and injects a truthful header for
  session executions.
- **Quota states**: `claimed(submitting)` → `reserved` → `providerSubmitted`
  → `generated` → `uploaded` → `delivered(completed)`. Failures after reserve
  refund exactly once (`failed` + `quotaState: refunded`); failed claims are
  permanently non-replayable so one claim can never bill twice. There is no
  `failedCharged` state by design: uncertain provider outcomes refund the
  user and absorb provider cost. Partial multi-scope reservations are
  compensated. Stale `submitting` claims are reclaimed after 15 minutes.
- **Privacy**: input text is normalized (NFC, rune-counted) and its hash
  keys the cache; request rows and `tts_cache` entries (which retain up to
  2000 chars of source text) inherit the documented retention schedule
  (`tts_cache` 90d + file deletion, `voice_claims` 7d) and user-file cleanup
  via `user_assets` on account deletion. Never log full private text.
