// Review exercise builder + personalization tests.
// Uses fabricated Word/Sentence models (no corpus dependency); the builder
// contract is: only verified content in, concrete cards out, unknowns skipped.

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/review/domain/memory_scheduler.dart';
import 'package:itun/features/review/domain/review_item.dart';
import 'package:itun/features/review/presentation/review_exercise.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/language_settings_providers.dart';

WordModel word(
  String id, {
  String olChiki = 'ᱫᱟᱜ',
  String meaning = 'water',
  String audio = 'https://x/audio.mp3',
}) => WordModel(
  id: id,
  wordOlChiki: olChiki,
  wordLatin: 'dag',
  meaning: meaning,
  audioUrl: audio,
);

SentenceModel sentence(String id, {String meaning = 'I drink water'}) =>
    SentenceModel(
      id: id,
      sentenceOlChiki: 'ᱤᱧ ᱫᱟᱜ ᱤᱧ ᱧᱩᱭᱟ',
      sentenceLatin: 'inj dag inj nyua',
      meaning: meaning,
      audioUrl: 'https://x/s.mp3',
    );

MemoryItemState dueItem(
  String id, {
  ReviewItemType type = ReviewItemType.word,
  int successes = 0,
  int fails = 0,
}) {
  final t0 = DateTime.utc(2026, 1, 1, 9);
  var item = MemoryScheduler.introduce(itemId: id, itemType: type, now: t0);
  var now = t0;
  for (var i = 0; i < successes; i++) {
    item = MemoryScheduler.recordRecall(
      item,
      RecallInput(
        correct: true,
        exerciseType: ReviewExerciseType.recognition,
        now: now,
      ),
    );
    now = item.nextReviewAt;
  }
  for (var i = 0; i < fails; i++) {
    item = MemoryScheduler.recordRecall(
      item,
      RecallInput(
        correct: false,
        exerciseType: ReviewExerciseType.recognition,
        now: now,
      ),
    );
    now = item.nextReviewAt;
  }
  // Force due regardless of scheduling (builder input contract is "due").
  return item.copyWith(nextReviewAt: t0);
}

void main() {
  group('ReviewExerciseBuilder', () {
    test(
      'skips items with no matching corpus content (never broken cards)',
      () {
        final cards = ReviewExerciseBuilder.buildCards(
          due: [dueItem('ghost')],
          words: [word('w1')],
          sentences: const [],
        );
        expect(cards, isEmpty);
      },
    );

    test(
      'first recall is recognition with the correct meaning among options',
      () {
        final cards = ReviewExerciseBuilder.buildCards(
          due: [dueItem('w1')],
          words: [
            word('w1'),
            word('w2', meaning: 'fire', olChiki: 'ᱥᱮᱸᱜᱮᱞ'),
          ],
          sentences: const [],
        );
        expect(cards, hasLength(1));
        final card = cards.first;
        expect(card.kind, ReviewPromptKind.olChikiToMeaning);
        expect(card.promptOlChiki, 'ᱫᱟᱜ');
        expect(card.options, contains('water'));
        expect(card.options[card.correctOptionIndex], 'water');
        expect(card.options.length, lessThanOrEqualTo(4));
      },
    );

    test('second recall pushes typing production (meaning -> Ol Chiki)', () {
      final cards = ReviewExerciseBuilder.buildCards(
        due: [dueItem('w1', successes: 1)],
        words: [word('w1')],
        sentences: const [],
      );
      expect(cards.first.kind, ReviewPromptKind.meaningToTyping);
      expect(cards.first.expectedTyping, 'ᱫᱟᱜ');
      expect(cards.first.options, isEmpty);
      expect(cards.first.exerciseType, ReviewExerciseType.typing);
    });

    test('listening card carries audio and empty text prompt', () {
      // Production already proven once -> rotation reaches listening.
      final item = dueItem('w1', successes: 2).copyWith(typingSuccesses: 1);
      final cards = ReviewExerciseBuilder.buildCards(
        due: [item],
        words: [word('w1')],
        sentences: const [],
      );
      final card = cards.first;
      expect(card.kind, ReviewPromptKind.audioToMeaning);
      expect(card.audioUrl, isNotEmpty);
      expect(card.promptOlChiki, isEmpty);
      expect(card.exerciseType, ReviewExerciseType.listening);
    });

    test(
      'words without audio fall back to recognition (no dead audio btn)',
      () {
        final item = dueItem('w1', successes: 2).copyWith(typingSuccesses: 1);
        final cards = ReviewExerciseBuilder.buildCards(
          due: [item],
          words: [word('w1', audio: '')],
          sentences: const [],
        );
        expect(cards.first.kind, ReviewPromptKind.olChikiToMeaning);
      },
    );

    test(
      'sentence cards stay recognition/listening (no full-sentence typing)',
      () {
        final cards = ReviewExerciseBuilder.buildCards(
          due: [dueItem('s1', type: ReviewItemType.sentence, successes: 3)],
          words: const [],
          sentences: [
            sentence('s1'),
            sentence('s2', meaning: 'She sings a song'),
          ],
        );
        expect(cards, hasLength(1));
        expect(cards.first.kind.isTyping, isFalse);
        expect(cards.first.options, contains('I drink water'));
      },
    );

    test('distractor order is deterministic per review (seeded)', () {
      List<ReviewCard> build() => ReviewExerciseBuilder.buildCards(
        due: [dueItem('w1')],
        words: [
          word('w1'),
          word('w2', meaning: 'fire', olChiki: 'ᱥᱮᱸᱜᱮᱞ'),
          word('w3', meaning: 'earth', olChiki: 'ᱚᱛ'),
        ],
        sentences: const [],
      );
      expect(build().first.options, build().first.options);
    });
  });

  group('prioritizeReviewItems', () {
    final items = [dueItem('s1', type: ReviewItemType.sentence), dueItem('w1')];

    test('beginner default: foundational words before sentences', () {
      final ranked = prioritizeReviewItems(
        items,
        proficiency: SantaliProficiency.none,
        goals: const {},
      );
      expect(ranked.map((e) => e.itemId), ['w1', 's1']);
    });

    test('speaking goal: useful sentences first', () {
      final ranked = prioritizeReviewItems(
        items,
        proficiency: SantaliProficiency.understandsSome,
        goals: {LearningGoal.speakSantali},
      );
      expect(ranked.map((e) => e.itemId), ['s1', 'w1']);
    });

    test('reader goal: items due for typing proof first', () {
      final recognized = dueItem('w1', successes: 1); // needs production
      final fresh = dueItem('w2');
      final ranked = prioritizeReviewItems(
        [fresh, recognized],
        proficiency: SantaliProficiency.beginnerReader,
        goals: const {},
      );
      expect(ranked.first.itemId, 'w1');
    });

    test('exam goal: scheduler order untouched (structured)', () {
      final ranked = prioritizeReviewItems(
        items,
        proficiency: SantaliProficiency.none,
        goals: {LearningGoal.prepareForExam},
      );
      expect(ranked.map((e) => e.itemId), ['s1', 'w1']);
    });

    test('stable: equal ranks keep urgency order', () {
      final a = dueItem('w1');
      final b = dueItem('w2');
      final ranked = prioritizeReviewItems(
        [a, b],
        proficiency: SantaliProficiency.none,
        goals: const {},
      );
      expect(ranked.map((e) => e.itemId), ['w1', 'w2']);
    });
  });
}
