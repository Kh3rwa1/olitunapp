import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/audio_track_entity.dart';

/// Access to audio tracks attached to Santali content items.
///
/// Santali tracks are human recordings uploaded via the admin CMS;
/// teaching-language tracks may be generated server-side with Sarvam
/// TTS. The app only reads playable tracks — generation and approval
/// never happen in mobile code.
abstract class AudioTrackRepository {
  /// All playable tracks for [contentKind]:[contentId].
  ///
  /// Unplayable tracks (no audio, or unreviewed synthetic ones) are
  /// surfaced as "unavailable" in the UI, so callers also need the
  /// raw list — use [getAllTracks] when full metadata is required.
  Future<Either<Failure, List<AudioTrack>>> getPlayableTracks({
    required String contentKind,
    required String contentId,
  });

  /// Every track row (playable or not) for an item, for admin tooling
  /// and for showing "audio unavailable" states.
  Future<Either<Failure, List<AudioTrack>>> getAllTracks({
    required String contentKind,
    required String contentId,
  });

  /// Tracks of a specific type and language for an item, e.g. the
  /// Santali [TrackType.targetNormal] track or the Hindi
  /// [TrackType.translation] track.
  Future<Either<Failure, List<AudioTrack>>> getTracksByType({
    required String contentKind,
    required String contentId,
    required TrackType trackType,
    required String languageCode,
  });

  /// Story-segment tracks; [segmentId] is null for whole-item tracks.
  Future<Either<Failure, List<AudioTrack>>> getSegmentTracks({
    required String storyId,
    required String segmentId,
  });

  /// Finds a track matching the idempotency composite key
  /// (contentKind, contentId, segmentId, languageCode, trackType,
  /// contentHash) so re-generation reuses instead of duplicating.
  Future<Either<Failure, AudioTrack?>> findByIdempotencyKey(AudioTrack track);

  Future<Either<Failure, void>> saveTrack(AudioTrack track);

  Future<Either<Failure, void>> deleteTrack(String id);
}
