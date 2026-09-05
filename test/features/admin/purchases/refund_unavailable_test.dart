import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/purchases/utils/purchases_actions_helper.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/purchases_provider.dart';

void main() {
  test('refund cannot access uninitialized providers', () async {
    final notifier = AdminPurchasesNotifier();
    expect(
      await notifier.recordExternalRefund('purchase-1'),
      RefundResult.failed,
    );
    expect(await notifier.refundPurchase('purchase-1'), isFalse);
  });

  testWidgets('refund dialog explains the safe recovery path', (tester) async {
    final item = PurchaseModel.fromJson({
      '\$id': 'purchase-1',
      'userId': 'user-1',
      'categoryId': 'category-1',
      'status': 'verified',
      'unlockMethod': 'razorpay',
      'amountPaidInr': 499,
      'purchasedAt': '2026-09-05T00:00:00Z',
    });
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) => TextButton(
                onPressed: () => PurchasesActionsHelper.showRefundDialog(
                  context: context,
                  ref: ref,
                  item: item,
                  onProcessingChanged: (value) => expect(value, isFalse),
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
    expect(find.text('Refund recording unavailable'), findsOneWidget);
    expect(
      find.text(externalRefundRecordingUnavailableMessage),
      findsOneWidget,
    );
    expect(find.text('Record Refund & Revoke Access'), findsNothing);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
