import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import '../../../../core/api/appwrite_functions_service.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../shared/security/premium_content_policy.dart';
import '../models/lesson_model.dart';

abstract class LessonRemoteDataSource {
  Future<List<LessonModel>> getLessons();
  Future<List<LessonModel>> getLessonsByCategory(String categoryId);
  Future<LessonModel> getLessonById(String id);
  Future<LessonModel> getAuthorizedLesson(String id);
  Future<void> createLesson(LessonModel lesson);
  Future<void> updateLesson(LessonModel lesson);
  Future<void> deleteLesson(String id);
}

class LessonRemoteDataSourceImpl implements LessonRemoteDataSource {
  static const Duration _readTimeout = Duration(seconds: 6);
  static const Duration _writeTimeout = Duration(seconds: 15);
  static const int _authorizedListPageSize = 100;
  static const int _maxAuthorizedListPages = 100;

  final TablesDB tablesDB;
  final AppwriteFunctionsService? functionsService;

  LessonRemoteDataSourceImpl(this.tablesDB, {this.functionsService});

  Future<List<LessonModel>> _getAuthorizedLessonList({
    String? categoryId,
  }) async {
    if (functionsService == null) {
      throw ServerException(
        message: 'Authorization service unavailable',
        code: 503,
      );
    }

    try {
      final lessons = <LessonModel>[];
      final seenLessonIds = <String>{};
      final seenCursors = <String>{};
      String? cursor;

      for (var page = 0; page < _maxAuthorizedListPages; page++) {
        final body = <String, dynamic>{
          'action': 'list_lessons',
          'limit': _authorizedListPageSize,
          'categoryId': ?categoryId,
          'cursor': ?cursor,
        };
        final result = await functionsService!.execute(
          'getAuthorizedLesson',
          body: body,
          usePost: true,
        );
        final data = result.bodyJson;
        if (!result.isCompleted ||
            result.statusCode != 200 ||
            data == null ||
            data['ok'] != true ||
            data['lessons'] is! List) {
          throw ServerException(
            message:
                data?['message'] as String? ??
                'Failed to load authorized lesson metadata',
            code: result.statusCode,
          );
        }

        for (final rawLesson in data['lessons'] as List) {
          if (rawLesson is! Map) {
            throw ServerException(
              message: 'Malformed authorized lesson metadata',
              code: 502,
            );
          }
          final lessonMap = Map<String, dynamic>.from(rawLesson);
          final lessonId = lessonMap['id'];
          if (lessonId is! String ||
              lessonId.isEmpty ||
              !seenLessonIds.add(lessonId)) {
            throw ServerException(
              message: 'Malformed or duplicate lesson metadata',
              code: 502,
            );
          }
          lessons.add(LessonModel.fromJson(lessonMap, lessonId));
        }

        if (data['hasMore'] != true) return lessons;
        final nextCursor = data['nextCursor'];
        if (nextCursor is! String ||
            nextCursor.isEmpty ||
            !seenCursors.add(nextCursor)) {
          throw ServerException(
            message: 'Malformed lesson-list pagination cursor',
            code: 502,
          );
        }
        cursor = nextCursor;
      }

      throw ServerException(
        message: 'Lesson list exceeded the safe pagination bound',
        code: 502,
      );
    } on ServerException {
      rethrow;
    } catch (error) {
      throw ServerException(
        message: 'Failed to load authorized lesson metadata: $error',
      );
    }
  }

  @override
  Future<List<LessonModel>> getLessons() => _getAuthorizedLessonList();

  @override
  Future<List<LessonModel>> getLessonsByCategory(String categoryId) =>
      _getAuthorizedLessonList(categoryId: categoryId);

