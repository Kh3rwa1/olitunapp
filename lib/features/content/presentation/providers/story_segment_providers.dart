import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/story_segment_entity.dart';
import 'audio_playback_providers.dart';

/// Phase 6 wiring: story segment datasource → repository →
/// `storySegmentsProvider` (spec §13).
///
/// The segment-based story player consumes `storySegmentsProvider` for
/// text/highlighting and routes all audio through the central
/// [playbackControllerProvider] so the one-global-player rule holds.

/// Resolves a story's segments, hydrated with their audio tracks.
///
/// Failure-swallowing by design (spec §13): if neither network nor
/// cache can serve the story, the provider resolves to an empty list
/// so the story screen shows a friendly empty state instead of an
/// error — the reader is never blocked by a missing story.
final storySegmentsProvider = FutureProvider.autoDispose
    .family<List<StorySegment>, String>((ref, storyId) async {
      final repository = ref.watch(storySegmentRepositoryProvider);
      final result = await repository.getSegmentsForStory(storyId);
      return result.fold(
        (failure) => const <StorySegment>[],
        (segments) => segments,
      );
    });
