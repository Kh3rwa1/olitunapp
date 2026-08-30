import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/shared/providers/language_settings_providers.dart';

Future<ProviderContainer> _containerWith(Map<String, Object> initialPrefs) async {
  SharedPreferences.setMockInitialValues(initialPrefs);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('language settings: fresh install defaults', () {
    test('teaching language defaults to English', () async {
      final container = await _containerWith({});
      expect(container.read(teachingLanguageProvider), 'en');
      expect(container.read(effectiveTeachingLanguageProvider), 'en');
    });

    test('proficiency defaults to none', () async {
      final container = await _containerWith({});
      expect(
        container.read(santaliProficiencyProvider),
        SantaliProficiency.none,
      );
    });

    test('audio mode defaults to translationOnDemand', () async {
      final container = await _containerWith({});
      expect(
        container.read(lessonAudioModeProvider),
        LessonAudioMode.translationOnDemand,
      );
    });

    test('goals default to empty set', () async {
      final container = await _containerWith({});
      expect(container.read(learningGoalsProvider), isEmpty);
    });

    test('starter audio download defaults to false', () async {
      final container = await _containerWith({});
      expect(container.read(starterAudioDownloadProvider), isFalse);
    });
  });

  group('legacy migration', () {
    test('legacy app_language=sat seeds teaching language sat', () async {
      final container = await _containerWith({
        'app_language': 'sat',
        'learner_level': 'basicReader',
      });

      expect(container.read(teachingLanguageProvider), 'sat');
      expect(
        container.read(santaliProficiencyProvider),
        SantaliProficiency.beginnerReader,
      );
    });

    test('legacy app_language=en seeds teaching language en', () async {
      final container = await _containerWith({'app_language': 'en'});
      expect(container.read(teachingLanguageProvider), 'en');
    });

    test('existing new keys are never overwritten by migration', () async {
      final container = await _containerWith({
        'app_language': 'sat',
        'teaching_language': 'bn',
      });

      expect(container.read(teachingLanguageProvider), 'bn');
    });

    test('legacy keys are preserved and migration is idempotent', () async {
      SharedPreferences.setMockInitialValues({'app_language': 'sat'});
      final prefs = await SharedPreferences.getInstance();

      migrateLegacyLanguagePrefs(prefs);
      migrateLegacyLanguagePrefs(prefs);

      expect(prefs.getString('app_language'), 'sat');
      expect(prefs.getString(teachingLanguageKey), 'sat');
      expect(prefs.getInt('language_prefs_version'), 1);
    });

    test('unknown stored values fall back safely', () async {
      final container = await _containerWith({
        'teaching_language': 'fr',
        'santali_proficiency': 'wizard',
        'lesson_audio_mode': 'surround',
      });

      // No legacy app_language stored -> English fallback.
      expect(container.read(teachingLanguageProvider), 'en');
      expect(container.read(effectiveTeachingLanguageProvider), 'en');
      expect(
        container.read(santaliProficiencyProvider),
        SantaliProficiency.none,
      );
      expect(
        container.read(lessonAudioModeProvider),
        LessonAudioMode.translationOnDemand,
      );
    });

    test('teaching falls back to legacy interface when stored value invalid',
        () async {
      final container = await _containerWith({
        'teaching_language': 'fr',
        'app_language': 'bn',
      });

      // 'fr' is not teachable; provider falls back to interface language.
      expect(container.read(teachingLanguageProvider), 'bn');
      expect(container.read(effectiveTeachingLanguageProvider), 'bn');
    });
  });

  group('mapLegacyLearnerLevel', () {
    test('maps legacy levels conservatively', () {
      expect(mapLegacyLearnerLevel('beginner'), SantaliProficiency.none);
      expect(
        mapLegacyLearnerLevel('familiar'),
        SantaliProficiency.understandsSome,
      );
      expect(
        mapLegacyLearnerLevel('basicReader'),
        SantaliProficiency.beginnerReader,
      );
      expect(
        mapLegacyLearnerLevel('advanced'),
        SantaliProficiency.fluentReader,
      );
      expect(mapLegacyLearnerLevel(null), SantaliProficiency.none);
      expect(mapLegacyLearnerLevel('garbage'), SantaliProficiency.none);
    });
  });

  group('LearningGoal parsing', () {
    test('unknown goal names are dropped from stored lists', () async {
      final container = await _containerWith({
        'learning_goals': ['speakSantali', 'flyToMoon', 'readOlChiki'],
      });

      expect(
        container.read(learningGoalsProvider),
        {LearningGoal.speakSantali, LearningGoal.readOlChiki},
      );
    });
  });
}
