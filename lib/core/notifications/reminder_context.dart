import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_types.dart';

/// Learner state that decides what a reminder says (and whether it fires
/// today at all). Built by the home layer from real stats; defaults to
/// "nothing known" so copy never claims a streak that does not exist.
class ReminderContext {
  const ReminderContext({
    this.streak = 0,
    this.dueReviews = 0,
    this.practicedToday = false,
    this.lastPracticeAt,
  });

  /// Nothing known: no streak, no due reviews, not practiced today.
  static const ReminderContext empty = ReminderContext();

  /// Current honest streak in days (0 when none / unknown).
  final int streak;

  /// Spaced-repetition items due right now (0 when none / unknown).
  final int dueReviews;

  /// Whether the learner already practiced today (lesson, quiz or bakhed).
  final bool practicedToday;

  /// Local date of the learner's most recent practice, if any. Lapse
  /// reminders count from here, not from the current launch, so opening the
  /// app without practising never pushes them back.
  final DateTime? lastPracticeAt;

  ReminderContext copyWith({
    int? streak,
    int? dueReviews,
    bool? practicedToday,
    DateTime? lastPracticeAt,
  }) {
    return ReminderContext(
      streak: streak ?? this.streak,
      dueReviews: dueReviews ?? this.dueReviews,
      practicedToday: practicedToday ?? this.practicedToday,
      lastPracticeAt: lastPracticeAt ?? this.lastPracticeAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderContext &&
      other.streak == streak &&
      other.dueReviews == dueReviews &&
      other.practicedToday == practicedToday;

  @override
  int get hashCode => Object.hash(streak, dueReviews, practicedToday);

  @override
  String toString() =>
      'ReminderContext(streak: $streak, dueReviews: $dueReviews, '
      'practicedToday: $practicedToday, lastPracticeAt: $lastPracticeAt)';
}

/// Latest known [ReminderContext]. The home layer (which may read feature
/// providers) keeps it current; the settings providers (shared/) read it so
/// a reschedule from Settings keeps honest copy without importing features.
final reminderContextProvider = StateProvider<ReminderContext>(
  (ref) => ReminderContext.empty,
);

/// Pure decisions shared by startup, settings and the home layer.
class ReminderPolicy {
  const ReminderPolicy._();

  /// Prefs keys written by the daily-practice flags
  /// (features/home/.../mission_providers.dart), value = UTC `yyyy-MM-dd`.
  static const List<String> practiceDateKeys = [
    'mission_lesson_completed_date',
    'mission_quiz_taken_date',
    'mission_bakhed_listened_date',
  ];

  /// Prefs key for the user's reminder frequency choice.
  static const String frequencyPrefKey = 'notification_frequency';

  /// Default cadence for anyone who has not chosen: one reminder a day.
  static const NotificationFrequency defaultFrequency =
      NotificationFrequency.once;

  /// UTC date key used by the practice flags.
  static String dateKey(DateTime now) =>
      now.toUtc().toIso8601String().substring(0, 10);

  /// True when any practice flag was written for today's UTC date.
  static bool practicedTodayFromPrefs(
    SharedPreferences prefs, {
    DateTime? now,
  }) {
    final today = dateKey(now ?? DateTime.now());
    for (final key in practiceDateKeys) {
      if (prefs.getString(key) == today) return true;
    }
    return false;
  }

  /// Most recent practice date written by the practice flags (local
  /// midnight of that UTC date key), or null when the learner never practised.
  static DateTime? lastPracticeFromPrefs(SharedPreferences prefs) {
    DateTime? latest;
    for (final key in practiceDateKeys) {
      final raw = prefs.getString(key);
      if (raw == null || raw.length < 10) continue;
      final parsed = DateTime.tryParse(raw.substring(0, 10));
      if (parsed == null) continue;
      final local = DateTime(parsed.year, parsed.month, parsed.day);
      if (latest == null || local.isAfter(latest)) latest = local;
    }
    return latest;
  }

  /// Parses a stored frequency name; unknown or missing → [defaultFrequency].
  static NotificationFrequency parseFrequency(String? name) {
    if (name == null || name.isEmpty) return defaultFrequency;
    for (final value in NotificationFrequency.values) {
      if (value.name == name) return value;
    }
    return defaultFrequency;
  }
}
