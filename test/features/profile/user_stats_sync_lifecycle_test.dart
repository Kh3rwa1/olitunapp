import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:itun/core/error/failures.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/auth/domain/repositories/auth_repository.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/profile/domain/repositories/profile_repository.dart';
import 'package:itun/features/profile/presentation/providers/user_stats_provider.dart';
import 'package:itun/shared/widgets/state_widgets.dart';

class _ProfileRepo extends Mock implements ProfileRepository {}

class _AuthRepo extends Mock implements AuthRepository {}

const _stats = UserStatsEntity(
  practicedLetters: {},
  completedLessons: {},
  quizHistory: {},
  categoryMastery: {},
  totalLearningMinutes: 0,
  lastActiveDate: '',
  currentStreak: 0,
  totalStars: 10,
);

void main() {
  late _ProfileRepo repo;
  late ProviderContainer container;
  late UserStatsNotifier notifier;
  var disposed = false;

  void disposeContainer() {
    if (disposed) return;
    disposed = true;
    container.dispose();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = _ProfileRepo();
    final auth = _AuthRepo();
    when(repo.getUserStats).thenAnswer((_) async => const Right(_stats));
    when(repo.syncPendingStats).thenAnswer((_) async => const Right(null));
    when(auth.getCurrentUser).thenAnswer((_) async => const Right(null));
    container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
        authRepositoryProvider.overrideWithValue(auth),
        sharedPreferencesProvider.overrideWithValue(prefs),
        appConnectivityProvider.overrideWith(
          (ref) => const Stream<List<ConnectivityResult>>.empty(),
        ),
      ],
    );
    disposed = false;
    addTearDown(disposeContainer);
    notifier = container.read(userStatsProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    clearInteractions(repo);
  });

  test('does not start sync after disposal', () async {
    disposeContainer();

    await expectLater(notifier.syncPendingStats(), completes);

    verifyNever(repo.syncPendingStats);
    verifyNever(repo.getUserStats);
  });

  for (final succeeds in [true, false]) {
    test('ignores late sync result: success=$succeeds', () async {
      final sync = Completer<Either<Failure, void>>();
      when(repo.syncPendingStats).thenAnswer((_) => sync.future);
      final work = notifier.syncPendingStats();
      final completed = expectLater(work, completes);
      expect(container.read(syncStatusProvider), SyncStatus.syncing);

      disposeContainer();
      sync.complete(
        succeeds
            ? const Right(null)
            : const Left(ServerFailure(message: 'offline')),
      );
      await completed;

      verifyNever(repo.getUserStats);
    });
  }

  test('ignores a stats reload completed after disposal', () async {
    final reload = Completer<Either<Failure, UserStatsEntity>>();
    final reloadStarted = Completer<void>();
    when(repo.getUserStats).thenAnswer((_) {
      reloadStarted.complete();
      return reload.future;
    });
    final work = notifier.syncPendingStats();
    final completed = expectLater(work, completes);
    await reloadStarted.future;

    disposeContainer();
    reload.complete(const Right(_stats));
    await completed;

    verify(repo.getUserStats).called(1);
  });

  test('live sync still reloads merged stats', () async {
    final merged = _stats.copyWith(totalStars: 25);
    when(repo.getUserStats).thenAnswer((_) async => Right(merged));

    await notifier.syncPendingStats();

    expect(container.read(syncStatusProvider), SyncStatus.success);
    expect(container.read(isStatsSyncedProvider), isTrue);
    expect(container.read(userStatsProvider).value, merged);
    verify(repo.getUserStats).called(1);
  });

  test('live sync failures still mark stats unsynced', () async {
    when(repo.syncPendingStats).thenAnswer(
      (_) async => const Left(ServerFailure(message: 'offline')),
    );

    await notifier.syncPendingStats();

    expect(container.read(syncStatusProvider), SyncStatus.error);
    expect(container.read(isStatsSyncedProvider), isFalse);
    verifyNever(repo.getUserStats);
  });
}
