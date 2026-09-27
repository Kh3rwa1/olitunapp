# Production Appwrite Environment Audit (Read-Only)

Date: 2026-09-28  
Target Endpoint: `https://sgp.cloud.appwrite.io/v1` (Singapore)  
Project ID: `699495910038e39622c5`  
Database: `olitun_db`  
Execution Mode: Read-Only (Zero writes, zero deployments, zero migrations)

---

## 1. CRITICAL Findings

1. **Payment Gateway Credentials Missing in Production Cloud**:
   - Neither `RAZORPAY_KEY_ID` nor `RAZORPAY_KEY_SECRET` is configured in Appwrite Cloud for ANY payment function (`createRazorpayOrder`, `verifyCoursePurchase`, `razorpayWebhook`, `reconcilePaymentAttempts`).
   - `RAZORPAY_WEBHOOK_SECRET` is also MISSING in `razorpayWebhook`.
   - In the local dev client `.env`, `RAZORPAY_KEY_ID` exists with prefix `rzp_test_...`, but in production Cloud, neither test nor live keys are present.
   - Any attempt to invoke `createRazorpayOrder` in production today immediately exits with HTTP 500: `Payment gateway misconfiguration`.
2. **`RATE_LIMIT_SALT` Missing on Key Functions**:
   - `RATE_LIMIT_SALT` is currently only configured on `bintiWaitlist`.
   - In `createRazorpayOrder`, `RATE_LIMIT_SALT` is completely MISSING, causing it to fall back to the insecure dev string `'olitun-dev-salt-do-not-use-in-production'`.
   - In `translator`, `RATE_LIMIT_SALT` is also MISSING.
   - Once unconditional `requireEnv('RATE_LIMIT_SALT')` is deployed, `createRazorpayOrder` will fail closed (HTTP 500) unless the variable is added in the Appwrite Console first.
3. **`app_settings` Security Exposure: LOW / NOT CRITICAL**:
   - The `app_settings` collection allows `read("users")` with `documentSecurity: false`.
   - Audit revealed exactly 1 document: `translation_engine` with fields `settingKey` and `settingValue` ("google", length 6).
   - Zero credential-like fields (tokens, secrets, keys, passwords, account IDs) exist in the collection. No secret leakage to users occurs.

---

## 2. Audit Tables

### Section A: Project-Wide Variables

| Metric | Status | Details |
|---|---|---|
| Project-Wide Variables Total | `0` | No global variables exist. Every function relies entirely on per-function variables or built-in open-runtimes variables. |

---

### Section B: Per-Function Variables

#### Target Functions Variable Status

