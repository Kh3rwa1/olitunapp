import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/profile/presentation/widgets/live_achievements_section.dart';
import 'package:itun/shared/providers/gamification_content_provider.dart';

Widget _wrap(UserGamificationSummary summary) => ProviderScope(
  overrides: [
    userGamificationSummaryProvider.overrideWith((ref) => summary),
  ],
  child: const MaterialApp(
    home: Scaffold(
      body: SizedBox(width: 420, child: LiveAchievementsSection()),
    ),
  ),
);

void main() {
  testWidgets('renders only real badges returned by Appwrite', (tester) async {
    const summary = UserGamificationSummary(
      badges: [
        UserGamificationBadge(
          badgeId: 'real_reader',
          name: 'Verified Reader',
          description: 'Verified by the backend.',
          category: 'learning',
          icon: '🏆',
          progress: 3,
          target: 10,
          rewardStars: 25,
          isUnlocked: false,
          unlockedAt: '',
        ),
      ],
    );

    await tester.pumpWidget(_wrap(summary));
    await tester.pumpAndSettle();

    expect(find.text('Verified Reader'), findsOneWidget);
    expect(find.text('3 of 10'), findsOneWidget);
    expect(find.text('First Step'), findsNothing);
  });

  testWidgets('shows an honest empty state without invented progress', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(UserGamificationSummary.empty));
    await tester.pumpAndSettle();

    expect(find.textContaining('No verified achievements yet'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
