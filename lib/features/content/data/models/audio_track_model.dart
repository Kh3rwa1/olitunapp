import 'package:itun/features/content/domain/entities/audio_track_entity.dart';
import 'package:itun/features/content/domain/entities/localized_content_entity.dart';

/// Appwrite document mapper for the `audio_tracks` collection (spec §7/§8).
///
/// Documents are written by the admin CMS and the server-side Sarvam
/// generation function; the learner app only reads them. [toEntity]
/// returns null for rows with an unknown `trackType` so repositories
/// can drop unsupported legacy rows instead of crashing.
class AudioTrackModel {
  final String id;
  final String contentKind;
  final String contentId;
  final String? segmentId;
  final String languageCode;
  final String trackTypeName;
  final String? audioUrl;
  final String? storageFileId;
  final int? durationMs;
  final String? provider;
  final String? model;
  final String? voiceId;
  final bool isHumanRecorded;
  final String? playbackRatePurpose;
  final String? contentHash;
  final String generationStatusName;
  final String reviewStatusName;
  final String? errorMessage;
  final String? createdAtIso;
  final String? updatedAtIso;

  const AudioTrackModel({
    required this.id,
    required this.contentKind,
    required this.contentId,
    this.segmentId,
    required this.languageCode,
    required this.trackTypeName,
    this.audioUrl,
    this.storageFileId,
    this.durationMs,
    this.provider,
    this.model,
    this.voiceId,
    this.isHumanRecorded = false,
    this.playbackRatePurpose,
    this.contentHash,
    this.generationStatusName = 'notRequested',
    this.reviewStatusName = 'needsReview',
    this.errorMessage,
    this.createdAtIso,
    this.updatedAtIso,
  });

  factory AudioTrackModel.fromJson(Map<String, dynamic> data, String docId) {
    return AudioTrackModel(
      id: docId,
      contentKind: data['contentKind'] as String? ?? '',
      contentId: data['contentId'] as String? ?? '',
      segmentId: data['segmentId'] as String?,
      languageCode: data['languageCode'] as String? ?? '',
      trackTypeName: data['trackType'] as String? ?? '',
      audioUrl: data['audioUrl'] as String?,
      storageFileId: data['storageFileId'] as String?,
      durationMs: data['durationMs'] as int?,
      provider: data['provider'] as String?,
      model: data['model'] as String?,
      voiceId: data['voiceId'] as String?,
      isHumanRecorded: data['isHumanRecorded'] as bool? ?? false,
      playbackRatePurpose: data['playbackRatePurpose'] as String?,
      contentHash: data['contentHash'] as String?,
      generationStatusName:
          data['generationStatus'] as String? ?? 'notRequested',
      reviewStatusName: data['reviewStatus'] as String? ?? 'needsReview',
      errorMessage: data['errorMessage'] as String?,
      createdAtIso: data['createdAt'] as String?,
      updatedAtIso: data['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contentKind': contentKind,
      'contentId': contentId,
      'segmentId': segmentId,
      'languageCode': languageCode,
      'trackType': trackTypeName,
      'audioUrl': audioUrl,
      'storageFileId': storageFileId,
      'durationMs': durationMs,
      'provider': provider,
      'model': model,
      'voiceId': voiceId,
      'isHumanRecorded': isHumanRecorded,
      'playbackRatePurpose': playbackRatePurpose,
      'contentHash': contentHash,
      'generationStatus': generationStatusName,
      'reviewStatus': reviewStatusName,
      'errorMessage': errorMessage,
      'createdAt': createdAtIso,
      'updatedAt': updatedAtIso,
    };
  }

  AudioTrack? toEntity() {
    final trackType = TrackType.tryFromName(trackTypeName);
    if (trackType == null) return null;
    return AudioTrack(
      id: id,
      contentKind: contentKind,
      contentId: contentId,
      segmentId: segmentId,
      languageCode: languageCode,
      trackType: trackType,
      audioUrl: audioUrl,
      storageFileId: storageFileId,
      durationMs: durationMs,
      provider: provider,
      model: model,
      voiceId: voiceId,
      isHumanRecorded: isHumanRecorded,
      playbackRatePurpose: playbackRatePurpose,
      contentHash: contentHash,
      generationStatus: GenerationStatus.fromName(generationStatusName),
      reviewStatus: ReviewStatus.fromName(reviewStatusName),
      errorMessage: errorMessage,
      createdAt: _tryParse(createdAtIso),
      updatedAt: _tryParse(updatedAtIso),
    );
  }

  factory AudioTrackModel.fromEntity(AudioTrack track) {
    return AudioTrackModel(
      id: track.id,
      contentKind: track.contentKind,
      contentId: track.contentId,
      segmentId: track.segmentId,
      languageCode: track.languageCode,
      trackTypeName: track.trackType.name,
      audioUrl: track.audioUrl,
      storageFileId: track.storageFileId,
      durationMs: track.durationMs,
      provider: track.provider,
      model: track.model,
      voiceId: track.voiceId,
      isHumanRecorded: track.isHumanRecorded,
      playbackRatePurpose: track.playbackRatePurpose,
      contentHash: track.contentHash,
      generationStatusName: track.generationStatus.name,
      reviewStatusName: track.reviewStatus.name,
      errorMessage: track.errorMessage,
      createdAtIso: track.createdAt?.toIso8601String(),
      updatedAtIso: track.updatedAt?.toIso8601String(),
    );
  }

  static DateTime? _tryParse(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }
}
