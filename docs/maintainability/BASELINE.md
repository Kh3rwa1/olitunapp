# Olitun Maintainability Baseline (Phase 0)

> Generated: 2026-09-27
> Commit: `f80a5396` (main)
> Environment: Flutter 3.47.4 (Dart 3.13.3), Node.js v22.22.3, macOS

---

## 1. Code Volume & Layer Distribution

### Dart LOC per Layer & Feature (`lib/`)
Total Dart files in `lib/`: **775 files**, **156,924 lines of code** (excluding generated l10n files).

| Layer / Feature | Dart Files | Total LOC | % of Codebase | Primary Purpose |
| :--- | :---: | :---: | :---: | :--- |
| **`features/admin`** | 198 | 43,804 | 27.9% | Admin CMS, curriculum editor, analytics, media management |
| **`core`** | 155 | 25,138 | 16.0% | Network, storage, auth, telemetry, audio engine, motion |
| **`shared`** | 95 | 17,545 | 11.2% | Shared models, reusable UI widgets, cross-cutting providers |
| **`features/lessons`** | 62 | 13,979 | 8.9% | Lesson viewer, interactive exercises, Ol Chiki tracing |
| **`features/profile`** | 44 | 10,393 | 6.6% | User profile, stats, streaks, avatar customization, settings |
| **`features/quiz`** | 36 | 8,575 | 5.5% | Adaptive quiz engine, memory attribution, mistakes review |
| **`features/content`** | 34 | 7,491 | 4.8% | Content catalog, audio bundles, stories, segment streams |
| **`features/review`** | 24 | 6,334 | 4.0% | Spaced repetition (SRS), memory store sync & migration |
| **`features/rhymes`** | 19 | 3,929 | 2.5% | Traditional Bakhed audio, poems, rhythmic player |
| **`features/home`** | 14 | 3,111 | 2.0% | Daily missions, streak board, curriculum entry hubs |
| **`features/onboarding`** | 13 | 3,056 | 1.9% | Script introduction, placement survey, interactive audio intro |
| **`features/ai_studio`** | 10 | 2,875 | 1.8% | Multimodal OCR, translation playground, audio generation |
| **`features/voice`** | 13 | 2,600 | 1.7% | Santali Bodhan neural TTS studio & voice selector |
| **`features/auth`** | 16 | 2,128 | 1.4% | Email/password, Google OAuth, session management |
| **`features/practice`** | 8 | 1,849 | 1.2% | Typing practice, keyboard layout training |
| **`features/main`** | 11 | 1,707 | 1.1% | Main shell navigation, responsive sidebar & bottom bar |
| **`app`** | 10 | 757 | 0.5% | App routing (GoRouter), theme configuration, app lifecycle |
| **`features/categories`** | 9 | 729 | 0.5% | Category grids, category selection models |
| **`features/learn`** | 1 | 371 | 0.2% | Content grid overview tab |
| **`main.dart`** | 1 | 286 | 0.2% | App bootstrapper, service initialization, crash handling |
| **`features/legal`** | 1 | 173 | 0.1% | Privacy policy, terms of service viewer |
| **`features/premium`** | 1 | 71 | <0.1% | Premium entitlement presentation wrapper |
| **Total** | **775** | **156,924** | **100%** | |

---

## 2. 20 Largest Files & Cap Proximity

### Top 20 Largest Files in `lib/`
The repository enforces a 600-line cap via `scripts/check_file_length.mjs`.

