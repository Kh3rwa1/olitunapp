// Memory engine domain model: item-level learning state.
//
// Reuses existing content IDs (WordModel.id / SentenceModel.id) as itemId.
// Pure Dart — no Flutter, no Riverpod, no clock inside (callers pass `now`).
// See `memory_scheduler.dart` for transitions.

/// Learnable item kinds. Letters are traced, not retrieved — the scheduler
/// focuses on vocabulary + sentences (the verified corpus).
enum ReviewItemType { word, sentence }

extension ReviewItemTypeX on ReviewItemType {
  String get json => name;

  static ReviewItemType fromJson(String? raw) {
    switch (raw) {
      case 'sentence':
        return ReviewItemType.sentence;
      case 'word':
      default:
        return ReviewItemType.word;
    }
  }
}

/// Mastery lifecycle. MASTERED requires repeated successful retrieval over
/// time — never a single completion (enforced in [MemoryScheduler]).
enum MasteryState { fresh, learning, review, mastered }

extension MasteryStateX on MasteryState {
  /// Stable wire value. `fresh` serializes as `new` per product spec.
  String get json => switch (this) {
    MasteryState.fresh => 'new',
    MasteryState.learning => 'learning',
    MasteryState.review => 'review',
    MasteryState.mastered => 'mastered',
  };

  static MasteryState fromJson(String? raw) {
    switch (raw) {
      case 'learning':
        return MasteryState.learning;
      case 'review':
        return MasteryState.review;
      case 'mastered':
        return MasteryState.mastered;
      case 'new':
      default:
        return MasteryState.fresh;
    }
  }
}

/// Exercise that produced a recall. Typing is the primary *production*
/// mechanism; recognition (MCQ/audio) is weaker evidence.
enum ReviewExerciseType { recognition, typing, listening, sentence }

extension ReviewExerciseTypeX on ReviewExerciseType {
  String get json => name;

  static ReviewExerciseType fromJson(String? raw) {
    switch (raw) {
      case 'typing':
        return ReviewExerciseType.typing;
      case 'listening':
        return ReviewExerciseType.listening;
      case 'sentence':
        return ReviewExerciseType.sentence;
      case 'recognition':
      default:
        return ReviewExerciseType.recognition;
    }
  }

  /// Typing correct answers are stronger evidence of mastery.
  bool get isProduction => this == ReviewExerciseType.typing;
}

class MemoryItemState {
  final String itemId;
  final ReviewItemType itemType;
  final DateTime introducedAt;
  final DateTime? lastPresentedAt;
  final DateTime? lastReviewedAt;
  final DateTime nextReviewAt;
  final double intervalDays;
  final double ease;
  final int successfulRecalls;
  final int failedRecalls;
  final int lapseCount;
  final MasteryState masteryState;
  final int? lastResponseTimeMs;
  final ReviewExerciseType? lastExerciseType;
  final int typingSuccesses;

  /// When the item's FIRST successful recall happened. Enables precise
  /// D1/D7/D30 recall measurement (introduced → recalled within N days);
  /// retention math reads this, never an approximation from counts.
  final DateTime? firstRecallAt;

  const MemoryItemState({
    required this.itemId,
    required this.itemType,
    required this.introducedAt,
    this.lastPresentedAt,
    this.lastReviewedAt,
    required this.nextReviewAt,
    this.intervalDays = 0,
    this.ease = 2.5,
    this.successfulRecalls = 0,
    this.failedRecalls = 0,
    this.lapseCount = 0,
    this.masteryState = MasteryState.fresh,
    this.lastResponseTimeMs,
    this.lastExerciseType,
    this.typingSuccesses = 0,
    this.firstRecallAt,
  });

  bool isDue(DateTime now) => !nextReviewAt.isAfter(now);

  bool get isMastered => masteryState == MasteryState.mastered;

  /// Measurable retention: reached REVIEW or MASTERED with net positive recall.
  bool get isRetained =>
      (masteryState == MasteryState.review ||
          masteryState == MasteryState.mastered) &&
      successfulRecalls > failedRecalls;

