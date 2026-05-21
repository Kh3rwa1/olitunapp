import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:itun/core/logging/app_logger.dart';
import '../../../../core/storage/hive_service.dart';

Future<String> fetchServerDate() async {
  try {
    final uri1 = Uri.parse('https://timeapi.io/api/Time/current/zone?timeZone=UTC');
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

final currentDateProvider = StateNotifierProvider<CurrentDateNotifier, String>((ref) {
  return CurrentDateNotifier();
});

class CurrentDateNotifier extends StateNotifier<String> {
  CurrentDateNotifier() : super(DateTime.now().toUtc().toIso8601String().substring(0, 10)) {
    syncDate();
  }

  Future<void> syncDate() async {
    final serverDate = await fetchServerDate();
    state = serverDate;
  }
}

class DailyMissionNotifier extends StateNotifier<bool> {
  final Ref _ref;
  final String _prefKey;

  DailyMissionNotifier(this._ref, this._prefKey) : super(false) {
    _loadState();
    _ref.listen<String>(currentDateProvider, (previous, next) {
      _loadState();
    });
  }

  void _loadState() {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final savedDate = prefs.getString(_prefKey) ?? '';
      final today = _ref.read(currentDateProvider);
      state = savedDate == today;
    } catch (_) {
      state = false;
    }
  }

  Future<void> setCompleted(bool completed) async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      if (completed) {
        final today = _ref.read(currentDateProvider);
        await prefs.setString(_prefKey, today);
        state = true;
      } else {
        await prefs.remove(_prefKey);
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

final lessonCompletedTodayProvider =
    StateNotifierProvider<DailyMissionNotifier, bool>((ref) {
      return DailyMissionNotifier(ref, 'mission_lesson_completed_date');
    });

final quizTakenTodayProvider =
    StateNotifierProvider<DailyMissionNotifier, bool>((ref) {
      return DailyMissionNotifier(ref, 'mission_quiz_taken_date');
    });

final bakhedListenedTodayProvider =
    StateNotifierProvider<DailyMissionNotifier, bool>((ref) {
      return DailyMissionNotifier(ref, 'mission_bakhed_listened_date');
    });
