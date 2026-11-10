# Olitun daily-habit plan (10/10 target)

Status: in progress, started 2026-11-10. Branch `feat/daily-habit`.
Baseline: `3fa1a778` (main after PR #474, Worker sign-in). Live Play build:
1.3.4+26110205 (listing updated 2026-11-02).

## 1. Diagnosis (evidence in code, 2026-11-10 audit)

| # | Finding | Evidence | Weight |
|---|---------|----------|--------|
| 1 | Users on builds before 26110205 cannot sign in (every Appwrite POST returns 402) and there is no minimum-build check, so they stay locked out and reminders send them into a dead end. | `app/router/route_guards.dart:72-75`, `features/auth/presentation/welcome_screen.dart:329-376`; no `min_supported_build` anywhere | Critical |
| 2 | No daily return hook: streak is not on the mobile Home header, daily missions were retired, the onboarding daily goal is never read, no daily content. | `home_screen.dart:408-517`, `daily_missions_observer.dart:9-11`, `dailyGoalMinutesProvider` has no non-onboarding reader | High |
| 3 | Streak loss is silent: `currentStreak` is only recomputed on practice writes, so Home shows a stale streak until the next practice drops it to 1. | `user_stats_notifier_helpers.dart:77-95`, `user_stats_provider.dart:182-196` | High |
| 4 | Reminders over-notify and lie: fresh installs default to `high` (4/day) in `main.dart:143-147` while settings show `balanced`; copy says "Protect your streak" with no streak; every cold start re-arms today's slots and undoes practice suppression. | `main.dart:134-154`, `notification_service.dart:349-408, 478-557` | High |
| 5 | Content runway is ~4.5 h (52 lessons x 5 min). After that Home says "All done". | `assets/seed/lessons.json`, `next_best_action_card.dart:144-153` | High |
| 6 | Ad friction inside a 5-minute session: app-open ad on nearly every cold start (cap is in memory only), interstitial on the lesson back button, native ad on every lesson page. | `ad_state.dart:19,58-60`, `lesson_block_top_nav_bar.dart:120-124` | Medium |
| 7 | Retention is unmeasurable: no `app_open`/`session_start` event, no stable install id, guest actor = 30-minute session id. | `analytics_service.dart:50-124, 331-333`, `admin_dashboard.ts:97` | Medium |

## 2. Principles

- Honest state: never show a streak, goal or reminder that is not true.
- One clear reason to open the app each day, visible in the first frame of Home.
- Content never runs out: daily practice is generated from the existing corpus.
- Fewer, smarter notifications beat more notifications.
- Every change is measurable (events exist before the feature ships).
- Every CI gate stays green: 600-line file cap, no hardcoded `Text('...')`,
  l10n parity across en/hi/bn/or/sat, colour tokens only, coverage floor,
  Appwrite auth-only.

## 3. Work streams

### A. Reliability and measurement (ship first)

A1. **Minimum-build gate.** Worker `app_settings` keys `min_supported_build`
and `latest_build` (admin sets via `PUT /api/v1/admin/settings/:key`). App reads
`appSettingsProvider`, compares with `PackageInfo.buildNumber`
(`package_info_plus`, already in the lockfile). Below minimum: full-screen
localized "Update Olitun" screen with a Play Store button (`market://details?id=com.ol.itun`,
https fallback), no other navigation. Below latest: dismissible Home banner.
Offline or settings unavailable: never block. Last known minimum is cached in
prefs so an offline cold start still honours it.

A2. **Analytics attribution.** Stable `installId` (UUID in prefs) sent with
every event; Worker validates (≤64 chars) and stores it in
`learning_analytics_event_details.install_id` (column added at first use via
`PRAGMA table_info` check, following `worker_users.ts`). Admin snapshot actor
becomes `user → install → session`. New events: `app_open` (cold/warm,
`days_since_last_open`), `session_start`, `notification_opened` (payload),
`word_of_day_played`, `daily_goal_met`, `streak_lost_seen`,
`daily_practice_started/completed`, `update_required_shown`.

A3. **Ad friction.** Persist `lastAppOpenShownAt` and `lastInterstitialShownAt`
in prefs so caps survive cold starts. Remove the interstitial from the lesson
back button (keep completion interstitials). No app-open ad within 60 s of a
notification tap.

### B. Notifications that tell the truth

B1. Default frequency `once` everywhere (`main.dart` fallback and provider);
`balanced`/`high` remain opt-in in Settings.
B2. Copy derived from state at schedule time: streak > 0 → "Keep your N-day
streak", due reviews → "N reviews ready", else "Today's word is waiting".
B3. Do not re-arm today's slots on launch when today is already practiced
(mission date keys in prefs); re-arm from tomorrow.
B4. Lapse series instead of one shot: day 3, day 7, day 14 with distinct copy,
re-armed on every practice.
B5. Tap routing by payload: `review` → `/review`, `daily` → Home,
`practice` → `/practice/daily`; every tap logs `notification_opened`.
B6. Permission prompt moves to a moment of success: after the first completed
lesson or quiz, with a one-line in-app rationale sheet first, never in the same
frame as the consent form.

### C. Home habit loop

C1. **Today strip** in the header: streak flame + count (derived, honest),
daily-goal ring (today's minutes / goal), due reviews. Tap → Progress.
C2. **Honest streak**: `displayedStreakProvider` derives the streak from
`practiceDates` at read time. If the stored streak > 0 and the derived streak is
0, show a one-time "Streak reset, start a new one today" card and log
`streak_lost_seen`.
C3. **Streak at risk** branch of `NextBestActionCard` moves to the top when
`hour >= 17`, streak > 0 and nothing practiced today.
C4. **Daily goal**: per-day minutes log in prefs (`daily_minutes_YYYY-MM-DD`),
bumped wherever learning minutes are recorded. Goal met once per day → small
celebration and `daily_goal_met`.
C5. **Word of the day** card: deterministic pick from the words corpus by date,
Ol Chiki + Latin + meaning, play audio, "Practice this word" → daily practice
seeded with that word.
C6. **Daily practice** (`/practice/daily`): a 10-item mixed session built from
due reviews first, then quiz mistakes, then letters/words/sentences the learner
has not seen recently. Reuses the quiz engine and scoring, marks
`quizTakenToday`, awards stars. Always available, so content never runs out.
Home shows it as the primary action when the curriculum is finished and as a
secondary action otherwise.

### D. Measurement view

D1. Admin analytics snapshot already computes DAU/WAU/MAU and retention; with
A2 it becomes correct for guests. Add `app_open` to the default event list.

## 4. Sequencing

Wave 1 (parallel, disjoint files): B (notifications core) and A (ads, analytics,
Worker, update gate, l10n for the update screen).
Wave 2 (parallel): C1–C5 (Home, l10n) and C6 engine (practice domain + route).
Wave 3: wire Home → daily practice, permission prompt, full CI run, PR.

## 5. Definition of done

- `dart format`, `flutter analyze --fatal-infos`, `custom_lint`, all Node gates,
  `flutter test --coverage` with the coverage floor, Worker `vitest` all green.
- New code has tests (files untested after 2026-10-01 fail the gate).
- Fresh install: Home shows streak 0, goal ring, word of the day, daily practice.
- Day 2 without practice: one reminder, honest copy; Home shows streak at risk.
- Day 3 without practice: streak shows 0 with the reset card; lapse reminder.
- Old build below `min_supported_build`: update screen, nothing else.
- Admin snapshot shows DAU from `app_open` with install attribution.

## 6. Out of scope (needs a human decision)

- Authoring new Santali lesson content (cultural and linguistic review needed).
- Push notifications (FCM) and server-side scheduling.
- Reducing native ad placements beyond A3 (revenue trade-off for the owner).
- Setting `min_supported_build` in production (owner action after this ships).
