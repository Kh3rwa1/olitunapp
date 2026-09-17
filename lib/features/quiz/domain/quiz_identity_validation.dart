// Canonical learning-item identity validation (domain layer).
//
// Invariants enforced for every quiz question:
//
// A. Memory question (isNonMemory == false):
//    - exactly one source ID is present (word XOR sentence — never both,
//      never neither)
//    - the source ID resolves through [ReviewCorpusIdentityMap] when a map
//      is available (no fake IDs)
//    - the final canonical ID exists in the active corpus
//    - the final canonical item type matches the source field (no
//      cross-type collision: a word field must resolve to a word)
//    - the canonical item is not tombstoned
//    - alias chains resolve without cycles (handled by the map)
// B. Non-memory question (isNonMemory == true):
//    - sourceWordId and sourceSentenceId are both null/empty
//
// A question is never both attributed and non-memory.
//
// Verification depth depends on caller:
// - structural checks (exactly-one, exclusivity) need no corpus and are
//   enforced at every boundary, including offline publish attempts.
// - corpus checks (existence, alias, tombstone, type) require a
//   [ReviewCorpusIdentityMap]; when unavailable the result is
//   [QuizIdentityStatus.unverified] (NOT valid) so publish boundaries fail
//   closed while runtime read paths can explicitly choose a documented
//   degraded policy.

import '../../review/domain/review_corpus_identity.dart';
import '../../review/domain/review_item.dart';
import '../../../core/logging/app_logger.dart';
import '../../../shared/models/content/quiz_model.dart';

/// Validation outcome. Only [valid] and [explicitNonMemory] permit
/// scheduler tracking; only [valid]/[explicitNonMemory] permit publication.
enum QuizIdentityStatus {
  valid,
  explicitNonMemory,
  unverified,
  bothIds,
  missingAttribution,
  nonMemoryWithId,
  unknownId,
  tombstonedId,
  aliasCycle,
  typeMismatch,
}

class QuizIdentityValidation {
  final QuizIdentityStatus status;
  final String? message;
  final String? canonicalId;
  final ReviewItemType? canonicalType;
  final bool resolvedViaAlias;

  const QuizIdentityValidation({
    required this.status,
    this.message,
    this.canonicalId,
    this.canonicalType,
    this.resolvedViaAlias = false,
  });

  bool get isPublishable =>
      status == QuizIdentityStatus.valid ||
      status == QuizIdentityStatus.explicitNonMemory;

  /// Scheduler tracking is allowed only for valid memory questions with a
  /// verified canonical id.
  bool get isTrackable =>
      status == QuizIdentityStatus.valid && canonicalId != null;
}

/// Structural validation only (no corpus needed). Enforced at every
/// boundary including offline.
QuizIdentityValidation validateQuestionIdentityStructure(QuizQuestion q) {
  final wordId = q.sourceWordId?.trim() ?? '';
  final sentenceId = q.sourceSentenceId?.trim() ?? '';
  final hasWord = wordId.isNotEmpty;
  final hasSentence = sentenceId.isNotEmpty;

  if (q.isNonMemory) {
    if (hasWord || hasSentence) {
      return const QuizIdentityValidation(
        status: QuizIdentityStatus.nonMemoryWithId,
        message:
            'Non-memory assessment must not carry a corpus source ID. '
            'Clear the Word/Sentence ID or unset Non-memory.',
      );
    }
    return const QuizIdentityValidation(
      status: QuizIdentityStatus.explicitNonMemory,
    );
  }
  if (hasWord && hasSentence) {
    return const QuizIdentityValidation(
      status: QuizIdentityStatus.bothIds,
      message:
          'Question links both a Word ID and a Sentence ID. '
          'Memory questions must attribute exactly one corpus item.',
    );
  }
  if (!hasWord && !hasSentence) {
    return const QuizIdentityValidation(
      status: QuizIdentityStatus.missingAttribution,
      message:
          'Question must be linked to a corpus item (Word ID or Sentence ID) '
          'or marked as Non-memory assessment.',
    );
  }
  return const QuizIdentityValidation(status: QuizIdentityStatus.valid);
}

