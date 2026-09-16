#!/usr/bin/env python3
"""Temporary deterministic patcher for the secure lesson-listing branch."""
from pathlib import Path

function_path = Path('functions/getAuthorizedLesson/src/main.js')
source = function_path.read_text()
media_import = "import { createMediaAccess, MEDIA_HEADERS, scopeLessonMedia } from './media-access.js';"
listing_import = "import { ListLessonsRequestError, listAuthorizedLessons } from './list-lessons.js';"
if source.count(media_import) != 1 or listing_import in source:
    raise SystemExit('Unexpected authorized-lesson import anchors')
source = source.replace(media_import, f'{media_import}\n{listing_import}', 1)

limiter_start = source.index('export function createSlidingWindowRateLimiter({')
limiter_end = source.index('\nconst defaultRateLimiter', limiter_start)
new_limiter = """export function createSlidingWindowRateLimiter({
  windowMs = 60000,
  maxPerWindow = 60,
  maxKeys = 5000,
  cleanupIntervalMs = windowMs,
  clock = Date.now,
} = {}) {
  if (!Number.isFinite(windowMs) || windowMs <= 0 ||
      !Number.isInteger(maxPerWindow) || maxPerWindow <= 0 ||
      !Number.isInteger(maxKeys) || maxKeys <= 0 ||
      !Number.isFinite(cleanupIntervalMs) || cleanupIntervalMs <= 0) {
    throw new RangeError('Invalid rate limiter configuration');
  }

  const records = new Map();
  let lastCleanupAt = Number.NEGATIVE_INFINITY;

  function compact(now, force = false) {
    if (!force && records.size < maxKeys && now - lastCleanupAt < cleanupIntervalMs) return;
    const cutoff = now - windowMs;
    for (const [key, timestamps] of records.entries()) {
      const active = timestamps.filter(timestamp => timestamp > cutoff);
      if (active.length === 0) records.delete(key);
      else records.set(key, active);
    }
    lastCleanupAt = now;
  }

  function evictOldestKey() {
    let oldestKey = null;
    let oldestTimestamp = Number.POSITIVE_INFINITY;
    for (const [key, timestamps] of records.entries()) {
      const timestamp = timestamps[0] ?? Number.NEGATIVE_INFINITY;
      if (timestamp < oldestTimestamp) {
        oldestTimestamp = timestamp;
        oldestKey = key;
      }
    }
    if (oldestKey !== null) records.delete(oldestKey);
  }

  return {
    isAllowed(key) {
      if (!key) return { allowed: true, remaining: maxPerWindow, retryAfterSec: 0 };
      const now = clock();
      compact(now);
      if (!records.has(key) && records.size >= maxKeys) {
        compact(now, true);
        if (records.size >= maxKeys) evictOldestKey();
      }

      const cutoff = now - windowMs;
      const timestamps = (records.get(key) || []).filter(timestamp => timestamp > cutoff);
      if (timestamps.length >= maxPerWindow) {
        const retryAfterSec = Math.max(
          1,
          Math.ceil((timestamps[0] + windowMs - now) / 1000),
        );
        records.set(key, timestamps);
        return { allowed: false, remaining: 0, retryAfterSec };
      }
      timestamps.push(now);
      records.set(key, timestamps);
      return {
        allowed: true,
        remaining: maxPerWindow - timestamps.length,
        retryAfterSec: 0,
      };
    },
    reset() {
      records.clear();
      lastCleanupAt = Number.NEGATIVE_INFINITY;
    },
    get size() {
      return records.size;
    },
  };
}
"""
source = source[:limiter_start] + new_limiter + source[limiter_end:]

old_ip = "    const clientIp = req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || 'anonymous';"
new_ip = """    const forwardedFor = req.headers['x-forwarded-for'];
    const forwardedClientIp = typeof forwardedFor === 'string'
      ? forwardedFor.split(',')[0].trim()
      : '';
    const clientIp = text(
      req.headers['x-appwrite-client-ip'] || forwardedClientIp || req.headers['x-real-ip'],
      64,
    ) || 'anonymous';"""
if source.count(old_ip) != 1:
    raise SystemExit('Unexpected client-IP anchor')
source = source.replace(old_ip, new_ip, 1)

dispatch_start = source.index('    const body = parseBody(req);')
dispatch_end = source.index('\n\n    let lessonDoc;', dispatch_start)
new_dispatch = """    const body = parseBody(req);
    const lessonId = text(body.lessonId, 64);
    const action = text(body.action, 32) || 'get_lesson';

    if (action === 'list_lessons') {
      try {
        const listing = await listAuthorizedLessons({
          databases,
          databaseId,
          callerUserId,
          body,
          evaluateAccess: evaluateLessonAccess,
          onEntitlementError: () => error('Failed to query lesson-list entitlements'),
        });
        return res.json(
          { ok: true, ...listing },
          200,
          { 'cache-control': 'no-store, private' },
        );
      } catch (err) {
        if (err instanceof ListLessonsRequestError) {
          return res.json({
            ok: false,
            error: err.code,
            message: err.message,
          }, err.statusCode);
        }
        error('Failed to list lesson metadata');
        return res.json({
          ok: false,
          error: 'lesson_list_unavailable',
          message: 'Lesson list is temporarily unavailable',
        }, 503);
      }
    }

    if (action !== 'get_lesson' && action !== 'get_media') {
      return res.json({ ok: false, error: 'invalid_action', message: 'Invalid action' }, 400);
    }
    if (!lessonId) {
      return res.json({ ok: false, message: 'Missing or invalid lessonId' }, 400);
    }"""
source = source[:dispatch_start] + new_dispatch + source[dispatch_end:]
function_path.write_text(source)

datasource_path = Path('lib/features/lessons/data/datasources/lesson_remote_datasource.dart')
datasource = datasource_path.read_text()
pagination_import = "import '../../../../core/api/appwrite_databases_pagination.dart';\n"
if datasource.count(pagination_import) != 1:
    raise SystemExit('Unexpected lesson pagination import anchor')
datasource = datasource.replace(pagination_import, '', 1)
constant_anchor = "  static const Duration _writeTimeout = Duration(seconds: 15);"
constants = """  static const Duration _writeTimeout = Duration(seconds: 15);
  static const int _authorizedListPageSize = 100;
  static const int _maxAuthorizedListPages = 100;"""
if datasource.count(constant_anchor) != 1:
    raise SystemExit('Unexpected lesson data-source constant anchor')
datasource = datasource.replace(constant_anchor, constants, 1)

start_marker = "  @override\n  Future<List<LessonModel>> getLessons() async {"
end_marker = "\n  @override\n  Future<LessonModel> getAuthorizedLesson"
if datasource.count(start_marker) != 1 or datasource.count(end_marker) != 1:
    raise SystemExit('Unexpected lesson-list method anchors')
start = datasource.index(start_marker)
end = datasource.index(end_marker, start)
new_methods = """  Future<List<LessonModel>> _getAuthorizedLessonList({
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
          if (categoryId != null) 'categoryId': categoryId,
          if (cursor != null) 'cursor': cursor,
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
"""
datasource_path.write_text(datasource[:start] + new_methods + datasource[end:])
