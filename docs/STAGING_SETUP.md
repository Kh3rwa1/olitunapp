# Staging Environment Setup & Configuration

This guide describes how to configure and maintain Olitun's staging infrastructure on Appwrite.

---

## 1. Required GitHub Secrets

Configure the following secrets in GitHub Repository Settings → Secrets and Variables → Actions:

| Secret Name | Purpose | Example Value |
|---|---|---|
| `STAGING_APPWRITE_ENDPOINT` | Staging Appwrite REST endpoint URL | `https://cloud.appwrite.io/v1` |
| `STAGING_APPWRITE_PROJECT_ID` | Staging project ID | `olitun-staging-project` |
| `APPWRITE_API_KEY` | Server API key for schema snapshots & migrations | `standard-server-api-key` |
| `RAZORPAY_KEY_ID` | Razorpay Sandbox key ID | `rzp_test_key` |
| `RAZORPAY_KEY_SECRET` | Razorpay Sandbox key secret | `rzp_test_secret` |
| `RAZORPAY_WEBHOOK_SECRET` | Razorpay Sandbox webhook HMAC secret | `wh_sec_test` |

---

## 2. Decoupled CI & Health Workflows

1. **`Flutter CI` (`.github/workflows/flutter-ci.yml`)**:
   - Executes code formatting, lint analysis, unit/widget tests with coverage, Node function tests, web release build, and Android APK build.
   - Runs unconditionally on code changes without depending on external staging server uptime.

2. **`Staging Health` (`.github/workflows/staging-health.yml`)**:
   - Runs on a 6-hour cron schedule and manually via `workflow_dispatch`.
   - Performs live connectivity tests and checks for Appwrite schema drift against `test/fixtures/schema/`.
