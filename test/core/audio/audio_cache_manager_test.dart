// ignore_for_file: depend_on_referenced_packages
import 'package:file/memory.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/audio/audio_cache_manager.dart';
import 'package:mocktail/mocktail.dart';

class MockBaseCacheManager extends Mock implements BaseCacheManager {}

void main() {
  late MockBaseCacheManager mockCache;
  late DefaultAudioCacheManager cacheManager;
  late MemoryFileSystem memoryFs;

  setUp(() {
    mockCache = MockBaseCacheManager();
    cacheManager = DefaultAudioCacheManager(mockCache);
    memoryFs = MemoryFileSystem();
  });

  group('AudioCacheManager', () {
    test('returns Uri as-is for empty or local/asset URLs', () async {
      expect(
        (await cacheManager.getPlayableUri('')).toString(),
        '',
      );
      expect(
        (await cacheManager.getPlayableUri('assets/audio/eyes.wav')).toString(),
        'assets/audio/eyes.wav',
      );
      expect(
        (await cacheManager.getPlayableUri('file:///data/audio.mp3')).toString(),
        'file:///data/audio.mp3',
      );
      expect(
        (await cacheManager.getPlayableUri('/var/mobile/sound.wav')).toString(),
        '/var/mobile/sound.wav',
      );
    });

    test('returns file: Uri on cache hit without downloading', () async {
      final file = memoryFs.file('/cache/audio/123.wav');
      file.createSync(recursive: true);

      final fileInfo = FileInfo(
        file,
        FileSource.Cache,
        DateTime.now().add(const Duration(days: 1)),
        'https://example.com/audio.wav',
      );

      when(
        () => mockCache.getFileFromCache('https://example.com/audio.wav'),
      ).thenAnswer((_) async => fileInfo);

      final uri = await cacheManager.getPlayableUri('https://example.com/audio.wav');

      expect(uri.isScheme('file'), isTrue);
      expect(uri.toFilePath(), '/cache/audio/123.wav');
      verifyNever(() => mockCache.downloadFile(any()));
    });

    test('returns remote Uri on cache miss and initiates background download', () async {
      when(
        () => mockCache.getFileFromCache('https://example.com/new.wav'),
      ).thenAnswer((_) async => null);

      final file = memoryFs.file('/cache/audio/new.wav');
      final fileInfo = FileInfo(
        file,
        FileSource.Online,
        DateTime.now().add(const Duration(days: 1)),
        'https://example.com/new.wav',
      );
      when(
        () => mockCache.downloadFile('https://example.com/new.wav'),
      ).thenAnswer((_) async => fileInfo);

      final uri = await cacheManager.getPlayableUri('https://example.com/new.wav');

      expect(uri.toString(), 'https://example.com/new.wav');
      await Future<void>.delayed(Duration.zero);
      verify(() => mockCache.downloadFile('https://example.com/new.wav')).called(1);
    });

    test('isCached returns true when file is in cache and exists', () async {
      final file = memoryFs.file('/cache/audio/cached.mp3');
      file.createSync(recursive: true);

      final fileInfo = FileInfo(
        file,
        FileSource.Cache,
        DateTime.now().add(const Duration(days: 1)),
        'https://example.com/cached.mp3',
      );

      when(
        () => mockCache.getFileFromCache('https://example.com/cached.mp3'),
      ).thenAnswer((_) async => fileInfo);

      expect(await cacheManager.isCached('https://example.com/cached.mp3'), isTrue);
    });

    test('isCached returns false when file is missing from cache', () async {
      when(
        () => mockCache.getFileFromCache('https://example.com/missing.mp3'),
      ).thenAnswer((_) async => null);

      expect(await cacheManager.isCached('https://example.com/missing.mp3'), isFalse);
    });

    test('precache downloads missing audio files in batches', () async {
      when(
        () => mockCache.getFileFromCache(any()),
      ).thenAnswer((_) async => null);

      final file = memoryFs.file('/cache/audio/f.wav');
      final fileInfo = FileInfo(
        file,
        FileSource.Online,
        DateTime.now().add(const Duration(days: 1)),
        'url',
      );
      when(() => mockCache.downloadFile(any())).thenAnswer((_) async => fileInfo);

      await cacheManager.precache([
        'https://example.com/1.wav',
        'https://example.com/2.wav',
        'https://example.com/3.wav',
      ]);

      verify(() => mockCache.downloadFile('https://example.com/1.wav')).called(1);
      verify(() => mockCache.downloadFile('https://example.com/2.wav')).called(1);
      verify(() => mockCache.downloadFile('https://example.com/3.wav')).called(1);
    });

    test('clearCache empties cache safely', () async {
      when(() => mockCache.emptyCache()).thenAnswer((_) async {});
      await cacheManager.clearCache();
      verify(() => mockCache.emptyCache()).called(1);
    });
  });
}
