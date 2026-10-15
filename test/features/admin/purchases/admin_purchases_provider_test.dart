import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/api/admin_purchases_api.dart';
import 'package:itun/core/api/edge_json_client.dart';
import 'package:itun/core/api/appwrite_functions_service.dart';
import 'package:itun/core/payments/purchase_repository.dart';
import 'package:itun/features/admin/domain/purchase_csv_exporter.dart';
import 'package:itun/core/auth/user_entity.dart';
import 'package:itun/core/auth/auth_providers.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/features/admin/presentation/purchases/providers/admin_purchases_provider.dart';
import 'package:mocktail/mocktail.dart';

typedef _PageHandler = Future<AdminPurchasePage> Function(_PageRequest request);

class _PageRequest {
  _PageRequest(this.filter, this.search, this.cursor, this.limit, this.export);
  final String filter;
  final String search;
  final String? cursor;
  final int limit;
  final bool export;
}

/// Worker purchases API stand-in: records requests, answers via [handler].
class _FakePurchasesApi extends Fake implements AdminPurchasesApi {
  _PageHandler handler = (_) async =>
      const AdminPurchasePage(items: [], hasMore: false);
  final requests = <_PageRequest>[];

  @override
  Future<AdminPurchasePage> list({
    required String filter,
    String search = '',
    String? cursor,
    int limit = 50,
    bool export = false,
  }) {
    final request = _PageRequest(filter, search, cursor, limit, export);
    requests.add(request);
    return handler(request);
  }
}

AdminPurchasePage _page(
  List<Map<String, dynamic>> items, {
  bool hasMore = false,
  String? next,
}) => AdminPurchasePage(items: items, hasMore: hasMore, nextCursor: next);

class MockPurchaseRepository extends Mock implements PurchaseRepository {}

class MockAppwriteAuthService extends Mock implements AppwriteAuthService {}

