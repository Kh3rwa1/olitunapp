import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/hive_service.dart';

// Language, proficiency, goal, and audio-mode preferences for the
// multilingual audio-first learning experience.
//
// The interface (UI) language intentionally remains owned by
// `appLanguageProvider` in `local_settings_provider.dart` — that is the
// single source of truth watched by `main.dart`. This file adds the new,
// separate axes:
// - [teachingLanguageProvider]: the language used for meanings,
//   explanations, hints, and translation audio.
// - [santaliProficiencyProvider]: self-reported Santali level.
// - [lessonAudioModeProvider]: how lesson audio plays.
// - [learningGoalsProvider]: what the learner wants to achieve.
//
// Ol Chiki / Romanized display remains governed by `scriptModeProvider` in
// `local_settings_provider.dart` and is intentionally separate.

/// Interface (UI) languages supported by the app.
const kInterfaceLanguages = <String>['en', 'hi', 'bn', 'or', 'sat'];

/// Languages that can teach Santali content (meanings, explanations,
/// translation audio). Santali is allowed for fluent speakers.
const kTeachingLanguages = <String>['en', 'hi', 'bn', 'or', 'sat'];

/// Stable self-reported Santali proficiency values from onboarding.
/// Never persist localized labels — only [name] is stored.
enum SantaliProficiency {
  none,
  understandsSome,
  fluentSpeaker,
  beginnerReader,
  fluentReader;

  static SantaliProficiency fromName(String? name) {
    return SantaliProficiency.values.firstWhere(
      (e) => e.name == name,
      orElse: () => SantaliProficiency.none,
    );
  }
}

/// How lesson audio should play for the learner.
enum LessonAudioMode {
  /// Play only the Santali target audio.
  targetOnly,

  /// Play Santali, then the teaching-language explanation.
  bilingual,

  /// Play Santali automatically; translation plays on demand.
  translationOnDemand;

  static LessonAudioMode fromName(String? name) {
    return LessonAudioMode.values.firstWhere(
      (e) => e.name == name,
      orElse: () => LessonAudioMode.translationOnDemand,
    );
  }
}

/// Stable learning-goal identifiers (multi-select in onboarding).
enum LearningGoal {
  speakSantali,
  understandSantali,
  readOlChiki,
  writeOlChiki,
  learnEverything,
  helpMyChild,
  prepareForExam;

  static LearningGoal? tryFromName(String? name) {
    for (final goal in LearningGoal.values) {
      if (goal.name == name) return goal;
    }
    return null;
  }
}

// Storage keys.
const teachingLanguageKey = 'teaching_language';
const santaliProficiencyKey = 'santali_proficiency';
const lessonAudioModeKey = 'lesson_audio_mode';
const learningGoalsKey = 'learning_goals';
const starterAudioDownloadKey = 'starter_audio_download';
const teachingLanguageCustomizedKey = 'teaching_language_customized';

const _prefsVersionKey = 'language_prefs_version';
const _prefsVersion = 1;

String _normalize(String? code, List<String> allowed, String fallback) {
  if (code != null && allowed.contains(code)) return code;
  return fallback;
}

/// Maps the legacy `learner_level` enum (beginner / familiar / basicReader /
/// advanced) onto Santali proficiency. Conservative by design: when unsure,
/// pick the safer (lower) bucket.
SantaliProficiency mapLegacyLearnerLevel(String? legacyLevel) {
  switch (legacyLevel) {
    case 'familiar':
      return SantaliProficiency.understandsSome;
    case 'basicReader':
      return SantaliProficiency.beginnerReader;
    case 'advanced':
      return SantaliProficiency.fluentReader;
    case 'beginner':
    default:
      return SantaliProficiency.none;
  }
}

/// One-time, idempotent migration that derives the new preferences from
/// legacy keys (`app_language`, `learner_level`) without deleting them.
/// Existing users get safe defaults; nothing they chose is overwritten.
void migrateLegacyLanguagePrefs(SharedPreferences prefs) {
  final version = prefs.getInt(_prefsVersionKey) ?? 0;
  if (version >= _prefsVersion) return;

  if (prefs.getString(teachingLanguageKey) == null) {
    final legacyInterface = prefs.getString('app_language') ?? 'en';
    prefs.setString(
      teachingLanguageKey,
      kTeachingLanguages.contains(legacyInterface) ? legacyInterface : 'en',
    );
  }

  if (prefs.getString(santaliProficiencyKey) == null) {
    prefs.setString(
      santaliProficiencyKey,
      mapLegacyLearnerLevel(prefs.getString('learner_level')).name,
    );
  }

  if (prefs.getString(lessonAudioModeKey) == null) {
    prefs.setString(
      lessonAudioModeKey,
      LessonAudioMode.translationOnDemand.name,
    );
  }

  prefs.setInt(_prefsVersionKey, _prefsVersion);
}

