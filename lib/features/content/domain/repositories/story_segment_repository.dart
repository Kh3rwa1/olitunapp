import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/story_segment_entity.dart';

/// Access to story segments for the segment-based story player (spec §13).
///
/// Segments are authored in the admin CMS and read-only here. The
/// repository is offline-first: a story's segments (plus their audio
/// track rows) are cached persistently so downloaded stories stay
/// fully replayable without a network.
abstract class StorySegmentRepository {
  /// All segments of [storyId] in reading order, each hydrated with its
  /// audio tracks ([StorySegment.audioTracks]).
  ///
  /// Segments without playable audio still return — the player shows
  /// their text and highlights without sound rather than skipping them.
  Future<Either<Failure, List<StorySegment>>> getSegmentsForStory(
    String storyId,
  );
}
