import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:itun/core/audio/playback_controller.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/languages/language_registry.dart';
import 'package:itun/core/languages/providers/target_language_provider.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/content/presentation/providers/audio_playback_providers.dart';
import 'package:itun/features/home/presentation/providers/mission_providers.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/quiz/presentation/providers/mistake_provider.dart';
import 'package:itun/features/quiz/presentation/providers/quiz_session_notifier.dart';
import 'package:itun/features/quiz/presentation/quiz_screen.dart';
import 'package:itun/shared/models/content/quiz_model.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:itun/l10n/generated/app_localizations.dart';

class MockPlaybackController extends Mock implements PlaybackController {}

class MockLearningAnalyticsService extends Mock
    implements LearningAnalyticsService {}

class MockUserStatsNotifier extends UserStatsNotifier {
  final List<QuizResultEntity> savedResults = [];
  final List<int> starsAdded = [];
  int completedLessons = 0;

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

  @override
  Future<void> saveQuizResult(QuizResultEntity result) async {
    savedResults.add(result);
  }

  @override
  Future<void> addStars(int count) async {
    starsAdded.add(count);
  }

  @override
  Future<void> completeLesson(
    String lessonId, {
    String? categoryId,
    int? estimatedMinutes,
  }) async {
    completedLessons++;
  }
}

class MockMistakeNotifier extends MistakeNotifier {
  MockMistakeNotifier();

  @override
  List<MistakeItem> build() => [];

  @override
  Future<void> syncFromBackend() async {}

  @override
  Future<void> recordMistake({
    required String quizId,
    required int questionIndex,
    required QuizQuestion question,
    String? wrongAnswer,
  }) async {}
}

class MockQuizTakenTodayNotifier extends QuizTakenTodayNotifier {
  int setCompletedCalls = 0;

  @override
  bool build() => false;

  @override
  Future<void> setCompleted(bool completed) async {
    setCompletedCalls++;
  }
}

final _emptyLessonQuiz = QuizModel(
  id: 'dynamic_quiz_lesson_conv3',
  categoryId: 'cat_sentences',
  title: 'Modern Conversational Exchanges III Quiz',
);

const _emptyLesson = LessonEntity(
  id: 'lesson_conv3',
  categoryId: 'cat_sentences',
  titleLatin: 'Modern Conversational Exchanges III',
  titleOlChiki: 'ᱱᱟᱦᱟᱜ ᱨᱚᱲ',
);

Future<ProviderContainer> _notifierContainer(
  MockUserStatsNotifier stats,
  MockQuizTakenTodayNotifier takenToday,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final analytics = MockLearningAnalyticsService();
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
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      userStatsProvider.overrideWith(() => stats),
      learningAnalyticsServiceProvider.overrideWithValue(analytics),
      mistakeProvider.overrideWith(MockMistakeNotifier.new),
      quizTakenTodayProvider.overrideWith(() => takenToday),
    ],
  );
}

Future<void> _pumpUnavailableQuiz(
  WidgetTester tester, {
  required List<Override> extraOverrides,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final playback = MockPlaybackController();
  when(playback.stop).thenAnswer((_) async {});
  final router = GoRouter(
    initialLocation: '/quiz/dynamic_quiz_lesson_conv3?lessonId=lesson_conv3',
    routes: [
      GoRoute(
        path: '/quiz/:quizId',
        builder: (context, state) => QuizScreen(
          quizId: state.pathParameters['quizId'] ?? '',
          lessonId: state.uri.queryParameters['lessonId'],
        ),
      ),
      GoRoute(
        path: '/lesson/:lessonId',
        builder: (context, state) =>
            Text('lesson ${state.pathParameters['lessonId']}'),
      ),
      GoRoute(path: '/', builder: (context, state) => const Text('home')),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        playbackControllerProvider.overrideWithValue(playback),
        effectiveTeachingLanguageProvider.overrideWithValue('hi'),
        effectiveScriptModeProvider.overrideWithValue('both'),
        activeLanguageManifestProvider.overrideWithValue(
          LanguageRegistry.findByCode('sat'),
        ),
        // The catalog lesson carries no blocks, so the quiz hydrates
        // through the detail boundary — which resolves empty here.
        learnerLessonDetailProvider(
          'lesson_conv3',
        ).overrideWith((_) => Future.value(_emptyLesson)),
        ...extraOverrides,
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('empty quiz cannot save results or award progress', () {
    test('start/select/next on an empty quiz are no-ops', () async {
      final stats = MockUserStatsNotifier();
      final takenToday = MockQuizTakenTodayNotifier();
      final container = await _notifierContainer(stats, takenToday);
      addTearDown(container.dispose);

      final notifier = container.read(
        quizSessionNotifierProvider('dynamic_quiz_lesson_conv3').notifier,
      );
      notifier.startQuiz(_emptyLessonQuiz);
      final state = container.read(
        quizSessionNotifierProvider('dynamic_quiz_lesson_conv3'),
      );
      expect(state.hasStarted, isFalse);

      notifier.selectAnswer(
        0,
        QuizQuestion(promptOlChiki: 'ᱥᱮᱸᱫᱨᱟ'),
        _emptyLessonQuiz,
      );
      await notifier.nextQuestion(_emptyLessonQuiz);

      expect(state.isQuizComplete, isFalse);
      expect(stats.savedResults, isEmpty);
      expect(stats.starsAdded, isEmpty);
      expect(stats.completedLessons, 0);
      expect(takenToday.setCompletedCalls, 0);
    });
  });

  group('lesson quiz unavailable screen', () {
    testWidgets('empty dynamic quiz shows the unavailable state with '
        'Back/Finish Lesson navigation', (tester) async {
      await _pumpUnavailableQuiz(
        tester,
        extraOverrides: [
          learnerLessonsProvider.overrideWithValue(
            const AsyncValue.data([_emptyLesson]),
          ),
        ],
      );

      expect(
        find.text(
          'Quiz unavailable — this lesson does not contain enough valid '
          'questions yet.',
        ),
        findsOneWidget,
      );
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Finish Lesson'), findsOneWidget);
      // Never an unrelated alphabet question.
      expect(find.text('Which sound does this letter make?'), findsNothing);

      await tester.tap(find.text('Finish Lesson'));
      await tester.pumpAndSettle();
      expect(find.text('lesson lesson_conv3'), findsOneWidget);
    });

    testWidgets('Back leaves the unavailable quiz', (tester) async {
      await _pumpUnavailableQuiz(
        tester,
        extraOverrides: [
          learnerLessonsProvider.overrideWithValue(
            const AsyncValue.data([_emptyLesson]),
          ),
        ],
      );

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
    });
  });
}