  @override
  Future<LessonModel> getAuthorizedLesson(String id) async {
    if (functionsService == null) {
      throw ServerException(
        message: 'Authorization service unavailable',
        code: 503,
      );
    }
    try {
      final result = await functionsService!.execute(
        'getAuthorizedLesson',
        body: {'lessonId': id},
        usePost: true,
      );
      if (result.isCompleted &&
          result.statusCode == 200 &&
          result.bodyJson != null) {
        final data = result.bodyJson!;
        if (data['ok'] == true && data['lesson'] is Map) {
          final lessonMap = Map<String, dynamic>.from(data['lesson'] as Map);
          return LessonModel.fromJson(lessonMap, lessonMap['id'] as String?);
        }
      }
      if (result.statusCode == 404) {
        throw ServerException(message: 'Lesson not found', code: 404);
      }
      if (result.statusCode == 401 || result.statusCode == 403) {
        throw ServerException(message: 'Access denied to lesson', code: 403);
      }
      throw ServerException(
        message:
            result.bodyJson?['message'] as String? ??
            'Failed to retrieve authorized lesson',
        code: result.statusCode,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Failed to retrieve authorized lesson: $e',
      );
    }
  }

  @override
  Future<LessonModel> getLessonById(String id) async {
    return getAuthorizedLesson(id);
  }

  Future<PublicationDecision> _publicationDecisionFor(
    LessonModel lesson,
  ) async {
    if (lesson.categoryId.trim().isEmpty) {
      return PremiumContentPolicy.forContentItem(
        isPremium: lesson.data?['isPremium'] == true,
        categoryResolved: false,
      );
    }

    try {
      final category = await tablesDB
          .getRow(
            databaseId: AppwriteConfig.databaseId,
            tableId: 'categories',
            rowId: lesson.categoryId,
          )
          .timeout(_readTimeout);
      return PremiumContentPolicy.forContentItem(
        isPremium: lesson.data?['isPremium'] == true,
        categoryUnlockMode: category.data['unlockMode'] as String?,
        lessonOrder: lesson.order,
        previewLessonCount: category.data['previewLessonCount'] as int? ?? 0,
        isPreview: lesson.isPreview,
      );
    } catch (_) {
      return PremiumContentPolicy.forContentItem(
        isPremium: lesson.data?['isPremium'] == true,
        categoryResolved: false,
      );
    }
  }

  List<String> _readPermissions(PublicationDecision decision) =>
      decision.allowAnonymousRead ? [Permission.read(Role.any())] : const [];

  @override
  Future<void> createLesson(LessonModel lesson) async {
    try {
      final data = lesson.toJson()..remove('id');
      data['blocks'] = jsonEncode(data['blocks']);
      data.removeWhere((key, value) => value == null);
      final decision = await _publicationDecisionFor(lesson);

      await tablesDB
          .createRow(
            databaseId: AppwriteConfig.databaseId,
            tableId: 'lessons',
            rowId: lesson.id,
            data: data,
            permissions: _readPermissions(decision),
          )
          .timeout(_writeTimeout);
    } on AppwriteException catch (e) {
      if (e.code == 409) {
        return updateLesson(lesson);
      }
      throw ServerException(
        message: e.message ?? 'Failed to create lesson',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateLesson(LessonModel lesson) async {
    try {
      final data = lesson.toJson()..remove('id');
      data['blocks'] = jsonEncode(data['blocks']);
      data.removeWhere((key, value) => value == null);
      final decision = await _publicationDecisionFor(lesson);

      await tablesDB
          .updateRow(
            databaseId: AppwriteConfig.databaseId,
            tableId: 'lessons',
            rowId: lesson.id,
            data: data,
            permissions: _readPermissions(decision),
          )
          .timeout(_writeTimeout);
    } on AppwriteException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to update lesson',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteLesson(String id) async {
    try {
      await tablesDB
          .deleteRow(
            databaseId: AppwriteConfig.databaseId,
            tableId: 'lessons',
            rowId: id,
          )
          .timeout(_writeTimeout);
    } on AppwriteException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to delete lesson',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
