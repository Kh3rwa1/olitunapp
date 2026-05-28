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

### Mitigation Strategies in Play:
1. **SW Caching Exclusion (Layer 1)**: By excluding the bootstrap file from the Service Worker cache manifest, the browser always requests the bootstrap script over the network.
2. **Reference Guard (Layer 2)**: The server-side Appwrite DB Reference Guard intercepts any save operations, ensuring that even if a stale client attempts a media delete/swap, the actively referenced files are preserved.
3. **Build SHA Mismatch Detector (Layer 3)**: A client-side polling mechanism detects if the local build's SHA is older than the server's. It locks destructive admin actions and displays a reload prompt.
