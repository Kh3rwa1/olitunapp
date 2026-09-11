import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:itun/features/home/presentation/widgets/next_best_action_card.dart';
import 'package:itun/features/home/presentation/providers/mission_providers.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/quiz/presentation/providers/mistake_provider.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}
