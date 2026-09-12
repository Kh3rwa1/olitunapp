import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/profile/data/datasources/remote_avatar_cache.dart';
import 'package:itun/features/profile/data/datasources/remote_avatar_datasource.dart';
import 'package:itun/features/profile/domain/entities/profile_avatar.dart';
import 'package:itun/features/profile/presentation/providers/profile_account_providers.dart';
import 'package:itun/features/profile/presentation/widgets/avatar_lottie.dart';
import 'package:lottie/lottie.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Future<Set<String>> cachedFileIds() async => const {};
}

Uint8List _lottieBytes() => Uint8List.fromList(
  utf8.encode(
    jsonEncode({
      'v': '5.7.0',
      'fr': 60,
      'ip': 0,
      'op': 10,
      'w': 10,
      'h': 10,
      'layers': [
        {'nm': 'l'},
      ],
    }),
  ),
);

FileList _files(String updatedAt) => FileList.fromMap({
  'total': 1,
  'files': [
    {
      '\$id': 'remote1',
      'bucketId': 'profile_avatars',
      '\$createdAt': updatedAt,
      '\$updatedAt': updatedAt,
      '\$permissions': ['read("any")'],
      'name': 'avatar_dragon.json',
      'signature': 's',
      'mimeType': 'application/json',
      'sizeOriginal': 10,
      'chunksTotal': 1,
      'chunksUploaded': 1,
      'encryption': false,
      'compression': 'none',
    },
  ],
});

Future<ProviderContainer> _container({
  required SharedPreferences prefs,
  required Storage storage,
}) async {
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      remoteAvatarDatasourceProvider.overrideWithValue(
        RemoteAvatarDatasource(storage, MemoryAvatarCache()),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test(
    'availableAvatarsProvider prefers the remote set when sync succeeds',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = MockStorage();
      when(
        () => storage.listFiles(bucketId: any(named: 'bucketId')),
      ).thenAnswer((_) async => _files('u1'));
      when(
        () => storage.getFileDownload(
          bucketId: any(named: 'bucketId'),
          fileId: any(named: 'fileId'),
        ),
      ).thenAnswer((_) async => _lottieBytes());

      final container = await _container(prefs: prefs, storage: storage);
      final avatars = await container.read(availableAvatarsProvider.future);

      expect(avatars.map((a) => a.id), ['dragon']);
      expect(avatars.first.isRemote, isTrue);
    },
  );

  test(
    'availableAvatarsProvider falls back to bundled when sync fails',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = MockStorage();
      when(
        () => storage.listFiles(bucketId: any(named: 'bucketId')),
      ).thenThrow(AppwriteException('offline'));

      final container = await _container(prefs: prefs, storage: storage);
      final avatars = await container.read(availableAvatarsProvider.future);

      expect(avatars, kProfileAvatars);
    },
  );

  test(
    'avatarArtworkBytesProvider serves cached bytes for remote avatars',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = MockStorage();
      final renderable = await io.File(
        'assets/animations/avatars/avatar_paw_prints.json',
      ).readAsBytes();
      when(
        () => storage.listFiles(bucketId: any(named: 'bucketId')),
      ).thenAnswer((_) async => _files('u1'));
      when(
        () => storage.getFileDownload(
          bucketId: any(named: 'bucketId'),
          fileId: any(named: 'fileId'),
        ),
      ).thenAnswer((_) async => renderable);

      final container = await _container(prefs: prefs, storage: storage);
      final avatars = await container.read(availableAvatarsProvider.future);
      final bytes = await container.read(
        avatarArtworkBytesProvider(avatars.first).future,
      );

      expect(bytes, renderable);
    },
  );

  testWidgets('AvatarLottie degrades when remote bytes are missing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const orphan = ProfileAvatar(
      id: 'ghost',
      assetFileName: 'avatar_ghost.json',
      label: 'Ghost',
      remoteFileId: 'nope',
    );
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        avatarArtworkBytesProvider(
          orphan,
        ).overrideWith((ref) => throw StateError('no bytes')),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: AvatarLottie(
              avatar: orphan,
              width: 64,
              height: 64,
              animate: false,
              repeat: false,
              fallback: Text('fallback'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Falls back to bundled artwork, never a blank box or an exception.
    expect(find.byType(LottieBuilder), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
