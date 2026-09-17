import '../../../shared/models/content/quiz_model.dart';
import '../../review/domain/review_item.dart';

typedef QuizMemoryItem = ({String itemId, ReviewItemType itemType});

/// Maps a question to the exact corpus item under test.
/// Precedence: word (finer-grained — matches the review word cards) over
/// sentence (context). Empty IDs are treated as absent. Returns null when
/// the question carries no attribution (hand-written, lesson-block, admin,
/// legacy) — the scheduler stays silent rather than tracking wrong items.
QuizMemoryItem? resolveQuizMemoryItem(QuizQuestion question) {
  if (question.isNonMemory) return null;
  final wordId = question.sourceWordId?.trim() ?? '';
  if (wordId.isNotEmpty) {
    return (itemId: wordId, itemType: ReviewItemType.word);
  }
  final sentenceId = question.sourceSentenceId?.trim() ?? '';
  if (sentenceId.isNotEmpty) {
    return (itemId: sentenceId, itemType: ReviewItemType.sentence);
  }
  return null;
}
