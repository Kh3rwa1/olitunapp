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
    return ProviderContainer(
      overrides: [
        appwriteDbServiceProvider.overrideWithValue(mockDb),
        purchaseRepositoryProvider.overrideWithValue(mockRepo),
        isAuthenticatedProvider.overrideWith((ref) async => true),
        currentUserProvider.overrideWith((ref) async => operator),
      ],
    );
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

        final notifier = container.read(adminPurchasesProvider.notifier);
        await notifier.loadPurchases();

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

        final notifier = container.read(adminPurchasesProvider.notifier);
        await notifier.loadPurchases();

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

        final notifier = container.read(adminPurchasesProvider.notifier);
        await notifier.loadPurchases();

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

    test(
      'Case 4: recordExternalRefund stores actual operator admin ID and invalidates user cache',
      () async {
        when(
          () => mockDb.listDocuments(
            'course_purchases',
            queries: any(named: 'queries'),
          ),
        ).thenAnswer(
          (_) async => [
            makePurchaseDoc(
              id: 'p_refund_target',
              userId: 'u_target_123',
              categoryId: 'santali_pro',
              unlockMethod: 'razorpay',
              amountPaidInr: 499,
              status: 'verified',
              paymentId: 'pay_target',
            ),
          ],
        );

        when(
          () => mockDb.getDocument('course_purchases', 'p_refund_target'),
        ).thenAnswer(
          (_) async => makePurchaseDoc(
            id: 'p_refund_target',
            userId: 'u_target_123',
            categoryId: 'santali_pro',
            unlockMethod: 'razorpay',
            amountPaidInr: 499,
            status: 'verified',
            paymentId: 'pay_target',
          ),
        );

        when(
          () => mockDb.updateDocument(
            'course_purchases',
            'p_refund_target',
            any(),
          ),
        ).thenAnswer((_) async => {});

        when(
          () => mockRepo.clearUserEntitlementCache('u_target_123'),
        ).thenAnswer((_) async => {});

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(adminPurchasesProvider.notifier);
        await notifier.loadPurchases();

        final outcome = await notifier.recordExternalRefund(
          'p_refund_target',
          externalRefundId: 'rfnd_ext_123',
          reason: 'Customer requested refund via support ticket',
          idempotencyKey: 'idemp_key_999',
        );

        expect(outcome, RefundResult.completed);
        verify(
          () => mockDb.updateDocument(
            'course_purchases',
            'p_refund_target',
            any(
              that: predicate((Map<String, dynamic> data) {
                return data['status'] == 'refunded' &&
                    data['refundReference'] == 'rfnd_ext_123' &&
                    data['refundReason'] ==
                        'Customer requested refund via support ticket' &&
                    data['refundedBy'] ==
                        'admin_usr_999' && // Actual operator ID!
                    data['idempotencyKey'] == 'idemp_key_999' &&
                    data['previousStatus'] == 'verified';
              }),
            ),
          ),
        ).called(1);

        verify(
          () => mockRepo.clearUserEntitlementCache('u_target_123'),
        ).called(1);
      },
    );

    test(
      'Case 5: recordExternalRefund returns alreadyRefunded idempotently without duplicate update',
      () async {
        when(
          () => mockDb.listDocuments(
            'course_purchases',
            queries: any(named: 'queries'),
          ),
        ).thenAnswer(
          (_) async => [
            makePurchaseDoc(
              id: 'p_already_refunded',
              userId: 'u_target_456',
              categoryId: 'santali_pro',
              unlockMethod: 'razorpay',
              amountPaidInr: 499,
              status: 'refunded',
              paymentId: 'pay_target',
            ),
          ],
        );

        when(
          () => mockDb.getDocument('course_purchases', 'p_already_refunded'),
        ).thenAnswer(
          (_) async => makePurchaseDoc(
            id: 'p_already_refunded',
            userId: 'u_target_456',
            categoryId: 'santali_pro',
            unlockMethod: 'razorpay',
            amountPaidInr: 499,
            status: 'refunded',
            paymentId: 'pay_target',
          ),
        );

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(adminPurchasesProvider.notifier);
        await notifier.loadPurchases();

        final outcome = await notifier.recordExternalRefund(
          'p_already_refunded',
        );

        expect(outcome, RefundResult.alreadyRefunded);
        verifyNever(
          () => mockDb.updateDocument('course_purchases', any(), any()),
        );
      },
    );

    test(
      'Case 6: recordExternalRefund rejects invalid state transitions',
      () async {
        when(
          () => mockDb.listDocuments(
            'course_purchases',
            queries: any(named: 'queries'),
          ),
        ).thenAnswer(
          (_) async => [
            makePurchaseDoc(
              id: 'p_failed_item',
              userId: 'u_fail_1',
              categoryId: 'santali_pro',
              unlockMethod: 'razorpay',
              amountPaidInr: 499,
              status: 'failed',
            ),
          ],
        );

        when(
          () => mockDb.getDocument('course_purchases', 'p_failed_item'),
        ).thenAnswer(
          (_) async => makePurchaseDoc(
            id: 'p_failed_item',
            userId: 'u_fail_1',
            categoryId: 'santali_pro',
            unlockMethod: 'razorpay',
            amountPaidInr: 499,
            status: 'failed',
          ),
        );

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(adminPurchasesProvider.notifier);
        await notifier.loadPurchases();

        final outcome = await notifier.recordExternalRefund('p_failed_item');
        expect(outcome, RefundResult.invalidTransition);
      },
    );

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
