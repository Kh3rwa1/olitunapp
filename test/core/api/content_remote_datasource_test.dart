import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/api/admin_content_client.dart';
import 'package:itun/core/api/content_remote_datasource.dart';
import 'package:itun/core/api/edge_json_client.dart';
import 'package:itun/core/config/cloudflare_config.dart';

void main() {
  late List<Uri> requests;
  late List<http.Request> sent;

  setUp(() {
    requests = [];
    sent = [];
  });

  ContentRemoteDataSourceImpl datasource(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    final client = MockClient((request) {
      requests.add(request.url);
      sent.add(request);
      return handler(request);
    });
    return ContentRemoteDataSourceImpl(
      httpClient: client,
      adminClient: AdminContentClient(
        client,
        authHeaders: () async => {'Authorization': 'Bearer jwt-admin'},
      ),
    );
  }

  const adminBase = '${CloudflareConfig.baseUrl}/api/v1/admin/content';

  group('getPublicRow', () {
    test('reads one learner item from the Worker, never Appwrite', () async {
      final ds = datasource(
        (_) async => http.Response(
          jsonEncode({
            'ok': true,
            'item': {'id': 'w 1', 'wordLatin': 'johar'},
          }),
          200,
        ),
      );

      final row = await ds.getPublicRow(tableId: 'words', rowId: 'w 1');

      expect(requests.single.path, '/api/v1/content/word/w%201');
      expect(row.id, 'w 1');
      expect(row.data['wordLatin'], 'johar');
    });

    test('a missing item surfaces the Worker error', () async {
      final ds = datasource((_) async => http.Response('{}', 404));

      await expectLater(
        ds.getPublicRow(tableId: 'letters', rowId: 'x'),
        throwsA(isA<EdgeApiException>()),
      );
    });

    test('lessons have no public by-id route', () async {
      final ds = datasource((_) async => http.Response('{}', 200));

      await expectLater(
        ds.getPublicRow(tableId: 'lessons', rowId: 'l1'),
        throwsUnsupportedError,
      );
      expect(requests, isEmpty);
    });
  });

  group('listRows', () {
    test(
      'rhymes are listed from the Worker with the category filter',
      () async {
        final ds = datasource(
          (_) async => http.Response(
            jsonEncode({
              'ok': true,
              'rhymes': [
                {'id': 'r1', 'titleLatin': 'Sohrai'},
              ],
            }),
            200,
          ),
        );

        final rows = await ds.listRows(
          tableId: 'rhymes',
          categoryAttribute: 'categoryId',
          categoryId: 'Sohrai',
        );

        expect(requests.single.path, '/api/v1/rhymes');
        expect(requests.single.queryParameters['category'], 'Sohrai');
        expect(rows.single.id, 'r1');
        expect(rows.single.data['titleLatin'], 'Sohrai');
      },
    );

    test('an empty Worker list is a valid empty result', () async {
      final ds = datasource(
        (_) async => http.Response(jsonEncode({'ok': true, 'words': []}), 200),
      );

      expect(await ds.listRows(tableId: 'words'), isEmpty);
    });

    test('a Worker error is surfaced, not replaced by Appwrite', () async {
      final ds = datasource((_) async => http.Response('down', 500));

      await expectLater(
        ds.listRows(tableId: 'letters'),
        throwsA(isA<EdgeApiException>()),
      );
    });

    test('a table without a Worker route is rejected', () async {
      final ds = datasource((_) async => http.Response('{}', 200));

      await expectLater(
        ds.listRows(tableId: 'unknown_table'),
        throwsA(isA<UnsupportedError>()),
      );
      expect(requests, isEmpty);
    });
  });

  group('getCategory', () {
    test('reads /api/v1/categories/:id from the Worker', () async {
      final ds = datasource(
        (_) async => http.Response(
          jsonEncode({
            'ok': true,
            'category': {'id': 'cat_paid', 'unlockMode': 'paid_only'},
          }),
          200,
        ),
      );

      final category = await ds.getCategory(categoryId: 'cat_paid');

      expect(requests.single.path, '/api/v1/categories/cat_paid');
      expect(category['unlockMode'], 'paid_only');
    });

    test('a Worker error is surfaced without an Appwrite fallback', () async {
      final ds = datasource((_) async => http.Response('{"ok":false}', 404));

      await expectLater(
        ds.getCategory(categoryId: 'missing'),
        throwsA(
          isA<EdgeApiException>().having((e) => e.statusCode, 'status', 404),
        ),
      );
    });
  });

  group('admin rows (Worker admin routes, no Appwrite)', () {
    test('upsertRow PUTs the document with the admin JWT', () async {
      final ds = datasource(
        (_) async => http.Response(
          jsonEncode({
            'ok': true,
            'item': {'id': 'w1', 'wordLatin': 'johar', 'order': 2},
          }),
          200,
        ),
      );

      final row = await ds.upsertRow(
        tableId: 'words',
        rowId: 'w1',
        data: {'id': 'w1', 'wordLatin': 'johar', 'order': 2},
      );

      final request = sent.single;
      expect(request.method, 'PUT');
      expect(request.url.toString(), '$adminBase/words/w1');
      expect(request.headers['Authorization'], 'Bearer jwt-admin');
      expect(jsonDecode(request.body), {'wordLatin': 'johar', 'order': 2});
      expect(row.id, 'w1');
      expect(row.data['order'], 2);
    });

    test('getRow reads the full admin body', () async {
      final ds = datasource(
        (_) async => http.Response(
          jsonEncode({
            'ok': true,
            'item': {'id': 'l1', 'isActive': false},
          }),
          200,
        ),
      );

      final row = await ds.getRow(tableId: 'lessons', rowId: 'l1');

      expect(sent.single.method, 'GET');
      expect(sent.single.url.toString(), '$adminBase/lessons/l1');
      expect(sent.single.headers['Authorization'], 'Bearer jwt-admin');
      expect(row.data['isActive'], isFalse);
    });

    test('deleteRow sends DELETE with the admin JWT', () async {
      final ds = datasource(
        (_) async => http.Response(jsonEncode({'ok': true}), 200),
      );

      await ds.deleteRow(tableId: 'letters', rowId: 'l_la');

      expect(sent.single.method, 'DELETE');
      expect(sent.single.url.toString(), '$adminBase/letters/l_la');
      expect(sent.single.headers['Authorization'], 'Bearer jwt-admin');
    });

    test('a Worker write error is surfaced with its status', () async {
      final ds = datasource(
        (_) async => http.Response(
          jsonEncode({'ok': false, 'message': 'Admin access required'}),
          403,
        ),
      );

      await expectLater(
        ds.upsertRow(tableId: 'rhymes', rowId: 'r1', data: {}),
        throwsA(
          isA<EdgeApiException>()
              .having((e) => e.statusCode, 'status', 403)
              .having((e) => e.message, 'message', contains('Admin access')),
        ),
      );
    });

    test('an unsupported table is rejected before any request', () async {
      final ds = datasource((_) async => http.Response('{}', 200));

      expect(
        () => ds.deleteRow(tableId: 'users', rowId: 'x'),
        throwsArgumentError,
      );
      expect(sent, isEmpty);
    });
  });
}
