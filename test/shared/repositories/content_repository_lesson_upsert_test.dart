import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/api/admin_content_client.dart';
import 'package:itun/core/api/content_remote_datasource.dart';
import 'package:itun/core/config/cloudflare_config.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/repositories/content_repository.dart';

class _FakeNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}

ContentItem _buildLessonItem({String categoryId = 'cat_sentences'}) =>
    ContentItem(
      id: 'lesson_basics_1',
      kind: ContentKind.lesson,
      categoryId: categoryId,
      title: 'Basic Sentences',
      titleOlChiki: 'ᱥᱟᱱᱛᱟᱲᱤ ᱟᱹᱭᱟᱹᱛ',
      blocks: const [
        TextBlock(
          id: 'b1',
          order: 0,
          markdown: 'Nowa do ced kana?',
          textLatin: 'Nowa do ced kana?',
          textOlChiki: 'ᱱᱚᱶᱟ ᱫᱚ ᱪᱮᱫ ᱠᱟᱱᱟ?',
          meta: {'meaning_en': 'What is this?'},
        ),
      ],
      order: 1,
      isPublished: true,
      updatedAt: DateTime(2026, 9, 6),
    );

http.Response _json(Object body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status);

void main() {
  late Directory tempDir;
  late List<http.Request> requests;
  late http.Response Function(http.Request) respond;
  late ContentRepository repo;

  const lessonPath = '/api/v1/admin/content/lessons/lesson_basics_1';

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('test_hive_lesson_upsert');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    CacheService.resetForTesting();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  setUp(() {
    CacheService.resetForTesting();
    requests = [];
    // Echo the stored document back like the Worker does.
    respond = (request) {
      final doc = jsonDecode(request.body) as Map<String, dynamic>;
      return _json({
        'ok': true,
        'item': {...doc, 'id': 'lesson_basics_1'},
      });
    };
    final client = MockClient((request) async {
      requests.add(request);
      return respond(request);
    });
    repo = ContentRepository(
      remoteDataSource: ContentRemoteDataSourceImpl(
        httpClient: client,
        adminClient: AdminContentClient(
          client,
          authHeaders: () async => {'Authorization': 'Bearer jwt-admin'},
        ),
      ),
      networkInfo: _FakeNetworkInfo(),
    );
  });

  group('ContentRepository admin writes go to the Worker', () {
    test('upsert PUTs the lesson document with the admin JWT', () async {
      final result = await repo.upsert(_buildLessonItem());

      result.fold(
        (failure) => fail('Upsert should have succeeded: ${failure.message}'),
        (saved) {
          expect(saved.id, 'lesson_basics_1');
          expect(saved.kind, ContentKind.lesson);
          expect(saved.blocks.length, 1);
        },
      );
      final request = requests.single;
      expect(request.method, 'PUT');
      expect(request.url.toString(), '${CloudflareConfig.baseUrl}$lessonPath');
      expect(request.headers['Authorization'], 'Bearer jwt-admin');
      expect(request.headers['Content-Type'], startsWith('application/json'));
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body.containsKey('id'), isFalse);
      expect(body['categoryId'], 'cat_sentences');
      expect(body['titleOlChiki'], 'ᱥᱟᱱᱛᱟᱲᱤ ᱟᱹᱭᱟᱹᱛ');
      // No category lookup: premium gating is enforced by the Worker.
      expect(requests.where((r) => r.url.path.contains('/categories/')), []);
    });

    test('a Worker rejection surfaces as a ServerFailure', () async {
      respond = (_) => http.Response(
        jsonEncode({'ok': false, 'message': 'Admin access required'}),
        403,
      );

      final result = await repo.upsert(_buildLessonItem());

      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, contains('403'));
        expect(failure.message, contains('Admin access required'));
      }, (_) => fail('Expected the 403 to surface'));
    });

    test(
      'getForAdministration reads the full body from the admin route',
      () async {
        respond = (_) => _json({
          'ok': true,
          'item': {
            'id': 'lesson_basics_1',
            ..._buildLessonItem().toAppwriteAttributes(),
          },
        });

        final result = await repo.getForAdministration(
          ContentKind.lesson,
          'lesson_basics_1',
        );

        expect(result.isRight(), isTrue);
        expect(requests.single.method, 'GET');
        expect(requests.single.url.path, lessonPath);
        expect(requests.single.headers['Authorization'], 'Bearer jwt-admin');
      },
    );

    test('delete sends DELETE and surfaces a missing row', () async {
      respond = (request) => request.method == 'DELETE'
          ? http.Response(
              jsonEncode({'ok': false, 'message': 'Row not found'}),
              404,
            )
          : http.Response('{"ok":false}', 404);

      final result = await repo.delete(ContentKind.lesson, 'lesson_basics_1');

      expect(result.isLeft(), isTrue);
      final delete = requests.singleWhere((r) => r.method == 'DELETE');
      expect(delete.url.path, lessonPath);
      expect(delete.headers['Authorization'], 'Bearer jwt-admin');
    });
  });
}
