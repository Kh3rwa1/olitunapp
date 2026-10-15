import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/api/content_remote_datasource.dart';
import 'package:itun/core/api/edge_json_client.dart';
import 'package:mocktail/mocktail.dart';

class _MockTablesDB extends Mock implements TablesDB {}

void main() {
  late _MockTablesDB tablesDB;
  late List<Uri> requests;

  setUp(() {
    tablesDB = _MockTablesDB();
    requests = [];
  });

  ContentRemoteDataSourceImpl datasource(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    return ContentRemoteDataSourceImpl(
      tablesDB: tablesDB,
      httpClient: MockClient((request) {
        requests.add(request.url);
        return handler(request);
      }),
    );
  }

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
      verifyZeroInteractions(tablesDB);
    });

    test('a missing item surfaces the Worker error', () async {
      final ds = datasource((_) async => http.Response('{}', 404));

      await expectLater(
        ds.getPublicRow(tableId: 'letters', rowId: 'x'),
        throwsA(isA<EdgeApiException>()),
      );
      verifyZeroInteractions(tablesDB);
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
        verifyZeroInteractions(tablesDB);
      },
    );

    test('an empty Worker list is a valid empty result', () async {
      final ds = datasource(
        (_) async => http.Response(jsonEncode({'ok': true, 'words': []}), 200),
      );

      expect(await ds.listRows(tableId: 'words'), isEmpty);
      verifyZeroInteractions(tablesDB);
    });

    test('a Worker error is surfaced, not replaced by Appwrite', () async {
      final ds = datasource((_) async => http.Response('down', 500));

      await expectLater(
        ds.listRows(tableId: 'letters'),
        throwsA(isA<EdgeApiException>()),
      );
      verifyZeroInteractions(tablesDB);
    });

    test('a table without a Worker route is rejected', () async {
      final ds = datasource((_) async => http.Response('{}', 200));

      await expectLater(
        ds.listRows(tableId: 'unknown_table'),
        throwsA(isA<UnsupportedError>()),
      );
      expect(requests, isEmpty);
      verifyZeroInteractions(tablesDB);
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
      verifyZeroInteractions(tablesDB);
    });

    test('a Worker error is surfaced without an Appwrite fallback', () async {
      final ds = datasource((_) async => http.Response('{"ok":false}', 404));

      await expectLater(
        ds.getCategory(categoryId: 'missing'),
        throwsA(
          isA<EdgeApiException>().having((e) => e.statusCode, 'status', 404),
        ),
      );
      verifyZeroInteractions(tablesDB);
    });
  });
}
