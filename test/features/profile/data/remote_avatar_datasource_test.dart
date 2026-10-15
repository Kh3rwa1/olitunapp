import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/features/profile/data/datasources/remote_avatar_cache.dart';
import 'package:itun/features/profile/data/datasources/remote_avatar_datasource.dart';

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

Map<String, dynamic> _object(String name, String version) => {
  'id': name,
  'name': name,
  'key': 'avatars/$name',
  'path': '/api/v1/assets/avatars/$name',
  'size': 10,
  'version': version,
  'updatedAt': '2026-10-01T00:00:00.000Z',
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

/// Fake Worker: `/api/v1/avatars` lists [objects]; `/api/v1/assets/*`
/// serves [fileBytes]. Records every request path.
class _FakeWorker {
  List<Map<String, dynamic>> objects = [];
  List<int> Function() fileBytes = _lottieBytes;
  int listStatus = 200;
  final requests = <String>[];

  late final MockClient client = MockClient((request) async {
    requests.add(request.url.path);
    if (request.url.path == '/api/v1/avatars') {
      if (listStatus != 200) return http.Response('boom', listStatus);
      return http.Response(
        jsonEncode({'ok': true, 'total': objects.length, 'avatars': objects}),
        200,
      );
    }
    if (request.url.path.startsWith('/api/v1/assets/avatars/')) {
      return http.Response.bytes(fileBytes(), 200);
    }
    return http.Response('not found', 404);
  });

  int get downloads =>
      requests.where((p) => p.startsWith('/api/v1/assets/')).length;
}

void main() {
  late _FakeWorker worker;
  late MemoryAvatarCache cache;
  late RemoteAvatarDatasource datasource;

  setUp(() {
    worker = _FakeWorker();
    cache = MemoryAvatarCache();
    datasource = RemoteAvatarDatasource(worker.client, cache);
  });

  test('sync lists the Worker catalogue and caches bytes', () async {
    worker.objects = [
      _object('avatar_tiger.json', 'e1'),
      _object('avatar_owl.json', 'e2'),
    ];

    final result = await datasource.syncAvatars();

    expect(result.isRight(), isTrue);
    final avatars = result.getOrElse((_) => throw StateError('left'));
    expect(avatars.map((a) => a.id), ['tiger', 'owl']);
    expect(avatars.every((a) => a.isRemote), isTrue);
    expect(avatars.first.remoteFileId, 'avatar_tiger.json');
    expect(await cache.exists('avatar_tiger.json.json'), isTrue);
    expect(worker.requests, contains('/api/v1/avatars'));
    expect(
      worker.requests,
      contains('/api/v1/assets/avatars/avatar_tiger.json'),
    );
  });

  test('empty catalogue is a valid empty result', () async {
    final result = await datasource.syncAvatars();
    expect(result.getOrElse((_) => throw StateError('left')), isEmpty);
    expect(worker.downloads, 0);
  });

  test('sync skips non-json files and unusable names', () async {
    worker.objects = [
      _object('avatar_tiger.json', 'e1'),
      _object('notes.txt', 'e1'),
      _object('avatar_.json', 'e1'),
    ];

    final result = await datasource.syncAvatars();
    final avatars = result.getOrElse((_) => throw StateError('left'));
    expect(avatars.map((a) => a.id), ['tiger']);
  });

  test('sync skips re-download for unchanged files', () async {
    worker.objects = [_object('avatar_tiger.json', 'e1')];

    await datasource.syncAvatars();
    await datasource.syncAvatars();
    expect(worker.downloads, 1);

    worker.objects = [_object('avatar_tiger.json', 'e2')];
    await datasource.syncAvatars();
    expect(worker.downloads, 2);
  });

  test('sync prunes files removed from the catalogue', () async {
    worker.objects = [_object('avatar_tiger.json', 'e1')];
    await datasource.syncAvatars();
    expect(await cache.exists('avatar_tiger.json.json'), isTrue);

    worker.objects = [];
    final result = await datasource.syncAvatars();
    expect(result.getOrElse((_) => throw StateError('left')), isEmpty);
    expect(await cache.exists('avatar_tiger.json.json'), isFalse);
  });

  test('sync rejects invalid lottie payloads', () async {
    worker.objects = [_object('avatar_tiger.json', 'e1')];
    worker.fileBytes = () => utf8.encode('not json');

    final result = await datasource.syncAvatars();
    expect(result.isLeft(), isTrue);
    expect(
      result.fold((l) => l, (_) => throw StateError('right')),
      isA<CacheFailure>(),
    );
  });

  test('sync surfaces Worker errors as failures', () async {
    worker.listStatus = 500;

    final result = await datasource.syncAvatars();
    expect(
      result.fold((l) => l, (_) => throw StateError('right')),
      isA<ServerFailure>(),
    );
  });

  test('sync maps transport errors to network failures', () async {
    final offline = RemoteAvatarDatasource(
      MockClient((_) async => throw http.ClientException('offline')),
      cache,
    );
    final result = await offline.syncAvatars();
    expect(
      result.fold((l) => l, (_) => throw StateError('right')),
      isA<NetworkFailure>(),
    );
  });
}
