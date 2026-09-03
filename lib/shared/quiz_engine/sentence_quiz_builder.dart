import '../../shared/models/content_models.dart';
import 'quiz_engine.dart';

/// Helper for constructing fill-in-the-blank quiz questions from sentence models.
class SentenceQuizBuilder {
  static QuizQuestion? build(SentenceModel sentence, List<WordModel> words) {
    final matchedWord = words
        .where(
          (word) =>
              word.wordOlChiki.length >= 2 &&
              sentence.sentenceOlChiki.contains(word.wordOlChiki),
        )
        .firstOrNull;

    if (matchedWord != null) {
      return matchedSentenceQuestion(sentence, matchedWord, words);
    }

    final targetWord = sentence.sentenceOlChiki
        .split(RegExp(r'\s+'))
        .map((word) => word.replaceAll(RegExp(r'[᱾,?.!\-#%&()]'), '').trim())
        .where((word) => word.length >= 3)
        .firstOrNull;
    if (targetWord == null) return null;

    // Distractors must not duplicate the correct option textually — a dupe
    // makes a correct answer indistinguishable from a wrong one.
    final options = <String>[
      targetWord,
      ...words
          .takeShuffled(6)
          .map((word) => word.wordOlChiki)
          .where((option) => option != targetWord)
          .take(3),
    ];
    return fillBlankQuestion(
      sentence: sentence,
      targetWord: targetWord,
      optionsOlChiki: options,
      optionsLatin: options,
      promptLatin: 'Complete the sentence with the correct word.',
    );
  }

  static QuizQuestion matchedSentenceQuestion(
    SentenceModel sentence,
    WordModel matchedWord,
    List<WordModel> words,
  ) {
    final options = <WordModel>[
      matchedWord,
      ...QuizEngine.wordDistractors(matchedWord, words),
    ]..shuffle();

    return fillBlankQuestion(
      sentence: sentence,
      targetWord: matchedWord.wordOlChiki,
      optionsOlChiki: options.map((word) => word.wordOlChiki).toList(),
      optionsLatin: options.map(QuizEngine.meaningDisplay).toList(),
      promptLatin:
          'Choose the word that means "${matchedWord.meaning}" to complete the sentence.',
    );
  }

  static QuizQuestion fillBlankQuestion({
    required SentenceModel sentence,
    required String targetWord,
    required List<String> optionsOlChiki,
    required List<String> optionsLatin,
    required String promptLatin,
  }) {
    final indices = List<int>.generate(optionsOlChiki.length, (index) => index)
      ..shuffle();
    final shuffledOptionsOlChiki = [
      for (final index in indices) optionsOlChiki[index],
    ];
    final shuffledOptionsLatin = [
      for (final index in indices) optionsLatin[index],
    ];

    return QuizQuestion(
      type: 'fill_blank',
      promptOlChiki: 'Fill in the blank:',
      promptLatin: promptLatin,
      optionsOlChiki: shuffledOptionsOlChiki,
      optionsLatin: shuffledOptionsLatin,
      correctIndex: indices.indexOf(0),
      blankSentenceOlChiki: blankTargetInSentence(
        sentence.sentenceOlChiki,
        targetWord,
      ),
      blankSentenceLatin: sentence.meaning,
      correctAnswer: targetWord,
    );
  }

  /// Blanks the target word in the sentence — but only when it appears as a
  /// whole (punctuation-stripped) token. Naive `replaceAll` blanks the target
  /// inside unrelated longer words, corrupting the displayed sentence.
  static String blankTargetInSentence(
    String sentenceOlChiki,
    String targetWord,
  ) {
    final tokens = sentenceOlChiki.split(RegExp(r'\s+'));
    final blanked = tokens
        .map((token) {
          final stripped = token.replaceAll(RegExp(r'[᱾,?.!\-#%&()]'), '');
          return stripped == targetWord
              ? token.replaceAll(targetWord, '___')
              : token;
        })
        .join(' ');
    // Whole-token blanking missed (punctuation shapes differ) — fall back to
    // the naive blank so the question still shows a gap.
    return blanked == sentenceOlChiki
        ? sentenceOlChiki.replaceAll(targetWord, '___')
        : blanked;
  }
}

extension _ShuffledTake<T> on List<T> {
  List<T> takeShuffled(int count) {
    if (count <= 0 || isEmpty) return const [];
    return (List<T>.from(this)..shuffle()).take(count).toList();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