| Function | Variable Name | Status | Type | Length | Level |
|---|---|---|---|---|---|
| **createRazorpayOrder** | `RATE_LIMIT_SALT` | **MISSING** | — | 0 | — |
| | `RAZORPAY_KEY_ID` | **MISSING** | — | 0 | — |
| | `RAZORPAY_KEY_SECRET` | **MISSING** | — | 0 | — |
| | `APPWRITE_API_KEY` | **SET** | Secret | Masked | Function |
| | `APPWRITE_FUNCTION_API_KEY` | *(Alias: uses `APPWRITE_API_KEY`)* | Secret | Masked | Function |
| | `PAYMENT_ORDERS_PER_HOUR` | **MISSING** *(Uses code default 10)* | — | 0 | — |
| **bintiWaitlist** | `RATE_LIMIT_SALT` | **SET** | Secret | Masked | Function |
| | `APPWRITE_API_KEY` | **SET** | Secret | Masked | Function |
| **translator** (`6a007db60024418c0997`) | `RATE_LIMIT_SALT` | **MISSING** | — | 0 | — |
| | `CLOUDFLARE_ACCOUNT_ID` | **SET** | Plaintext | 32 | Function |
| | `CLOUDFLARE_API_TOKEN` | **SET** | Plaintext | 53 | Function |
| | `GOOGLE_TRANSLATE_API_KEY` | **MISSING** | — | 0 | — |
| **delete-account** | `DELETION_HMAC_SECRET` | **SET** | Secret | Masked | Function |
| | `DELETION_OLD_HMAC_SECRETS` | **MISSING** | — | 0 | — |
| | `APPWRITE_DATABASE_ID` | **SET** | Plaintext | 9 | Function |
| | `APPWRITE_API_KEY` | **SET** | Secret | Masked | Function |
| **reconcileOrphanedDeletions** | `DELETION_HMAC_SECRET` | **SET** | Secret | Masked | Function |
| | `DELETION_OLD_HMAC_SECRETS` | **MISSING** | — | 0 | — |
| | `APPWRITE_DATABASE_ID` | **SET** | Plaintext | 9 | Function |
| | `APPWRITE_API_KEY` | **SET** | Secret | Masked | Function |
| **manageAdminAccess** | `ADMIN_TEAM_ID` | **MISSING** *(Uses code default `admins`)* | — | 0 | — |
| | `APPWRITE_ENDPOINT` | **SET** | Plaintext | 32 | Function |
| | `APPWRITE_PROJECT_ID` | **SET** | Plaintext | 20 | Function |
| | `APPWRITE_API_KEY` | **SET** | Secret | Masked | Function |
| **reviewContent** | *Function not deployed in Cloud* | **NOT DEPLOYED** | — | — | — |
| **admin-maintenance** | `ADMIN_TEAM_ID` | **MISSING** *(Uses code default `admins`)* | — | 0 | — |
| | `APPWRITE_API_KEY` | **SET** | Secret | Masked | Function |
| **razorpayWebhook** | `RAZORPAY_KEY_ID` | **MISSING** | — | 0 | — |
| | `RAZORPAY_KEY_SECRET` | **MISSING** | — | 0 | — |
| | `RAZORPAY_WEBHOOK_SECRET` | **MISSING** | — | 0 | — |
| | `APPWRITE_API_KEY` | **SET** | Secret | Masked | Function |
| **verifyCoursePurchase** | `RAZORPAY_KEY_ID` | **MISSING** | — | 0 | — |
| | `RAZORPAY_KEY_SECRET` | **MISSING** | — | 0 | — |
| | `RAZORPAY_WEBHOOK_SECRET` | **MISSING** | — | 0 | — |
| | `APPWRITE_API_KEY` | **SET** | Secret | Masked | Function |
| **reconcilePaymentAttempts** | `RAZORPAY_KEY_ID` | **MISSING** | — | 0 | — |
| | `RAZORPAY_KEY_SECRET` | **MISSING** | — | 0 | — |
| | `APPWRITE_API_KEY` | **SET** | Secret | Masked | Function |

---

### Section C: Secret Consistency (Zero Secret Values Disclosed)

| Variable | Functions Involved | Status | Notes |
|---|---|---|---|
| `DELETION_HMAC_SECRET` | `delete-account`, `reconcileOrphanedDeletions` | **SET (Masked)** | Configured as secret variables on both functions in Cloud. Values are masked by Appwrite Cloud REST API. Console check advised to confirm identical key. |
| `RATE_LIMIT_SALT` | `bintiWaitlist`, `createRazorpayOrder`, `translator` | **MISMATCH** | Configured only on `bintiWaitlist`. Completely missing from `createRazorpayOrder` and `translator`. |
| `RAZORPAY_KEY_SECRET` | `createRazorpayOrder`, `verifyCoursePurchase`, `razorpayWebhook`, `reconcilePaymentAttempts` | **MISSING** | Missing on all 4 payment functions in Cloud. |
| `RAZORPAY_KEY_ID` | All payment functions | **MISSING** | Missing on all payment functions in Cloud. In local client `.env`, prefix is `rzp_test_`. Neither test nor live key exists in production Appwrite. |

---

### Section D: Function Runtime Configuration

All 28 deployed functions run on Appwrite Cloud with active deployments. Common functions have 100% identical timeout and execute permissions to `appwrite.json`.

