import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:itun/features/home/presentation/widgets/next_best_action_card.dart';
import 'package:itun/features/home/presentation/providers/mission_providers.dart';
import 'package:itun/features/home/presentation/providers/displayed_streak_provider.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/quiz/presentation/providers/mistake_provider.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/features/profile/presentation/providers/profile_providers.dart';

/// Mid-journey learner: alphabet + numbers done, no mistakes, streak at rest,
/// bakhed already heard — so the card must take its default "continue" path.
class _MidJourneyStats extends UserStatsNotifier {
  @override
  AsyncValue<UserStatsEntity> build() => const AsyncValue.data(
    UserStatsEntity(
      practicedLetters: {},
      completedLessons: {'alphabet_intro', 'number_intro'},
      quizHistory: {},
      categoryMastery: {},
      totalLearningMinutes: 30,
      lastActiveDate: '',
      currentStreak: 0,
      totalStars: 120,
    ),
  );
}

class _NoMistakes extends MistakeNotifier {
  @override
  List<MistakeItem> build() => [];
}

/// Returning learner: vocabulary progress and a streak, but no alphabet
/// work yet — the card must frame alphabet as the next step, never as a
/// permanently stuck "start here".
class _VocabOnlyStats extends UserStatsNotifier {
  @override
  AsyncValue<UserStatsEntity> build() => const AsyncValue.data(
    UserStatsEntity(
      practicedLetters: {},
      completedLessons: {'lesson_vocab_basics'},
      quizHistory: {},
      categoryMastery: {},
      totalLearningMinutes: 12,
      lastActiveDate: '',
      currentStreak: 2,
      totalStars: 15,
    ),
  );
}

class _DoneMission extends LessonCompletedTodayNotifier {
  @override
  bool build() => true;
}

class _QuizDoneMission extends QuizTakenTodayNotifier {
  @override
  bool build() => true;
}

class _BakhedDoneMission extends BakhedListenedTodayNotifier {
  @override
  bool build() => true;
}

List<Override> _midJourneyOverrides() => [
  isAuthenticatedProvider.overrideWith((ref) async => true),
  userStatsProvider.overrideWith(_MidJourneyStats.new),
  mistakeProvider.overrideWith(_NoMistakes.new),
  lessonCompletedTodayProvider.overrideWith(_DoneMission.new),
  quizTakenTodayProvider.overrideWith(_QuizDoneMission.new),
  bakhedListenedTodayProvider.overrideWith(_BakhedDoneMission.new),
];

List<Override> _vocabOnlyOverrides() => [
  isAuthenticatedProvider.overrideWith((ref) async => true),
  userStatsProvider.overrideWith(_VocabOnlyStats.new),
  mistakeProvider.overrideWith(_NoMistakes.new),
];

class _NewcomerStats extends UserStatsNotifier {
  @override
  AsyncValue<UserStatsEntity> build() => const AsyncValue.data(
    UserStatsEntity(
      practicedLetters: {},
      completedLessons: {},
      quizHistory: {},
      categoryMastery: {},
      totalLearningMinutes: 0,
      lastActiveDate: '',
      currentStreak: 0,
      totalStars: 0,
    ),
  );
}

List<Override> _newcomerOverrides() => [
  isAuthenticatedProvider.overrideWith((ref) async => true),
  userStatsProvider.overrideWith(_NewcomerStats.new),
  mistakeProvider.overrideWith(_NoMistakes.new),
  lastOpenedLessonIdProvider.overrideWith((ref) => null),
];

List<Override> _incompleteLessonOverrides() => [
  isAuthenticatedProvider.overrideWith((ref) async => true),
  userStatsProvider.overrideWith(_NewcomerStats.new),
  mistakeProvider.overrideWith(_NoMistakes.new),
  lastOpenedLessonIdProvider.overrideWith((ref) => 'lesson_x'),
];

