import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/appwrite_auth_service.dart';
import '../../core/config/appwrite_config.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/network_info.dart';
import '../../core/storage/cache_service.dart';
import '../../features/categories/presentation/providers/category_notifier.dart';
import '../models/content_item.dart';
import '../providers/content_providers.dart';
import '../providers/learner_content_providers.dart';
import '../providers/letters_provider.dart';
import '../providers/numbers_provider.dart';
import '../providers/rhymes_providers.dart';
import '../providers/sentences_provider.dart';
import '../providers/words_provider.dart';
import '../../features/lessons/presentation/providers/lesson_notifier.dart';

/// Realtime content synchronizer that connects to Appwrite Realtime WebSockets.
///
/// Ensures any creation, modification, or deletion of content in the database
/// (via Admin Panel web or another device) immediately evicts local caches and
/// invalidates Riverpod providers so the mobile app reflects changes instantly.
class ContentRealtimeSync with WidgetsBindingObserver {
  final Ref _ref;
  final Client? _client;
  final NetworkInfo? _networkInfoOverride;
  final Realtime? _realtimeOverride;
  final void Function(ContentKind kind, String? itemId, String? categoryId)?
  onInvalidated;
  final void Function()? onSyncAll;

  RealtimeSubscription? _subscription;
  StreamSubscription<RealtimeMessage>? _streamSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _disposed = false;

  ContentRealtimeSync({
    required Ref ref,
    Client? client,
    NetworkInfo? networkInfo,
    Realtime? realtimeOverride,
    this.onInvalidated,
    this.onSyncAll,
  }) : _ref = ref,
       _client = client,
       _networkInfoOverride = networkInfo,
       _realtimeOverride = realtimeOverride;

  /// Starts listening to Appwrite Realtime events and lifecycle hooks.
  void initialize() {
    if (_disposed) return;
    WidgetsBinding.instance.addObserver(this);
    _listenToConnectivity();
    _startRealtimeSubscription();
  }

