# Resumable content restore — rollout and recovery

This is a maintenance operation, not an atomic whole-database swap. Do not deploy this change until the following staging checks pass. No live changes are made by this PR.

## Required deployment configuration

- Use a transaction-capable Appwrite server and the pinned Node SDK. Every content mutation, checkpoint, and active-operation fence must share a transaction. Unsupported transactions fail closed; do not add a non-transactional fallback.
- In `olitun_db` (or the configured database), provision a collection named `admin_restore_jobs`, or set `ADMIN_RESTORE_JOBS_COLLECTION_ID` to its ID. Enable document security and give it **no client collection permissions**. Add one required string attribute `payload`, size 8192, and wait for it to become available. The function creates private documents with empty permissions.
- The admin function needs database/document read/write and file read/write scopes. The repository's function configuration declares the additions; an operator must review/apply them as part of deployment. No public bucket or journal access is required.
- Keep `admin_backups` private/admin-only. Do not delete or mutate the source backup or deterministic safety file during recovery.
- Keep operation history and the `active` fence. Do not apply TTL deletion to them or recycle operation IDs: completed history prevents delayed requests from looking like new restores.

## Operator flow

1. Announce a maintenance window and pause content publishers, direct content edits, wipe/reseed, import jobs, and other writers. Restore requests fence one another; this is **not** a lock shared by every existing writer. Partial collections can be visible between batches, so stop learner traffic if a consistent catalog is required.
2. In Admin Settings → Danger Zone → **Restore / Resume**, enter the backup file ID and type `RESTORE`.
3. The app saves an operation ID before the first request. A request does bounded work and returns `202` with `complete: false` until the final checkpoint returns `200` with `complete: true`. Do not treat HTTP success alone as restore completion.
4. On a timeout, network error, process restart, or pause, reopen the same action and enter the same backup ID. Leave the recovery ID blank on the same device; its saved ID is reused. On another device, enter the displayed operation ID explicitly. A competing job's error also identifies the unfinished job and backup.
5. Verify final per-collection counts, IDs, representative documents, and permissions. Record the safety file ID before ending maintenance. Clear/refresh learner caches as appropriate.

The JSON request contract is `{ "action": "restore_content", "fileId": "...", "restoreId": "stable-operation-id" }`. The optional ID exists for older callers; its file-derived default can be used only for that operation. A deliberate later restore of the same backup requires a **new** operation ID. A completed retry is a no-op while it owns the active fence; after a later operation takes over it fails closed rather than restarting.

## Safety backup and difficult interruptions

The safety file ID is deterministic for the operation and is create-only. A lost upload acknowledgment reuses the completed file rather than taking a backup of partially restored content. If storage reports an incomplete multipart upload, the operation stays in preparation and **does not delete content**. Inspect/recover that upload during a quiescent maintenance window; do not automatically delete a safety file because another worker may have completed it. Do not remove a safety file after the journal enters deletion/restoration.

A corrupted journal, missing history, changed source digest, or mismatched checkpoint is an investigation condition, not a reason to reset the journal. Preserve all records and backups. After destructive work begins, prefer resuming the same job. Rolling back from the safety backup is a separate, explicitly planned recovery operation; do not bypass the unfinished-operation fence ad hoc.

## Mandatory staging acceptance

- Run the mocked interruption suite and installed-SDK request contract tests; then prove actual Appwrite transaction isolation with concurrent requests.
- Kill execution after a deletion commit, after an insertion commit, and after safety upload. Resume with the same ID and compare content and permissions.
- Pause an old deletion worker, complete recovery from another worker, then release the old one. Its conflicting transaction must not commit.
- Verify 403 for a non-admin; reject a competing job and modified source backup without additional content writes.
- Exercise app restart, explicit cross-device operation ID, pause, and a lost final response. Only acknowledged completion may clear the local pending ID.
- Test realistic maximum backup size, download/parse memory, upload size, transaction time limits, browser and Android journeys. The backup is revalidated on every request; do not infer large-backup performance from unit tests.
- Verify complete journal counts and sample all seven content collections before restoring traffic.
