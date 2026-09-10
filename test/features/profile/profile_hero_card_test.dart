import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:itun/features/profile/domain/entities/profile_avatar.dart';
import 'package:itun/features/profile/domain/entities/weekly_leaderboard_entity.dart';
import 'package:itun/features/profile/presentation/providers/weekly_leaderboard_provider.dart';
import 'package:itun/features/profile/presentation/widgets/profile_hero_card.dart';

WeeklyLeaderboardEntity _leaderboard({int? rank = 2, int points = 75}) {
  return WeeklyLeaderboardEntity(
    rank: rank,
    points: points,
    totalParticipants: 8,
    weekStart: '2026-09-07',
    weekEnd: '2026-09-13',
    generatedAt: DateTime.utc(2026, 9, 10, 5, 30),
    breakdown: rank == null ? const {} : const {'quiz_completed': 75},
  );
}

Widget _wrap({
  String? memberSince,
  WeeklyLeaderboardEntity? leaderboard,
  bool leaderboardError = false,
  String avatarId = kDefaultAvatarId,
}) {
  return ProviderScope(
    overrides: [
      weeklyLeaderboardProvider.overrideWith((ref) async {
        if (leaderboardError) throw StateError('offline');
        return leaderboard ?? _leaderboard();
      }),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ProfileHeroCard(
            userName: 'Learner',
            avatarColors: const [Color(0xFF34C77B), Color(0xFF1B9E5A)],
            avatarId: avatarId,
            level: 'Beginner',
            levelIndex: 0,
            memberSince: memberSince,
            overallProgress: 0,
            isDark: false,
            onEditName: () {},
            onEditAvatar: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the Lottie avatar animation, never an emoji', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();
    expect(find.byType(LottieBuilder), findsOneWidget);
    expect(find.text('👶'), findsNothing);
  });

  testWidgets('shows the name initial when no avatar is selected', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(avatarId: ''));
    await tester.pumpAndSettle();
    expect(find.text('L'), findsOneWidget);
    expect(find.byType(LottieBuilder), findsNothing);
  });

  testWidgets('shows real weekly rank and points in the existing badge', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.text('Leaderboard · #2 · 75 pts'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
    expect(find.text('Beginner'), findsNothing);
  });

  testWidgets('shows unranked instead of inventing a rank', (tester) async {
    await tester.pumpWidget(
      _wrap(leaderboard: _leaderboard(rank: null, points: 0)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Leaderboard · Unranked'), findsOneWidget);
    expect(find.textContaining('#'), findsNothing);
  });

  testWidgets('shows unavailable instead of stale or fake data on error', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(leaderboardError: true));
    await tester.pumpAndSettle();
    expect(find.text('Leaderboard unavailable'), findsOneWidget);
    expect(find.textContaining('pts'), findsNothing);
  });

  testWidgets('hides the Since line when creation date is unknown', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.textContaining('Since'), findsNothing);
  });

  testWidgets('shows formatted Since date when known', (tester) async {
    await tester.pumpWidget(_wrap(memberSince: '2024-04-01'));
    await tester.pumpAndSettle();
    expect(find.text('Since Apr 01, 2024'), findsOneWidget);
  });
}
