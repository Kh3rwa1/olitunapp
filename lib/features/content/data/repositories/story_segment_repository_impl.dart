import 'package:fpdart/fpdart.dart';
import 'package:itun/core/error/exceptions.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/core/observability/crash_reporting.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:itun/features/content/domain/entities/audio_track_entity.dart';
import 'package:itun/features/content/domain/entities/story_segment_entity.dart';
import 'package:itun/features/content/domain/repositories/audio_track_repository.dart';
import 'package:itun/features/content/domain/repositories/story_segment_repository.dart';

import '../datasources/story_segment_remote_datasource.dart';
import '../models/audio_track_model.dart';
import '../models/story_segment_model.dart';

/// Offline-first [StorySegmentRepository] (spec §12/§13).
///
/// A story's segments plus their audio-track metadata are persisted to
/// the Hive [CacheService] with a long TTL, so a story opened once stays
/// readable (and, once its audio files are downloaded, replayable)
/// without a network. Fetches dedupe in-flight requests; failures fall
/// back to whatever is cached instead of blocking the reader.
class StorySegmentRepositoryImpl implements StorySegmentRepository {
  /// Cached longer than content lists because segment text changes
  /// rarely and offline replayability matters more than freshness.
  static const Duration _cacheTtl = Duration(days: 7);

  /// Cache key for a story's hydrated segment list.
  static String cacheKey(String storyId) => 'story_segments:$storyId';

  final StorySegmentRemoteDataSource remoteDataSource;
  final AudioTrackRepository audioTrackRepository;
  final NetworkInfo networkInfo;

  /// In-flight request dedup so concurrent resolvers share one fetch.
  final Map<String, Future<List<StorySegment>>> _inFlight = {};

  StorySegmentRepositoryImpl({
    required this.remoteDataSource,
    required this.audioTrackRepository,
    required this.networkInfo,
  });

  ServerFailure _recordedServerFailure(ServerException e, [StackTrace? st]) {
    final failure = ServerFailure(message: e.message, code: e.code);
    CrashReporting.recordFailure(failure, st);
    return failure;
  }

  List<StorySegment> _validated(List<StorySegment> segments) {
    final valid = segments.where((segment) {
      final isValid =
          segment.storyId.trim().isNotEmpty &&
          segment.id.trim().isNotEmpty &&
          (segment.textOlChiki.trim().isNotEmpty ||
              segment.textLatin?.trim().isNotEmpty == true);
      if (!isValid) {
        AppLogger.warning(
          'StorySegmentRepositoryImpl: dropped invalid segment '
          '${segment.id}',
        );
      }
      return isValid;
    }).toList()..sort((a, b) => a.order.compareTo(b.order));
    return valid;
  }

  @override
  Future<Either<Failure, List<StorySegment>>> getSegmentsForStory(
    String storyId,
  ) async {
    final trimmed = storyId.trim();
    if (trimmed.isEmpty) return const Right(<StorySegment>[]);

    final existing = _inFlight[trimmed];
    if (existing != null) {
      try {
        return Right(await existing);
      } on ServerException catch (e, st) {
        return await _cachedOrFailure(e, st, trimmed);
      }
    }

    final future = _fetchHydrated(trimmed);
    _inFlight[trimmed] = future;
    try {
      return Right(await future);
    } on ServerException catch (e, st) {
      return await _cachedOrFailure(e, st, trimmed);
    } finally {
      _inFlight.remove(trimmed);
    }
  }

  /// Falls back to the cached segment list on network failure (spec
  /// §12: offline resilience beats freshness): cached segments are
  /// served as a successful read; only a true cache miss surfaces the
  /// server failure.
  Future<Either<Failure, List<StorySegment>>> _cachedOrFailure(
    ServerException e,
    StackTrace st,
    String storyId,
  ) async {
    final cached = await _readCache(storyId);
    if (cached != null && cached.isNotEmpty) {
      AppLogger.debug(
        'StorySegmentRepositoryImpl: serving cached segments for '
        '$storyId after fetch failure',
      );
      return Right(cached);
    }
    return Left(_recordedServerFailure(e, st));
  }

  /// Fetches segments, hydrates their audio tracks, and persists the
  /// hydrated list to [CacheService] for offline replay.
  Future<List<StorySegment>> _fetchHydrated(String storyId) async {
    final rows = await remoteDataSource.getSegmentsForStory(storyId);
    var segments = _validated(rows.map((row) => row.toEntity()).toList());

    // Hydrate audio tracks: story tracks carry segmentId, so one batch
    // read covers the whole story (contentKind 'story', contentId
    // storyId). Missing audio never fails the fetch — segments simply
    // render without sound (spec §13).
    final tracksResult = await audioTrackRepository.getAllTracks(
      contentKind: 'story',
      contentId: storyId,
    );
    final tracksBySegment = <String, List<AudioTrack>>{};
    tracksResult.fold(
      (failure) {
        AppLogger.warning(
          'StorySegmentRepositoryImpl: audio hydration failed for '
          '$storyId (${failure.message}); segments stay text-only',
        );
      },
      (tracks) {
        for (final track in tracks) {
          final segmentId = track.segmentId?.trim();
          if (segmentId == null || segmentId.isEmpty) continue;
          tracksBySegment.putIfAbsent(segmentId, () => []).add(track);
        }
      },
    );
    if (tracksBySegment.isNotEmpty) {
      segments = segments
          .map(
            (segment) => segment.copyWith(
              audioTracks: tracksBySegment[segment.id] ?? const [],
            ),
          )
          .toList();
    }

    await _writeCache(storyId, segments);
    return segments;
  }

  // ── Persistent cache (offline replay of segment text + track
  // metadata; the audio files themselves are downloaded by the Phase 6
  // download manager, which keys on the same track rows).

  static Map<String, dynamic> _segmentToCachedJson(StorySegment segment) {
    final json = StorySegmentModel.fromEntity(segment).toJson();
    json['id'] = segment.id;
    json['audioTracks'] = segment.audioTracks
        .map((track) => AudioTrackModel.fromEntity(track).toJson())
        .toList();
    return json;
  }

  static StorySegment _segmentFromCachedJson(Map<String, dynamic> json) {
    final tracksJson = json['audioTracks'];
    final tracks = <AudioTrack>[];
    if (tracksJson is List) {
      for (final raw in tracksJson) {
        if (raw is Map<String, dynamic>) {
          final track = AudioTrackModel.fromJson(
            raw,
            raw['id'] as String? ?? '',
          ).toEntity();
          if (track != null) tracks.add(track);
        }
      }
    }
    final model = StorySegmentModel.fromJson(json, json['id'] as String? ?? '');
    return model.toEntity().copyWith(audioTracks: tracks);
  }

  Future<void> _writeCache(String storyId, List<StorySegment> segments) async {
    try {
      await CacheService.set(
        cacheKey(storyId),
        segments.map(_segmentToCachedJson).toList(),
        ttl: _cacheTtl,
      );
    } catch (e) {
      AppLogger.debug(
        'StorySegmentRepositoryImpl: cache write failed for $storyId: $e',
      );
    }
  }

  Future<List<StorySegment>?> _readCache(String storyId) async {
    try {
      return await CacheService.getList<StorySegment>(
        cacheKey(storyId),
        _segmentFromCachedJson,
      );
    } catch (e) {
      AppLogger.debug(
        'StorySegmentRepositoryImpl: cache read failed for $storyId: $e',
      );
      return null;
    }
  }
}
