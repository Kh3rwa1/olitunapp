// Review exercise builder: turns due memory states + verified corpus content
// into concrete retrieval cards.
//
// Uses ONLY existing content (WordModel / SentenceModel) and existing
// interactions (recognition MCQ, listening MCQ, Ol Chiki typing). No new
// content, no new corpus, no speech recognition.
//
// Exercise mix (deterministic per item, rotates with recall history):
// - word: recognition (Ol Chiki → meaning) → typing (meaning → Ol Chiki)
//   → listening (audio → meaning, falls back to recognition without audio)
// - sentence: recognition ↔ listening (typing a full sentence is too hard;
//   sentence production happens via the existing fill-blank quizzes)

import 'dart:math';

import '../../../shared/models/content_models.dart';
import '../../../shared/providers/language_settings_providers.dart';
import '../domain/review_item.dart';

enum ReviewPromptKind {
  olChikiToMeaning,
  meaningToTyping,
  audioToMeaning,
  audioToTyping,
  sentenceToMeaning,
}

extension ReviewPromptKindX on ReviewPromptKind {
  ReviewExerciseType get exerciseType => switch (this) {
    ReviewPromptKind.meaningToTyping ||
    ReviewPromptKind.audioToTyping => ReviewExerciseType.typing,
    ReviewPromptKind.audioToMeaning => ReviewExerciseType.listening,
    ReviewPromptKind.olChikiToMeaning ||
    ReviewPromptKind.sentenceToMeaning => ReviewExerciseType.recognition,
  };

  bool get isTyping =>
      this == ReviewPromptKind.meaningToTyping ||
      this == ReviewPromptKind.audioToTyping;
}

class ReviewCard {
  final String itemId;
  final ReviewItemType itemType;
  final ReviewPromptKind kind;

  /// What the learner sees (Ol Chiki word/sentence, meaning, or "🔊 listen").
  final String promptOlChiki;
  final String promptLatin;
  final String promptMeaning;
  final String audioUrl;

  /// MCQ options (meanings). Empty for typing cards.
  final List<String> options;
  final int correctOptionIndex;

  /// Expected answer for typing cards (Ol Chiki). Empty for MCQ cards.
  final String expectedTyping;

  const ReviewCard({
    required this.itemId,
    required this.itemType,
    required this.kind,
    required this.promptOlChiki,
    required this.promptLatin,
    required this.promptMeaning,
    required this.audioUrl,
    this.options = const [],
    this.correctOptionIndex = 0,
    this.expectedTyping = '',
  });

  ReviewExerciseType get exerciseType => kind.exerciseType;
}

class ReviewExerciseBuilder {
  static const int maxOptions = 4;

  /// Builds cards for [due] items, resolving each against the verified
  /// corpus. Items with no matching content (deleted/renamed) are skipped —
  /// review must never show a broken card.
  static List<ReviewCard> buildCards({
    required List<MemoryItemState> due,
    required List<WordModel> words,
    required List<SentenceModel> sentences,
  }) {
    final wordById = {for (final w in words) w.id: w};
    final sentenceById = {for (final s in sentences) s.id: s};
    final cards = <ReviewCard>[];

    for (final item in due) {
      switch (item.itemType) {
        case ReviewItemType.word:
          final word = wordById[item.itemId];
          if (word == null) continue;
          cards.add(_wordCard(item: item, word: word, pool: words));
        case ReviewItemType.sentence:
          final sentence = sentenceById[item.itemId];
          if (sentence == null) continue;
          cards.add(
            _sentenceCard(item: item, sentence: sentence, pool: sentences),
          );
      }
    }
    return cards;
  }

  static ReviewCard _wordCard({
    required MemoryItemState item,
    required WordModel word,
    required List<WordModel> pool,
  }) {
    final wordAudio = word.audioUrl ?? '';
    final hasAudio = wordAudio.trim().isNotEmpty;
    // Rotate with history so the same item is retrieved differently
    // across sessions (desirable difficulty, exercise diversity).
    final turn = item.successfulRecalls + item.failedRecalls;
    ReviewPromptKind kind;
    if (turn % 3 == 1 ||
        (item.successfulRecalls >= 1 && item.typingSuccesses == 0)) {
      // Push production early: the first recall proves recognition, the
      // second must prove production.
      kind = ReviewPromptKind.meaningToTyping;
    } else if (turn % 3 == 2 && hasAudio) {
      kind = ReviewPromptKind.audioToMeaning;
    } else {
      kind = ReviewPromptKind.olChikiToMeaning;
    }

    if (kind.isTyping) {
      return ReviewCard(
        itemId: item.itemId,
        itemType: ReviewItemType.word,
        kind: kind,
        promptOlChiki: '',
        promptLatin: word.wordLatin,
        promptMeaning: word.meaning,
        audioUrl: kind == ReviewPromptKind.audioToTyping ? wordAudio : '',
        expectedTyping: word.wordOlChiki,
      );
    }

    final meanings = _meaningOptions(
      correct: word.meaning,
      pool: pool.map((w) => w.meaning).toList(),
      seed: item.itemId.hashCode ^ item.successfulRecalls,
    );
    return ReviewCard(
      itemId: item.itemId,
      itemType: ReviewItemType.word,
      kind: kind,
      promptOlChiki: kind == ReviewPromptKind.audioToMeaning
          ? ''
          : word.wordOlChiki,
      promptLatin: kind == ReviewPromptKind.audioToMeaning
          ? ''
          : word.wordLatin,
      promptMeaning: '',
      audioUrl: kind == ReviewPromptKind.audioToMeaning ? wordAudio : '',
      options: meanings.options,
      correctOptionIndex: meanings.correctIndex,
    );
  }

