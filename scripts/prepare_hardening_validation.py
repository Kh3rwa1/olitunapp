import os
import subprocess
from pathlib import Path

BASE = '72d7b56361b84123bc6d18f7e999fb494a65b339'
AREA = os.environ['AREA']
ALLOWED = {'web', 'progress', 'content', 'payment'}
assert AREA in ALLOWED

def baseline(path):
    return subprocess.check_output(['git', 'show', f'{BASE}:{path}'], text=True)

def replace_once(s, old, new):
    assert s.count(old) == 1, f'Expected one unique patch anchor: {old[:90]}'
    return s.replace(old, new, 1)

def write(path, s):
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(s)

if AREA == 'progress':
    path = 'lib/features/profile/presentation/providers/user_stats_provider.dart'
    s = baseline(path)
    begin = s.index('  Future<void> resetProgress() async {')
    finish = s.index('  Future<void> updateName(', begin)
    s = s[:begin] + '''  Future<void> resetProgress() async {
    final result = await _repository.resetUserStats();
    if (_disposed) return;
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (stats) {
        state = AsyncValue.data(stats);
        _updateSyncStateFromPrefs();
      },
    );
  }

''' + s[finish:]
    write(path, s)
    path = 'lib/features/profile/domain/entities/user_stats_entity.dart'
    s = baseline(path)
    s = replace_once(s, '  final Set<String> completedMissionsDates;\n', '  final Set<String> completedMissionsDates;\n\n  /// Reset generation; legacy payloads belong to generation zero.\n  final int syncEpoch;\n')
    s = replace_once(s, '    this.practiceDates = const {},\n', '    this.practiceDates = const {},\n    this.syncEpoch = 0,\n')
    s = replace_once(s, '    practiceDates,\n', '    practiceDates,\n    syncEpoch,\n')
    s = replace_once(s, '    Set<String>? practiceDates,\n', '    Set<String>? practiceDates,\n    int? syncEpoch,\n')
    s = replace_once(s, '      practiceDates: practiceDates ?? this.practiceDates,\n', '      practiceDates: practiceDates ?? this.practiceDates,\n      syncEpoch: syncEpoch ?? this.syncEpoch,\n')
    write(path, s)

if AREA == 'payment':
    path = 'lib/shared/providers/purchases_provider.dart'
    s = baseline(path)
    marker = '/// Typed outcome for recording an external refund in Appwrite.\n'
    message = '''const externalRefundRecordingUnavailableMessage =
    'Manual refund recording is temporarily disabled. '
    'Use the Razorpay Dashboard for gateway refunds and ask the administrator '
    'to reconcile external refunds through a secure server-side process. '
    'Do not issue a refund twice.';

'''
    s = replace_once(s, marker, message + marker)
    begin = s.index('  /// Records an external refund in Appwrite')
    finish = s.index('  /// Fetches matching purchase records', begin)
    s = s[:begin] + '''  /// Fails closed until a server-authorized, transactional recorder exists.
  /// No operator identity, stale client state, or client idempotency key can
  /// authorize a direct financial ledger write. This does not transfer money.
  Future<RefundResult> recordExternalRefund(
    String purchaseId, {
    String? externalRefundId,
    String? reason,
    String? idempotencyKey,
  }) async {
    AppLogger.debug(externalRefundRecordingUnavailableMessage);
    return RefundResult.failed;
  }

''' + s[finish:]
    write(path, s)
    path = 'lib/features/admin/presentation/purchases/utils/purchases_actions_helper.dart'
    s = baseline(path)
    s = replace_once(s, "import 'package:intl/intl.dart';\n", '')
    s = replace_once(s, "import 'package:itun/features/admin/presentation/widgets/common/admin_destructive_dialog.dart';\n", '')
    begin = s.index('  static final NumberFormat _inrCurrencyFormat')
    finish = s.index('  static Future<void> exportVisibleRows', begin)
    s = s[:begin] + '''  static Future<void> showRefundDialog({
    required BuildContext context,
    required WidgetRef ref,
    required PurchaseModel item,
    required void Function(bool isProcessing) onProcessingChanged,
  }) async {
    onProcessingChanged(false);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Refund recording unavailable'),
        content: const Text(externalRefundRecordingUnavailableMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

''' + s[finish:]
    write(path, s)
    path = 'test/features/admin/purchases/admin_purchases_provider_test.dart'
    s = baseline(path)
    begin = s.index("    test(\n      'Case 4:")
    finish = s.index("    test(\n      'Case 7:", begin)
    s = s[:begin] + '''    for (final status in ['verified', 'refunded', 'failed', 'disputed']) {
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
        expect(container.read(adminPurchasesProvider).items.single.status, status);
        verifyNever(() => mockDb.getDocument('course_purchases', any()));
        verifyNever(
          () => mockDb.updateDocument('course_purchases', any(), any()),
        );
        verifyNever(() => mockRepo.clearUserEntitlementCache(any()));
      });
    }

''' + s[finish:]
    write(path, s)
    write('test/features/admin/purchases/refund_unavailable_test.dart', r'''import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/purchases/utils/purchases_actions_helper.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/purchases_provider.dart';

void main() {
  test('refund cannot access uninitialized providers', () async {
    final notifier = AdminPurchasesNotifier();
    expect(await notifier.recordExternalRefund('purchase-1'), RefundResult.failed);
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
    expect(find.text(externalRefundRecordingUnavailableMessage), findsOneWidget);
    expect(find.text('Record Refund & Revoke Access'), findsNothing);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
''')
    doc = Path('docs/PAYMENT_DISPUTE_HARDENING.md')
    doc.write_text(doc.read_text() + '''
## Client refund containment

The unsafe client-side ledger update is disabled. `recordExternalRefund` returns a failed outcome without reading providers or writing data, and its legacy boolean alias returns false. The admin dialog explicitly explains the pause, distinguishes gateway refunds from recording, and warns against duplicate refunds. Existing pagination/export tests are retained; former client-refund-success tests now assert zero ledger reads/writes/cache invalidations for each relevant state.

This is intentionally a temporary loss of manual-recording functionality, not a server-side authorization boundary. Deploy an authorized transactional recording endpoint and restrict direct client write permissions before restoring it. No refund has been executed by this change.
''')

print(f'Applied focused {AREA} preparation without changing release gates.')