| Function Name | Cloud Function ID | Cloud Runtime | Timeout | Execute | Deployment ID | Repo JSON Status |
|---|---|---|---|---|---|---|
| translator | `6a007db60024418c0997` | node-22 | 30s | `any` | `6ab479608854f3cf6e9c` | Present (`node-22.0`) |
| delete-account | `delete-account` | node-22 | 30s | `users` | `6aa268fb6c10c9bb477e` | Present (`node-22.0`) |
| admin-maintenance | `admin-maintenance` | node-22 | 300s | `users` | `6aa269164657c6ea6691` | Present (`node-22.0`) |
| finalizeWeeklyCircles | `finalizeWeeklyCircles` | node-22 | 60s | *none* | `6aa268fc6b32c9590af1` | **Cloud Only** |
| assignUserToWeeklyCircle | `assignUserToWeeklyCircle` | node-22 | 30s | `users` | `6aa268fb814d9845f406` | **Cloud Only** |
| getCircleLeaderboard | `getCircleLeaderboard` | node-22 | 30s | `users` | `6a0f51cc5bb7f1d7c748` | **Cloud Only** |
| recordCircleEvent | `recordCircleEvent` | node-22 | 30s | `users` | `6aa268fa942c988b4d1b` | **Cloud Only** |
| recordMistake | `recordMistake` | node-22 | 30s | `users` | `6a972a063a0befd0edd9` | Present (`node-22.0`) |
| getUserMistakes | `getUserMistakes` | node-22 | 30s | `users` | `6a972a27c390f3db4aae` | Present (`node-22.0`) |
| markMistakeMastered | `markMistakeMastered` | node-22 | 30s | `users` | `6aa268fa96c68d89fff4` | Present (`node-22.0`) |
| completeMistakeReview | `completeMistakeReview` | node-22 | 30s | `users` | `6aa2690b24470a57671f` | Present (`node-22.0`) |
| recordBakhedProgress | `recordBakhedProgress` | node-22 | 30s | `users` | `6a972a116999785355c6` | Present (`node-22.0`) |
| getUserGamificationSummary | `getUserGamificationSummary` | node-22 | 30s | `users` | `6aa292fdc4954c572cd8` | Present (`node-22.0`) |
| updateStreakShield | `updateStreakShield` | node-22 | 30s | `users` | `6aa2690b0624ef4f0279` | **Cloud Only** |
| manageAdminAccess | `manageAdminAccess` | node-22 | 30s | `users` | `6aa269168e18d61a30b7` | Present (`node-22.0`) |
| aggregateLearningAnalytics | `aggregateLearningAnalytics` | node-22 | 60s | *none* | `6a98126bb424fe629b30` | Present (`node-22.0`) |
| bintiWaitlist | `bintiWaitlist` | node-22 | 30s | `any` | `6a97b0bcb35a93a7d1a3` | Present (`node-22.0`) |
| createRazorpayOrder | `createRazorpayOrder` | node-22 | 30s | `users` | `6a97b0c81c9bba0b313b` | Present (`node-22.0`) |
| verifyCoursePurchase | `verifyCoursePurchase` | node-22 | 30s | `users` | `6a9729c25fd8a689c352` | Present (`node-22.0`) |
| razorpayWebhook | `razorpayWebhook` | node-22 | 30s | `any` | `6a9729cd97dc5738bb71` | Present (`node-22.0`) |
| reconcilePaymentAttempts | `reconcilePaymentAttempts` | node-22 | 60s | *none* | `6a97b0e3d9f895c29fde` | Present (`node-22.0`) |
| cleanupAnalyticsEvents | `cleanupAnalyticsEvents` | node-22 | 120s | *none* | `6aa2690b493d55e120ee` | Present (`node-22.0`) |
| backupCollections | `backupCollections` | node-22 | 300s | *none* | `6aa2690b527aa5a19cf4` | Present (`node-22.0`) |
| reconcileOrphanedDeletions | `reconcileOrphanedDeletions` | node-22 | 120s | *none* | `6aa2690b4f1ef2169367` | Present (`node-22.0`) |
| mutateReviewState | `mutateReviewState` | node-22 | 30s | `users` | `6aaa2e37b5845307e25b` | Present (`node-22.0`) |
| getAuthorizedLesson | `getAuthorizedLesson` | node-22 | 30s | `any` | `6aaa2a5ed3593b8eab12` | Present (`node-22.0`) |
| santaliVoice | `santaliVoice` | node-22 | 60s | `users` | `6aaaa2d7545055b54430` | Present (`node-22.0`) |
| aiStudio | `aiStudio` | node-22 | 60s | `users` | `6aab7fccb93744086ae8` | Present (`node-22.0`) |
| generateAudio | `generateAudio` | — | 30s | `users` | *None* | **Repo JSON Only** |
| reviewContent | `reviewContent` | — | 30s | `users` | *None* | **Repo JSON Only** |