  static ReviewCard _sentenceCard({
    required MemoryItemState item,
    required SentenceModel sentence,
    required List<SentenceModel> pool,
  }) {
    final sentenceAudio = sentence.audioUrl ?? '';
    final hasAudio = sentenceAudio.trim().isNotEmpty;
    final turn = item.successfulRecalls + item.failedRecalls;
    final kind = (turn % 2 == 1 && hasAudio)
        ? ReviewPromptKind.audioToMeaning
        : ReviewPromptKind.sentenceToMeaning;

    final meanings = _meaningOptions(
      correct: sentence.meaning,
      pool: pool.map((s) => s.meaning).toList(),
      seed: item.itemId.hashCode ^ item.successfulRecalls,
    );
    return ReviewCard(
      itemId: item.itemId,
      itemType: ReviewItemType.sentence,
      kind: kind,
      promptOlChiki: kind == ReviewPromptKind.audioToMeaning
          ? ''
          : sentence.sentenceOlChiki,
      promptLatin: kind == ReviewPromptKind.audioToMeaning
          ? ''
          : sentence.sentenceLatin,
      promptMeaning: '',
      audioUrl: kind == ReviewPromptKind.audioToMeaning ? sentenceAudio : '',
      options: meanings.options,
      correctOptionIndex: meanings.correctIndex,
    );
  }

  /// Deterministic distractor pick: correct + up to 3 distinct others,
  /// shuffled with [seed] so order varies per review but stays testable.
  static ({List<String> options, int correctIndex}) _meaningOptions({
    required String correct,
    required List<String> pool,
    required int seed,
  }) {
    final correctTrimmed = correct.trim().isEmpty ? '—' : correct.trim();
    final others = <String>[];
    final seen = {correctTrimmed.toLowerCase()};
    for (final candidate in pool) {
      final trimmed = candidate.trim();
      if (trimmed.isEmpty) continue;
      if (seen.add(trimmed.toLowerCase())) others.add(trimmed);
      if (others.length >= 12) break;
    }
    others.shuffle(Random(seed));
    final options = [correctTrimmed, ...others.take(maxOptions - 1)];
    options.shuffle(Random(seed ^ 0x9E3779B9));
    return (options: options, correctIndex: options.indexOf(correctTrimmed));
  }
}

/// Personalizes an already need-sorted due queue using onboarding data.
/// Stable: items with equal priority keep scheduler order, so personalization
/// re-ranks but never overrides urgency (overdue-first is preserved within
/// each tier because selectDue order feeds in).
///
/// - SPEAKER / HERITAGE (fluentSpeaker) + read/write goals
///   → production-first: items due for their typing proof come first.
/// - SPEAKING GOAL (speakSantali) → useful sentences before single words.
/// - EXAM GOAL (prepareForExam) → scheduler order untouched (structured).
/// - BEGINNER (none/understandsSome, default) → foundational words first.
List<MemoryItemState> prioritizeReviewItems(
  List<MemoryItemState> due, {
  required SantaliProficiency proficiency,
  required Set<LearningGoal> goals,
}) {
  if (due.length <= 1) return List.of(due);
  if (goals.contains(LearningGoal.prepareForExam)) return List.of(due);

  final wantsProduction =
      goals.contains(LearningGoal.readOlChiki) ||
      goals.contains(LearningGoal.writeOlChiki) ||
      proficiency == SantaliProficiency.beginnerReader ||
      proficiency == SantaliProficiency.fluentReader ||
      proficiency == SantaliProficiency.fluentSpeaker;
  final wantsSentences = goals.contains(LearningGoal.speakSantali);

  int rank(MemoryItemState item) {
    if (wantsProduction) {
      // Due for typing proof (recognized but never produced) goes first.
      if (item.successfulRecalls >= 1 && item.typingSuccesses == 0) return 0;
      if (item.itemType == ReviewItemType.word) return 1;
      return 2;
    }
    if (wantsSentences) {
      if (item.itemType == ReviewItemType.sentence) return 0;
      return 1;
    }
    // Beginner default: foundational vocabulary before sentences.
    if (item.itemType == ReviewItemType.word) return 0;
    return 1;
  }

  final ranked = List.of(due);
  // Dart's sort is stable: equal ranks keep scheduler (urgency) order.
  ranked.sort((a, b) => rank(a).compareTo(rank(b)));
  return ranked;
}
