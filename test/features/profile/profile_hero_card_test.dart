import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/profile/presentation/widgets/profile_hero_card.dart';

Widget _wrap({String? memberSince}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: ProfileHeroCard(
          userName: 'Learner',
          avatarColors: const [Color(0xFF34C77B), Color(0xFF1B9E5A)],
          avatarEmoji: '👶',
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
  );
}

void main() {
  testWidgets('hides the Since line when creation date is unknown', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    expect(find.textContaining('Since'), findsNothing);
  });

  testWidgets('shows formatted Since date when known', (tester) async {
    await tester.pumpWidget(_wrap(memberSince: '2024-04-01'));
    expect(find.text('Since Apr 01, 2024'), findsOneWidget);
  });
}
