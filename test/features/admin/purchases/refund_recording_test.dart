import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:itun/features/admin/presentation/purchases/utils/purchases_actions_helper.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/purchases_provider.dart';

void main() {
  group('adminRefundOperationKey', () {
    test('is deterministic for identical inputs', () {
      expect(
        adminRefundOperationKey('p1', 15000),
        adminRefundOperationKey('p1', 15000),
      );
    });

    test('distinguishes full refunds from partial amounts', () {
      expect(
        adminRefundOperationKey('p1', null),
        isNot(adminRefundOperationKey('p1', 15000)),
      );
    });

    test('distinguishes purchases', () {
      expect(
        adminRefundOperationKey('p1', 15000),
        isNot(adminRefundOperationKey('p2', 15000)),
      );
    });
  });

  group('refundResultFromResponse', () {
    test('maps success with alreadyRefunded flag', () {
      expect(
        refundResultFromResponse(
          statusCode: 200,
          body: {'success': true, 'alreadyRefunded': true},
        ),
        RefundResult.alreadyRefunded,
      );
      expect(
        refundResultFromResponse(
          statusCode: 200,
          body: {'success': true, 'alreadyRefunded': false},
        ),
        RefundResult.completed,
      );
    });

    test('maps idempotency conflicts distinctly from status conflicts', () {
      expect(
        refundResultFromResponse(
          statusCode: 409,
          body: {
            'success': false,
            'message': 'Idempotency conflict: operation key was already used.',
          },
        ),
        RefundResult.conflict,
      );
      expect(
        refundResultFromResponse(
          statusCode: 409,
          body: {
            'success': false,
            'message':
                'This gateway refund was already recorded under a different operation.',
          },
        ),
        RefundResult.conflict,
      );
      expect(
        refundResultFromResponse(
          statusCode: 409,
          body: {
            'success': false,
            'message': 'Cannot refund purchase in status \'created\'.',
          },
        ),
        RefundResult.invalidTransition,
      );
    });

    test('maps not-found and unauthorized', () {
      expect(
        refundResultFromResponse(
          statusCode: 404,
          body: {'success': false, 'message': 'Purchase x not found.'},
        ),
        RefundResult.notFound,
      );
      expect(
        refundResultFromResponse(
          statusCode: 403,
          body: {
            'success': false,
            'message': 'Admin team membership required.',
          },
        ),
        RefundResult.unauthorized,
      );
    });

    test('maps transport failures and garbage bodies to failed', () {
      expect(
        refundResultFromResponse(statusCode: null, body: null),
        RefundResult.failed,
      );
      expect(
        refundResultFromResponse(statusCode: 500, body: {'success': false}),
        RefundResult.failed,
      );
      expect(
        refundResultFromResponse(statusCode: 200, body: {'ok': true}),
        RefundResult.failed,
      );
    });
  });

  group('recordExternalRefund provider', () {
    test('rejects missing identity without calling the function', () async {
      final container = ProviderContainer(
        overrides: [
          adminPurchasesProvider.overrideWith(FakeAdminPurchases.new),
        ],
      );
      addTearDown(container.dispose);
      var called = false;
      final notifier =
          container.read(adminPurchasesProvider.notifier) as FakeAdminPurchases;
      notifier.passthroughExecutor = (payload) async {
        called = true;
        return {'success': true};
      };
      final result = await notifier.recordExternalRefund(
        'purchase-1',
        executor: (payload) async {
          called = true;
          return {'success': true};
        },
      );
      expect(result, RefundResult.failed);
      expect(called, isFalse);
    });

    test('maps executor outcomes and refreshes on success', () async {
      final container = ProviderContainer(
        overrides: [
          adminPurchasesProvider.overrideWith(FakeAdminPurchases.new),
        ],
      );
      addTearDown(container.dispose);
      final notifier =
          container.read(adminPurchasesProvider.notifier) as FakeAdminPurchases;

      notifier.passthroughExecutor = (_) async => {
        'success': true,
        'alreadyRefunded': false,
      };
      expect(
        await notifier.recordExternalRefund(
          'purchase-1',
          operationKey: 'op_1',
          executor: (payload) async => notifier.passthroughExecutor!(payload),
        ),
        RefundResult.completed,
      );
      expect(notifier.reloadCalls, 1);

      notifier.passthroughExecutor = (_) async => {
        'success': true,
        'alreadyRefunded': true,
      };
      expect(
        await notifier.recordExternalRefund(
          'purchase-1',
          operationKey: 'op_1',
          executor: (payload) async => notifier.passthroughExecutor!(payload),
        ),
        RefundResult.alreadyRefunded,
      );
      expect(notifier.reloadCalls, 2);

      notifier.passthroughExecutor = (_) async => {
        'success': false,
        'message': 'Idempotency conflict: operation key was already used.',
      };
      expect(
        await notifier.recordExternalRefund(
          'purchase-1',
          operationKey: 'op_1',
          executor: (payload) async => notifier.passthroughExecutor!(payload),
        ),
        RefundResult.conflict,
      );
      expect(notifier.reloadCalls, 2);
    });
  });

  group('refund recording dialog', () {
    PurchaseModel item() => PurchaseModel.fromJson({
      '\$id': 'purchase-1',
      'userId': 'user-1',
      'categoryId': 'category-1',
      'status': 'verified',
      'unlockMethod': 'razorpay',
      'amountPaidInr': 499,
      'purchasedAt': '2026-09-05T00:00:00Z',
    });

    Future<void> pumpDialog(
      WidgetTester tester,
      FakeAdminPurchases Function() fake,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [adminPurchasesProvider.overrideWith(fake)],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) => TextButton(
                  onPressed: () => PurchasesActionsHelper.showRefundDialog(
                    context: context,
                    ref: ref,
                    item: item(),
                    onProcessingChanged: (_) {},
                  ),
                  child: const Text('Open refund'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open refund'));
      await tester.pumpAndSettle();
    }

    testWidgets('completed recording shows success and refreshes', (
      tester,
    ) async {
      late FakeAdminPurchases fake;
      fake = FakeAdminPurchases();
      await pumpDialog(tester, () => fake);

      expect(find.text('Record external refund'), findsOneWidget);
      expect(find.text('Record Refund'), findsOneWidget);

      await tester.tap(find.text('Record Refund'));
      await tester.pumpAndSettle();

      expect(fake.recordCalls, 1);
      expect(find.text('Refund recorded and access revoked.'), findsOneWidget);
      expect(fake.reloadCalls, 1);
      // Full refund (empty amount) derives a stable, restart-safe key.
      expect(fake.lastPayload['operationKey'], 'admin-record:purchase-1:full');

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('double submit issues a single recording call', (tester) async {
      late FakeAdminPurchases fake;
      fake = FakeAdminPurchases(slow: true);
      await pumpDialog(tester, () => fake);

      await tester.tap(find.text('Record Refund'));
      await tester.pump();
      // While submitting, the action relabels and disables: tapping the
      // button again must not issue a second recording call.
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(fake.recordCalls, 1);
    });

    testWidgets('conflict result explains without closing', (tester) async {
      late FakeAdminPurchases fake;
      fake = FakeAdminPurchases(result: RefundResult.conflict);
      await pumpDialog(tester, () => fake);

      await tester.tap(find.text('Record Refund'));
      await tester.pumpAndSettle();

      expect(fake.recordCalls, 1);
      expect(
        find.textContaining('conflicts with an earlier record'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('invalid amount blocks submission with inline error', (
      tester,
    ) async {
      late FakeAdminPurchases fake;
      fake = FakeAdminPurchases();
      await pumpDialog(tester, () => fake);

      await tester.enterText(
        find.widgetWithText(
          TextField,
          'Refund amount in ₹ (empty = full refund)',
        ),
        'abc',
      );
      await tester.tap(find.text('Record Refund'));
      await tester.pumpAndSettle();

      expect(fake.recordCalls, 0);
      expect(find.textContaining('valid amount'), findsOneWidget);
    });

    testWidgets('dialog completes on a 320px small screen without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late FakeAdminPurchases fake;
      fake = FakeAdminPurchases();
      await pumpDialog(tester, () => fake);

      await tester.tap(find.text('Record Refund'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Refund recorded and access revoked.'), findsOneWidget);
    });
  });
}

class FakeAdminPurchases extends AdminPurchasesNotifier {
  FakeAdminPurchases({
    RefundResult result = RefundResult.completed,
    this.slow = false,
  }) : _result = result;

  final RefundResult _result;
  final bool slow;
  int recordCalls = 0;
  int reloadCalls = 0;
  Map<String, dynamic> lastPayload = const {};
  Future<Map<String, dynamic>> Function(Map<String, dynamic> payload)?
  passthroughExecutor;

  @override
  AdminPurchasesState build() => const AdminPurchasesState();

  @override
  Future<void> loadPurchases({String? filter, String? search}) async {
    reloadCalls++;
  }

  @override
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
    recordCalls++;
    lastPayload = {
      'purchaseId': purchaseId,
      'operationKey': operationKey,
      'gatewayRefundId': externalRefundId,
      'amountPaise': amountPaise,
      'reason': reason,
    };
    final passthrough = passthroughExecutor;
    if (passthrough != null) {
      // Exercise the real provider logic (payload building + mapping);
      // the executor seam stands in for the function call.
      return super.recordExternalRefund(
        purchaseId,
        operationKey: operationKey,
        externalRefundId: externalRefundId,
        reason: reason,
        idempotencyKey: idempotencyKey,
        amountPaise: amountPaise,
        executor: executor ?? passthrough,
      );
    }
    if (slow) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    final outcome = _result;
    if (outcome == RefundResult.completed ||
        outcome == RefundResult.alreadyRefunded) {
      await loadPurchases();
    }
    return outcome;
  }
}
