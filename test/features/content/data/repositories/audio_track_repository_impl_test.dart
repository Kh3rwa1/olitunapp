import 'package:itun/core/error/exceptions.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/features/content/data/datasources/audio_track_remote_datasource.dart';
import 'package:itun/features/content/data/models/audio_track_model.dart';
import 'package:itun/features/content/data/repositories/audio_track_repository_impl.dart';
import 'package:itun/features/content/domain/entities/audio_track_entity.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAudioTrackRemoteDataSource extends Mock
    implements AudioTrackRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

AudioTrackModel row(
  String id, {
  String contentKind = 'word',
  String contentId = 'w1',
  String? segmentId,
  String languageCode = 'sat',
  String trackType = 'targetNormal',
  String? audioUrl = 'https://cdn.example.com/a.mp3',
  bool isHumanRecorded = true,
  String reviewStatus = 'approved',
  String? contentHash,
}) {
  return AudioTrackModel(
    id: id,
    contentKind: contentKind,
    contentId: contentId,
    segmentId: segmentId,
    languageCode: languageCode,
    trackTypeName: trackType,
    audioUrl: audioUrl,
    isHumanRecorded: isHumanRecorded,
    reviewStatusName: reviewStatus,
    contentHash: contentHash,
  );
}

void main() {
  late MockAudioTrackRemoteDataSource remote;
  late MockNetworkInfo networkInfo;
  late AudioTrackRepositoryImpl repository;

  setUp(() {
    remote = MockAudioTrackRemoteDataSource();
    networkInfo = MockNetworkInfo();
    repository = AudioTrackRepositoryImpl(
      remoteDataSource: remote,
      networkInfo: networkInfo,
    );
  });

  group('getAllTracks', () {
    test('fetches, maps and caches rows per item', () async {
      when(
        () => remote.getAllTracks(contentKind: 'word', contentId: 'w1'),
      ).thenAnswer(
        (_) async => [
          row('t1'),
          // Invalid row: empty languageCode must be dropped.
          row('t2', languageCode: ' '),
          // Unknown legacy trackType maps to null entity and is dropped.
          row('t3', trackType: 'legacyUnknown'),
        ],
      );

      final first = await repository.getAllTracks(
        contentKind: 'word',
        contentId: 'w1',
      );
      final second = await repository.getAllTracks(
        contentKind: 'word',
        contentId: 'w1',
      );

      expect(first.isRight(), isTrue);
      expect(second.isRight(), isTrue);
      expect(first.getOrElse((f) => []).map((t) => t.id), equals(['t1']));
      verify(
        () => remote.getAllTracks(contentKind: 'word', contentId: 'w1'),
      ).called(1);
    });

    test('serves a different item without cross-talk', () async {
      when(
        () => remote.getAllTracks(contentKind: 'word', contentId: 'w1'),
      ).thenAnswer((_) async => [row('t1')]);
      when(
        () => remote.getAllTracks(contentKind: 'sentence', contentId: 's1'),
      ).thenAnswer(
        (_) async => [row('t9', contentKind: 'sentence', contentId: 's1')],
      );

      final word = await repository.getAllTracks(
        contentKind: 'word',
        contentId: 'w1',
      );
      final sentence = await repository.getAllTracks(
        contentKind: 'sentence',
        contentId: 's1',
      );

      expect(word.getOrElse((f) => []).single.id, 't1');
      expect(sentence.getOrElse((f) => []).single.id, 't9');
    });

    test('concurrent calls share one in-flight fetch', () async {
      when(
        () => remote.getAllTracks(contentKind: 'word', contentId: 'w1'),
      ).thenAnswer((_) async => [row('t1')]);

      // Both futures are created before either is awaited, so the second
      // call must join the first call's in-flight fetch instead of issuing
      // a second datasource query.
      final first = repository.getAllTracks(
        contentKind: 'word',
        contentId: 'w1',
      );
      final second = repository.getAllTracks(
        contentKind: 'word',
        contentId: 'w1',
      );

      final results = await Future.wait([first, second]);

      expect(results.length, 2);
      for (final result in results) {
        expect(result.getOrElse((f) => []).map((t) => t.id), equals(['t1']));
      }
      verify(
        () => remote.getAllTracks(contentKind: 'word', contentId: 'w1'),
      ).called(1);
    });

    test('returns ServerFailure when the datasource throws', () async {
      when(
        () => remote.getAllTracks(contentKind: 'word', contentId: 'w1'),
      ).thenThrow(ServerException(message: 'Appwrite down'));

      final result = await repository.getAllTracks(
        contentKind: 'word',
        contentId: 'w1',
      );

      expect(
        result.swap().getOrElse((f) => throw StateError('expected Left')),
        isA<ServerFailure>(),
      );
    });
  });

  group('getPlayableTracks', () {
    test('filters to playable tracks only', () async {
      when(
        () => remote.getAllTracks(contentKind: 'word', contentId: 'w1'),
      ).thenAnswer(
        (_) async => [
          // Human-recorded + approved: playable.
          row('t1'),
          // No audio URL: not playable.
          row('t2', audioUrl: null),
          // Synthetic + unapproved: not playable.
          row('t3', isHumanRecorded: false, reviewStatus: 'needsReview'),
          // Synthetic + approved with URL: playable.
          row('t4', isHumanRecorded: false),
          // Human but empty URL string: not playable.
          row('t5', audioUrl: ''),
        ],
      );

      final result = await repository.getPlayableTracks(
        contentKind: 'word',
        contentId: 'w1',
      );

      expect(
        result.getOrElse((f) => []).map((t) => t.id),
        equals(['t1', 't4']),
      );
    });

    test('degrades to CacheFailure on server error', () async {
      when(
        () => remote.getAllTracks(contentKind: 'word', contentId: 'w1'),
      ).thenThrow(ServerException(message: 'offline'));

      final result = await repository.getPlayableTracks(
        contentKind: 'word',
        contentId: 'w1',
      );

      expect(
        result.swap().getOrElse((f) => throw StateError('expected Left')),
        equals(const CacheFailure(message: 'Audio unavailable')),
      );
    });
  });

  group('getTracksByType', () {
    test('filters by type, language and playability', () async {
      when(
        () => remote.getAllTracks(contentKind: 'word', contentId: 'w1'),
      ).thenAnswer(
        (_) async => [
          row('t1'),
          row('t2', trackType: 'targetSlow'),
          row('t3', trackType: 'explanation', languageCode: 'hi'),
          row('t4', audioUrl: null),
          row('t5', languageCode: 'en'),
        ],
      );

      final result = await repository.getTracksByType(
        contentKind: 'word',
        contentId: 'w1',
        trackType: TrackType.targetNormal,
        languageCode: 'sat',
      );

      expect(result.getOrElse((f) => []).map((t) => t.id), equals(['t1']));
    });

    test('degrades to CacheFailure on server error', () async {
      when(
        () => remote.getAllTracks(contentKind: 'word', contentId: 'w1'),
      ).thenThrow(ServerException(message: 'offline'));

      final result = await repository.getTracksByType(
        contentKind: 'word',
        contentId: 'w1',
        trackType: TrackType.targetNormal,
        languageCode: 'sat',
      );

      expect(
        result.swap().getOrElse((f) => throw StateError('expected Left')),
        equals(const CacheFailure(message: 'Audio unavailable')),
      );
    });
  });

  group('getSegmentTracks', () {
    test('reads the whole story item regardless of segment', () async {
      when(
        () => remote.getAllTracks(contentKind: 'story', contentId: 'story1'),
      ).thenAnswer(
        (_) async => [
          row(
            'n1',
            contentKind: 'story',
            contentId: 'story1',
            segmentId: 'seg1',
          ),
        ],
      );

      final result = await repository.getSegmentTracks(
        storyId: 'story1',
        segmentId: 'seg1',
      );

      expect(result.getOrElse((f) => []).single.id, 'n1');
      verify(
        () => remote.getAllTracks(contentKind: 'story', contentId: 'story1'),
      ).called(1);
    });
  });

  group('findByIdempotencyKey', () {
    test('returns the track with the matching idempotency key', () async {
      when(
        () => remote.getAllTracks(contentKind: 'word', contentId: 'w1'),
      ).thenAnswer(
        (_) async => [
          row('t1', contentHash: 'hash-a'),
          row('t2', contentHash: 'hash-b', trackType: 'targetSlow'),
        ],
      );

      final probe = row('probe', contentHash: 'hash-a').toEntity()!;
      final result = await repository.findByIdempotencyKey(probe);

      expect(result.getOrElse((f) => null)?.id, 't1');
    });

    test('returns null when no stored track matches', () async {
      when(
        () => remote.getAllTracks(contentKind: 'word', contentId: 'w1'),
      ).thenAnswer((_) async => [row('t1', contentHash: 'hash-a')]);

      final probe = row('probe', contentHash: 'hash-z').toEntity()!;
      final result = await repository.findByIdempotencyKey(probe);

      expect(result.getOrElse((f) => null), isNull);
    });

    test('degrades to CacheFailure on server error', () async {
      when(
        () => remote.getAllTracks(contentKind: 'word', contentId: 'w1'),
      ).thenThrow(ServerException(message: 'offline'));

      final probe = row('probe').toEntity()!;
      final result = await repository.findByIdempotencyKey(probe);

      expect(
        result.swap().getOrElse((f) => throw StateError('expected Left')),
        equals(const CacheFailure(message: 'Audio unavailable')),
      );
    });
  });

  group('write operations', () {
    test('saveTrack is rejected with AuthFailure', () async {
      final result = await repository.saveTrack(row('t1').toEntity()!);

      expect(
        result.swap().getOrElse((f) => throw StateError('expected Left')),
        equals(
          const AuthFailure(
            message: 'Audio tracks are managed via the admin CMS',
          ),
        ),
      );
      verifyZeroInteractions(remote);
    });

    test('deleteTrack is rejected with AuthFailure', () async {
      final result = await repository.deleteTrack('t1');

      expect(
        result.swap().getOrElse((f) => throw StateError('expected Left')),
        equals(
          const AuthFailure(
            message: 'Audio tracks are managed via the admin CMS',
          ),
        ),
      );
      verifyZeroInteractions(remote);
    });
  });
}
