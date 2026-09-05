import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:itun/core/error/failures.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/profile/domain/repositories/profile_repository.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

/// Hand-written fake proving the interface contract without mocks.
class _InMemoryProfileRepository implements ProfileRepository {
  _InMemoryProfileRepository(this.stats);

  UserStatsEntity stats;
  String? updatedName;
  ({String emoji, int colorIndex})? updatedAvatar;
  int syncCalls = 0;

  @override
  Future<Either<Failure, UserStatsEntity>> getUserStats() async => Right(stats);

  @override
  Future<Either<Failure, UserStatsEntity>> updateUserStats(
    UserStatsEntity newStats,
  ) async {
    stats = newStats;
    return Right(stats);
  }

  @override
  Future<Either<Failure, UserStatsEntity>> resetUserStats() async {
    stats = UserStatsEntity(
      practicedLetters: const {},
      completedLessons: const {},
      quizHistory: const {},
      categoryMastery: const {},
      totalLearningMinutes: 0,
      lastActiveDate: '',
      currentStreak: 0,
      totalStars: 0,
      syncEpoch: stats.syncEpoch + 1,
    );
    return Right(stats);
  }

  @override
  Future<Either<Failure, void>> updateDisplayName(String name) async {
    updatedName = name;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateAvatar(
    String emoji,
    int colorIndex,
  ) async {
    updatedAvatar = (emoji: emoji, colorIndex: colorIndex);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> syncPendingStats() async {
    syncCalls++;
    return const Right(null);
  }
}

const _baseStats = UserStatsEntity(
  practicedLetters: {},
  completedLessons: {},
  quizHistory: {},
  categoryMastery: {},
  totalLearningMinutes: 0,
  lastActiveDate: '2026-09-01',
  currentStreak: 2,
  totalStars: 7,
);

void main() {
  setUpAll(() {
    registerFallbackValue(_baseStats);
  });

  group('ProfileRepository contract', () {
    test('getUserStats returns the stored stats on success', () async {
      final repo = _InMemoryProfileRepository(_baseStats);
      final result = await repo.getUserStats();
      expect(result.getRight().toNullable()!.totalStars, 7);
    });

    test('updateUserStats persists and echoes the new stats', () async {
      final repo = _InMemoryProfileRepository(_baseStats);
      final updated = _baseStats.copyWith(totalStars: 12);
      final result = await repo.updateUserStats(updated);
      expect(result.getRight().toNullable()!.totalStars, 12);
      expect(
        (await repo.getUserStats()).getRight().toNullable()!.totalStars,
        12,
      );
    });

    test('resetUserStats clears progress and advances its epoch', () async {
      final repo = _InMemoryProfileRepository(_baseStats);
      final result = await repo.resetUserStats();
      final reset = result.getRight().toNullable()!;
      expect(reset.totalStars, 0);
      expect(reset.currentStreak, 0);
      expect(reset.syncEpoch, 1);
    });

    test('updateDisplayName and updateAvatar record the changes', () async {
      final repo = _InMemoryProfileRepository(_baseStats);
      expect((await repo.updateDisplayName('Somi')).isRight(), isTrue);
      expect((await repo.updateAvatar('🦊', 3)).isRight(), isTrue);
      expect(repo.updatedName, 'Somi');
      expect(repo.updatedAvatar?.emoji, '🦊');
      expect(repo.updatedAvatar?.colorIndex, 3);
    });

    test('syncPendingStats completes without error and is repeatable', () async {
      final repo = _InMemoryProfileRepository(_baseStats);
      expect((await repo.syncPendingStats()).isRight(), isTrue);
      expect((await repo.syncPendingStats()).isRight(), isTrue);
      expect(repo.syncCalls, 2);
    });

    test('mock repositories surface failures', () async {
      final repo = _MockProfileRepository();
      when(repo.getUserStats).thenAnswer(
        (_) async => const Left(NetworkFailure(message: 'offline')),
      );
      when(() => repo.updateDisplayName(any())).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'conflict')),
      );
      final read = await repo.getUserStats();
      final renamed = await repo.updateDisplayName('Somi');
      expect(read.getLeft().toNullable(), isA<NetworkFailure>());
      expect(renamed.getLeft().toNullable(), isA<ServerFailure>());
      verify(repo.getUserStats).called(1);
    });
  });
}
