import 'package:equatable/equatable.dart';
import '../../core/error/failures.dart';

/// Explicit typed source of content data.
enum ContentSource { none, bundleSeed, localCache, remoteServer }

/// Freshness state of content lifecycle.
enum ContentFreshness { initial, fresh, stale, failed }

/// Explicit typed lifecycle states for offline-first cache-first SWR architecture.
class ContentState<T> extends Equatable {
  final T? data;
  final ContentSource source;
  final ContentFreshness freshness;
  final bool isRefreshing;
  final Failure? failure;
  final DateTime lastUpdated;

  const ContentState._({
    this.data,
    this.source = ContentSource.none,
    this.freshness = ContentFreshness.initial,
    this.isRefreshing = false,
    this.failure,
    required this.lastUpdated,
  });

  /// Factory: Initial empty state before any cache or network access.
  factory ContentState.noData() => ContentState._(lastUpdated: DateTime.now());

  /// Factory: Data loaded from fresh local cache (< TTL).
  factory ContentState.freshCache(T data) => ContentState._(
    data: data,
    source: ContentSource.localCache,
    freshness: ContentFreshness.fresh,
    lastUpdated: DateTime.now(),
  );

  /// Factory: Data loaded from stale local cache (>= TTL), background refresh pending/active.
  factory ContentState.staleCache(T data, {bool isRefreshing = false}) =>
      ContentState._(
        data: data,
        source: ContentSource.localCache,
        freshness: ContentFreshness.stale,
        isRefreshing: isRefreshing,
        lastUpdated: DateTime.now(),
      );

  /// Factory: Background or explicit refresh currently active while retaining cached data.
  factory ContentState.refreshing({
    T? currentData,
    ContentSource? currentSource,
  }) => ContentState._(
    data: currentData,
    source: currentSource ?? ContentSource.localCache,
    freshness: ContentFreshness.stale,
    isRefreshing: true,
    lastUpdated: DateTime.now(),
  );

  /// Factory: Fresh data successfully retrieved from remote server and committed to cache.
  factory ContentState.freshRemote(T data) => ContentState._(
    data: data,
    source: ContentSource.remoteServer,
    freshness: ContentFreshness.fresh,
    lastUpdated: DateTime.now(),
  );

  /// Factory: Device is offline; using cached data.
  factory ContentState.offlineUsingCache(T data) => ContentState._(
    data: data,
    source: ContentSource.localCache,
    freshness: ContentFreshness.stale,
    lastUpdated: DateTime.now(),
  );

  /// Factory: Device is offline and cache is empty; using bundled static seed data.
  factory ContentState.offlineUsingSeed(T data) => ContentState._(
    data: data,
    source: ContentSource.bundleSeed,
    freshness: ContentFreshness.fresh,
    lastUpdated: DateTime.now(),
  );

  /// Factory: Background refresh failed, but continuing to display cached data safely.
  factory ContentState.refreshFailedUsingCache(T cachedData, Failure failure) =>
      ContentState._(
        data: cachedData,
        source: ContentSource.localCache,
        freshness: ContentFreshness.failed,
        failure: failure,
        lastUpdated: DateTime.now(),
      );

  /// Factory: No local data, no seed, and network request fatally failed.
  factory ContentState.fatalNoData(Failure failure) => ContentState._(
    freshness: ContentFreshness.failed,
    failure: failure,
    lastUpdated: DateTime.now(),
  );

  bool get hasData => data != null;
  bool get isAvailable => hasData;
  bool get isStale => freshness == ContentFreshness.stale;
  bool get isFromRemote => source == ContentSource.remoteServer;
  bool get isFromCache => source == ContentSource.localCache;
  bool get isFromSeed => source == ContentSource.bundleSeed;

  ContentState<T> copyWith({
    T? data,
    ContentSource? source,
    ContentFreshness? freshness,
    bool? isRefreshing,
    Failure? failure,
    DateTime? lastUpdated,
  }) {
    return ContentState._(
      data: data ?? this.data,
      source: source ?? this.source,
      freshness: freshness ?? this.freshness,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      failure: failure ?? this.failure,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
    data,
    source,
    freshness,
    isRefreshing,
    failure,
    lastUpdated.millisecondsSinceEpoch,
  ];
}
