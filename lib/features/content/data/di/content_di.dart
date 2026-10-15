import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/edge_json_client.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/audio_track_remote_datasource.dart';
import '../datasources/localized_content_remote_datasource.dart';
import '../datasources/story_segment_remote_datasource.dart';
import '../repositories/audio_track_repository_impl.dart';
import '../repositories/localized_content_repository_impl.dart';
import '../repositories/story_segment_repository_impl.dart';
import '../../domain/repositories/audio_track_repository.dart';
import '../../domain/repositories/localized_content_repository.dart';
import '../../domain/repositories/story_segment_repository.dart';

// Data-layer DI wiring for the content feature (audio tracks, localized
// content, story segments). All three read from the Cloudflare Worker and
// share one HTTP client.

final audioTrackRemoteDataSourceProvider = Provider<AudioTrackRemoteDataSource>(
  (ref) {
    return AudioTrackRemoteDataSourceImpl(ref.watch(edgeHttpClientProvider));
  },
);

final audioTrackRepositoryProvider = Provider<AudioTrackRepository>((ref) {
  final remote = ref.watch(audioTrackRemoteDataSourceProvider);
  final network = ref.watch(networkInfoProvider);
  return AudioTrackRepositoryImpl(
    remoteDataSource: remote,
    networkInfo: network,
  );
});

final localizedContentRemoteDataSourceProvider =
    Provider<LocalizedContentRemoteDataSource>((ref) {
      return LocalizedContentRemoteDataSourceImpl(
        ref.watch(edgeHttpClientProvider),
      );
    });

final localizedContentRepositoryProvider = Provider<LocalizedContentRepository>(
  (ref) {
    final remote = ref.watch(localizedContentRemoteDataSourceProvider);
    final network = ref.watch(networkInfoProvider);
    return LocalizedContentRepositoryImpl(
      remoteDataSource: remote,
      networkInfo: network,
    );
  },
);

final storySegmentRemoteDataSourceProvider =
    Provider<StorySegmentRemoteDataSource>((ref) {
      return StorySegmentRemoteDataSourceImpl(
        ref.watch(edgeHttpClientProvider),
      );
    });

final storySegmentRepositoryProvider = Provider<StorySegmentRepository>((ref) {
  return StorySegmentRepositoryImpl(
    remoteDataSource: ref.watch(storySegmentRemoteDataSourceProvider),
    audioTrackRepository: ref.watch(audioTrackRepositoryProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});
