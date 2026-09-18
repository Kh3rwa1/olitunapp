import 'dart:async';
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

/// Collects data emissions until [done] holds. Riverpod's exposed stream
/// only closes on provider dispose, so `.toList()` would hang forever.
Future<List<List<ProfileAvatar>>> _emissionsUntil(
  ProviderContainer container,
  bool Function(List<List<ProfileAvatar>> emissions) done,
) async {
  final emissions = <List<ProfileAvatar>>[];
  final sub = container.listen<AsyncValue<List<ProfileAvatar>>>(
    availableAvatarsProvider,
    (_, next) => next.whenData(emissions.add),
    fireImmediately: true,
  );
  try {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!done(emissions)) {
      if (DateTime.now().isAfter(deadline)) {
        throw StateError('Timed out waiting for avatar emissions');
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    // Extra pump so an unexpected follow-up yield would surface.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return List.of(emissions);
  } finally {
    sub.close();
  }
}

void main() {
  test(
    'availableAvatarsProvider emits bundled catalog instantly without network',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      // A network that never answers: the old blocking implementation would
      // stall on the 8s sync timeout, so the first frame must arrive well
      // before that to prove the picker never blocks on Appwrite.
      final gate = Completer<FileList>();
      addTearDown(() {
        if (!gate.isCompleted) gate.completeError(StateError('teardown'));
      });
      final storage = MockStorage();
      when(
        () => storage.listFiles(bucketId: any(named: 'bucketId')),
      ).thenAnswer((_) => gate.future);

      final container = await _container(prefs: prefs, storage: storage);
      final first = await container
          .read(availableAvatarsProvider.future)
          .timeout(const Duration(seconds: 2));

      expect(
        first.map((avatar) => avatar.id),
        orderedEquals(kProfileAvatars.map((avatar) => avatar.id)),
      );
    },
  );

  test(
    'availableAvatarsProvider merges the remote set in the background',
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
      final emissions = await _emissionsUntil(
        container,
        (e) => e.length >= 2,
      );

      // Bundled first (instant grid), merged catalog once sync lands.
      expect(
        emissions.first.map((a) => a.id),
        orderedEquals(kProfileAvatars.map((avatar) => avatar.id)),
      );
      final merged = emissions.last;
      expect(
        merged.map((a) => a.id),
        orderedEquals([
          ...kProfileAvatars.map((avatar) => avatar.id),
          'dragon',
        ]),
      );
      expect(merged.last.isRemote, isTrue);
    },
  );

  test(
    'availableAvatarsProvider keeps bundled catalog when sync fails',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = MockStorage();
      when(
        () => storage.listFiles(bucketId: any(named: 'bucketId')),
      ).thenThrow(AppwriteException('offline'));

      final container = await _container(prefs: prefs, storage: storage);
      final emissions = await _emissionsUntil(
        container,
        (e) => e.isNotEmpty,
      );

      expect(emissions.length, 1);
      expect(emissions.single, kProfileAvatars);
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
      final emissions = await _emissionsUntil(
        container,
        (e) => e.any((list) => list.any((avatar) => avatar.isRemote)),
      );
      final merged = emissions.last;
      final remote = merged.firstWhere((avatar) => avatar.isRemote);
      final bytes = await container.read(
        avatarArtworkBytesProvider(remote).future,
      );

      expect(bytes, renderable);

      // Second read is served from the in-memory memo: no re-download.
      await container.read(avatarArtworkBytesProvider(remote).future);
      verify(
        () => storage.getFileDownload(
          bucketId: any(named: 'bucketId'),
          fileId: any(named: 'fileId'),
        ),
      ).called(1);
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
