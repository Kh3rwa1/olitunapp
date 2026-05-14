import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/cache_service.dart';
import '../models/category_model.dart';

abstract class CategoryLocalDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<void> cacheCategories(List<CategoryModel> categories);
  Future<void> clearCache();
}

class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  static const String _cacheKey = 'cached_categories';

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final cached = await CacheService.getList<CategoryModel>(
        _cacheKey,
        CategoryModel.fromJson,
      );
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      throw CacheException(message: 'No cached categories found');
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> cacheCategories(List<CategoryModel> categories) async {
    try {
      final data = categories.map((e) => e.toJson()).toList();
      await CacheService.set(_cacheKey, data);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> clearCache() async {
    await CacheService.delete(_cacheKey);
  }
}
