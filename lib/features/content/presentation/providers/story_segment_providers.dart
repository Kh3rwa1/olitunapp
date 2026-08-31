import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/appwrite_auth_service.dart';
import '../../../../core/network/network_info.dart';
import '../../data/datasources/story_segment_remote_datasource.dart';
import '../../data/repositories/story_segment_repository_impl.dart';
import '../../domain/entities/story_segment_entity.dart';
import '../../domain/repositories/story_segment_repository.dart';
import 'audio_playback_providers.dart';

/// Phase 6 wiring: story segment datasource → repository →
/// `storySegmentsProvider` (spec §13).
///
/// The segment-based story player consumes `storySegmentsProvider` for
/// text/highlighting and routes all audio through the central
/// [playbackControllerProvider] so the one-global-player rule holds.

final storySegmentRemoteDataSourceProvider =
    Provider<StorySegmentRemoteDataSource>((ref) {
      final client = ref.watch(appwriteAuthServiceProvider).client;
      return StorySegmentRemoteDataSourceImpl(Databases(client));
    });

final storySegmentRepositoryProvider = Provider<StorySegmentRepository>((ref) {
  return StorySegmentRepositoryImpl(
    remoteDataSource: ref.watch(storySegmentRemoteDataSourceProvider),
    audioTrackRepository: ref.watch(audioTrackRepositoryProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

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
