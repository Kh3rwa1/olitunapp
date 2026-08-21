import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/core/payments/purchase_repository.dart';
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

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        appwriteDbServiceProvider.overrideWithValue(mockDb),
        purchaseRepositoryProvider.overrideWithValue(mockRepo),
        isAuthenticatedProvider.overrideWith((ref) async => true),
        currentUserProvider.overrideWith((ref) async => null),
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

  group('AdminPurchasesNotifier - State & Pagination Matrix', () {
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
      },
    );

    test(
      'Case 3: loadNextPage preserves existing items when error occurs',
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
            throw AppwriteException('Network error', 0, 'network_failure');
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
        expect(state.items.length, 50);
        expect(state.isLoadingMore, isFalse);
        expect(state.failure, isNotNull);
      },
    );

    test(
      'Case 4: recordExternalRefund updates document, invalidates user entitlement cache, and reloads',
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

        final success = await notifier.recordExternalRefund(
          'p_refund_target',
          externalRefundId: 'rfnd_ext_123',
          reason: 'Customer requested refund via email',
        );

        expect(success, isTrue);
        verify(
          () => mockDb.updateDocument(
            'course_purchases',
            'p_refund_target',
            any(
              that: predicate((Map<String, dynamic> data) {
                return data['status'] == 'refunded' &&
                    data['refundReference'] == 'rfnd_ext_123' &&
                    data['refundReason'] ==
                        'Customer requested refund via email' &&
                    data['refundedBy'] == 'admin' &&
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
      'Case 5: recordExternalRefund handles already-refunded items idempotently',
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

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(adminPurchasesProvider.notifier);
        await notifier.loadPurchases();

        final success = await notifier.recordExternalRefund(
          'p_already_refunded',
        );

        expect(success, isTrue);
        verifyNever(
          () => mockDb.updateDocument('course_purchases', any(), any()),
        );
      },
    );

    test(
      'Case 6: fetchAllMatchingPurchases loops through all pages with cursor',
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
        final allItems = await notifier.fetchAllMatchingPurchases();

        expect(allItems.length, 80);
      },
    );
  });
}
