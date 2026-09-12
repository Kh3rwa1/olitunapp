import 'package:equatable/equatable.dart';

class WeeklyLeaderboardEntity extends Equatable {
  const WeeklyLeaderboardEntity({
    required this.rank,
    required this.points,
    required this.totalParticipants,
    required this.weekStart,
    required this.weekEnd,
    required this.generatedAt,
    required this.breakdown,
  });

  final int? rank;
  final int points;
  final int totalParticipants;
  final String weekStart;
  final String weekEnd;
  final DateTime generatedAt;
  final Map<String, int> breakdown;

  bool get isRanked => rank != null;

  String get badgeLabel => isRanked
      ? 'Leaderboard · #$rank · $points pts'
      : 'Leaderboard · Unranked';

  factory WeeklyLeaderboardEntity.fromJson(Map<String, dynamic> json) {
    int readNonNegativeInt(String key) {
      final value = json[key];
      if (value is! num || value.isNaN || value.isInfinite) {
        throw FormatException('Invalid leaderboard field: $key');
      }
      final integer = value.toInt();
      if (integer != value || integer < 0) {
        throw FormatException('Invalid leaderboard field: $key');
      }
      return integer;
    }

    String readDateKey(String key) {
      final value = json[key];
      if (value is! String ||
          !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
          DateTime.tryParse(value) == null) {
        throw FormatException('Invalid leaderboard field: $key');
      }
      return value;
    }

    final rawRank = json['rank'];
    final rank = rawRank == null ? null : readNonNegativeInt('rank');
    final points = readNonNegativeInt('points');
    final totalParticipants = readNonNegativeInt('totalParticipants');
    final weekStart = readDateKey('weekStart');
    final weekEnd = readDateKey('weekEnd');
    final generatedAtRaw = json['generatedAt'];
    final generatedAt = generatedAtRaw is String
        ? DateTime.tryParse(generatedAtRaw)
        : null;
    if (generatedAt == null || weekStart.compareTo(weekEnd) > 0) {
      throw const FormatException('Invalid leaderboard date range');
    }
    if (rank != null &&
        (rank == 0 || rank > totalParticipants || points == 0)) {
      throw const FormatException('Invalid leaderboard rank');
    }
    if (rank == null && points != 0) {
      throw const FormatException('Unranked leaderboard entry has points');
    }

    final rawBreakdown = json['breakdown'];
    if (rawBreakdown is! Map) {
      throw const FormatException('Invalid leaderboard breakdown');
    }
    final breakdown = <String, int>{};
    for (final entry in rawBreakdown.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (key.isEmpty || value is! num || value.toInt() != value || value < 0) {
        throw const FormatException('Invalid leaderboard breakdown');
      }
      breakdown[key] = value.toInt();
    }

    return WeeklyLeaderboardEntity(
      rank: rank,
      points: points,
      totalParticipants: totalParticipants,
      weekStart: weekStart,
      weekEnd: weekEnd,
      generatedAt: generatedAt.toUtc(),
      breakdown: Map.unmodifiable(breakdown),
    );
  }

  @override
  List<Object?> get props => [
    rank,
    points,
    totalParticipants,
    weekStart,
    weekEnd,
    generatedAt,
    breakdown,
  ];
}
