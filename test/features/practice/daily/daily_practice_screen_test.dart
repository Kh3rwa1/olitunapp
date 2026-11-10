import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/home/presentation/providers/mission_providers.dart';
import 'package:itun/features/practice/daily/presentation/daily_practice_builder.dart';
import 'package:itun/features/practice/daily/presentation/daily_practice_outcome.dart';
import 'package:itun/features/practice/daily/presentation/daily_practice_screen.dart';
import 'package:itun/features/practice/daily/presentation/providers/daily_practice_providers.dart';
import 'package:itun/features/review/domain/review_item.dart';
import 'package:itun/features/review/presentation/review_exercise.dart';
import 'package:itun/features/review/presentation/review_session_screen.dart';
import 'package:itun/features/review/presentation/widgets/review_session_states.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/learner_content_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../home/widgets/habit_test_support.dart';

class _QuizToday extends QuizTakenTodayNotifier {
  bool completed = false;
  @override
  bool build() => false;
  @override
  Future<void> setCompleted(bool value) async {
    completed = value;
    state = value;
  }
}

ReviewCard _letter(String id, {int correct = 0}) => ReviewCard(
  itemId: '$letterItemIdPrefix$id',
  itemType: ReviewItemType.word,
  kind: ReviewPromptKind.olChikiToMeaning,
  promptOlChiki: 'ᱚ$id',
  promptLatin: id,
  promptMeaning: 'sound-$id',
  audioUrl: '',
  options: ['sound-$id-0', 'sound-$id-1', 'sound-$id-2'],
  correctOptionIndex: correct,
);

Widget _host(Widget child, List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

void main() {
  late SharedPreferences prefs;
  late RecordingAnalyticsService analytics;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    analytics = RecordingAnalyticsService(prefs);
  });

  List<Override> baseOverrides(_QuizToday quizToday) => [
    sharedPreferencesProvider.overrideWithValue(prefs),
    learningAnalyticsServiceProvider.overrideWithValue(analytics),
    learnerWordsProvider.overrideWithValue(
      const AsyncValue.data(<WordModel>[]),
    ),
    learnerSentencesProvider.overrideWithValue(
      const AsyncValue.data(<SentenceModel>[]),
    ),
    quizTakenTodayProvider.overrideWith(() => quizToday),
  ];

  test('route constant matches the registered path', () {
    expect(dailyPracticeRoute, '/practice/daily');
  });

  testWidgets('runs a letter-only session end to end and finishes', (
    tester,
  ) async {
    final quizToday = _QuizToday();
    final cards = [_letter('a', correct: 1), _letter('b', correct: 2)];
    List<AnsweredCard>? finishedWith;
    late ProviderContainer container;

    await tester.pumpWidget(
      _host(
        Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return const DailyPracticeScreen();
          },
        ),
        [
          ...baseOverrides(quizToday),
          dailyPracticeCardsProvider.overrideWithValue(AsyncValue.data(cards)),
          dailyPracticeFinisherProvider.overrideWithValue(({
            required answered,
            required elapsed,
          }) async {
            finishedWith = answered;
            return DailyPracticeOutcome.from(answered, elapsed: elapsed);
          }),
        ],
      ),
    );
    container.read(dailyPracticeSeedWordProvider.notifier).state = 'w1';
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(ReviewSessionScreen), findsOneWidget);
    expect(find.text('Daily practice 1 of 2'), findsOneWidget);
    expect(
      analytics.names,
      contains(LearningAnalyticsEvents.dailyPracticeStarted),
    );
    expect(find.byTooltip('Exit practice'), findsOneWidget);

    // Card 1: correct answer.
    await tester.tap(find.text('sound-a-1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Card 2: wrong answer, then finish.
    await tester.tap(find.text('sound-b-0'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.ensureVisible(find.text('Finish practice'));
    await tester.tap(find.text('Finish practice'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(ReviewSummaryView), findsOneWidget);
    expect(find.text('Practice complete'), findsWidgets);
    expect(find.text('1 of 2 correct (50%)'), findsOneWidget);
    expect(find.text('+10 stars · 1 min logged'), findsOneWidget);

    expect(finishedWith, isNotNull);
    expect(finishedWith!.map((a) => a.correct), [true, false]);
    expect(quizToday.completed, isTrue);
    expect(container.read(dailyPracticeSeedWordProvider), isNull);
    expect(
      analytics.names,
      contains(LearningAnalyticsEvents.dailyPracticeCompleted),
    );
    final completed = analytics.events.lastWhere(
      (e) => e.name == LearningAnalyticsEvents.dailyPracticeCompleted,
    );
    expect(completed.source, 'daily_practice');
    expect(completed.meta['correct'], 1);
    expect(completed.meta['total'], 2);
    expect(completed.meta['stars'], 10);
    // Letter cards are graded locally: correct/wrong events, no store.
    expect(analytics.names, contains(LearningAnalyticsEvents.reviewCorrect));
    expect(analytics.names, contains(LearningAnalyticsEvents.reviewWrong));
    expect(
      analytics.names,
      isNot(contains(LearningAnalyticsEvents.itemRescheduled)),
    );
  });

  testWidgets('no cards (corpus unavailable) shows an honest error + retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const DailyPracticeScreen(), [
        ...baseOverrides(_QuizToday()),
        dailyPracticeCardsProvider.overrideWithValue(
          const AsyncValue.data(<ReviewCard>[]),
        ),
      ]),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(ReviewLoadErrorView), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Daily practice'), findsOneWidget);
  });

  testWidgets('waits while cards are loading', (tester) async {
    await tester.pumpWidget(
      _host(const DailyPracticeScreen(), [
        ...baseOverrides(_QuizToday()),
        dailyPracticeCardsProvider.overrideWithValue(
          const AsyncValue.loading(),
        ),
      ]),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(analytics.names, isEmpty);
  });
}
