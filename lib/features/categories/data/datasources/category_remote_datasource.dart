// This collection stores categories for the Learn home tab only
// (Alphabets, Numbers, Vocabulary, Sentences, Greetings).
//
// Bakhed (rhymes/stories) categories are NOT stored here — they live as
// string fields directly on rhyme rows in the `rhymes` collection.
// See `RhymeModel.category` and `rhymeCategoriesProvider`.
//
// DO NOT add Bakhed-only categories to this collection. They will leak
// onto the Learn tab. The historical "Sohrai" leak was caused by this.
import 'package:appwrite/appwrite.dart';
import '../../../../core/api/appwrite_databases_pagination.dart';
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
  static const Duration _readTimeout = Duration(seconds: 6);
  static const Duration _writeTimeout = Duration(seconds: 15);

  final TablesDB tablesDB;

  CategoryRemoteDataSourceImpl(this.tablesDB);

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final rows = await AppwriteDatabasesPagination.listRows(
        tablesDB,
        databaseId: AppwriteConfig.databaseId,
        tableId: 'categories',
        queries: [Query.orderAsc('order'), Query.limit(500)],
      );
      return rows
          .map((row) => CategoryModel.fromJson(row.data, row.$id))
          .toList();
    } on AppwriteException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to load categories',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<CategoryModel> getCategoryById(String id) async {
    try {
      final row = await tablesDB
          .getRow(
            databaseId: AppwriteConfig.databaseId,
            tableId: 'categories',
            rowId: id,
          )
          .timeout(_readTimeout);
      return CategoryModel.fromJson(row.data, row.$id);
    } on AppwriteException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to get category',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> createCategory(CategoryModel category) async {
    try {
      final data = category.toJson()..remove('id');
      data.removeWhere((key, value) => value == null);
      await tablesDB
          .createRow(
            databaseId: AppwriteConfig.databaseId,
            tableId: 'categories',
            rowId: category.id,
            data: data,
            permissions: [Permission.read(Role.any())],
          )
          .timeout(_writeTimeout);
    } on AppwriteException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to create category',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateCategory(CategoryModel category) async {
    try {
      final data = category.toJson()..remove('id');
      data.removeWhere((key, value) => value == null);
      await tablesDB
          .updateRow(
            databaseId: AppwriteConfig.databaseId,
            tableId: 'categories',
            rowId: category.id,
            data: data,
          )
          .timeout(_writeTimeout);
    } on AppwriteException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to update category',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await tablesDB
          .deleteRow(
            databaseId: AppwriteConfig.databaseId,
            tableId: 'categories',
            rowId: id,
          )
          .timeout(_writeTimeout);
    } on AppwriteException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to delete category',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
