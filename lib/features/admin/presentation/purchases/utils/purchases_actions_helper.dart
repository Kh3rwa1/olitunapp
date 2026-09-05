import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/features/admin/domain/purchase_csv_exporter.dart';
import 'package:itun/features/admin/presentation/analytics/admin_analytics_csv_exporter.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/purchases_provider.dart';

class PurchasesActionsHelper {
  static Future<void> showRefundDialog({
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
