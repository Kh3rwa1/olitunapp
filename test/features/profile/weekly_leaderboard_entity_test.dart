import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/profile/domain/entities/weekly_leaderboard_entity.dart';

Map<String, dynamic> _payload({
  int? rank = 2,
  int points = 75,
  int totalParticipants = 8,
}) {
  return {
    'rank': rank,
    'points': points,
    'totalParticipants': totalParticipants,
    'weekStart': '2026-09-07',
    'weekEnd': '2026-09-13',
    'generatedAt': '2026-09-10T05:30:00.000Z',
    'breakdown': {'quiz_completed': 75},
  };
}

void main() {
  test('parses a ranked live leaderboard payload', () {
    final entity = WeeklyLeaderboardEntity.fromJson(_payload());
    expect(entity.rank, 2);
    expect(entity.points, 75);
    expect(entity.totalParticipants, 8);
    expect(entity.badgeLabel, 'Leaderboard · #2 · 75 pts');
    expect(entity.breakdown, {'quiz_completed': 75});
  });

  test('represents a real zero-point user as unranked', () {
    final entity = WeeklyLeaderboardEntity.fromJson(
      _payload(rank: null, points: 0),
    );
    expect(entity.isRanked, isFalse);
    expect(entity.badgeLabel, 'Leaderboard · Unranked');
  });

  test('rejects contradictory or fabricated rank payloads', () {
    expect(
      () => WeeklyLeaderboardEntity.fromJson(
        _payload(rank: 9, totalParticipants: 8),
      ),
      throwsFormatException,
    );
    expect(
      () => WeeklyLeaderboardEntity.fromJson(_payload(rank: null, points: 10)),
      throwsFormatException,
    );
  });
}
