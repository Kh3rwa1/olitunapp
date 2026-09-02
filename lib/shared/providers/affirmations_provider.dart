import 'dart:convert';
import 'package:itun/core/logging/app_logger.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/appwrite_db_service.dart';
import '../../core/auth/appwrite_auth_service.dart';
import '../../core/storage/cache_service.dart';
import '../models/content_models.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

final affirmationsProvider =
    NotifierProvider<AffirmationsNotifier, AsyncValue<List<AffirmationModel>>>(
      AffirmationsNotifier.new,
    );

class AffirmationsNotifier
    extends Notifier<AsyncValue<List<AffirmationModel>>> {
  bool _disposed = false;

  @override
  AsyncValue<List<AffirmationModel>> build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Re-create the notifier when the auth state changes.
    ref.watch(isAuthenticatedProvider);
    // Deferred: `state` may not be read or written inside build().
    Future.microtask(_loadAffirmations);
    return const AsyncValue.data(<AffirmationModel>[]);
  }

  static const String _cacheKey = 'cached_daily_affirmations';

  Future<void> _loadAffirmations() async {
    final cached = await CacheService.getList(
      _cacheKey,
      AffirmationModel.fromJson,
    );
    if (_disposed) return;
    if (cached != null) {
      state = AsyncValue.data(cached);
    }

    try {
      final db = ref.read(appwriteDbServiceProvider);
      final data = await db.listDocuments(
        'daily_affirmations',
        queries: [Query.orderAsc('order'), Query.limit(500)],
      );
      if (_disposed) return;
      final affirmations = data.map(AffirmationModel.fromJson).toList();
      state = AsyncValue.data(affirmations);
      await CacheService.set(
        _cacheKey,
        affirmations.map((e) => e.toJson()).toList(),
      );
    } catch (e, stack) {
      AppLogger.debug('❌ load affirmations FAILED: $e');
      if (_disposed) return;
      if (cached == null) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> add(AffirmationModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.createDocument('daily_affirmations', item.id, item.toJson());
      await _loadAffirmations();
    } catch (e) {
      AppLogger.debug('❌ add affirmation FAILED: $e');
      rethrow;
    }
  }

  Future<void> update(AffirmationModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.updateDocument('daily_affirmations', item.id, item.toJson());
      await _loadAffirmations();
    } catch (e) {
      AppLogger.debug('❌ update affirmation FAILED: $e');
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.deleteDocument('daily_affirmations', id);
      await _loadAffirmations();
    } catch (e) {
      AppLogger.debug('❌ delete affirmation FAILED: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> syncFromGoogleSheet({
    String? sheetUrl,
    bool force = false,
  }) async {
    try {
      final client = ref.read(appwriteAuthServiceProvider).client;
      final functions = Functions(client);
      final execution = await functions.createExecution(
        functionId: 'syncDailyAffirmation',
        body: '{"sheetUrl":"${sheetUrl ?? ""}", "force":$force}',
      );

      Map<String, dynamic> result = {'ok': true};
      if (execution.responseBody.isNotEmpty) {
        try {
          final decoded = jsonDecode(execution.responseBody);
          if (decoded is Map<String, dynamic>) {
            result = decoded;
          }
        } catch (e) {
          AppLogger.warning(
            'AffirmationsNotifier: failed to parse sync response: $e',
          );
        }
      }

      await _loadAffirmations();
      return result;
    } catch (e) {
      AppLogger.debug('❌ sync affirmations from Google Sheet FAILED: $e');
      rethrow;
    }
  }

  Future<void> refresh() async => _loadAffirmations();
}

final todayAffirmationProvider = Provider<AsyncValue<AffirmationModel?>>((ref) {
  final affirmationsAsync = ref.watch(affirmationsProvider);
  return affirmationsAsync.when(
    data: (list) {
      if (list.isEmpty) return const AsyncValue.data(null);
      // Prioritize the latest synced affirmation by order desc and publishedAt desc
      final sorted = List<AffirmationModel>.from(list)
        ..sort((a, b) {
          final orderComp = b.order.compareTo(a.order);
          if (orderComp != 0) return orderComp;
          return b.publishedAt.compareTo(a.publishedAt);
        });
      return AsyncValue.data(sorted.first);
    },
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});

final todayAffirmationReadProvider =
    NotifierProvider<TodayAffirmationReadNotifier, bool>(
      TodayAffirmationReadNotifier.new,
    );

class TodayAffirmationReadNotifier extends Notifier<bool> {
  bool _disposed = false;

  @override
  bool build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Rebuild when the affirmation of the day changes.
    final todayAffId = ref.watch(todayAffirmationProvider).value?.id;
    if (todayAffId == null) return false;
    _load(todayAffId);
    return false;
  }

  String get _dateKey {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> _load(String todayAffId) async {
    final data = await CacheService.get(
      'affirmation_read_${_dateKey}_$todayAffId',
      (json) => json['read'] as bool,
    );
    if (_disposed) return;
    state = data ?? false;
  }

  Future<void> markAsRead() async {
    final todayAffId = ref.watch(todayAffirmationProvider).value?.id;
    if (todayAffId == null) return;
    await CacheService.set('affirmation_read_${_dateKey}_$todayAffId', {
      'read': true,
    }, ttl: const Duration(days: 2));
    state = true;
  }
}
