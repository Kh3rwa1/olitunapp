import '../../../core/logging/app_logger.dart';
import '../../../shared/models/content/quiz_model.dart';
import '../../review/domain/review_corpus_identity.dart';
import '../../review/domain/review_item.dart';
import 'quiz_identity_validation.dart';

typedef QuizMemoryItem = ({String itemId, ReviewItemType itemType});

/// Maps a question to the exact corpus item under test.
///
/// Defensive rules (never text matching):
/// - Non-memory questions return null (never tracked in SRS).
/// - Questions carrying BOTH source IDs return null and log: silently
///   prioritizing one side would mistrack the other.
/// - Empty/whitespace IDs are treated as absent.
/// - When [corpusMap] is provided, the identity is verified (alias
///   resolution, tombstone and type checks); unverifiable IDs return null
///   with a logged warning so legacy invalid production quizzes fail safe
///   instead of mistracking.
/// - When [corpusMap] is null (offline/degraded), the raw structural
///   attribution is used so offline-first learning is never blocked; the
///   publish boundary remains fail-closed via [validateQuestionIdentity].
QuizMemoryItem? resolveQuizMemoryItem(
  QuizQuestion question, {
  ReviewCorpusIdentityMap? corpusMap,
}) {
  if (question.isNonMemory) return null;
  final wordId = question.sourceWordId?.trim() ?? '';
  final sentenceId = question.sourceSentenceId?.trim() ?? '';
  if (wordId.isNotEmpty && sentenceId.isNotEmpty) {
    AppLogger.warning(
      'QuizMemoryResolver: question carries both word "$wordId" and sentence '
      '"$sentenceId" IDs; refusing to guess. Relink to exactly one item.',
    );
    return null;
  }
  if (wordId.isEmpty && sentenceId.isEmpty) return null;

  if (corpusMap != null) {
    final validation = validateQuestionIdentity(question, corpusMap: corpusMap);
    if (!validation.isTrackable) {
      AppLogger.warning(
        'QuizMemoryResolver: skipping untrackable question '
        '(${validation.status.name}${validation.message == null ? '' : ': ${validation.message}'})',
      );
      return null;
    }
    return (
      itemId: validation.canonicalId!,
      itemType: validation.canonicalType!,
    );
  }

  if (wordId.isNotEmpty) {
    return (itemId: wordId, itemType: ReviewItemType.word);
  }
  return (itemId: sentenceId, itemType: ReviewItemType.sentence);
}