| Rank | Lines | File Path | Status / Notes |
| :---: | :---: | :--- | :--- |
| 1 | **943** | `lib/features/lessons/data/ol_chiki_strokes.dart` | **Exempt** (static SVG vector database) |
| 2 | **600** | `lib/features/voice/presentation/screens/santali_voice_screen.dart` | **At Cap (600/600)** |
| 3 | **594** | `lib/shared/repositories/content_repository.dart` | Near Cap |
| 4 | **590** | `lib/features/admin/presentation/content/admin_content_list_screen.dart` | Near Cap |
| 5 | **587** | `lib/features/review/data/review_state_sync.dart` | Near Cap |
| 6 | **586** | `lib/features/lessons/presentation/widgets/full_bleed_hero_media.dart` | Near Cap |
| 7 | **586** | `lib/features/onboarding/presentation/onboarding_v2_screen.dart` | Near Cap |
| 8 | **584** | `lib/features/profile/presentation/widgets/mastery_chart.dart` | Near Cap |
| 9 | **580** | `lib/core/languages/ol_chiki_multilingual_helper.dart` | Near Cap |
| 10 | **577** | `lib/features/review/data/review_migration_engine.dart` | Near Cap |
| 11 | **575** | `lib/core/notifications/notification_service.dart` | Near Cap |
| 12 | **575** | `lib/features/admin/presentation/lessons/content/admin_lesson_content_screen.dart` | Near Cap |
| 13 | **575** | `lib/features/admin/presentation/widgets/media_picker_field.dart` | Near Cap |
| 14 | **574** | `lib/features/admin/presentation/widgets/admin_data_table.dart` | Near Cap |
| 15 | **572** | `lib/features/admin/presentation/widgets/content_form/content_form_identity_section.dart` | Near Cap |
| 16 | **571** | `lib/features/voice/presentation/screens/widgets/voice_flip_faces.dart` | Near Cap |
| 17 | **570** | `lib/features/admin/presentation/bakhed/controllers/bakhed_editor_controller.dart` | Near Cap |
| 18 | **570** | `lib/shared/providers/purchases_provider.dart` | Near Cap |
| 19 | **567** | `lib/features/admin/presentation/widgets/content_form.dart` | Near Cap |
| 20 | **566** | `lib/features/admin/presentation/lessons/content/widgets/universal_block_sheet.dart` | Near Cap |

### Files Near the 600-Line Cap (>500 lines)
- Total files exceeding 500 lines: **56 files** (55 non-exempt, 1 exempt).
- Zero non-exempt files currently exceed 600 lines (`check_file_length.mjs` passes).
- High-churn candidates near the ceiling include:
  - `santali_voice_screen.dart` (600 lines)
  - `content_repository.dart` (594 lines)
  - `review_state_sync.dart` (587 lines)
  - `onboarding_v2_screen.dart` (586 lines)
  - `mastery_chart.dart` (584 lines)
  - `notification_service.dart` (575 lines)

---

## 3. Test Suites & Code Coverage

### Flutter Test Suite Metrics
- Total Flutter tests executed: **2,608 passing tests** (2 skipped).
- Total tracked files in `coverage/lcov.info`: **739 files**.
- Overall codebase line coverage: **55.57%** (32,425 of 58,353 instrumented lines).
- Critical learning path coverage: **81.3%** (1,073 of 1,320 lines, passes minimum threshold of 65.0%).
- Completely untested files: **43 files** in `lib/` are never imported by any test.

### Coverage by Architectural Layer
| Layer | Files | Hit / Found Lines | Line Coverage | CI Status / Notes |
| :--- | :---: | :---: | :---: | :--- |
| **`core`** | 147 | 3,708 / 5,439 | **68.17%** | Target ≥ 80% |
| **`shared`** | 88 | 4,016 / 6,737 | **59.61%** | Target ≥ 75% |
| **`app`** | 8 | 142 / 269 | **52.79%** | Routing & app wrappers |
| **Domain Tiers (`*/domain/*`)** | 39 | 1,672 / 1,945 | **85.96%** | Target ≥ 90% in Phase 5 |
| **Data Tiers (`*/data/*`)** | 61 | 2,451 / 4,122 | **59.46%** | Target ≥ 80% in Phase 5 |
| **Presentation Tiers (`*/presentation/*`)** | 389 | 20,006 / 36,320 | **55.08%** | Target ≥ 75% for notifiers/providers |
| **Root/Other (`main.dart` etc.)** | 7 | 481 / 3,562 | **13.50%** | App bootstrapper & unassigned |

