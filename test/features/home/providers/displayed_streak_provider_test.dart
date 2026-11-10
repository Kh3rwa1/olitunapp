import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/home/presentation/providers/displayed_streak_provider.dart';
import 'package:itun/features/home/presentation/providers/mission_providers.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/profile/presentation/providers/user_stats_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserStatsEntity _stats({
  int streak = 0,
  String lastActive = '',
  Set<String> dates = const {},
}) => UserStatsEntity(
  practicedLetters: const {},
  completedLessons: const {},
  quizHistory: const {},
  categoryMastery: const {},
  totalLearningMinutes: 0,
  lastActiveDate: lastActive,
  currentStreak: streak,
  totalStars: 0,
  practiceDates: dates,
);

class _StatsNotifier extends UserStatsNotifier {
  _StatsNotifier(this.stats);
  final UserStatsEntity stats;
  @override
  AsyncValue<UserStatsEntity> build() => AsyncValue.data(stats);
}

void main() {
  final now = DateTime(2026, 11, 10, 20); // 8 pm local

  group('deriveDisplayedStreak', () {
    test('practiced today keeps the full streak', () {
      final s = _stats(
        streak: 5,
        lastActive: '2026-11-10',
        dates: {
          '2026-11-06',
          '2026-11-07',
          '2026-11-08',
          '2026-11-09',
          '2026-11-10',
        },
      );
      expect(deriveDisplayedStreak(s, now), 5);
    });

    test('last practice yesterday keeps the streak alive', () {
      final s = _stats(
        streak: 3,
        lastActive: '2026-11-09',
        dates: {'2026-11-07', '2026-11-08', '2026-11-09'},
      );
      expect(deriveDisplayedStreak(s, now), 3);
    });

    test('two days without practice shows 0, not the stale counter', () {
      final s = _stats(
        streak: 7,
        lastActive: '2026-11-08',
        dates: {'2026-11-06', '2026-11-07', '2026-11-08'},
      );
      expect(deriveDisplayedStreak(s, now), 0);
    });

    test('empty log trusts the counter only for a recent lastActiveDate', () {
      expect(
        deriveDisplayedStreak(_stats(streak: 4, lastActive: '2026-11-10'), now),
        4,
      );
      expect(
        deriveDisplayedStreak(_stats(streak: 4, lastActive: '2026-11-09'), now),
        4,
      );
      expect(
        deriveDisplayedStreak(_stats(streak: 4, lastActive: '2026-11-07'), now),
        0,
      );
      expect(deriveDisplayedStreak(_stats(streak: 4), now), 0);
    });
  });

  group('providers', () {
    Future<ProviderContainer> container(
      UserStatsEntity stats, {
      Map<String, Object> prefsValues = const {},
      DateTime? clock,
    }) async {
      SharedPreferences.setMockInitialValues(prefsValues);
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          userStatsProvider.overrideWith(() => _StatsNotifier(stats)),
          streakClockProvider.overrideWithValue(() => clock ?? now),
          missionClockProvider.overrideWithValue(() => clock ?? now),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('displayedStreakProvider derives from stats', () async {
      final c = await container(
        _stats(streak: 7, lastActive: '2026-11-08', dates: {'2026-11-08'}),
      );
      expect(c.read(displayedStreakProvider), 0);
    });

    test('streakLostProvider fires once and can be acknowledged', () async {
      final stats = _stats(
        streak: 7,
        lastActive: '2026-11-08',
        dates: {'2026-11-08'},
      );
      final c = await container(stats);
      expect(c.read(streakLostProvider), isTrue);

      await acknowledgeStreakLost(await SharedPreferences.getInstance(), stats);
      c.invalidate(streakLostProvider);
      expect(c.read(streakLostProvider), isFalse);
    });

    test('streakLostProvider is false while the streak is alive', () async {
      final c = await container(
        _stats(streak: 2, lastActive: '2026-11-10', dates: {'2026-11-10'}),
      );
      expect(c.read(streakLostProvider), isFalse);
    });

    test('streakAtRisk: alive streak, no practice today, evening', () async {
      final c = await container(
        _stats(streak: 2, lastActive: '2026-11-09', dates: {'2026-11-09'}),
      );
      expect(c.read(streakAtRiskProvider), isTrue);
    });

    test('streakAtRisk is false in the morning', () async {
      final c = await container(
        _stats(streak: 2, lastActive: '2026-11-09', dates: {'2026-11-09'}),
        clock: DateTime(2026, 11, 10, 9),
      );
      expect(c.read(streakAtRiskProvider), isFalse);
    });

    test('streakAtRisk is false once something was practiced today', () async {
      final c = await container(
        _stats(streak: 2, lastActive: '2026-11-09', dates: {'2026-11-09'}),
        prefsValues: {
          'mission_quiz_taken_date': now.toUtc().toIso8601String().substring(
            0,
            10,
          ),
        },
      );
      expect(c.read(practicedTodayProvider), isTrue);
      expect(c.read(streakAtRiskProvider), isFalse);
    });
  });
}
