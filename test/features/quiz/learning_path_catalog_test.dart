import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/quiz/domain/learning_path_catalog.dart';
import 'package:itun/shared/providers/language_settings_providers.dart'
    show SantaliProficiency;

void main() {
  group('learningPathFor (proficiency-based progression, spec §15)', () {
    test('fluent speakers get the Santali speaker path', () {
      final path = learningPathFor(SantaliProficiency.fluentSpeaker);
      expect(identical(path, LearningPathCatalog.santaliSpeakerPath), isTrue);
      expect(path.steps.first.categoryId, 'cat_alphabets');
      expect(
        path.steps.map((s) => s.id),
        containsAll(<String>['ol_chiki_alphabet', 'reading']),
      );
    });

    test('fluent readers also get the Santali speaker path', () {
      final path = learningPathFor(SantaliProficiency.fluentReader);
      expect(identical(path, LearningPathCatalog.santaliSpeakerPath), isTrue);
    });

    test('complete beginners get the non-Santali beginner path', () {
      final path = learningPathFor(SantaliProficiency.none);
      expect(
        identical(path, LearningPathCatalog.nonSantaliBeginnerPath),
        isTrue,
      );
      // Starts with spoken greetings, ends with gradual Ol Chiki.
      expect(path.steps.first.id, 'greetings');
      expect(path.steps.last.id, 'gradual_ol_chiki');
    });

    test('partial speakers get the bridge path', () {
      for (final proficiency in [
        SantaliProficiency.understandsSome,
        SantaliProficiency.beginnerReader,
      ]) {
        final path = learningPathFor(proficiency);
        expect(identical(path, LearningPathCatalog.partialSpeakerPath), isTrue);
        expect(path.steps.first.id, 'audio_diagnostic');
      }
    });

    test('every proficiency maps to a catalog path', () {
      for (final proficiency in SantaliProficiency.values) {
        expect(kLearningPathCatalog, contains(learningPathFor(proficiency)));
      }
    });

    test('step ids are unique within a path', () {
      for (final path in kLearningPathCatalog) {
        final ids = path.steps.map((s) => s.id).toList();
        expect(
          ids.toSet().length,
          ids.length,
          reason: 'Duplicate step ids in path for ${path.title}',
        );
      }
    });

    test('every path has at least one openable category step', () {
      for (final path in kLearningPathCatalog) {
        expect(
          path.firstOpenableStep,
          isNotNull,
          reason: 'No openable step in path for ${path.title}',
        );
        for (final step in path.steps) {
          // Steps either open a real category or are served by a dedicated
          // surface (tracing, typing, stories, audio diagnostic).
          expect(
            step.categoryId == null || step.categoryId!.startsWith('cat_'),
            isTrue,
            reason: 'Bad categoryId on step ${step.id} in ${path.title}',
          );
        }
      }
    });

    test('santali speaker path matches the spec §15 verbatim order', () {
      final ids = LearningPathCatalog.santaliSpeakerPath.steps
          .map((s) => s.id)
          .toList();
      expect(ids, [
        'ol_chiki_alphabet',
        'letter_sounds',
        'tracing',
        'word_recognition',
        'spelling',
        'dictation',
        'reading',
        'typing',
        'stories',
      ]);
    });
  });
}
