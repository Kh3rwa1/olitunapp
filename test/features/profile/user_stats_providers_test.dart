import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/auth/domain/repositories/auth_repository.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/profile/domain/repositories/profile_repository.dart';
import 'package:itun/features/profile/presentation/providers/profile_account_providers.dart';
import 'package:itun/features/profile/presentation/providers/user_stats_provider.dart';
import 'package:itun/shared/widgets/state_widgets.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockProfileRepo extends Mock implements ProfileRepository {}

class _MockAuthRepo extends Mock implements AuthRepository {}

class _MockAnalytics extends Mock implements LearningAnalyticsService {}

const _baseStats = UserStatsEntity(
  practicedLetters: {},
  completedLessons: {},
  quizHistory: {},
  categoryMastery: {},
  totalLearningMinutes: 0,
  lastActiveDate: '2026-05-01',
  currentStreak: 3,
  totalStars: 10,
);

void main() {
  late _MockProfileRepo repo;
  late _MockAuthRepo authRepo;
  late _MockAnalytics analytics;
  late SharedPreferences prefs;

  setUpAll(() {
    registerFallbackValue(_baseStats);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = _MockProfileRepo();
    authRepo = _MockAuthRepo();
    analytics = _MockAnalytics();
    when(
      () => repo.getUserStats(),
    ).thenAnswer((_) async => const Right(_baseStats));
    when(() => repo.updateUserStats(any())).thenAnswer(
      (invocation) async =>
          Right(invocation.positionalArguments[0] as UserStatsEntity),
    );
    when(
      () => repo.updateDisplayName(any()),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => repo.updateAvatar(any(), any()),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => repo.syncPendingStats(),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => authRepo.getCurrentUser(),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => analytics.track(
        any(),
        source: any(named: 'source'),
        sourceId: any(named: 'sourceId'),
        metadata: any(named: 'metadata'),
        learnerLevel: any(named: 'learnerLevel'),
        scriptMode: any(named: 'scriptMode'),
      ),
    ).thenAnswer((_) async {});
  });

  ProviderContainer containerFor({DateTime Function()? now}) {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        profileRepositoryProvider.overrideWithValue(repo),
        authRepositoryProvider.overrideWithValue(authRepo),
        learningAnalyticsServiceProvider.overrideWithValue(analytics),
        appConnectivityProvider.overrideWith(
          (ref) => Stream.value([ConnectivityResult.wifi]),
        ),
        if (now != null) userStatsClockProvider.overrideWithValue(now),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<UserStatsNotifier> readyNotifier(ProviderContainer container) async {
    final notifier = container.read(userStatsProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return notifier;
  }

  test('syncPendingStats marks success and reloads merged stats', () async {
    final container = containerFor();
    final notifier = await readyNotifier(container);

    await notifier.syncPendingStats();

    expect(container.read(syncStatusProvider), SyncStatus.success);
    expect(container.read(isStatsSyncedProvider), isTrue);
    verify(() => repo.getUserStats()).called(greaterThanOrEqualTo(2));
  });

  test('syncPendingStats marks error and unsynced on failure', () async {
    when(
      () => repo.syncPendingStats(),
    ).thenAnswer((_) async => const Left(ServerFailure(message: 'offline')));
    final container = containerFor();
    final notifier = await readyNotifier(container);

    await notifier.syncPendingStats();

    expect(container.read(syncStatusProvider), SyncStatus.error);
    expect(container.read(isStatsSyncedProvider), isFalse);
  });

  test(
    'updateName persists via repository and updates the name provider',
    () async {
      final container = containerFor();
      final notifier = await readyNotifier(container);

      await notifier.updateName('Somi');

      expect(container.read(userNameProvider), 'Somi');
      verify(() => repo.updateDisplayName('Somi')).called(1);
    },
  );

  test('updateAvatar updates emoji and color providers on success', () async {
    final container = containerFor();
    final notifier = await readyNotifier(container);

    await notifier.updateAvatar('🦊', 2);

    expect(container.read(userAvatarEmojiProvider), '🦊');
    expect(container.read(userAvatarColorIndexProvider), 2);
  });

  test('practiceLetter on a digit updates numbers category mastery', () async {
    final container = containerFor();
    final notifier = await readyNotifier(container);

    await notifier.practiceLetter('᱑');

    final stats = notifier.state.value!;
    expect(stats.practicedLetters, contains('᱑'));
    expect(stats.categoryMastery['numbers'], 10);
  });

  test('recordDailyMissionsCompletedToday records the day only once', () async {
    final container = containerFor();
    final notifier = await readyNotifier(container);

    await notifier.recordDailyMissionsCompletedToday();
    final afterFirst = notifier.state.value!.completedMissionsDates.length;
    await notifier.recordDailyMissionsCompletedToday();

    expect(afterFirst, 1);
    expect(notifier.state.value!.completedMissionsDates.length, 1);
    verify(() => repo.updateUserStats(any())).called(1);
  });

  test(
    'derived providers expose stars, lessons and quizzes counters',
    () async {
      final container = containerFor();
      await readyNotifier(container);

      expect(container.read(userStarsProvider), 10);
      expect(container.read(lessonsCompletedProvider), 0);
      expect(container.read(quizzesCompletedProvider), 0);
    },
  );

  test('isStatsSyncedProvider reflects the stored preference', () async {
    SharedPreferences.setMockInitialValues({'is_stats_synced': false});
    prefs = await SharedPreferences.getInstance();
    final container = containerFor();

    expect(container.read(isStatsSyncedProvider), isFalse);
  });
}
