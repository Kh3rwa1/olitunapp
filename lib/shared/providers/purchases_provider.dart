import 'package:flutter/foundation.dart';
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

/// Immutable state model for the Admin Purchases & Revenue module.
@immutable
class AdminPurchasesState {
  final List<PurchaseModel> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? nextCursor;
  final bool isSampledOrPartial;
  final String activeFilter;
  final String searchQuery;
  final AdminFailure? failure;
  final int totalLoaded;
  final int requestGeneration;
  final DateTime? lastUpdatedAt;

  const AdminPurchasesState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.nextCursor,
    this.isSampledOrPartial = false,
    this.activeFilter = 'all',
    this.searchQuery = '',
    this.failure,
    this.totalLoaded = 0,
    this.requestGeneration = 0,
    this.lastUpdatedAt,
  });

  bool get hasError => failure != null;
  bool get isInitialLoading => isLoading && items.isEmpty;

  PurchaseMetricsResult get metrics => PurchaseMetricsCalculator.calculate(
    items,
    isSampledOrPartial: isSampledOrPartial,
  );

  AdminPurchasesState copyWith({
    List<PurchaseModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isSampledOrPartial,
    String? activeFilter,
    String? searchQuery,
    AdminFailure? failure,
    bool clearFailure = false,
    int? totalLoaded,
    int? requestGeneration,
    DateTime? lastUpdatedAt,
  }) {
    return AdminPurchasesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      isSampledOrPartial: isSampledOrPartial ?? this.isSampledOrPartial,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      failure: clearFailure ? null : (failure ?? this.failure),
      totalLoaded: totalLoaded ?? this.totalLoaded,
      requestGeneration: requestGeneration ?? this.requestGeneration,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

final adminPurchasesProvider =
    StateNotifierProvider<AdminPurchasesNotifier, AdminPurchasesState>((ref) {
      return AdminPurchasesNotifier(ref);
    });

class AdminPurchasesNotifier extends StateNotifier<AdminPurchasesState> {
  final Ref ref;

  static const int pageSize = 50;
  int _generationCounter = 0;

  bool get isLoadingMore => state.isLoadingMore;
  bool get hasMore => state.hasMore;
  int get totalCount => state.totalLoaded;
  bool get isSampledOrPartial => state.isSampledOrPartial;
  String get currentFilter => state.activeFilter;
  String get currentSearch => state.searchQuery;

  AdminPurchasesNotifier(this.ref)
    : super(const AdminPurchasesState(isLoading: true)) {
    loadPurchases();
  }

  /// Pure financial metrics calculated from current loaded items.
  PurchaseMetricsResult get currentMetrics => state.metrics;

  /// Loads initial page with optional server-side filter and search query.
  Future<void> loadPurchases({String? filter, String? search}) async {
    final gen = ++_generationCounter;
    final newFilter = filter ?? state.activeFilter;
    final newSearch = (search ?? state.searchQuery).trim();

    state = state.copyWith(
      isLoading: true,
      clearFailure: true,
      activeFilter: newFilter,
      searchQuery: newSearch,
      clearNextCursor: true,
      requestGeneration: gen,
    );

    try {
      final db = ref.read(appwriteDbServiceProvider);
      final queries = <String>[
        Query.orderDesc('purchasedAt'),
        Query.limit(pageSize),
      ];

      // Status & unlockMethod filtering
      if (newFilter == 'razorpay') {
        queries.add(Query.equal('unlockMethod', 'razorpay'));
        queries.add(Query.equal('status', 'verified'));
      } else if (newFilter == 'review') {
        queries.add(Query.equal('unlockMethod', 'play_store_review'));
      } else if (newFilter == 'refunded') {
        queries.add(Query.equal('status', 'refunded'));
      }

      // Search filter
      if (newSearch.isNotEmpty) {
        queries.add(Query.search('categoryId', newSearch));
      }

      final result = await db.listDocuments(
        'course_purchases',
        queries: queries,
      );

      // Stale response protection: if a newer request was dispatched, discard this result
      if (gen != _generationCounter || !mounted) return;

      final list = result.map(PurchaseModel.fromJson).toList();
      final hasMoreRecords = list.length >= pageSize;
      final nextCursor = list.isNotEmpty ? list.last.id : null;

      state = state.copyWith(
        items: list,
        isLoading: false,
        hasMore: hasMoreRecords,
        nextCursor: nextCursor,
        clearNextCursor: nextCursor == null,
        isSampledOrPartial: hasMoreRecords,
        totalLoaded: list.length,
        lastUpdatedAt: DateTime.now().toUtc(),
        clearFailure: true,
      );
    } catch (e) {
      if (gen != _generationCounter || !mounted) return;

      final failure = AdminFailure.fromException(
        e,
        actionContext: 'Loading purchases',
      );
      AppLogger.debug('❌ loadPurchases failed: ${failure.sanitizedDetails}');
      state = state.copyWith(isLoading: false, failure: failure);
    }
  }

  /// Loads subsequent page using cursor-based pagination.
  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasMore || state.nextCursor == null) {
      return;
    }

    final gen = ++_generationCounter;
    final cursor = state.nextCursor!;
    state = state.copyWith(isLoadingMore: true, clearFailure: true);

    try {
      final db = ref.read(appwriteDbServiceProvider);
      final queries = <String>[
        Query.orderDesc('purchasedAt'),
        Query.cursorAfter(cursor),
        Query.limit(pageSize),
      ];

      if (state.activeFilter == 'razorpay') {
        queries.add(Query.equal('unlockMethod', 'razorpay'));
        queries.add(Query.equal('status', 'verified'));
      } else if (state.activeFilter == 'review') {
        queries.add(Query.equal('unlockMethod', 'play_store_review'));
      } else if (state.activeFilter == 'refunded') {
        queries.add(Query.equal('status', 'refunded'));
      }

      if (state.searchQuery.isNotEmpty) {
        queries.add(Query.search('categoryId', state.searchQuery));
      }

      final result = await db.listDocuments(
        'course_purchases',
        queries: queries,
      );

      if (gen != _generationCounter || !mounted) return;

      final newItems = result.map(PurchaseModel.fromJson).toList();
      final hasMoreRecords = newItems.length >= pageSize;
      final nextCursor = newItems.isNotEmpty ? newItems.last.id : null;

      final existingIds = state.items.map((p) => p.id).toSet();
      final deduplicatedNew = newItems
          .where((p) => !existingIds.contains(p.id))
          .toList();

      final combined = [...state.items, ...deduplicatedNew];

      state = state.copyWith(
        items: combined,
        isLoadingMore: false,
        hasMore: hasMoreRecords,
        nextCursor: nextCursor,
        clearNextCursor: nextCursor == null,
        // Crucial fix: recompute isSampledOrPartial so reaching the final page marks dataset complete
        isSampledOrPartial: hasMoreRecords,
        totalLoaded: combined.length,
        lastUpdatedAt: DateTime.now().toUtc(),
        clearFailure: true,
      );
    } catch (e) {
      if (gen != _generationCounter || !mounted) return;

      final failure = AdminFailure.fromException(
        e,
        actionContext: 'Loading next purchases page',
      );
      AppLogger.debug('⚠️ loadNextPage failed: ${failure.sanitizedDetails}');
      // Preserve existing loaded items on load-more error
      state = state.copyWith(isLoadingMore: false, failure: failure);
    }
  }

  /// Records an external refund in the Appwrite database and revokes course access.
  ///
  /// Truthful Mode B Status-Only Operation:
  /// Updates database record with status 'refunded', notes external refund reference,
  /// and invalidates the user's entitlement cache. Does not execute payment gateway wire transfers.
  Future<bool> recordExternalRefund(
    String purchaseId, {
    String? externalRefundId,
    String? reason,
  }) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);

      PurchaseModel? targetItem;
      for (final p in state.items) {
        if (p.id == purchaseId) {
          targetItem = p;
          break;
        }
      }

      // If already marked as refunded, return idempotently
      if (targetItem != null && targetItem.status == 'refunded') {
        AppLogger.debug('ℹ️ Purchase $purchaseId is already refunded.');
        return true;
      }

      if (targetItem == null) {
        try {
          final doc = await db.getDocument('course_purchases', purchaseId);
          targetItem = PurchaseModel.fromJson(doc);
          if (targetItem.status == 'refunded') {
            return true;
          }
        } catch (_) {
          // Proceed with update
        }
      }

      final nowUtc = DateTime.now().toUtc().toIso8601String();
      final updatePayload = <String, dynamic>{
        'status': 'refunded',
        'refundedAt': nowUtc,
        'refundedBy': 'admin',
        if (targetItem != null) 'previousStatus': targetItem.status,
      };

      if (externalRefundId != null && externalRefundId.trim().isNotEmpty) {
        updatePayload['refundReference'] = externalRefundId.trim();
      }
      if (reason != null && reason.trim().isNotEmpty) {
        updatePayload['refundReason'] = reason.trim();
      }

      // Update purchase status in Appwrite
      await db.updateDocument('course_purchases', purchaseId, updatePayload);

      // Invalidate the specific user's entitlement cache
      final repo = ref.read(purchaseRepositoryProvider);
      if (targetItem != null && targetItem.userId.isNotEmpty) {
        await repo.clearUserEntitlementCache(targetItem.userId);
      }

      // Reload purchases table
      await loadPurchases();

      // Refresh currentUser entitlement provider
      ref.invalidate(purchasedCategoriesProvider);
      return true;
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

  /// Fetches all matching purchase records from Appwrite via cursor loop for full export.
  Future<List<PurchaseModel>> fetchAllMatchingPurchases({
    String? filter,
    String? search,
    int maxLimit = 5000,
    void Function(int count)? onProgress,
  }) async {
    final effectiveFilter = filter ?? state.activeFilter;
    final effectiveSearch = (search ?? state.searchQuery).trim();
    final db = ref.read(appwriteDbServiceProvider);

    final allItems = <PurchaseModel>[];
    final seenIds = <String>{};
    String? cursor;
    bool hasMore = true;

    while (hasMore && allItems.length < maxLimit) {
      final queries = <String>[
        Query.orderDesc('purchasedAt'),
        Query.limit(pageSize),
      ];

      if (cursor != null) {
        queries.add(Query.cursorAfter(cursor));
      }

      if (effectiveFilter == 'razorpay') {
        queries.add(Query.equal('unlockMethod', 'razorpay'));
        queries.add(Query.equal('status', 'verified'));
      } else if (effectiveFilter == 'review') {
        queries.add(Query.equal('unlockMethod', 'play_store_review'));
      } else if (effectiveFilter == 'refunded') {
        queries.add(Query.equal('status', 'refunded'));
      }

      if (effectiveSearch.isNotEmpty) {
        queries.add(Query.search('categoryId', effectiveSearch));
      }

      final result = await db.listDocuments(
        'course_purchases',
        queries: queries,
      );

      final page = result.map(PurchaseModel.fromJson).toList();
      if (page.isEmpty) break;

      cursor = page.last.id;
      hasMore = page.length >= pageSize;

      for (final item in page) {
        if (!seenIds.contains(item.id)) {
          seenIds.add(item.id);
          allItems.add(item);
        }
      }

      onProgress?.call(allItems.length);
    }

    return allItems;
  }

  /// Backward-compatible alias to recordExternalRefund.
  Future<void> refundPurchase(String purchaseId) =>
      recordExternalRefund(purchaseId);
}
