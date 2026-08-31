# Multilingual Foundation (Phase 1)

This document describes the language architecture introduced by
`feat/multilingual-foundation`. It is the base layer for the audio-first
Santali platform; later phases (content/audio models, playback, Sarvam
generation, admin workflow, stories/offline, listening quizzes) build on it.

## The four language axes — keep them separate

| Axis | Values | Where it lives | Drives |
| --- | --- | --- | --- |
| Interface (UI) language | `en`, `hi`, `bn`, `or`, `sat` | `appLanguageProvider` (legacy key `app_language`) | App locale, UI strings |
| Teaching language | `en`, `hi`, `bn`, `or`, `sat` | `teachingLanguageProvider` (key `teaching_language`) | Meanings, explanations, translation audio |
| Target language | Santali only | content models | Lesson content |
| Script-display mode | `olchiki`, `latin`, `both` | `scriptModeProvider` (legacy key `script_mode`) | Ol Chiki vs Romanized rendering |

Never treat Romanized Santali as English. Never send Santali text to a
teaching-language TTS voice (see the Phase 0 audit for the Sarvam contract).

## New preferences (`lib/shared/providers/language_settings_providers.dart`)

| Provider | Storage key | Type | Default |
| --- | --- | --- | --- |
| `teachingLanguageProvider` | `teaching_language` | String | interface language if teachable, else `en` |
| `santaliProficiencyProvider` | `santali_proficiency` | `SantaliProficiency` enum name | `none` |
| `lessonAudioModeProvider` | `lesson_audio_mode` | `LessonAudioMode` enum name | `translationOnDemand` |
| `learningGoalsProvider` | `learning_goals` | string list of `LearningGoal` names | empty |
| `starterAudioDownloadProvider` | `starter_audio_download` | bool | `false` |

Stable enums — never persist localized labels:

- `SantaliProficiency`: `none`, `understandsSome`, `fluentSpeaker`,
  `beginnerReader`, `fluentReader`
- `LessonAudioMode`: `targetOnly`, `bilingual`, `translationOnDemand`
- `LearningGoal`: `speakSantali`, `understandSantali`, `readOlChiki`,
  `writeOlChiki`, `learnEverything`, `helpMyChild`, `prepareForExam`

### Interface vs teaching language coupling

- `updateAppLanguage` (in `local_settings_provider.dart`) remains the single
  entry point for interface-language changes and still owns the Santali →
  Ol Chiki script coupling.
- It now accepts all five interface languages and cascades the teaching
  language via `cascadeTeachingLanguageForInterface` — **until** the learner
  picks a teaching language explicitly (`updateTeachingLanguage` sets
  `teaching_language_customized`). After that the two axes are independent.

### Migration for existing users

`migrateLegacyLanguagePrefs` runs lazily on first read of any new provider
(versioned by `language_prefs_version`, idempotent):

- `teaching_language` ← legacy `app_language` if teachable, else `en`
- `santali_proficiency` ← legacy `learner_level` (`beginner→none`,
  `familiar→understandsSome`, `basicReader→beginnerReader`,
  `advanced→fluentReader`)
- `lesson_audio_mode` ← `translationOnDemand`

Legacy keys are never deleted; existing values are never overwritten.

## Feature flags (`lib/core/config/feature_flags.dart`)

Resolution order: `--dart-define` override → `app_settings` collection →
default **off**.

| Flag | dart-define | app_settings key |
| --- | --- | --- |
| `multilingualAudioEnabled` | `MULTILINGUAL_AUDIO_ENABLED` | `multilingual_audio_enabled` |
| `onboardingV2Enabled` | `ONBOARDING_V2_ENABLED` | `onboarding_v2_enabled` |
| `bilingualPlaybackEnabled` | `BILINGUAL_PLAYBACK_ENABLED` | `bilingual_playback_enabled` |
| `audioDownloadsEnabled` | `AUDIO_DOWNLOADS_ENABLED` | `audio_downloads_enabled` |
| `audioQuizzesEnabled` | `AUDIO_QUIZZES_ENABLED` | `audio_quizzes_enabled` |
| `sarvamGenerationEnabled` | `SARVAM_GENERATION_ENABLED` | `sarvam_generation_enabled` |

