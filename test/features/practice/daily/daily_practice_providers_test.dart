import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/home/presentation/providers/today_activity_provider.dart';
import 'package:itun/features/practice/daily/presentation/daily_practice_builder.dart';
import 'package:itun/features/practice/daily/presentation/daily_practice_outcome.dart';
import 'package:itun/features/practice/daily/presentation/providers/daily_practice_providers.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';
import 'package:itun/features/profile/presentation/providers/user_stats_provider.dart';
import 'package:itun/features/quiz/presentation/providers/mistake_provider.dart';
import 'package:itun/features/review/domain/review_item.dart';
import 'package:itun/features/review/presentation/review_queue_provider.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/learner_content_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoMistakes extends MistakeNotifier {
  @override
  List<MistakeItem> build() => [];
}

class _RecordingStats extends UserStatsNotifier {
  int starsAdded = 0;
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
  Future<void> addStars(int count) async {
    starsAdded += count;
  }
}

WordModel _word(String id) => WordModel(
  id: id,
  wordOlChiki: 'ᱚ$id',
  wordLatin: id,
  meaning: 'meaning $id',
);

void main() {
  final words = [for (var i = 0; i < 5; i++) _word('w$i')];
  final sentences = [
    SentenceModel(
      id: 's0',
      sentenceOlChiki: 'ᱥ',
      sentenceLatin: 's',
      meaning: 'sentence',
    ),
  ];
  final letters = [
    LetterModel(id: 'ᱚ', charOlChiki: 'ᱚ', transliterationLatin: 'La'),
  ];

  Future<ProviderContainer> container({
    AsyncValue<List<WordModel>>? wordsValue,
    AsyncValue<List<SentenceModel>>? sentencesValue,
    AsyncValue<List<LetterModel>>? lettersValue,
    List<MemoryItemState> due = const [],
    _RecordingStats? stats,
    Map<String, Object> prefsValues = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        learnerWordsProvider.overrideWithValue(
          wordsValue ?? AsyncValue.data(words),
        ),
        learnerSentencesProvider.overrideWithValue(
          sentencesValue ?? AsyncValue.data(sentences),
        ),
        learnerLettersProvider.overrideWithValue(
          lettersValue ?? AsyncValue.data(letters),
        ),
        personalizedDueItemsProvider.overrideWithValue(due),
        mistakeProvider.overrideWith(_NoMistakes.new),
        userStatsProvider.overrideWith(() => stats ?? _RecordingStats()),
        dailyPracticeRngProvider.overrideWithValue(Random(7)),
        todayActivityClockProvider.overrideWithValue(
          () => DateTime(2026, 11, 10, 12),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('loading while any corpus list loads', () async {
    final c = await container(lettersValue: const AsyncValue.loading());
    expect(c.read(dailyPracticeCardsProvider).isLoading, isTrue);
  });

  test('error only when every corpus list failed', () async {
    const failed = AsyncValue<List<WordModel>>.error('x', StackTrace.empty);
    final partial = await container(wordsValue: failed);
    expect(partial.read(dailyPracticeCardsProvider).hasValue, isTrue);
    expect(partial.read(dailyPracticeCardsProvider).value, isNotEmpty);

    final all = await container(
      wordsValue: failed,
      sentencesValue: const AsyncValue.error('x', StackTrace.empty),
      lettersValue: const AsyncValue.error('x', StackTrace.empty),
    );
    expect(all.read(dailyPracticeCardsProvider).hasError, isTrue);
  });

  test('cards: word of the day first, due items next, all unique', () async {
    final c = await container(
      due: [
        MemoryItemState(
          itemId: 's0',
          itemType: ReviewItemType.sentence,
          introducedAt: DateTime.utc(2026),
          nextReviewAt: DateTime.utc(2026),
        ),
      ],
    );
    final cards = c.read(dailyPracticeCardsProvider).requireValue;
    expect(cards.length, 7); // 5 words + 1 sentence + 1 letter
    expect(cards.first.itemId, startsWith('w'));
    expect(cards[1].itemId, 's0');
    expect(cards.map((x) => x.itemId).toSet().length, 7);
  });

  test('seed override: explicit word first, empty string disables', () async {
    final c = await container();
    c.read(dailyPracticeSeedWordProvider.notifier).state = 'w3';
    expect(c.read(dailyPracticeCardsProvider).requireValue.first.itemId, 'w3');

    c.read(dailyPracticeSeedWordProvider.notifier).state = '';
    final cards = c.read(dailyPracticeCardsProvider).requireValue;
    expect(cards.length, 7);
  });

  test('finisher awards stars, logs minutes and marks ids seen', () async {
    final stats = _RecordingStats();
    final c = await container(
      stats: stats,
      prefsValues: {'daily_goal_minutes': 5},
    );
    c.listen(todayMinutesProvider, (_, _) {});
    final cards = c.read(dailyPracticeCardsProvider).requireValue;

    final outcome = await c.read(dailyPracticeFinisherProvider)(
      answered: [
        (card: cards[0], correct: true),
        (card: cards[1], correct: false),
      ],
      elapsed: const Duration(minutes: 1, seconds: 30),
    );

    expect(outcome.stars, dailyPracticeStarsPerCorrect);
    expect(stats.starsAdded, dailyPracticeStarsPerCorrect);
    expect(outcome.minutes, 2);
    expect(c.read(todayMinutesProvider), 2);
    expect(c.read(recentPracticeLogProvider).ids(), {
      cards[0].itemId,
      cards[1].itemId,
    });
    expect(isLetterCard(cards[0]), isFalse);
  });

  test('finisher with nothing answered changes nothing', () async {
    final stats = _RecordingStats();
    final c = await container(stats: stats);
    final outcome = await c.read(dailyPracticeFinisherProvider)(
      answered: const [],
      elapsed: const Duration(minutes: 3),
    );
    expect(outcome.total, 0);
    expect(stats.starsAdded, 0);
    expect(c.read(recentPracticeLogProvider).ids(), isEmpty);
  });
}
