# ADR-001: Appwrite over Firebase

**Status:** Accepted
**Date:** 2025-02-15

## Context

The app needs a backend for authentication, database, and file storage. Firebase and Appwrite are the two leading BaaS platforms for Flutter. Firebase has a larger ecosystem but is vendor-locked to Google Cloud. Appwrite is open-source and self-hostable.

## Decision

Use **Appwrite Cloud** (Singapore region) as the primary backend.

**Reasons:**
- **Open source** — no vendor lock-in; can self-host if needed
- **Simpler pricing** — generous free tier, predictable costs
- **First-class Dart SDK** — native `appwrite` package with full API coverage
- **Document-based DB** — fits our content model (categories → lessons → blocks)
- **Built-in OAuth** — Google OAuth works out of the box
- **Regional deployment** — Singapore region gives low latency for South Asian users

## Consequences

- ✅ No Firebase dependency or Google Cloud billing complexity
- ✅ Database schema is managed via setup scripts (`scripts/appwrite_setup.mjs`)
- ✅ Can migrate to self-hosted Appwrite if costs increase
- ⚠️ Smaller community than Firebase — fewer third-party tutorials
- ⚠️ No built-in analytics (using separate solution)
