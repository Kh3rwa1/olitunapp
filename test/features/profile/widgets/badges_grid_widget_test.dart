import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/profile/presentation/widgets/badges_grid_widget.dart';
import 'package:itun/shared/providers/gamification_content_provider.dart';

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

  const testStats = UserStatsEntity(
    practicedLetters: {'ᱚ', 'ᱛ', 'ᱜ', 'ᱝ'},
    completedLessons: {'lesson_1', 'lesson_2'},
    quizHistory: {},
    categoryMastery: {},
    totalLearningMinutes: 120,
    lastActiveDate: '2026-09-01',
    currentStreak: 7,
    totalStars: 150,
    completedMissionsDates: {'2026-08-30', '2026-08-31', '2026-09-01'},
  );

  group('BadgesGridWidget & BadgeDetailDialog Tests', () {
    testWidgets('renders category filter pills and badge items', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userGamificationSummaryProvider.overrideWith(
              (ref) => const UserGamificationSummary(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BadgesGridWidget(stats: testStats, isDark: false),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('LEARNING'), findsOneWidget);
      expect(find.text('CULTURE'), findsOneWidget);
      expect(find.text('HABIT'), findsOneWidget);
      expect(find.text('First Step'), findsOneWidget);
    });

    testWidgets('filters badges on category pill tap', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userGamificationSummaryProvider.overrideWith(
              (ref) => const UserGamificationSummary(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BadgesGridWidget(stats: testStats, isDark: false),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap CULTURE category
      await tester.tap(find.text('CULTURE'));
      await tester.pumpAndSettle();

      expect(find.text('Cultural Spark'), findsOneWidget);
      expect(find.text('First Step'), findsNothing);
    });

    testWidgets('opens BadgeDetailDialog and triggers Share Achievement', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userGamificationSummaryProvider.overrideWith(
              (ref) => const UserGamificationSummary(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BadgesGridWidget(stats: testStats, isDark: false),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap an unlocked badge (First Step)
      await tester.tap(find.text('First Step'));
      await tester.pumpAndSettle();

      expect(find.text('Complete your first Santali lesson.'), findsOneWidget);
      expect(find.text('Share Achievement'), findsOneWidget);

      // Tap Share Achievement
      await tester.tap(find.text('Share Achievement'));
      await tester.pumpAndSettle();

      expect(find.text('Share Your Milestone'), findsOneWidget);
      expect(find.text('First Step Unlocked! 🏆'), findsOneWidget);
    });
  });
}
