import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:itun/core/theme/admin_tokens.dart';
import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/features/admin/presentation/widgets/admin_data_table.dart';
import 'package:itun/shared/models/content_models.dart';

class PurchasesDataTable extends StatelessWidget {
  final List<PurchaseModel> items;
  final bool isDark;
  final bool isProcessingRefund;
  final ValueChanged<PurchaseModel> onRefundRequested;

  const PurchasesDataTable({
    super.key,
    required this.items,
    required this.isDark,
    required this.isProcessingRefund,
    required this.onRefundRequested,
  });

  static final NumberFormat _inrCurrencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No transactions match the selected filter.',
            style: AdminTokens.body(isDark),
          ),
        ),
      );
    }

    return AdminDataTable<PurchaseModel>(
      items: items,
      searchPredicate: (item, query) =>
          item.categoryId.toLowerCase().contains(query.toLowerCase()) ||
          (item.razorpayPaymentId?.toLowerCase().contains(
                query.toLowerCase(),
              ) ??
              false) ||
          item.userId.toLowerCase().contains(query.toLowerCase()),
      columns: [
        AdminColumn<PurchaseModel>(
          label: 'Transaction / Order',
          flex: 4,
          cellBuilder: (item) {
            final isRazorpay = item.unlockMethod == 'razorpay';
            final paymentId = item.razorpayPaymentId ?? item.id;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      isRazorpay
                          ? Icons.verified_rounded
                          : Icons.card_giftcard_rounded,
                      size: 14,
                      color: isRazorpay ? AppColors.primary : Colors.blueAccent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        paymentId,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.razorpayOrderId != null &&
                    item.razorpayOrderId!.isNotEmpty)
                  Text(
                    'Order: ${item.razorpayOrderId}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: AdminTokens.textMuted(isDark),
                    ),
                  ),
              ],
            );
          },
        ),
        AdminColumn<PurchaseModel>(
          label: 'User',
          flex: 2,
          cellBuilder: (item) {
            final masked = item.userId.length > 6
                ? 'u_${item.userId.substring(0, 4)}***'
                : item.userId;
            return Text(
              masked,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            );
          },
        ),
        AdminColumn<PurchaseModel>(
          label: 'Category',
          flex: 3,
          cellBuilder: (item) => Text(
            item.categoryId,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        AdminColumn<PurchaseModel>(
          label: 'Amount',
          flex: 2,
          cellBuilder: (item) {
            if (item.unlockMethod != 'razorpay') {
              return const Text(
                'Free / Review',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              );
            }
            return Text(
              _inrCurrencyFormat.format(item.amountPaidInr),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: item.status == 'refunded'
                    ? Colors.orange
                    : AppColors.primary,
              ),
            );
          },
        ),
        AdminColumn<PurchaseModel>(
          label: 'Date',
          flex: 2,
          cellBuilder: (item) {
            String dateFormatted = item.purchasedAt;
            try {
              final parsed = DateTime.parse(item.purchasedAt);
              dateFormatted = DateFormat('yyyy-MM-dd').format(parsed);
            } catch (_) {}
            return Text(
              dateFormatted,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: AdminTokens.textMuted(isDark),
              ),
            );
          },
        ),
        AdminColumn<PurchaseModel>(
          label: 'Status',
          flex: 2,
          cellBuilder: (item) {
            final status = item.status;
            Color c = Colors.grey;
            if (status == 'verified') c = Colors.green;
            if (status == 'failed') c = Colors.red;
            if (status == 'refunded') c = Colors.orange;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: c.withValues(alpha: isDark ? 0.20 : 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            );
          },
        ),
      ],
      trailingBuilder: (item) {
        if (item.status != 'verified' || item.unlockMethod != 'razorpay') {
          return const SizedBox.shrink();
        }
        return IconButton(
          icon: const Icon(
            Icons.replay_circle_filled_rounded,
            color: Colors.orange,
            size: 20,
          ),
          tooltip: 'Record Refund in Database & Revoke Access',
          onPressed: isProcessingRefund ? null : () => onRefundRequested(item),
        );
      },
    );
  }
}