### Coverage by Feature
| Feature | Files | Lines Hit / Found | Coverage % |
| :--- | :---: | :---: | :---: |
| **`main`** | 10 | 561 / 599 | **93.66%** |
| **`legal`** | 1 | 35 / 36 | **97.22%** |
| **`onboarding`** | 13 | 1,000 / 1,103 | **90.66%** |
| **`learn`** | 1 | 117 / 130 | **90.00%** |
| **`practice`** | 7 | 607 / 677 | **89.66%** |
| **`premium`** | 1 | 14 / 18 | **77.78%** |
| **`ai_studio`** | 10 | 883 / 1,159 | **76.19%** |
| **`quiz`** | 36 | 2,341 / 3,145 | **74.44%** |
| **`home`** | 14 | 799 / 1,115 | **71.66%** |
| **`profile`** | 42 | 2,542 / 3,944 | **64.45%** |
| **`lessons`** | 57 | 3,177 / 5,011 | **63.40%** |
| **`content`** | 31 | 1,658 / 2,671 | **62.07%** |
| **`categories`** | 7 | 176 / 293 | **60.07%** |
| **`review`** | 24 | 1,294 / 2,210 | **58.55%** |
| **`auth`** | 14 | 459 / 810 | **56.67%** |
| **`voice`** | 12 | 416 / 899 | **46.27%** |
| **`rhymes`** | 18 | 706 / 1,589 | **44.43%** |
| **`admin`** | 191 | 7,293 / 16,937 | **43.06%** |

---

## 4. Appwrite Functions Test Suite & Coverage

There are **25 Appwrite serverless functions** under `functions/` and 1 shared directory (`functions/_shared`).
Backend tests in `npm run test:backend` run **464 tests (462 pass, 2 skip, 0 fail)** in 3.3 seconds.

| Function Name | LOC | Tests | Line Cov % | Branch Cov % | Status / Notes |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **`reconcileOrphanedDeletions`** | 688 | 1 | **100.00%** | **100.00%** | Tested |
| **`reconcilePaymentAttempts`** | 768 | 2 | **100.00%** | **100.00%** | Tested |
| **`getUserGamificationSummary`** | 325 | 1 | **96.89%** | **82.50%** | Tested |
| **`getAuthorizedLesson`** | 812 | 4 | **94.57%** | **84.26%** | Tested |
| **`aiStudio`** | 365 | 2 | **91.74%** | **71.43%** | Tested |
| **`bintiWaitlist`** | 828 | 1 | **90.94%** | **78.46%** | Tested |
| **`mutateReviewState`** | 889 | 4 | **87.88%** | **75.23%** | Tested |
| **`santaliVoice`** | 1,117 | 1 | **85.07%** | **58.82%** | Tested |
| **`delete-account`** | 639 | 2 | **84.82%** | **77.10%** | Tested |
| **`razorpayWebhook`** | 743 | 2 | **80.25%** | **55.26%** | Tested |
| **`admin-maintenance`** | 1,331 | 6 | **79.78%** | **85.19%** | Stale local test fails transaction check; hardened in `functions/test/` |
| **`reviewContent`** | 537 | 1 | **79.50%** | **90.00%** | Tested |
| **`createRazorpayOrder`** | 1,533 | 3 | **79.30%** | **71.03%** | Tested (Phase 1 lockout risk confirmed) |
| **`generateAudio`** | 588 | 1 | **77.88%** | **85.71%** | Tested |
| **`verifyCoursePurchase`** | 461 | 2 | **75.09%** | **48.33%** | Tested |
| **`cleanupAnalyticsEvents`** | 963 | 2 | **61.85%** | **41.18%** | Tested |
| **`translator`** | 1,006 | 1 | **60.00%** | **100.00%** | Tested |
| **`aggregateLearningAnalytics`** | 164 | 1 | **51.22%** | **78.95%** | Tested |
| **`backupCollections`** | 149 | 1 | **25.50%** | **100.00%** | Tested |
| **`completeMistakeReview`** | 90 | 0 | **0.00%** | **0.00%** | **UNTESTED** (legacy `node-appwrite: 15.0.0`) |
| **`getUserMistakes`** | 55 | 0 | **0.00%** | **0.00%** | **UNTESTED** (legacy `node-appwrite: 15.0.0`) |
| **`manageAdminAccess`** | 230 | 0 | **0.00%** | **0.00%** | **UNTESTED (PROTECTED ZONE)** |
| **`markMistakeMastered`** | 66 | 0 | **0.00%** | **0.00%** | **UNTESTED** (legacy `node-appwrite: 15.0.0`) |
| **`recordBakhedProgress`** | 105 | 0 | **0.00%** | **0.00%** | **UNTESTED** (legacy `node-appwrite: 15.0.0`) |
| **`recordMistake`** | 97 | 0 | **0.00%** | **0.00%** | **UNTESTED** (legacy `node-appwrite: 15.0.0`) |

