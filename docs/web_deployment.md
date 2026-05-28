# Web Deployment & Service Worker Cache Hardening

This document outlines the deployment workflow, manual upgrade procedures, and caching safety guarantees for the Olitun Web Admin client.

---

## 1. Web Build & Deploy Flow

To ensure the client does not get stuck in stale caching loops (a common issue with Flutter Web PWA templates), all builds must go through our custom patching and verification pipeline.

### Local & Production Builds
Do **not** run raw `flutter build web` directly. Instead, use the build wrapper script:
```bash
./scripts/build_web.sh
```

This script:
1. Compiles the Flutter Web release bundle.
2. Runs the post-build patching script `scripts/patch_service_worker.mjs` to strip `flutter_bootstrap.js` out of the Service Worker's cache manifest.
3. Automatically runs the verification step `scripts/verify_service_worker_patch.mjs` to guarantee `flutter_bootstrap.js` is not present in the cached manifest.

If the verification step fails, the build process exits with a non-zero status code and prevents deployment.

---

## 2. Flutter SDK Upgrade Checklist

The post-build service worker patch relies on regex parsing of `flutter_service_worker.js` to locate the `RESOURCES` manifest map. When upgrading Flutter to a new SDK version:

1. **Build a fresh release** using `flutter build web --release`.
2. **Inspect the generated `build/web/flutter_service_worker.js`**:
   * Verify the `RESOURCES` map declaration is still regex-compatible with `scripts/patch_service_worker.mjs`.
   * Ensure that `flutter_bootstrap.js` is still present inside `RESOURCES`.
3. **Execute Node Tests**:
   * Run the test suite: `node scripts/patch_service_worker.test.mjs` (or run tests in your Node environment) to verify patch compatibility and idempotency.
4. **Run the Full Wrapper**:
   * Run `./scripts/build_web.sh` to confirm the patch compiles, applies correctly, and passes verification.

This guarantees that future Flutter SDK upgrades do not introduce silent failures or staled service worker manifests.

---

## 3. Known Platform Limitations: Appwrite Sites Edge Caching

During the Phase 2d audit, we discovered that:
* **No Custom Headers**: Appwrite Sites does not support custom edge header injections (e.g. `_headers` or `vercel.json`).
* **Caching Strategy**: The Appwrite CDN serves all static files with a default `cache-control: public, max-age=0, must-revalidate` header. 
* **Varnish CDN Caching**: Appwrite's Varnish CDN caches files aggressively and may serve cached hits (up to the edge TTL) to returning clients even after a new deployment is successfully pushed.

### Stale Client Defense Architecture

To close the circular edge caching window completely, we implemented a robust **Three-Layer Caching Defense System**:

| Layer | What it catches | Worst-case window | Failure mode |
|---|---|---|---|
| **Reference Guard (Server)** | All media orphan attempts | 0 ms (Immediate) | **Fail-Safe**: Refuses delete on query/reference match or database check failures |
| **SW Caching Exclusion (Client)** | Cached bootstrap script | Per-resource cache hit | **Fail-Safe**: Bypasses service worker cache, forcing network fetch |
| **SHA Mismatch Detector (Client UX)** | Stale code path in active browser tabs | 5 min (polling) + edge TTL | **Fail-Open**: Bypasses dialog warnings, allowing normal CMS operations |

---

## 4. Known Limitations & Follow-ups

1. **Appwrite Sites Edge Cache TTL**: The Varnish static cache TTL is platform-controlled (typically ~3 minutes). We cannot inject custom `no-store` or `max-age` headers for static files.
2. **Detection Latency Window**: The worst-case latency window for the stale banner warning to appear is `(Varnish Edge Propagation) + 5 minutes (periodic check polling interval)`.
3. **Reference Guard is the Ultimate Safety**: Within the 5-minute polling window, if a stale client attempts a deletion, the server-side DB Reference Guard (Layer 1) catches and aborts the request, preventing orphans.
4. **Legacy Form Callsites**: 6 standard content form callsites inside `content_form.dart` currently bypass deferred deletion state logic and still trigger immediate deletes. These have been explicitly marked with `// TODO(orphan-bug):` and are scheduled for refactoring during the next CMS standardization sprint.


