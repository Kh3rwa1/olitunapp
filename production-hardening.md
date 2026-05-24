# Production Hardening & Caching Plan

## Goal
Enforce strict production TLS validation, automate asset compression, and enforce robust Hive schema versioning.

## Tasks
- [x] Task 1: Create `lib/core/network/secure_http_overrides.dart` and initialize it in `lib/main.dart` to enforce strict production TLS validation. → Verify: Running `flutter analyze` returns no warnings.
- [x] Task 2: Create a Python automation script `scripts/compress_assets.py` using Pillow and ffmpeg to optimize PNG and MP4 assets in-place. → Verify: Running the script reports successful compression stats.
- [x] Task 3: Execute the `scripts/compress_assets.py` script. → Verify: File size of `assets/videos/onboarding.mp4` is reduced significantly.
- [x] Task 4: Verify the Hive schema versioning configuration in `lib/core/storage/cache_service.dart`. → Verify: `CacheService.evictStale()` is verified to protect user data (which resides in `SharedPreferences`) while safely invalidating stale Hive boxes.
- [x] Task 5: Run final comprehensive static analysis and test suite. → Verify: `flutter test` executes all 111+ tests successfully with 0 failures.

## Done When
- [x] Production TLS validation override is active in the boot sequence.
- [x] Onboarding video and images are compressed and optimized in-place.
- [x] Complete codebase is fully validated with 0 compile errors and 0 test failures.

## Appwrite Production Environment Checklist

Before deploying the Appwrite backend services and building the Flutter clients for production release, verify the following configuration:

### 1. Database and Storage Security Rules
- [ ] **Restricted Content Access**: Core content collections (`categories`, `lessons`, `quizzes`, `letters`, `numbers`, `words`, `sentences`, `rhymes`, `banners`, `app_settings`, `bravo_messages`, `badges`, `mission_templates`, `reward_messages`, `quiz_feedback_messages`, `daily_affirmations`) must use `'read("users")'` read permissions. Generic public-read `'read("any")'` is disabled for content collections to protect platform intellectual property.
- [ ] **Anonymous Waitlist Signup**: The `binti_guru_waitlist` collection must retain `'create("any")'` permission so unauthenticated users can submit waitlist signup forms, but read/update/delete permissions are restricted to the `'team:admins'` role.
- [ ] **Functional Permissions**: Backend-managed transaction/support collections (`translation_cache`, `rate_limits`, `reward_events`, `course_purchases`) must have empty public/client permissions (accessible only via Appwrite Function server API keys).
- [ ] **Bucket Policies**: Storage buckets (`audio`, `images`, `animations`, `videos`) must use `'read("users")'` instead of public read to restrict assets to registered members. The `admin_backups` bucket is restricted exclusively to `'team:admins'`.

### 2. Appwrite Cloud Function Environment Variables
- [ ] **`verifyCoursePurchase` Function Env Vars**:
  - `APPWRITE_FUNCTION_API_ENDPOINT` / `APPWRITE_ENDPOINT` (Pointing to production Appwrite gateway)
  - `APPWRITE_FUNCTION_PROJECT_ID` / `APPWRITE_PROJECT_ID` (Production Project ID)
  - `APPWRITE_FUNCTION_API_KEY` / `APPWRITE_API_KEY` (Key with databases and documents read/write scopes)
  - `APPWRITE_DATABASE_ID` (Set to the production database identifier, e.g. `olitun_db`)
  - `ADMIN_TEAM_ID` (Set to the production admin team identifier)
  - `RAZORPAY_KEY_SECRET` (Production Razorpay API key secret; do not use sandbox credentials in production)
- [ ] **`admin-maintenance` Function Env Vars**:
  - `APPWRITE_DATABASE_ID` / `DATABASE_ID` (`olitun_db`)
  - `ADMIN_TEAM_ID` (Set to matching `ADMIN_TEAM_ID` of the administrators team)
  - `ADMIN_BACKUP_BUCKET_ID` (`admin_backups`)
- [ ] **`manageAdminAccess` Function Env Vars**:
  - `APPWRITE_DATABASE_ID`
  - `ADMIN_TEAM_ID`

### 3. Client Build Definitions
- [ ] Verify `--dart-define` inputs in release pipeline:
  - `APPWRITE_ENDPOINT=https://[YOUR_PRODUCTION_DOMAIN]/v1` (SSL active)
  - `APPWRITE_PROJECT_ID=[YOUR_PRODUCTION_PROJECT_ID]`
  - `ADMIN_TEAM_ID=[YOUR_IMMUTABLE_ADMIN_TEAM_ID]`
  - `TRANSLATE_URL=https://[YOUR_PRODUCTION_DOMAIN]/v1/functions/[TRANSLATOR_ID]/executions`
  - `SENTRY_DSN=[YOUR_PRODUCTION_SENTRY_DSN]`
  - `ALLOW_SELF_SIGNED=false` (Must be false in production builds)