/// Full validation against the verified corpus. Fails closed (never
/// `valid`) when [corpusMap] is null or the corpus is unavailable.
QuizIdentityValidation validateQuestionIdentity(
  QuizQuestion q, {
  ReviewCorpusIdentityMap? corpusMap,
}) {
  final structural = validateQuestionIdentityStructure(q);
  if (structural.status != QuizIdentityStatus.valid) return structural;

  if (corpusMap == null ||
      corpusMap.availabilityState ==
          CorpusAvailabilityState.corpusUnavailable) {
    return const QuizIdentityValidation(
      status: QuizIdentityStatus.unverified,
      message: 'Corpus unavailable; identity cannot be verified.',
    );
  }

  final wordId = q.sourceWordId?.trim() ?? '';
  final isWordField = wordId.isNotEmpty;
  final rawId = isWordField ? wordId : (q.sourceSentenceId?.trim() ?? '');
  final expectedType = isWordField
      ? ReviewItemType.word
      : ReviewItemType.sentence;

  // Tombstones (raw or canonical) are never trackable.
  if (corpusMap.isTombstoned(rawId)) {
    return QuizIdentityValidation(
      status: QuizIdentityStatus.tombstonedId,
      message:
          'Source ID "$rawId" is retired (tombstoned). Relink the question.',
    );
  }

  String canonical = rawId;
  var viaAlias = false;
  final aliasTarget = corpusMap.resolveCanonicalId(
    rawId,
    expectedType: expectedType,
  );
  if (corpusMap.aliasFor(rawId) != null) {
    // Aliased: must resolve cleanly, else the chain is broken/cyclic.
    if (aliasTarget == null) {
      return QuizIdentityValidation(
        status: QuizIdentityStatus.aliasCycle,
        message:
            'Source ID "$rawId" has a broken alias chain (cycle, type '
            'mismatch, or retired target). Relink the question.',
      );
    }
    canonical = aliasTarget;
    viaAlias = true;
  } else if (!corpusMap.isActive(rawId)) {
    return QuizIdentityValidation(
      status: QuizIdentityStatus.unknownId,
      message:
          'Source ID "$rawId" is not in the verified corpus. '
          'Pick a valid item or mark Non-memory.',
    );
  }

  // Cross-type collision: the source FIELD must match the canonical TYPE.
  final canonicalIsWord = corpusMap.isWord(canonical);
  final canonicalIsSentence = corpusMap.isSentence(canonical);
  if (expectedType == ReviewItemType.word &&
      (!canonicalIsWord || canonicalIsSentence)) {
    // An id present in both sets is a corpus integrity violation; an id in
    // neither (but "active" via legacy path) is treated as unknown above.
    // Reaching here with a word field resolving to a sentence is a type
    // mismatch.
    if (canonicalIsSentence) {
      return QuizIdentityValidation(
        status: QuizIdentityStatus.typeMismatch,
        message:
            'Word field "$rawId" resolves to a sentence item. '
            'Use the Sentence field or relink.',
      );
    }
  }
  if (expectedType == ReviewItemType.sentence &&
      (!canonicalIsSentence || canonicalIsWord)) {
    if (canonicalIsWord) {
      return QuizIdentityValidation(
        status: QuizIdentityStatus.typeMismatch,
        message:
            'Sentence field "$rawId" resolves to a word item. '
            'Use the Word field or relink.',
      );
    }
  }

  if (corpusMap.isTombstoned(canonical)) {
    return QuizIdentityValidation(
      status: QuizIdentityStatus.tombstonedId,
      message: 'Canonical ID "$canonical" is retired (tombstoned). Relink.',
    );
  }

  return QuizIdentityValidation(
    status: QuizIdentityStatus.valid,
    canonicalId: canonical,
    canonicalType: expectedType,
    resolvedViaAlias: viaAlias,
  );
}

/// Normalizes raw block attribution to exactly-one-or-none at content-build
/// time. When a lesson block carries BOTH a word and a sentence id, the
/// word (finer-grained, matches review word cards) is kept and the sentence
/// id dropped with an explicit warning — a documented build-time choice,
/// never a silent runtime guess. Returns `(wordId, sentenceId, hasCanonical)`.
({String? wordId, String? sentenceId, bool hasCanonical})
normalizeSourceAttribution({String? sourceWordId, String? sourceSentenceId}) {
  final word = sourceWordId?.trim();
  final sentence = sourceSentenceId?.trim();
  final hasWord = word != null && word.isNotEmpty;
  final hasSentence = sentence != null && sentence.isNotEmpty;
  if (hasWord && hasSentence) {
    AppLogger.warning(
      'QuizIdentity: block carries both word "$word" and sentence '
      '"$sentence" IDs; keeping the word attribution.',
    );
    return (wordId: word, sentenceId: null, hasCanonical: true);
  }
  return (
    wordId: hasWord ? word : null,
    sentenceId: hasSentence ? sentence : null,
    hasCanonical: hasWord || hasSentence,
  );
}

/// Validates every question of a quiz for publication. Returns a list of
/// human-readable errors (empty = publishable). Structural rules always
/// apply; corpus rules apply when [corpusMap] is provided, otherwise any
/// attributed question is reported unverified (fail closed).
List<String> validateQuizForPublish(
  QuizModel quiz, {
  ReviewCorpusIdentityMap? corpusMap,
}) {
  final errors = <String>[];
  for (var i = 0; i < quiz.questions.length; i++) {
    final q = quiz.questions[i];
    final v = validateQuestionIdentity(q, corpusMap: corpusMap);
    if (!v.isPublishable) {
      errors.add(
        'Q${i + 1}: ${v.message ?? v.status.name} '
        '(status: ${v.status.name})',
      );
    }
  }
  return errors;
}
