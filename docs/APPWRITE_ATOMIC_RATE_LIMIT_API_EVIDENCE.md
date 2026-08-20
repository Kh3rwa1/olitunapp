# Appwrite Atomic Rate Limiting API & Concurrency Evidence

**Audited Date:** August 20, 2026
**Target Package:** `node-appwrite`
**Installed Version:** `25.1.0` (Root `package.json` & `functions/translator/package.json`)
**Server Compatibility:** Appwrite 1.4.x, 1.5.x, 1.6.x+

---

## 1. SDK API Audit & Authoritative Version Alignment

Inspection of the installed TypeScript definitions (`functions/translator/node_modules/node-appwrite/dist/index.d.ts`) reveals the exact supported methods on the `Databases` service for `node-appwrite` v25.1.0:

```typescript
createDocument<T extends Models.Document>(
    databaseId: string,
    collectionId: string,
    documentId: string,
    data: Omit<T, keyof Models.Document>,
    permissions?: string[]
): Promise<T>;

getDocument<T extends Models.Document>(
    databaseId: string,
    collectionId: string,
    documentId: string,
    queries?: string[]
): Promise<T>;

updateDocument<T extends Models.Document>(
    databaseId: string,
    collectionId: string,
    documentId: string,
    data?: Partial<Omit<T, keyof Models.Document>>,
    permissions?: string[]
): Promise<T>;

deleteDocument(
    databaseId: string,
    collectionId: string,
    documentId: string
): Promise<{}>;

listDocuments<T extends Models.Document>(
    databaseId: string,
    collectionId: string,
    queries?: string[]
): Promise<Models.DocumentList<T>>;
```

### Key API Findings:
1. **No `incrementDocumentAttribute`:** Appwrite Databases REST API does not offer a native server-side atomic integer increment endpoint in current production releases.
2. **No Compare-and-Swap (CAS) Preconditions on `updateDocument`:** `updateDocument` accepts document attributes in `data`. Custom fields such as `_expectedRevision` or `_revision` are treated as arbitrary document attributes. Appwrite does not execute conditional `WHERE revision = expectedRevision` checks on updates.
3. **No Multi-Document Interactive Transactions:** The client SDK does not expose interactive transaction blocks (`BEGIN` / `COMMIT`).
4. **Atomic Primary Key Uniqueness on `createDocument`:** Appwrite's underlying storage engine enforces strict unique primary key constraints on `documentId`. If two concurrent requests invoke `createDocument` with the identical `documentId`, exactly **one** call succeeds (`201 Created`), while all concurrent competitors receive **`409 Conflict` (AppwriteException: `document_already_exists`)**.

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
1. For each window (burst minute `m`, sustained hour `h`), the rate limiter generates a deterministic document ID for slot $s \in [1, \text{limit}]$:
   - Window index = `Math.floor(now / windowMs)`
   - Slot Document ID = `prefix + '_' + sha256(prefix + ':' + identifier + ':' + windowIndex + ':' + slot).slice(0, 28)`
2. When a request arrives:
   - It attempts to claim slot $s=1$ by calling `createDocument(dbId, collectionId, slotDocId, { clientIp, count: s, windowStart })`.
   - If `createDocument` succeeds, the slot is claimed (`allowed: true`, `remaining: limit - s`).
   - If `createDocument` throws an Appwrite `409 Conflict` with `document_already_exists`, slot $s$ is occupied by a concurrent request. The worker advances to probe slot $s+1$.
   - If all slots $1 \dots \text{limit}$ are occupied, the request is denied (`allowed: false`, `reason: 'burst_limit_exceeded'` or `'hourly_limit_exceeded'`).
   - If any storage error other than a duplicate collision occurs (e.g. 500, network error, non-duplicate 409), the system fails closed immediately (`rate_limit_storage_error`).

### Hardening & Boundaries:
- **Maximum Configured Limit Ceiling:** Enforced at `MAX_ALLOWED_LIMIT = 500` to prevent unbounded sequential Appwrite roundtrips.
- **Dual-Window Partial Rollback:** If the minute burst window succeeds but the hourly sustained window is exhausted, the claimed minute slot document is deleted in a rollback operation.
- **Deterministic Cleanup:** Staging tests and maintenance tasks delete only exact slot IDs reserved by that run.

---

## 4. Root vs Translator Dependency Architecture

1. **Authoritative Deployment Package:** `functions/translator/package.json` and its lockfile `functions/translator/package-lock.json` define the exact Node.js runtime for the serverless translator.
2. **Aligned SDK Version:** Both root and translator declare and resolve exact `node-appwrite@25.1.0`.
3. **Automated Drift Enforcement:** `scripts/verify_node_dependency_alignment.mjs` runs in CI (`format-and-analyze` job) to prevent any major/minor version discrepancy between root and translator.
