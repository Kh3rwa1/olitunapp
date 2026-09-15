# mutateReviewState — Trusted Review State Mutation Function

Serverless Appwrite Function for cloud-backed spaced repetition review state (`review_states` collection in `olitun_db`).

## Security & Architectural Requirements

1. **Elimination of Direct Table Writes**:
   - Table-level `create("users")`, `update("users")`, and `delete("users")` permissions are completely removed (`permissions: []`).
   - Row-level security (`rowSecurity: true`) is enabled on `review_states`.
   - All mutations route through this trusted Function using server-side administrative credentials.
   - Prevents deterministic row-ID squatting and denial-of-service attacks.

2. **Caller Identity Verification**:
   - The authenticated user ID is derived strictly from `req.headers['x-appwrite-user-id']`.
   - `userId` in the client request body is never trusted. If supplied, it must strictly match the authenticated user ID, or the request is rejected with `403 FORBIDDEN`.
   - Unauthenticated or malformed requests are rejected with `401 UNAUTHENTICATED`.

3. **Row Identity Algorithms**:
   - **Legacy Row ID Algorithm**:
     ```javascript
     function legacyRowIdFor(userId, itemId) {
       const clean = (raw) => String(raw || '').replaceAll(/[^a-zA-Z0-9._-]/g, '_').slice(0, 60);
       return `${clean(userId)}__${clean(itemId)}`;
     }
     ```
   - **Hashed Row ID Algorithm** (SHA-256 with length-prefixed domain separation):
     ```javascript
     function rowIdFor(userId, itemId) {
       const input = `usr:${userId.length}:${userId}:item:${itemId.length}:${itemId}`;
       return `r_${createHash('sha256').update(input).digest('hex').slice(0, 31)}`;
     }
     ```

4. **Legacy Row Migration Protocol**:
   - On upsert, the function checks for an existing legacy row (`${clean(userId)}__${clean(itemId)}`).
   - If only the legacy row exists, the state is persisted to the new hashed row ID, and the legacy row is deleted only after successful new-row persistence.
   - If both rows exist, the whole-state winner is selected using `lastReviewedAt ?? introducedAt` (preferring the hashed row on equal timestamps), written to the hashed row, and the legacy row is deleted upon success.
   - If new-row writing fails, the legacy row is retained and never deleted.

## Actions

### `upsert`
```json
{
  "action": "upsert",
  "itemId": "word_123",
  "itemType": "word",
  "stateJson": "{\"itemId\":\"word_123\",...}",
  "nextReviewAt": "2026-01-04T09:00:00.000Z",
  "lastReviewedAt": "2026-01-01T09:00:00.000Z",
  "schemaVersion": 3
}
```

### `delete`
```json
{
  "action": "delete",
  "itemId": "word_123"
}
```

### `list`
```json
{
  "action": "list"
}
```

## Error Codes

| Status | Code | Meaning |
|---|---|---|
| 401 | `UNAUTHENTICATED` | Missing or invalid `x-appwrite-user-id` header |
| 403 | `FORBIDDEN` | Request body `userId` does not match session user |
| 400 | `INVALID_ARGUMENT` | Missing or malformed parameters (`itemId`, `itemType`, timestamps, etc.) |
| 413 | `PAYLOAD_TOO_LARGE` | `stateJson` exceeds 8,192 bytes |
| 500 | `SERVER_MISCONFIGURED` | Missing server environment variables |
| 500 | `SERVER_ERROR` | Internal error |
