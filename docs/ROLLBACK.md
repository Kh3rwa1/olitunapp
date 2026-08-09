# Deployment Rollback Procedures

This document provides step-by-step instructions for rolling back client builds and Appwrite backend configurations.

---

## 1. Web Release Rollback

1. In Vercel / Appwrite App Hosting console, revert the active deployment alias to the previous stable build SHA artifact stored in GitHub Releases artifacts.
2. The PWA service worker will fetch the updated `version.json` and clear client caches automatically on next load.

## 2. Appwrite Database & Permission Rollback

1. Locate the pre-migration snapshot in `test/fixtures/schema/`.
2. Run non-destructive restore using:
   ```bash
   node scripts/appwrite_setup.mjs --restore-snapshot test/fixtures/schema/
   ```
3. Re-verify collection permission state using:
   ```bash
   node --test functions/test/payment_functions.test.js
   ```
