import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/api/admin_content_client.dart';
import 'package:itun/core/config/cloudflare_config.dart';
import 'package:itun/core/error/exceptions.dart';
import 'package:itun/features/lessons/data/datasources/lesson_remote_datasource.dart';
import 'package:itun/features/lessons/data/models/lesson_model.dart';

const _lesson = LessonModel(
  id: 'lesson_1',
  categoryId: 'cat/1',
  titleOlChiki: 'ᱚ',
  titleLatin: 'O',
  order: 1,
  blocks: [],
);

const _lessonUrl =
    '${CloudflareConfig.baseUrl}/api/v1/admin/content/lessons/lesson_1';

void main() {
  late List<http.Request> requests;
  late http.Response Function(http.Request) respond;
  late LessonRemoteDataSourceImpl ds;

  setUp(() {
    requests = [];
    respond = (_) => http.Response(
      jsonEncode({
        'ok': true,
        'item': {'id': 'lesson_1'},
      }),
      200,
    );
    final client = MockClient((request) async {
      requests.add(request);
      return respond(request);
    });
    ds = LessonRemoteDataSourceImpl(
      adminClient: AdminContentClient(
        client,
        authHeaders: () async => {'Authorization': 'Bearer jwt-admin'},
      ),
    );
  });

  for (final entry in {
    'createLesson': (LessonRemoteDataSourceImpl d) => d.createLesson(_lesson),
    'updateLesson': (LessonRemoteDataSourceImpl d) => d.updateLesson(_lesson),
  }.entries) {
    test('${entry.key} PUTs the lesson to the Worker with the JWT', () async {
      await entry.value(ds);

      final request = requests.single;
      expect(request.method, 'PUT');
      expect(request.url.toString(), _lessonUrl);
      expect(request.headers['Authorization'], 'Bearer jwt-admin');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body.containsKey('id'), isFalse);
      expect(body['categoryId'], 'cat/1');
      expect(body['titleLatin'], 'O');
      // Same stored shape as the Appwrite era: blocks as a JSON string.
      expect(body['blocks'], '[]');
      expect(body.values, isNot(contains(null)));
    });
  }

  test('deleteLesson sends DELETE to the Worker', () async {
    await ds.deleteLesson('lesson_1');

    expect(requests.single.method, 'DELETE');
    expect(requests.single.url.toString(), _lessonUrl);
    expect(requests.single.headers['Authorization'], 'Bearer jwt-admin');
  });

  test('a Worker error surfaces as ServerException with its status', () async {
    respond = (_) => http.Response(
      jsonEncode({'ok': false, 'message': 'Admin access required'}),
      403,
    );

    await expectLater(
      ds.createLesson(_lesson),
      throwsA(
        isA<ServerException>()
            .having((e) => e.code, 'code', 403)
            .having((e) => e.message, 'message', contains('Admin access')),
      ),
    );
  });

  test('without an admin client writes fail instead of no-oping', () async {
    await expectLater(
      LessonRemoteDataSourceImpl().deleteLesson('lesson_1'),
      throwsA(isA<ServerException>()),
    );
    expect(requests, isEmpty);
  });
}
