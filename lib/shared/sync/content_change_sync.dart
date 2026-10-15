import 'dart:async';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/content_change_feed.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/network_info.dart';
import '../../core/storage/cache_service.dart';
import '../../features/categories/presentation/providers/category_notifier.dart';
import '../../features/lessons/presentation/providers/lesson_notifier.dart';
import '../models/content_item.dart';
import '../providers/content_providers.dart';
import '../providers/learner_content_providers.dart';
import '../providers/letters_provider.dart';
import '../providers/numbers_provider.dart';
import '../providers/rhymes_providers.dart';
import '../providers/sentences_provider.dart';
import '../providers/words_provider.dart';

/// Keeps learner content fresh by polling the Worker content change feed
/// (`GET /api/v1/content/changes?since=<seq>`), replacing Appwrite Realtime.
///
/// Polls when the app starts or returns to the foreground, every
/// [pollInterval] while it stays in the foreground, and when connectivity
/// returns. Failures back off exponentially up to [maxBackoff]. Each change
/// evicts the local caches and invalidates the same providers the realtime
/// sync did.
class ContentChangeSync with WidgetsBindingObserver {
  ContentChangeSync({
    required Ref ref,
    NetworkInfo? networkInfo,
    ContentChangeSource? source,
    ContentChangeCursorStore? cursorStore,
    this.pollInterval = const Duration(seconds: 60),
    this.maxBackoff = const Duration(minutes: 15),
    this.onInvalidated,
    this.onSyncAll,
  }) : _ref = ref,
       _networkInfoOverride = networkInfo,
       _sourceOverride = source,
       _cursorOverride = cursorStore;

  /// Tables mirrored by the feed that the app caches.
  static const Map<String, ContentKind?> trackedTables = {
    'words': ContentKind.word,
    'sentences': ContentKind.sentence,
    'lessons': ContentKind.lesson,
    'letters': ContentKind.letter,
    'numbers': ContentKind.number,
    'rhymes': ContentKind.rhyme,
    'categories': null,
  };

  /// Above this many changed rows of one table in a poll, the table is
  /// refreshed as a whole instead of row by row.
  static const int maxRowsPerTable = 50;

  /// Pages fetched per poll before falling back to a full refresh.
  static const int maxPagesPerPoll = 5;

  final Ref _ref;
  final NetworkInfo? _networkInfoOverride;
  final ContentChangeSource? _sourceOverride;
  final ContentChangeCursorStore? _cursorOverride;
  final Duration pollInterval;
  final Duration maxBackoff;
  final void Function(ContentKind kind, String? itemId, String? categoryId)?
  onInvalidated;
  final void Function()? onSyncAll;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _timer;
  Future<void>? _inFlight;
  int _failures = 0;
  bool _foreground = true;
  bool _disposed = false;

  ContentChangeSource get _source =>
      _sourceOverride ?? _ref.read(contentChangeSourceProvider);
  ContentChangeCursorStore get _cursor =>
      _cursorOverride ?? _ref.read(contentChangeCursorStoreProvider);

  /// Current delay before the next poll (grows after failures).
  @visibleForTesting
  Duration get nextDelay {
    if (_failures == 0) return pollInterval;
    final factor = math.pow(2, math.min(_failures, 10)).toInt();
    final delay = pollInterval * factor;
    return delay > maxBackoff ? maxBackoff : delay;
  }

  /// Starts polling and listens to lifecycle and connectivity changes.
  void initialize() {
    if (_disposed) return;
    WidgetsBinding.instance.addObserver(this);
    _listenToConnectivity();
    unawaited(poll());
  }

