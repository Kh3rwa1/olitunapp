import 'dart:convert';
import 'package:hive/hive.dart';
import '../../../../core/error/exceptions.dart';
import '../models/category_model.dart';

abstract class CategoryLocalDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<void> cacheCategories(List<CategoryModel> categories);
  Future<void> clearCache();
}

class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  static const String _boxName = 'content_cache';
  static const String _cacheKey = 'cached_categories';

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final box = await Hive.openBox(_boxName);
      final jsonString = box.get(_cacheKey);
      if (jsonString != null) {
        final decoded = jsonDecode(jsonString) as List;
        return decoded
            .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw CacheException(message: 'No cached categories found');
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> cacheCategories(List<CategoryModel> categories) async {
    try {
      final box = await Hive.openBox(_boxName);
      final jsonString = jsonEncode(categories.map((e) => e.toJson()).toList());
      await box.put(_cacheKey, jsonString);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> clearCache() async {
    final box = await Hive.openBox(_boxName);
    await box.delete(_cacheKey);
  }
}