---

## 5. Hardcoded Strings Baseline

- Baseline file: `scripts/hardcoded_strings_baseline.json`
- Baseline count: **2 entries**
  1. `lib/core/startup/startup_status_app.dart:65` (`"Retry Startup"`)
  2. `lib/features/ai_studio/presentation/ai_studio_input.dart:172` (`"${l10n.aiStudioThinking}$dots"`)
- Gate execution status (`node scripts/check_hardcoded_strings.mjs`): **Failing (exit code 1)**
  - **1 stale entry** in baseline: `ai_studio_input.dart:172` has moved or changed.
  - **2 ungrandfathered violations**:
    1. `lib/features/lessons/presentation/category_lessons_screen.dart:230` (`"${manifest.name} (${manifest.scriptName}) course packs are in preview..."`)
    2. `lib/shared/widgets/ai_spark_assistant.dart:337` (`"⚡ Sparks: $_tapCount"`)

---

## 6. Dependency Health & Version Census

### A. Flutter Direct & Dev Dependencies (`pubspec.yaml`)
Total dependencies in `pubspec.yaml`: 44 direct, 8 dev.

| Package | Kind | Locked Version | Latest Available | Major Behind | Documented Cap & Reason |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **`lottie`** | Direct | `3.3.3` | `3.6.1` | No | **Capped `<3.4.0`**: Lottie ≥3.4.0 requires Dart ^3.12 / Flutter ≥3.44; Appwrite Sites builder is pinned to Flutter 3.35 (Dart 3.9.2). |
| **`image_picker`** | Direct | `1.2.2` | `1.2.3` | No | **Capped `<1.2.3`**: Image picker ≥1.2.3 requires Dart ^3.10 / Flutter ≥3.38; Appwrite Sites builder is pinned to Flutter 3.35. |
| **`path_provider`** | Direct | `2.1.5` | `2.1.6` | No | **Capped `<2.1.6`**: Path provider 2.1.6 requires Dart ^3.10 / Flutter ≥3.38; Appwrite Sites builder is pinned to Flutter 3.35. |
| **`record`** | Direct | `6.2.1` | `7.1.1` | **1 major** | **Pinned `6.2.1`**: Record v7 raises SDK floor to Flutter 3.44 / Dart 3.12 (above Appwrite Sites builder runtime) and changes permission signatures. |
| **`appwrite`** | Direct | `21.1.0` | `27.0.0` | **6 majors** | **Capped `^21.1.0`**: Matches backend server API version (TablesDB) and avoids breaking changes in 22+ SDKs. |
| **`flutter_riverpod`** | Direct | `2.6.1` | `3.4.3` | **1 major** | None documented (drift) |
| **`riverpod_lint`** | Dev | `2.6.5` | `3.1.9` | **1 major** | Paired with Riverpod 2.x |
| **`equatable`** | Direct | `2.1.0` | `3.0.0` | **1 major** | None documented (drift) |
| **`file_picker`** | Direct | `10.3.10` | `13.1.0` | **3 majors** | None documented (drift) |
| **`google_mobile_ads`** | Direct | `7.0.0` | `9.1.0` | **2 majors** | None documented (drift) |
| **`shimmer`** | Direct | `3.0.0` | `4.0.0` | **1 major** | None documented (drift) |
| **`cached_network_image`** | Direct | `3.4.1` | `4.0.2` | **1 major** | None documented (drift) |
| **`flutter_local_notifications`** | Direct | `20.1.0` | `22.3.1` | **2 majors** | None documented (drift) |
| **`share_plus`** | Direct | `12.0.2` | `13.3.0` | **1 major** | None documented (drift) |
| `flutter_web_auth_2` | Direct | `5.0.2` | `5.1.0` | No | Upgradable (minor) |
| `razorpay_flutter` | Direct | `1.4.5` | `1.4.7` | No | Upgradable (patch) |
| `go_router` | Direct | `17.2.3` | `18.0.1` | **1 major** | None documented (drift) |
| `video_player` | Direct | `2.10.1` | `2.14.0` | No | Upgradable (minor) |
| `uuid` | Direct | `4.5.3` | `4.6.0` | No | Upgradable (minor) |
| `sentry_flutter` | Direct | `9.28.0` | `9.30.1` | No | Upgradable (minor) |
| `timezone` | Direct | `0.10.1` | `0.11.1` | No | Upgradable (minor) |
| `custom_lint` | Dev | `0.7.6` | `0.8.1` | No | Upgradable (minor) |

