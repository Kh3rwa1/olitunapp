import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/api/appwrite_functions_service.dart';
import 'package:itun/features/profile/domain/entities/weekly_leaderboard_entity.dart';

import 'user_stats_provider.dart';

const _gamificationSummaryFunctionId = 'getUserGamificationSummary';
const _leaderboardRefreshInterval = Duration(minutes: 5);
const _leaderboardRequestTimeout = Duration(seconds: 10);

WeeklyLeaderboardEntity parseWeeklyLeaderboardExecution(
  FunctionExecutionResult execution,
) {
  if (!execution.isCompleted || execution.statusCode != 200) {
    throw StateError('Live leaderboard request failed.');
  }
  final body = execution.bodyJson;
  if (body == null || body['ok'] != true) {
    throw StateError('Live leaderboard response was unsuccessful.');
  }
  final rawLeaderboard = body['leaderboard'];
  if (rawLeaderboard is! Map) {
    throw const FormatException('Live leaderboard payload is missing.');
  }
  return WeeklyLeaderboardEntity.fromJson(
    Map<String, dynamic>.from(rawLeaderboard),
  );
}

final weeklyLeaderboardProvider =
    FutureProvider.autoDispose<WeeklyLeaderboardEntity>((ref) async {
      // Refresh after real local learning progress changes and periodically
      // while the profile remains mounted.
      ref.watch(
        userStatsProvider.select((value) {
          final stats = value.valueOrNull;
          return (
            stats?.totalStars,
            stats?.lessonsCompletedCount,
            stats?.quizzesCompletedCount,
            stats?.practiceDates.length,
            stats?.completedMissionsDates.length,
          );
        }),
      );
      final refreshTimer = Timer(
        _leaderboardRefreshInterval,
        ref.invalidateSelf,
      );
      ref.onDispose(refreshTimer.cancel);

      final execution = await ref
          .watch(appwriteFunctionsServiceProvider)
          .execute(
            _gamificationSummaryFunctionId,
            body: const {'scope': 'leaderboard'},
            usePost: true,
          )
          .timeout(_leaderboardRequestTimeout);
      return parseWeeklyLeaderboardExecution(execution);
    });
