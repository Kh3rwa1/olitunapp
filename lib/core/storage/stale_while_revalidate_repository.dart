import 'dart:async';
import '../logging/app_logger.dart';
import 'cache_service.dart';

enum SWRState {
  loadingNoCache,
  cached,
  fresh,
  stale,
  refreshing,
  offline,
  errorWithCache,
  fatalError,
}

class SWRResult<T> {
  final T? data;
  final SWRState state;
  final String? error;
  final bool isStale;

  const SWRResult({
    this.data,
    required this.state,
    this.error,
    this.isStale = false,
  });

  bool get hasData => data != null;
}

class StaleWhileRevalidateRepository {
  /// Executes stale-while-revalidate pattern:
  /// 1. Reads local cache (including stale entries past TTL) and yields immediately if present.
  /// 2. Executes background network fetch.
  /// 3. Updates cache and yields fresh data on success.
  /// 4. Handles offline/error states gracefully while preserving cached data.
  static Stream<SWRResult<T>> fetchSWR<T>({
    required String cacheKey,
    required T Function(Map<String, dynamic> json) fromJson,
    required Map<String, dynamic> Function(T data) toJson,
    required Future<T> Function() fetchRemote,
    Duration staleDuration = const Duration(hours: 1),
  }) async* {
    T? cachedData;
    bool isStaleCache = false;

    try {
      // 1. First attempt fresh cache lookup
      cachedData = await CacheService.get(cacheKey, fromJson);

      // 2. If fresh cache lookup returned null, check for stale cache entry
      if (cachedData == null) {
        final meta = await CacheService.getMeta(cacheKey);
        if (meta != null && meta.data != null) {
          try {
            if (meta.data is Map<String, dynamic>) {
              cachedData = fromJson(meta.data as Map<String, dynamic>);
              isStaleCache = true;
            }
          } catch (e) {
            AppLogger.debug(
              'SWR: Failed to parse stale entry for $cacheKey: $e',
            );
          }
        }
      }
    } catch (e) {
      AppLogger.debug('SWR: Error reading cache for key $cacheKey: $e');
    }

    if (cachedData != null) {
      yield SWRResult<T>(
        data: cachedData,
        state: isStaleCache ? SWRState.stale : SWRState.cached,
        isStale: isStaleCache,
      );
    } else {
      yield SWRResult<T>(state: SWRState.loadingNoCache);
    }

    try {
      if (cachedData != null) {
        yield SWRResult<T>(
          data: cachedData,
          state: SWRState.refreshing,
          isStale: isStaleCache,
        );
      }

      final freshData = await fetchRemote();
      await CacheService.set(cacheKey, toJson(freshData), ttl: staleDuration);

      yield SWRResult<T>(data: freshData, state: SWRState.fresh);
    } catch (e) {
      AppLogger.debug('SWR: Remote fetch failed for key $cacheKey: $e');

      if (cachedData != null) {
        yield SWRResult<T>(
          data: cachedData,
          state: SWRState.errorWithCache,
          error: e.toString(),
          isStale: true,
        );
      } else {
        yield SWRResult<T>(state: SWRState.fatalError, error: e.toString());
      }
    }
  }
}
