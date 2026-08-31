# reviewContent — Phase 5 Admin Review Workflow

Admin-gated Appwrite Function that gives the CMS a review queue over the two
review-gated collections so learner-facing content can be moderated:

- `audio_tracks` — Sarvam-generated teaching-language tracks (Phase 4) and
  human-recorded uploads
- `localized_contents` — translated meanings/explanations (Phase 2)

Learner queries only ever surface `approved` rows, and synthetic tracks are
written `needsReview` by `generateAudio`. Until an admin approves them they
remain invisible; this function is the approval path.

## Actions

| Action | Body | Result |
| --- | --- | --- |
| `list_audio` | `{reviewStatus?, languageCode?, contentKind?, generationStatus?, limit?, offset?}` | pending queue page for `audio_tracks` (defaults to `needsReview`) |
| `approve_audio` | `{ids: string[1..50]}` | sets `reviewStatus: 'approved'` + `reviewedBy/reviewedAt` |
| `reject_audio` | `{ids: string[1..50]}` | sets `reviewStatus: 'rejected'` + `reviewedBy/reviewedAt` |
| `list_localized` | `{reviewStatus?, languageCode?, contentKind?, limit?, offset?}` | pending queue page for `localized_contents` |
| `approve_localized` | `{ids: string[1..50]}` | approve + audit stamps |
| `reject_localized` | `{ids: string[1..50]}` | reject + audit stamps |

All requests are `POST` with JSON bodies. Success responses use
`{ success: true, data }`; failures `{ success: false, error, message }`
(mirrors `generateAudio` / `admin-maintenance` conventions).

## Guarantees

- **Admin-team gate** — execution requires membership of the `admins` team
  (env `ADMIN_TEAM_ID`, default `admins`), verified server-side via
  `users.listMemberships`. Fails closed. Learners never hold review rights.
- **Broken audio never becomes playable** — `approve_audio` only approves
  tracks that have an `audioUrl` and either completed generation or the
  `isHumanRecorded` flag. Ineligible ids are reported per-id as
  `TRACK_NOT_APPROVABLE` without blocking the rest of the batch.
- **Audit trail** — every decision stamps `reviewedBy` (the caller's user id)
  and `reviewedAt` on the document.
- **Bounded batches** — at most 50 ids per call; duplicates de-duplicated.
- **Unknown ids** — reported as `NOT_FOUND` per-id; never throw.

## Error codes

| Code | Status | Meaning |
| --- | --- | --- |
| `METHOD_NOT_ALLOWED` | 405 | non-POST request |
| `INVALID_INPUT` | 400 | bad body / filters / ids |
| `UNSUPPORTED_ACTION` | 400 | unknown action |
| `FORBIDDEN` | 403 | caller is not on the admins team |
| `SERVER_MISCONFIGURED` | 500 | missing Appwrite env vars |
| `REVIEW_ERROR` | 500 | unexpected failure |

## Environment

- `APPWRITE_FUNCTION_API_ENDPOINT`, `APPWRITE_FUNCTION_PROJECT_ID`,
  `APPWRITE_FUNCTION_API_KEY` — standard Appwrite function runtime vars
- `APPWRITE_DATABASE_ID` (default `olitun_db`)
- `ADMIN_TEAM_ID` (default `admins`)

## Deploy

```bash
appwrite deploy functions
```

## Test

```bash
npm test
```

## Relationship to other pieces

- `generateAudio` (Phase 4) writes `needsReview` rows — this function is the
  moderation path that flips them to `approved` so `isPlayable` becomes true
  for learners.
- The Flutter admin CMS review screen (`lib/features/admin/presentation/review/`)
  calls this function via `Functions.createExecution`.
