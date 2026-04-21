import 'package:appwrite/appwrite.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/error/exceptions.dart';
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
  final Databases databases;

  LessonRemoteDataSourceImpl(this.databases);

  @override
  Future<List<LessonModel>> getLessons() async {
    try {
      final result = await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'lessons',
        queries: [Query.orderAsc('order'), Query.limit(500)],
      );
      return result.documents
          .map((doc) => LessonModel.fromJson(doc.data, doc.$id))
          .toList();
    } on AppwriteException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to load lessons', code: e.code);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<LessonModel>> getLessonsByCategory(String categoryId) async {
    try {
      final result = await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'lessons',
        queries: [
          Query.equal('categoryId', categoryId),
          Query.orderAsc('order'),
          Query.limit(500),
        ],
      );
      return result.documents
          .map((doc) => LessonModel.fromJson(doc.data, doc.$id))
          .toList();
    } on AppwriteException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to load lessons by category', code: e.code);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<LessonModel> getLessonById(String id) async {
    try {
      final doc = await databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'lessons',
        documentId: id,
      );
      return LessonModel.fromJson(doc.data, doc.$id);
    } on AppwriteException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to get lesson', code: e.code);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> createLesson(LessonModel lesson) async {
    try {
      final data = lesson.toJson()..remove('id');
      // Appwrite expects blocks as a JSON string in some cases, or we can use relationships.
      // Based on current implementation, it seems we use JSON string for blocks.
      data['blocks'] = data['blocks'].toString(); 
      data.removeWhere((key, value) => value == null);
      
      await databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'lessons',
        documentId: lesson.id,
        data: data,
      );
    } on AppwriteException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to create lesson', code: e.code);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateLesson(LessonModel lesson) async {
    try {
      final data = lesson.toJson()..remove('id');
      data['blocks'] = data['blocks'].toString();
      data.removeWhere((key, value) => value == null);
      
      await databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'lessons',
        documentId: lesson.id,
        data: data,
      );
    } on AppwriteException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to update lesson', code: e.code);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteLesson(String id) async {
    try {
      await databases.deleteDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'lessons',
        documentId: id,
      );
    } on AppwriteException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to delete lesson', code: e.code);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
