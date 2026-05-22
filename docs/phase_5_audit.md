# Phase 5 Audit: Backend & Admin Cleanup

This document presents the detailed subtractive cleanup audit of the Appwrite database collections schema, admin console presentation screens, admin-specific Riverpod providers, and background/seed scripts.

---

## 1. Table A — Database Collections Audit

Below is the audit of all 33 collections defined in `scripts/appwrite_setup.mjs`. It cross-checks their usage across the active mobile client codebase (`lib/`), the admin web console pages (`lib/features/admin/`), the backend serverless Appwrite functions, and data seeding scripts.

| Collection ID | Collection Name | Has Admin CRUD? | Has Mobile Provider/Repo? | Has Domain Entity? | Verdict & Action |
|---|---|---|---|---|---|
| `categories` | Categories | Yes | Yes | Yes | **KEEP**. Core category structure. |
| `lessons` | Lessons | Yes | Yes | Yes | **KEEP**. Core lessons content. |
| `quizzes` | Quizzes | Yes | Yes | Yes | **KEEP**. Core quizzes content. |
| `letters` | Letters | Yes | Yes | Yes | **KEEP**. Core letters & alphabet content. |
| `numbers` | Numbers | Yes | Yes | Yes | **KEEP**. Core numbers content. |
| `words` | Words | Yes | Yes | Yes | **KEEP**. Core vocabulary words content. |
| `sentences` | Sentences | Yes | Yes | Yes | **KEEP**. Core sentences content. |
| `rhymes` | Rhymes | Yes | Yes | Yes | **KEEP**. Core Bakhed content. |
| `rhyme_categories` | Rhyme Categories | Yes | Yes | Yes | **DELETE_FROM_SCHEMA**. Orphaned after Phase 3's flatten-to-tags refactoring. Needs full pruning from schemas, seed scripts, router, and codebase. |
| `banners` | Banners | Yes | Yes | Yes | **KEEP**. Hero announcement slides. |
| `translation_cache` | Translation Cache | No | No (Backend) | Yes | **KEEP (Translate)**. Backend translation cache; protected and preserved. |
| `rate_limits` | Translator Rate Limits | No | No (Backend) | No | **KEEP (Translate)**. Translation function security; protected and preserved. |
| `app_settings` | App Settings | Yes | Yes | Yes | **KEEP**. Core system configurations. |
| `bravo_messages` | Bravo Messages | Yes | Yes | Yes | **DELETE_ADMIN_SCREEN_ONLY**. Managed via seed script, never edited via Admin UI in production. Prune screen but KEEP in schema. |
| `badges` | Badges | Yes | Yes | Yes | **KEEP**. Admin-configured gamification badges. |
| `user_badges` | User Badges | Read-only | Yes | Yes | **KEEP**. Backend-managed learner badges. |
| `mission_templates` | Mission Templates | Yes | Yes | Yes | **DELETE_ADMIN_SCREEN_ONLY**. Managed via seed script, never edited via Admin UI. Prune screen but KEEP in schema. |
| `reward_messages` | Reward Messages | Yes | Yes | Yes | **DELETE_ADMIN_SCREEN_ONLY**. Managed via seed script, never edited via Admin UI. Prune screen but KEEP in schema. |
| `quiz_feedback_messages` | Quiz Feedback Messages | Yes | Yes | Yes | **DELETE_ADMIN_SCREEN_ONLY**. Managed via seed script, never edited via Admin UI. Prune screen but KEEP in schema. |
| `gamification_config` | Gamification Config | Yes | Yes | Yes | **KEEP**. Global gamification limits. |
| `admin_audit_logs` | Admin Audit Logs | Read-only | No | Yes | **KEEP**. Security and compliance audit log. |
| `learning_analytics_events` | Learning Analytics Events | Read-only | Yes (Writes) | Yes | **KEEP**. Privacy-safe product usage metrics. |
| `learning_analytics_daily_rollups` | Learning Analytics Rollups | Read-only | No | Yes | **KEEP**. Rollup data for analytics dashboard. |
| `reward_events` | Reward Events | No | Yes | Yes | **KEEP**. Backend reward transaction ledger. |
| `user_mistakes` | User Mistakes | No | Yes | Yes | **KEEP**. Sync ledger for learner review cards. |
| `mistake_review_sessions` | Mistake Review Sessions | No | Yes | Yes | **KEEP**. Backend review performance history. |
| `bakhed_lyrics` | Bakhed Lyrics | Yes | Yes | Yes | **KEEP**. Timed lyrics for music/story playback. |
| `bakhed_vocabulary` | Bakhed Vocabulary | Yes | Yes | Yes | **KEEP**. Curated words from songs. |
| `bakhed_cultural_notes` | Bakhed Cultural Notes | Yes | Yes | Yes | **KEEP**. Historical and cultural annotations. |
| `bakhed_listening_progress` | Bakhed Listening Progress | No | Yes | Yes | **KEEP**. Offline-synced song progress tracker. |
| `daily_affirmations` | Daily Affirmations | Yes | Yes | Yes | **KEEP**. Hero block content on Home. |
| `course_purchases` | Course Purchases | Yes | Yes | Yes | **KEEP**. Protected Razorpay/course transactions. |
| `binti_guru_waitlist` | Binti Guru Waitlist | Yes | Yes | Yes | **KEEP**. Lead generation tracker. |

