import 'package:equatable/equatable.dart';

/// Review lifecycle of a localized teaching translation.
///
/// Mobile clients can never set [approved] — approval happens in the
/// admin CMS by a reviewer with team membership (enforced server-side).
enum ReviewStatus {
  draft,
  generated,
  needsReview,
  approved,
  rejected;

  /// Parses a persisted review status; unknown values fall back to
  /// [needsReview] so unreviewed content is never treated as approved.
  static ReviewStatus fromName(String? name) {
    return ReviewStatus.values.firstWhere(
      (e) => e.name == name,
      orElse: () => ReviewStatus.needsReview,
    );
  }
}

/// Teaching-language translation of a single Santali content item.
///
/// One row per (contentKind, contentId, languageCode). The Santali text
/// itself continues to live on the existing content document
/// (word/sentence/letter/etc.) — this entity only carries the
/// teaching-language overlay (meaning, explanation, hint, ...).
class LocalizedContent extends Equatable {
  final String id;
  final String contentKind; // word, sentence, letter, number, rhyme, story
  final String contentId;
  final String languageCode; // en, hi, bn, or, sat
  final String? meaning;
  final String? explanation;
  final String? hint;
  final String? grammarNote;
  final String? exampleTranslation;
  final String? pronunciationGuide;
  final ReviewStatus reviewStatus;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final int version;

  const LocalizedContent({
    required this.id,
    required this.contentKind,
    required this.contentId,
    required this.languageCode,
    this.meaning,
    this.explanation,
    this.hint,
    this.grammarNote,
    this.exampleTranslation,
    this.pronunciationGuide,
    this.reviewStatus = ReviewStatus.draft,
    this.reviewedBy,
    this.reviewedAt,
    this.version = 1,
  });

  /// Whether this localization is publishable to learners.
  ///
  /// Only approved content is surfaced in the learning UI; drafts and
  /// machine-generated entries stay in the admin CMS until reviewed.
  bool get isApproved => reviewStatus == ReviewStatus.approved;

  /// Returns the best available meaning text, or null when none exists.
  String? get meaningOrEmpty =>
      (meaning == null || meaning!.isEmpty) ? null : meaning;

  LocalizedContent copyWith({
    String? id,
    String? contentKind,
    String? contentId,
    String? languageCode,
    String? meaning,
    String? explanation,
    String? hint,
    String? grammarNote,
    String? exampleTranslation,
    String? pronunciationGuide,
    ReviewStatus? reviewStatus,
    String? reviewedBy,
    DateTime? reviewedAt,
    int? version,
  }) {
    return LocalizedContent(
      id: id ?? this.id,
      contentKind: contentKind ?? this.contentKind,
      contentId: contentId ?? this.contentId,
      languageCode: languageCode ?? this.languageCode,
      meaning: meaning ?? this.meaning,
      explanation: explanation ?? this.explanation,
      hint: hint ?? this.hint,
      grammarNote: grammarNote ?? this.grammarNote,
      exampleTranslation: exampleTranslation ?? this.exampleTranslation,
      pronunciationGuide: pronunciationGuide ?? this.pronunciationGuide,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [
    id,
    contentKind,
    contentId,
    languageCode,
    meaning,
    explanation,
    hint,
    grammarNote,
    exampleTranslation,
    pronunciationGuide,
    reviewStatus,
    reviewedBy,
    reviewedAt,
    version,
  ];
}
