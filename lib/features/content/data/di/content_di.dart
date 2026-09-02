import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/appwrite_auth_service.dart';
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
// content, story segments). Lives beside the datasources/repositories it
// constructs so `package:appwrite` never leaks into presentation.

final audioTrackRemoteDataSourceProvider = Provider<AudioTrackRemoteDataSource>(
  (ref) {
    final client = ref.watch(appwriteAuthServiceProvider).client;
    return AudioTrackRemoteDataSourceImpl(Databases(client));
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
      final client = ref.watch(appwriteAuthServiceProvider).client;
      return LocalizedContentRemoteDataSourceImpl(Databases(client));
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