---

## 2. Table B — Admin Screens Audit

Below is the inventory of all presentation screens found under `lib/features/admin/presentation/`, mapping their file location, GoRouter route, sidebar entry, and target collection, along with their survival verdict.

| Admin Screen File | GoRouter Route | Sidebar Entry Label | Target Collection | Verdict & Action |
|---|---|---|---|---|
| `admin_login_screen.dart` | `/admin/login` | *None (Auth page)* | *None* | **KEEP**. Admin authentication. |
| `admin_media_screen.dart` | `/admin/media` | Media Library | *Storage Buckets* | **KEEP**. Handles media attachments. |
| `admin_rhyme_categories_screen.dart` | `/admin/rhymes/categories` | Bakhed Categories | `rhyme_categories` | **DELETE**. Orphan category page; delete screen, route, and entry. |
| `admin_rhymes_screen.dart` | `/admin/rhymes` | Bakhed & Stories | `rhymes` | **KEEP**. Bakhed and stories CRUD. |
| `admin_settings_screen.dart` | `/admin/settings` | Settings | `app_settings` | **KEEP**. Maintenance and configuration. |
| `affirmations/admin_affirmations_screen.dart` | `/admin/affirmations` | Daily Affirmations | `daily_affirmations` | **KEEP**. Affirmation content manager. |
| `analytics/admin_analytics_screen.dart` | `/admin/analytics` | Analytics | `learning_analytics_daily_rollups` | **KEEP**. Core analytics dashboard. |
| `banners/admin_banners_screen.dart` | `/admin/banners` | Banners | `banners` | **KEEP**. Hero banners manager. |
| `binti_waitlist/admin_binti_waitlist_screen.dart` | `/admin/binti-waitlist` | Binti Waitlist | `binti_guru_waitlist` | **KEEP**. Marriage/ritual waitlist lead CRUD. |
| `categories/admin_categories_screen.dart` | `/admin/categories` | Categories | `categories` | **KEEP**. Subject/category manager. |
| `dashboard/admin_dashboard_screen.dart` | `/admin` | Dashboard | *None* | **KEEP**. Admin console entry point. |
| `gamification/admin_gamification_screen.dart` | `/admin/gamification/*` | Gamification | *Multiple* | **KEEP (Modified)**. Remove sections `'copy'` (bravo), `'missions'` (templates), `'rewards'` (messages), `'quiz_feedback'` (feedback) while keeping `badges`, `config`, `audit_logs`, `maintenance`, and all `bakhed_*` CMS screens. |
| `lessons/admin_lessons_screen.dart` | `/admin/lessons` | Lessons | `lessons` | **KEEP**. Curriculum content manager. |
| `letters/admin_letters_screen.dart` | `/admin/letters` | Letters & Alphabet | `letters` | **KEEP**. Alphabet cards manager. |
| `numbers/admin_numbers_screen.dart` | `/admin/numbers` | Numbers | `numbers` | **KEEP**. Numbers learning manager. |
| `purchases/admin_purchases_screen.dart` | `/admin/purchases` | Purchases & Revenue | `course_purchases` | **KEEP**. Razorpay payment reviewer. |
| `quizzes/admin_quizzes_screen.dart` | `/admin/quizzes` | Quizzes | `quizzes` | **KEEP**. Subject quizzes manager. |
| `sentences/admin_sentences_screen.dart` | `/admin/sentences` | Sentences | `sentences` | **KEEP**. Basic sentences manager. |
| `words/admin_words_screen.dart` | `/admin/words` | Words & Vocabulary | `words` | **KEEP**. Vocabulary card manager. |

