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
  return ref.watch(purchaseRepositoryProvider).fetchPurchasedCategoryIds(user.id);
});

enum RefundResult { completed, alreadyRefunded, invalidTransition, notFound, unauthorized, failed }

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
    this.items = const [], this.isLoading = false, this.isLoadingMore = false,
    this.hasMore = false, this.nextCursor, this.isSampledOrPartial = false,
    this.activeFilter = 'all', this.searchQuery = '', this.initialFailure,
    this.loadMoreFailure, this.totalLoaded = 0, this.requestGeneration = 0,
    this.lastUpdatedAt,
  });

  bool get hasInitialError => initialFailure != null;
  bool get hasLoadMoreError => loadMoreFailure != null;
  bool get hasError => hasInitialError || hasLoadMoreError;
  bool get isInitialLoading => isLoading && items.isEmpty;
  AdminFailure? get failure => initialFailure ?? loadMoreFailure;
  PurchaseMetricsResult get metrics => PurchaseMetricsCalculator.calculate(items, isSampledOrPartial: isSampledOrPartial);

  AdminPurchasesState copyWith({
    List<PurchaseModel>? items, bool? isLoading, bool? isLoadingMore,
    bool? hasMore, String? nextCursor, bool clearNextCursor = false,
    bool? isSampledOrPartial, String? activeFilter, String? searchQuery,
    AdminFailure? initialFailure, bool clearInitialFailure = false,
    AdminFailure? loadMoreFailure, bool clearLoadMoreFailure = false,
    int? totalLoaded, int? requestGeneration, DateTime? lastUpdatedAt,
  }) => AdminPurchasesState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
    nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
    isSampledOrPartial: isSampledOrPartial ?? this.isSampledOrPartial,
    activeFilter: activeFilter ?? this.activeFilter,
    searchQuery: searchQuery ?? this.searchQuery,
    initialFailure: clearInitialFailure ? null : (initialFailure ?? this.initialFailure),
    loadMoreFailure: clearLoadMoreFailure ? null : (loadMoreFailure ?? this.loadMoreFailure),
    totalLoaded: totalLoaded ?? this.totalLoaded,
    requestGeneration: requestGeneration ?? this.requestGeneration,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
  );
}

final adminPurchasesProvider = NotifierProvider<AdminPurchasesNotifier, AdminPurchasesState>(AdminPurchasesNotifier.new);

class AdminPurchasesNotifier extends Notifier<AdminPurchasesState> {
  bool _disposed = false;
  static const int pageSize = 50;
  static const int exportSafetyThreshold = 25000;
  int _generationCounter = 0;

