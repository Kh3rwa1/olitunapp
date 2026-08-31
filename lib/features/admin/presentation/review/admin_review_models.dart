/// Phase 5 — admin review workflow client models.
///
/// Lean projections of the rows returned by the `reviewContent`
/// Appwrite Function (audio_tracks + localized_contents queues).
/// Parsing is defensive: the function is the only writer of these
/// shapes, but admin tooling should never crash on a stray field.
library;

/// A single audio track awaiting (or holding) a review decision.
class AdminAudioTrackRow {
  final String id;
  final String contentKind;
  final String contentId;
  final String? segmentId;
  final String languageCode;
  final String trackType;
  final String? audioUrl;
  final String? provider;
  final bool isHumanRecorded;
  final String? generationStatus;
  final String reviewStatus;
  final String? errorMessage;

  const AdminAudioTrackRow({
    required this.id,
    required this.contentKind,
    required this.contentId,
    this.segmentId,
    required this.languageCode,
    required this.trackType,
    this.audioUrl,
    this.provider,
    this.isHumanRecorded = false,
    this.generationStatus,
    required this.reviewStatus,
    this.errorMessage,
  });

  factory AdminAudioTrackRow.fromJson(Map<String, dynamic> json) {
    return AdminAudioTrackRow(
      id: _s(json, 'id'),
      contentKind: _s(json, 'contentKind'),
      contentId: _s(json, 'contentId'),
      segmentId: _sOrNull(json, 'segmentId'),
      languageCode: _s(json, 'languageCode'),
      trackType: _s(json, 'trackType'),
      audioUrl: _sOrNull(json, 'audioUrl'),
      provider: _sOrNull(json, 'provider'),
      isHumanRecorded: json['isHumanRecorded'] == true,
      generationStatus: _sOrNull(json, 'generationStatus'),
      reviewStatus: _s(json, 'reviewStatus'),
      errorMessage: _sOrNull(json, 'errorMessage'),
    );
  }

  /// Mirrors the backend `canApproveAudioTrack` rule so the UI can
  /// disable approve actions on broken/incomplete tracks up front:
  /// a playable url is always required; human uploads bypass the
  /// generation check, synthetic audio must be fully generated.
  bool get isApprovable =>
      (audioUrl != null && audioUrl!.trim().isNotEmpty) &&
      (isHumanRecorded || generationStatus == 'completed');

  bool get hasAudio => audioUrl != null && audioUrl!.trim().isNotEmpty;

  /// The schema stores `-` for trackless segments; normalize for display.
  String get displaySegmentId {
    final value = segmentId ?? '';
    if (value.isEmpty || value == '-') return '';
    return value;
  }

  String get title =>
      '$contentKind · $contentId'
      '${displaySegmentId.isEmpty ? '' : ' · $displaySegmentId'}';

  static String _s(Map<String, dynamic> json, String key) =>
      json[key]?.toString() ?? '';

  static String? _sOrNull(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }
}

/// A single localized translation awaiting (or holding) a review decision.
class AdminLocalizedContentRow {
  final String id;
  final String contentKind;
  final String contentId;
  final String languageCode;
  final String? meaning;
  final String? explanation;
  final String reviewStatus;

  const AdminLocalizedContentRow({
    required this.id,
    required this.contentKind,
    required this.contentId,
    required this.languageCode,
    this.meaning,
    this.explanation,
    required this.reviewStatus,
  });

  factory AdminLocalizedContentRow.fromJson(Map<String, dynamic> json) {
    return AdminLocalizedContentRow(
      id: json['id']?.toString() ?? '',
      contentKind: json['contentKind']?.toString() ?? '',
      contentId: json['contentId']?.toString() ?? '',
      languageCode: json['languageCode']?.toString() ?? '',
      meaning: _textOrNull(json, 'meaning'),
      explanation: _textOrNull(json, 'explanation'),
      reviewStatus: json['reviewStatus']?.toString() ?? '',
    );
  }

  String get title => '$contentKind · $contentId';

  static String? _textOrNull(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }
}

/// One page of a review queue plus the server-side total.
class AdminAudioQueuePage {
  final int total;
  final List<AdminAudioTrackRow> tracks;

  const AdminAudioQueuePage({required this.total, required this.tracks});

  static AdminAudioQueuePage fromData(Map<String, dynamic> data) {
    final documents = data['documents'];
    final rows = documents is List
        ? documents
              .whereType<Map>()
              .map(
                (doc) =>
                    AdminAudioTrackRow.fromJson(Map<String, dynamic>.from(doc)),
              )
              .toList()
        : <AdminAudioTrackRow>[];
    return AdminAudioQueuePage(
      total: _toInt(data['total'], rows.length),
      tracks: rows,
    );
  }
}

/// One page of the localized-content review queue plus the total.
class AdminLocalizedQueuePage {
  final int total;
  final List<AdminLocalizedContentRow> contents;

  const AdminLocalizedQueuePage({required this.total, required this.contents});

  static AdminLocalizedQueuePage fromData(Map<String, dynamic> data) {
    final documents = data['documents'];
    final rows = documents is List
        ? documents
              .whereType<Map>()
              .map(
                (doc) => AdminLocalizedContentRow.fromJson(
                  Map<String, dynamic>.from(doc),
                ),
              )
              .toList()
        : <AdminLocalizedContentRow>[];
    return AdminLocalizedQueuePage(
      total: _toInt(data['total'], rows.length),
      contents: rows,
    );
  }
}

/// Result of one item inside a batch approve/reject response.
class AdminReviewItemResult {
  final String id;
  final bool ok;
  final String? reason;

  const AdminReviewItemResult({
    required this.id,
    required this.ok,
    this.reason,
  });

  factory AdminReviewItemResult.fromJson(Map<String, dynamic> json) {
    return AdminReviewItemResult(
      id: json['id']?.toString() ?? '',
      ok: json['ok'] == true,
      reason: json['reason']?.toString(),
    );
  }
}

/// Aggregated outcome of a batch approve/reject call.
class AdminReviewBatchResult {
  final String decision;
  final int requested;
  final int updated;
  final int failed;
  final List<AdminReviewItemResult> results;

  const AdminReviewBatchResult({
    required this.decision,
    required this.requested,
    required this.updated,
    required this.failed,
    required this.results,
  });

  static AdminReviewBatchResult fromData(Map<String, dynamic> data) {
    final rawResults = data['results'];
    final results = rawResults is List
        ? rawResults
              .whereType<Map>()
              .map(
                (row) => AdminReviewItemResult.fromJson(
                  Map<String, dynamic>.from(row),
                ),
              )
              .toList()
        : <AdminReviewItemResult>[];
    return AdminReviewBatchResult(
      decision: data['decision']?.toString() ?? '',
      requested: _toInt(data['requested'], 0),
      updated: _toInt(data['updated'], 0),
      failed: _toInt(data['failed'], 0),
      results: results,
    );
  }
}

int _toInt(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