void main() {
  late _FakePurchasesApi api;
  late MockPurchaseRepository mockRepo;

  setUp(() {
    api = _FakePurchasesApi();
    mockRepo = MockPurchaseRepository();
  });

  const testAdminUser = UserEntity(
    id: 'admin_usr_999',
    email: 'admin@olitun.com',
    name: 'Admin Operator',
    isEmailVerified: true,
  );

  ProviderContainer createContainer({UserEntity? operator = testAdminUser}) {
    final container = ProviderContainer(
      overrides: [
        adminPurchasesApiProvider.overrideWithValue(api),
        purchaseRepositoryProvider.overrideWithValue(mockRepo),
        isAuthenticatedProvider.overrideWith((ref) async => true),
        currentUserProvider.overrideWith((ref) async => operator),
      ],
    );
    // Pin the notifier instance for the duration of the test.
    container.listen(adminPurchasesProvider, (previous, next) {});
    container.read(adminPurchasesProvider.notifier);
    return container;
  }

  /// Waits for the build()-triggered initial load to settle.
  Future<void> waitForInitialLoad(ProviderContainer container) async {
    for (var i = 0; i < 100; i++) {
      await Future<void>.delayed(Duration.zero);
      if (!container.read(adminPurchasesProvider).isLoading) return;
    }
  }

  Map<String, dynamic> makePurchaseDoc({
    required String id,
    required String userId,
    required String categoryId,
    required String unlockMethod,
    required int amountPaidInr,
    required String status,
    String? paymentId,
  }) {
    return {
      '\$id': id,
      'userId': userId,
      'categoryId': categoryId,
      'unlockMethod': unlockMethod,
      'amountPaidInr': amountPaidInr,
      'status': status,
      'razorpayPaymentId': paymentId,
      'purchasedAt': '2026-08-21T10:00:00Z',
    };
  }

  List<Map<String, dynamic>> docs(String prefix, int count) => List.generate(
    count,
    (i) => makePurchaseDoc(
      id: '${prefix}_$i',
      userId: 'u_$i',
      categoryId: 'santali_basics',
      unlockMethod: 'razorpay',
      amountPaidInr: 299,
      status: 'verified',
      paymentId: 'pay_$i',
    ),
  );

  group(
    'AdminPurchasesNotifier - State, Pagination, Idempotency & Export Matrix',
    () {
      test(
        'Case 1: initial load reads the Worker list and computes metrics',
        () async {
          api.handler = (_) async => _page([
            makePurchaseDoc(
              id: 'p1',
              userId: 'u1',
              categoryId: 'santali_1',
              unlockMethod: 'razorpay',
              amountPaidInr: 299,
              status: 'verified',
              paymentId: 'pay_1',
            ),
            makePurchaseDoc(
              id: 'p2',
              userId: 'u2',
              categoryId: 'santali_2',
              unlockMethod: 'play_store_review',
              amountPaidInr: 0,
              status: 'verified',
            ),
          ]);

          final container = createContainer();
          addTearDown(container.dispose);
          await waitForInitialLoad(container);

          final state = container.read(adminPurchasesProvider);
          expect(state.isLoading, isFalse);
          expect(state.hasInitialError, isFalse);
          expect(state.hasLoadMoreError, isFalse);
          expect(state.items.length, 2);
          expect(state.hasMore, isFalse);
          expect(state.isSampledOrPartial, isFalse);
          expect(state.metrics.grossCollectedInr, 299);
          expect(state.metrics.netRevenueInr, 299);
          expect(state.metrics.activePaidCount, 1);
          expect(state.metrics.reviewUnlockCount, 1);
          final first = api.requests.single;
          expect(first.filter, 'all');
          expect(first.cursor, isNull);
          expect(first.limit, AdminPurchasesNotifier.pageSize);
          expect(first.export, isFalse);
        },
      );

      test('filters and search are sent to the Worker', () async {
        final container = createContainer();
        addTearDown(container.dispose);
        await waitForInitialLoad(container);

        await container
            .read(adminPurchasesProvider.notifier)
            .loadPurchases(filter: 'refunded', search: '  santali ');

        final last = api.requests.last;
        expect(last.filter, 'refunded');
        expect(last.search, 'santali');
      });

      test(
        'Case 2: loadNextPage follows the server cursor and hasMore flag',
        () async {
          api.handler = (request) async => request.cursor == null
              ? _page(docs('p', 50), hasMore: true, next: 'cursor-1')
              : _page([...docs('q', 1)]);

          final container = createContainer();
          addTearDown(container.dispose);
          await waitForInitialLoad(container);
          final notifier = container.read(adminPurchasesProvider.notifier);

          var state = container.read(adminPurchasesProvider);
          expect(state.items.length, 50);
          expect(state.hasMore, isTrue);
          expect(state.isSampledOrPartial, isTrue);
          expect(state.nextCursor, 'cursor-1');

          await notifier.loadNextPage();

          state = container.read(adminPurchasesProvider);
          expect(api.requests.last.cursor, 'cursor-1');
          expect(state.items.length, 51);
          expect(state.hasMore, isFalse);
          expect(state.isSampledOrPartial, isFalse);
          expect(state.hasLoadMoreError, isFalse);
        },
      );

      test(
        'Case 3: loadNextPage preserves items, sets loadMoreFailure, keeps hasMore on error',
        () async {
          api.handler = (request) async {
            if (request.cursor != null) {
              throw const EdgeApiException('Request timed out');
            }
            return _page(docs('p', 50), hasMore: true, next: 'c1');
          };

          final container = createContainer();
          addTearDown(container.dispose);
          await waitForInitialLoad(container);
          final notifier = container.read(adminPurchasesProvider.notifier);

          expect(container.read(adminPurchasesProvider).items.length, 50);

          await notifier.loadNextPage();

          final state = container.read(adminPurchasesProvider);
          expect(state.items.length, 50); // Preserved!
          expect(state.isLoadingMore, isFalse);
          expect(state.hasLoadMoreError, isTrue);
          expect(state.hasInitialError, isFalse);
          expect(state.hasMore, isTrue); // Stays true so user can retry!
        },
      );

      test('a 403 from the Worker is an initial permission failure', () async {
        api.handler = (_) async => throw const EdgeApiException(
          'Admin access required',
          statusCode: 403,
        );
        final container = createContainer();
        addTearDown(container.dispose);
        await waitForInitialLoad(container);

        final state = container.read(adminPurchasesProvider);
        expect(state.hasInitialError, isTrue);
        expect(state.failure!.userMessage, contains('permission'));
      });

      for (final status in ['verified', 'refunded', 'failed', 'disputed']) {
        test('client refund fails closed for $status', () async {
          api.handler = (_) async => _page([
            makePurchaseDoc(
              id: 'p_refund_target',
              userId: 'u_target',
              categoryId: 'santali_pro',
              unlockMethod: 'razorpay',
              amountPaidInr: 499,
              status: status,
            ),
          ]);
          final container = createContainer();
          addTearDown(container.dispose);
          await waitForInitialLoad(container);
          final notifier = container.read(adminPurchasesProvider.notifier);
          final requestsBefore = api.requests.length;
          // Without an operation identity the call fails before any I/O,
          // regardless of the purchase status.
          final outcome = await notifier.recordExternalRefund(
            'p_refund_target',
          );
          expect(outcome, RefundResult.failed);
          expect(
            container.read(adminPurchasesProvider).items.single.status,
            status,
          );
          expect(api.requests.length, requestsBefore);
          verifyNever(() => mockRepo.clearUserEntitlementCache(any()));
        });
      }

      test(
        'client refund fails closed when the function service is unreachable',
        () async {
          // The Worker cannot be reached: every request fails at transport.
          final unreachable = AppwriteFunctionsService(
            httpClient: MockClient((_) async => throw Exception('unreachable')),
          );
          final container = ProviderContainer(
            overrides: [
              adminPurchasesApiProvider.overrideWithValue(api),
              purchaseRepositoryProvider.overrideWithValue(mockRepo),
              appwriteFunctionsServiceProvider.overrideWithValue(unreachable),
              isAuthenticatedProvider.overrideWith((ref) async => true),
              currentUserProvider.overrideWith((ref) async => testAdminUser),
            ],
          );
          addTearDown(container.dispose);
          container.listen(adminPurchasesProvider, (previous, next) {});
          container.read(adminPurchasesProvider.notifier);
          await waitForInitialLoad(container);
          final notifier = container.read(adminPurchasesProvider.notifier);
          final outcome = await notifier.recordExternalRefund(
            'p_refund_target',
            operationKey: 'op_unreachable_1',
          );
          expect(outcome, RefundResult.failed);
          expect(await notifier.refundPurchase('p_refund_target'), isFalse);
        },
      );

      test(
        'record_refund posts to the Worker maintenance route and reloads',
        () async {
          late Uri url;
          late Map<String, dynamic> sent;
          final worker = AppwriteFunctionsService(
            httpClient: MockClient((request) async {
              url = request.url;
              sent = jsonDecode(request.body) as Map<String, dynamic>;
              return http.Response(
                jsonEncode({'success': true, 'alreadyRefunded': false}),
                200,
              );
            }),
          );
          final container = ProviderContainer(
            overrides: [
              adminPurchasesApiProvider.overrideWithValue(api),
              purchaseRepositoryProvider.overrideWithValue(mockRepo),
              appwriteFunctionsServiceProvider.overrideWithValue(worker),
              isAuthenticatedProvider.overrideWith((ref) async => true),
              currentUserProvider.overrideWith((ref) async => testAdminUser),
            ],
          );
          addTearDown(container.dispose);
          container.listen(adminPurchasesProvider, (previous, next) {});
          await waitForInitialLoad(container);
          final listCalls = api.requests.length;

          final outcome = await container
              .read(adminPurchasesProvider.notifier)
              .recordExternalRefund(
                'p1',
                operationKey: adminRefundOperationKey('p1', 5000),
                amountPaise: 5000,
                externalRefundId: 'rfnd_1',
              );

          expect(outcome, RefundResult.completed);
          expect(url.path, '/api/v1/admin/maintenance');
          expect(sent, {
            'action': 'record_refund',
            'purchaseId': 'p1',
            'operationKey': 'admin-record:p1:5000',
            'gatewayRefundId': 'rfnd_1',
            'amountPaise': 5000,
          });
          expect(api.requests.length, listCalls + 1);
        },
      );

      test(
        'Case 7: fetchAllMatchingPurchases loops through export pages via cursor',
        () async {
          api.handler = (request) async {
            if (!request.export) return _page([]);
            return request.cursor == null
                ? _page(docs('a', 50), hasMore: true, next: 'c-a')
                : _page(docs('b', 30));
          };

          final container = createContainer();
          addTearDown(container.dispose);

          final notifier = container.read(adminPurchasesProvider.notifier);
          final result = await notifier.fetchAllMatchingPurchases(
            filter: 'razorpay',
          );

          expect(result.status, PurchaseExportStatus.completed);
          expect(result.items.length, 80);
          expect(result.isTruncated, isFalse);
          final exports = api.requests.where((r) => r.export).toList();
          expect(exports.map((r) => r.cursor), [null, 'c-a']);
          expect(exports.every((r) => r.filter == 'razorpay'), isTrue);
          expect(exports.first.limit, AdminPurchasesNotifier.exportPageSize);
        },
      );

      test(
        'Case 8: fetchAllMatchingPurchases respects safety threshold and returns truncated status',
        () async {
          var n = 0;
          api.handler = (request) async {
            n++;
            return _page(
              docs('p$n', request.limit),
              hasMore: true,
              next: 'c$n',
            );
          };

          final container = createContainer();
          addTearDown(container.dispose);

          final notifier = container.read(adminPurchasesProvider.notifier);
          final result = await notifier.fetchAllMatchingPurchases(
            safetyLimit: 100, // Explicit safety limit for test
          );

          expect(result.status, PurchaseExportStatus.truncated);
          expect(result.items.length, 100);
          expect(result.isTruncated, isTrue);
          expect(result.hasMore, isTrue);
        },
      );

      test(
        'Case 9: fetchAllMatchingPurchases handles cancellation cleanly',
        () async {
          api.handler = (_) async => _page(docs('p', 50), hasMore: true);

          final container = createContainer();
          addTearDown(container.dispose);

          final notifier = container.read(adminPurchasesProvider.notifier);
          final result = await notifier.fetchAllMatchingPurchases(
            isCancelled: () => true, // Cancel immediately
          );

          expect(result.status, PurchaseExportStatus.cancelled);
          expect(result.items.isEmpty, isTrue);
        },
      );
    },
  );
}