  @override
  AdminPurchasesState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    Future.microtask(loadPurchases);
    return const AdminPurchasesState(isLoading: true);
  }

  bool get isLoadingMore => state.isLoadingMore;
  bool get hasMore => state.hasMore;
  int get totalCount => state.totalLoaded;
  bool get isSampledOrPartial => state.isSampledOrPartial;
  String get currentFilter => state.activeFilter;
  String get currentSearch => state.searchQuery;
  PurchaseMetricsResult get currentMetrics => state.metrics;

  List<String> _queries({required String filter, required String search, String? cursor}) {
    final queries = <String>[Query.orderDesc('\$createdAt'), Query.limit(pageSize)];
    if (cursor != null) queries.add(Query.cursorAfter(cursor));

    if (filter == 'razorpay') {
      queries.add(Query.or([
        Query.equal('provider', 'razorpay'),
        Query.equal('unlockMethod', 'razorpay'),
      ]));
      queries.add(Query.equal('status', 'verified'));
    } else if (filter == 'review') {
      queries.add(Query.or([
        Query.equal('provider', 'play_store_review'),
        Query.equal('unlockMethod', 'play_store_review'),
      ]));
    } else if (filter == 'refunded') {
      queries.add(Query.equal('status', 'refunded'));
    }
    if (search.isNotEmpty) queries.add(Query.search('categoryId', search));
    return queries;
  }

  Future<void> loadPurchases({String? filter, String? search}) async {
    final gen = ++_generationCounter;
    final newFilter = filter ?? state.activeFilter;
    final newSearch = (search ?? state.searchQuery).trim();
    state = state.copyWith(isLoading: true, clearInitialFailure: true, clearLoadMoreFailure: true, activeFilter: newFilter, searchQuery: newSearch, clearNextCursor: true, requestGeneration: gen);
    try {
      final result = await ref.read(appwriteDbServiceProvider).listDocuments('course_purchases', queries: _queries(filter: newFilter, search: newSearch));
      if (gen != _generationCounter || _disposed) return;
      final list = result.map(PurchaseModel.fromJson).toList();
      final more = list.length >= pageSize;
      final cursor = list.isEmpty ? null : list.last.id;
      state = state.copyWith(items: list, isLoading: false, hasMore: more, nextCursor: cursor, clearNextCursor: cursor == null, isSampledOrPartial: more, totalLoaded: list.length, lastUpdatedAt: DateTime.now().toUtc(), clearInitialFailure: true, clearLoadMoreFailure: true);
    } catch (e) {
      if (gen != _generationCounter || _disposed) return;
      final failure = AdminFailure.fromException(e, actionContext: 'Loading purchases');
      AppLogger.debug('❌ loadPurchases failed: ${failure.sanitizedDetails}');
      state = state.copyWith(isLoading: false, initialFailure: failure);
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasMore || state.nextCursor == null) return;
    final gen = ++_generationCounter;
    final cursor = state.nextCursor!;
    state = state.copyWith(isLoadingMore: true, clearLoadMoreFailure: true);
    try {
      final result = await ref.read(appwriteDbServiceProvider).listDocuments('course_purchases', queries: _queries(filter: state.activeFilter, search: state.searchQuery, cursor: cursor));
      if (gen != _generationCounter || _disposed) return;
      final page = result.map(PurchaseModel.fromJson).toList();
      final ids = state.items.map((p) => p.id).toSet();
      final combined = [...state.items, ...page.where((p) => !ids.contains(p.id))];
      final next = page.isEmpty ? null : page.last.id;
      final more = page.length >= pageSize;
      state = state.copyWith(items: combined, isLoadingMore: false, hasMore: more, nextCursor: next, clearNextCursor: next == null, isSampledOrPartial: more, totalLoaded: combined.length, lastUpdatedAt: DateTime.now().toUtc(), clearLoadMoreFailure: true);
    } catch (e) {
      if (gen != _generationCounter || _disposed) return;
      final failure = AdminFailure.fromException(e, actionContext: 'Loading next purchases page');
      AppLogger.debug('⚠️ loadNextPage failed: ${failure.sanitizedDetails}');
      state = state.copyWith(isLoadingMore: false, loadMoreFailure: failure);
    }
  }

  Future<RefundResult> recordExternalRefund(String purchaseId, {String? externalRefundId, String? reason, String? idempotencyKey}) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      final currentUser = await ref.read(currentUserProvider.future);
      final operatorId = currentUser?.id ?? 'authenticated_admin';
      PurchaseModel? target;
      for (final item in state.items) { if (item.id == purchaseId) { target = item; break; } }
      try { target = PurchaseModel.fromJson(await db.getDocument('course_purchases', purchaseId)); } catch (_) { if (target == null) return RefundResult.notFound; }
      if (target.status == 'refunded') return RefundResult.alreadyRefunded;
      if (target.status != 'verified' && target.status != 'completed') return RefundResult.invalidTransition;
      final payload = <String, dynamic>{'status': 'refunded', 'refundedAt': DateTime.now().toUtc().toIso8601String(), 'refundedBy': operatorId, 'previousStatus': target.status};
      if (externalRefundId?.trim().isNotEmpty == true) payload['refundReference'] = externalRefundId!.trim();
      if (reason?.trim().isNotEmpty == true) payload['refundReason'] = reason!.trim();
      if (idempotencyKey?.trim().isNotEmpty == true) payload['idempotencyKey'] = idempotencyKey!.trim();
      await db.updateDocument('course_purchases', purchaseId, payload);
      if (target.userId.isNotEmpty) {
        try { await ref.read(purchaseRepositoryProvider).clearUserEntitlementCache(target.userId); } catch (e) { AppLogger.debug('⚠️ Cache invalidation failed: $e'); }
      }
      await loadPurchases();
      ref.invalidate(purchasedCategoriesProvider);
      return RefundResult.completed;
    } catch (e) {
      final failure = AdminFailure.fromException(e, actionContext: 'Recording purchase refund');
      AppLogger.debug('❌ recordExternalRefund failed: ${failure.sanitizedDetails}');
      return RefundResult.failed;
    }
  }

  Future<PurchaseExportResult> fetchAllMatchingPurchases({String? filter, String? search, int safetyLimit = exportSafetyThreshold, void Function(int count)? onProgress, bool Function()? isCancelled}) async {
    final started = DateTime.now().toUtc();
    final effectiveFilter = filter ?? state.activeFilter;
    final effectiveSearch = (search ?? state.searchQuery).trim();
    final db = ref.read(appwriteDbServiceProvider);
    final items = <PurchaseModel>[];
    final seen = <String>{};
    String? cursor;
    var more = true;
    var truncated = false;
    while (more) {
      if (isCancelled?.call() == true) return PurchaseExportResult(items: items, exportedCount: items.length, isTruncated: true, hasMore: true, status: PurchaseExportStatus.cancelled, activeFilter: effectiveFilter, searchQuery: effectiveSearch, startedAt: started, completedAt: DateTime.now().toUtc());
      if (items.length >= safetyLimit) { truncated = true; break; }
      List<Map<String, dynamic>>? result;
      Object? lastError;
      for (var attempt = 0; attempt < 3 && result == null; attempt++) {
        try { result = await db.listDocuments('course_purchases', queries: _queries(filter: effectiveFilter, search: effectiveSearch, cursor: cursor)); }
        catch (e) { lastError = e; if (attempt < 2) await Future.delayed(Duration(milliseconds: 250 * (1 << (attempt + 1)))); }
      }
      if (result == null) {
        final failure = AdminFailure.fromException(lastError!, actionContext: 'Export query');
        return PurchaseExportResult(items: items, exportedCount: items.length, isTruncated: true, hasMore: true, status: PurchaseExportStatus.failed, activeFilter: effectiveFilter, searchQuery: effectiveSearch, startedAt: started, completedAt: DateTime.now().toUtc(), sanitizedFailure: failure.userMessage);
      }
      if (result.isEmpty) break;
      final page = result.map(PurchaseModel.fromJson).toList();
      cursor = page.last.id;
      more = page.length >= pageSize;
      for (final item in page) { if (seen.add(item.id)) items.add(item); }
      onProgress?.call(items.length);
    }
    return PurchaseExportResult(items: items, exportedCount: items.length, isTruncated: truncated, hasMore: more && truncated, status: truncated ? PurchaseExportStatus.truncated : PurchaseExportStatus.completed, activeFilter: effectiveFilter, searchQuery: effectiveSearch, startedAt: started, completedAt: DateTime.now().toUtc());
  }

  Future<bool> refundPurchase(String purchaseId) async {
    final result = await recordExternalRefund(purchaseId);
    return result == RefundResult.completed || result == RefundResult.alreadyRefunded;
  }
}
