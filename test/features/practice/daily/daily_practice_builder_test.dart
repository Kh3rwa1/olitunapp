import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/practice/daily/presentation/daily_practice_builder.dart';
import 'package:itun/features/quiz/presentation/providers/mistake_item.dart';
import 'package:itun/features/review/domain/review_item.dart';
import 'package:itun/features/review/presentation/review_exercise.dart';
import 'package:itun/shared/models/content_models.dart';

WordModel _word(String id, {String? audio}) => WordModel(
  id: id,
  wordOlChiki: 'ᱚ$id',
  wordLatin: 'w$id',
  meaning: 'meaning $id',
  audioUrl: audio,
);

SentenceModel _sentence(String id) => SentenceModel(
  id: id,
  sentenceOlChiki: 'ᱥ$id',
  sentenceLatin: 's$id',
  meaning: 'sentence meaning $id',
);

LetterModel _letter(String id, String sound) =>
    LetterModel(id: id, charOlChiki: id, transliterationLatin: sound);

MemoryItemState _due(String id, ReviewItemType type) => MemoryItemState(
  itemId: id,
  itemType: type,
  introducedAt: DateTime.utc(2026),
  nextReviewAt: DateTime.utc(2026),
  successfulRecalls: 2,
);

MistakeItem _mistake({
  String? wordId,
  String? sentenceId,
  bool resolved = false,
}) => MistakeItem(
  quizId: 'q',
  questionIndex: 0,
  question: QuizQuestion(
    promptOlChiki: 'x',
    sourceWordId: wordId,
    sourceSentenceId: sentenceId,
  ),
  addedAt: '2026-11-01',
  isResolved: resolved,
);

void main() {
  final words = [for (var i = 0; i < 6; i++) _word('w$i')];
  final sentences = [for (var i = 0; i < 4; i++) _sentence('s$i')];
  final letters = [
    _letter('ᱚ', 'La'),
    _letter('ᱛ', 'At'),
    _letter('ᱜ', 'Ag'),
    _letter('ᱝ', 'Ang'),
  ];

  List<ReviewCard> build({
    List<MemoryItemState> due = const [],
    List<MistakeItem> mistakes = const [],
    Set<String> recent = const {},
    int size = 10,
    String? seed,
    int rngSeed = 1,
  }) => DailyPracticeBuilder.build(
    due: due,
    mistakes: mistakes,
    words: words,
    sentences: sentences,
    letters: letters,
    recentlySeenIds: recent,
    rng: Random(rngSeed),
    size: size,
    seedWordId: seed,
  );

  test('fills to size with unique items from the corpus', () {
    final cards = build();
    expect(cards.length, 10);
    expect(cards.map((c) => c.itemId).toSet().length, 10);
  });

  test('never exceeds the corpus and respects a small size', () {
    expect(build(size: 3).length, 3);
    final tiny = DailyPracticeBuilder.build(
      due: const [],
      mistakes: const [],
      words: [_word('only')],
      sentences: const [],
      letters: const [],
      recentlySeenIds: const {},
      rng: Random(1),
    );
    expect(tiny.map((c) => c.itemId), ['only']);
  });

  test('due items come first, then mistakes, then fresh content', () {
    final cards = build(
      due: [
        _due('w3', ReviewItemType.word),
        _due('s1', ReviewItemType.sentence),
      ],
      mistakes: [
        _mistake(wordId: 'w5'),
        _mistake(sentenceId: 's2'),
      ],
    );
    expect(cards.map((c) => c.itemId).take(4), ['w3', 's1', 'w5', 's2']);
    expect(cards.map((c) => c.itemId).toSet().length, cards.length);
  });

  test('seed word goes first and is not duplicated by a due item', () {
    final cards = build(seed: 'w2', due: [_due('w2', ReviewItemType.word)]);
    expect(cards.first.itemId, 'w2');
    expect(cards.where((c) => c.itemId == 'w2').length, 1);
    // A seed that is not in the corpus is ignored.
    expect(build(seed: 'nope').first.itemId, isNot('nope'));
  });

  test('skips resolved mistakes and mistakes without a corpus item', () {
    final cards = build(
      size: 2,
      mistakes: [
        _mistake(wordId: 'w1', resolved: true),
        _mistake(wordId: 'deleted'),
        _mistake(wordId: 'w4'),
      ],
    );
    expect(cards.first.itemId, 'w4');
  });

  test('recently seen items are used only when nothing else is left', () {
    final allIds = {
      for (final w in words) w.id,
      for (final s in sentences) s.id,
      for (final l in letters) '$letterItemIdPrefix${l.id}',
    };
    final recent = allIds.where((id) => id != 'w0' && id != 's0').toSet();
    final cards = build(recent: recent, size: 4);
    expect(cards.take(2).map((c) => c.itemId).toSet(), {'w0', 's0'});
    expect(cards.length, 4);
  });

  test('letter cards are recognition MCQs over letter sounds', () {
    final cards = build(size: 14);
    final letterCards = cards.where(isLetterCard).toList();
    expect(letterCards.length, 4);
    for (final card in letterCards) {
      expect(card.kind, ReviewPromptKind.olChikiToMeaning);
      expect(card.options.length, 4);
      expect(card.options.toSet().length, 4);
      final letter = letters.firstWhere(
        (l) => '$letterItemIdPrefix${l.id}' == card.itemId,
      );
      expect(card.promptOlChiki, letter.charOlChiki);
      expect(
        card.options[card.correctOptionIndex],
        letter.transliterationLatin,
      );
    }
  });

  test('fresh word and sentence cards are recognition with 4 options', () {
    final cards = build(size: 14).where((c) => !isLetterCard(c));
    for (final card in cards) {
      expect(card.exerciseType, ReviewExerciseType.recognition);
      expect(card.options, isNotEmpty);
      expect(card.correctOptionIndex, inInclusiveRange(0, 3));
    }
  });

  test('inactive content is excluded', () {
    final cards = DailyPracticeBuilder.build(
      due: const [],
      mistakes: const [],
      words: [
        WordModel(
          id: 'off',
          wordOlChiki: 'x',
          wordLatin: 'x',
          meaning: 'x',
          isActive: false,
        ),
        _word('on'),
      ],
      sentences: const [],
      letters: const [],
      recentlySeenIds: const {},
      rng: Random(1),
    );
    expect(cards.map((c) => c.itemId), ['on']);
  });
}
