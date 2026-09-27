import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/lessons/data/models/lesson_model.dart';
import 'package:itun/features/quiz/domain/lesson_quiz_generator.dart';
import 'package:itun/features/quiz/domain/quiz_option_equivalence.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuizOptionEquivalence - Number extraction & semantic matching', () {
    test(
      'extractNumberValue extracts correct integer across scripts & formats',
      () {
        // Bengali formats
        expect(QuizOptionEquivalence.extractNumberValue('সাত (৭)'), 7);
        expect(QuizOptionEquivalence.extractNumberValue('৭'), 7);
        expect(QuizOptionEquivalence.extractNumberValue('সাত'), 7);
        expect(QuizOptionEquivalence.extractNumberValue('চার (৪)'), 4);
        expect(QuizOptionEquivalence.extractNumberValue('৪'), 4);
        expect(QuizOptionEquivalence.extractNumberValue('পাঁচ (৫)'), 5);
        expect(QuizOptionEquivalence.extractNumberValue('৫'), 5);
        expect(QuizOptionEquivalence.extractNumberValue('এক (১)'), 1);
        expect(QuizOptionEquivalence.extractNumberValue('১'), 1);

        // Hindi formats
        expect(QuizOptionEquivalence.extractNumberValue('सात (७)'), 7);
        expect(QuizOptionEquivalence.extractNumberValue('७'), 7);
        expect(QuizOptionEquivalence.extractNumberValue('सात'), 7);
        expect(QuizOptionEquivalence.extractNumberValue('चार (४)'), 4);
        expect(QuizOptionEquivalence.extractNumberValue('१'), 1);

        // Odia formats
        expect(QuizOptionEquivalence.extractNumberValue('ସାତ (୭)'), 7);
        expect(QuizOptionEquivalence.extractNumberValue('୭'), 7);
        expect(QuizOptionEquivalence.extractNumberValue('ସାତ'), 7);
        expect(QuizOptionEquivalence.extractNumberValue('୧'), 1);

        // English & Dash formats
        expect(QuizOptionEquivalence.extractNumberValue('7 – Seven'), 7);
        expect(QuizOptionEquivalence.extractNumberValue('Seven (7)'), 7);
        expect(QuizOptionEquivalence.extractNumberValue('Seven'), 7);
        expect(QuizOptionEquivalence.extractNumberValue('7'), 7);
        expect(
          QuizOptionEquivalence.extractNumberValue('21 – Bar Gel Mit'),
          21,
        );
        expect(QuizOptionEquivalence.extractNumberValue('100'), 100);

        // Alphanumeric test labels are NOT numbers
        expect(QuizOptionEquivalence.extractNumberValue('A0'), isNull);
        expect(QuizOptionEquivalence.extractNumberValue('B0'), isNull);
        expect(QuizOptionEquivalence.extractNumberValue('C0'), isNull);
        expect(QuizOptionEquivalence.extractNumberValue('A1'), isNull);
        expect(QuizOptionEquivalence.extractNumberValue('Q2'), isNull);
      },
    );

    test('areEquivalent identifies semantic number duplicates', () {
      // The user's exact reported bug: "সাত (৭)" vs "৭"
      expect(
        QuizOptionEquivalence.areEquivalent('সাত (৭)', '৭', isNumber: true),
        isTrue,
      );
      expect(
        QuizOptionEquivalence.areEquivalent('৭', 'সাত (৭)', isNumber: true),
        isTrue,
      );
      expect(
        QuizOptionEquivalence.areEquivalent('সাত (৭)', 'সাত', isNumber: true),
        isTrue,
      );
      expect(
        QuizOptionEquivalence.areEquivalent('7 – Seven', '7', isNumber: true),
        isTrue,
      );

      // Different numbers are NOT equivalent
      expect(
        QuizOptionEquivalence.areEquivalent(
          'সাত (৭)',
          'চার (৪)',
          isNumber: true,
        ),
        isFalse,
      );
      expect(
        QuizOptionEquivalence.areEquivalent('৭', '৫', isNumber: true),
        isFalse,
      );

      // Non-number labels are not equivalent
      expect(QuizOptionEquivalence.areEquivalent('A0', 'B0'), isFalse);
    });
  });

  group('QuizOptionEquivalence - Option building & Deduplication', () {
    test('buildOptions guarantees no duplicate or equivalent options in numbers', () {
      final lessonOptions = [
        'এক (১)',
        'দুই (২)',
        'তিন (৩)',
        'চার (৪)',
        'পাঁচ (৫)',
        'ছয় (৬)',
        'সাত (৭)',
        'আট (৮)',
        'নয় (৯)',
      ];

      // For every number 1..9, build options and verify
      for (final target in lessonOptions) {
        final options = QuizOptionEquivalence.buildOptions(
          correctOption: target,
          lessonOptions: lessonOptions,
          isNumber: true,
          isAlphabet: false,
          getFallbackDistractors: () => [
            '১',
            '২',
            '৩',
            '৪',
            '৫',
            '৬',
            '৭',
            '৮',
            '৯',
          ],
        );

        expect(options, hasLength(4));
        expect(options.contains(target), isTrue);

        // Verify all 4 options are distinct strings
        expect(options.toSet(), hasLength(4));

        // Verify NO two options represent the same numeric value
        final numericValues = options
            .map(QuizOptionEquivalence.extractNumberValue)
            .whereType<int>()
            .toList();
        expect(
          numericValues.toSet(),
          hasLength(4),
          reason:
              'Duplicate numeric value detected in options: $options for target $target',
        );

        // Verify formatting consistency (all are "word (numeral)", no bare digits)
        for (final opt in options) {
          expect(
            opt.contains('(') && opt.contains(')'),
            isTrue,
            reason:
                'Option "$opt" lacks numeral parentheses in number lesson quiz',
          );
        }
      }
    });
  });

  group('LessonQuizGenerator - Numbers 0-9 Quiz Generation', () {
    test(
      'Numbers 0-9 Quiz in Bengali never produces duplicate representations of any number',
      () async {
        final raw =
            jsonDecode(await rootBundle.loadString('assets/seed/lessons.json'))
                as List<dynamic>;

        final lessonRaw = raw.cast<Map<String, dynamic>>().firstWhere(
          (l) => l['id'] == 'lesson_numbers_0_9',
        );
        final lesson = LessonModel.fromJson(lessonRaw).toEntity();

        final result = LessonQuizGenerator.generateResult(
          lesson,
          teachingLanguage: 'bn',
        );

        expect(result.isSuccess, isTrue);
        expect(result.quiz.questions, isNotEmpty);

        for (final q in result.quiz.questions) {
          expect(q.optionsLatin, hasLength(4));
          expect(q.optionsLatin.toSet(), hasLength(4));

          // Check for the user bug: no question has both "সাত (৭)" and "৭"
          final numbersInOptions = q.optionsLatin
              .map(QuizOptionEquivalence.extractNumberValue)
              .whereType<int>()
              .toList();

          expect(
            numbersInOptions.toSet().length,
            numbersInOptions.length,
            reason:
                'Question for "${q.promptOlChiki}" has duplicate numeric options: ${q.optionsLatin}',
          );

          // Options must all have consistent formatting (word + numeral)
          for (final opt in q.optionsLatin) {
            expect(
              opt.contains('(') && opt.contains(')'),
              isTrue,
              reason:
                  'Option "$opt" should have localized word with numeral in parentheses',
            );
          }

          // Correct option must match prompt
          final correctOpt = q.optionsLatin[q.correctIndex];
          final correctNum = QuizOptionEquivalence.extractNumberValue(
            correctOpt,
          );
          final promptNum = QuizOptionEquivalence.extractNumberValue(
            q.promptOlChiki,
          );
          expect(correctNum, promptNum);
        }
      },
    );

    test(
      'Numbers 0-9 Quiz in Hindi never produces duplicate representations of any number',
      () async {
        final raw =
            jsonDecode(await rootBundle.loadString('assets/seed/lessons.json'))
                as List<dynamic>;

        final lessonRaw = raw.cast<Map<String, dynamic>>().firstWhere(
          (l) => l['id'] == 'lesson_numbers_0_9',
        );
        final lesson = LessonModel.fromJson(lessonRaw).toEntity();

        final result = LessonQuizGenerator.generateResult(
          lesson,
          teachingLanguage: 'hi',
        );

        expect(result.isSuccess, isTrue);
        for (final q in result.quiz.questions) {
          expect(q.optionsLatin, hasLength(4));
          final numbersInOptions = q.optionsLatin
              .map(QuizOptionEquivalence.extractNumberValue)
              .whereType<int>()
              .toList();

          expect(
            numbersInOptions.toSet().length,
            numbersInOptions.length,
            reason:
                'Hindi question has duplicate numeric options: ${q.optionsLatin}',
          );
        }
      },
    );
  });
}
