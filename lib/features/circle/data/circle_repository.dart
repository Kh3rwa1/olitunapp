import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:appwrite/appwrite.dart';
import '../../../core/auth/appwrite_auth_service.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/storage/hive_service.dart';
import '../domain/circle_models.dart';

class CircleRepository {
  final Ref _ref;
  static const String _localLeaderboardKey = 'local_weekly_circle_leaderboard';
  static const String _localCircleKey = 'local_weekly_circle';

  CircleRepository(this._ref);

  String _getWeekId() {
    final now = DateTime.now();
    // Use ISO week number or year-week format
    final year = now.year;
    // Calculate week of year
    final firstDayOfYear = DateTime(year);
    final daysOffset = firstDayOfYear.weekday - 1;
    final firstMonday = firstDayOfYear.subtract(Duration(days: daysOffset));
    final daysSinceFirstMonday = now.difference(firstMonday).inDays;
    final week = (daysSinceFirstMonday / 7).floor() + 1;
    return '$year-W$week';
  }

  Future<WeeklyCircle> assignUserToWeeklyCircle(String userId) async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none)) {
        return _getFallbackCircle();
      }

      // If connected, attempt to call Appwrite cloud function
      final authService = _ref.read(appwriteAuthServiceProvider);
      final functions = Functions(authService.client);

      final response = await functions.createExecution(
        functionId: 'assignUserToWeeklyCircle',
        body: jsonEncode({'userId': userId, 'weekId': _getWeekId()}),
      );

      if (response.status.name == 'completed') {
        final decoded = jsonDecode(response.responseBody);
        final circle = WeeklyCircle.fromMap(decoded['circle']);

        // Cache locally
        final prefs = _ref.read(sharedPreferencesProvider);
        await prefs.setString(_localCircleKey, jsonEncode(circle.toMap()));

        return circle;
      }
    } catch (e) {
      AppLogger.debug(
        'CircleRepository: assignUserToWeeklyCircle failed: $e. Using local simulation.',
      );
    }
    return _getFallbackCircle();
  }

  Future<void> recordCircleEvent(
    String userId,
    String eventType,
    String sourceId, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none)) {
        await _recordCircleEventLocally(eventType, sourceId);
        return;
      }

      final authService = _ref.read(appwriteAuthServiceProvider);
      final functions = Functions(authService.client);

      final payload = {
        'userId': userId,
        'weekId': _getWeekId(),
        'eventType': eventType,
        'sourceId': sourceId,
        'metadata': metadata ?? {},
      };

      final response = await functions.createExecution(
        functionId: 'recordCircleEvent',
        body: jsonEncode(payload),
      );

      if (response.status.name != 'completed') {
        throw Exception('Cloud function failed to execute');
      }

      // Sync local state as well
      await _recordCircleEventLocally(eventType, sourceId);
    } catch (e) {
      AppLogger.debug(
        'CircleRepository: recordCircleEvent failed: $e. Using local simulation.',
      );
      await _recordCircleEventLocally(eventType, sourceId);
    }
  }

  Future<Map<String, dynamic>> getCircleLeaderboard(
    String userId, {
    String? weekId,
  }) async {
    final activeWeekId = weekId ?? _getWeekId();
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none)) {
        return _getFallbackLeaderboard(activeWeekId);
      }

      final authService = _ref.read(appwriteAuthServiceProvider);
      final functions = Functions(authService.client);

      final response = await functions.createExecution(
        functionId: 'getCircleLeaderboard',
        body: jsonEncode({'userId': userId, 'weekId': activeWeekId}),
      );

      if (response.status.name == 'completed') {
        final decoded = jsonDecode(response.responseBody);

        // Cache locally
        final prefs = _ref.read(sharedPreferencesProvider);
        await prefs.setString(_localLeaderboardKey, response.responseBody);

        return decoded;
      }
    } catch (e) {
      AppLogger.debug(
        'CircleRepository: getCircleLeaderboard failed: $e. Using local simulation.',
      );
    }
    return _getFallbackLeaderboard(activeWeekId);
  }

  // ─── Local simulations for offline / fallback ───

  WeeklyCircle _getFallbackCircle() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    return WeeklyCircle(
      circleId: 'fallback_circle_id',
      weekId: _getWeekId(),
      learnerLevel: 'beginner',
      activityTier: 'medium',
      scriptMode: 'latin',
      memberCount: 4,
      targetMembers: 20,
      maxMembers: 20,
      status: 'open',
      createdAt: now,
      startsAt: weekStart,
      endsAt: weekEnd,
    );
  }

  Future<void> _recordCircleEventLocally(
    String eventType,
    String sourceId,
  ) async {
    // Add point mapping locally
    int points = 0;
    switch (eventType) {
      case 'lesson_completed':
        points = 40;
        break;
      case 'quiz_completed':
        points = 25;
        break;
      case 'quiz_high_score_90':
        points = 10;
        break;
      case 'bakhed_completed_80_percent':
        points = 20;
        break;
      case 'daily_mission_completed':
        points = 30;
        break;
      case 'mistake_review_completed':
        points = 15;
        break;
      case 'streak_maintained':
        points = 10;
        break;
      case 'quick_win_completed':
        points = 10;
        break;
    }

    final prefs = _ref.read(sharedPreferencesProvider);
    final int currentPoints =
        prefs.getInt('local_circle_points_${_getWeekId()}') ?? 0;
    await prefs.setInt(
      'local_circle_points_${_getWeekId()}',
      currentPoints + points,
    );
  }

  Map<String, dynamic> _getFallbackLeaderboard(String weekId) {
    final prefs = _ref.read(sharedPreferencesProvider);
    final userPoints = prefs.getInt('local_circle_points_$weekId') ?? 0;
    final now = DateTime.now();
    final endsAt = now.add(Duration(days: 7 - now.weekday)).toIso8601String();

    // Benchmark rows as required by brief
    // Starter Circle: Benchmarks help you track progress while more learners join.
    final List<Map<String, dynamic>> benchmarks = [
      {
        'circleId': 'fallback_circle_id',
        'userId': 'benchmark_1',
        'weekId': weekId,
        'displayName': 'Weekly Target 🦚',
        'anonymousName': 'Weekly Target',
        'avatarEmoji': '🦚',
        'learnerLevel': 'beginner',
        'circlePoints': 500,
        'starsThisWeek': 120,
        'lessonsCompleted': 4,
        'quizzesTaken': 2,
        'bakhedListened': 1,
        'missionDaysCompleted': 3,
        'mistakeReviewsCompleted': 1,
        'rank': 1,
        'joinedAt': now.toIso8601String(),
        'lastActiveAt': now.toIso8601String(),
      },
      {
        'circleId': 'fallback_circle_id',
        'userId': 'current_user',
        'weekId': weekId,
        'displayName': 'You ⭐',
        'anonymousName': 'You',
        'avatarEmoji': '⭐',
        'learnerLevel': 'beginner',
        'circlePoints': userPoints,
        'starsThisWeek': 0,
        'lessonsCompleted': 0,
        'quizzesTaken': 0,
        'bakhedListened': 0,
        'missionDaysCompleted': 0,
        'mistakeReviewsCompleted': 0,
        'rank': 2,
        'joinedAt': now.toIso8601String(),
        'lastActiveAt': now.toIso8601String(),
      },
      {
        'circleId': 'fallback_circle_id',
        'userId': 'benchmark_2',
        'weekId': weekId,
        'displayName': 'Average Learner 🌿',
        'anonymousName': 'Average Learner',
        'avatarEmoji': '🌿',
        'learnerLevel': 'beginner',
        'circlePoints': 260,
        'starsThisWeek': 50,
        'lessonsCompleted': 2,
        'quizzesTaken': 1,
        'bakhedListened': 0,
        'missionDaysCompleted': 1,
        'mistakeReviewsCompleted': 0,
        'rank': 3,
        'joinedAt': now.toIso8601String(),
        'lastActiveAt': now.toIso8601String(),
      },
      {
        'circleId': 'fallback_circle_id',
        'userId': 'benchmark_3',
        'weekId': weekId,
        'displayName': 'Starter Goal 🔥',
        'anonymousName': 'Starter Goal',
        'avatarEmoji': '🔥',
        'learnerLevel': 'beginner',
        'circlePoints': 150,
        'starsThisWeek': 30,
        'lessonsCompleted': 1,
        'quizzesTaken': 0,
        'bakhedListened': 0,
        'missionDaysCompleted': 1,
        'mistakeReviewsCompleted': 0,
        'rank': 4,
        'joinedAt': now.toIso8601String(),
        'lastActiveAt': now.toIso8601String(),
      },
    ];

    // Sort benchmarks by points desc
    benchmarks.sort(
      (a, b) => (b['circlePoints'] as int).compareTo(a['circlePoints'] as int),
    );

    // Re-assign ranks based on sorted order
    var userRank = 1;
    for (var i = 0; i < benchmarks.length; i++) {
      benchmarks[i]['rank'] = i + 1;
      if (benchmarks[i]['userId'] == 'current_user') {
        userRank = i + 1;
      }
    }

    final pointsToNextRank = userRank > 1
        ? (benchmarks[userRank - 2]['circlePoints'] as int) - userPoints
        : 0;

    return {
      'circle': {
        'circleId': 'fallback_circle_id',
        'weekId': weekId,
        'learnerLevel': 'beginner',
        'activityTier': 'medium',
        'scriptMode': 'latin',
        'memberCount': 4,
        'targetMembers': 20,
        'maxMembers': 20,
        'status': 'open',
        'createdAt': now.toIso8601String(),
        'startsAt': now
            .subtract(Duration(days: now.weekday - 1))
            .toIso8601String(),
        'endsAt': endsAt,
      },
      'currentUserMember': benchmarks.firstWhere(
        (element) => element['userId'] == 'current_user',
      ),
      'leaderboard': benchmarks,
      'pointsToNextRank': pointsToNextRank,
      'rank': userRank,
      'totalMembers': 4,
      'endsAt': endsAt,
    };
  }
}

// Provider
final circleRepositoryProvider = Provider<CircleRepository>((ref) {
  return CircleRepository(ref);
});
