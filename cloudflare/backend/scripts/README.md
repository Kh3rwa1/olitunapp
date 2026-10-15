# Backend scripts

## import_appwrite_user_data.mjs

One-shot copy of learners' per-user data from the Appwrite database
(`olitun_db`) into D1 (`olitun-db`). Run it once the Appwrite database read
quota has reset (until then every read returns 402
`limit_databases_reads_exceeded` and the script aborts with exit code 2).

```sh
cd cloudflare/backend
# 1. Look first: reads + maps, writes nothing, prints counts and 3 redacted samples per collection.
node scripts/import_appwrite_user_data.mjs ~/.appwrite/olitun_server_key \
  --deletion-secret-file ~/.appwrite/deletion_hmac_secret --dry-run
# 2. Import (resumable; re-run the same command after a failure).
node scripts/import_appwrite_user_data.mjs ~/.appwrite/olitun_server_key \
  --deletion-secret-file ~/.appwrite/deletion_hmac_secret --state ./.appwrite-import-state.json
```

- The key file holds an Appwrite server key with database read and
  `users.read` scopes. It is never printed.
- `--deletion-secret-file` holds the old delete-account `DELETION_HMAC_SECRET`
  (older secrets on further lines). Without it, the script refuses to run
  if Appwrite has open deletion requests it cannot attribute.
- Other options: `--collections a,b`, `--since <iso>`, `--batch <n>`,
  `--d1 <name>`, `--endpoint`, `--project`, `--local [--persist-to dir]`.
  `--help` prints the full header.

| Appwrite collection | D1 table(s) | id |
| --- | --- | --- |
| `review_states` | `review_states` | `r_` + sha256 (legacy `user__item` rows rewritten; newest kept) |
| `user_mistakes` | `user_mistakes` | stableId(`user:quiz:question`) |
| `mistake_review_sessions` | `mistake_review_sessions` | `sessionId` |
| `bakhed_listening_progress` | `bakhed_listening_progress` | stableId(`user:bakhed`) |
| `user_badges` | `user_badges` | stableId(`user:badge`) |
| `reward_events` | `reward_events` | `rewardEventId` |
| `learning_analytics_events` | `learning_analytics_events` + `_details` | stableId(`analytics:user:eventId`), last 90 days only |
| `binti_guru_waitlist` | `binti_waitlist` | Appwrite `$id` |
| `course_purchases` (status `verified`, with order + payment id, not fully refunded) | `course_purchases` (`completed`) (+ `purchase_refunds` for partial refunds) | stableId(`purch:user:category`) |

Conflict policy: data already in D1 wins. Append-only tables and purchases
use `ON CONFLICT DO NOTHING`; `review_states` and `user_mistakes` only take
the imported row when it is strictly newer; Bakhed progress and badges merge
monotonically (highest percent/progress, completion sticks). Users with any
D1 `deletion_requests` row, an Appwrite deletion request, or no (or a
blocked) Appwrite account are skipped.

Tests: `node --test scripts/import_appwrite_user_data.test.mjs` (needs
`npm ci`; the end-to-end test uses a mock Appwrite server and a temporary
local D1).
