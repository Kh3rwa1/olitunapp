# AI Studio backend

Standalone Appwrite Function `aiStudio`, Node 22, pinned `node-appwrite` 25.1.0. It does not modify or call the existing translator. All Sarvam calls use native `fetch`; there is no Sarvam SDK dependency.

## Client contract

Execute with an authenticated Appwrite session and a freshly issued JWT. Forward that JWT as `x-appwrite-user-jwt` or `Authorization: Bearer …`. The backend validates it with `Account.get()` on a separate JWT-only client. `x-appwrite-user-id`, caller API-key headers, supplied user IDs and anonymous calls do not establish identity.

POST JSON actions:

| Action | Fields | Result `data` |
|---|---|---|
| `translate` | `text` (1–2000 Unicode code points), `language` (`hi-IN`, `bn-IN`, `as-IN`, `od-IN`) | `text`, `language: sat-IN`, `cached` |
| `transcribe` | `fileId`, `language` (same four plus `sat-IN`) | `text`, `language`, `durationSeconds` on first execution, `cached` |
| `ocrStart` | `fileId`, `language` (same five) | `jobId`, `status`, `language`, `text` if already complete |
| `ocrStatus` | `jobId` (local ID returned by `ocrStart`) | `jobId`, `status`, `language`, `text` when complete/partial |

Success: `{ "success": true, "data": { "text": "…" } }` (OCR pending results do not include text).
Failure: `{ "success": false, "message": "Safe user message", "error": "ERROR_CODE" }`.
HTTP codes: 400 validation; 401 authentication; 403 ownership; 404 private file/job missing; 409 non-replayable request; 429 quota; 502 provider failure; 503 unavailable/configuration/storage.

OCR states: `submitting`, `processing`, `completed`, `partially_completed`, `failed`, `rejected`. Partial completion is terminal and includes successful-page text. Stop polling terminal states. Poll no faster than every 12 seconds, use a bounded polling loop (for example five minutes), then offer an explicit resume-status action. Never retry an OCR start to recover status. A durable `submitting` record after a crash requires operator investigation, not automatic resubmission.

## Private inputs

Fixed bucket: `ai_studio_inputs`. Upload directly through the authenticated Appwrite Storage client with **only** `read("user:USER_ID")`, `delete("user:USER_ID")`, and optional `update("user:USER_ID")` file permissions. The server rejects public, shared, team and other-user permissions and downloads through the caller's JWT client, not its privileged service key. Ownership is represented by exclusive user permissions (Appwrite files do not expose a creator ID). Bucket permissions must be create-only for `users`, with file security enabled.

* OCR: PNG, JPEG, PDF, maximum 10 MiB. Type checked from bytes, not filename or MIME alone. ZIP is not accepted. Sarvam enforces its documented maximum 10 PDF pages; local byte size is not a page count. Reservation covers the full 10-page maximum before submission. Document parser validity and page counting are performed by the provider, so malformed files can consume a conservative reservation.
* Audio: PCM WAV only, signed 16-bit, mono/stereo, 8/16/22.05/24/44.1/48 kHz; maximum **30 seconds**, maximum 10 MiB. Server validates RIFF size, chunk bounds, one standard `fmt` and `data` chunk, codec, sample rate, block alignment, byte rate and frame-derived duration. MP3/M4A/WebM require a future trusted decode/normalization service; they are not accepted here.
* No URL, bucket, model, duration or page-count field is accepted from callers.
* Clients should delete uploads after successful processing or cancellation. Status/result retrieval does not need the original file. Never make inputs public to enable a provider download.

## Verified Sarvam REST contracts

Verified against current public docs on 2026-09-17:

