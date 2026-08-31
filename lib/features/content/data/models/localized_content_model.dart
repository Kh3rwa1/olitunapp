import 'package:itun/features/content/domain/entities/localized_content_entity.dart';

/// Appwrite document mapper for the `localized_contents` collection
/// (spec §7/§8). One row per (contentKind, contentId, languageCode).
///
/// Learner queries only surface rows whose reviewStatus is approved —
/// this mapper parses every row, and filtering happens in the
/// repository so admin tooling can still read drafts.
class LocalizedContentModel {
  final String id;
  final String contentKind;
  final String contentId;
  final String languageCode;
  final String? meaning;
  final String? explanation;
  final String? hint;
  final String? grammarNote;
  final String? exampleTranslation;
  final String? pronunciationGuide;
  final String reviewStatusName;
  final String? reviewedBy;
  final String? reviewedAtIso;
  final int version;

  const LocalizedContentModel({
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
    this.reviewStatusName = 'needsReview',
    this.reviewedBy,
    this.reviewedAtIso,
    this.version = 1,
  });

  factory LocalizedContentModel.fromJson(
    Map<String, dynamic> data,
    String docId,
  ) {
    return LocalizedContentModel(
      id: docId,
      contentKind: data['contentKind'] as String? ?? '',
      contentId: data['contentId'] as String? ?? '',
      languageCode: data['languageCode'] as String? ?? '',
      meaning: data['meaning'] as String?,
      explanation: data['explanation'] as String?,
      hint: data['hint'] as String?,
      grammarNote: data['grammarNote'] as String?,
      exampleTranslation: data['exampleTranslation'] as String?,
      pronunciationGuide: data['pronunciationGuide'] as String?,
      reviewStatusName: data['reviewStatus'] as String? ?? 'needsReview',
      reviewedBy: data['reviewedBy'] as String?,
      reviewedAtIso: data['reviewedAt'] as String?,
      version: data['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contentKind': contentKind,
      'contentId': contentId,
      'languageCode': languageCode,
      'meaning': meaning,
      'explanation': explanation,
      'hint': hint,
      'grammarNote': grammarNote,
      'exampleTranslation': exampleTranslation,
      'pronunciationGuide': pronunciationGuide,
      'reviewStatus': reviewStatusName,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAtIso,
      'version': version,
    };
  }

  /// Null when the row is structurally invalid (missing keys) so
  /// repositories can drop it instead of crashing playback.
  LocalizedContent? toEntity() {
    if (contentKind.isEmpty || contentId.isEmpty || languageCode.isEmpty) {
      return null;
    }
    return LocalizedContent(
      id: id,
      contentKind: contentKind,
      contentId: contentId,
      languageCode: languageCode,
      meaning: meaning,
      explanation: explanation,
      hint: hint,
      grammarNote: grammarNote,
      exampleTranslation: exampleTranslation,
      pronunciationGuide: pronunciationGuide,
      reviewStatus: ReviewStatus.fromName(reviewStatusName),
      reviewedBy: reviewedBy,
      reviewedAt: _tryParse(reviewedAtIso),
      version: version,
    );
  }

  factory LocalizedContentModel.fromEntity(LocalizedContent content) {
    return LocalizedContentModel(
      id: content.id,
      contentKind: content.contentKind,
      contentId: content.contentId,
      languageCode: content.languageCode,
      meaning: content.meaning,
      explanation: content.explanation,
      hint: content.hint,
      grammarNote: content.grammarNote,
      exampleTranslation: content.exampleTranslation,
      pronunciationGuide: content.pronunciationGuide,
      reviewStatusName: content.reviewStatus.name,
      reviewedBy: content.reviewedBy,
      reviewedAtIso: content.reviewedAt?.toIso8601String(),
      version: content.version,
    );
  }

  static DateTime? _tryParse(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }
}