---

## 3. Table C — Admin Providers Audit

Every Riverpod provider declared under `lib/features/admin/providers/` has been checked using codebase-wide recursive grep to count its active consumers.

| Provider Name | File Location | Consumer Count | Verdict |
|---|---|---|---|
| `adminAuthProvider` | `lib/features/admin/providers/admin_auth_provider.dart` | 3 (Active) | **KEEP**. Manages team logins and security. |
| `adminAuthServiceProvider` | `lib/features/admin/providers/admin_auth_provider.dart` | 1 (Active) | **KEEP**. Integrates auth with database endpoints. |

> [!NOTE]
> There are zero orphaned providers located under `lib/features/admin/providers/`. All admin providers are actively consumed by the authentication and routing guard structures.

---

## 4. Table D — Seed & Migration Scripts Audit

The seed and utility scripts stored under the `scripts/` directory have been audited to identify references to now-orphaned collections.

| Script File Path | Target / Referenced Collections | Stale / Orphan References | Verdict & Action |
|---|---|---|---|
| `scripts/appwrite_setup.mjs` | All 33 database collections | `rhyme_categories` | **MODIFY**. Remove `rhyme_categories` from collection definitions. |
| `scripts/appwrite_seed.mjs` | Curriculum content & configurations | `rhyme_categories` | **MODIFY**. Remove `rhyme_categories` mock lists and seeding commands. |
| `scripts/appwrite_import.mjs` | Dumps importation | `rhyme_categories` | **MODIFY**. Remove `rhyme_categories` mappings. |
| `scripts/fix_permissions.mjs` | Collection permission configurations | `rhyme_categories` | **MODIFY**. Remove `rhyme_categories` permission initialization array entry. |
| `scripts/seed_gamification_content.mjs`| Gamification copy & configs | *None* | **KEEP**. Seeds messages and rules. |
| `scripts/seed_data.py` | Curriculum content | *None* | **KEEP**. seeds curriculum entries. |

---

## 5. Summary of Suspected Orphans & Preserved Content

### Confirmed Orphans (To Be Deleted/Pruned)
* **`rhyme_categories`**: Completely orphaned. Deleted from the Appwrite setup schema, permissions script, seed script, routing, sidebar, and presentation layers.
* **Gamification Admin UIs (`bravo_messages`, `reward_messages`, `quiz_feedback_messages`, `mission_templates`)**: Identified as `DELETE_ADMIN_SCREEN_ONLY`. These records are seeded once during environment setup and never edited by admin users in production. Pruning their CRUD sections from `admin_gamification_screen.dart` reduces bundle size and visual clutter while protecting their collections and data in the schema for mobile consumption.

### Preserved Features
* **Translate Feature**: Protected. The `translation_cache` and `rate_limits` collections, `AiTranslatorScreen`, `magic_translate_dialog.dart`, and Translate settings entries are kept fully intact.
