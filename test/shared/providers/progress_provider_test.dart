import 'package:flutter_test/flutter_test.dart';
import 'package:itun/shared/providers/progress_provider.dart';

void main() {
  group('UserProgressData', () {
    test('fromJson → toJson roundtrip preserves data', () {
      final original = UserProgressData(
        practicedLetters: {'ᱚ', 'ᱟ', 'ᱤ'},
        completedLessons: {'lesson_a1', 'lesson_n1'},
        quizHistory: {
          'quiz_1': QuizResult(
            quizId: 'quiz_1', score: 4, totalQuestions: 5,
            completedAt: '2026-04-20T10:00:00.000',
          ),
        },
        categoryMastery: {'alphabets': 1},
        totalLearningMinutes: 45,
        lastActiveDate: '2026-04-20',
        currentStreak: 3,
        totalStars: 12,
      );

      final json = original.toJson();
      final restored = UserProgressData.fromJson(json);

      expect(restored.practicedLetters, original.practicedLetters);
      expect(restored.completedLessons, original.completedLessons);
      expect(restored.quizHistory.length, 1);
      expect(restored.quizHistory['quiz_1']!.score, 4);
      expect(restored.categoryMastery['alphabets'], 1);
      expect(restored.totalLearningMinutes, 45);
      expect(restored.lastActiveDate, '2026-04-20');
      expect(restored.currentStreak, 3);
      expect(restored.totalStars, 12);
    });

    test('fromJson handles empty/missing fields gracefully', () {
      final data = UserProgressData.fromJson({});

      expect(data.practicedLetters, isEmpty);
      expect(data.completedLessons, isEmpty);
      expect(data.quizHistory, isEmpty);
      expect(data.totalStars, 0);
      expect(data.currentStreak, 0);
      expect(data.totalLearningMinutes, 0);
    });

    test('copyWith preserves unmodified fields', () {
      final original = UserProgressData(
        totalStars: 10,
        currentStreak: 5,
        totalLearningMinutes: 60,
      );

      final updated = original.copyWith(totalStars: 15);

      expect(updated.totalStars, 15);
      expect(updated.currentStreak, 5);
      expect(updated.totalLearningMinutes, 60);
    });

    group('computed properties', () {
      test('alphabetProgress caps at 1.0', () {
        final data = UserProgressData(
          practicedLetters: Set.from(List.generate(50, (i) => 'letter_$i')),
        );
        expect(data.alphabetProgress, 1.0);
      });

      test('alphabetProgress is 0 when empty', () {
        final data = UserProgressData();
        expect(data.alphabetProgress, 0.0);
      });

      test('lessonsCompletedCount returns correct count', () {
        final data = UserProgressData(
          completedLessons: {'a', 'b', 'c'},
        );
        expect(data.lessonsCompletedCount, 3);
      });

      test('quizAccuracy calculates correctly', () {
        final data = UserProgressData(
          quizHistory: {
            'q1': QuizResult(quizId: 'q1', score: 8, totalQuestions: 10, completedAt: ''),
            'q2': QuizResult(quizId: 'q2', score: 6, totalQuestions: 10, completedAt: ''),
          },
        );
        expect(data.quizAccuracy, 0.7);
      });

      test('quizAccuracy is 0 when no quizzes taken', () {
        final data = UserProgressData();
        expect(data.quizAccuracy, 0.0);
      });

      test('learnerLevel returns Beginner for fresh user', () {
        final data = UserProgressData();
        expect(data.learnerLevel, 'Beginner');
      });

      test('overallProgress averages all skill areas', () {
        final data = UserProgressData();
        // All zeros → 0.0
        expect(data.overallProgress, 0.0);
      });

      test('bestQuizScore returns highest percentage', () {
        final data = UserProgressData(
          quizHistory: {
            'q1': QuizResult(quizId: 'q1', score: 5, totalQuestions: 10, completedAt: ''),
            'q2': QuizResult(quizId: 'q2', score: 9, totalQuestions: 10, completedAt: ''),
          },
        );
        expect(data.bestQuizScore, 90);
      });
    });
  });

  group('QuizResult', () {
    test('isPassing returns true for 70%+', () {
      final result = QuizResult(quizId: 'q1', score: 7, totalQuestions: 10, completedAt: '');
      expect(result.isPassing, true);
    });

    test('isPassing returns false for below 70%', () {
      final result = QuizResult(quizId: 'q1', score: 6, totalQuestions: 10, completedAt: '');
      expect(result.isPassing, false);
    });

    test('isPassing returns false for zero questions', () {
      final result = QuizResult(quizId: 'q1', score: 0, totalQuestions: 0, completedAt: '');
      expect(result.isPassing, false);
    });

    test('fromJson → toJson roundtrip', () {
      final original = QuizResult(
        quizId: 'test_quiz', score: 8, totalQuestions: 10,
        completedAt: '2026-04-20T10:00:00.000',
      );
      final json = original.toJson();
      final restored = QuizResult.fromJson(json);

      expect(restored.quizId, 'test_quiz');
      expect(restored.score, 8);
      expect(restored.totalQuestions, 10);
      expect(restored.completedAt, '2026-04-20T10:00:00.000');
    });
  });
}
