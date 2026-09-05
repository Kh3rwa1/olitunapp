# Staging Environment Setup & Configuration

This guide describes how to configure and maintain Olitun's staging infrastructure on Appwrite.

Live staging verification is currently **BLOCKED** (see §4). Nothing below
provisions anything by itself — a maintainer must perform §3 with real
credentials. Never invent or commit secret values.

---

## 1. Required GitHub Secrets

Configure the following secrets in GitHub Repository Settings → Secrets and Variables → Actions:

| Secret Name | Purpose | Example Value |
|---|---|---|
| `STAGING_APPWRITE_ENDPOINT` | Staging Appwrite REST endpoint URL | `https://cloud.appwrite.io/v1` |
| `STAGING_APPWRITE_PROJECT_ID` | Staging project ID | `olitun-staging-project` |
| `STAGING_APPWRITE_API_KEY` | Server API key for the staging project (databases/collections/teams/buckets write) | (server-generated, never committed) |
| `APPWRITE_API_KEY` | Server API key for schema snapshots & migrations | (server-generated, never committed) |
| `RAZORPAY_KEY_ID` | Razorpay Sandbox key ID | `rzp_test_key` |
| `RAZORPAY_KEY_SECRET` | Razorpay Sandbox key secret | (dashboard-generated, never committed) |
| `RAZORPAY_WEBHOOK_SECRET` | Razorpay Sandbox webhook HMAC secret | (dashboard-generated, never committed) |

---

## 2. Decoupled CI & Health Workflows

1. **`Flutter CI` (`.github/workflows/flutter-ci.yml`)**:
   - Executes code formatting, lint analysis, unit/widget tests with coverage, Node function tests, web release build, and Android APK build.
   - Runs unconditionally on code changes without depending on external staging server uptime.

2. **`Staging Health` (`.github/workflows/staging-health.yml`)**:
   - Runs on a 6-hour cron schedule and manually via `workflow_dispatch`.
   - Performs live connectivity tests and checks for Appwrite schema drift against `test/fixtures/schema/`.
   - Is also called by the manual release flow (`release-checklist.yml`) as required live staging verification.

---

## 3. Provisioning checklist (maintainer-run, in order)

1. Create a **separate non-production** Appwrite project (never reuse the
   production project ID from `appwrite.json` — the workflow refuses to run
   when they match).
2. Run `node scripts/appwrite_setup.mjs` against the staging project to
   create the database, collections, buckets, and admin team.
3. Create a staging server API key with databases/collections/teams/buckets
   write scopes; store it as `STAGING_APPWRITE_API_KEY`.
4. Create Razorpay **test-mode** credentials and a test webhook secret;
   store as `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`,
   `RAZORPAY_WEBHOOK_SECRET`. Never use live keys here.
5. Trigger `Staging Health` via `workflow_dispatch` and confirm every live
   step runs (guard reports `configured=true`).
6. Run the §8 paid checklist from the mission plan against staging:
   buyer grant, non-buyer denial, media-to-lesson binding, refund
   propagation, restore-after-reinstall, pending/failed/recovered states,
   account deletion — all with disposable staging users and test payments.

## 4. Current status (verified 2026-09-05)

Present: `STAGING_APPWRITE_ENDPOINT`, `STAGING_APPWRITE_PROJECT_ID`.
Missing: `STAGING_APPWRITE_API_KEY`, `APPWRITE_API_KEY`,
`RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET`.
Consequence: live verification is **BLOCKED**. The scheduled monitor
reports this explicitly (warning + BLOCKED summary) instead of failing as
a health regression; release and manual runs still fail closed until §3 is
complete. Do not weaken these gates to obtain a green result.

## 5. Rotation and teardown

- Rotate a staging key by creating its replacement first, updating the
  secret, re-running the health workflow, then revoking the old key.
- Tear down by deleting disposable staging users/data, revoking staging
  keys, and removing the secrets. Production credentials are never valid
  substitutes — re-provision instead.
