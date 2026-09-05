part of 'user_stats_provider.dart';

// Private helper implementations for [UserStatsNotifier], extracted
// into this library part to keep every file under the size budget.
extension _UserStatsNotifierHelpers on UserStatsNotifier {
  void _updateSyncStateFromPrefs() {
    if (_disposed) return;
    try {
      final isSynced =
          ref.read(sharedPreferencesProvider).getBool('is_stats_synced') ??
          true;
      ref.read(isStatsSyncedProvider.notifier).state = isSynced;
    } catch (_) {
      // Prefs/container unavailable (e.g. during teardown) — skip the
      // sync-state read; it is refreshed on the next successful load.
    }
  }

  void _trackStreakMilestone(
    UserStatsEntity? previous,
    UserStatsEntity current,
  ) {
    if (previous == null) return;
    if (current.currentStreak <= previous.currentStreak) return;

    const milestones = [3, 7, 14, 30, 60, 100, 365];
    for (final milestone in milestones) {
      if (previous.currentStreak < milestone &&
          current.currentStreak >= milestone) {
        unawaited(
          ref
              .read(learningAnalyticsServiceProvider)
              .track(
                LearningAnalyticsEvents.streakMilestone,
                source: 'profile_stats',
                sourceId: 'streak_$milestone',
                metadata: {
                  'milestone': milestone,
                  'currentStreak': current.currentStreak,
                },
              ),
        );
      }
    }
  }

  void _trackStreakMaintained(
    UserStatsEntity? previous,
    UserStatsEntity current,
  ) {
    if (previous == null) return;
    if (current.currentStreak <= 0) return;
    if (current.lastActiveDate.isEmpty ||
        current.lastActiveDate == previous.lastActiveDate) {
      return;
    }

    unawaited(
      ref
          .read(learningAnalyticsServiceProvider)
          .track(
            LearningAnalyticsEvents.streakMaintained,
            source: 'profile_stats',
            sourceId: current.lastActiveDate,
            learnerLevel: current.learnerLevel,
            metadata: {
              'currentStreak': current.currentStreak,
              'previousStreak': previous.currentStreak,
            },
          ),
    );
  }

  /// Updates lastActiveDate and currentStreak based on today's date and practiceDates.
  UserStatsEntity _withStreakUpdate(UserStatsEntity stats) {
    final now = _now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final today = StreakWeekLogic.dateKey(todayDate);

    final updatedPracticeDates = _bumpPracticeDates(stats, today);
    final newStreak = StreakWeekLogic.deriveStreak(
      updatedPracticeDates,
      asOf: todayDate,
      lastActiveDate: stats.lastActiveDate,
      fallbackStreak: stats.currentStreak,
    );

    return stats.copyWith(
      lastActiveDate: today,
      currentStreak: newStreak,
      practiceDates: updatedPracticeDates,
    );
  }

  /// Adds [todayKey] to the practice-date log, keeping only the most recent
  /// [_practiceDateLogLimit] entries.
  Set<String> _bumpPracticeDates(UserStatsEntity stats, String todayKey) {
    const limit = 90;
    final dates = Set<String>.from(stats.practiceDates)..add(todayKey);
    if (dates.length <= limit) return dates;
    final sorted = dates.toList()..sort();
    return Set<String>.from(sorted.sublist(sorted.length - limit));
  }

  /// Resolves a category key from a categoryId for mastery tracking.
  String _normalizeCategoryKey(String categoryId) {
    final lower = categoryId.toLowerCase();
    if (lower.contains('alphabet') || lower.contains('letter')) {
      return 'alphabets';
    }
    if (lower.contains('number')) return 'numbers';
    if (lower.contains('word') || lower.contains('vocab')) return 'words';
    if (lower.contains('sentence') || lower.contains('phrase')) {
      return 'sentences';
    }
    if (lower.contains('rhyme')) return 'rhymes';
    return categoryId;
  }
}
