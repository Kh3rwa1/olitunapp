import 'dart:convert';
import 'dart:typed_data';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/features/profile/data/datasources/remote_avatar_cache.dart';
import 'package:itun/features/profile/data/datasources/remote_avatar_datasource.dart';

class MockStorage extends Mock implements Storage {}

class MemoryAvatarCache extends RemoteAvatarCache {
  final files = <String, List<int>>{};

  @override
  bool get isSupported => true;

  @override
  Future<void> writeBytes(String relativePath, List<int> bytes) async {
    files[relativePath] = bytes;
  }

  @override
  Future<List<int>> readBytes(String relativePath) async {
    final bytes = files[relativePath];
    if (bytes == null) throw StateError('missing $relativePath');
    return bytes;
  }

  @override
  Future<bool> exists(String relativePath) async =>
      files.containsKey(relativePath);

  @override
  Future<void> delete(String relativePath) async {
    files.remove(relativePath);
  }

  @override
  Future<Set<String>> cachedFileIds() async => files.keys
      .where((path) => path.endsWith('.json') && path != 'manifest.json')
      .map((path) => path.substring(0, path.length - '.json'.length))
      .toSet();
}

Map<String, dynamic> _fileMap(String id, String name, String updatedAt) => {
  '\$id': id,
  'bucketId': 'profile_avatars',
  '\$createdAt': updatedAt,
  '\$updatedAt': updatedAt,
  '\$permissions': ['read("any")'],
  'name': name,
  'signature': 'sig',
  'mimeType': 'application/json',
  'sizeOriginal': 10,
  'chunksTotal': 1,
  'chunksUploaded': 1,
  'encryption': false,
  'compression': 'none',
};

Uint8List _lottieBytes() => Uint8List.fromList(
  utf8.encode(
    jsonEncode({
      'v': '5.7.0',
      'fr': 60,
      'ip': 0,
      'op': 90,
      'w': 100,
      'h': 100,
      'layers': [
        {'nm': 'layer'},
      ],
    }),
  ),
);

void main() {
  late MockStorage storage;
  late MemoryAvatarCache cache;
  late RemoteAvatarDatasource datasource;

  setUp(() {
    storage = MockStorage();
    cache = MemoryAvatarCache();
    datasource = RemoteAvatarDatasource(storage, cache);
  });

  test('sync maps bucket files to catalog entries and caches bytes', () async {
    when(() => storage.listFiles(bucketId: any(named: 'bucketId'))).thenAnswer(
      (_) async => FileList.fromMap({
        'total': 2,
        'files': [
          _fileMap('f1', 'avatar_tiger.json', 'u1'),
          _fileMap('f2', 'avatar_owl.json', 'u2'),
        ],
      }),
    );
    when(
      () => storage.getFileDownload(
        bucketId: any(named: 'bucketId'),
        fileId: any(named: 'fileId'),
      ),
    ).thenAnswer((_) async => _lottieBytes());

    final result = await datasource.syncAvatars();

    expect(result.isRight(), isTrue);
    final avatars = result.getOrElse((_) => throw StateError('left'));
    expect(avatars.map((a) => a.id), ['tiger', 'owl']);
    expect(avatars.every((a) => a.isRemote), isTrue);
    expect(avatars.first.remoteFileId, 'f1');
    expect(await cache.exists('f1.json'), isTrue);
  });

  test('sync skips non-json files and unusable names', () async {
    when(() => storage.listFiles(bucketId: any(named: 'bucketId'))).thenAnswer(
      (_) async => FileList.fromMap({
        'total': 3,
        'files': [
          _fileMap('f1', 'avatar_tiger.json', 'u1'),
          _fileMap('f2', 'notes.txt', 'u1'),
          _fileMap('f3', 'avatar_.json', 'u1'),
        ],
      }),
    );
    when(
      () => storage.getFileDownload(
        bucketId: any(named: 'bucketId'),
        fileId: any(named: 'fileId'),
      ),
    ).thenAnswer((_) async => _lottieBytes());

    final result = await datasource.syncAvatars();
    final avatars = result.getOrElse((_) => throw StateError('left'));
    expect(avatars.map((a) => a.id), ['tiger']);
  });

  test('sync skips re-download for unchanged files', () async {
    when(() => storage.listFiles(bucketId: any(named: 'bucketId'))).thenAnswer(
      (_) async => FileList.fromMap({
        'total': 1,
        'files': [_fileMap('f1', 'avatar_tiger.json', 'u1')],
      }),
    );
    var downloads = 0;
    when(
      () => storage.getFileDownload(
        bucketId: any(named: 'bucketId'),
        fileId: any(named: 'fileId'),
      ),
    ).thenAnswer((_) async {
      downloads++;
      return _lottieBytes();
    });

    await datasource.syncAvatars();
    await datasource.syncAvatars();
    expect(downloads, 1);
  });

  test('sync prunes files removed from the bucket', () async {
    when(() => storage.listFiles(bucketId: any(named: 'bucketId'))).thenAnswer(
      (_) async => FileList.fromMap({
        'total': 1,
        'files': [_fileMap('f1', 'avatar_tiger.json', 'u1')],
      }),
    );
    when(
      () => storage.getFileDownload(
        bucketId: any(named: 'bucketId'),
        fileId: any(named: 'fileId'),
      ),
    ).thenAnswer((_) async => _lottieBytes());

    await datasource.syncAvatars();
    expect(await cache.exists('f1.json'), isTrue);

    when(
      () => storage.listFiles(bucketId: any(named: 'bucketId')),
    ).thenAnswer((_) async => FileList.fromMap({'total': 0, 'files': []}));
    final result = await datasource.syncAvatars();
    expect(result.getOrElse((_) => throw StateError('left')), isEmpty);
    expect(await cache.exists('f1.json'), isFalse);
  });

  test('sync rejects invalid lottie payloads', () async {
    when(() => storage.listFiles(bucketId: any(named: 'bucketId'))).thenAnswer(
      (_) async => FileList.fromMap({
        'total': 1,
        'files': [_fileMap('f1', 'avatar_tiger.json', 'u1')],
      }),
    );
    when(
      () => storage.getFileDownload(
        bucketId: any(named: 'bucketId'),
        fileId: any(named: 'fileId'),
      ),
    ).thenAnswer((_) async => utf8.encode('not json'));

    final result = await datasource.syncAvatars();
    expect(result.isLeft(), isTrue);
    expect(
      result.fold((l) => l, (_) => throw StateError('right')),
      isA<CacheFailure>(),
    );
  });

  test('sync maps Appwrite errors to failures', () async {
    when(
      () => storage.listFiles(bucketId: any(named: 'bucketId')),
    ).thenThrow(AppwriteException('offline', 500, 'network_error', 'resp'));

    final result = await datasource.syncAvatars();
    expect(result.isLeft(), isTrue);
    expect(
      result.fold((l) => l, (_) => throw StateError('right')),
      isA<NetworkFailure>(),
    );
  });
}
