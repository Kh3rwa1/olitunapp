import 'dart:convert';
// ignore_for_file: deprecated_member_use
import 'package:appwrite/appwrite.dart';
import '../../../../core/api/appwrite_databases_pagination.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../shared/security/premium_content_policy.dart';
import '../models/lesson_model.dart';

abstract class LessonRemoteDataSource {
  Future<List<LessonModel>> getLessons();
  Future<List<LessonModel>> getLessonsByCategory(String categoryId);
  Future<LessonModel> getLessonById(String id);
  Future<void> createLesson(LessonModel lesson);
  Future<void> updateLesson(LessonModel lesson);
  Future<void> deleteLesson(String id);
}

class LessonRemoteDataSourceImpl implements LessonRemoteDataSource {
  static const Duration _readTimeout = Duration(seconds: 6);
  static const Duration _writeTimeout = Duration(seconds: 15);

  final Databases databases;

  LessonRemoteDataSourceImpl(this.databases);

  @override
  Future<List<LessonModel>> getLessons() async {
    try {
      final documents = await AppwriteDatabasesPagination.listDocuments(
        databases,
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'lessons',
        queries: [Query.orderAsc('order'), Query.limit(500)],
      );
      return documents
          .map((doc) => LessonModel.fromJson(doc.data, doc.$id))
          .toList();
    } on AppwriteException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to load lessons',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<LessonModel>> getLessonsByCategory(String categoryId) async {
    try {
      final documents = await AppwriteDatabasesPagination.listDocuments(
        databases,
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'lessons',
        queries: [
          Query.equal('categoryId', categoryId),
          Query.orderAsc('order'),
          Query.limit(500),
        ],
      );
      return documents
          .map((doc) => LessonModel.fromJson(doc.data, doc.$id))
          .toList();
    } on AppwriteException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to load lessons by category',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<LessonModel> getLessonById(String id) async {
    try {
      final doc = await databases
          .getDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: 'lessons',
            documentId: id,
          )
          .timeout(_readTimeout);
      return LessonModel.fromJson(doc.data, doc.$id);
    } on AppwriteException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to get lesson',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
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
      final category = await databases
          .getDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: 'categories',
            documentId: lesson.categoryId,
          )
          .timeout(_readTimeout);
      return PremiumContentPolicy.forContentItem(
        isPremium: lesson.data?['isPremium'] == true,
        categoryUnlockMode: category.data['unlockMode'] as String?,
        lessonOrder: lesson.order,
        previewLessonCount: category.data['previewLessonCount'] as int? ?? 0,
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

      await databases
          .createDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: 'lessons',
            documentId: lesson.id,
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

      await databases
          .updateDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: 'lessons',
            documentId: lesson.id,
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
      await databases
          .deleteDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: 'lessons',
            documentId: id,
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
