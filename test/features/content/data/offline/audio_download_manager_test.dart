import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/features/content/data/offline/audio_download_manager.dart';
import 'package:itun/features/content/data/offline/audio_download_store.dart';
import 'package:itun/features/content/domain/entities/audio_track_entity.dart';
import 'package:itun/features/content/domain/entities/localized_content_entity.dart'
    show ReviewStatus;

/// In-memory [AudioDownloadStore] double. Mirrors the IO store's
/// semantics: writeFileString survives across manager instances (manifest
/// persistence), deleteFile removes the file but leaves other data alone.
class FakeAudioDownloadStore implements AudioDownloadStore {
  final Map<String, List<int>> files = {};
  final Map<String, String> strings = {};

  @override
  bool get isSupported => true;

  @override
  Future<String> absolutePath(String relativePath) async =>
      '/fake_root/$relativePath';

  @override
  Future<bool> fileExists(String relativePath) async =>
      files.containsKey(relativePath) || strings.containsKey(relativePath);

  @override
  Future<int> fileSize(String relativePath) async =>
      files[relativePath]?.length ?? strings[relativePath]?.length ?? 0;

  @override
  Future<Uint8List> readFileBytes(String relativePath) async =>
      Uint8List.fromList(files[relativePath] ?? const []);

  @override
  Future<String> readFileString(String relativePath) async =>
      strings[relativePath] ?? '';

  @override
  Future<void> deleteFile(String relativePath) async {
    files.remove(relativePath);
    strings.remove(relativePath);
  }

  @override
  Future<void> writeFileBytes(String relativePath, List<int> bytes) async {
    files[relativePath] = List<int>.from(bytes);
  }

  @override
  Future<void> writeFileString(String relativePath, String contents) async {
    strings[relativePath] = contents;
  }
}

/// Store that reports unsupported, simulating the web stub.
class UnsupportedAudioDownloadStore implements AudioDownloadStore {
  @override
  bool get isSupported => false;

  @override
  Future<String> absolutePath(String relativePath) async => relativePath;

  @override
  Future<bool> fileExists(String relativePath) async => false;

  @override
  Future<int> fileSize(String relativePath) async => 0;

  @override
  Future<Uint8List> readFileBytes(String relativePath) async => Uint8List(0);

  @override
  Future<String> readFileString(String relativePath) async => '';

  @override
  Future<void> deleteFile(String relativePath) async {}

  @override
  Future<void> writeFileBytes(String relativePath, List<int> bytes) async {}

  @override
  Future<void> writeFileString(String relativePath, String contents) async {}
}

Uint8List _wavBytes([int size = 32]) {
  final bytes = Uint8List(size);
  for (var i = 0; i < size; i++) {
    bytes[i] = i % 251;
  }
  return bytes;
}

