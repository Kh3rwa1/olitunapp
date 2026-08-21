import 'dart:convert';
import 'package:itun/core/logging/app_logger.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/appwrite_db_service.dart';
import '../../core/storage/cache_service.dart';
import '../models/content_models.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

final affirmationsProvider =
    StateNotifierProvider<
      AffirmationsNotifier,
      AsyncValue<List<AffirmationModel>>
    >((ref) {
      ref.watch(isAuthenticatedProvider);
      return AffirmationsNotifier(ref);
    });

class AffirmationsNotifier
    extends StateNotifier<AsyncValue<List<AffirmationModel>>> {
  AffirmationsNotifier(this.ref)
    : super(const AsyncValue.data(<AffirmationModel>[])) {
    _loadAffirmations();
  }

  final Ref ref;
  static const String _cacheKey = 'cached_daily_affirmations';

  Future<void> _loadAffirmations() async {
    final cached = await CacheService.getList(
      _cacheKey,
      AffirmationModel.fromJson,
    );
    if (!mounted) return;
    if (cached != null) {
      state = AsyncValue.data(cached);
    }

    try {
      final db = ref.read(appwriteDbServiceProvider);
      final data = await db.listDocuments(
        'daily_affirmations',
        queries: [Query.orderAsc('order'), Query.limit(500)],
      );
      if (!mounted) return;
      final affirmations = data.map(AffirmationModel.fromJson).toList();
      state = AsyncValue.data(affirmations);
      await CacheService.set(
        _cacheKey,
        affirmations.map((e) => e.toJson()).toList(),
      );
    } catch (e, stack) {
      AppLogger.debug('❌ load affirmations FAILED: $e');
      if (!mounted) return;
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
        } catch (_) {}
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
    StateNotifierProvider<TodayAffirmationReadNotifier, bool>((ref) {
      final todayAff = ref.watch(todayAffirmationProvider).value;
      return TodayAffirmationReadNotifier(ref, todayAff?.id);
    });

class TodayAffirmationReadNotifier extends StateNotifier<bool> {
  final Ref ref;
  final String? todayAffId;
  TodayAffirmationReadNotifier(this.ref, this.todayAffId) : super(false) {
    _load();
  }

  String get _dateKey {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> _load() async {
    if (todayAffId == null) return;
    final data = await CacheService.get(
      'affirmation_read_${_dateKey}_$todayAffId',
      (json) => json['read'] as bool,
    );
    state = data ?? false;
  }

  Future<void> markAsRead() async {
    if (todayAffId == null) return;
    await CacheService.set('affirmation_read_${_dateKey}_$todayAffId', {
      'read': true,
    }, ttl: const Duration(days: 2));
    state = true;
  }
}
