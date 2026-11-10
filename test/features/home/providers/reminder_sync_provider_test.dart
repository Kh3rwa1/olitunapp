import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/notifications/notification_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/home/presentation/providers/daily_missions_observer.dart';
import 'package:itun/features/home/presentation/providers/mission_providers.dart';
import 'package:itun/features/home/presentation/providers/reminder_sync_provider.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/profile/presentation/providers/user_stats_provider.dart';
import 'package:itun/features/review/data/review_store_notifier.dart';
import 'package:itun/shared/providers/notification_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StatsNotifier extends UserStatsNotifier {
  _StatsNotifier(this.stats);
  final UserStatsEntity? stats;

  @override
  AsyncValue<UserStatsEntity> build() =>
      stats == null ? const AsyncValue.loading() : AsyncValue.data(stats!);
}

UserStatsEntity _stats({
  required Set<String> practiceDates,
  required String lastActive,
  int storedStreak = 0,
}) => UserStatsEntity(
  practicedLetters: const {},
  completedLessons: const {},
  quizHistory: const {},
  categoryMastery: const {},
  totalLearningMinutes: 0,
  lastActiveDate: lastActive,
  currentStreak: storedStreak,
  totalStars: 0,
  practiceDates: practiceDates,
);

void main() {
  final now = DateTime.utc(2026, 11, 10, 12);

  Future<ProviderContainer> make({
    UserStatsEntity? stats,
    int due = 0,
    Map<String, Object> prefsValues = const {},
    bool observe = false,
  }) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      observers: observe ? const [DailyMissionsObserver()] : const [],
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        missionClockProvider.overrideWithValue(() => now),
        userStatsProvider.overrideWith(() => _StatsNotifier(stats)),
        dueReviewCountProvider.overrideWithValue(due),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('live context is null until stats load', () async {
    final c = await make();
    expect(c.read(liveReminderContextProvider), isNull);
    c.read(reminderSyncProvider);
    expect(c.read(reminderContextProvider), ReminderContext.empty);
  });

  test('live context derives the streak from practice dates', () async {
    final c = await make(
      stats: _stats(
        practiceDates: {'2026-11-08', '2026-11-09'},
        lastActive: '2026-11-09',
        storedStreak: 2,
      ),
      due: 3,
    );
    expect(
      c.read(liveReminderContextProvider),
      const ReminderContext(streak: 2, dueReviews: 3),
    );
  });

  test(
    'a lapsed streak reads as 0 even if the stored counter says 9',
    () async {
      final c = await make(
        stats: _stats(
          practiceDates: {'2026-11-01'},
          lastActive: '2026-11-01',
          storedStreak: 9,
        ),
      );
      expect(c.read(liveReminderContextProvider)!.streak, 0);
    },
  );

  test('practiced today is read from the mission flags', () async {
    final c = await make(
      stats: _stats(practiceDates: {'2026-11-10'}, lastActive: '2026-11-10'),
      prefsValues: {'mission_lesson_completed_date': '2026-11-10'},
    );
    expect(c.read(liveReminderContextProvider)!.practicedToday, isTrue);
  });

  test('reminderSyncProvider publishes the live context', () async {
    final c = await make(
      stats: _stats(
        practiceDates: {'2026-11-09', '2026-11-10'},
        lastActive: '2026-11-10',
      ),
      due: 1,
    );
    c.read(reminderSyncProvider);
    await Future<void>.delayed(Duration.zero);
    expect(
      c.read(reminderContextProvider),
      const ReminderContext(streak: 2, dueReviews: 1),
    );
  });

  test('observer marks the context as practiced once a flag flips', () async {
    final c = await make(
      stats: _stats(practiceDates: {'2026-11-09'}, lastActive: '2026-11-09'),
      observe: true,
    );
    c.read(reminderSyncProvider);
    c.read(lessonCompletedTodayProvider);
    await c.read(lessonCompletedTodayProvider.notifier).setCompleted(true);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(reminderContextProvider).practicedToday, isTrue);
    expect(c.read(notificationsEnabledProvider), isTrue);
  });
}
