import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/logging/app_logger.dart';
import '../../../../core/storage/hive_service.dart';

/// Clock used for the daily-mission date. Overridable in tests.
final missionClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Today's UTC date (`yyyy-MM-dd`) for the daily-mission flags.
///
/// This is the **device clock** (converted to UTC); it is not tamper-proof —
/// a learner who changes the device date can re-open a mission. That is
/// acceptable because missions are a local nudge, not a reward authority
/// (rewards and streaks are server-authoritative). No third-party time API
/// is called: those were blocked by the web CSP, and the Worker exposes no
/// server time. Evaluated once per provider lifetime, as before.
final currentDateProvider = Provider<String>((ref) {
  final now = ref.watch(missionClockProvider)();
  return now.toUtc().toIso8601String().substring(0, 10);
});

/// Base for the daily-practice flags (lesson / quiz / bakhed completed
/// today). These drive NextBestActionCard decisions and the
/// "practiced today" reminder suppression. Each concrete notifier supplies
/// its own [prefKey]; separate provider instances keep per-provider test
/// overrides possible.
abstract class DailyMissionNotifier extends Notifier<bool> {
  String get prefKey;

  @override
  bool build() {
    try {
      // Rebuild when the server-synced date rolls over.
      final today = ref.watch(currentDateProvider);
      final prefs = ref.read(sharedPreferencesProvider);
      final savedDate = prefs.getString(prefKey) ?? '';
      return savedDate == today;
    } catch (_) {
      // Prefs unavailable (e.g. early teardown) — mission starts incomplete.
      return false;
    }
  }

  Future<void> setCompleted(bool completed) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final today = ref.read(currentDateProvider);
      if (completed) {
        await prefs.setString(prefKey, today);
        state = true;
      } else {
        await prefs.remove(prefKey);
        state = false;
      }
    } catch (e) {
      AppLogger.debug('Mission: failed to persist : ');
      state = completed;
    }
  }

  Future<void> toggle() async {
    await setCompleted(!state);
  }
}

class LessonCompletedTodayNotifier extends DailyMissionNotifier {
  @override
  String get prefKey => 'mission_lesson_completed_date';
}

class QuizTakenTodayNotifier extends DailyMissionNotifier {
  @override
  String get prefKey => 'mission_quiz_taken_date';
}

class BakhedListenedTodayNotifier extends DailyMissionNotifier {
  @override
  String get prefKey => 'mission_bakhed_listened_date';
}

final lessonCompletedTodayProvider =
    NotifierProvider<LessonCompletedTodayNotifier, bool>(
      LessonCompletedTodayNotifier.new,
    );

final quizTakenTodayProvider = NotifierProvider<QuizTakenTodayNotifier, bool>(
  QuizTakenTodayNotifier.new,
);

final bakhedListenedTodayProvider =
    NotifierProvider<BakhedListenedTodayNotifier, bool>(
      BakhedListenedTodayNotifier.new,
    );