* [Translate](https://docs.sarvam.ai/api-reference/text/translate-text): `POST https://api.sarvam.ai/translate`, JSON `input`, `source_language_code`, fixed `target_language_code: sat-IN`, `model: sarvam-translate:v1`, `mode: formal`; response `translated_text`. Santali and Assamese are documented for this model.
* [Transcribe](https://docs.sarvam.ai/api-reference/speech-to-text/transcribe): `POST /speech-to-text`, multipart `file`, `language_code`, `model: saaras:v3`, `mode: transcribe`; response `transcript`. This is speech recognition in the input language, not automatic translation.
* [Digitise](https://docs.sarvam.ai/api-reference/doc-ai/job/digitise): `POST /doc-ai/v1/job/digitise`, multipart `file`, `language`, `output_format: md`; response `job_id`. No guessed model parameter: use the provider's documented default Vision pipeline.
* [Status](https://docs.sarvam.ai/api-reference/doc-ai/job/status): `GET /doc-ai/v1/job/{job_id}/status`.
* [Results](https://docs.sarvam.ai/api-reference/doc-ai/job/results): terminal jobs use `GET /doc-ai/v1/job/{job_id}/results?format=json`, digitise `documents[].pages[].content`.
* [Guide](https://docs.sarvam.ai/api/api-guides-tutorials/document-intelligence/overview): `md`, not `markdown`; `language`, not `language_code`. Current Doc AI supersedes old Document Digitization endpoints. Maximum 10 PDF pages, 10 requests/minute.

Every call uses `api-subscription-key`, fixed HTTPS origin, rejected redirects, 45-second timeout and 2 MiB streamed-response cap. No provider error body is logged or returned. Extracted text is limited to 100,000 characters and strips HTML-looking tags/control characters. Markdown remains inert plain text: render **only editable/selectable text**, never HTML, Markdown widgets, webviews, links or scripts. Extraction is not an instruction to the app or another model. Human review is required before publication.

## Spend, atomicity and retries

`ai_studio_quotas` uses Appwrite 25's `incrementDocumentAttribute({value,max})` database-side bounded atomic increment, never a read/update counter. Each unique submission reserves the full configured amount in UTC calendar-month global, UTC calendar-day global, and user-day counters **before** the provider call. Counters initialize with an atomic unique document create. Partial reservations and failed calls are never refunded: failures over-account rather than overspend. If the API/database cannot enforce an increment, no provider request is made. This requires a compatible Appwrite server; there is no unsafe fallback for older servers.

Defaults (integer paise, ₹1 = 100 paise):

| Environment | Default |
|---|---:|
| `AI_STUDIO_MONTHLY_PAISE` | `7500000` (₹75,000 — deployed value) |
| `AI_STUDIO_DAILY_PAISE` | `250000` (₹2,500 — deployed value) |
| `AI_STUDIO_USER_DAILY_PAISE` | `30000` (₹300 — deployed value) |
| `AI_STUDIO_TRANSLATE_RESERVE_PAISE` | `400` (₹4/full 2,000-char request) |
| `AI_STUDIO_TRANSCRIBE_RESERVE_PAISE` | `200` (₹2/up to 30 seconds) |
| `AI_STUDIO_OCR_RESERVE_PAISE` | `5000` (₹50/up to 10 pages) |

These are conservative **reservation policies, not a claimed Sarvam tariff or invoice guarantee**. Confirm current contract pricing, taxes and maximum billed units before enabling. Increase reservations when rates rise. Use a dedicated provider key/workspace plus provider-side prepaid balance/spend caps; unrelated key use, taxes, provider billing changes and Appwrite infrastructure/storage are not controlled by these counters. All limits must be positive integers; invalid configuration fails closed.

Authenticated requests are also bounded at 20/user/minute and 120/global/minute. OCR reserves two API-call slots per start/status action in a global 10/minute counter, conservatively covering status plus results. Cached results do not consume paid quota. Counter failures fail closed. Appwrite platform rate limits and upload storage capacity/retention controls remain necessary against storage/execution abuse.

A server-secret HMAC of user, action, language and normalized text/file-content hash gives a unique durable request claim. Concurrent identical requests cannot create duplicate paid submissions. Completed text replays from private server-only cache; OCR replays the original local job ID. No automatic POST retry, provider fallback, claim expiry, claim deletion or paid replay after timeout. A claim in failed/submitting state can represent an uncertain paid operation; an operator must reconcile before any manual retry. HMAC secret rotation or deleting claims removes deduplication, so do neither casually. Store no raw input text or filename; store output only in server-only job records. The function emits no logs.

## Setup and deployment (operator steps; not run live in this change)

1. Review `/Users/dulorai/olitun/olitunapp/scripts/setup_ai_studio.mjs`. Preview safely:
   `node /Users/dulorai/olitun/olitunapp/scripts/setup_ai_studio.mjs --dry-run`.
2. Provision the **existing** intended database only after explicit environment review. Set `APPWRITE_ENDPOINT` (HTTPS), `APPWRITE_PROJECT_ID`, `APPWRITE_API_KEY`, `APPWRITE_DATABASE_ID`, then run the same script with `--apply`. It creates the fixed private bucket and server-only `ai_studio_jobs`/`ai_studio_quotas` collections, awaits attributes, rejects conflicting privacy/schema. No index is needed: all lookups use primary keys. It does not create/deploy/enable functions or change existing translator resources.
3. Register function ID `aiStudio`, runtime `node-22.0`, path `functions/aiStudio`, entrypoint `src/main.js`, build `npm ci --omit=dev`, execute permission `users`, no schedule/events, timeout at least 120 seconds, logging disabled. Include metadata-read scope `buckets.read`, plus `files.read`, `databases.read`, `databases.write`, `documents.read`, `documents.write`. Do not expose an unprotected anonymous custom-domain proxy. No client receives the service key or provider key.
4. Configure server environment: `APPWRITE_FUNCTION_API_ENDPOINT`, `APPWRITE_FUNCTION_PROJECT_ID`, `APPWRITE_FUNCTION_API_KEY` (or explicit `APPWRITE_ENDPOINT`/`APPWRITE_PROJECT_ID`/`APPWRITE_API_KEY`), `APPWRITE_DATABASE_ID`, secret `SARVAM_API_KEY`, and dedicated random `AI_STUDIO_HMAC_SECRET` (at least 32 characters). Generate a high-entropy secret offline. Keep `AI_STUDIO_ENABLED` unset until verified, then set exactly `true`. Set budget variables deliberately. There is no client override.
5. In a separately approved staging project, verify real authenticated execution, all five languages, Appwrite atomic increments under concurrency, private file ownership, partial OCR output, provider billing and failure cases. Mock tests do not prove provider entitlement, language accuracy, Appwrite deployment permissions or live API compatibility. Availability of Santali OCR/STT remains dependent on the account/model and source quality.
6. Retention: delete source uploads after processing; schedule operator-controlled cleanup of abandoned inputs and redact old result text. Retain claim tombstones to preserve idempotency. Retain current month/day/minute counters through their active period; only purge expired windows after a safety margin. No live cleanup or deletion is included. For account deletion, integrate cleanup of owner inputs and cached outputs in the existing account deletion workflow before production release (not modified here).

## Local validation

`node --test /Users/dulorai/olitun/olitunapp/functions/test/ai_studio.test.js`

Mocked tests cover validated auth, strict parameters, private ownership, real PCM duration, concurrent idempotency, atomic spending ceilings, fail-closed quota storage, no paid retries, cross-user OCR access, partial results, confirmed REST fields, safe errors and handler envelopes. A mocked default-handler smoke test and setup dry-run were also run. No live services were changed, deployed or called for paid processing.


## Deployment notes (Appwrite Cloud, verified 2026-09-17)

* Function variables are injected at deployment time: create/update variables **before** deploying, or redeploy after changing them.
* Variable **IDs are project-scoped** on Cloud: two functions cannot both use ID `APPWRITE_API_KEY` (santaliVoice already holds lowercase `appwrite-api-key`). Use a unique ID and keep the env **key** as `APPWRITE_API_KEY`; the key, not the ID, becomes the injected environment name.
* The privileged key (`APPWRITE_API_KEY`) must be set as a function variable; Cloud does not inject one automatically. Scope it to what the function needs.
* The CLI push rejects local `node-22.0` vs remote `node-22` runtime strings; deploy via `scripts/deploy_changed_functions.py` for new functions, or REST multipart `POST /functions/{id}/deployments` with `activate=true` for redeploys.
* Final live verification: `dart run tool/ai_studio_live_e2e.dart` (session → JWT → authenticated execution → asserts Ol Chiki U+1C50–U+1C7F output).