/// The language used for meanings, explanations, and translation audio.
/// Defaults to the interface language when teachable, otherwise English.
final teachingLanguageProvider = StateProvider<String>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  migrateLegacyLanguagePrefs(prefs);
  final stored = prefs.getString(teachingLanguageKey);
  if (stored != null && kTeachingLanguages.contains(stored)) return stored;
  final legacyInterface = prefs.getString('app_language') ?? 'en';
  return kTeachingLanguages.contains(legacyInterface) ? legacyInterface : 'en';
});

/// Teaching language guaranteed to be one of [kTeachingLanguages].
final effectiveTeachingLanguageProvider = Provider<String>((ref) {
  return _normalize(
    ref.watch(teachingLanguageProvider),
    kTeachingLanguages,
    'en',
  );
});

/// Self-reported Santali proficiency chosen in onboarding.
final santaliProficiencyProvider = StateProvider<SantaliProficiency>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  migrateLegacyLanguagePrefs(prefs);
  return SantaliProficiency.fromName(prefs.getString(santaliProficiencyKey));
});

/// Lesson audio playback mode (see [LessonAudioMode]).
final lessonAudioModeProvider = StateProvider<LessonAudioMode>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  migrateLegacyLanguagePrefs(prefs);
  return LessonAudioMode.fromName(prefs.getString(lessonAudioModeKey));
});

/// Selected learning goals (multi-select).
final learningGoalsProvider = StateProvider<Set<LearningGoal>>((ref) {
  final stored = ref
      .read(sharedPreferencesProvider)
      .getStringList(learningGoalsKey);
  if (stored == null) return <LearningGoal>{};
  return stored.map(LearningGoal.tryFromName).whereType<LearningGoal>().toSet();
});

/// Whether the learner opted into downloading the starter audio pack.
final starterAudioDownloadProvider = StateProvider<bool>((ref) {
  return ref.read(sharedPreferencesProvider).getBool(starterAudioDownloadKey) ??
      false;
});

void updateTeachingLanguage(WidgetRef ref, String languageCode) {
  final normalized = _normalize(languageCode, kTeachingLanguages, 'en');
  final prefs = ref.read(sharedPreferencesProvider);
  prefs.setString(teachingLanguageKey, normalized);
  prefs.setBool(teachingLanguageCustomizedKey, true);
  ref.read(teachingLanguageProvider.notifier).state = normalized;
}

/// Keeps the teaching language aligned with the interface language until the
/// learner customizes it explicitly. Call this whenever the interface
/// language changes.
void cascadeTeachingLanguageForInterface(WidgetRef ref, String interfaceCode) {
  final prefs = ref.read(sharedPreferencesProvider);
  final customized = prefs.getBool(teachingLanguageCustomizedKey) ?? false;
  if (customized) return;
  final teaching =
      kTeachingLanguages.contains(interfaceCode) ? interfaceCode : 'en';
  prefs.setString(teachingLanguageKey, teaching);
  ref.read(teachingLanguageProvider.notifier).state = teaching;
}

void updateSantaliProficiency(WidgetRef ref, SantaliProficiency value) {
  ref
      .read(sharedPreferencesProvider)
      .setString(santaliProficiencyKey, value.name);
  ref.read(santaliProficiencyProvider.notifier).state = value;
}

void updateLessonAudioMode(WidgetRef ref, LessonAudioMode mode) {
  ref.read(sharedPreferencesProvider).setString(lessonAudioModeKey, mode.name);
  ref.read(lessonAudioModeProvider.notifier).state = mode;
}

void toggleLearningGoal(WidgetRef ref, LearningGoal goal) {
  final current = ref.read(learningGoalsProvider);
  final next = <LearningGoal>{...current};
  if (!next.remove(goal)) next.add(goal);
  ref
      .read(sharedPreferencesProvider)
      .setStringList(learningGoalsKey, next.map((g) => g.name).toList());
  ref.read(learningGoalsProvider.notifier).state = next;
}

void updateStarterAudioDownload(WidgetRef ref, bool enabled) {
  ref.read(sharedPreferencesProvider).setBool(starterAudioDownloadKey, enabled);
  ref.read(starterAudioDownloadProvider.notifier).state = enabled;
}
