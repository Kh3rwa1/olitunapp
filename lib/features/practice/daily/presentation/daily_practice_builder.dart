// Daily practice: a short mixed session assembled from content the app
// already has, so there is always something to practise after the
// curriculum is finished. No new content is authored here.
//
// Order of fill: due spaced-repetition items → unresolved quiz mistakes
// (mapped to their corpus word/sentence) → letters, words and sentences the
// learner has not seen in recent daily sessions. Items are unique per
// session. Cards are [ReviewCard]s so the review session renderer can show
// them unchanged.
//
// Lives in presentation (not domain) because [ReviewCard] and [MistakeItem]
// are presentation types of other features and the architecture gate
// forbids data/domain → foreign presentation imports.

import 'dart:math';

import '../../../../shared/models/content_models.dart';
import '../../../quiz/presentation/providers/mistake_item.dart';
import '../../../review/domain/review_item.dart';
import '../../../review/presentation/review_exercise.dart';

/// Prefix for letter cards' `itemId`. Letters are not part of the review
/// store (its item types are word/sentence), so a letter card carries
/// `itemType: word` and this prefix; never feed it to the review store.
const String letterItemIdPrefix = 'letter:';

bool isLetterCard(ReviewCard card) =>
    card.itemId.startsWith(letterItemIdPrefix);

class DailyPracticeBuilder {
  static const int defaultSize = 10;

  /// Builds up to [size] unique cards. [seedWordId] (word of the day) goes
  /// first when it exists in [words]. [recentlySeenIds] are skipped for the
  /// fresh-content fill unless nothing else is left.
  static List<ReviewCard> build({
    required List<MemoryItemState> due,
    required List<MistakeItem> mistakes,
    required List<WordModel> words,
    required List<SentenceModel> sentences,
    required List<LetterModel> letters,
    required Set<String> recentlySeenIds,
    Random? rng,
    int size = defaultSize,
    String? seedWordId,
  }) {
    final random = rng ?? Random();
    final activeWords = words.where((w) => w.isActive).toList();
    final activeSentences = sentences.where((s) => s.isActive).toList();
    final activeLetters = letters.where((l) => l.isActive).toList();
    final wordById = {for (final w in activeWords) w.id: w};
    final sentenceById = {for (final s in activeSentences) s.id: s};

    final cards = <ReviewCard>[];
    final used = <String>{};

    void addCard(ReviewCard? card) {
      if (card == null || cards.length >= size) return;
      if (!used.add(card.itemId)) return;
      cards.add(card);
    }

    // 0. Seed word (word of the day) first.
    final seed = seedWordId == null ? null : wordById[seedWordId];
    if (seed != null) {
      addCard(_freshWordCard(seed, activeWords));
    }

    // 1. Due review items, in the (already personalized) order given.
    for (final card in ReviewExerciseBuilder.buildCards(
      due: due,
      words: activeWords,
      sentences: activeSentences,
    )) {
      addCard(card);
    }

    // 2. Unresolved mistakes with a canonical word/sentence behind them.
    for (final mistake in mistakes.where((m) => !m.isResolved)) {
      final q = mistake.question;
      final wordId = q.sourceWordId?.trim();
      final sentenceId = q.sourceSentenceId?.trim();
      if (wordId != null && wordId.isNotEmpty && wordById[wordId] != null) {
        addCard(_freshWordCard(wordById[wordId]!, activeWords));
      } else if (sentenceId != null &&
          sentenceId.isNotEmpty &&
          sentenceById[sentenceId] != null) {
        addCard(_freshSentenceCard(sentenceById[sentenceId]!, activeSentences));
      }
    }

    // 3. Fresh fill: unseen first, then anything, shuffled per session.
    final fresh = <ReviewCard>[
      for (final l in activeLetters) _letterCard(l, activeLetters),
      for (final w in activeWords) ?_freshWordCard(w, activeWords),
      for (final s in activeSentences) ?_freshSentenceCard(s, activeSentences),
    ]..shuffle(random);
    final unseen = fresh.where((c) => !recentlySeenIds.contains(c.itemId));
    for (final card in unseen) {
      addCard(card);
    }
    for (final card in fresh) {
      if (cards.length >= size) break;
      addCard(card);
    }
    return cards;
  }

  /// A never-reviewed state so [ReviewExerciseBuilder] picks recognition.
  static MemoryItemState _freshState(String id, ReviewItemType type) {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return MemoryItemState(
      itemId: id,
      itemType: type,
      introducedAt: epoch,
      nextReviewAt: epoch,
    );
  }

  static ReviewCard? _freshWordCard(WordModel word, List<WordModel> pool) {
    final cards = ReviewExerciseBuilder.buildCards(
      due: [_freshState(word.id, ReviewItemType.word)],
      words: pool,
      sentences: const [],
    );
    return cards.isEmpty ? null : cards.first;
  }

  static ReviewCard? _freshSentenceCard(
    SentenceModel sentence,
    List<SentenceModel> pool,
  ) {
    final cards = ReviewExerciseBuilder.buildCards(
      due: [_freshState(sentence.id, ReviewItemType.sentence)],
      words: const [],
      sentences: pool,
    );
    return cards.isEmpty ? null : cards.first;
  }

  /// Letter recognition: Ol Chiki character → its Latin sound, with up to
  /// three other letters' sounds as distractors (deterministic per letter).
  static ReviewCard _letterCard(LetterModel letter, List<LetterModel> pool) {
    final correct = letter.transliterationLatin.trim().isEmpty
        ? '—'
        : letter.transliterationLatin.trim();
    final others = <String>[];
    final seen = {correct.toLowerCase()};
    for (final other in pool) {
      final t = other.transliterationLatin.trim();
      if (t.isEmpty) continue;
      if (seen.add(t.toLowerCase())) others.add(t);
    }
    others.shuffle(Random(letter.id.hashCode));
    final options = [
      correct,
      ...others.take(ReviewExerciseBuilder.maxOptions - 1),
    ]..shuffle(Random(letter.id.hashCode ^ 0x9E3779B9));
    return ReviewCard(
      itemId: '$letterItemIdPrefix${letter.id}',
      itemType: ReviewItemType.word,
      kind: ReviewPromptKind.olChikiToMeaning,
      promptOlChiki: letter.charOlChiki,
      promptLatin: '',
      promptMeaning: '',
      audioUrl: '',
      options: options,
      correctOptionIndex: options.indexOf(correct),
    );
  }
}