  MemoryItemState copyWith({
    DateTime? introducedAt,
    DateTime? lastPresentedAt,
    DateTime? lastReviewedAt,
    DateTime? nextReviewAt,
    double? intervalDays,
    double? ease,
    int? successfulRecalls,
    int? failedRecalls,
    int? lapseCount,
    MasteryState? masteryState,
    int? lastResponseTimeMs,
    ReviewExerciseType? lastExerciseType,
    int? typingSuccesses,
    DateTime? firstRecallAt,
  }) {
    return MemoryItemState(
      itemId: itemId,
      itemType: itemType,
      introducedAt: introducedAt ?? this.introducedAt,
      lastPresentedAt: lastPresentedAt ?? this.lastPresentedAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      intervalDays: intervalDays ?? this.intervalDays,
      ease: ease ?? this.ease,
      successfulRecalls: successfulRecalls ?? this.successfulRecalls,
      failedRecalls: failedRecalls ?? this.failedRecalls,
      lapseCount: lapseCount ?? this.lapseCount,
      masteryState: masteryState ?? this.masteryState,
      lastResponseTimeMs: lastResponseTimeMs ?? this.lastResponseTimeMs,
      lastExerciseType: lastExerciseType ?? this.lastExerciseType,
      typingSuccesses: typingSuccesses ?? this.typingSuccesses,
      firstRecallAt: firstRecallAt ?? this.firstRecallAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemType': itemType.json,
      'introducedAt': introducedAt.toIso8601String(),
      'lastPresentedAt': lastPresentedAt?.toIso8601String(),
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      'nextReviewAt': nextReviewAt.toIso8601String(),
      'intervalDays': intervalDays,
      'ease': ease,
      'successfulRecalls': successfulRecalls,
      'failedRecalls': failedRecalls,
      'lapseCount': lapseCount,
      'masteryState': masteryState.json,
      'lastResponseTimeMs': lastResponseTimeMs,
      'lastExerciseType': lastExerciseType?.json,
      'typingSuccesses': typingSuccesses,
      'firstRecallAt': firstRecallAt?.toIso8601String(),
    };
  }

  factory MemoryItemState.fromMap(Map<String, dynamic> map) {
    DateTime parse(String? raw, DateTime fallback) {
      if (raw == null || raw.isEmpty) return fallback;
      return DateTime.tryParse(raw) ?? fallback;
    }

    final now = DateTime.now().toUtc();
    final introduced = parse(map['introducedAt'] as String?, now);
    return MemoryItemState(
      itemId: (map['itemId'] ?? '').toString(),
      itemType: ReviewItemTypeX.fromJson(map['itemType'] as String?),
      introducedAt: introduced,
      lastPresentedAt: (map['lastPresentedAt'] as String?)?.isNotEmpty == true
          ? DateTime.tryParse(map['lastPresentedAt'] as String)
          : null,
      lastReviewedAt: (map['lastReviewedAt'] as String?)?.isNotEmpty == true
          ? DateTime.tryParse(map['lastReviewedAt'] as String)
          : null,
      nextReviewAt: parse(map['nextReviewAt'] as String?, introduced),
      intervalDays: (map['intervalDays'] as num?)?.toDouble() ?? 0,
      ease: (map['ease'] as num?)?.toDouble() ?? 2.5,
      successfulRecalls: (map['successfulRecalls'] as num?)?.toInt() ?? 0,
      failedRecalls: (map['failedRecalls'] as num?)?.toInt() ?? 0,
      lapseCount: (map['lapseCount'] as num?)?.toInt() ?? 0,
      masteryState: MasteryStateX.fromJson(map['masteryState'] as String?),
      lastResponseTimeMs: (map['lastResponseTimeMs'] as num?)?.toInt(),
      lastExerciseType: (map['lastExerciseType'] as String?) == null
          ? null
          : ReviewExerciseTypeX.fromJson(map['lastExerciseType'] as String?),
      typingSuccesses: (map['typingSuccesses'] as num?)?.toInt() ?? 0,
      firstRecallAt: (map['firstRecallAt'] as String?)?.isNotEmpty == true
          ? DateTime.tryParse(map['firstRecallAt'] as String)
          : null,
    );
  }
}
