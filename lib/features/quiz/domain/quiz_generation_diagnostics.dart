import '../../../shared/models/content_models.dart';

/// Bounded rejection reason codes for lesson quiz generation.
///
/// Only the lesson ID and block index travel with a rejection — sentence
/// text and translations are never logged.
abstract final class QuizRejectionReason {
  static const String missingOlChiki = 'missing_ol_chiki';
  static const String missingLatin = 'missing_latin';
  static const String missingMeaning = 'missing_meaning';
  static const String malformedData = 'malformed_data';
  static const String duplicateContent = 'duplicate_content';
  static const String insufficientDistractors = 'insufficient_distractors';

  static const List<String> values = [
    missingOlChiki,
    missingLatin,
    missingMeaning,
    malformedData,
    duplicateContent,
    insufficientDistractors,
  ];
}

/// Why a single lesson block produced no question. Carries the block index
/// and reason codes only — never block text.
class BlockRejection {
  final int blockIndex;
  final List<String> reasons;

  const BlockRejection({required this.blockIndex, required this.reasons});
}

/// Typed outcome of lesson quiz generation.
///
/// A lesson with no generatable questions yields [isFailure] with an empty
/// quiz — callers must surface an honest "unavailable" state and must never
/// convert the failure into placeholder questions.
class QuizGenerationResult {
  /// Maximum rejection entries retained per result (bounded diagnostics).
  static const int maxRejections = 32;

  final QuizModel quiz;
  final String lessonId;
  final int validBlockCount;
  final List<BlockRejection> rejections;

  const QuizGenerationResult({
    required this.quiz,
    required this.lessonId,
    required this.validBlockCount,
    this.rejections = const [],
  });

  bool get isSuccess => quiz.questions.isNotEmpty;
  bool get isFailure => quiz.questions.isEmpty;
}
