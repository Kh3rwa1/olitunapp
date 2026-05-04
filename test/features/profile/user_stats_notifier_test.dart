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
    registerFallbackValue(const UserStatsEntity(
      practicedLetters: {},
      completedLessons: {},
      quizHistory: {},
      categoryMastery: {},
      totalLearningMinutes: 0,
      lastActiveDate: '',
      currentStreak: 0,
      totalStars: 0,
    ));
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
      when(() => mockRepo.getUserStats())
          .thenAnswer((_) async => const Right(baseStats));

      final notifier = UserStatsNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      expect(notifier.state.value, baseStats);
      expect(notifier.state.value!.totalStars, 50);
    });

    test('loadStats emits error on failure', () async {
      when(() => mockRepo.getUserStats()).thenAnswer(
        (_) async => const Left(CacheFailure(message: 'no data')),
      );

      final notifier = UserStatsNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      expect(notifier.state.hasError, isTrue);
    });

    test('addStars increments totalStars correctly', () async {
      when(() => mockRepo.getUserStats())
          .thenAnswer((_) async => const Right(baseStats));
      when(() => mockRepo.updateUserStats(any()))
          .thenAnswer((_) async => const Right(null));

      final notifier = UserStatsNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      await notifier.addStars(25);
      expect(notifier.state.value!.totalStars, 75);
    });

    test('addStars does nothing when state has no value', () async {
      when(() => mockRepo.getUserStats()).thenAnswer(
        (_) async => const Left(CacheFailure(message: 'no data')),
      );

      final notifier = UserStatsNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      // Should not throw.
      await notifier.addStars(10);
      verifyNever(() => mockRepo.updateUserStats(any()));
    });

    test('completeLesson adds lessonId to set', () async {
      when(() => mockRepo.getUserStats())
          .thenAnswer((_) async => const Right(baseStats));
      when(() => mockRepo.updateUserStats(any()))
          .thenAnswer((_) async => const Right(null));

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
      when(() => mockRepo.getUserStats())
          .thenAnswer((_) async => const Right(baseStats));
      when(() => mockRepo.updateUserStats(any()))
          .thenAnswer((_) async => const Right(null));

      final notifier = UserStatsNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      await notifier.completeLesson('l1');
      expect(notifier.state.value!.completedLessons.length, 1);
    });

    test('practiceLetter adds letter to set', () async {
      when(() => mockRepo.getUserStats())
          .thenAnswer((_) async => const Right(baseStats));
      when(() => mockRepo.updateUserStats(any()))
          .thenAnswer((_) async => const Right(null));

      final notifier = UserStatsNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      await notifier.practiceLetter('c');
      expect(notifier.state.value!.practicedLetters, contains('c'));
      expect(notifier.state.value!.practicedLetters.length, 3);
    });

    test('saveQuizResult stores result in history', () async {
      when(() => mockRepo.getUserStats())
          .thenAnswer((_) async => const Right(baseStats));
      when(() => mockRepo.updateUserStats(any()))
          .thenAnswer((_) async => const Right(null));

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

    test('resetProgress clears all stats', () async {
      when(() => mockRepo.getUserStats())
          .thenAnswer((_) async => const Right(baseStats));
      when(() => mockRepo.updateUserStats(any()))
          .thenAnswer((_) async => const Right(null));

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
