import 'package:itun/core/logging/app_logger.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/appwrite_db_service.dart';
import '../../core/storage/cache_service.dart';
import '../models/content_models.dart';

final affirmationsProvider =
    StateNotifierProvider<
      AffirmationsNotifier,
      AsyncValue<List<AffirmationModel>>
    >(AffirmationsNotifier.new);

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
    if (cached != null) {
      state = AsyncValue.data(cached);
    }

    try {
      final db = ref.read(appwriteDbServiceProvider);
      final data = await db.listDocuments(
        'daily_affirmations',
        queries: [Query.orderAsc('order'), Query.limit(500)],
      );
      final affirmations = data.map(AffirmationModel.fromJson).toList();
      state = AsyncValue.data(affirmations);
      await CacheService.set(
        _cacheKey,
        affirmations.map((e) => e.toJson()).toList(),
      );
    } catch (e, stack) {
      AppLogger.debug('❌ load affirmations FAILED: $e');
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

  Future<void> refresh() async => _loadAffirmations();
}

final todayAffirmationProvider = Provider<AsyncValue<AffirmationModel?>>((ref) {
  final affirmationsAsync = ref.watch(affirmationsProvider);
  return affirmationsAsync.when(
    data: (list) {
      if (list.isEmpty) return const AsyncValue.data(null);
      // Deterministic selection per day of year
      final now = DateTime.now();
      final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
      final selected = list[dayOfYear % list.length];
      return AsyncValue.data(selected);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

final todayAffirmationReadProvider =
    StateNotifierProvider<TodayAffirmationReadNotifier, bool>((ref) {
      final notifier = TodayAffirmationReadNotifier(ref);
      ref.listen(todayAffirmationProvider, (prev, next) {
        notifier._load();
      });
      return notifier;
    });

class TodayAffirmationReadNotifier extends StateNotifier<bool> {
  final Ref ref;
  TodayAffirmationReadNotifier(this.ref) : super(false) {
    _load();
  }

  String get _dateKey {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> _load() async {
    final todayAff = ref.read(todayAffirmationProvider).value;
    if (todayAff == null) return;
    final data = await CacheService.get(
      'affirmation_read_${_dateKey}_${todayAff.id}',
      (json) => json['read'] as bool,
    );
    state = data ?? false;
  }

  Future<void> markAsRead() async {
    final todayAff = ref.read(todayAffirmationProvider).value;
    if (todayAff == null) return;
    await CacheService.set('affirmation_read_${_dateKey}_${todayAff.id}', {
      'read': true,
    }, ttl: const Duration(days: 2));
    state = true;
  }
}
