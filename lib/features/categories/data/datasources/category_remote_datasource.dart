// ignore_for_file: deprecated_member_use
import 'package:appwrite/appwrite.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/error/exceptions.dart';
import '../models/category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<CategoryModel> getCategoryById(String id);
  Future<void> createCategory(CategoryModel category);
  Future<void> updateCategory(CategoryModel category);
  Future<void> deleteCategory(String id);
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final Databases databases;

  CategoryRemoteDataSourceImpl(this.databases);

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final result = await databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'categories',
        queries: [Query.orderAsc('order'), Query.limit(500)],
      );
      return result.documents
          .map((doc) => CategoryModel.fromJson(doc.data, doc.$id))
          .toList();
    } on AppwriteException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to load categories', code: e.code);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<CategoryModel> getCategoryById(String id) async {
    try {
      final doc = await databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'categories',
        documentId: id,
      );
      return CategoryModel.fromJson(doc.data, doc.$id);
    } on AppwriteException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to get category', code: e.code);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> createCategory(CategoryModel category) async {
    try {
      final data = category.toJson()..remove('id');
      data.removeWhere((key, value) => value == null);
      await databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'categories',
        documentId: category.id,
        data: data,
      );
    } on AppwriteException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to create category', code: e.code);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateCategory(CategoryModel category) async {
    try {
      final data = category.toJson()..remove('id');
      data.removeWhere((key, value) => value == null);
      await databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'categories',
        documentId: category.id,
        data: data,
      );
    } on AppwriteException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to update category', code: e.code);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await databases.deleteDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'categories',
        documentId: id,
      );
    } on AppwriteException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to delete category', code: e.code);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
