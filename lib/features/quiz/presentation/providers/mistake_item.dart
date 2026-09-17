import 'dart:convert';

import '../../../../shared/models/content_models.dart';

/// Domain terms (see docs/architecture/learner_state_authority.md):
/// - recorded mistake: immutable historical incorrect answer (audit).
/// - unresolved recovery need: derived from current SRS state + policy.
/// - recovered: item reached SRS MasteryState.mastered.
/// - review: SRS lifecycle state — NEVER "mastered".
/// - mastered: SRS MasteryState.mastered ONLY.
///
/// [MistakeNotifier] owns the historical audit + the derived recovery queue.
/// [ReviewStore]/SRS owns current learning weakness. There is exactly one
/// mastery lifecycle.

class MistakeItem {
  final String quizId;
  final String questionId;
  final int questionIndex;
  final QuizQuestion question;
  final String addedAt;
  final bool isResolved;
  final String? resolvedAt;

  /// SRS `successfulRecalls` for the attributed item at record time.
  /// Recovery = strictly more successes afterwards (one correct recall
  /// after the mistake). Legacy records decode to 0 (fail-safe: any
  /// subsequent success recovers).
  final int baselineSuccesses;

  MistakeItem({
    required this.quizId,
    String? questionId,
    required this.questionIndex,
    required this.question,
    required this.addedAt,
    this.isResolved = false,
    this.resolvedAt,
    this.baselineSuccesses = 0,
  }) : questionId = questionId ?? '${quizId}_$questionIndex';

  MistakeItem copyWith({
    String? quizId,
    String? questionId,
    int? questionIndex,
    QuizQuestion? question,
    String? addedAt,
    bool? isResolved,
    String? resolvedAt,
    int? baselineSuccesses,
  }) {
    return MistakeItem(
      quizId: quizId ?? this.quizId,
      questionId: questionId ?? this.questionId,
      questionIndex: questionIndex ?? this.questionIndex,
      question: question ?? this.question,
      addedAt: addedAt ?? this.addedAt,
      isResolved: isResolved ?? this.isResolved,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      baselineSuccesses: baselineSuccesses ?? this.baselineSuccesses,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'questionId': questionId,
      'questionIndex': questionIndex,
      'question': question.toMap(),
      'addedAt': addedAt,
      'isResolved': isResolved,
      'resolvedAt': resolvedAt,
      'baselineSuccesses': baselineSuccesses,
    };
  }

  factory MistakeItem.fromJson(Map<String, dynamic> json) {
    final snapshot = json['question'] ?? json['questionSnapshot'];
    return MistakeItem(
      quizId: json['quizId'] ?? '',
      questionId: json['questionId'] as String?,
      questionIndex: json['questionIndex'] ?? 0,
      question: QuizQuestion.fromMap(_readQuestionSnapshot(snapshot)),
      addedAt: json['addedAt'] ?? json['lastMissedAt'] ?? '',
      isResolved: json['isResolved'] as bool? ?? false,
      resolvedAt: json['resolvedAt'] as String?,
      baselineSuccesses: (json['baselineSuccesses'] as num?)?.toInt() ?? 0,
    );
  }

  static Map<String, dynamic> _readQuestionSnapshot(dynamic snapshot) {
    try {
      if (snapshot is String && snapshot.trim().isNotEmpty) {
        final decoded = jsonDecode(snapshot);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }
      if (snapshot is Map) {
        return Map<String, dynamic>.from(snapshot);
      }
    } catch (_) {
      // Remote mistakes should never break the local review queue.
    }
    return <String, dynamic>{};
  }
}

/// One durable outbox entry for a mistake backend mutation. Account-scoped
/// storage key; idempotency key dedupes retries and replay-after-crash.
class MistakeOutboxEntry {
  final String idempotencyKey;
  final String kind; // 'record' | 'resolve' | 'complete'
  final Map<String, dynamic> body;
  final String enqueuedAt;

  const MistakeOutboxEntry({
    required this.idempotencyKey,
    required this.kind,
    required this.body,
    required this.enqueuedAt,
  });

  Map<String, dynamic> toJson() => {
    'idempotencyKey': idempotencyKey,
    'kind': kind,
    'body': body,
    'enqueuedAt': enqueuedAt,
  };

  factory MistakeOutboxEntry.fromJson(Map<String, dynamic> json) =>
      MistakeOutboxEntry(
        idempotencyKey: (json['idempotencyKey'] ?? '').toString(),
        kind: (json['kind'] ?? '').toString(),
        body: Map<String, dynamic>.from(json['body'] as Map? ?? const {}),
        enqueuedAt: (json['enqueuedAt'] ?? '').toString(),
      );
}
