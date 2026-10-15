import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/api/admin_content_client.dart';
import 'package:itun/core/config/cloudflare_config.dart';
import 'package:itun/core/error/exceptions.dart';
import 'package:itun/features/categories/data/datasources/category_remote_datasource.dart';
import 'package:itun/features/categories/data/models/category_model.dart';

void main() {
  late List<Uri> requests;
  late List<http.Request> sent;

  setUp(() {
    requests = [];
    sent = [];
  });

  CategoryRemoteDataSourceImpl datasource(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    final client = MockClient((request) {
      requests.add(request.url);
      sent.add(request);
      return handler(request);
    });
    return CategoryRemoteDataSourceImpl(
      httpClient: client,
      adminClient: AdminContentClient(
        client,
        authHeaders: () async => {'Authorization': 'Bearer jwt-admin'},
      ),
    );
  }

  const categoryUrl =
      '${CloudflareConfig.baseUrl}/api/v1/admin/content/categories/cat_1';

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
    });

    test('an empty Worker list is a valid empty result', () async {
      final ds = datasource(
        (_) async =>
            http.Response(jsonEncode({'ok': true, 'categories': []}), 200),
      );

      expect(await ds.getCategories(), isEmpty);
    });

    test('a Worker error surfaces as ServerException', () async {
      final ds = datasource((_) async => http.Response('down', 503));

      await expectLater(
        ds.getCategories(),
        throwsA(isA<ServerException>().having((e) => e.code, 'code', 503)),
      );
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
    });

    test('a 404 surfaces as ServerException without Appwrite', () async {
      final ds = datasource((_) async => http.Response('{"ok":false}', 404));

      await expectLater(
        ds.getCategoryById('missing'),
        throwsA(isA<ServerException>().having((e) => e.code, 'code', 404)),
      );
    });
  });

  group('admin writes', () {
    final category = CategoryModel.fromJson({
      'titleLatin': 'Alphabets',
      'titleOlChiki': 'ᱚᱞ ᱪᱤᱠᱤ',
      'unlockMode': 'paid_only',
      'isActive': true,
    }, 'cat_1');

    for (final entry in {
      'createCategory': (CategoryRemoteDataSourceImpl d) =>
          d.createCategory(category),
      'updateCategory': (CategoryRemoteDataSourceImpl d) =>
          d.updateCategory(category),
    }.entries) {
      test('${entry.key} PUTs to the Worker with the admin JWT', () async {
        final ds = datasource(
          (_) async => http.Response(
            jsonEncode({
              'ok': true,
              'item': {'id': 'cat_1'},
            }),
            200,
          ),
        );

        await entry.value(ds);

        final request = sent.single;
        expect(request.method, 'PUT');
        expect(request.url.toString(), categoryUrl);
        expect(request.headers['Authorization'], 'Bearer jwt-admin');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.containsKey('id'), isFalse);
        expect(body['titleLatin'], 'Alphabets');
        expect(body['unlockMode'], 'paid_only');
        expect(body.values, isNot(contains(null)));
      });
    }

    test('deleteCategory sends DELETE to the Worker', () async {
      final ds = datasource(
        (_) async => http.Response(jsonEncode({'ok': true}), 200),
      );

      await ds.deleteCategory('cat_1');

      expect(sent.single.method, 'DELETE');
      expect(sent.single.url.toString(), categoryUrl);
      expect(sent.single.headers['Authorization'], 'Bearer jwt-admin');
    });

    test('a Worker write error surfaces as ServerException', () async {
      final ds = datasource(
        (_) async => http.Response(
          jsonEncode({'ok': false, 'message': 'Failed to save content'}),
          500,
        ),
      );

      await expectLater(
        ds.createCategory(category),
        throwsA(isA<ServerException>().having((e) => e.code, 'code', 500)),
      );
    });
  });
}
