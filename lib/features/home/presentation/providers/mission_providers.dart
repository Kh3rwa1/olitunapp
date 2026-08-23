import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:itun/core/logging/app_logger.dart';
import '../../../../core/storage/hive_service.dart';

Future<String> fetchServerDate() async {
  try {
    final uri1 = Uri.parse(
      'https://timeapi.io/api/Time/current/zone?timeZone=UTC',
    );
    final response1 = await http.get(uri1).timeout(const Duration(seconds: 3));
    if (response1.statusCode == 200) {
      final data = jsonDecode(response1.body);
      if (data is Map && data['dateTime'] != null) {
        return (data['dateTime'] as String).substring(0, 10);
      }
    }
  } catch (e) {
    AppLogger.debug('ServerTime: Failed timeapi.io: $e');
  }

  try {
    final uri2 = Uri.parse('https://worldtimeapi.org/api/timezone/Etc/UTC');
    final response2 = await http.get(uri2).timeout(const Duration(seconds: 3));
    if (response2.statusCode == 200) {
      final data = jsonDecode(response2.body);
      if (data is Map && data['datetime'] != null) {
        return (data['datetime'] as String).substring(0, 10);
      }
    }
  } catch (e) {
    AppLogger.debug('ServerTime: Failed worldtimeapi.org: $e');
  }

  // Timezone-safe fallback to UTC date (ignoring local manipulation)
  return DateTime.now().toUtc().toIso8601String().substring(0, 10);
}

final currentDateProvider = NotifierProvider<CurrentDateNotifier, String>(
  CurrentDateNotifier.new,
);

class CurrentDateNotifier extends Notifier<String> {
  bool _disposed = false;

  @override
  String build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    syncDate();
    return DateTime.now().toUtc().toIso8601String().substring(0, 10);
  }

  Future<void> syncDate() async {
    final serverDate = await fetchServerDate();
    if (_disposed) return;
    state = serverDate;
  }
}

/// Base for the four daily-mission flags. Each concrete notifier supplies
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
    } catch (_) {
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

class QuickWinCompletedTodayNotifier extends DailyMissionNotifier {
  @override
  String get prefKey => 'mission_quick_win_completed_date';
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

final quickWinCompletedTodayProvider =
    NotifierProvider<QuickWinCompletedTodayNotifier, bool>(
      QuickWinCompletedTodayNotifier.new,
    );