  void _listenToConnectivity() {
    NetworkInfo? networkInfo = _networkInfoOverride;
    try {
      networkInfo ??= _ref.read(networkInfoProvider);
    } catch (e, stack) {
      AppLogger.warning(
        '[ChangeSync] Network info unavailable; skipping connectivity sync',
        name: 'ContentChangeSync',
        error: e,
        stackTrace: stack,
      );
    }
    _connectivitySubscription = networkInfo?.onConnectivityChanged.listen((
      results,
    ) {
      if (!results.contains(ConnectivityResult.none)) unawaited(poll());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _foreground = true;
        unawaited(poll());
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _foreground = false;
        _timer?.cancel();
        _timer = null;
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (_disposed || !_foreground) return;
    _timer = Timer(nextDelay, () => unawaited(poll()));
  }

  /// Fetches and applies new changes; overlapping calls share one poll.
  Future<void> poll() {
    if (_disposed) return Future.value();
    return _inFlight ??= _pollOnce().whenComplete(() {
      _inFlight = null;
      _schedule();
    });
  }

  Future<void> _pollOnce() async {
    try {
      final stored = await _cursor.read();
      if (stored == null) {
        // First run: content was just loaded fresh, so only remember where
        // the feed is.
        final page = await _source.fetch(0);
        if (_disposed) return;
        await _cursor.write(page.latest);
        _failures = 0;
        return;
      }

      var since = stored;
      final changes = <ContentChange>[];
      var fullRefresh = false;
      for (var pageIndex = 0; ; pageIndex++) {
        final page = await _source.fetch(since);
        if (_disposed) return;
        if (page.latest < since) {
          // The feed was reset; we cannot tell what changed.
          fullRefresh = true;
          since = page.latest;
          break;
        }
        changes.addAll(page.changes);
        if (page.changes.isNotEmpty) since = page.changes.last.seq;
        if (page.changes.isEmpty || since >= page.latest) {
          since = math.max(since, page.latest);
          break;
        }
        if (pageIndex + 1 >= maxPagesPerPoll) {
          fullRefresh = true;
          since = page.latest;
          break;
        }
      }

      if (fullRefresh) {
        syncAll();
      } else if (changes.isNotEmpty) {
        await applyChanges(changes);
      }
      await _cursor.write(since);
      _failures = 0;
    } catch (e, stack) {
      _failures++;
      AppLogger.warning(
        '[ChangeSync] Poll failed (attempt $_failures); retrying in $nextDelay',
        name: 'ContentChangeSync',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Evicts caches and invalidates providers for [changes].
  @visibleForTesting
  Future<void> applyChanges(List<ContentChange> changes) async {
    final byTable = <String, Set<String>>{};
    for (final change in changes) {
      if (!trackedTables.containsKey(change.table)) continue;
      byTable
          .putIfAbsent(change.table, () => <String>{})
          .add(change.isBulk ? '*' : change.rowId);
    }
    for (final entry in byTable.entries) {
      final rows = entry.value;
      final bulk = rows.contains('*') || rows.length > maxRowsPerTable;
      final kind = trackedTables[entry.key];
      if (_disposed) return;
      if (entry.key == 'categories') {
        await _handleCategoryUpdate();
      } else if (kind != null) {
        await _handleContentUpdate(kind, bulk ? null : rows);
      }
    }
  }

  Future<void> _handleCategoryUpdate() async {
    await CacheService.delete('cached_categories');
    _ref.invalidate(categoryNotifierProvider);
    // The feed has no category ids, so every category's lesson list is
    // refreshed.
    _ref.invalidate(lessonsByCategoryProvider);
    try {
      await _ref.read(categoryNotifierProvider.notifier).refresh();
    } catch (e, stack) {
      AppLogger.warning(
        '[ChangeSync] Category refresh failed',
        name: 'ContentChangeSync',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// [itemIds] null means "everything of this kind changed".
  Future<void> _handleContentUpdate(
    ContentKind kind,
    Set<String>? itemIds,
  ) async {
    // Lists may be cached per category; the feed carries no category id.
    await CacheService.deleteByPrefix('content_list_${kind.name}_');
    if (itemIds == null) {
      await CacheService.deleteByPrefix('content_item_${kind.name}_');
      if (kind == ContentKind.lesson) {
        await CacheService.deleteByPrefix('content_admin_item_${kind.name}_');
      }
    } else {
      for (final id in itemIds) {
        await CacheService.delete('content_item_${kind.name}_$id');
        if (kind == ContentKind.lesson) {
          await CacheService.delete('content_admin_item_${kind.name}_$id');
        }
      }
    }
    invalidateProviders(kind: kind, itemIds: itemIds);
  }

  /// Invalidates all Riverpod providers associated with a content kind.
  void invalidateProviders({required ContentKind kind, Set<String>? itemIds}) {
    _ref.invalidate(contentListProvider);
    if (kind == ContentKind.lesson) _ref.invalidate(lessonsByCategoryProvider);

    if (itemIds == null) {
      _ref.invalidate(contentDetailProvider);
      if (kind == ContentKind.lesson) {
        _ref.invalidate(learnerLessonDetailProvider);
      }
    } else {
      for (final id in itemIds) {
        _ref.invalidate(contentDetailProvider((kind, id)));
        if (kind == ContentKind.lesson) {
          _ref.invalidate(learnerLessonDetailProvider(id));
        }
      }
    }

    switch (kind) {
      case ContentKind.word:
        _ref.invalidate(wordsProvider);
        _ref.invalidate(learnerWordsProvider);
      case ContentKind.sentence:
        _ref.invalidate(sentencesProvider);
        _ref.invalidate(learnerSentencesProvider);
      case ContentKind.lesson:
        _ref.invalidate(learnerLessonsProvider);
      case ContentKind.letter:
        _ref.invalidate(lettersProvider);
        _ref.invalidate(learnerLettersProvider);
      case ContentKind.number:
        _ref.invalidate(numbersProvider);
        _ref.invalidate(learnerNumbersProvider);
      case ContentKind.rhyme:
        _ref.invalidate(rhymesProvider);
    }
    if (itemIds == null) {
      onInvalidated?.call(kind, null, null);
    } else {
      for (final id in itemIds) {
        onInvalidated?.call(kind, id, null);
      }
    }
  }

  /// Triggers a full background refresh across all content catalogs.
  void syncAll() {
    if (_disposed) return;
    onSyncAll?.call();
    _ref.invalidate(categoryNotifierProvider);
    _ref.invalidate(contentListProvider);
    _ref.invalidate(contentDetailProvider);
    _ref.invalidate(lessonsByCategoryProvider);
    _ref.invalidate(wordsProvider);
    _ref.invalidate(sentencesProvider);
    _ref.invalidate(lettersProvider);
    _ref.invalidate(numbersProvider);
    _ref.invalidate(rhymesProvider);
    _ref.invalidate(learnerLessonsProvider);
    _ref.invalidate(learnerWordsProvider);
    _ref.invalidate(learnerSentencesProvider);
    _ref.invalidate(learnerLettersProvider);
    _ref.invalidate(learnerNumbersProvider);
  }

  /// Stops polling and removes observers.
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
  }
}

/// Keeps one [ContentChangeSync] alive for the app's lifetime.
final contentChangeSyncProvider = Provider<ContentChangeSync>((ref) {
  final sync = ContentChangeSync(ref: ref);
  sync.initialize();
  ref.onDispose(sync.dispose);
  return sync;
});
