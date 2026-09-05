import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/core/payments/purchase_repository.dart';
import 'package:itun/features/admin/domain/admin_failure.dart';
import 'package:itun/features/admin/domain/purchase_csv_exporter.dart';
import 'package:itun/features/admin/domain/purchase_metrics_calculator.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/shared/models/content_models.dart';

final purchasedCategoriesProvider = FutureProvider<Set<String>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return {};

  ref.watch(entitlementRevisionProvider(user.id));
  final repo = ref.watch(purchaseRepositoryProvider);
  return repo.fetchPurchasedCategoryIds(user.id);
});

/// Typed outcome for recording an external refund in Appwrite.
enum RefundResult {
  completed,
  alreadyRefunded,
  invalidTransition,
  conflict,
  notFound,
  unauthorized,
  failed,
}

/// Deterministic operation key for recording an external refund.
///
/// Derived from (purchaseId, cumulative amount) so retries — including
/// across app restarts — reuse the same key and converge on the server
/// instead of creating duplicate operations. Under the server's max-floor
/// bookkeeping, identical inputs always produce identical ledger outcomes.
String adminRefundOperationKey(String purchaseId, int? amountPaise) {
  final amount = amountPaise == null ? 'full' : amountPaise.toString();
  return 'admin-record:$purchaseId:$amount';
}

