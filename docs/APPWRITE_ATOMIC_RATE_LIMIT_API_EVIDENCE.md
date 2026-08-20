# Appwrite Atomic Rate Limiting API & Concurrency Evidence

**Audited Date:** August 20, 2026  
**Target Package:** `node-appwrite`  
**Installed Version:** `14.2.0` (Root & `functions/translator/node_modules/node-appwrite`)  
**Server Compatibility:** Appwrite 1.4.x, 1.5.x, 1.6.x+  

---

## 1. SDK API Audit & Method Signatures

Inspection of the installed TypeScript definitions (`node_modules/node-appwrite/dist/services/databases.d.ts`) reveals the exact supported methods on the `Databases` service:

```typescript
createDocument<Document extends Models.Document>(
    databaseId: string,
    collectionId: string,
    documentId: string,
    data: Omit<Document, keyof Models.Document>,
    permissions?: string[]
): Promise<Document>;

getDocument<Document extends Models.Document>(
    databaseId: string,
    collectionId: string,
    documentId: string,
    queries?: string[]
): Promise<Document>;

updateDocument<Document extends Models.Document>(
    databaseId: string,
    collectionId: string,
    documentId: string,
    data?: Partial<Omit<Document, keyof Models.Document>>,
    permissions?: string[]
): Promise<Document>;

deleteDocument(
    databaseId: string,
    collectionId: string,
    documentId: string
): Promise<{}>;

listDocuments<Document extends Models.Document>(
    databaseId: string,
    collectionId: string,
    queries?: string[]
): Promise<Models.DocumentList<Document>>;
```

### Key API Findings:
1. **No `incrementDocumentAttribute`:** Appwrite Databases REST API does not offer a native server-side atomic integer increment endpoint in current production releases.
2. **No Compare-and-Swap (CAS) Preconditions on `updateDocument`:** `updateDocument` accepts document attributes in `data`. Custom fields such as `_expectedRevision` or `_revision` are treated as arbitrary document attributes. Appwrite does not execute conditional `WHERE revision = expectedRevision` checks on updates.
3. **No Multi-Document Interactive Transactions:** The client SDK does not expose interactive transaction blocks (`BEGIN` / `COMMIT`).
4. **Atomic Primary Key Uniqueness on `createDocument`:** Appwrite's underlying storage engine (MariaDB) enforces strict unique primary key constraints on `documentId`. If two concurrent requests invoke `createDocument` with the identical `documentId`, exactly **one** call succeeds (`201 Created`), while all concurrent competitors receive **`409 Conflict` (AppwriteException: Document already exists)**.

---

## 2. Analysis of the Rejected Fake-CAS Strategy

### The Rejected Approach:
```javascript
// REJECTED: Fake CAS in updateDocument
const doc = await databases.getDocument(db, coll, windowId);
await databases.updateDocument(db, coll, windowId, {
    count: doc.count + 1,
    _expectedRevision: doc._revision, // Ignored by Appwrite engine!
    _revision: nextRevision
});
```

### Why it Fails in Production:
- In tests with a fake mock that manually implemented `if (data._expectedRevision !== currentDoc._revision) throw 409`, the test appeared to pass.
- In real Appwrite instances, `_expectedRevision` is persisted as a regular attribute. Concurrent requests read `count = 1` simultaneously and overwrite each other with `count = 2`, creating a race condition where 20+ concurrent requests pass a limit of 5.

---

## 3. Selected Production Strategy: Deterministic Slot Reservation

To achieve genuine atomicity without server-side CAS or schema extensions, we utilize **Deterministic Slot Reservation** backed by Appwrite's unique document ID primary key enforcement.

### Mechanism:
1. For each window (burst minute `m`, sustained hour `h`), the rate limiter defines a deterministic window prefix:
   - Minute Window: `m_${identifier}_${minuteTimestamp}`
   - Hour Window: `h_${identifier}_${hourTimestamp}`
2. Up to $L$ slots exist for a limit of $L$ (e.g. $L=5$ for burst, $L=30$ for hourly).
3. Each slot has a deterministic document ID: `${windowPrefix}_s${slotNumber}` (where `slotNumber` $\in [1, L]$).
4. When a request arrives:
   - It attempts to claim an available slot $s \in [1, L]$ by calling `createDocument(dbId, collId, slotDocId, { windowId, slot: s, expiresAt })`.
   - If `createDocument` succeeds (`201`), the slot is successfully claimed.
   - If `createDocument` returns `409 Conflict`, that specific slot has already been claimed by another concurrent request. The worker proceeds to attempt the next slot $s+1$.
   - If all slots $1 \dots L$ return `409 Conflict`, all allowed capacity for that window has been exhausted. The request is deterministically denied (`429 Too Many Requests`).
   - If any storage error other than `409` occurs (e.g. network timeout, 500), the limiter fails closed with HTTP 503 (`RATE_LIMIT_ERROR`).

### Dual-Window Atomicity:
- The rate limiter reserves a slot in the minute burst window first. If rejected, it immediately stops and returns `burst_limit_exceeded`.
- It then reserves a slot in the hourly sustained window. If the hourly limit is exceeded, it cleans up the reserved minute slot and returns `hourly_limit_exceeded`.

---

## 4. Verification & Concurrency Guarantees

| Metric | Guarantee | Evidence |
| :--- | :--- | :--- |
| **Max Concurrent Requests Allowed** | Exactly $\le L$ | MariaDB primary key uniqueness on `${windowPrefix}_s${slot}` prevents double-allocation. |
| **Fail-Closed on Outage** | 503 `RATE_LIMIT_ERROR` | Non-409 errors immediately abort and fail closed. |
| **Privacy Preservation** | Zero PII | Identifiers use domain-separated HMAC-SHA256 digests (`usr_` and `net_`). |
| **Retention Pruning** | Automatic | Documents include `expiresAt` timestamps; expired slot documents are batch-deleted. |