### B. Appwrite Functions `node-appwrite` Versions Across All 25 Functions
Functions show extreme dependency fragmentation across **6 different major versions**:

| `node-appwrite` Version | Functions Using This Version | Count |
| :--- | :--- | :---: |
| **`^14.0.0` / `14.2.0`** | `createRazorpayOrder`, `reconcileOrphanedDeletions` | 2 |
| **`15.0.0`** | `completeMistakeReview`, `delete-account`, `getUserGamificationSummary`, `getUserMistakes`, `manageAdminAccess`, `markMistakeMastered`, `recordBakhedProgress`, `recordMistake` | 8 |
| **`24.1.0`** | `backupCollections`, `cleanupAnalyticsEvents` | 2 |
| **`25.1.0`** | `aiStudio`, `generateAudio`, `mutateReviewState`, `razorpayWebhook`, `reconcilePaymentAttempts`, `reviewContent`, `santaliVoice`, `translator`, `verifyCoursePurchase`, (root `package.json`) | 9 |
| **`27.1.0`** | `admin-maintenance`, `aggregateLearningAnalytics`, `getAuthorizedLesson`, (`scripts/package.json`) | 3 |
| **`29.0.0` (Latest)** | `bintiWaitlist` | 1 |

---

## 7. Open Dependabot PRs

Currently **29 Dependabot PRs** are open in the repository:

### A. GitHub Actions (3 PRs) — Low/High Risk
- `#368`: Bump `actions/setup-node` SHA hash (Low risk)
- `#350`: Bump `actions/setup-java` SHA hash (Low risk)
- `#180`: Bump `actions/checkout` from `4.2.2` to `7.0.1` (**High risk**: tag does not exist or unverified; violates immutable SHA pinning)

### B. Pub Ecosystem (5 PRs) — Medium/High Risk
- `#349`: Bump `path_provider` to `2.1.6` (**Blocked**: violates Appwrite Sites builder Flutter 3.35 cap)
- `#348`: Bump `appwrite` to `26.2.0` (**High risk**: major breaking SDK changes; requires Phase 2 upgrade plan)
- `#347`: Bump `flutter_web_auth_2` to `5.1.0` (Low risk)
- `#346`: Bump `razorpay_flutter` to `1.4.6` (Low risk)
- `#345`: Bump `flutter-ui` group (Medium risk: SVG and font rendering)

### C. npm / Serverless Functions (21 PRs) — High Risk & Noise
- **20 PRs** (`#292`–`#313`) attempting to bump individual functions to `node-appwrite: 29.0.0`.
- **1 PR** (`#314`) bumping `node-appwrite` in `/scripts`.
- **Root Cause**: Dependabot is configured to treat every single function folder as a separate npm ecosystem, resulting in 20 parallel PRs for a single dependency update.
- **Solution Planned for Phase 2**: Group npm dependencies in `.github/dependabot.yml` and unify functions under npm workspaces or a single version matrix.

