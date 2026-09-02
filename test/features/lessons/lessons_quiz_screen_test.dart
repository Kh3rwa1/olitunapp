import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/auth/domain/repositories/auth_repository.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/features/lessons/presentation/quiz/quiz_screen.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/quizzes_provider.dart';
import 'package:itun/shared/widgets/state_widgets.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/profile/domain/repositories/profile_repository.dart';
import 'package:itun/features/profile/presentation/providers/profile_providers.dart';

class _MockProfileRepo extends Mock implements ProfileRepository {}

class _MockAuthRepo extends Mock implements AuthRepository {}

class _MockAnalytics extends Mock implements LearningAnalyticsService {}

class _FakeQuizzesNotifier extends QuizzesNotifier {
  final List<QuizModel> quizzes;
  _FakeQuizzesNotifier(this.quizzes);

  @override
  AsyncValue<List<QuizModel>> build() => AsyncValue.data(quizzes);
}

QuizModel _quiz({String id = 'quiz_1', List<QuizQuestion>? questions}) =>
    QuizModel(
      id: id,
      title: 'Ol Chiki Basics',
      questions:
          questions ??
          [
            QuizQuestion(
              promptOlChiki: 'ᱚ',
              promptLatin: 'Which sound does this letter make?',
              optionsLatin: const ['a', 'i', 'u', 'o'],
              correctIndex: 2,
            ),
            QuizQuestion(
              promptOlChiki: 'ᱛ',
              promptLatin: 'And this one?',
              optionsLatin: const ['t', 'k', 'm', 'n'],
            ),
          ],
    );

Future<void> pumpQuizScreen(
  WidgetTester tester, {
  String? quizId,
  List<QuizModel> quizzes = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final profileRepo = _MockProfileRepo();
  when(profileRepo.getUserStats).thenAnswer((_) async {
    return const Right(
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
  });
  when(() => profileRepo.updateUserStats(any())).thenAnswer((invocation) async {
    return Right(invocation.positionalArguments[0] as UserStatsEntity);
  });
  final authRepo = _MockAuthRepo();
  when(authRepo.getCurrentUser).thenAnswer((_) async => const Right(null));
  final analytics = _MockAnalytics();
  when(
    () => analytics.track(
      any(),
      source: any(named: 'source'),
      sourceId: any(named: 'sourceId'),
      metadata: any(named: 'metadata'),
      learnerLevel: any(named: 'learnerLevel'),
      scriptMode: any(named: 'scriptMode'),
    ),
  ).thenAnswer((_) async {});

  final router = GoRouter(
    initialLocation: '/quiz${quizId == null ? '' : '/$quizId'}',
    routes: [
      GoRoute(path: '/quiz', builder: (context, state) => const QuizScreen()),
      GoRoute(
        path: '/quiz/:quizId',
        builder: (context, state) =>
            QuizScreen(quizId: state.pathParameters['quizId']),
      ),
      GoRoute(
        path: '/quizzes',
        builder: (context, state) => const Text('quizzes list'),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        quizzesProvider.overrideWith(() => _FakeQuizzesNotifier(quizzes)),
        profileRepositoryProvider.overrideWithValue(profileRepo),
        authRepositoryProvider.overrideWithValue(authRepo),
        learningAnalyticsServiceProvider.overrideWithValue(analytics),
        appConnectivityProvider.overrideWith(
          (ref) =>
              Stream<List<ConnectivityResult>>.value([ConnectivityResult.wifi]),
        ),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const UserStatsEntity(
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
  });

  testWidgets('renders the hardcoded fallback quiz when quizId is null', (
    tester,
  ) async {
    await pumpQuizScreen(tester);

    expect(find.text('1/1Q'), findsOneWidget);
    expect(find.text('Which sound does this letter make?'), findsOneWidget);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('o'), findsOneWidget);
    expect(find.byType(OfflineStatusBanner), findsOneWidget);
  });

  testWidgets('loads the quiz matching the provided quizId', (tester) async {
    await pumpQuizScreen(tester, quizId: 'quiz_1', quizzes: [_quiz()]);

    expect(find.text('1/2Q'), findsOneWidget);
    expect(find.text('Which sound does this letter make?'), findsOneWidget);
    expect(find.text('Ol Chiki Basics'), findsNothing);
  });

  testWidgets('unknown quizId falls back to the hardcoded question', (
    tester,
  ) async {
    await pumpQuizScreen(tester, quizId: 'missing', quizzes: [_quiz()]);

    expect(find.text('1/1Q'), findsOneWidget);
  });

  testWidgets('empty quiz renders the empty state', (tester) async {
    await pumpQuizScreen(
      tester,
      quizId: 'quiz_empty',
      quizzes: [_quiz(id: 'quiz_empty', questions: const [])],
    );

    expect(find.text('Quiz is Empty'), findsOneWidget);
  });

  testWidgets(
    'correct answer reveals the next button and finishing shows the passing dialog',
    (tester) async {
      await pumpQuizScreen(tester, quizId: 'quiz_1', quizzes: [_quiz()]);

      await tester.tap(find.text('u'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('Next Question'), findsOneWidget);

      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();
      expect(find.text('2/2Q'), findsOneWidget);

      await tester.tap(find.text('t'));
      await tester.pumpAndSettle();
      expect(find.text('Finish Quiz'), findsOneWidget);

      await tester.tap(find.text('Finish Quiz'));
      await tester.pumpAndSettle();

      expect(find.text('Amazing! 🎉'), findsOneWidget);
      expect(find.text('You scored 2 out of 2'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    },
  );

  testWidgets('retry resets the quiz to the first question', (tester) async {
    await pumpQuizScreen(tester, quizId: 'quiz_1', quizzes: [_quiz()]);

    await tester.tap(find.text('u'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next Question'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('t'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish Quiz'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Amazing! 🎉'), findsNothing);
    expect(find.text('1/2Q'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });
}
