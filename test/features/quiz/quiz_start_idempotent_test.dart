import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/quiz/presentation/quiz_screen.dart';
import 'package:itun/features/quiz/presentation/providers/quiz_session_notifier.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/quiz/presentation/providers/mistake_provider.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:mocktail/mocktail.dart';

class MockLearningAnalyticsService extends Mock
    implements LearningAnalyticsService {}

class MockQuizzesNotifier extends QuizzesNotifier {
  final AsyncValue<List<QuizModel>> _initial;

  MockQuizzesNotifier(this._initial);

  @override
  AsyncValue<List<QuizModel>> build() => _initial;
}

class MockUserStatsNotifier extends UserStatsNotifier {
  final AsyncValue<UserStatsEntity> _initial;

  MockUserStatsNotifier(this._initial);

  @override
  AsyncValue<UserStatsEntity> build() => _initial;

  @override
  Future<void> saveQuizResult(covariant dynamic result) async {}

  @override
  Future<void> addStars(covariant dynamic count) async {}
}

class MockMistakeNotifier extends MistakeNotifier {
  final List<MistakeItem> _initial;

  MockMistakeNotifier(this._initial);

  @override
  List<MistakeItem> build() => _initial;

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

class StatefulRebuilder extends StatefulWidget {
  final Widget child;
  const StatefulRebuilder({super.key, required this.child});

  @override
  StatefulRebuilderState createState() => StatefulRebuilderState();
}

class StatefulRebuilderState extends State<StatefulRebuilder> {
  int rebuildCount = 0;

  void rebuild() {
    setState(() {
      rebuildCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

void main() {
  late SharedPreferences mockPrefs;
  late MockLearningAnalyticsService mockAnalytics;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockPrefs = await SharedPreferences.getInstance();
    mockAnalytics = MockLearningAnalyticsService();

    // Stub the track call
    when(
      () => mockAnalytics.track(
        any(),
        source: any(named: 'source'),
        sourceId: any(named: 'sourceId'),
        metadata: any(named: 'metadata'),
        learnerLevel: any(named: 'learnerLevel'),
        scriptMode: any(named: 'scriptMode'),
      ),
    ).thenAnswer((_) async {});
  });

  final mockQuiz = QuizModel(
    id: 'test_quiz',
    categoryId: 'alphabets',
    title: 'Test Alphabet Quiz',
    questions: [
      QuizQuestion(
        promptOlChiki: 'ᱚ',
        promptLatin: 'Sound of this?',
        optionsOlChiki: ['a', 'e', 'i', 'o'],
        optionsLatin: ['a', 'e', 'i', 'o'],
      ),
    ],
  );

  const mockStats = UserStatsEntity(
    practicedLetters: {},
    completedLessons: {},
    quizHistory: {},
    categoryMastery: {},
    totalLearningMinutes: 0,
    lastActiveDate: '',
    currentStreak: 0,
    totalStars: 0,
  );

  testWidgets(
    'QuizScreen startQuiz is called exactly once despite parent rebuilds',
    (tester) async {
      final rebuilderKey = GlobalKey<StatefulRebuilderState>();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
          quizzesProvider.overrideWith(
            () => MockQuizzesNotifier(AsyncValue.data([mockQuiz])),
          ),
          userStatsProvider.overrideWith(
            () => MockUserStatsNotifier(const AsyncValue.data(mockStats)),
          ),
          mistakeProvider.overrideWith(() => MockMistakeNotifier([])),
          learningAnalyticsServiceProvider.overrideWithValue(mockAnalytics),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: StatefulRebuilder(
              key: rebuilderKey,
              child: const QuizScreen(quizId: 'test_quiz'),
            ),
          ),
        ),
      );

      // Initial pump and Settle to let ref.listen trigger and startQuiz execute
      await tester.pumpAndSettle();

      // Trigger parent rebuilds via state changes
      rebuilderKey.currentState?.rebuild();
      await tester.pumpAndSettle();

      rebuilderKey.currentState?.rebuild();
      await tester.pumpAndSettle();

      rebuilderKey.currentState?.rebuild();
      await tester.pumpAndSettle();

      // Assert that analytics track(LearningAnalyticsEvents.quizAttempted) was called exactly once
      verify(
        () => mockAnalytics.track(
          LearningAnalyticsEvents.quizAttempted,
          source: any(named: 'source'),
          sourceId: 'test_quiz',
          metadata: any(named: 'metadata'),
        ),
      ).called(1);

      // Assert state is started
      final state = container.read(quizSessionNotifierProvider('test_quiz'));
      expect(state.hasStarted, isTrue);
    },
  );
}