---

## 8. Riverpod Usage Census

Symbol and provider declaration count in `lib/`:

| Provider / Notifier Pattern | Declarations Count | Legacy Status (Riverpod 2.6+) | Action Required |
| :--- | :---: | :--- | :--- |
| **`StateNotifierProvider`** | **3** | **Legacy** | Migrate to `NotifierProvider` / `AsyncNotifierProvider` |
| **`StateNotifier` classes** | **2** | **Legacy** | Migrate to `Notifier` |
| **`StateProvider`** | **29** | **Legacy** | Replace with `NotifierProvider` or pass through widget state |
| **`ChangeNotifierProvider`** | **0** | **Legacy** | None found (clean) |
| **`NotifierProvider`** | **30** | Modern | Keep as canonical pattern for sync state |
| **`Notifier` classes** | **25** | Modern | Keep |
| **`AsyncNotifierProvider`** | **1** | Modern | Keep as canonical pattern for async mutations |
| **`AsyncNotifier` classes** | **1** | Modern | Keep |
| **`FutureProvider`** | **25** | Modern | Keep for read-only async data |
| **`StreamProvider`** | **6** | Modern | Keep for reactive streams (audio, connectivity) |
| **`Provider`** | **110** | Modern | Keep for dependency injection & computed values |

### Legacy Provider Inventory
- `StateNotifierProvider` (3 instances):
  - `targetLanguageCodeProvider` (`lib/core/languages/providers/target_language_provider.dart`)
  - `santaliVoiceNameProvider` (`lib/features/voice/presentation/providers/santali_voice_providers.dart`)
  - `santaliVoiceStyleProvider` (`lib/features/voice/presentation/providers/santali_voice_providers.dart`)
- `StateProvider` (29 instances across `lib/features/admin/`, `lib/features/profile/`, and `lib/shared/providers/local_settings_provider.dart`).

---

## 9. Repository Size & Git History Contributors

### Working Tree Size
- Total working tree: **11 GB** (dominated by untracked artifacts: `.dart_tool`: 5.7 GB, `build/`: 3.9 GB, `release_build/`: 257 MB, `build_artifacts/`: 94 MB).
- `.git` directory size: **481 MB**.

### Top 10 Blobs in Git History
| SHA | Size | Git History Path |
| :--- | :---: | :--- |
| `3768f799d3` | **75.1 MB** | `build/dabf21cbd4f3da7d57aed22daf3344d1.cache.dill.track.dill` |
| `cf45e7371c` | **71.6 MB** | `build/1441e673947503cde6220b848c8e96ee.cache.dill.track.dill` |
| `8457ec214c` | **71.6 MB** | `build/512255e6d0d65f8be62ed92f7210b547.cache.dill.track.dill` |
| `2c72c0f6af` | **71.5 MB** | `build/892b637c16d52470fb7b14b9d9897587.cache.dill.track.dill` |
| `922188dd00` | **57.2 MB** | `mapping.txt` |
| `f8f58ecada` | **15.5 MB** | `build_web_v8.zip` |
| `dbe4ab39ff` | **15.5 MB** | `build_web_v7.zip` |
| `0e977ee177` | **12.6 MB** | `deployment.tar.gz` |
| `4dbf9da7bc` | **7.1 MB** | `build/web/canvaskit/canvaskit.wasm` |
| `d6665c6976` | **4.1 MB** | `assets/videos/onboarding.mp4` |

*Note: Historical commits containing `build/*.dill`, `mapping.txt`, and release archives account for ~420 MB of the 481 MB `.git` directory. Script `scripts/clean_history_remove_build_artifacts.sh` exists in repo but requires owner approval prior to execution.*

### Top 5 Largest Currently Tracked Files
1. `assets/images/bakhed/*.jpg` (13 images, ~1.1 MB–1.33 MB each)
2. `assets/seed/lessons.json` (1.23 MB)
3. `assets/images/olitun_mascot.png` (1.06 MB)
4. `assets/fonts/Inter-Variable.ttf` (856 KB)
5. `assets/animations/avatars/avatar_cat_3d.json` (783 KB)

