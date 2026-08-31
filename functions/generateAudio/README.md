# generateAudio (Appwrite Function)

Server-side synthetic audio generation for **teaching-language** tracks using
Sarvam AI bulbul TTS. This is Phase 4 of the multilingual roadmap
(`docs/MULTILINGUAL_FOUNDATION.md`): the app can play audio for explanations,
translations, and other teaching-language tracks without any client-side
TTS, while Santali (target) audio remains exclusively human-recorded.

## What it does

For a single content item the function:

1. Validates the request (content kind, teaching language, track type).
2. Computes the `contentHash` idempotency key and looks for an existing
   `audio_tracks` row with the same composite key
   (`contentKind + contentId + segmentId + languageCode + trackType + contentHash`).
   If one exists, it is returned untouched — generation is idempotent.
3. Calls the Sarvam AI `text-to-speech` endpoint (bulbul:v4, automatic fallback
   to bulbul:v3 when the key's tier lacks v4) and retries on 429s.
4. Uploads the resulting WAV to the Appwrite `audio` storage bucket.
5. Persists an `audio_tracks` row with `provider: sarvam`, model/voice metadata,
   and the public playback URL.

## Guarantees (product policy)

- **Synthetic Santali is forbidden.** Requests with `languageCode: "sat"` or
  target track types (`targetNormal`, `targetSlow`, `targetSyllable`,
  `storyNarration`) are rejected with `400` before any provider call. Target
  audio is human-recorded via the admin CMS only.
- **Synthetic tracks are never auto-approved.** Rows are written with
  `reviewStatus: "needsReview"` and stay that way; approval happens in the
  admin review workflow (Phase 5). Learners only see approved tracks
  (`AudioTrack.isPlayable`).
- **Idempotent.** Re-generating identical content (same text + voice params)
  reuses the existing row and file — no duplicates, no wasted Sarvam calls.
- **Admin-only.** Only members of the `admins` team may invoke the function.
- **Secret-safe errors.** Upstream failure messages are persisted with any
  `api-subscription-key` material redacted.

## Endpoint

`POST` with JSON body:

```jsonc
{
  "contentKind": "word",        // word | sentence | letter | number | rhyme | story
  "contentId": "word_42",
  "segmentId": null,            // optional; story segments
  "languageCode": "hi",         // en | hi | bn | or  (never "sat")
  "trackType": "explanation",   // explanation | translation | instruction | storyTranslation | exampleSentence | feedback
  "text": "यह एक शब्द है",
  "speaker": "shubh",           // optional: shubh | aditi | priya | amartya
  "model": "bulbul:v4",         // optional; auto-fallback to bulbul:v3
  "pace": 0.9                   // optional; 0.5–2.0, 0.9 is ideal for learners
}
```

Successful response:

```json
{
  "success": true,
  "data": {
    "trackId": "...",
    "audioUrl": "https://.../storage/buckets/audio/files/.../view",
    "storageFileId": "...",
    "generationStatus": "completed",
    "reviewStatus": "needsReview",
    "model": "bulbul:v4",
    "cached": false
  }
}
```

Errors: `400` invalid input / forbidden language or track type, `403` not an
admin, `405` non-POST, `500` missing configuration, `502` Sarvam or upload
failure (the `audio_tracks` row is marked `generationStatus: "failed"` with a
redacted `errorMessage`).

## Setup

1. **Collections** — run `scripts/appwrite_setup.mjs` to ensure the
   `audio_tracks` collection (with the `idx_audio_track_idempotency` unique
   index) and the `audio` bucket exist.
2. **Function env vars** (Appwrite console → function settings):
   - `SARVAM_API_KEY` — Sarvam AI subscription key
   - `APPWRITE_FUNCTION_API_ENDPOINT`, `APPWRITE_FUNCTION_PROJECT_ID`,
     `APPWRITE_FUNCTION_API_KEY` — injected automatically by Appwrite
   - Optional: `ADMIN_TEAM_ID` (default `admins`), `AUDIO_BUCKET_ID`
     (default `audio`), `APPWRITE_DATABASE_ID` (default `olitun_db`)
3. **Deploy** — `appwrite deploy functions` (registered in `appwrite.json`
   and `appwrite.config.json` as `generateAudio`).

## Relationship to `scripts/generate_audio_sarvam.mjs`

The existing script remains the **batch backfill** tool (it rewrites seed JSON
locally and uploads via the CLI session). This function is the **on-demand,
server-side** generation path used by the admin CMS workflow: it writes
proper `audio_tracks` rows with review state and provider metadata instead of
patching seed files.

## Tests

```bash
cd functions/generateAudio && npm test
```

25 node tests cover request validation (including the Santali- forbidden
cases), prompt cleaning, content hashing, the Sarvam client (fallback +
retry + redaction), admin gating, and the full idempotent generation
pipeline against in-memory fakes.
