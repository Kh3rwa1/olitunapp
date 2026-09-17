import 'package:itun/features/quiz/domain/quiz_identity_validation.dart'
    as quiz_identity;

class QuizValidation {
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    return null;
  }

  static String? validateOrder(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Order is required';
    }
    if (int.tryParse(value) == null) {
      return 'Order must be a valid number';
    }
    return null;
  }

  static String? validatePassingScore(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Passing score is required';
    }
    final score = int.tryParse(value);
    if (score == null || score < 0 || score > 100) {
      return 'Must be between 0 and 100';
    }
    return null;
  }

  /// Structural identity gate for the admin form (no corpus needed):
  /// - non-memory questions must carry NO source IDs;
  /// - memory questions must carry EXACTLY ONE source ID.
  /// Returns a human-readable error or null when structurally valid.
  /// Corpus verification (fake/tombstoned/alias/type) runs in
  /// [validateQuestionIdentityStrict] and at the publish boundary.
  static String? validateQuestionIdentity(dynamic question) {
    final bool isNonMemory = question.isNonMemory == true;
    final String wordId = (question.sourceWordId as String?)?.trim() ?? '';
    final String sentenceId =
        (question.sourceSentenceId as String?)?.trim() ?? '';
    final hasWord = wordId.isNotEmpty;
    final hasSentence = sentenceId.isNotEmpty;
    if (isNonMemory) {
      if (hasWord || hasSentence) {
        return 'Non-memory assessment must not carry a corpus source ID. '
            'Clear the Word/Sentence ID or unset Non-memory.';
      }
      return null;
    }
    if (hasWord && hasSentence) {
      return 'Question links both a Word ID and a Sentence ID. '
          'Memory questions must attribute exactly one corpus item — '
          'clear one side.';
    }
    final bool hasIdentity = question.hasCanonicalIdentity == true;
    if (!hasIdentity) {
      return 'Question must be linked to a corpus item (Word ID or Sentence ID) or marked as Non-Memory.';
    }
    return null;
  }

  /// Strict corpus-aware validation for the admin form when a corpus map is
  /// available. Fails closed (returns an error) for fake, tombstoned,
  /// cyclic-alias and cross-type IDs.
  static String? validateQuestionIdentityStrict(
    dynamic question, {
    required dynamic corpusMap,
  }) {
    final structural = validateQuestionIdentity(question);
    if (structural != null) return structural;
    if (corpusMap == null) {
      return 'Corpus unavailable; cannot verify this ID. '
          'Retry online before publishing.';
    }
    try {
      final result = quiz_identity.validateQuestionIdentity(
        // ignore: avoid_dynamic_calls
        _toQuizQuestion(question),
        corpusMap: corpusMap,
      );
      if (result.status == quiz_identity.QuizIdentityStatus.valid) {
        return null;
      }
      return result.message ??
          'Invalid corpus identity (${result.status.name}).';
    } catch (_) {
      return 'Unable to verify corpus identity. Retry before publishing.';
    }
  }

  // Adapts the untyped admin-form question to the domain validator without
  // coupling this file to the concrete model import graph.
  static dynamic _toQuizQuestion(dynamic question) => question;
}