---

## 10. Static Analysis & Lint Ignores

- `flutter analyze`: **0 issues found** (0 errors, 0 warnings, 0 infos).
- `flutter pub run custom_lint`: **0 issues found**.
- Lint ignore comments in `lib/`: **31 total** (30 `// ignore:`, 1 `// ignore_for_file:`).
  - `deprecated_member_use`: 11
  - `discarded_futures`: 7
  - `invalid_use_of_visible_for_testing_member`: 2
  - `unnecessary_import`: 2
  - `use_null_aware_elements`: 2
  - other individual rules: 5
- Lint ignore comments in `test/`: **21 total** (19 `// ignore:`, 2 `// ignore_for_file:`).

---

## 11. Verification of Review Findings

| Finding | Review Premise | Verification Result | Evidence in Current Code |
| :--- | :--- | :---: | :--- |
| **1. Checkout lockout risk** | Failed/stale attempt without `providerOrderId` causes 409 `reservation_conflict` on retry. | **CONFIRMED TRUE** | `functions/createRazorpayOrder/src/main.js:238` has no resolution branch for `status === 'failed'` or timed-out attempts with `providerOrderId === null`. Client `paywall_bottom_sheet.dart:63` passes no idempotency key, falling back to `checkout_default`, permanently locking the user out of retrying that category. |
| **2. Fail-closed secrets** | `RATE_LIMIT_SALT` falls back to hardcoded dev string. | **CONFIRMED TRUE** | `functions/bintiWaitlist/src/main.js:97` and `functions/createRazorpayOrder/src/main.js:11` use `process.env.RATE_LIMIT_SALT || 'olitun-dev-salt-do-not-use-in-production'`. |
| **3. SecureHttpOverrides** | Returns false from `badCertificateCallback` (platform default), while `ALLOW_SELF_SIGNED=true` returns early without configuring override. | **CONFIRMED TRUE** | `lib/core/network/secure_http_overrides.dart:14-35`: `ALLOW_SELF_SIGNED` logs and returns without setting override; strict path returns `false` which is default. |
| **4. `adminAuthProvider` stale cache** | Does not recompute on sign-out or account switch; can return stale `true`. | **CONFIRMED TRUE** | `lib/features/admin/providers/admin_auth_provider.dart:94-97`: `adminAuthProvider` watches only `adminAuthServiceProvider` and does not listen to `currentUserProvider` or `authNotifierProvider`. |
| **5. SECURITY.md contact email** | `security@olitun.app` while site is `olitun.in`. | **CONFIRMED TRUE** | `SECURITY.md:5` lists `security@olitun.app`. |
| **6. Shared function code drift** | Need sync step or CI check to prevent drift between copies of shared files. | **PARTIALLY TRUE** | `scripts/sync_shared_modules.mjs` and `npm run test:backend` check ALREADY EXIST for 9 functions, but 16 functions are omitted from `functions/_shared/manifest.json`. |
| **7. Side effects in `quiz_screen.dart` `build()`** | Starts quiz and fires analytics inside `build()` via `whenData`. | **CONFIRMED TRUE** | `lib/features/quiz/presentation/quiz_screen.dart:220-239`: `build()` triggers `_trackListeningStarted(quiz)` and `notifier.startQuiz(quiz)`. |
| **8. Hardcoded strings in `quiz_screen.dart`** | "Loading Quiz...", "Quiz is Empty", "Back to Home". | **CONFIRMED TRUE** | `lib/features/quiz/presentation/quiz_screen.dart:245, 273, 276` contains untranslated strings. |
| **9. Live credentials test in `test/`** | `test/ai_studio_sdk_temporary_test.dart` requires live credentials. | **CONFIRMED TRUE** | `test/ai_studio_sdk_temporary_test.dart` checks `Platform.environment['STUDIO_LIVE_CHECK']`. |
| **10. Untested Functions** | Several functions have no tests. | **CONFIRMED TRUE** | 6 functions have 0 tests, including `manageAdminAccess` (a protected zone). |
