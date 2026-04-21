import 'dart:convert';
import 'package:hive/hive.dart';
import '../../../../core/error/exceptions.dart';
import '../models/lesson_model.dart';

abstract class LessonLocalDataSource {
  Future<List<LessonModel>> getLessons();
  Future<void> cacheLessons(List<LessonModel> lessons);
  Future<void> clearCache();
}

class LessonLocalDataSourceImpl implements LessonLocalDataSource {
  static const String _boxName = 'content_cache';
  static const String _cacheKey = 'cached_lessons';

  @override
  Future<List<LessonModel>> getLessons() async {
    try {
      final box = await Hive.openBox(_boxName);
      final jsonString = box.get(_cacheKey);
      if (jsonString != null) {
        final decoded = jsonDecode(jsonString) as List;
        return decoded
            .map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw CacheException(message: 'No cached lessons found');
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> cacheLessons(List<LessonModel> lessons) async {
    try {
      final box = await Hive.openBox(_boxName);
      final jsonString = jsonEncode(lessons.map((e) => e.toJson()).toList());
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
