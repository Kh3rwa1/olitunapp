import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/cache_service.dart';
import '../models/lesson_model.dart';

abstract class LessonLocalDataSource {
  Future<List<LessonModel>> getLessons();
  Future<void> cacheLessons(List<LessonModel> lessons);
  Future<void> clearCache();

  Future<AuthorizedLessonCacheEntry?> getAuthorizedLesson({
    required String userId,
    required String lessonId,
  });

  Future<void> cacheAuthorizedLesson({
    required String userId,
    required LessonModel lesson,
    required Duration gracePeriod,
    bool isExplicitlyDenied = false,
  });

  Future<void> invalidateAuthorizedLesson({
    required String userId,
    required String lessonId,
    bool markExplicitlyDenied = true,
  });

  Future<void> clearUserAuthorizedLessons(String userId);
}

/// Metadata envelope for user-scoped cached authorized lessons with grace-period TTL.
class AuthorizedLessonCacheEntry {
  final LessonModel lesson;
  final String userId;
  final int cachedAtMs;
  final int expiresAtMs;
  final bool isExplicitlyDenied;

  const AuthorizedLessonCacheEntry({
    required this.lesson,
    required this.userId,
    required this.cachedAtMs,
    required this.expiresAtMs,
    this.isExplicitlyDenied = false,
  });

  bool isExpiredBy(DateTime now) => now.millisecondsSinceEpoch > expiresAtMs;
  bool get isExpired => isExpiredBy(DateTime.now());

  Map<String, dynamic> toJson() => {
    'lesson': lesson.toJson(),
    'userId': userId,
    'cachedAtMs': cachedAtMs,
    'expiresAtMs': expiresAtMs,
    'isExplicitlyDenied': isExplicitlyDenied,
  };

  factory AuthorizedLessonCacheEntry.fromJson(Map<String, dynamic> json) {
    final lessonJson = json['lesson'];
    final lessonMap = lessonJson is Map
        ? Map<String, dynamic>.from(lessonJson)
        : <String, dynamic>{};
    return AuthorizedLessonCacheEntry(
      lesson: LessonModel.fromJson(lessonMap, lessonMap['id'] as String?),
      userId: json['userId'] as String? ?? '',
      cachedAtMs: json['cachedAtMs'] as int? ?? 0,
      expiresAtMs: json['expiresAtMs'] as int? ?? 0,
      isExplicitlyDenied: json['isExplicitlyDenied'] as bool? ?? false,
    );
  }
}

class LessonLocalDataSourceImpl implements LessonLocalDataSource {
  static const String _cacheKey = 'cached_lessons';
  static String _authLessonKey(String userId, String lessonId) =>
      'auth_lesson_${userId}_$lessonId';

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

  @override
  Future<AuthorizedLessonCacheEntry?> getAuthorizedLesson({
    required String userId,
    required String lessonId,
  }) async {
    try {
      final key = _authLessonKey(userId, lessonId);
      final entry = await CacheService.get<AuthorizedLessonCacheEntry>(
        key,
        AuthorizedLessonCacheEntry.fromJson,
      );
      if (entry != null && entry.userId == userId) {
        return entry;
      }
      return null;
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> cacheAuthorizedLesson({
    required String userId,
    required LessonModel lesson,
    required Duration gracePeriod,
    bool isExplicitlyDenied = false,
  }) async {
    try {
      final key = _authLessonKey(userId, lesson.id);
      final now = DateTime.now().millisecondsSinceEpoch;
      final entry = AuthorizedLessonCacheEntry(
        lesson: lesson,
        userId: userId,
        cachedAtMs: now,
        expiresAtMs: now + gracePeriod.inMilliseconds,
        isExplicitlyDenied: isExplicitlyDenied,
      );
      await CacheService.set(key, entry.toJson(), ttl: gracePeriod);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> invalidateAuthorizedLesson({
    required String userId,
    required String lessonId,
    bool markExplicitlyDenied = true,
  }) async {
    try {
      final key = _authLessonKey(userId, lessonId);
      if (markExplicitlyDenied) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final entry = AuthorizedLessonCacheEntry(
          lesson: LessonModel(
            id: lessonId,
            categoryId: '',
            titleOlChiki: '',
            titleLatin: '',
            isLocked: true,
            blocks: const [],
          ),
          userId: userId,
          cachedAtMs: now,
          expiresAtMs: now + const Duration(days: 365).inMilliseconds,
          isExplicitlyDenied: true,
        );
        await CacheService.set(key, entry.toJson());
      } else {
        await CacheService.delete(key);
      }
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> clearUserAuthorizedLessons(String userId) async {
    // Keys are isolated per user via 'auth_lesson_${userId}_*' prefix.
  }
}