---

### Section E: Admin Team

| Team ID | Team Name | Total Members | Verified Code / Client Default |
|---|---|---|---|
| `admins` | `admins` | 1 | **MATCH**: Matches `AppwriteConfig.adminTeamId` ('admins'), build scripts, and server functions. |
| `69f872fd002558a03f0f` | `Olitun Admins` | 1 | Legacy / alternate admin team in console. |

---

### Section F: `app_settings` Exposure (SECURITY)

| Attribute | Setting / Value |
|---|---|
| Collection ID | `app_settings` (in `olitun_db`) |
| Collection Permissions | `read("users")`, `create("team:admins")`, `update("team:admins")`, `delete("team:admins")` |
| Document Security | `false` (Collection-level read permissions apply to all authenticated users) |
| Total Documents | `1` |
| Document 0 ID | `translation_engine` |
| Document 0 Fields | `settingKey`, `settingValue` |
| Credential Analysis | `settingKey`: `"translation_engine"`, `settingValue`: `"google"` (length 6). **Zero credential fields exist**. |
| Security Assessment | **LOW / SAFE**. No tokens, keys, secrets, or account IDs are exposed to users. |

---

### Section G: Stuck Checkouts

Database collection: `payment_attempts` in `olitun_db`  
Query filter: `status IN ('failed', 'in_progress') AND providerOrderId IS NULL`

| Status | Age < 1h | Age 1h – 24h | Age > 24h | Total Stuck |
|---|---|---|---|---|
| `failed` | 0 | 0 | 0 | **0** |
| `in_progress` | 0 | 0 | 0 | **0** |
| **Total** | **0** | **0** | **0** | **0** |

*Note*: `payment_attempts` collection currently has 0 total documents in production.

---

## 3. Action Items for Console (Owner Actions)

The following environment variables need to be set in the Appwrite Console (Project Settings or Function Settings):

1. **Add `RATE_LIMIT_SALT`**:
   - To `createRazorpayOrder` (must match the salt used in `bintiWaitlist`).
   - To `translator`.
2. **Add Razorpay Production Credentials**:
   - To `createRazorpayOrder`: `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`.
   - To `verifyCoursePurchase`: `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`.
   - To `razorpayWebhook`: `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET`.
   - To `reconcilePaymentAttempts`: `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`.
   *(Ensure production live keys `rzp_live_...` are used rather than `rzp_test_...`)*.
3. **Confirm `DELETION_HMAC_SECRET`**:
   - Verify in the Appwrite Console that `DELETION_HMAC_SECRET` in `delete-account` exactly matches the value in `reconcileOrphanedDeletions`.
4. **Deploy Missing Functions (When Ready)**:
   - `generateAudio` and `reviewContent` exist in the repo and in `appwrite.json`, but have not been deployed to Cloud yet.

---

## 4. Impact on Plan for PR #411 & `requireEnv` Step

1. **PR #411 Timing & Lease Constants**:
   - `createRazorpayOrder` has an execution timeout of **30 seconds** in Appwrite Cloud.
   - PR #411 defines `LEASE_DURATION_MS = 30000` (30s) and `STALE_RESERVATION_TIMEOUT_MS = 30000` (30s).
   - This aligns with the serverless timeout: any reservation left `in_progress` past 30s has exceeded the execution budget and can be recovered safely without concurrency collisions.
2. **`requireEnv` Step**:
   - Unconditional `requireEnv('RATE_LIMIT_SALT')` in `createRazorpayOrder` and `bintiWaitlist` will cause `createRazorpayOrder` to throw and return HTTP 500 in production until the owner adds `RATE_LIMIT_SALT` to `createRazorpayOrder` in Appwrite Console.
   - Therefore, the code changes for `requireEnv` should be merged only after the owner adds `RATE_LIMIT_SALT` in the console, or the PR can be prepared and reviewed while awaiting console confirmation.
