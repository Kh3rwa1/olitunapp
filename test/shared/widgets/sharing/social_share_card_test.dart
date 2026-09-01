import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/shared/widgets/sharing/share_card_payload.dart';
import 'package:itun/shared/widgets/sharing/social_share_card.dart';
import 'package:itun/shared/widgets/sharing/social_share_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (message) async {
          if (message.method == 'Clipboard.setData') {
            return null;
          }
          if (message.method == 'Clipboard.getData') {
            return {'text': 'mock'};
          }
          return null;
        });
  });

  group('SocialShareCard Visual & Payload Tests', () {
    testWidgets('renders Quiz Completion Share Card correctly', (tester) async {
      final payload = ShareCardPayload.quizResult(
        score: 9,
        total: 10,
        percentage: 90,
        stars: 30,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: SocialShareCard(payload: payload)),
          ),
        ),
      );

      expect(find.text('OLITUN • ᱚᱞ ᱪᱤᱠᱤ'), findsOneWidget);
      expect(find.text('Santali Quiz Completed! 🎉'), findsOneWidget);
      expect(find.text('Practicing Ol Chiki on Olitun'), findsOneWidget);
      expect(find.text('ᱚᱞ ᱪᱤᱠᱤ ᱪᱮᱫᱚᱜ ᱢᱮ'), findsOneWidget);
      expect(find.text('9 / 10 (90%)'), findsOneWidget);
      expect(find.text('+30 ⭐'), findsOneWidget);
      expect(
        find.text('Learn Santali (Ol Chiki) • olitun.app'),
        findsOneWidget,
      );
    });

    testWidgets('renders Streak Milestone Share Card correctly', (
      tester,
    ) async {
      final payload = ShareCardPayload.streakMilestone(streakDays: 14);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: SocialShareCard(payload: payload)),
          ),
        ),
      );

      expect(find.text('14 Day Streak! 🔥'), findsOneWidget);
      expect(find.text('14 Days'), findsOneWidget);
      expect(find.text('Top Learner 🏆'), findsOneWidget);
      expect(find.text('ᱫᱤᱱᱟᱹᱢ ᱦᱤᱞᱚᱜ ᱚᱞ ᱪᱤᱠᱤ'), findsOneWidget);
    });

    testWidgets('renders Badge Achievement Share Card correctly', (
      tester,
    ) async {
      final payload = ShareCardPayload.badgeAchievement(
        badgeName: 'Ol Chiki Master',
        description: 'Master all script strokes and phonetics.',
        iconEmoji: '🏆',
        category: 'LEARNING',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: SocialShareCard(payload: payload)),
          ),
        ),
      );

      expect(find.text('Ol Chiki Master Unlocked! 🏆'), findsOneWidget);
      expect(find.text('🏆'), findsOneWidget);
      expect(find.text('LEARNING'), findsOneWidget);
      expect(find.text('Verified ✅'), findsOneWidget);
    });
  });

  group('SocialShareModal State & Actions Tests', () {
    testWidgets('renders modal and handles copy text trigger', (tester) async {
      final payload = ShareCardPayload.streakMilestone(streakDays: 7);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () =>
                      SocialShareModal.show(context, payload: payload),
                  child: const Text('Open Modal'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Share Your Milestone'), findsOneWidget);
      expect(find.text('Share to Apps'), findsOneWidget);
      expect(find.text('Copy Text Summary'), findsOneWidget);

      await tester.tap(find.text('Copy Text Summary'));
      await tester.pumpAndSettle();

      expect(
        find.text('Share message copied to clipboard! 📋'),
        findsOneWidget,
      );
    });
  });
}
