import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/api/appwrite_functions_service.dart';
import 'package:itun/core/error/exceptions.dart';
import 'package:itun/features/lessons/data/datasources/lesson_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';

class _MockDatabases extends Mock implements Databases {}

class _MockFunctionsService extends Mock implements AppwriteFunctionsService {}

FunctionExecutionResult _execution(Map<String, dynamic> body) {
  return FunctionExecutionResult(
    status: 'completed',
    statusCode: 200,
    responseBody: jsonEncode(body),
  );
}

Map<String, dynamic> _metadata(
  String id, {
  String categoryId = 'cat_secure',
  bool isLocked = false,
  int order = 1,
}) {
  return {
    'id': id,
    'categoryId': categoryId,
    'titleOlChiki': 'ᱯᱟᱹᱴ',
    'titleLatin': 'Secure lesson',
    'level': 'beginner',
    'description': 'Metadata only',
    'order': order,
    'estimatedMinutes': 5,
    'isActive': true,
    'isPreview': false,
    'isLocked': isLocked,
    'accessReason': isLocked ? 'purchase_required' : 'entitled',
  };
}

void main() {
  late _MockDatabases mockDatabases;
  late _MockFunctionsService mockFunctions;
  late LessonRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDatabases = _MockDatabases();
    mockFunctions = _MockFunctionsService();
    dataSource = LessonRemoteDataSourceImpl(
      mockDatabases,
      functionsService: mockFunctions,
    );
  });

  test('getLessons uses metadata-only authorization function response', () async {
    when(
      () => mockFunctions.execute(
        'getAuthorizedLesson',
        body: {'action': 'list_lessons', 'limit': 100},
        usePost: true,
      ),
    ).thenAnswer(
      (_) async => _execution({
        'ok': true,
        'lessons': [
          _metadata('lesson_free'),
          _metadata('lesson_paid', isLocked: true, order: 2),
        ],
        'hasMore': false,
        'nextCursor': null,
      }),
    );

    final lessons = await dataSource.getLessons();

    expect(lessons.map((lesson) => lesson.id), [
      'lesson_free',
      'lesson_paid',
    ]);
    expect(lessons.first.isLocked, isFalse);
    expect(lessons.last.isLocked, isTrue);
    expect(lessons.every((lesson) => lesson.blocks.isEmpty), isTrue);
    verifyNoMoreInteractions(mockDatabases);
  });

  test('getLessons follows bounded server cursors', () async {
    when(
      () => mockFunctions.execute(
        'getAuthorizedLesson',
        body: {'action': 'list_lessons', 'limit': 100},
        usePost: true,
      ),
    ).thenAnswer(
      (_) async => _execution({
        'ok': true,
        'lessons': [_metadata('lesson_1')],
        'hasMore': true,
        'nextCursor': 'lesson_1',
      }),
    );
    when(
      () => mockFunctions.execute(
        'getAuthorizedLesson',
        body: {
          'action': 'list_lessons',
          'limit': 100,
          'cursor': 'lesson_1',
        },
        usePost: true,
      ),
    ).thenAnswer(
      (_) async => _execution({
        'ok': true,
        'lessons': [_metadata('lesson_2', order: 2)],
        'hasMore': false,
        'nextCursor': null,
      }),
    );

    final lessons = await dataSource.getLessons();

    expect(lessons.map((lesson) => lesson.id), ['lesson_1', 'lesson_2']);
    verifyInOrder([
      () => mockFunctions.execute(
        'getAuthorizedLesson',
        body: {'action': 'list_lessons', 'limit': 100},
        usePost: true,
      ),
      () => mockFunctions.execute(
        'getAuthorizedLesson',
        body: {
          'action': 'list_lessons',
          'limit': 100,
          'cursor': 'lesson_1',
        },
        usePost: true,
      ),
    ]);
  });

  test('getLessonsByCategory sends only the category filter', () async {
    when(
      () => mockFunctions.execute(
        'getAuthorizedLesson',
        body: {
          'action': 'list_lessons',
          'limit': 100,
          'categoryId': 'cat_secure',
        },
        usePost: true,
      ),
    ).thenAnswer(
      (_) async => _execution({
        'ok': true,
        'lessons': [_metadata('category_lesson')],
        'hasMore': false,
        'nextCursor': null,
      }),
    );

    final lessons = await dataSource.getLessonsByCategory('cat_secure');

    expect(lessons.single.id, 'category_lesson');
    verifyNoMoreInteractions(mockDatabases);
  });

  test('malformed pagination fails closed instead of looping', () async {
    when(
      () => mockFunctions.execute(
        'getAuthorizedLesson',
        body: {'action': 'list_lessons', 'limit': 100},
        usePost: true,
      ),
    ).thenAnswer(
      (_) async => _execution({
        'ok': true,
        'lessons': <Map<String, dynamic>>[],
        'hasMore': true,
        'nextCursor': '',
      }),
    );

    expect(
      () => dataSource.getLessons(),
      throwsA(isA<ServerException>().having((error) => error.code, 'code', 502)),
    );
  });

  test('list methods never fall back to direct database reads', () async {
    final unavailable = LessonRemoteDataSourceImpl(mockDatabases);

    expect(
      () => unavailable.getLessons(),
      throwsA(isA<ServerException>().having((error) => error.code, 'code', 503)),
    );
    expect(
      () => unavailable.getLessonsByCategory('cat_secure'),
      throwsA(isA<ServerException>().having((error) => error.code, 'code', 503)),
    );
    verifyNoMoreInteractions(mockDatabases);
  });
}
