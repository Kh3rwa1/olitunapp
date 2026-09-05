import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/features/admin/domain/purchase_csv_exporter.dart';
import 'package:itun/features/admin/presentation/analytics/admin_analytics_csv_exporter.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/purchases_provider.dart';

/// Dialog that records a gateway-issued refund through the protected
/// server function. The operation key is derived deterministically from
/// (purchase, amount) so retries — including across restarts — reuse one
/// key and converge instead of duplicating. Submit is disabled while a
/// request is in flight (duplicate-submit prevention).
class _RefundRecordingDialog extends StatefulWidget {
  const _RefundRecordingDialog({
    required this.item,
    required this.amountController,
    required this.reasonController,
    required this.gatewayController,
    required this.onProcessingChanged,
    required this.recordRefund,
  });

  final PurchaseModel item;
  final TextEditingController amountController;
  final TextEditingController reasonController;
  final TextEditingController gatewayController;
  final void Function(bool isProcessing) onProcessingChanged;
  final Future<RefundResult> Function(
    String purchaseId, {
    required String operationKey,
    String? gatewayRefundId,
    int? amountPaise,
    String? reason,
  })
  recordRefund;

  @override
  State<_RefundRecordingDialog> createState() => _RefundRecordingDialogState();
}

class _RefundRecordingDialogState extends State<_RefundRecordingDialog> {
  bool _submitting = false;
  bool _done = false;
  String? _formError;
  RefundResult? _result;

  static const _resultCopy = <RefundResult, String>{
    RefundResult.completed: 'Refund recorded and access revoked.',
    RefundResult.alreadyRefunded:
        'Already recorded — no duplicate entry was created.',
    RefundResult.invalidTransition:
        'Purchase is not in a refundable state. Refresh the list and check its status.',
    RefundResult.conflict:
        'This refund conflicts with an earlier record. Check the existing record instead of retrying.',
    RefundResult.notFound: 'Purchase not found. It may have been deleted.',
    RefundResult.unauthorized:
        'Not authorized. Sign in with an admin account and retry.',
    RefundResult.failed:
        'Recording failed. Retry with the same details — the operation key keeps retries safe.',
  };

