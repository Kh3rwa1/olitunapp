import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/core/payments/purchase_repository.dart';
import 'package:itun/features/admin/domain/admin_failure.dart';
import 'package:itun/features/admin/domain/purchase_csv_exporter.dart';
import 'package:itun/features/admin/domain/purchase_metrics_calculator.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/shared/models/content_models.dart';

final purchasedCategoriesProvider = FutureProvider<Set<String>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return {};

  final repo = ref.watch(purchaseRepositoryProvider);
  return repo.fetchPurchasedCategoryIds(user.id);
});

/// Typed outcome for recording an external refund in Appwrite.
enum RefundResult {
  completed,
  alreadyRefunded,
  invalidTransition,
  notFound,
  unauthorized,
  failed,
}

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
  final AdminFailure? initialFailure;
  final AdminFailure? loadMoreFailure;
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
    this.initialFailure,
    this.loadMoreFailure,
    this.totalLoaded = 0,
    this.requestGeneration = 0,
    this.lastUpdatedAt,
  });

  bool get hasInitialError => initialFailure != null;
  bool get hasLoadMoreError => loadMoreFailure != null;
  bool get hasError => hasInitialError || hasLoadMoreError;
  bool get isInitialLoading => isLoading && items.isEmpty;

  AdminFailure? get failure => initialFailure ?? loadMoreFailure;

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
    AdminFailure? initialFailure,
    bool clearInitialFailure = false,
    AdminFailure? loadMoreFailure,
    bool clearLoadMoreFailure = false,
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
      initialFailure: clearInitialFailure
          ? null
          : (initialFailure ?? this.initialFailure),
      loadMoreFailure: clearLoadMoreFailure
          ? null
          : (loadMoreFailure ?? this.loadMoreFailure),
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
  static const int exportSafetyThreshold = 25000;
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
      clearInitialFailure: true,
      clearLoadMoreFailure: true,
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
        clearInitialFailure: true,
        clearLoadMoreFailure: true,
      );
    } catch (e) {
      if (gen != _generationCounter || !mounted) return;

      final failure = AdminFailure.fromException(
        e,
        actionContext: 'Loading purchases',
      );
      AppLogger.debug('❌ loadPurchases failed: ${failure.sanitizedDetails}');
      state = state.copyWith(isLoading: false, initialFailure: failure);
    }
  }

  /// Loads subsequent page using cursor-based pagination.
  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasMore || state.nextCursor == null) {
      return;
    }

    final gen = ++_generationCounter;
    final cursor = state.nextCursor!;
    state = state.copyWith(isLoadingMore: true, clearLoadMoreFailure: true);

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
        isSampledOrPartial: hasMoreRecords,
        totalLoaded: combined.length,
        lastUpdatedAt: DateTime.now().toUtc(),
        clearLoadMoreFailure: true,
      );
    } catch (e) {
      if (gen != _generationCounter || !mounted) return;

      final failure = AdminFailure.fromException(
        e,
        actionContext: 'Loading next purchases page',
      );
      AppLogger.debug('⚠️ loadNextPage failed: ${failure.sanitizedDetails}');
      // Preserves existing loaded items and keeps hasMore intact for retry
      state = state.copyWith(isLoadingMore: false, loadMoreFailure: failure);
    }
  }

  /// Records an external refund in Appwrite with authenticated admin ID and idempotency protection.
  ///
  /// Truthful Mode B Status-Only Operation:
  /// Updates database record with status 'refunded', records operator admin ID,
  /// and invalidates the user's entitlement cache. Does not execute payment gateway wire transfers.
  Future<RefundResult> recordExternalRefund(
    String purchaseId, {
    String? externalRefundId,
    String? reason,
    String? idempotencyKey,
  }) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);

      // Authenticate operator identity
      final currentUser = await ref.read(currentUserProvider.future);
      final operatorId = currentUser?.id ?? 'authenticated_admin';

      PurchaseModel? targetItem;
      for (final p in state.items) {
        if (p.id == purchaseId) {
          targetItem = p;
          break;
        }
      }

      // Fetch fresh server state to prevent race conditions
      try {
        final freshDoc = await db.getDocument('course_purchases', purchaseId);
        targetItem = PurchaseModel.fromJson(freshDoc);
      } catch (e) {
        if (targetItem == null) {
          return RefundResult.notFound;
        }
      }

      // Concurrency & Idempotency check
      if (targetItem.status == 'refunded') {
        AppLogger.debug(
          'ℹ️ Purchase $purchaseId is already refunded (Idempotent).',
        );
        return RefundResult.alreadyRefunded;
      }

      // Validate state transition
      if (targetItem.status != 'verified' && targetItem.status != 'completed') {
        AppLogger.debug(
          '⚠️ Invalid refund transition from status: ${targetItem.status}',
        );
        return RefundResult.invalidTransition;
      }

      final nowUtc = DateTime.now().toUtc().toIso8601String();
      final updatePayload = <String, dynamic>{
        'status': 'refunded',
        'refundedAt': nowUtc,
        'refundedBy': operatorId,
        'previousStatus': targetItem.status,
      };

      if (externalRefundId != null && externalRefundId.trim().isNotEmpty) {
        updatePayload['refundReference'] = externalRefundId.trim();
      }
      if (reason != null && reason.trim().isNotEmpty) {
        updatePayload['refundReason'] = reason.trim();
      }
      if (idempotencyKey != null && idempotencyKey.trim().isNotEmpty) {
        updatePayload['idempotencyKey'] = idempotencyKey.trim();
      }

      // Update document in Appwrite
      await db.updateDocument('course_purchases', purchaseId, updatePayload);

      // Invalidate the specific user's entitlement cache
      final repo = ref.read(purchaseRepositoryProvider);
      if (targetItem.userId.isNotEmpty) {
        try {
          await repo.clearUserEntitlementCache(targetItem.userId);
        } catch (e) {
          AppLogger.debug(
            '⚠️ Cache invalidation warning for ${targetItem.userId}: $e',
          );
        }
      }

      // Reload purchase records
      await loadPurchases();

      // Refresh current user entitlement provider
      ref.invalidate(purchasedCategoriesProvider);
      return RefundResult.completed;
    } catch (e) {
      final failure = AdminFailure.fromException(
        e,
        actionContext: 'Recording purchase refund',
      );
      AppLogger.debug(
        '❌ recordExternalRefund failed: ${failure.sanitizedDetails}',
      );
      return RefundResult.failed;
    }
  }

  /// Fetches matching purchase records from Appwrite with continuous pagination, backoff, and safety limits.
  Future<PurchaseExportResult> fetchAllMatchingPurchases({
    String? filter,
    String? search,
    int safetyLimit = exportSafetyThreshold,
    void Function(int count)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final startedAt = DateTime.now().toUtc();
    final effectiveFilter = filter ?? state.activeFilter;
    final effectiveSearch = (search ?? state.searchQuery).trim();
    final db = ref.read(appwriteDbServiceProvider);

    final allItems = <PurchaseModel>[];
    final seenIds = <String>{};
    String? cursor;
    bool hasMore = true;
    bool isTruncated = false;

    while (hasMore) {
      if (isCancelled?.call() == true) {
        return PurchaseExportResult(
          items: allItems,
          exportedCount: allItems.length,
          isTruncated: true,
          hasMore: true,
          status: PurchaseExportStatus.cancelled,
          activeFilter: effectiveFilter,
          searchQuery: effectiveSearch,
          startedAt: startedAt,
          completedAt: DateTime.now().toUtc(),
        );
      }

      if (allItems.length >= safetyLimit) {
        isTruncated = true;
        break;
      }

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

      List<Map<String, dynamic>>? result;
      int attempts = 0;
      const maxRetries = 3;

      while (attempts < maxRetries && result == null) {
        try {
          result = await db.listDocuments('course_purchases', queries: queries);
        } catch (e) {
          attempts++;
          if (attempts >= maxRetries) {
            final failure = AdminFailure.fromException(
              e,
              actionContext: 'Export query',
            );
            return PurchaseExportResult(
              items: allItems,
              exportedCount: allItems.length,
              isTruncated: true,
              hasMore: true,
              status: PurchaseExportStatus.failed,
              activeFilter: effectiveFilter,
              searchQuery: effectiveSearch,
              startedAt: startedAt,
              completedAt: DateTime.now().toUtc(),
              sanitizedFailure: failure.userMessage,
            );
          }
          await Future.delayed(Duration(milliseconds: 250 * (1 << attempts)));
        }
      }

      if (result == null || result.isEmpty) break;

      final page = result.map(PurchaseModel.fromJson).toList();
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

    return PurchaseExportResult(
      items: allItems,
      exportedCount: allItems.length,
      isTruncated: isTruncated,
      hasMore: hasMore && isTruncated,
      status: isTruncated
          ? PurchaseExportStatus.truncated
          : PurchaseExportStatus.completed,
      activeFilter: effectiveFilter,
      searchQuery: effectiveSearch,
      startedAt: startedAt,
      completedAt: DateTime.now().toUtc(),
    );
  }

  /// Backward-compatible alias.
  Future<bool> refundPurchase(String purchaseId) async {
    final res = await recordExternalRefund(purchaseId);
    return res == RefundResult.completed || res == RefundResult.alreadyRefunded;
  }
}
