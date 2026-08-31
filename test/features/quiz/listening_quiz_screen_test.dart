import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/audio/audio_service.dart';
import 'package:itun/core/audio/playback_controller.dart';
import 'package:itun/core/config/feature_flags.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/content/presentation/providers/audio_playback_providers.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/quiz/presentation/quiz_screen.dart';
import 'package:itun/features/quiz/presentation/providers/mistake_provider.dart';
import 'package:itun/features/quiz/presentation/widgets/listening_question_card.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_question_card.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/providers.dart';

import '../../test_utils.dart';

/// Phase 7: the `listening_quiz_<lessonId>` flow end-to-end — flag-off
/// keeps the classic quiz experience, flag-on renders the listening card
/// wired to the single global PlaybackController, and both funnel events
/// (spec §16) emit exactly once.
void main() {
  late SharedPreferences mockPrefs;
  late MockLearningAnalyticsService analyticsService;
  late _MockAudioService audioService;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  // The lesson backing `listening_quiz_test_lesson`. The generator turns
  // each audio-bearing block into one 'listen_meaning' question, so the
  // first question's correct answer is 'Water'.
  const testLesson = LessonEntity(
    id: 'test_lesson',
    categoryId: 'cat_phrases',
    titleOlChiki: 'ᱥᱤᱛᱤ',
    titleLatin: 'Greetings',
    blocks: [
      LessonBlockEntity(
        type: 'word',
        textOlChiki: 'ᱫᱟᱜ',
        textLatin: 'Water',
        audioUrl: 'https://example.com/audio/water.mp3',
      ),
      LessonBlockEntity(
        type: 'word',
        textOlChiki: 'ᱥᱟᱜ',
        textLatin: 'Fire',
        audioUrl: 'https://example.com/audio/fire.mp3',
      ),
      LessonBlockEntity(
        type: 'word',
        textOlChiki: 'ᱡᱚᱢ',
        textLatin: 'Food',
        audioUrl: 'https://example.com/audio/food.mp3',
      ),
      LessonBlockEntity(
        type: 'word',
        textOlChiki: 'ᱫᱟᱨᱮ',
        textLatin: 'Tree',
        audioUrl: 'https://example.com/audio/tree.mp3',
      ),
    ],
  );

  // The lesson's playable clip set — startQuiz shuffles which question is
  // displayed first, so playback assertions accept any of these tracks.
  const lessonAudioUrls = [
    'https://example.com/audio/water.mp3',
    'https://example.com/audio/fire.mp3',
    'https://example.com/audio/food.mp3',
    'https://example.com/audio/tree.mp3',
  ];

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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockPrefs = await SharedPreferences.getInstance();
    analyticsService = MockLearningAnalyticsService();
    audioService = _MockAudioService();

    // Catch-all stub: `track` returns a non-nullable Future<void>, and
    // mocktail returns null for unstubbed calls — which throws a TypeError
    // at every call site (quiz_attempted, quiz_answered, ...). Stubbed calls
    // are still recorded, so verify/verifyNever keep working.
    when(
      () => analyticsService.track(
        any(),
        source: any(named: 'source'),
        sourceId: any(named: 'sourceId'),
        metadata: any(named: 'metadata'),
        learnerLevel: any(named: 'learnerLevel'),
        scriptMode: any(named: 'scriptMode'),
      ),
    ).thenAnswer((_) async {});
  });

  List<Override> baseOverrides() => [
    sharedPreferencesProvider.overrideWithValue(mockPrefs),
    // The `listening_quiz_` prefix routes through learnerLessonsProvider.
    learnerLessonsProvider.overrideWithValue(
      const AsyncValue.data([testLesson]),
    ),
    quizzesProvider.overrideWith(
      () => MockQuizzesNotifier(const AsyncValue.data([])),
    ),
    userStatsProvider.overrideWith(
      () => MockUserStatsNotifier(const AsyncValue.data(mockStats)),
    ),
    mistakeProvider.overrideWith(() => MockMistakeNotifier([])),
    learningAnalyticsServiceProvider.overrideWithValue(analyticsService),
  ];

  void setPortraitSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets(
    'flag OFF (default): listen_meaning renders the classic QuizQuestionCard',
    (tester) async {
      setPortraitSurface(tester);

      // No featureFlagsProvider override: appSettingsProvider cannot load in
      // tests, so FeatureFlags.fromSettings resolves with every flag OFF.
      await tester.pumpWidget(
        createTestableWidget(
          child: const QuizScreen(quizId: 'listening_quiz_test_lesson'),
          overrides: baseOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(QuizQuestionCard), findsOneWidget);
      expect(find.byType(ListeningQuestionCard), findsNothing);
      // No play button — the flag-off experience is unchanged.
      expect(find.byIcon(Icons.volume_up_rounded), findsNothing);

      verifyNever(
        () => analyticsService.track(
          LearningAnalyticsEvents.listeningQuizStarted,
          source: 'quiz_session',
          sourceId: 'listening_quiz_test_lesson',
          metadata: any(named: 'metadata', that: isNotNull),
        ),
      );
    },
  );

  testWidgets(
    'flag ON: ListeningQuestionCard renders and play routes through the global PlaybackController',
    (tester) async {
      setPortraitSurface(tester);

      await tester.pumpWidget(
        createTestableWidget(
          child: const QuizScreen(quizId: 'listening_quiz_test_lesson'),
          overrides: [
            ...baseOverrides(),
            featureFlagsProvider.overrideWithValue(
              const FeatureFlags(
                multilingualAudioEnabled: false,
                onboardingV2Enabled: false,
                bilingualPlaybackEnabled: false,
                audioDownloadsEnabled: false,
                audioQuizzesEnabled: true,
                sarvamGenerationEnabled: false,
              ),
            ),
            playbackControllerProvider.overrideWithValue(
              PlaybackController(audioService: audioService),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListeningQuestionCard), findsOneWidget);
      expect(find.byType(QuizQuestionCard), findsNothing);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

      verify(
        () => analyticsService.track(
          LearningAnalyticsEvents.listeningQuizStarted,
          source: 'quiz_session',
          sourceId: 'listening_quiz_test_lesson',
          metadata: any(named: 'metadata', that: isNotNull),
        ),
      ).called(1);

      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      await tester.pumpAndSettle();

      // The tap went through playbackControllerProvider.playSingle →
      // AudioService.tryPlayUrl (single global player rule). The session
      // shuffles question order, so the displayed word can be any of the
      // lesson's blocks — assert the played clip is one of its own tracks.
      expect(audioService.playedUrls, isNotEmpty);
      for (final url in audioService.playedUrls) {
        expect(lessonAudioUrls, contains(url));
      }
    },
  );

  testWidgets('flag ON: answering emits listening_quiz_answered exactly once', (
    tester,
  ) async {
    setPortraitSurface(tester);

    await tester.pumpWidget(
      createTestableWidget(
        child: const QuizScreen(quizId: 'listening_quiz_test_lesson'),
        overrides: [
          ...baseOverrides(),
          featureFlagsProvider.overrideWithValue(
            const FeatureFlags(
              multilingualAudioEnabled: false,
              onboardingV2Enabled: false,
              bilingualPlaybackEnabled: false,
              audioDownloadsEnabled: false,
              audioQuizzesEnabled: true,
              sarvamGenerationEnabled: false,
            ),
          ),
          playbackControllerProvider.overrideWithValue(
            PlaybackController(audioService: audioService),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // The session notifier shuffles question AND option order, so tap
    // the first option tile by its stable key rather than by label.
    await tester.tap(find.byKey(const ValueKey('quiz-option-semantics-0')));
    await tester.pumpAndSettle();

    // Tapping another option after the question is answered must not
    // double-emit (the isAnswered guard in QuizScreen._selectAnswer).
    await tester.tap(find.byKey(const ValueKey('quiz-option-semantics-1')));
    await tester.pumpAndSettle();

    // mocktail's verify() consumes matched invocations, so assert the
    // exactly-once contract in a single verify after both taps.
    verify(
      () => analyticsService.track(
        LearningAnalyticsEvents.listeningQuizAnswered,
        source: 'quiz_session',
        sourceId: 'listening_quiz_test_lesson',
        metadata: any(named: 'metadata', that: isNotNull),
      ),
    ).called(1);
  });
}

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
  Future<void> saveQuizResult(QuizResultEntity result) async {}
  @override
  Future<void> addStars(int count) async {}
}

class MockMistakeNotifier extends MistakeNotifier {
  final List<MistakeItem> _initial;

  MockMistakeNotifier(this._initial);

  @override
  List<MistakeItem> build() => _initial;

  @override
  Future<void> recordMistake({
    required String quizId,
    required int questionIndex,
    required QuizQuestion question,
    String? wrongAnswer,
  }) async {}

  @override
  Future<void> masterMistake({
    required String quizId,
    required int questionIndex,
  }) async {}

  @override
  Future<void> syncFromBackend() async {}
}

// No explicit `track` override: a real method body would take precedence
// over mocktail's noSuchMethod and invocations would never be recorded
// (quiz_screen_test.dart precedent).
class MockLearningAnalyticsService extends Mock
    implements LearningAnalyticsService {}

/// AudioService double: records played URLs, never touches real audio,
/// and exposes empty streams so PlaybackController stays idle
/// (story_player_body_test.dart precedent).
class _MockAudioService extends AudioService {
  final List<String> playedUrls = [];

  @override
  Future<bool> tryPlayUrl(String url) async {
    playedUrls.add(url);
    return true;
  }

  @override
  Future<void> playUrl(String url) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Stream<ProcessingState> get processingStateStream => const Stream.empty();

  @override
  Stream<Duration> get positionStream => const Stream.empty();

  @override
  Stream<Duration?> get durationStream => const Stream.empty();

  @override
  Stream<bool> get isPlayingStream => const Stream.empty();
}
