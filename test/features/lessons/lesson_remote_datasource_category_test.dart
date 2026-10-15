import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/features/lessons/data/datasources/lesson_remote_datasource.dart';
import 'package:itun/features/lessons/data/models/lesson_model.dart';
import 'package:mocktail/mocktail.dart';

class _MockDatabases extends Mock implements TablesDB {}

class _FakeRow extends Fake implements models.Row {}

const _lesson = LessonModel(
  id: 'lesson_1',
  categoryId: 'cat/1',
  titleOlChiki: 'ᱚ',
  titleLatin: 'O',
  order: 1,
  blocks: [],
);

void main() {
  late _MockDatabases db;
  late List<Object?> capturedPermissions;

  setUp(() {
    db = _MockDatabases();
    capturedPermissions = [];
    when(
      () => db.createRow(
        databaseId: any(named: 'databaseId'),
        tableId: any(named: 'tableId'),
        rowId: any(named: 'rowId'),
        data: any(named: 'data'),
        permissions: any(named: 'permissions'),
      ),
    ).thenAnswer((invocation) async {
      capturedPermissions.add(invocation.namedArguments[#permissions]);
      return _FakeRow();
    });
  });

  test('category premium lookup reads the Worker, never Appwrite', () async {
    final requests = <Uri>[];
    final client = MockClient((request) async {
      requests.add(request.url);
      return http.Response(
        jsonEncode({
          'ok': true,
          'category': {'id': 'cat/1', 'unlockMode': 'free'},
        }),
        200,
      );
    });
    final ds = LessonRemoteDataSourceImpl(db, edgeClient: client);

    await ds.createLesson(_lesson);

    expect(requests.single.path, '/api/v1/categories/cat%2F1');
    expect(capturedPermissions.single, isNotEmpty);
    verifyNever(
      () => db.getRow(
        databaseId: any(named: 'databaseId'),
        tableId: any(named: 'tableId'),
        rowId: any(named: 'rowId'),
      ),
    );
  });

  test('unresolved category (Worker error) fails closed', () async {
    final client = MockClient((_) async => http.Response('boom', 503));
    final ds = LessonRemoteDataSourceImpl(db, edgeClient: client);

    await ds.createLesson(_lesson);

    expect(capturedPermissions.single, isEmpty);
  });
}
