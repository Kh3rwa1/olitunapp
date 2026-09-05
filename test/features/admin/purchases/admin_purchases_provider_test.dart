import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/core/payments/purchase_repository.dart';
import 'package:itun/features/admin/domain/purchase_csv_exporter.dart';
import 'package:itun/features/auth/domain/entities/user_entity.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/shared/providers/purchases_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockAppwriteDbService extends Mock implements AppwriteDbService {}

class MockPurchaseRepository extends Mock implements PurchaseRepository {}

void main() {
  late MockAppwriteDbService mockDb;
  late MockPurchaseRepository mockRepo;

  setUp(() {
    mockDb = MockAppwriteDbService();
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
        appwriteDbServiceProvider.overrideWithValue(mockDb),
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

  group('AdminPurchasesNotifier - State, Pagination, Idempotency & Export Matrix', () {
    test(
      'Case 1: initial load loads first page and computes metrics',
      () async {
        when(
          () => mockDb.listDocuments(
            'course_purchases',
            queries: any(named: 'queries'),
          ),
        ).thenAnswer(
          (_) async => [
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
          ],
        );

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
      },
    );

    test(
      'Case 2: loadNextPage appends records, updates nextCursor, and recomputes isSampledOrPartial',
      () async {
        final page1 = List.generate(
          50,
          (i) => makePurchaseDoc(
            id: 'p_$i',
            userId: 'u_$i',
            categoryId: 'santali_basics',
            unlockMethod: 'razorpay',
            amountPaidInr: 299,
            status: 'verified',
            paymentId: 'pay_$i',
          ),
        );

        final page2 = [
          makePurchaseDoc(
            id: 'p_50',
            userId: 'u_50',
            categoryId: 'santali_basics',
            unlockMethod: 'razorpay',
            amountPaidInr: 299,
            status: 'verified',
            paymentId: 'pay_50',
          ),
        ];

        when(
          () => mockDb.listDocuments(
            'course_purchases',
            queries: any(named: 'queries'),
          ),
        ).thenAnswer((invocation) async {
          final queries =
              invocation.namedArguments[const Symbol('queries')]
                  as List<String>? ??
              [];
          final hasCursor = queries.any((q) => q.contains('cursorAfter'));
          return hasCursor ? page2 : page1;
        });

        final container = createContainer();
        addTearDown(container.dispose);
        await waitForInitialLoad(container);
        final notifier = container.read(adminPurchasesProvider.notifier);

        var state = container.read(adminPurchasesProvider);
        expect(state.items.length, 50);
        expect(state.hasMore, isTrue);
        expect(state.isSampledOrPartial, isTrue);
        expect(state.nextCursor, 'p_49');

        await notifier.loadNextPage();

        state = container.read(adminPurchasesProvider);
        expect(state.items.length, 51);
        expect(state.hasMore, isFalse);
        expect(state.isSampledOrPartial, isFalse);
        expect(state.hasLoadMoreError, isFalse);
      },
    );

    test(
      'Case 3: loadNextPage preserves existing items, sets loadMoreFailure, and keeps hasMore true on error',
      () async {
        when(
          () => mockDb.listDocuments(
            'course_purchases',
            queries: any(named: 'queries'),
          ),
        ).thenAnswer((invocation) async {
          final queries =
              invocation.namedArguments[const Symbol('queries')]
                  as List<String>? ??
              [];
          final hasCursor = queries.any((q) => q.contains('cursorAfter'));
          if (hasCursor) {
            throw AppwriteException('Network timeout', 0, 'network_timeout');
          }
          return List.generate(
            50,
            (i) => makePurchaseDoc(
              id: 'p_$i',
              userId: 'u_$i',
              categoryId: 'santali_basics',
              unlockMethod: 'razorpay',
              amountPaidInr: 299,
              status: 'verified',
              paymentId: 'pay_$i',
            ),
          );
        });

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

    for (final status in ['verified', 'refunded', 'failed', 'disputed']) {
      test('client refund fails closed for $status', () async {
        when(
          () => mockDb.listDocuments(
            'course_purchases',
            queries: any(named: 'queries'),
          ),
        ).thenAnswer(
          (_) async => [
            makePurchaseDoc(
              id: 'p_refund_target',
              userId: 'u_target',
              categoryId: 'santali_pro',
              unlockMethod: 'razorpay',
              amountPaidInr: 499,
              status: status,
            ),
          ],
        );
        final container = createContainer();
        addTearDown(container.dispose);
        await waitForInitialLoad(container);
        final notifier = container.read(adminPurchasesProvider.notifier);
        final outcome = await notifier.recordExternalRefund(
          'p_refund_target',
          externalRefundId: 'already-issued-refund',
          reason: 'Support reconciliation',
          idempotencyKey: 'same-key',
        );
        expect(outcome, RefundResult.failed);
        expect(await notifier.refundPurchase('p_refund_target'), isFalse);
        expect(
          container.read(adminPurchasesProvider).items.single.status,
          status,
        );
        verifyNever(() => mockDb.getDocument('course_purchases', any()));
        verifyNever(
          () => mockDb.updateDocument('course_purchases', any(), any()),
        );
        verifyNever(() => mockRepo.clearUserEntitlementCache(any()));
      });
    }

    test(
      'Case 7: fetchAllMatchingPurchases loops through all pages via cursor and returns completed status',
      () async {
        when(
          () => mockDb.listDocuments(
            'course_purchases',
            queries: any(named: 'queries'),
          ),
        ).thenAnswer((invocation) async {
          final queries =
              invocation.namedArguments[const Symbol('queries')]
                  as List<String>? ??
              [];
          final hasCursor = queries.any((q) => q.contains('cursorAfter'));
          if (!hasCursor) {
            return List.generate(
              50,
              (i) => makePurchaseDoc(
                id: 'p_a_$i',
                userId: 'u_$i',
                categoryId: 'santali_basics',
                unlockMethod: 'razorpay',
                amountPaidInr: 299,
                status: 'verified',
              ),
            );
          } else {
            return List.generate(
              30,
              (i) => makePurchaseDoc(
                id: 'p_b_$i',
                userId: 'u_${i + 50}',
                categoryId: 'santali_basics',
                unlockMethod: 'razorpay',
                amountPaidInr: 299,
                status: 'verified',
              ),
            );
          }
        });

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(adminPurchasesProvider.notifier);
        final result = await notifier.fetchAllMatchingPurchases();

        expect(result.status, PurchaseExportStatus.completed);
        expect(result.items.length, 80);
        expect(result.isTruncated, isFalse);
      },
    );

    test(
      'Case 8: fetchAllMatchingPurchases respects safety threshold and returns truncated status',
      () async {
        when(
          () => mockDb.listDocuments(
            'course_purchases',
            queries: any(named: 'queries'),
          ),
        ).thenAnswer((invocation) async {
          return List.generate(
            50,
            (i) => makePurchaseDoc(
              id: 'p_${DateTime.now().microsecondsSinceEpoch}_$i',
              userId: 'u_$i',
              categoryId: 'santali_basics',
              unlockMethod: 'razorpay',
              amountPaidInr: 299,
              status: 'verified',
            ),
          );
        });

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
        when(
          () => mockDb.listDocuments(
            'course_purchases',
            queries: any(named: 'queries'),
          ),
        ).thenAnswer((invocation) async {
          return List.generate(
            50,
            (i) => makePurchaseDoc(
              id: 'p_$i',
              userId: 'u_$i',
              categoryId: 'santali_basics',
              unlockMethod: 'razorpay',
              amountPaidInr: 299,
              status: 'verified',
            ),
          );
        });

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
  });
}
