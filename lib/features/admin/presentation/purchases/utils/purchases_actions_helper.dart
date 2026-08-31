import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/features/admin/domain/purchase_csv_exporter.dart';
import 'package:itun/features/admin/presentation/analytics/admin_analytics_csv_exporter.dart';
import 'package:itun/features/admin/presentation/widgets/common/admin_destructive_dialog.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/purchases_provider.dart';

class PurchasesActionsHelper {
  static final NumberFormat _inrCurrencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static Future<void> showRefundDialog({
    required BuildContext context,
    required WidgetRef ref,
    required PurchaseModel item,
    required void Function(bool isProcessing) onProcessingChanged,
  }) async {
    final confirmed = await AdminDestructiveDialog.show(
      context: context,
      title: 'Record External Refund & Revoke Access',
      actionName: 'Record Refund in Database',
      targetName:
          'Payment: ${item.razorpayPaymentId ?? item.id} (User: ${item.userId})',
      blastRadiusDescription:
          'Course "${item.categoryId}" access will be removed on the user\'s next entitlement sync, normally within 5 minutes. Amount of ${_inrCurrencyFormat.format(item.amountPaidInr)} will be marked as refunded in the database.\n\n⚠️ Note: Payment disbursements must be issued separately in the Razorpay Dashboard if returning funds.',
      confirmButtonLabel: 'Record Refund & Revoke Access',
      icon: Icons.replay_circle_filled_rounded,
      onConfirm: () async {
        onProcessingChanged(true);
        try {
          final outcome = await ref
              .read(adminPurchasesProvider.notifier)
              .recordExternalRefund(
                item.id,
                idempotencyKey:
                    'rfnd_${item.id}_${DateTime.now().millisecondsSinceEpoch}',
              );

          if (!context.mounted) return;

          if (outcome == RefundResult.completed ||
              outcome == RefundResult.alreadyRefunded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Refund recorded. Access will be removed on the user’s next entitlement sync, normally within five minutes.',
                ),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (outcome == RefundResult.invalidTransition) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Cannot refund: Transaction is not in a verified state.',
                ),
                backgroundColor: AppColors.error,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to record refund in database.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        } finally {
          onProcessingChanged(false);
        }
      },
    );

    if (confirmed == null) {
      onProcessingChanged(false);
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
