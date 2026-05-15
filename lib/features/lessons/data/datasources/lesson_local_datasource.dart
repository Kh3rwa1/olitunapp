import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/cache_service.dart';
import '../models/lesson_model.dart';

abstract class LessonLocalDataSource {
  Future<List<LessonModel>> getLessons();
  Future<void> cacheLessons(List<LessonModel> lessons);
  Future<void> clearCache();
}

class LessonLocalDataSourceImpl implements LessonLocalDataSource {
  static const String _cacheKey = 'cached_lessons';

  @override
  Future<List<LessonModel>> getLessons() async {
    try {
      final cached = await CacheService.getList<LessonModel>(
        _cacheKey,
        LessonModel.fromJson,
      );
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      throw CacheException(message: 'No cached lessons found');
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> cacheLessons(List<LessonModel> lessons) async {
    try {
      final existing =
          await CacheService.getList<LessonModel>(
            _cacheKey,
            LessonModel.fromJson,
          ) ??
          [];

      final Map<String, LessonModel> lessonMap = {
        for (var l in existing) l.id: l,
      };

      for (var l in lessons) {
        lessonMap[l.id] = l;
      }

      final data = lessonMap.values.map((e) => e.toJson()).toList();
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
