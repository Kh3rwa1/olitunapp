import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:appwrite/appwrite.dart';
import 'package:itun/core/api/appwrite_functions_service.dart';
import 'package:itun/core/error/exceptions.dart';
import 'package:itun/features/lessons/data/datasources/lesson_remote_datasource.dart';

class _MockDatabases extends Mock implements Databases {}

class _MockFunctionsService extends Mock implements AppwriteFunctionsService {}

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

  group('LessonRemoteDataSource.getAuthorizedLesson', () {
    test('returns complete lesson model when authorized', () async {
      final payload = {
        'ok': true,
        'locked': false,
        'accessReason': 'entitled',
        'lesson': {
          'id': 'lesson_paid_1',
          'categoryId': 'cat_advanced',
          'titleOlChiki': 'ᱟᱹᱲᱟᱹ ᱜᱟᱵᱟᱱ',
          'titleLatin': 'Advanced Vocab',
          'level': 'advanced',
          'order': 3,
          'estimatedMinutes': 10,
          'isActive': true,
          'isPreview': false,
          'isLocked': false,
          'blocks': [
            {'type': 'text', 'textLatin': 'Lesson block 1'},
          ],
        },
      };

      when(
        () => mockFunctions.execute(
          'getAuthorizedLesson',
          body: {'lessonId': 'lesson_paid_1'},
          usePost: true,
        ),
      ).thenAnswer(
        (_) async => FunctionExecutionResult(
          status: 'completed',
          statusCode: 200,
          responseBody: jsonEncode(payload),
        ),
      );

      final result = await dataSource.getAuthorizedLesson('lesson_paid_1');

      expect(result.id, 'lesson_paid_1');
      expect(result.categoryId, 'cat_advanced');
      expect(result.isLocked, isFalse);
      expect(result.blocks.length, 1);
      expect(result.blocks.first.textLatin, 'Lesson block 1');
    });

    test(
      'returns locked lesson model with empty blocks when unauthorized',
      () async {
        final payload = {
          'ok': true,
          'locked': true,
          'reason': 'purchase_required',
          'lesson': {
            'id': 'lesson_paid_2',
            'categoryId': 'cat_advanced',
            'titleOlChiki': 'ᱚ',
            'titleLatin': 'Locked Lesson',
            'order': 5,
            'isLocked': true,
            'blocks': [],
          },
        };

        when(
          () => mockFunctions.execute(
            'getAuthorizedLesson',
            body: {'lessonId': 'lesson_paid_2'},
            usePost: true,
          ),
        ).thenAnswer(
          (_) async => FunctionExecutionResult(
            status: 'completed',
            statusCode: 200,
            responseBody: jsonEncode(payload),
          ),
        );

        final result = await dataSource.getAuthorizedLesson('lesson_paid_2');

        expect(result.id, 'lesson_paid_2');
        expect(result.isLocked, isTrue);
        expect(result.blocks, isEmpty);
      },
    );

    test('throws ServerException with code 403 on access denial', () async {
      when(
        () => mockFunctions.execute(
          'getAuthorizedLesson',
          body: {'lessonId': 'lesson_forbidden'},
          usePost: true,
        ),
      ).thenAnswer(
        (_) async => const FunctionExecutionResult(
          status: 'completed',
          statusCode: 403,
          responseBody: '{"ok":false,"error":"access_denied"}',
        ),
      );

      expect(
        () => dataSource.getAuthorizedLesson('lesson_forbidden'),
        throwsA(isA<ServerException>().having((e) => e.code, 'code', 403)),
      );
    });

    test('throws ServerException with code 404 on lesson not found', () async {
      when(
        () => mockFunctions.execute(
          'getAuthorizedLesson',
          body: {'lessonId': 'lesson_missing'},
          usePost: true,
        ),
      ).thenAnswer(
        (_) async => const FunctionExecutionResult(
          status: 'completed',
          statusCode: 404,
          responseBody: '{"ok":false,"error":"lesson_not_found"}',
        ),
      );

      expect(
        () => dataSource.getAuthorizedLesson('lesson_missing'),
        throwsA(isA<ServerException>().having((e) => e.code, 'code', 404)),
      );
    });

    test(
      'throws ServerException with code 503 when functionsService is null without bypassing',
      () async {
        final unauthDataSource = LessonRemoteDataSourceImpl(mockDatabases);

        expect(
          () => unauthDataSource.getAuthorizedLesson('lesson_any'),
          throwsA(isA<ServerException>().having((e) => e.code, 'code', 503)),
        );
        expect(
          () => unauthDataSource.getLessonById('lesson_any'),
          throwsA(isA<ServerException>().having((e) => e.code, 'code', 503)),
        );
      },
    );
  });
}