  void _listenToConnectivity() {
    NetworkInfo? networkInfo = _networkInfoOverride;
    try {
      networkInfo ??= _ref.read(networkInfoProvider);
    } catch (_) {}
    if (networkInfo == null) return;

    _connectivitySubscription = networkInfo.onConnectivityChanged.listen((
      results,
    ) {
      if (!results.contains(ConnectivityResult.none)) {
        AppLogger.debug('[RealtimeSync] Connectivity restored; syncing state.');
        syncAll();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppLogger.debug('[RealtimeSync] App resumed; refreshing content.');
      syncAll();
    }
  }

  /// Subscribes to document updates across all content collections.
  void _startRealtimeSubscription() {
    if (!AppwriteConfig.isBackendConfigured && _realtimeOverride == null) {
      AppLogger.debug(
        '[RealtimeSync] Backend not configured; skipping realtime socket.',
      );
      return;
    }

    try {
      final Realtime realtime;
      if (_realtimeOverride != null) {
        realtime = _realtimeOverride;
      } else {
        final client = _client ?? AppwriteAuthService().client;
        realtime = Realtime(client);
      }
      const dbId = AppwriteConfig.databaseId;

      final channels = [
        'databases.$dbId.collections.words.documents',
        'databases.$dbId.collections.sentences.documents',
        'databases.$dbId.collections.lessons.documents',
        'databases.$dbId.collections.letters.documents',
        'databases.$dbId.collections.numbers.documents',
        'databases.$dbId.collections.rhymes.documents',
        'databases.$dbId.collections.categories.documents',
      ];

      _subscription = realtime.subscribe(channels);
      _streamSubscription = _subscription?.stream.listen(
        _handleRealtimeMessage,
        onError: (error) {
          AppLogger.debug('[RealtimeSync] Realtime stream error: $error');
        },
      );
      AppLogger.debug(
        '[RealtimeSync] Successfully subscribed to content channels.',
      );
    } catch (e) {
      AppLogger.debug('[RealtimeSync] Failed to initialize subscription: $e');
    }
  }

  @visibleForTesting
  Future<void> handleMessageForTesting(RealtimeMessage message) =>
      _handleRealtimeMessage(message);

  Future<void> _handleRealtimeMessage(RealtimeMessage message) async {
    if (_disposed) return;
    try {
      final events = message.events;
      final payload = message.payload;
      final channels = message.channels;

      final targetCollection = _detectCollection(events, channels);
      if (targetCollection == null) return;

      final itemId = payload['\$id'] as String?;
      final categoryId =
          payload['categoryId'] as String? ?? payload['category'] as String?;

      AppLogger.debug(
        '[RealtimeSync] Received update for $targetCollection '
        '(id: $itemId, cat: $categoryId)',
      );

      if (targetCollection == 'categories') {
        await _handleCategoryUpdate(itemId);
      } else {
        final kind = _collectionToContentKind(targetCollection);
        if (kind != null) {
          await _handleContentItemUpdate(
            kind: kind,
            itemId: itemId,
            categoryId: categoryId,
          );
        }
      }
    } catch (e) {
      AppLogger.debug('[RealtimeSync] Error handling realtime message: $e');
    }
  }

  String? _detectCollection(List<String> events, List<String> channels) {
    const collections = [
      'words',
      'sentences',
      'lessons',
      'letters',
      'numbers',
      'rhymes',
      'categories',
    ];

    for (final col in collections) {
      for (final event in events) {
        if (event.contains('.collections.$col.')) return col;
      }
      for (final channel in channels) {
        if (channel.contains('.collections.$col.')) return col;
      }
    }
    return null;
  }

  ContentKind? _collectionToContentKind(String collection) {
    return switch (collection) {
      'words' => ContentKind.word,
      'sentences' => ContentKind.sentence,
      'lessons' => ContentKind.lesson,
      'letters' => ContentKind.letter,
      'numbers' => ContentKind.number,
      'rhymes' => ContentKind.rhyme,
      _ => null,
    };
  }

  Future<void> _handleCategoryUpdate(String? categoryId) async {
    await CacheService.delete('cached_categories');
    _ref.invalidate(categoryNotifierProvider);
    try {
      await _ref.read(categoryNotifierProvider.notifier).refresh();
    } catch (_) {}
    if (categoryId != null && categoryId.isNotEmpty) {
      _ref.invalidate(lessonsByCategoryProvider(categoryId));
    }
  }

  Future<void> _handleContentItemUpdate({
    required ContentKind kind,
    String? itemId,
    String? categoryId,
  }) async {
    // 1. Evict local cache lists & items
    await CacheService.delete('content_list_${kind.name}_all');
    if (categoryId != null && categoryId.isNotEmpty) {
      await CacheService.delete('content_list_${kind.name}_$categoryId');
    }
    if (itemId != null && itemId.isNotEmpty) {
      await CacheService.delete('content_item_${kind.name}_$itemId');
      if (kind == ContentKind.lesson) {
        await CacheService.delete('content_admin_item_${kind.name}_$itemId');
      }
    }

    // 2. Invalidate Riverpod providers to trigger instant UI refresh
    invalidateProviders(kind: kind, itemId: itemId, categoryId: categoryId);
  }

  /// Invalidates all Riverpod providers associated with a content kind.
  void invalidateProviders({
    required ContentKind kind,
    String? itemId,
    String? categoryId,
  }) {
    _ref.invalidate(contentListProvider((kind, null)));
    if (categoryId != null && categoryId.isNotEmpty) {
      _ref.invalidate(contentListProvider((kind, categoryId)));
      if (kind == ContentKind.lesson) {
        _ref.invalidate(lessonsByCategoryProvider(categoryId));
      }
    }

    if (itemId != null && itemId.isNotEmpty) {
      _ref.invalidate(contentDetailProvider((kind, itemId)));
      if (kind == ContentKind.lesson) {
        _ref.invalidate(learnerLessonDetailProvider(itemId));
      }
    }

    switch (kind) {
      case ContentKind.word:
        _ref.invalidate(wordsProvider);
        _ref.invalidate(learnerWordsProvider);
        break;
      case ContentKind.sentence:
        _ref.invalidate(sentencesProvider);
        _ref.invalidate(learnerSentencesProvider);
        break;
      case ContentKind.lesson:
        _ref.invalidate(learnerLessonsProvider);
        break;
      case ContentKind.letter:
        _ref.invalidate(lettersProvider);
        _ref.invalidate(learnerLettersProvider);
        break;
      case ContentKind.number:
        _ref.invalidate(numbersProvider);
        _ref.invalidate(learnerNumbersProvider);
        break;
      case ContentKind.rhyme:
        _ref.invalidate(rhymesProvider);
        break;
    }
    onInvalidated?.call(kind, itemId, categoryId);
  }

  /// Triggers a full background sync across all content catalogs.
  void syncAll() {
    if (_disposed) return;
    onSyncAll?.call();
    _ref.invalidate(categoryNotifierProvider);
    for (final kind in ContentKind.values) {
      _ref.invalidate(contentListProvider((kind, null)));
    }
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

  /// Disposes subscriptions and observers.
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _streamSubscription?.cancel();
    _subscription?.close();
  }
}

/// Provider that maintains a living [ContentRealtimeSync] instance for the app.
final contentRealtimeSyncProvider = Provider<ContentRealtimeSync>((ref) {
  final sync = ContentRealtimeSync(ref: ref);
  sync.initialize();
  ref.onDispose(sync.dispose);
  return sync;
});
