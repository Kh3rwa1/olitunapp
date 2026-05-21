import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/circle_repository.dart';
import '../../domain/circle_models.dart';

final weeklyCircleProvider = FutureProvider<WeeklyCircle>((ref) async {
  final repository = ref.watch(circleRepositoryProvider);
  return repository.assignUserToWeeklyCircle();
});

class CircleLeaderboardNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final CircleRepository _repository;

  CircleLeaderboardNotifier(this._repository)
    : super(const AsyncValue.loading()) {
    refreshLeaderboard();
  }

  Future<void> refreshLeaderboard() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repository.getCircleLeaderboard();
      state = AsyncValue.data(data);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> recordEvent(
    String eventType,
    String sourceId, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _repository.recordCircleEvent(
        eventType,
        sourceId,
        metadata: metadata,
      );
      // Refresh to update ranks and points immediately
      await refreshLeaderboard();
    } catch (e) {
      // Silently handle event registration errors in UI, log it
    }
  }
}

final circleLeaderboardProvider =
    StateNotifierProvider<
      CircleLeaderboardNotifier,
      AsyncValue<Map<String, dynamic>>
    >((ref) {
      final repository = ref.watch(circleRepositoryProvider);
      return CircleLeaderboardNotifier(repository);
    });

final currentCircleRankProvider = Provider<int>((ref) {
  final leaderboardAsync = ref.watch(circleLeaderboardProvider);
  return leaderboardAsync.maybeWhen(
    data: (data) => data['rank'] ?? 1,
    orElse: () => 1,
  );
});

final pointsToNextRankProvider = Provider<int>((ref) {
  final leaderboardAsync = ref.watch(circleLeaderboardProvider);
  return leaderboardAsync.maybeWhen(
    data: (data) => data['pointsToNextRank'] ?? 0,
    orElse: () => 0,
  );
});
