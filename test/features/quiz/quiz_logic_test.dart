import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/quiz/presentation/providers/quiz_session_notifier.dart';
import 'package:itun/features/profile/domain/entities/quiz_result_entity.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/shared/models/content_models.dart';

void main() {
  group('Quiz scoring rules', () {
    test('correct answers increment score, combo, multiplier, and stars', () {
      const state = QuizSessionState(comboStreak: 2, bestCombo: 2);

      final next = applyQuizAnswerResult(state, isCorrect: true);

      expect(next.score, 1);
      expect(next.comboStreak, 3);
      expect(next.bestCombo, 3);
      expect(next.comboMultiplier, 2);
      expect(next.bonusStars, 2);
      expect(next.hearts, 3);
    });

    test('combo multiplier is capped at four times', () {
      const state = QuizSessionState(
        score: 11,
        comboStreak: 11,
        bestCombo: 11,
        comboMultiplier: 4,
        bonusStars: 20,
      );

      final next = applyQuizAnswerResult(state, isCorrect: true);

      expect(next.score, 12);
      expect(next.comboStreak, 12);
      expect(next.bestCombo, 12);
      expect(next.comboMultiplier, 4);
      expect(next.bonusStars, 26);
    });

    test('wrong answers consume one heart and record the question once', () {
      const state = QuizSessionState(
        currentQuestion: 4,
        hearts: 1,
        comboStreak: 3,
        comboMultiplier: 2,
        incorrectQuestionIndices: [1],
      );

      final next = applyQuizAnswerResult(state, isCorrect: false);

      expect(next.score, 0);
      expect(next.hearts, 0);
      expect(next.comboStreak, 0);
      expect(next.comboMultiplier, 1);
      expect(next.incorrectQuestionIndices, [1, 4]);
    });
  });

  group('QuizResultEntity', () {
    test('isPassing returns true when score >= 70%', () {
      const result = QuizResultEntity(
        quizId: 'q1',
        score: 7,
        totalQuestions: 10,
        completedAt: '2026-05-04',
      );
      expect(result.isPassing, isTrue);
    });

    test('isPassing returns true at exactly 70%', () {
      const result = QuizResultEntity(
        quizId: 'q1',
        score: 70,
        totalQuestions: 100,
        completedAt: '2026-05-04',
      );
      expect(result.isPassing, isTrue);
    });

    test('isPassing returns false when score < 70%', () {
      const result = QuizResultEntity(
        quizId: 'q1',
        score: 6,
        totalQuestions: 10,
        completedAt: '2026-05-04',
      );
      expect(result.isPassing, isFalse);
    });

    test('isPassing returns false when totalQuestions is 0', () {
      const result = QuizResultEntity(
        quizId: 'q1',
        score: 0,
        totalQuestions: 0,
        completedAt: '2026-05-04',
      );
      expect(result.isPassing, isFalse);
    });

    test('isPassing returns true for perfect score', () {
      const result = QuizResultEntity(
        quizId: 'q1',
        score: 10,
        totalQuestions: 10,
        completedAt: '2026-05-04',
      );
      expect(result.isPassing, isTrue);
    });

    test('equatable works correctly', () {
      const a = QuizResultEntity(
        quizId: 'q1',
        score: 7,
        totalQuestions: 10,
        completedAt: '2026-05-04',
      );
      const b = QuizResultEntity(
        quizId: 'q1',
        score: 7,
        totalQuestions: 10,
        completedAt: '2026-05-04',
      );
      const c = QuizResultEntity(
        quizId: 'q2',
        score: 7,
        totalQuestions: 10,
        completedAt: '2026-05-04',
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('QuizModel', () {
    test('fromJson/toJson roundtrips correctly', () {
      final quiz = QuizModel(
        id: 'q1',
        categoryId: 'alphabets',
        title: 'Test Quiz',
        questions: [
          QuizQuestion(
            promptOlChiki: 'ᱚ',
            promptLatin: 'What sound?',
            optionsOlChiki: ['a', 'i', 'u', 'o'],
            optionsLatin: ['a', 'i', 'u', 'o'],
          ),
        ],
      );

      final json = quiz.toJson();
      final restored = QuizModel.fromJson(json);

      expect(restored.id, quiz.id);
      expect(restored.title, quiz.title);
      expect(restored.questions.length, 1);
      expect(restored.questions.first.correctIndex, 0);
      expect(restored.questions.first.promptOlChiki, 'ᱚ');
    });

    test('QuizQuestion validates correct answer index', () {
      final question = QuizQuestion(
        promptOlChiki: 'ᱛ',
        promptLatin: 'Identify:',
        optionsOlChiki: ['at', 'ag', 'al', 'ak'],
        optionsLatin: ['at', 'ag', 'al', 'ak'],
        correctIndex: 2,
      );

      expect(question.correctIndex, 2);
      expect(question.optionsLatin[question.correctIndex], 'al');
    });
  });

  group('UserStatsEntity quiz computations', () {
    test('quizAccuracy computes correctly', () {
      const stats = UserStatsEntity(
        practicedLetters: {},
        completedLessons: {},
        quizHistory: {
          'q1': QuizResultEntity(
            quizId: 'q1',
            score: 8,
            totalQuestions: 10,
            completedAt: '',
          ),
          'q2': QuizResultEntity(
            quizId: 'q2',
            score: 6,
            totalQuestions: 10,
            completedAt: '',
          ),
        },
        categoryMastery: {},
        totalLearningMinutes: 0,
        lastActiveDate: '',
        currentStreak: 0,
        totalStars: 0,
      );

      // (8+6) / (10+10) = 14/20 = 0.7
      expect(stats.quizAccuracy, closeTo(0.7, 0.001));
    });

    test('quizAccuracy returns 0 when no quizzes', () {
      const stats = UserStatsEntity(
        practicedLetters: {},
        completedLessons: {},
        quizHistory: {},
        categoryMastery: {},
        totalLearningMinutes: 0,
        lastActiveDate: '',
        currentStreak: 0,
        totalStars: 0,
      );
      expect(stats.quizAccuracy, 0.0);
    });

    test('bestQuizScore returns highest percentage', () {
      const stats = UserStatsEntity(
        practicedLetters: {},
        completedLessons: {},
        quizHistory: {
          'q1': QuizResultEntity(
            quizId: 'q1',
            score: 8,
            totalQuestions: 10,
            completedAt: '',
          ),
          'q2': QuizResultEntity(
            quizId: 'q2',
            score: 10,
            totalQuestions: 10,
            completedAt: '',
          ),
        },
        categoryMastery: {},
        totalLearningMinutes: 0,
        lastActiveDate: '',
        currentStreak: 0,
        totalStars: 0,
      );

      expect(stats.bestQuizScore, 100); // 10/10 = 100%
    });

    test('quizzesCompletedCount reflects history size', () {
      const stats = UserStatsEntity(
        practicedLetters: {},
        completedLessons: {},
        quizHistory: {
          'q1': QuizResultEntity(
            quizId: 'q1',
            score: 5,
            totalQuestions: 10,
            completedAt: '',
          ),
        },
        categoryMastery: {},
        totalLearningMinutes: 0,
        lastActiveDate: '',
        currentStreak: 0,
        totalStars: 0,
      );
      expect(stats.quizzesCompletedCount, 1);
    });

    test('learnerLevel progresses with activity', () {
      const beginner = UserStatsEntity(
        practicedLetters: {},
        completedLessons: {},
        quizHistory: {},
        categoryMastery: {},
        totalLearningMinutes: 0,
        lastActiveDate: '',
        currentStreak: 0,
        totalStars: 0,
      );
      expect(beginner.learnerLevel, 'Beginner');

      // Need >= 20% overallProgress AND >= 3 lessons.
      // overallProgress = avg(alphabetProgress, numbersProgress, vocabularyProgress, rhymesProgress)
      // Each needs to contribute: 10 letters (33%), 2 numbers_ (20%), 4 words_ (20%), 2 rhymes_ (20%) → avg ~23%
      const intermediate = UserStatsEntity(
        practicedLetters: {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'},
        completedLessons: {
          'l1',
          'l2',
          'l3',
          'numbers_1',
          'numbers_2',
          'words_1',
          'words_2',
          'words_3',
          'words_4',
          'rhymes_1',
          'rhymes_2',
        },
        quizHistory: {},
        categoryMastery: {},
        totalLearningMinutes: 60,
        lastActiveDate: '',
        currentStreak: 5,
        totalStars: 100,
      );
      expect(intermediate.learnerLevel, 'Intermediate');
    });

    test('overallProgress averages all skill categories', () {
      const stats = UserStatsEntity(
        practicedLetters: {},
        completedLessons: {},
        quizHistory: {},
        categoryMastery: {},
        totalLearningMinutes: 0,
        lastActiveDate: '',
        currentStreak: 0,
        totalStars: 0,
      );
      // All zeros → 0.0.
      expect(stats.overallProgress, 0.0);
    });
  });
}