This reuses the existing `app_settings` collection via
`appSettingsProvider`; there is no new flag framework.

## Onboarding v2 (`lib/features/onboarding/presentation/`)

`OnboardingGate` is wired at `/onboarding` in `public_routes.dart`. With the
flag off it renders the legacy `OnboardingScreen` untouched; with it on it
renders `OnboardingV2Screen`:

1. **Language you understand best** — sets interface + teaching language
   (same value initially; independently changeable later in Settings).
2. **Santali proficiency** — stable enum values above.
3. **Learning goals** — multi-select.
4. **Lesson audio mode** — `targetOnly` / `bilingual` / `translationOnDemand`.
5. **Daily goal** (reuses `dailyGoalMinutesProvider`), optional starter-audio
   download preference, optional sign-in, then finish.

Every tap persists immediately to SharedPreferences; guests are never
blocked. On finish, choices are copied best-effort into Appwrite account
prefs (`interfaceLanguage`, `teachingLanguage`, `santaliProficiency`,
`lessonAudioMode`, `learningGoals`, `dailyGoalMinutes`) when authenticated.

Analytics events (existing `LearningAnalyticsService`): `onboarding_language_selected`,
`teaching_language_selected`, `proficiency_selected`,
`learning_goal_selected`, `audio_mode_selected`, `onboarding_completed`.

## Settings

`learning_settings_tiles.dart` adds two tiles (inserted into the Appearance
card):

- **Teaching Language** — en/hi/bn/or/sat picker.
- **Lesson Audio** — audio-mode picker.

The App Language dialog gains Hindi/Bengali/Odia options.

## Localization

- New locales: `app_hi.arb`, `app_bn.arb`, `app_or.arb` — full coverage of
  the `app_en.arb` template plus the new feature keys.
- `app_en.arb` / `app_sat.arb` gain the new feature keys.
- Fallback chain: selected locale → English template → (existing behaviour).
  `hi`/`bn`/`or` are covered by Flutter's stock localizations delegates;
  `sat` keeps the existing fallback delegates in `main.dart`.
- Regenerate after editing ARBs: `flutter pub get` (with `generate: true`)
  or `flutter gen-l10n`.

**Translation review status:** all new `hi`/`bn`/`or` translations and the
new `sat` keys are marked **needs-review**. They are learner-facing but not
yet validated by a native reviewer; track review in this table until Phase 5
introduces a CMS-driven workflow:

| Locale | Scope | Status |
| --- | --- | --- |
| hi | full template + feature keys | needs-review |
| bn | full template + feature keys | needs-review |
| or | full template + feature keys | needs-review |
| sat | feature keys only | needs-review |

## Tests

- `test/shared/providers/language_settings_providers_test.dart` — defaults,
  legacy migration, idempotency, invalid-value fallbacks, enum parsing.
- `test/core/config/feature_flags_test.dart` — flag resolution.
- `test/l10n/arb_parity_test.dart` — required keys in all locales, hi/bn/or
  template coverage, placeholder parity, no empty values.
- `test/features/onboarding/onboarding_v2_screen_test.dart` — full five-step
  walkthrough persistence + guest default path.

Run: `dart format . && flutter analyze --fatal-infos && flutter test`.

## Explicitly not in Phase 1

Audio track/content models, the central playback controller, Sarvam
generation, admin CMS workflow, story player, offline audio downloads, and
listening quizzes. The starter-audio toggle in onboarding step 5 persists
the learner's *preference* only; the download system lands in Phase 6 behind
`audioDownloadsEnabled`.

## Rollback

Flags default off, so the app behaves exactly as before with the package
applied. To remove entirely: revert the branch. All new SharedPreferences
keys are additive; no existing keys are deleted.