Widget _host({required Locale locale, required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: NextBestActionCard(nextLessonId: 'lesson_x')),
    ),
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Animate.restartOnHotReload = false;
    SharedPreferences.setMockInitialValues({});
  });

  habitLoopTests();

  testWidgets('continue branch uses localized copy, not hardcoded English', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(locale: const Locale('en'), overrides: _midJourneyOverrides()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('RESUME JOURNEY'), findsOneWidget);
    expect(find.text('Continue Learning'), findsOneWidget);
    expect(find.text('Ready to learn today?'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    // Regression: previously hardcoded English-only strings.
    expect(find.text('CONTINUE LEARNING'), findsNothing);
    expect(find.text('Next step in your journey'), findsNothing);
    expect(
      find.text('Consistent daily practice creates strong roots. Keep going!'),
      findsNothing,
    );
  });

  testWidgets('returning learner sees next step, never a stuck start here', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(locale: const Locale('en'), overrides: _vocabOnlyOverrides()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('NEXT STEP'), findsOneWidget);
    expect(find.text('Learn your first Ol Chiki letters'), findsOneWidget);
    expect(find.text('Begin Lesson'), findsOneWidget);
    expect(find.text('START HERE'), findsNothing);
  });

  testWidgets('first-time newcomer sees START HERE', (tester) async {
    await tester.pumpWidget(
      _host(locale: const Locale('en'), overrides: _newcomerOverrides()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('START HERE'), findsOneWidget);
    expect(find.text('Learn your first Ol Chiki letters'), findsOneWidget);
    expect(find.text('Begin Lesson'), findsOneWidget);
  });

  testWidgets('learner after completing alphabet never sees START HERE', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(locale: const Locale('en'), overrides: _midJourneyOverrides()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('START HERE'), findsNothing);
  });

  testWidgets('learner resuming incomplete lesson sees RESUME', (tester) async {
    await tester.pumpWidget(
      _host(
        locale: const Locale('en'),
        overrides: _incompleteLessonOverrides(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('RESUME JOURNEY'), findsOneWidget);
    expect(find.text('Continue Learning'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('START HERE'), findsNothing);
  });
}

String _key(DateTime d) =>
    DateTime(d.year, d.month, d.day).toIso8601String().substring(0, 10);

/// Live 3-day streak (practiced yesterday), nothing practiced today.
class _LiveStreakStats extends UserStatsNotifier {
  @override
  AsyncValue<UserStatsEntity> build() {
    final now = DateTime(2026, 11, 10, 18);
    return AsyncValue.data(
      UserStatsEntity(
        practicedLetters: const {},
        completedLessons: const {'alphabet_intro', 'number_intro'},
        quizHistory: const {},
        categoryMastery: const {},
        totalLearningMinutes: 30,
        lastActiveDate: _key(now.subtract(const Duration(days: 1))),
        currentStreak: 3,
        totalStars: 120,
        practiceDates: {
          for (var i = 1; i <= 3; i++) _key(now.subtract(Duration(days: i))),
        },
      ),
    );
  }
}

class _NotDone extends LessonCompletedTodayNotifier {
  @override
  bool build() => false;
}

class _QuizNotDone extends QuizTakenTodayNotifier {
  @override
  bool build() => false;
}

class _BakhedNotDone extends BakhedListenedTodayNotifier {
  @override
  bool build() => false;
}

Widget _hostNoLesson({required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: NextBestActionCard()),
    ),
  );
}

void habitLoopTests() {
  testWidgets('late in the day a live streak at risk comes first', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        locale: const Locale('en'),
        overrides: [
          isAuthenticatedProvider.overrideWith((ref) async => true),
          userStatsProvider.overrideWith(_LiveStreakStats.new),
          mistakeProvider.overrideWith(_NoMistakes.new),
          lessonCompletedTodayProvider.overrideWith(_NotDone.new),
          quizTakenTodayProvider.overrideWith(_QuizNotDone.new),
          bakhedListenedTodayProvider.overrideWith(_BakhedNotDone.new),
          lastOpenedLessonIdProvider.overrideWith((ref) => 'lesson_x'),
          streakClockProvider.overrideWithValue(
            () => DateTime(2026, 11, 10, 18),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Even with a resumable lesson, the streak nudge wins after 17:00.
    expect(find.text('STREAK RISK'), findsOneWidget);
    expect(find.text('Start daily practice'), findsOneWidget);
    expect(find.text('RESUME JOURNEY'), findsNothing);
  });

  testWidgets('in the morning the same learner resumes normally', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        locale: const Locale('en'),
        overrides: [
          isAuthenticatedProvider.overrideWith((ref) async => true),
          userStatsProvider.overrideWith(_LiveStreakStats.new),
          mistakeProvider.overrideWith(_NoMistakes.new),
          lessonCompletedTodayProvider.overrideWith(_NotDone.new),
          quizTakenTodayProvider.overrideWith(_QuizNotDone.new),
          bakhedListenedTodayProvider.overrideWith(_BakhedNotDone.new),
          lastOpenedLessonIdProvider.overrideWith((ref) => 'lesson_x'),
          streakClockProvider.overrideWithValue(
            () => DateTime(2026, 11, 10, 9),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('STREAK RISK'), findsNothing);
    expect(find.text('RESUME JOURNEY'), findsOneWidget);
  });

  testWidgets('catalogue finished → daily practice is the primary action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _hostNoLesson(
        overrides: [
          isAuthenticatedProvider.overrideWith((ref) async => true),
          userStatsProvider.overrideWith(_MidJourneyStats.new),
          mistakeProvider.overrideWith(_NoMistakes.new),
          lessonCompletedTodayProvider.overrideWith(_DoneMission.new),
          quizTakenTodayProvider.overrideWith(_QuizNotDone.new),
          bakhedListenedTodayProvider.overrideWith(_BakhedDoneMission.new),
          lastOpenedLessonIdProvider.overrideWith((ref) => null),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('DAILY PRACTICE'), findsOneWidget);
    expect(find.text('Keep your Ol Chiki sharp'), findsOneWidget);
    expect(find.text('Start daily practice'), findsOneWidget);
    expect(find.text('Explore Bakhed'), findsNothing);
  });

  testWidgets(
    'catalogue finished and practiced today → all done, practice CTA',
    (tester) async {
      await tester.pumpWidget(
        _hostNoLesson(
          overrides: [
            ..._midJourneyOverrides(),
            lastOpenedLessonIdProvider.overrideWith((ref) => null),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('ALL COMPLETE'), findsOneWidget);
      expect(find.text('Start daily practice'), findsOneWidget);
    },
  );
}
