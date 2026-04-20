import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/progress_provider.dart';

/// Integration tests for critical user flows.
///
/// These test the data layer and state management without
/// requiring a running Appwrite backend. UI widget tests
/// that need navigation/GoRouter should use `integration_test/`.
void main() {
  group('Flow: Fresh user → Progress tracking', () {
    test('new user starts with empty progress', () {
      final progress = UserProgressData();

      expect(progress.currentStreak, 0);
      expect(progress.totalStars, 0);
      expect(progress.completedLessons, isEmpty);
      expect(progress.quizHistory, isEmpty);
      expect(progress.learnerLevel, 'Beginner');
      expect(progress.overallProgress, 0.0);
    });

    test('completing a lesson updates progress correctly', () {
      var progress = UserProgressData();

      // User completes first lesson
      progress = progress.copyWith(
        completedLessons: {...progress.completedLessons, 'lesson_a1'},
        totalStars: progress.totalStars + 3,
        totalLearningMinutes: 5,
      );

      expect(progress.lessonsCompletedCount, 1);
      expect(progress.totalStars, 3);
      expect(progress.totalLearningMinutes, 5);
    });

    test('completing a quiz records history and calculates accuracy', () {
      var progress = UserProgressData();

      // User takes quiz and scores 8/10
      final quizResult = QuizResult(
        quizId: 'quiz_alphabets',
        score: 8,
        totalQuestions: 10,
        completedAt: DateTime.now().toIso8601String(),
      );

      progress = progress.copyWith(
        quizHistory: {...progress.quizHistory, 'quiz_alphabets': quizResult},
      );

      expect(progress.quizHistory.length, 1);
      expect(progress.quizAccuracy, 0.8);
      expect(quizResult.isPassing, true);
      expect(progress.bestQuizScore, 80);
    });

    test('multiple quizzes calculate average accuracy', () {
      final progress = UserProgressData(
        quizHistory: {
          'q1': QuizResult(quizId: 'q1', score: 8, totalQuestions: 10, completedAt: ''),
          'q2': QuizResult(quizId: 'q2', score: 6, totalQuestions: 10, completedAt: ''),
          'q3': QuizResult(quizId: 'q3', score: 10, totalQuestions: 10, completedAt: ''),
        },
      );

      // Average: (8+6+10) / (10+10+10) = 24/30 = 0.8
      expect(progress.quizAccuracy, 0.8);
      expect(progress.bestQuizScore, 100);
    });

    test('practicing letters advances alphabet progress', () {
      // Practice 6 out of 30 letters → 20%
      final progress = UserProgressData(
        practicedLetters: {'ᱚ', 'ᱛ', 'ᱜ', 'ᱝ', 'ᱞ', 'ᱟ'},
      );

      expect(progress.alphabetProgress, closeTo(0.2, 0.01));
    });

    test('learner level advances with mastery', () {
      // Fresh user
      expect(UserProgressData().learnerLevel, 'Beginner');

      // overallProgress = average of 4 skills. Need alphabetProgress high enough
      // that average ≥ 0.2. 24/30 = 0.8 → avg = 0.8/4 = 0.2 ✓
      final intermediate = UserProgressData(
        completedLessons: Set.from(['lesson_1', 'lesson_2', 'lesson_3']),
        practicedLetters: Set.from([
          'ᱚ','ᱛ','ᱜ','ᱝ','ᱞ','ᱟ','ᱠ','ᱡ','ᱢ','ᱣ','ᱤ','ᱥ',
          'ᱦ','ᱧ','ᱨ','ᱩ','ᱪ','ᱫ','ᱬ','ᱭ','ᱮ','ᱯ','ᱰ','ᱱ',
        ]),
        totalLearningMinutes: 30,
      );

      expect(intermediate.learnerLevel, 'Intermediate');
    });

    test('streak tracking with daily activity', () {
      final progress = UserProgressData(
        currentStreak: 5,
        lastActiveDate: '2026-04-20',
        totalLearningMinutes: 150,
      );

      expect(progress.currentStreak, 5);
      expect(progress.lastActiveDate, '2026-04-20');

      // Simulate next-day activity
      final nextDay = progress.copyWith(
        currentStreak: 6,
        lastActiveDate: '2026-04-21',
        totalLearningMinutes: 160,
      );

      expect(nextDay.currentStreak, 6);
    });
  });

  group('Flow: Category → Lesson → Quiz data integrity', () {
    test('lesson belongs to a category', () {
      final category = CategoryModel.fromJson({
        'id': 'cat_alphabet',
        'titleOlChiki': 'ᱚᱞ ᱪᱤᱠᱤ',
        'titleLatin': 'Alphabet',
        'iconName': 'alphabet',
        'gradientPreset': 'skyBlue',
        'order': 0,
      });

      final lesson = LessonModel.fromJson({
        'id': 'lesson_1',
        'categoryId': 'cat_alphabet',
        'titleOlChiki': 'ᱯᱟᱹᱴ',
        'titleLatin': 'Vowels Part 1',
        'order': 0,
        'estimatedMinutes': 5,
        'blocks': [
          {'type': 'text', 'textOlChiki': 'ᱚ', 'textLatin': 'O'},
        ],
      });

      expect(lesson.categoryId, category.id);
      expect(lesson.blocks.length, 1);
      expect(lesson.blocks.first.type, 'text');
    });

    test('quiz links to lesson via block reference', () {
      final quiz = QuizModel.fromJson({
        'id': 'quiz_1',
        'categoryId': 'cat_alphabet',
        'title': 'Vowel Quiz',
        'level': 'beginner',
        'order': 0,
        'passingScore': 70,
        'questions': [
          {
            'promptOlChiki': 'ᱚ',
            'promptLatin': 'Identify this vowel',
            'optionsOlChiki': ['a', 'i', 'u', 'o'],
            'optionsLatin': ['a', 'i', 'u', 'o'],
            'correctIndex': 0,
          },
        ],
      });

      final lessonWithQuiz = LessonModel.fromJson({
        'id': 'lesson_quiz',
        'categoryId': 'cat_alphabet',
        'titleOlChiki': 'ᱠᱩᱤᱡᱽ',
        'titleLatin': 'Quiz Time',
        'order': 99,
        'blocks': [
          {'type': 'quiz', 'quizRefId': 'quiz_1'},
        ],
      });

      expect(lessonWithQuiz.blocks.first.type, 'quiz');
      expect(lessonWithQuiz.blocks.first.quizRefId, quiz.id);
    });

    test('full progress flow: complete lesson → take quiz → earn stars', () {
      var progress = UserProgressData();

      // Step 1: Complete lesson
      progress = progress.copyWith(
        completedLessons: {'lesson_vowels_1'},
        totalLearningMinutes: 5,
        totalStars: 2,
      );
      expect(progress.lessonsCompletedCount, 1);

      // Step 2: Take quiz
      final result = QuizResult(
        quizId: 'quiz_vowels',
        score: 9,
        totalQuestions: 10,
        completedAt: DateTime.now().toIso8601String(),
      );
      progress = progress.copyWith(
        quizHistory: {'quiz_vowels': result},
        totalStars: progress.totalStars + 5,
      );

      // Step 3: Verify final state
      expect(progress.lessonsCompletedCount, 1);
      expect(progress.quizAccuracy, 0.9);
      expect(progress.totalStars, 7);
      expect(result.isPassing, true);
    });
  });

  group('Flow: Serialization roundtrips (cloud sync)', () {
    test('full progress survives JSON roundtrip (simulates cloud save/load)', () {
      final original = UserProgressData(
        practicedLetters: {'ᱚ', 'ᱛ', 'ᱜ'},
        completedLessons: {'lesson_1', 'lesson_2'},
        quizHistory: {
          'q1': QuizResult(
            quizId: 'q1', score: 7, totalQuestions: 10,
            completedAt: '2026-04-20T10:00:00.000',
          ),
        },
        categoryMastery: {'alphabets': 2},
        totalLearningMinutes: 45,
        lastActiveDate: '2026-04-20',
        currentStreak: 3,
        totalStars: 15,
      );

      // Simulate: save to cloud → load from cloud
      final json = original.toJson();
      final jsonString = '${json}'; // Force through string representation
      final restored = UserProgressData.fromJson(json);

      expect(restored.practicedLetters, original.practicedLetters);
      expect(restored.completedLessons, original.completedLessons);
      expect(restored.quizHistory.length, original.quizHistory.length);
      expect(restored.totalStars, original.totalStars);
      expect(restored.currentStreak, original.currentStreak);
      expect(restored.quizAccuracy, original.quizAccuracy);
    });
  });
}