/// Maps an admin-maintenance `record_refund` function response to a
/// [RefundResult]. Pure and unit-tested; the live call lives in
/// [AdminPurchasesNotifier.recordExternalRefund].
@visibleForTesting
RefundResult refundResultFromResponse({
  required int? statusCode,
  required Map<String, dynamic>? body,
}) {
  if (body != null) {
    if (body['success'] == true) {
      return body['alreadyRefunded'] == true
          ? RefundResult.alreadyRefunded
          : RefundResult.completed;
    }
    final message = body['message'];
    final text = message is String ? message : '';
    if (statusCode == 404 || text.contains('not found')) {
      return RefundResult.notFound;
    }
    if (statusCode == 403 || text.contains('Admin team membership')) {
      return RefundResult.unauthorized;
    }
    if (statusCode == 409 || text.contains('Idempotency conflict')) {
      // Same-key-different-params and already-recorded-under-another-
      // operation both surface here; both mean "do not retry blindly".
      return text.contains('Cannot refund purchase in status')
          ? RefundResult.invalidTransition
          : RefundResult.conflict;
    }
    if (text.contains('Cannot refund purchase in status')) {
      return RefundResult.invalidTransition;
    }
  }
  if (statusCode == 401 || statusCode == 403) {
    return RefundResult.unauthorized;
  }
  if (statusCode == 404) return RefundResult.notFound;
  return RefundResult.failed;
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
    NotifierProvider<AdminPurchasesNotifier, AdminPurchasesState>(
      AdminPurchasesNotifier.new,
    );

class AdminPurchasesNotifier extends Notifier<AdminPurchasesState> {
  bool _disposed = false;

  static const int pageSize = 50;
  static const int exportSafetyThreshold = 25000;
  int _generationCounter = 0;

  @override
  AdminPurchasesState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Deferred: `state` may not be read or written inside build().
    Future.microtask(loadPurchases);
    return const AdminPurchasesState(isLoading: true);
  }

  bool get isLoadingMore => state.isLoadingMore;
  bool get hasMore => state.hasMore;
  int get totalCount => state.totalLoaded;
  bool get isSampledOrPartial => state.isSampledOrPartial;
  String get currentFilter => state.activeFilter;
  String get currentSearch => state.searchQuery;

  /// Pure financial metrics calculated from current loaded items.
  PurchaseMetricsResult get currentMetrics => state.metrics;

  /// Canonical provider wins; legacy values apply only to unmigrated rows.
  String _providerFilter(String provider) {
    return Query.or([
      Query.equal('provider', provider),
      Query.and([
        Query.or([Query.isNull('provider'), Query.equal('provider', '')]),
        Query.equal('unlockMethod', provider),
      ]),
    ]);
  }

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
        Query.orderDesc('\$createdAt'),
        Query.limit(pageSize),
      ];

      // Status and canonical/legacy provider filtering
      if (newFilter == 'razorpay') {
        queries.add(_providerFilter('razorpay'));
        queries.add(Query.equal('status', 'verified'));
      } else if (newFilter == 'review') {
        queries.add(_providerFilter('play_store_review'));
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
      if (gen != _generationCounter || _disposed) return;

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
      if (gen != _generationCounter || _disposed) return;

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
        Query.orderDesc('\$createdAt'),
        Query.cursorAfter(cursor),
        Query.limit(pageSize),
      ];

      if (state.activeFilter == 'razorpay') {
        queries.add(_providerFilter('razorpay'));
        queries.add(Query.equal('status', 'verified'));
      } else if (state.activeFilter == 'review') {
        queries.add(_providerFilter('play_store_review'));
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

      if (gen != _generationCounter || _disposed) return;

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
      if (gen != _generationCounter || _disposed) return;

      final failure = AdminFailure.fromException(
        e,
        actionContext: 'Loading next purchases page',
      );
      AppLogger.debug('⚠️ loadNextPage failed: ${failure.sanitizedDetails}');
      // Preserves existing loaded items and keeps hasMore intact for retry
      state = state.copyWith(isLoadingMore: false, loadMoreFailure: failure);
    }
  }

  /// Records an external (gateway-issued) refund through the protected
  /// `admin-maintenance` server function (`record_refund` action).
  ///
  /// This is bookkeeping only: it records a refund already issued in the
  /// payment dashboard. It never moves money and never writes the ledger
  /// directly — all bookkeeping happens server-side under admin
  /// authorization with a durable operation identity.
  ///
  /// [operationKey] is the stable idempotency identity, created once per
  /// refund intent (see [adminRefundOperationKey]) and reused across
  /// retries, including across app restarts. [externalRefundId] is the
  /// optional informational gateway refund reference. [amountPaise] is the
  /// cumulative refunded total in paise (omit for a full refund).
  /// [executor] is a test seam; production always calls the function.
  Future<RefundResult> recordExternalRefund(
    String purchaseId, {
    String? operationKey,
    String? externalRefundId,
    String? reason,
    String? idempotencyKey,
    int? amountPaise,
    Future<Map<String, dynamic>> Function(Map<String, dynamic> payload)?
    executor,
  }) async {
    final key = (operationKey ?? idempotencyKey ?? '').trim();
    if (purchaseId.trim().isEmpty || key.isEmpty) {
      return RefundResult.failed;
    }
    try {
      final gateway = externalRefundId?.trim();
      final trimmedReason = reason?.trim();
      final payload = <String, dynamic>{
        'action': 'record_refund',
        'purchaseId': purchaseId.trim(),
        'operationKey': key,
        if (gateway != null && gateway.isNotEmpty) 'gatewayRefundId': gateway,
        if (amountPaise case final int amount) 'amountPaise': amount,
        if (trimmedReason != null && trimmedReason.isNotEmpty)
          'reason': trimmedReason,
      };
      final Map<String, dynamic> resBody;
      int? statusCode;
      if (executor != null) {
        final result = await executor(payload);
        resBody = result;
      } else {
        final client = ref.read(appwriteAuthServiceProvider).client;
        final functions = Functions(client);
        final execution = await functions.createExecution(
          functionId: 'admin-maintenance',
          body: jsonEncode(payload),
        );
        statusCode = execution.responseStatusCode;
        final decoded = jsonDecode(execution.responseBody);
        if (decoded is! Map<String, dynamic>) return RefundResult.failed;
        resBody = decoded;
      }
      final outcome = refundResultFromResponse(
        statusCode: statusCode,
        body: resBody,
      );
      if (outcome == RefundResult.completed ||
          outcome == RefundResult.alreadyRefunded) {
        await loadPurchases();
      }
      return outcome;
    } catch (e) {
      AppLogger.debug('recordExternalRefund failed: $e');
      if (e is AppwriteException) {
        return refundResultFromResponse(statusCode: e.code, body: null);
      }
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
        Query.orderDesc('\$createdAt'),
        Query.limit(pageSize),
      ];

      if (cursor != null) {
        queries.add(Query.cursorAfter(cursor));
      }

      if (effectiveFilter == 'razorpay') {
        queries.add(_providerFilter('razorpay'));
        queries.add(Query.equal('status', 'verified'));
      } else if (effectiveFilter == 'review') {
        queries.add(_providerFilter('play_store_review'));
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

  /// Backward-compatible alias. Generates a single-shot operation key, so
  /// callers that retry must use [recordExternalRefund] directly with a
  /// stable key instead of calling this alias repeatedly.
  Future<bool> refundPurchase(String purchaseId) async {
    final res = await recordExternalRefund(
      purchaseId,
      operationKey: adminRefundOperationKey(purchaseId, null),
    );
    return res == RefundResult.completed || res == RefundResult.alreadyRefunded;
  }
}
