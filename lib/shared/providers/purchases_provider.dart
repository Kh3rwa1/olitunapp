import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/core/payments/purchase_repository.dart';
import 'package:itun/features/admin/domain/admin_failure.dart';
import 'package:itun/features/admin/domain/purchase_metrics_calculator.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/shared/models/content_models.dart';

final purchasedCategoriesProvider = FutureProvider<Set<String>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return {};

  final repo = ref.watch(purchaseRepositoryProvider);
  return repo.fetchPurchasedCategoryIds(user.id);
});

final adminPurchasesProvider =
    StateNotifierProvider<
      AdminPurchasesNotifier,
      AsyncValue<List<PurchaseModel>>
    >((ref) {
      return AdminPurchasesNotifier(ref);
    });

class AdminPurchasesNotifier
    extends StateNotifier<AsyncValue<List<PurchaseModel>>> {
  final Ref ref;

  static const int pageSize = 50;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _lastDocId;
  String _currentFilter = 'all';
  String _currentSearch = '';
  int _totalCount = 0;
  bool _isSampledOrPartial = false;

  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  int get totalCount => _totalCount;
  bool get isSampledOrPartial => _isSampledOrPartial;
  String get currentFilter => _currentFilter;
  String get currentSearch => _currentSearch;

  AdminPurchasesNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadPurchases();
  }

  /// Calculates pure financial metrics from the currently loaded purchase items.
  PurchaseMetricsResult get currentMetrics {
    final list = state.value ?? [];
    return PurchaseMetricsCalculator.calculate(
      list,
      isSampledOrPartial: _isSampledOrPartial,
    );
  }

  /// Initial or refreshed loading of purchases.
  Future<void> loadPurchases({String? filter, String? search}) async {
    try {
      if (!mounted) return;
      state = const AsyncValue.loading();
      _isLoadingMore = false;
      _hasMore = true;
      _lastDocId = null;

      if (filter != null) _currentFilter = filter;
      if (search != null) _currentSearch = search.trim();

      final db = ref.read(appwriteDbServiceProvider);
      final queries = <String>[
        Query.orderDesc('purchasedAt'),
        Query.limit(pageSize),
      ];

      // Server-side status / unlockMethod filters
      if (_currentFilter == 'razorpay') {
        queries.add(Query.equal('unlockMethod', 'razorpay'));
        queries.add(Query.equal('status', 'verified'));
      } else if (_currentFilter == 'review') {
        queries.add(Query.equal('unlockMethod', 'play_store_review'));
      } else if (_currentFilter == 'refunded') {
        queries.add(Query.equal('status', 'refunded'));
      }

      // Server-side search filter if query is provided
      if (_currentSearch.isNotEmpty) {
        queries.add(Query.search('categoryId', _currentSearch));
      }

      final result = await db.listDocuments(
        'course_purchases',
        queries: queries,
      );

      if (!mounted) return;
      final list = result.map(PurchaseModel.fromJson).toList();

      if (list.isNotEmpty) {
        _lastDocId = list.last.id;
      }
      _hasMore = list.length >= pageSize;
      _totalCount = list.length;
      _isSampledOrPartial = _hasMore;

      state = AsyncValue.data(list);
    } catch (e, stack) {
      final failure = AdminFailure.fromException(
        e,
        actionContext: 'Loading purchases',
      );
      AppLogger.debug('❌ loadPurchases failed: ${failure.sanitizedDetails}');
      if (!mounted) return;
      state = AsyncValue.error(failure, stack);
    }
  }

  /// Loads subsequent page using cursor-based pagination.
  Future<void> loadNextPage() async {
    if (_isLoadingMore || !_hasMore || _lastDocId == null) return;
    _isLoadingMore = true;

    try {
      final db = ref.read(appwriteDbServiceProvider);
      final queries = <String>[
        Query.orderDesc('purchasedAt'),
        Query.cursorAfter(_lastDocId!),
        Query.limit(pageSize),
      ];

      if (_currentFilter == 'razorpay') {
        queries.add(Query.equal('unlockMethod', 'razorpay'));
        queries.add(Query.equal('status', 'verified'));
      } else if (_currentFilter == 'review') {
        queries.add(Query.equal('unlockMethod', 'play_store_review'));
      } else if (_currentFilter == 'refunded') {
        queries.add(Query.equal('status', 'refunded'));
      }

      if (_currentSearch.isNotEmpty) {
        queries.add(Query.search('categoryId', _currentSearch));
      }

      final result = await db.listDocuments(
        'course_purchases',
        queries: queries,
      );

      if (!mounted) return;
      final newItems = result.map(PurchaseModel.fromJson).toList();

      if (newItems.isNotEmpty) {
        _lastDocId = newItems.last.id;
      }
      _hasMore = newItems.length >= pageSize;

      final existing = state.value ?? [];
      final existingIds = existing.map((p) => p.id).toSet();
      final deduplicatedNew = newItems
          .where((p) => !existingIds.contains(p.id))
          .toList();

      final combined = [...existing, ...deduplicatedNew];
      _totalCount = combined.length;

      state = AsyncValue.data(combined);
    } catch (e) {
      final failure = AdminFailure.fromException(
        e,
        actionContext: 'Loading next purchases page',
      );
      AppLogger.debug('⚠️ loadNextPage failed: ${failure.sanitizedDetails}');
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Records an external refund in the Appwrite database and revokes course access.
  ///
  /// Truthful Mode B Status-Only Operation:
  /// Updates database record with status 'refunded', notes external refund reference,
  /// and clears client access cache. Does not execute payment gateway financial payouts.
  Future<void> recordExternalRefund(
    String purchaseId, {
    String? externalRefundId,
    String? reason,
  }) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);

      final updatePayload = <String, dynamic>{'status': 'refunded'};
      if (externalRefundId != null && externalRefundId.trim().isNotEmpty) {
        updatePayload['refundReference'] = externalRefundId.trim();
      }
      if (reason != null && reason.trim().isNotEmpty) {
        updatePayload['refundReason'] = reason.trim();
      }

      // Update purchase status on Appwrite
      await db.updateDocument('course_purchases', purchaseId, updatePayload);

      // Clear purchase cache so user loses access immediately
      final repo = ref.read(purchaseRepositoryProvider);
      await repo.clearAllCaches();

      // Reload purchases
      await loadPurchases();

      // Refresh purchased categories provider
      ref.invalidate(purchasedCategoriesProvider);
    } catch (e) {
      final failure = AdminFailure.fromException(
        e,
        actionContext: 'Recording purchase refund',
      );
      AppLogger.debug(
        '❌ recordExternalRefund failed: ${failure.sanitizedDetails}',
      );
      rethrow;
    }
  }

  /// Backward-compatible alias to recordExternalRefund
  Future<void> refundPurchase(String purchaseId) =>
      recordExternalRefund(purchaseId);
}
