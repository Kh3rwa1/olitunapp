import 'package:equatable/equatable.dart';

import 'localized_content_entity.dart' show ReviewStatus;

/// What an audio track represents pedagogically.
enum TrackType {
  /// Native Santali audio at normal speed — the primary target audio.
  targetNormal,

  /// Same Santali audio, slowed down for pronunciation practice.
  targetSlow,

  /// Syllable-by-syllable Santali breakdown.
  targetSyllable,

  /// Teaching-language explanation of the Santali item.
  explanation,

  /// Teaching-language translation of the Santali item.
  translation,

  /// UI/lesson instruction narration.
  instruction,

  /// Story narration in Santali.
  storyNarration,

  /// Story narration in a teaching language.
  storyTranslation,

  /// Spoken example sentence audio.
  exampleSentence,

  /// Feedback/response audio.
  feedback;

  /// Parses a persisted track type; unknown values resolve to null so
  /// callers can skip unsupported legacy tracks instead of crashing.
  static TrackType? tryFromName(String? name) {
    if (name == null) return null;
    for (final t in TrackType.values) {
      if (t.name == name) return t;
    }
    return null;
  }
}

/// Lifecycle of synthetic (Sarvam) audio generation.
enum GenerationStatus {
  notRequested,
  queued,
  processing,
  completed,
  failed;

  static GenerationStatus fromName(String? name) {
    return GenerationStatus.values.firstWhere(
      (e) => e.name == name,
      orElse: () => GenerationStatus.notRequested,
    );
  }
}

/// A single piece of audio attached to a content item.
///
/// Santali tracks ([TrackType.targetNormal], [targetSlow],
/// [targetSyllable], [storyNarration]) MUST be human-recorded and
/// uploaded through the admin CMS — they are never generated
/// synthetically. Teaching-language tracks may be generated with
/// Sarvam TTS and carry [provider]/[model]/[voiceId] metadata.
///
/// [contentHash] makes generation idempotent: it is a stable hash of
/// (text, languageCode, trackType, voice/model params). Re-generating
/// the same content must reuse or replace the existing track rather
/// than creating duplicates.
class AudioTrack extends Equatable {
  final String id;

  /// word, sentence, letter, number, rhyme, story.
  final String contentKind;
  final String contentId;

  /// Story segment index for story tracks; null for whole-item tracks.
  final String? segmentId;

  /// en, hi, bn, or — for Santali audio — sat.
  final String languageCode;
  final TrackType trackType;

  /// Public playback URL of the audio file.
  final String? audioUrl;

  /// Appwrite storage file ID backing [audioUrl], if uploaded there.
  final String? storageFileId;
  final int? durationMs;

  /// e.g. 'sarvam', 'human', 'uploaded'. Null for human uploads.
  final String? provider;
  final String? model;
  final String? voiceId;

  /// True when a native speaker recorded this file. Synthetic Santali
  /// is forbidden by product policy, so Santali tracks must set this.
  final bool isHumanRecorded;

  /// Playback purpose this track was rendered for, e.g. 'slow'.
  final String? playbackRatePurpose;

  /// Stable idempotency hash of the source content + voice params.
  final String? contentHash;
  final GenerationStatus generationStatus;
  final ReviewStatus reviewStatus;

  /// Last generation error, redacted of any provider secrets.
  final String? errorMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AudioTrack({
    required this.id,
    required this.contentKind,
    required this.contentId,
    this.segmentId,
    required this.languageCode,
    required this.trackType,
    this.audioUrl,
    this.storageFileId,
    this.durationMs,
    this.provider,
    this.model,
    this.voiceId,
    this.isHumanRecorded = false,
    this.playbackRatePurpose,
    this.contentHash,
    this.generationStatus = GenerationStatus.notRequested,
    this.reviewStatus = ReviewStatus.draft,
    this.errorMessage,
    this.createdAt,
    this.updatedAt,
  });

  /// Whether this track can be played by a learner.
  ///
  /// A track is playable when it has audio and is either approved, or
  /// human-recorded (human uploads are trusted editorial content).
  bool get isPlayable =>
      audioUrl != null &&
      audioUrl!.isNotEmpty &&
      (reviewStatus == ReviewStatus.approved || isHumanRecorded);

  /// Whether this track is Santali (target language) audio.
  bool get isTargetAudio =>
      trackType == TrackType.targetNormal ||
      trackType == TrackType.targetSlow ||
      trackType == TrackType.targetSyllable ||
      trackType == TrackType.storyNarration;

  /// Idempotency key covering the spec's composite:
  /// contentKind + contentId + segmentId + languageCode + trackType
  /// + contentHash.
  String get idempotencyKey {
    final segment = segmentId ?? '-';
    final hash = contentHash ?? '-';
    return '$contentKind:$contentId:$segment:$languageCode:'
        '${trackType.name}:$hash';
  }

  AudioTrack copyWith({
    String? id,
    String? contentKind,
    String? contentId,
    String? segmentId,
    String? languageCode,
    TrackType? trackType,
    String? audioUrl,
    String? storageFileId,
    int? durationMs,
    String? provider,
    String? model,
    String? voiceId,
    bool? isHumanRecorded,
    String? playbackRatePurpose,
    String? contentHash,
    GenerationStatus? generationStatus,
    ReviewStatus? reviewStatus,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AudioTrack(
      id: id ?? this.id,
      contentKind: contentKind ?? this.contentKind,
      contentId: contentId ?? this.contentId,
      segmentId: segmentId ?? this.segmentId,
      languageCode: languageCode ?? this.languageCode,
      trackType: trackType ?? this.trackType,
      audioUrl: audioUrl ?? this.audioUrl,
      storageFileId: storageFileId ?? this.storageFileId,
      durationMs: durationMs ?? this.durationMs,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      voiceId: voiceId ?? this.voiceId,
      isHumanRecorded: isHumanRecorded ?? this.isHumanRecorded,
      playbackRatePurpose: playbackRatePurpose ?? this.playbackRatePurpose,
      contentHash: contentHash ?? this.contentHash,
      generationStatus: generationStatus ?? this.generationStatus,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    contentKind,
    contentId,
    segmentId,
    languageCode,
    trackType,
    audioUrl,
    storageFileId,
    durationMs,
    provider,
    model,
    voiceId,
    isHumanRecorded,
    playbackRatePurpose,
    contentHash,
    generationStatus,
    reviewStatus,
    errorMessage,
    createdAt,
    updatedAt,
  ];
}
