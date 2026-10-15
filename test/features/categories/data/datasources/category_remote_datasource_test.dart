import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/error/exceptions.dart';
import 'package:itun/features/categories/data/datasources/category_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';

class _MockTablesDB extends Mock implements TablesDB {}

void main() {
  late _MockTablesDB tablesDB;
  late List<Uri> requests;

  setUp(() {
    tablesDB = _MockTablesDB();
    requests = [];
  });

  CategoryRemoteDataSourceImpl datasource(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    return CategoryRemoteDataSourceImpl(
      tablesDB,
      httpClient: MockClient((request) {
        requests.add(request.url);
        return handler(request);
      }),
    );
  }

  group('getCategories', () {
    test('reads the Worker list and never Appwrite', () async {
      final ds = datasource(
        (_) async => http.Response(
          jsonEncode({
            'ok': true,
            'categories': [
              {'id': 'cat_1', 'titleLatin': 'Alphabets', 'order': 1},
            ],
          }),
          200,
        ),
      );

      final categories = await ds.getCategories();

      expect(requests.single.path, '/api/v1/categories');
      expect(categories.single.id, 'cat_1');
      expect(categories.single.titleLatin, 'Alphabets');
      verifyZeroInteractions(tablesDB);
    });

    test('an empty Worker list is a valid empty result', () async {
      final ds = datasource(
        (_) async =>
            http.Response(jsonEncode({'ok': true, 'categories': []}), 200),
      );

      expect(await ds.getCategories(), isEmpty);
      verifyZeroInteractions(tablesDB);
    });

    test('a Worker error surfaces as ServerException', () async {
      final ds = datasource((_) async => http.Response('down', 503));

      await expectLater(
        ds.getCategories(),
        throwsA(isA<ServerException>().having((e) => e.code, 'code', 503)),
      );
      verifyZeroInteractions(tablesDB);
    });
  });

  group('getCategoryById', () {
    test('reads /api/v1/categories/:id from the Worker', () async {
      final ds = datasource(
        (_) async => http.Response(
          jsonEncode({
            'ok': true,
            'category': {'id': 'cat 1', 'unlockMode': 'paid_only'},
          }),
          200,
        ),
      );

      final category = await ds.getCategoryById('cat 1');

      expect(requests.single.path, '/api/v1/categories/cat%201');
      expect(category.id, 'cat 1');
      verifyZeroInteractions(tablesDB);
    });

    test('a 404 surfaces as ServerException without Appwrite', () async {
      final ds = datasource((_) async => http.Response('{"ok":false}', 404));

      await expectLater(
        ds.getCategoryById('missing'),
        throwsA(isA<ServerException>().having((e) => e.code, 'code', 404)),
      );
      verifyZeroInteractions(tablesDB);
    });
  });
}
