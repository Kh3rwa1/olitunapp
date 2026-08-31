import 'package:fpdart/fpdart.dart';
import 'package:itun/core/error/exceptions.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/core/observability/crash_reporting.dart';
import 'package:itun/features/content/domain/entities/audio_track_entity.dart';
import 'package:itun/features/content/domain/repositories/audio_track_repository.dart';

import '../datasources/audio_track_remote_datasource.dart';

/// Offline-first [AudioTrackRepository] (spec §11/§12).
///
/// Tracks fetched for an item are memoized in an in-memory cache keyed by
/// (contentKind, contentId) so screens can re-resolve audio after network
/// loss without re-querying. Persistent audio-file caching is Phase 6;
/// this phase only needs metadata availability + graceful degradation.
class AudioTrackRepositoryImpl implements AudioTrackRepository {
  final AudioTrackRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  /// In-memory metadata cache: item key -> raw track rows.
  final Map<String, List<AudioTrack>> _cache = {};

  /// In-flight request dedup so concurrent resolvers share one fetch.
  final Map<String, Future<List<AudioTrack>>> _inFlight = {};

  static const int _maxCacheEntries = 200;

  AudioTrackRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  static String _key(String contentKind, String contentId) =>
      '$contentKind:$contentId';

  ServerFailure _recordedServerFailure(ServerException e, [StackTrace? st]) {
    final failure = ServerFailure(message: e.message, code: e.code);
    CrashReporting.recordFailure(failure, st);
    return failure;
  }

  List<AudioTrack> _validated(List<AudioTrack> tracks) {
    return tracks.where((track) {
      final isValid =
          track.contentId.trim().isNotEmpty &&
          track.languageCode.trim().isNotEmpty;
      if (!isValid) {
        AppLogger.warning(
          'AudioTrackRepositoryImpl: dropped invalid track row ${track.id}',
        );
      }
      return isValid;
    }).toList();
  }

  Future<Either<Failure, List<AudioTrack>>> _getAllCachedOrRemote({
    required String contentKind,
    required String contentId,
  }) async {
    final key = _key(contentKind, contentId);
    final cached = _cache[key];
    if (cached != null) return Right(cached);

    final existing = _inFlight[key];
    if (existing != null) {
      try {
        return Right(await existing);
      } on ServerException catch (e, st) {
        return Left(_recordedServerFailure(e, st));
      }
    }

    final future = _fetchAndCache(contentKind, contentId);
    _inFlight[key] = future;
    try {
      return Right(await future);
    } on ServerException catch (e, st) {
      return Left(_recordedServerFailure(e, st));
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<List<AudioTrack>> _fetchAndCache(
    String contentKind,
    String contentId,
  ) async {
    final rows = await remoteDataSource.getAllTracks(
      contentKind: contentKind,
      contentId: contentId,
    );
    final entities = rows
        .map((row) => row.toEntity())
        .whereType<AudioTrack>()
        .toList();
    final valid = _validated(entities);
    _cacheTrackList(_key(contentKind, contentId), valid);
    return valid;
  }

  void _cacheTrackList(String key, List<AudioTrack> tracks) {
    if (_cache.length >= _maxCacheEntries && !_cache.containsKey(key)) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = tracks;
  }

  @override
  Future<Either<Failure, List<AudioTrack>>> getPlayableTracks({
    required String contentKind,
    required String contentId,
  }) async {
    final result = await _getAllCachedOrRemote(
      contentKind: contentKind,
      contentId: contentId,
    );
    return result.fold(
      (failure) => const Left(CacheFailure(message: 'Audio unavailable')),
      (tracks) => Right(tracks.where((t) => t.isPlayable).toList()),
    );
  }

  @override
  Future<Either<Failure, List<AudioTrack>>> getAllTracks({
    required String contentKind,
    required String contentId,
  }) {
    return _getAllCachedOrRemote(
      contentKind: contentKind,
      contentId: contentId,
    );
  }

  @override
  Future<Either<Failure, List<AudioTrack>>> getTracksByType({
    required String contentKind,
    required String contentId,
    required TrackType trackType,
    required String languageCode,
  }) async {
    final result = await _getAllCachedOrRemote(
      contentKind: contentKind,
      contentId: contentId,
    );
    return result.fold(
      (failure) => const Left(CacheFailure(message: 'Audio unavailable')),
      (tracks) => Right(
        tracks
            .where(
              (t) =>
                  t.trackType == trackType &&
                  t.languageCode == languageCode &&
                  t.isPlayable,
            )
            .toList(),
      ),
    );
  }

  @override
  Future<Either<Failure, List<AudioTrack>>> getSegmentTracks({
    required String storyId,
    required String segmentId,
  }) {
    return _getAllCachedOrRemote(contentKind: 'story', contentId: storyId);
  }

  @override
  Future<Either<Failure, AudioTrack?>> findByIdempotencyKey(
    AudioTrack track,
  ) async {
    final result = await _getAllCachedOrRemote(
      contentKind: track.contentKind,
      contentId: track.contentId,
    );
    return result.fold(
      (failure) => const Left(CacheFailure(message: 'Audio unavailable')),
      (tracks) => Right(
        tracks
            .where((t) => t.idempotencyKey == track.idempotencyKey)
            .firstOrNull,
      ),
    );
  }

  // ── Write operations ──────────────────────────────────────────────
  // Mobile clients never write audio tracks (spec: uploads happen in the
  // admin CMS, generation happens server-side). These implementations
  // exist to satisfy the Phase 2 interface for admin tooling; they record
  // a permission failure and return AuthFailure instead of pretending.

  @override
  Future<Either<Failure, void>> saveTrack(AudioTrack track) async {
    AppLogger.warning(
      'AudioTrackRepositoryImpl.saveTrack rejected: mobile clients '
      'cannot write audio tracks',
    );
    return const Left(
      AuthFailure(message: 'Audio tracks are managed via the admin CMS'),
    );
  }

  @override
  Future<Either<Failure, void>> deleteTrack(String id) async {
    AppLogger.warning(
      'AudioTrackRepositoryImpl.deleteTrack rejected: mobile clients '
      'cannot delete audio tracks',
    );
    return const Left(
      AuthFailure(message: 'Audio tracks are managed via the admin CMS'),
    );
  }
}
