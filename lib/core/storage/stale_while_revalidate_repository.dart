import 'dart:async';
import 'package:itun/core/logging/app_logger.dart';
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

  const SWRResult({this.data, required this.state, this.error});

  bool get hasData => data != null;
}

class StaleWhileRevalidateRepository {
  /// Executes stale-while-revalidate pattern:
  /// 1. Reads local cache and yields immediately if found.
  /// 2. Executes background network fetch function.
  /// 3. Updates cache and yields fresh data on success.
  /// 4. Handles offline / error states gracefully without losing cached data.
  static Stream<SWRResult<T>> fetchSWR<T>({
    required String cacheKey,
    required T Function(Map<String, dynamic> json) fromJson,
    required Map<String, dynamic> Function(T data) toJson,
    required Future<T> Function() fetchRemote,
    Duration staleDuration = const Duration(hours: 1),
  }) async* {
    T? cachedData;

    try {
      cachedData = await CacheService.get(cacheKey, fromJson);
    } catch (e) {
      AppLogger.debug('SWR: Error reading cache for key $cacheKey: $e');
    }

    if (cachedData != null) {
      yield SWRResult<T>(data: cachedData, state: SWRState.cached);
    } else {
      yield SWRResult<T>(state: SWRState.loadingNoCache);
    }

    try {
      if (cachedData != null) {
        yield SWRResult<T>(data: cachedData, state: SWRState.refreshing);
      }

      final freshData = await fetchRemote();
      await CacheService.set(cacheKey, toJson(freshData));

      yield SWRResult<T>(data: freshData, state: SWRState.fresh);
    } catch (e) {
      AppLogger.debug('SWR: Remote fetch failed for key $cacheKey: $e');

      if (cachedData != null) {
        yield SWRResult<T>(
          data: cachedData,
          state: SWRState.errorWithCache,
          error: e.toString(),
        );
      } else {
        yield SWRResult<T>(state: SWRState.fatalError, error: e.toString());
      }
    }
  }
}
