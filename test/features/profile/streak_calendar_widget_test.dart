import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/profile/domain/entities/quiz_result_entity.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/profile/domain/streak_week_logic.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/quizzes_provider.dart';
import 'package:itun/features/profile/presentation/widgets/streak_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserStatsEntity _stats({
  int streak = 0,
  Set<String> practiceDates = const {},
  String lastActiveDate = '',
  Map<String, QuizResultEntity> quizHistory = const {},
}) {
  return UserStatsEntity(
    practicedLetters: {},
    completedLessons: {},
    quizHistory: quizHistory,
    categoryMastery: {},
    totalLearningMinutes: 0,
    lastActiveDate: lastActiveDate,
    currentStreak: streak,
    totalStars: 0,
    practiceDates: practiceDates,
  );
}

Future<Widget> wrap(
  UserStatsEntity stats, {
  List<Override> extraOverrides = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      // Keep the quizzes catalogue inert unless a test supplies real data.
      quizzesByIdProvider.overrideWithValue(const AsyncValue.data({})),
      ...extraOverrides,
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(child: StreakCalendar(stats: stats)),
      ),
    ),
  );
}

void main() {
  testWidgets('idle state shows Start Your Streak, never Active', (
    tester,
  ) async {
    await tester.pumpWidget(await wrap(_stats()));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Start Your Streak'), findsOneWidget);
    expect(find.text('Weekly Streak Active'), findsNothing);
    expect(find.text('Start learning'), findsOneWidget);
    expect(find.text('0 DAYS'), findsOneWidget);
  });

  testWidgets('active state shows Weekly Streak Active with streak count', (
    tester,
  ) async {
    await tester.pumpWidget(
      await wrap(_stats(streak: 3, lastActiveDate: '2026-08-23')),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Weekly Streak Active'), findsOneWidget);
    expect(find.text('Start Your Streak'), findsNothing);
    expect(find.text('3 DAYS'), findsOneWidget);
    expect(find.text('Start learning'), findsNothing);
  });

  testWidgets('tapping a practiced day opens the detail sheet', (tester) async {
    final semantics = tester.ensureSemantics();
    final now = DateTime.now();
    final todayKey = StreakWeekLogic.dateKey(now);

    await tester.pumpWidget(
      await wrap(
        _stats(streak: 1, lastActiveDate: todayKey, practiceDates: {todayKey}),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    // Flame #0 is the header badge; flame #1 is today's chip (the only
    // practiced day).
    await tester.tap(find.byIcon(Icons.local_fire_department_rounded).at(1));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Practice session'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('detail sheet shows the real quiz title when available', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final now = DateTime.now();
    final todayKey = StreakWeekLogic.dateKey(now);

    final quiz = QuizModel(id: 'quiz_letters', title: 'Letters Quiz');

    await tester.pumpWidget(
      await wrap(
        _stats(
          streak: 1,
          lastActiveDate: todayKey,
          quizHistory: {
            'quiz_letters': QuizResultEntity(
              quizId: 'quiz_letters',
              score: 8,
              totalQuestions: 10,
              completedAt: now.toIso8601String(),
            ),
          },
        ),
        extraOverrides: [
          quizzesByIdProvider.overrideWithValue(
            AsyncValue.data({'quiz_letters': quiz}),
          ),
        ],
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    // Flame #0 is the header badge; #1 is today's chip.
    await tester.tap(find.byIcon(Icons.local_fire_department_rounded).at(1));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Quiz · Letters Quiz'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('tapping an empty day reports no activity', (tester) async {
    final semantics = tester.ensureSemantics();
    final now = DateTime.now();

    await tester.pumpWidget(await wrap(_stats()));
    await tester.pump(const Duration(milliseconds: 600));

    // Today is always in the rendered week and, with no activity, shows
    // its date number rather than a flame.
    await tester.tap(find.text('${now.day}'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('No activity recorded'), findsOneWidget);
    semantics.dispose();
  });
}
