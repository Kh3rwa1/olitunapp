// Quiz → memory integration: quiz answers update the SAME review state
// used by Today's Review, typing and review sessions (single source of
// truth). Resolution uses generator-set source IDs only — no provider
// lookups inside selectAnswer (see quiz_shuffle_test for why that matters).

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/home/presentation/providers/mission_providers.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/profile/presentation/providers/profile_providers.dart';
import 'package:itun/features/quiz/presentation/providers/mistake_provider.dart';
import 'package:itun/features/quiz/presentation/providers/quiz_session_notifier.dart';
import 'package:itun/features/review/data/review_store.dart';
import 'package:itun/features/review/domain/review_item.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/quiz_engine/sentence_quiz_builder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAnalytics extends Mock implements LearningAnalyticsService {}

class _MockUserStats extends UserStatsNotifier {
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
  Future<void> saveQuizResult(covariant dynamic result) async {}

  @override
  Future<void> addStars(covariant dynamic count) async {}
}

class _MockMistakes extends MistakeNotifier {
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

class _MockQuizTakenToday extends QuizTakenTodayNotifier {
  @override
  bool build() => false;

  @override
  Future<void> setCompleted(bool completed) async {}
}

QuizQuestion wordQuestion(String wordId, {String? audioUrl}) => QuizQuestion(
  promptOlChiki: 'ᱫᱟᱜ',
  optionsLatin: const ['water', 'fire'],
  optionsOlChiki: const ['ᱫᱟᱜ', 'ᱥᱮᱸᱜᱮᱞ'],
  correctIndex: 0, // ignore: avoid_redundant_argument_values
  sourceWordId: wordId,
  audioUrl: audioUrl,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
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
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        userStatsProvider.overrideWith(_MockUserStats.new),
        learningAnalyticsServiceProvider.overrideWithValue(analytics),
        mistakeProvider.overrideWith(_MockMistakes.new),
        quizTakenTodayProvider.overrideWith(_MockQuizTakenToday.new),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<MemoryItemState?> readItem(String id) async {
    await container.read(reviewStoreProvider.future);
    // selectAnswer records fire-and-forget; flush microtasks + prefs write.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await container.read(reviewStoreProvider.future);
    return container.read(reviewStoreProvider).valueOrNull?.get(id);
  }

  QuizModel singleQuestionQuiz(String quizId, QuizQuestion q) =>
      QuizModel(id: quizId, questions: [q]);

  group('resolveQuizMemoryItem', () {
    test('word question maps to WordModel id', () {
      final resolved = resolveQuizMemoryItem(wordQuestion('w1'));
      expect(resolved?.itemId, 'w1');
      expect(resolved?.itemType, ReviewItemType.word);
    });

    test('sentence question maps to SentenceModel id', () {
      final q = QuizQuestion(
        type: 'fill_blank',
        promptOlChiki: 'Fill in the blank:',
        sourceSentenceId: 's1',
      );
      final resolved = resolveQuizMemoryItem(q);
      expect(resolved?.itemId, 's1');
      expect(resolved?.itemType, ReviewItemType.sentence);
    });

    test('both IDs set refuses to guess (exactly-one attribution)', () {
      final q = QuizQuestion(
        promptOlChiki: 'x',
        sourceWordId: 'w1',
        sourceSentenceId: 's1',
      );
      // Double-attributed questions must be fixed at content-build time
      // (see normalizeSourceAttribution); the runtime resolver never
      // silently prioritizes one side.
      expect(resolveQuizMemoryItem(q), isNull);
    });

    test('missing/blank source IDs fail safe to null', () {
      expect(resolveQuizMemoryItem(QuizQuestion(promptOlChiki: 'x')), isNull);
      expect(
        resolveQuizMemoryItem(
          QuizQuestion(
            promptOlChiki: 'x',
            sourceWordId: '  ',
            sourceSentenceId: '',
          ),
        ),
        isNull,
      );
    });
  });

  group('selectAnswer feeds the shared review state', () {
    test('quiz correct updates item (recall +1, due tomorrow)', () async {
      final quiz = singleQuestionQuiz('q1', wordQuestion('w-quiz-1'));
      final notifier = container.read(
        quizSessionNotifierProvider('q1').notifier,
      );
      notifier.startQuiz(quiz, testRng: Random(1));
      // displayedQuestion shuffles options: pick the displayed correct index.
      final displayed = notifier.displayedQuestion(quiz);
      notifier.selectAnswer(displayed.correctIndex, displayed, quiz);

      final item = await readItem('w-quiz-1');
      expect(item, isNotNull);
      expect(item!.successfulRecalls, 1);
      expect(item.failedRecalls, 0);
      expect(item.itemType, ReviewItemType.word);
      expect(
        item.nextReviewAt.difference(DateTime.now().toUtc()).inHours,
        greaterThanOrEqualTo(23),
      );
    });

    test('quiz wrong updates item (fail +1, back within the hour)', () async {
      final quiz = singleQuestionQuiz('q2', wordQuestion('w-quiz-2'));
      final notifier = container.read(
        quizSessionNotifierProvider('q2').notifier,
      );
      notifier.startQuiz(quiz, testRng: Random(1));
      // Pick any displayed option EXCEPT the correct one.
      final displayed = notifier.displayedQuestion(quiz);
      final wrongIndex = displayed.correctIndex == 0 ? 1 : 0;
      notifier.selectAnswer(wrongIndex, displayed, quiz);

      final item = await readItem('w-quiz-2');
      expect(item, isNotNull);
      expect(item!.failedRecalls, 1);
      expect(item.successfulRecalls, 0);
      expect(
        item.nextReviewAt.difference(DateTime.now().toUtc()).inMinutes,
        lessThan(60),
      );
    });

    test('listening question records listening evidence', () async {
      final quiz = singleQuestionQuiz(
        'q3',
        wordQuestion('w-quiz-3', audioUrl: 'https://x/a.mp3'),
      );
      final notifier = container.read(
        quizSessionNotifierProvider('q3').notifier,
      );
      notifier.startQuiz(quiz, testRng: Random(1));
      final displayed = notifier.displayedQuestion(quiz);
      notifier.selectAnswer(displayed.correctIndex, displayed, quiz);

      final item = await readItem('w-quiz-3');
      expect(item?.lastExerciseType, ReviewExerciseType.listening);
    });

    test('unattributed question creates no state and never throws', () async {
      final quiz = singleQuestionQuiz(
        'q4',
        QuizQuestion(
          promptOlChiki: 'hand-written?',
          optionsLatin: ['a', 'b'],
          correctIndex: 0, // ignore: avoid_redundant_argument_values
        ),
      );
      final notifier = container.read(
        quizSessionNotifierProvider('q4').notifier,
      );
      notifier.startQuiz(quiz, testRng: Random(1));
      notifier.selectAnswer(0, notifier.displayedQuestion(quiz), quiz);

      await container.read(reviewStoreProvider.future);
      expect(container.read(reviewStoreProvider).valueOrNull?.all(), isEmpty);
    });

    test('duplicate signals do not corrupt state', () async {
      final quiz = singleQuestionQuiz('q5', wordQuestion('w-quiz-5'));
      final notifier = container.read(
        quizSessionNotifierProvider('q5').notifier,
      );
      notifier.startQuiz(quiz, testRng: Random(1));
      final displayed = notifier.displayedQuestion(quiz);
      notifier.selectAnswer(displayed.correctIndex, displayed, quiz);
      // Second tap on the answered question is a no-op (isAnswered guard).
      notifier.selectAnswer(displayed.correctIndex, displayed, quiz);

      final item = await readItem('w-quiz-5');
      expect(item?.successfulRecalls, 1);
    });
  });

  group('generators preserve source IDs', () {
    test('sentence builder attributes sentence + matched word', () {
      final sentence = SentenceModel(
        id: 's-gen-1',
        sentenceOlChiki: 'ᱤᱧ ᱫᱟᱜ ᱤᱧ ᱧᱩᱭᱟ',
        sentenceLatin: 'inj dag inj nyua',
        meaning: 'I drink water',
      );
      final word = WordModel(
        id: 'w-gen-1',
        wordOlChiki: 'ᱫᱟᱜ',
        wordLatin: 'dag',
        meaning: 'water',
      );
      final q = SentenceQuizBuilder.build(sentence, [word]);
      expect(q, isNotNull);
      expect(q!.sourceSentenceId, 's-gen-1');
      expect(q.sourceWordId, 'w-gen-1');
    });

    test(
      'sentence builder without a matched word attributes only sentence',
      () {
        final sentence = SentenceModel(
          id: 's-gen-2',
          sentenceOlChiki: 'ᱟᱭᱢᱟ ᱦᱚᱲ ᱠᱚ ᱦᱤᱡᱩᱜᱼᱟ',
          sentenceLatin: 'ayma hor ko hijuga',
          meaning: 'Many people will come',
        );
        final q = SentenceQuizBuilder.build(sentence, const []);
        // Either null (no blankable token) or sentence-only attribution.
        if (q != null) {
          expect(q.sourceSentenceId, 's-gen-2');
          expect(q.sourceWordId, isNull);
        }
      },
    );

    test('source IDs survive map round-trip and display shuffle', () {
      final q = QuizQuestion(
        promptOlChiki: 'ᱫᱟᱜ',
        optionsLatin: ['water', 'fire'],
        optionsOlChiki: ['ᱫᱟᱜ', 'ᱥᱮᱸᱜᱮᱞ'],
        correctIndex: 0, // ignore: avoid_redundant_argument_values
        sourceWordId: 'w-rt-1',
      );
      final restored = QuizQuestion.fromMap(q.toMap());
      expect(restored.sourceWordId, 'w-rt-1');
      // copyWith (used by displayedQuestion for option shuffling) keeps them.
      final shuffled = q.copyWith(optionsLatin: const ['fire', 'water']);
      expect(shuffled.sourceWordId, 'w-rt-1');
    });
  });
}