  Future<void> _submit() async {
    if (_submitting || _done) return;
    final amountText = widget.amountController.text.trim();
    int? amountPaise;
    if (amountText.isNotEmpty) {
      final rupees = double.tryParse(amountText);
      if (rupees == null || rupees <= 0) {
        setState(
          () => _formError =
              'Enter a valid amount in ₹, or leave empty for a full refund.',
        );
        return;
      }
      amountPaise = (rupees * 100).round();
      if (amountPaise <= 0) {
        setState(
          () => _formError =
              'Enter a valid amount in ₹, or leave empty for a full refund.',
        );
        return;
      }
    }
    setState(() {
      _submitting = true;
      _formError = null;
    });
    widget.onProcessingChanged(true);
    try {
      final result = await widget.recordRefund(
        widget.item.id,
        operationKey: adminRefundOperationKey(widget.item.id, amountPaise),
        gatewayRefundId: widget.gatewayController.text.trim().isEmpty
            ? null
            : widget.gatewayController.text.trim(),
        amountPaise: amountPaise,
        reason: widget.reasonController.text.trim().isEmpty
            ? null
            : widget.reasonController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _done =
            result == RefundResult.completed ||
            result == RefundResult.alreadyRefunded;
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
      widget.onProcessingChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return AlertDialog(
      title: const Text('Record external refund'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: const Text(
                'Bookkeeping only — records a refund already issued in the payment dashboard. Does not move money. Do not record twice.',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Purchase ${item.id} · ₹${item.amountPaidInr} · ${item.status}',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.amountController,
              enabled: !_submitting && !_done,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Refund amount in ₹ (empty = full refund)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.gatewayController,
              enabled: !_submitting && !_done,
              decoration: const InputDecoration(
                labelText: 'Gateway refund ID (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.reasonController,
              enabled: !_submitting && !_done,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_formError != null) ...[
              const SizedBox(height: 8),
              Text(_formError!, style: const TextStyle(color: AppColors.error)),
            ],
            if (_result != null) ...[
              const SizedBox(height: 8),
              Text(
                _resultCopy[_result]!,
                style: TextStyle(
                  color: _done ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (_submitting) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(_done ? 'Close' : 'Cancel'),
        ),
        FilledButton(
          onPressed: _submitting || _done ? null : _submit,
          child: Text(_submitting ? 'Recording…' : 'Record Refund'),
        ),
      ],
    );
  }
}

class PurchasesActionsHelper {
  static Future<void> showRefundDialog({
    required BuildContext context,
    required WidgetRef ref,
    required PurchaseModel item,
    required void Function(bool isProcessing) onProcessingChanged,
  }) async {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    final gatewayController = TextEditingController();
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _RefundRecordingDialog(
          item: item,
          amountController: amountController,
          reasonController: reasonController,
          gatewayController: gatewayController,
          onProcessingChanged: onProcessingChanged,
          recordRefund:
              (
                String purchaseId, {
                required String operationKey,
                String? gatewayRefundId,
                int? amountPaise,
                String? reason,
              }) => ref
                  .read(adminPurchasesProvider.notifier)
                  .recordExternalRefund(
                    purchaseId,
                    operationKey: operationKey,
                    externalRefundId: gatewayRefundId,
                    amountPaise: amountPaise,
                    reason: reason,
                  ),
        ),
      );
    } finally {
      amountController.dispose();
      reasonController.dispose();
      gatewayController.dispose();
    }
  }

  static Future<void> exportVisibleRows({
    required BuildContext context,
    required List<PurchaseModel> visibleItems,
    required String selectedFilter,
    required String searchQuery,
  }) async {
    final csv = PurchaseCsvExporter.generateCsv(
      items: visibleItems,
      exportScope: 'Visible Rows',
      activeFilter: selectedFilter,
      searchQuery: searchQuery,
    );

    final filename =
        'olitun-purchases-visible-${DateTime.now().millisecondsSinceEpoch}.csv';

    try {
      await exportAnalyticsCsv(filename: filename, csv: csv);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Exported ${visibleItems.length} visible purchases as CSV',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export visible rows.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  static Future<void> exportAllMatchingRecords({
    required BuildContext context,
    required WidgetRef ref,
    required String selectedFilter,
    required String searchQuery,
    required void Function(bool isExporting, int fetchedCount) onProgress,
  }) async {
    onProgress(true, 0);

    try {
      final exportResult = await ref
          .read(adminPurchasesProvider.notifier)
          .fetchAllMatchingPurchases(
            filter: selectedFilter,
            search: searchQuery,
            onProgress: (count) => onProgress(true, count),
          );

      if (exportResult.status == PurchaseExportStatus.cancelled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchase export cancelled.')),
          );
        }
        return;
      }

      if (exportResult.status == PurchaseExportStatus.failed) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to export purchases: ${exportResult.sanitizedFailure ?? "Network error"}',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final csv = PurchaseCsvExporter.generateCsv(
        items: exportResult.items,
        exportScope: exportResult.isTruncated
            ? 'All Matching Results (Truncated)'
            : 'All Matching Results',
        activeFilter: selectedFilter,
        searchQuery: searchQuery,
        isTruncated: exportResult.isTruncated,
      );

      final filename =
          'olitun-purchases-all-matching-${DateTime.now().millisecondsSinceEpoch}.csv';

      await exportAnalyticsCsv(filename: filename, csv: csv);

      if (context.mounted) {
        if (exportResult.isTruncated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Exported first ${exportResult.exportedCount} matching purchases (safety limit reached). Narrow filters for a more targeted export.',
              ),
              backgroundColor: Colors.amber.shade800,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Exported all ${exportResult.exportedCount} matching purchases as CSV',
              ),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to fetch all matching records for export.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      onProgress(false, 0);
    }
  }
}