AudioTrack _track({
  required String id,
  String url = 'https://cdn.example.com/audio/clip-1.mp3',
  String? contentHash = 'hash-a',
  bool playable = true,
}) {
  return AudioTrack(
    id: id,
    contentKind: 'rhyme',
    contentId: 'story-1',
    languageCode: 'sat',
    trackType: TrackType.storyNarration,
    audioUrl: url,
    // isPlayable = url non-empty && (approved || isHumanRecorded), so a
    // non-playable fixture must be draft AND not human-recorded.
    reviewStatus: playable ? ReviewStatus.approved : ReviewStatus.draft,
    contentHash: contentHash,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAudioDownloadStore store;
  late AudioDownloadManager manager;

  setUp(() {
    store = FakeAudioDownloadStore();
    manager = AudioDownloadManager(store: store);
  });

  group('relativePathForTrack', () {
    test('extracts a short extension from the url', () {
      final track = _track(id: 't1', url: 'https://x.com/a/b/file.mp3');
      expect(AudioDownloadManager.relativePathForTrack(track), 'tracks/t1.mp3');
    });

    test('returns no extension for dotless urls', () {
      final track = _track(id: 't2', url: 'https://x.com/audio-only');
      expect(AudioDownloadManager.relativePathForTrack(track), 'tracks/t2');
    });

    test('rejects overly long suffixes that are not extensions', () {
      final track = _track(
        id: 't3',
        url: 'https://x.com/some.verylongpathsegment/file',
      );
      expect(AudioDownloadManager.relativePathForTrack(track), 'tracks/t3');
    });

    test('handles null urls', () {
      final track = _track(id: 't4', url: '');
      expect(AudioDownloadManager.relativePathForTrack(track), 'tracks/t4');
    });
  });

  group('skipReasonFor', () {
    test('missingUrl when the url is empty', () {
      final track = _track(id: 't1', url: '');
      expect(manager.skipReasonFor(track), AudioDownloadSkipReason.missingUrl);
    });

    test('notPlayable when the track is not approved/human', () {
      final track = _track(id: 't1', playable: false);
      expect(manager.skipReasonFor(track), AudioDownloadSkipReason.notPlayable);
    });

    test('null when downloadable', () {
      expect(manager.skipReasonFor(_track(id: 't1')), isNull);
    });

    test('unsupportedPlatform on web stub', () {
      final webManager = AudioDownloadManager(
        store: UnsupportedAudioDownloadStore(),
      );
      expect(
        webManager.skipReasonFor(_track(id: 't1')),
        AudioDownloadSkipReason.unsupportedPlatform,
      );
    });
  });

  group('downloadTracks', () {
    test('downloads bytes, records manifest, reports progress', () async {
      final bytes = _wavBytes(64);
      final client = MockClient(
        (request) async => http.Response.bytes(bytes, 200),
      );
      final progressCalls = <AudioDownloadBatchProgress>[];
      final result = await manager.downloadTracks(
        [_track(id: 't1')],
        batchId: 'story:s1',
        onProgress: progressCalls.add,
        client: client,
      );

      expect(result.succeeded, 1);
      expect(result.failed, 0);
      expect(result.skipped, 0);
      expect(result.bytesWritten, 64);
      expect(result.hasFailures, isFalse);

      final record = await manager.recordForTrack('t1');
      expect(record, isNotNull);
      expect(record!.bytes, 64);
      expect(record.sha256, isNotNull);
      expect(record.contentHash, 'hash-a');
      expect(store.files['tracks/t1.mp3'], bytes);

      expect(progressCalls, isNotEmpty);
      expect(progressCalls.last.isDone, isTrue);
      expect(progressCalls.last.overallFraction, 1.0);
    });

    test('dedupes: a fresh existing file is skipped, not re-fetched', () async {
      final bytes = _wavBytes(16);
      var fetchCount = 0;
      final client = MockClient((request) async {
        fetchCount++;
        return http.Response.bytes(bytes, 200);
      });

      await manager.downloadTracks(
        [_track(id: 't1')],
        batchId: 'b1',
        client: client,
      );
      final result = await manager.downloadTracks(
        [_track(id: 't1')],
        batchId: 'b2',
        client: client,
      );

      expect(fetchCount, 1);
      expect(result.skipped, 1);
      expect(result.succeeded, 0);
    });

    test('contentHash invalidation: stale file is re-downloaded', () async {
      final bytes = _wavBytes(16);
      var fetchCount = 0;
      final client = MockClient((request) async {
        fetchCount++;
        return http.Response.bytes(bytes, 200);
      });

      await manager.downloadTracks(
        [_track(id: 't1', contentHash: 'hash-old')],
        batchId: 'b1',
        client: client,
      );
      // Same track id, but upstream regenerated the audio.
      final result = await manager.downloadTracks(
        [_track(id: 't1', contentHash: 'hash-new')],
        batchId: 'b2',
        client: client,
      );

      expect(fetchCount, 2);
      expect(result.succeeded, 1);
      expect(result.skipped, 0);
      expect((await manager.recordForTrack('t1'))!.contentHash, 'hash-new');
    });

    test('non-200 responses fail the item with a reason', () async {
      final client = MockClient(
        (request) async => http.Response.bytes([], 404),
      );
      final result = await manager.downloadTracks(
        [_track(id: 't1')],
        batchId: 'b1',
        client: client,
      );

      expect(result.failed, 1);
      expect(result.succeeded, 0);
      expect(result.failures.single.reason, contains('HTTP 404'));
      expect(await manager.recordForTrack('t1'), isNull);
    });

    test('network errors fail the item without crashing the batch', () async {
      final client = MockClient(
        (request) async => throw Exception('socket hang up'),
      );
      final result = await manager.downloadTracks(
        [_track(id: 'bad'), _track(id: 'good')],
        batchId: 'b1',
        client: client,
      );

      expect(result.failed, 2);
      expect(result.failures, hasLength(2));
    });

    test('un-downloadable tracks are excluded from totals', () async {
      final bytes = _wavBytes(8);
      final client = MockClient(
        (request) async => http.Response.bytes(bytes, 200),
      );
      final result = await manager.downloadTracks(
        [
          _track(id: 'ok'),
          _track(id: 'no-url', url: ''),
          _track(id: 'not-playable', playable: false),
        ],
        batchId: 'b1',
        client: client,
      );

      expect(result.succeeded, 1);
      expect(result.failed, 0);
      // Skipped counts only fresh dedupes, not partitioned-out tracks.
      expect(result.skipped, 0);
    });

    test('cancelBatch stops remaining downloads', () async {
      final bytes = _wavBytes(8);
      final client = MockClient((request) async {
        // Cancel after the first fetch so the loop breaks mid-batch.
        manager.cancelBatch('b1');
        return http.Response.bytes(bytes, 200);
      });
      final result = await manager.downloadTracks(
        [_track(id: 'a'), _track(id: 'b')],
        batchId: 'b1',
        client: client,
      );

      expect(result.succeeded, 0);
      expect(result.failed, 0);
      expect(store.files, isEmpty);
    });

    test(
      'unsupported platform fails every item and never touches storage',
      () async {
        final webManager = AudioDownloadManager(
          store: UnsupportedAudioDownloadStore(),
        );
        final result = await webManager.downloadTracks([
          _track(id: 't1'),
        ], batchId: 'b1');

        expect(result.failed, 1);
        expect(result.failures.single.reason, 'unsupported platform');
        expect(await webManager.downloadCount(), 0);
      },
    );

    test('manifest persists across manager instances', () async {
      final bytes = _wavBytes(24);
      final client = MockClient(
        (request) async => http.Response.bytes(bytes, 200),
      );
      await manager.downloadTracks(
        [_track(id: 't1')],
        batchId: 'b1',
        client: client,
      );

      // New manager on the same store must see the persisted manifest.
      final revived = AudioDownloadManager(store: store);
      final record = await revived.recordForTrack('t1');
      expect(record, isNotNull);
      expect(record!.bytes, 24);

      // And the manifest JSON is real, decodable content on the store.
      final raw = store.strings['downloads_manifest.json'];
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as Map<String, dynamic>;
      expect(decoded.containsKey('t1'), isTrue);
    });

    test('corrupt manifest entries are ignored, not fatal', () async {
      store.strings['downloads_manifest.json'] = 'not json at all';
      final revived = AudioDownloadManager(store: store);
      expect(await revived.downloadCount(), 0);
    });
  });

  group('downloadTrack (single)', () {
    test('uses a single:<id> batch id', () async {
      final bytes = _wavBytes(8);
      final client = MockClient(
        (request) async => http.Response.bytes(bytes, 200),
      );
      final result = await manager.downloadTrack(
        _track(id: 't1'),
        client: client,
      );
      expect(result.batchId, 'single:t1');
      expect(result.succeeded, 1);
    });
  });

  group('storage usage + cache management', () {
    test('storageUsageBytes sums manifest byte counts', () async {
      final client = MockClient(
        (request) async => http.Response.bytes(_wavBytes(), 200),
      );
      await manager.downloadTracks(
        [_track(id: 'a'), _track(id: 'b')],
        batchId: 'b1',
        client: client,
      );
      expect(await manager.storageUsageBytes(), 64);
      expect(await manager.downloadCount(), 2);
    });

    test('storageUsageBytes prunes records whose file is gone', () async {
      final client = MockClient(
        (request) async => http.Response.bytes(_wavBytes(), 200),
      );
      await manager.downloadTracks(
        [_track(id: 'a'), _track(id: 'b')],
        batchId: 'b1',
        client: client,
      );

      // Simulate an external purge of one file.
      await store.deleteFile('tracks/a.mp3');
      expect(await manager.storageUsageBytes(), 32);
      // The pruned entry disappears from the manifest.
      expect(await manager.recordForTrack('a'), isNull);
      expect(await manager.downloadCount(), 1);
    });

    test('deleteTrack removes one file and its record', () async {
      final client = MockClient(
        (request) async => http.Response.bytes(_wavBytes(16), 200),
      );
      await manager.downloadTracks(
        [_track(id: 'a'), _track(id: 'b')],
        batchId: 'b1',
        client: client,
      );

      await manager.deleteTrack('a');
      expect(store.files.containsKey('tracks/a.mp3'), isFalse);
      expect(await manager.recordForTrack('a'), isNull);
      expect(await manager.recordForTrack('b'), isNotNull);
      expect(await manager.downloadCount(), 1);
    });

    test('deleteAll wipes files and the manifest', () async {
      final client = MockClient(
        (request) async => http.Response.bytes(_wavBytes(16), 200),
      );
      await manager.downloadTracks(
        [_track(id: 'a'), _track(id: 'b')],
        batchId: 'b1',
        client: client,
      );

      await manager.deleteAll();
      expect(store.files, isEmpty);
      expect(await manager.downloadCount(), 0);
      expect(await manager.storageUsageBytes(), 0);

      // Even a fresh manager sees an empty manifest.
      expect(await AudioDownloadManager(store: store).downloadCount(), 0);
    });
  });

  group('integrity verification', () {
    test('verifyIntegrity passes for an untouched file', () async {
      final client = MockClient(
        (request) async => http.Response.bytes(_wavBytes(48), 200),
      );
      await manager.downloadTracks(
        [_track(id: 't1')],
        batchId: 'b1',
        client: client,
      );
      final record = (await manager.recordForTrack('t1'))!;
      expect(await manager.verifyIntegrity(record), isTrue);
    });

    test('verifyIntegrity fails for a tampered file', () async {
      final client = MockClient(
        (request) async => http.Response.bytes(_wavBytes(48), 200),
      );
      await manager.downloadTracks(
        [_track(id: 't1')],
        batchId: 'b1',
        client: client,
      );

      // Tamper: flip one byte on disk.
      final bytes = store.files['tracks/t1.mp3']!;
      bytes[0] = (bytes[0] + 1) % 256;
      store.files['tracks/t1.mp3'] = bytes;

      final record = (await manager.recordForTrack('t1'))!;
      expect(await manager.verifyIntegrity(record), isFalse);
    });

    test('verifyIntegrity fails for a missing file', () async {
      final client = MockClient(
        (request) async => http.Response.bytes(_wavBytes(8), 200),
      );
      await manager.downloadTracks(
        [_track(id: 't1')],
        batchId: 'b1',
        client: client,
      );
      final record = (await manager.recordForTrack('t1'))!;
      await store.deleteFile(record.relativePath);
      expect(await manager.verifyIntegrity(record), isFalse);
    });
  });

  group('local playback URL', () {
    test('localFileUrlFor returns a file:// URL for a download', () async {
      final client = MockClient(
        (request) async => http.Response.bytes(_wavBytes(8), 200),
      );
      await manager.downloadTracks(
        [_track(id: 't1')],
        batchId: 'b1',
        client: client,
      );

      final url = await manager.localFileUrlFor(_track(id: 't1'));
      expect(url, 'file:///fake_root/tracks/t1.mp3');
    });

    test('localFileUrlFor returns null when the file is missing', () async {
      expect(await manager.localFileUrlFor(_track(id: 'nope')), isNull);
    });
  });

  group('downloadStoryPack', () {
    test(
      'uses a story:<id> batch id and filters un-downloadable tracks',
      () async {
        final client = MockClient(
          (request) async => http.Response.bytes(_wavBytes(8), 200),
        );
        final result = await manager.downloadStoryPack('story-9', [
          DownloadableTrack(track: _track(id: 'ok')),
          DownloadableTrack(
            track: _track(id: 'broken', url: ''),
          ),
        ], client: client);

        expect(result.batchId, 'story:story-9');
        expect(result.succeeded, 1);
        expect(result.failed, 0);
      },
    );
  });
}
