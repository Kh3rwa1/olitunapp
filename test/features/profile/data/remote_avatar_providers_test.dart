import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/profile/data/datasources/remote_avatar_cache.dart';
import 'package:itun/features/profile/data/datasources/remote_avatar_datasource.dart';
import 'package:itun/features/profile/domain/entities/profile_avatar.dart';
import 'package:itun/features/profile/presentation/providers/profile_account_providers.dart';
import 'package:itun/features/profile/presentation/widgets/avatar_lottie.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

http.Response _listing() => http.Response(
  jsonEncode({
    'ok': true,
    'total': 1,
    'avatars': [
      {
        'id': 'avatar_dragon.json',
        'name': 'avatar_dragon.json',
        'key': 'avatars/avatar_dragon.json',
        'path': '/api/v1/assets/avatars/avatar_dragon.json',
        'size': 10,
        'version': 'e1',
        'updatedAt': '2026-10-01T00:00:00.000Z',
      },
    ],
  }),
  200,
);

/// Fake Worker: [list] answers `/api/v1/avatars`, [bytes] answers asset
/// downloads; [downloads] counts asset requests.
class _FakeWorker {
  _FakeWorker({required this.list, List<int>? bytes})
    : bytes = bytes ?? _lottieBytes();

  final Future<http.Response> Function() list;
  final List<int> bytes;
  int downloads = 0;

  late final MockClient client = MockClient((request) async {
    if (request.url.path == '/api/v1/avatars') return list();
    if (request.url.path.startsWith('/api/v1/assets/')) {
      downloads++;
      return http.Response.bytes(bytes, 200);
    }
    return http.Response('not found', 404);
  });
}

Future<ProviderContainer> _container({
  required SharedPreferences prefs,
  required http.Client client,
}) async {
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      remoteAvatarDatasourceProvider.overrideWithValue(
        RemoteAvatarDatasource(client, MemoryAvatarCache()),
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
      final gate = Completer<http.Response>();
      addTearDown(() {
        if (!gate.isCompleted) gate.completeError(StateError('teardown'));
      });
      final worker = _FakeWorker(list: () => gate.future);

      final container = await _container(prefs: prefs, client: worker.client);
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
      final worker = _FakeWorker(list: () async => _listing());

      final container = await _container(prefs: prefs, client: worker.client);
      final emissions = await _emissionsUntil(container, (e) => e.length >= 2);

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
      final worker = _FakeWorker(
        list: () async => throw http.ClientException('offline'),
      );

      final container = await _container(prefs: prefs, client: worker.client);
      final emissions = await _emissionsUntil(container, (e) => e.isNotEmpty);

      expect(emissions.length, 1);
      expect(emissions.single, kProfileAvatars);
    },
  );

  test(
    'avatarArtworkBytesProvider serves cached bytes for remote avatars',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final renderable = await io.File(
        'assets/animations/avatars/avatar_paw_prints.json',
      ).readAsBytes();
      final worker = _FakeWorker(
        list: () async => _listing(),
        bytes: renderable,
      );

      final container = await _container(prefs: prefs, client: worker.client);
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
      expect(worker.downloads, 1);
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
