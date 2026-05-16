import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:itun/core/error/failures.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/features/profile/domain/repositories/profile_repository.dart';
import 'package:itun/features/profile/presentation/providers/profile_providers.dart';

class _MockProfileRepo extends Mock implements ProfileRepository {}

void main() {
  late _MockProfileRepo mockRepo;

  setUp(() {
    mockRepo = _MockProfileRepo();
  });

  setUpAll(() {
    registerFallbackValue(
      const UserStatsEntity(
        practicedLetters: {},
        completedLessons: {},
        quizHistory: {},
        categoryMastery: {},
        totalLearningMinutes: 0,
        lastActiveDate: '',
        currentStreak: 0,
        totalStars: 0,
      ),
    );
  });

  const baseStats = UserStatsEntity(
    practicedLetters: {'a', 'b'},
    completedLessons: {'l1'},
    quizHistory: {},
    categoryMastery: {},
    totalLearningMinutes: 30,
    lastActiveDate: '2026-05-01',
    currentStreak: 3,
    totalStars: 50,
  );

  group('UserStatsNotifier', () {
    test('loadStats emits data on success', () async {
      when(
        () => mockRepo.getUserStats(),
      ).thenAnswer((_) async => const Right(baseStats));

      final notifier = UserStatsNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      expect(notifier.state.value, baseStats);
      expect(notifier.state.value!.totalStars, 50);
    });

    test('loadStats emits error on failure', () async {
      when(
        () => mockRepo.getUserStats(),
      ).thenAnswer((_) async => const Left(CacheFailure(message: 'no data')));

      final notifier = UserStatsNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      expect(notifier.state.hasError, isTrue);
    });

    test('addStars increments totalStars correctly', () async {
      when(
        () => mockRepo.getUserStats(),
      ).thenAnswer((_) async => const Right(baseStats));
      when(
        () => mockRepo.updateUserStats(any()),
      ).thenAnswer((_) async => const Right(null));

      final notifier = UserStatsNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      await notifier.addStars(25);
      expect(notifier.state.value!.totalStars, 75);
    });

    test('addStars ignores non-positive values', () async {
      when(
        () => mockRepo.getUserStats(),
      ).thenAnswer((_) async => const Right(baseStats));
      when(
        () => mockRepo.updateUserStats(any()),
      ).thenAnswer((_) async => const Right(null));

      final notifier = UserStatsNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      await notifier.addStars(0);
      await notifier.addStars(-5);

      expect(notifier.state.value!.totalStars, 50);
      verifyNever(() => mockRepo.updateUserStats(any()));
    });

    test('addStars does nothing when state has no value', () async {
      when(
        () => mockRepo.getUserStats(),
      ).thenAnswer((_) async => const Left(CacheFailure(message: 'no data')));

      final notifier = UserStatsNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      // Should not throw.
      await notifier.addStars(10);
      verifyNever(() => mockRepo.updateUserStats(any()));
    });

    test('completeLesson adds lessonId to set', () async {
      when(
        () => mockRepo.getUserStats(),
      ).thenAnswer((_) async => const Right(baseStats));
      when(
        () => mockRepo.updateUserStats(any()),
      ).thenAnswer((_) async => const Right(null));

      final notifier = UserStatsNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      await notifier.completeLesson('l2');
      final lessons = notifier.state.value!.completedLessons;
      expect(lessons, contains('l1'));
      expect(lessons, contains('l2'));
      expect(lessons.length, 2);
    });

    test('completeLesson is idempotent for same lessonId', () async {
      when(
        () => mockRepo.getUserStats(),
      ).thenAnswer((_) async => const Right(baseStats));
      when(
        () => mockRepo.updateUserStats(any()),
      ).thenAnswer((_) async => const Right(null));

      final notifier = UserStatsNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      await notifier.completeLesson('l1');
      expect(notifier.state.value!.completedLessons.length, 1);
      expect(notifier.state.value!.totalLearningMinutes, 30);
    });

    test('completeLesson caps unreasonable learning minutes', () async {
      when(
        () => mockRepo.getUserStats(),
      ).thenAnswer((_) async => const Right(baseStats));
      when(
        () => mockRepo.updateUserStats(any()),
      ).thenAnswer((_) async => const Right(null));

      final notifier = UserStatsNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      await notifier.completeLesson('l2', estimatedMinutes: 999);
      expect(notifier.state.value!.totalLearningMinutes, 270);
    });

    test('streak advances by calendar day, not elapsed hours', () async {
      when(() => mockRepo.getUserStats()).thenAnswer(
        (_) async => const Right(
          UserStatsEntity(
            practicedLetters: {},
            completedLessons: {},
            quizHistory: {},
            categoryMastery: {},
            totalLearningMinutes: 0,
            lastActiveDate: '2026-05-15',
            currentStreak: 4,
            totalStars: 0,
          ),
        ),
      );
      when(
        () => mockRepo.updateUserStats(any()),
      ).thenAnswer((_) async => const Right(null));

      final notifier = UserStatsNotifier(
        mockRepo,
        now: () => DateTime(2026, 5, 16, 23, 55),
      );
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      await notifier.practiceLetter('a');
      expect(notifier.state.value!.currentStreak, 5);
      expect(notifier.state.value!.lastActiveDate, '2026-05-16');
    });

    test('practiceLetter adds letter to set', () async {
      when(
        () => mockRepo.getUserStats(),
      ).thenAnswer((_) async => const Right(baseStats));
      when(
        () => mockRepo.updateUserStats(any()),
      ).thenAnswer((_) async => const Right(null));

      final notifier = UserStatsNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      await notifier.practiceLetter('c');
      expect(notifier.state.value!.practicedLetters, contains('c'));
      expect(notifier.state.value!.practicedLetters.length, 3);
    });

    test('saveQuizResult stores result in history', () async {
      when(
        () => mockRepo.getUserStats(),
      ).thenAnswer((_) async => const Right(baseStats));
      when(
        () => mockRepo.updateUserStats(any()),
      ).thenAnswer((_) async => const Right(null));

      final notifier = UserStatsNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      const result = QuizResultEntity(
        quizId: 'q1',
        score: 8,
        totalQuestions: 10,
        completedAt: '2026-05-04T10:00:00',
      );

      await notifier.saveQuizResult(result);
      expect(notifier.state.value!.quizHistory, containsPair('q1', result));
    });

    test(
      'saveQuizResult preserves quiz retakes as separate attempts',
      () async {
        when(
          () => mockRepo.getUserStats(),
        ).thenAnswer((_) async => const Right(baseStats));
        when(
          () => mockRepo.updateUserStats(any()),
        ).thenAnswer((_) async => const Right(null));

        final notifier = UserStatsNotifier(mockRepo);
        await Future.delayed(Duration.zero);
        await Future.delayed(Duration.zero);

        const first = QuizResultEntity(
          quizId: 'q1',
          score: 8,
          totalQuestions: 10,
          completedAt: '2026-05-04T10:00:00',
        );
        const retake = QuizResultEntity(
          quizId: 'q1',
          score: 10,
          totalQuestions: 10,
          completedAt: '2026-05-05T10:00:00',
        );

        await notifier.saveQuizResult(first);
        await notifier.saveQuizResult(retake);

        final history = notifier.state.value!.quizHistory;
        expect(history.length, 2);
        expect(history['q1'], first);
        expect(history['q1@2026-05-05T10:00:00'], retake);
        expect(notifier.state.value!.quizAccuracy, 0.9);
      },
    );

    test('saveQuizResult clamps impossible scores', () async {
      when(
        () => mockRepo.getUserStats(),
      ).thenAnswer((_) async => const Right(baseStats));
      when(
        () => mockRepo.updateUserStats(any()),
      ).thenAnswer((_) async => const Right(null));

      final notifier = UserStatsNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      await notifier.saveQuizResult(
        const QuizResultEntity(
          quizId: 'q1',
          score: 99,
          totalQuestions: 10,
          completedAt: '2026-05-04T10:00:00',
        ),
      );

      expect(notifier.state.value!.quizHistory['q1']!.score, 10);
      expect(notifier.state.value!.bestQuizScore, 100);
    });

    test('resetProgress clears all stats', () async {
      when(
        () => mockRepo.getUserStats(),
      ).thenAnswer((_) async => const Right(baseStats));
      when(
        () => mockRepo.updateUserStats(any()),
      ).thenAnswer((_) async => const Right(null));

      final notifier = UserStatsNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      await notifier.resetProgress();
      final stats = notifier.state.value!;
      expect(stats.totalStars, 0);
      expect(stats.completedLessons.isEmpty, isTrue);
      expect(stats.practicedLetters.isEmpty, isTrue);
      expect(stats.quizHistory.isEmpty, isTrue);
    });
  });
}
