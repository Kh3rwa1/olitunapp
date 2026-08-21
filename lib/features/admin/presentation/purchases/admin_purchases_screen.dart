import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../shared/providers/providers.dart';
import '../analytics/admin_analytics_csv_exporter.dart';
import '../common/safe_csv_helper.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_glass_card.dart';
import '../widgets/admin_section_header.dart';
import '../widgets/common/admin_destructive_dialog.dart';

class AdminPurchasesScreen extends ConsumerStatefulWidget {
  const AdminPurchasesScreen({super.key});

  @override
  ConsumerState<AdminPurchasesScreen> createState() =>
      _AdminPurchasesScreenState();
}

class _AdminPurchasesScreenState extends ConsumerState<AdminPurchasesScreen> {
  String _selectedFilter = 'all'; // 'all', 'razorpay', 'review', 'refunded'
  DateTime _lastRefreshed = DateTime.now();

  static final NumberFormat _inrCurrencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final purchasesAsync = ref.watch(adminPurchasesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWideScreen ? 32 : 16,
        vertical: isWideScreen ? 32 : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          AdminSectionHeader(
            title: 'Purchases & Revenue',
            subtitle:
                'Manage course unlocks, review verified metrics, and safely process refunds',
            icon: Icons.shopping_bag_rounded,
            eyebrow: 'PRODUCT OPS · MONETIZATION',
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh Purchases Data',
                onPressed: () async {
                  await ref
                      .read(adminPurchasesProvider.notifier)
                      .loadPurchases();
                  if (mounted) setState(() => _lastRefreshed = DateTime.now());
                },
              ),
              const SizedBox(width: 8),
              purchasesAsync.maybeWhen(
                data: (items) => OutlinedButton.icon(
                  onPressed: items.isEmpty
                      ? null
                      : () => _exportToCsv(context, items),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                    ),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text(
                    'Export CSV',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),

          const SizedBox(height: 12),
          // Data freshness indicator
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 13,
                color: AdminTokens.textMuted(isDark),
              ),
              const SizedBox(width: 6),
              Text(
                'Data freshness: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_lastRefreshed)} (UTC/Local)',
                style: AdminTokens.label(
                  isDark,
                ).copyWith(color: AdminTokens.textMuted(isDark), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main content
          Expanded(
            child: purchasesAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return AdminEmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'No purchases yet',
                    message:
                        'Once users unlock premium courses, transaction details will appear here.',
                    actionLabel: 'Refresh',
                    onAction: () => ref
                        .read(adminPurchasesProvider.notifier)
                        .loadPurchases(),
                  );
                }

                // Compute exact revenue & transaction metrics
                final grossRevenue = items
                    .where(
                      (p) =>
                          p.status == 'verified' &&
                          p.unlockMethod == 'razorpay',
                    )
                    .fold(0, (sum, p) => sum + p.amountPaidInr);

                final refundedAmount = items
                    .where((p) => p.status == 'refunded')
                    .fold(0, (sum, p) => sum + p.amountPaidInr);

                final netRevenue = grossRevenue - refundedAmount;

                final paidCount = items
                    .where(
                      (p) =>
                          p.unlockMethod == 'razorpay' &&
                          p.status == 'verified',
                    )
                    .length;

                final refundedCount = items
                    .where((p) => p.status == 'refunded')
                    .length;

                final reviewCount = items
                    .where((p) => p.unlockMethod == 'play_store_review')
                    .length;

                // Accurate "Verified Paid Share" (percentage of verified unlocks that were paid)
                final totalVerifiedUnlocks = paidCount + reviewCount;
                final verifiedPaidShare = totalVerifiedUnlocks > 0
                    ? (paidCount / totalVerifiedUnlocks * 100).toStringAsFixed(
                        1,
                      )
                    : '0.0';

                // Filter list
                final filtered = items.where((p) {
                  if (_selectedFilter == 'razorpay') {
                    return p.unlockMethod == 'razorpay' &&
                        p.status == 'verified';
                  }
                  if (_selectedFilter == 'review') {
                    return p.unlockMethod == 'play_store_review';
                  }
                  if (_selectedFilter == 'refunded') {
                    return p.status == 'refunded';
                  }
                  return true;
                }).toList();

                return Column(
                  children: [
                    // KPI Row
                    _buildKpiRow(
                      isDark: isDark,
                      isWide: isWideScreen,
                      netRevenue: netRevenue,
                      grossRevenue: grossRevenue,
                      refundedAmount: refundedAmount,
                      paidCount: paidCount,
                      refundedCount: refundedCount,
                      reviewCount: reviewCount,
                      verifiedPaidShare: verifiedPaidShare,
                    ),
                    const SizedBox(height: 20),

                    // Filter chips row
                    _buildFilterChips(isDark),
                    const SizedBox(height: 16),

                    // Data Table
                    Expanded(child: _buildDataTable(filtered, isDark)),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 36,
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        'Unable to load purchases data. Please check connection and retry.',
                        style: AdminTokens.body(isDark),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        onPressed: () => ref
                            .read(adminPurchasesProvider.notifier)
                            .loadPurchases(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow({
    required bool isDark,
    required bool isWide,
    required int netRevenue,
    required int grossRevenue,
    required int refundedAmount,
    required int paidCount,
    required int refundedCount,
    required int reviewCount,
    required String verifiedPaidShare,
  }) {
    final cardStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      fontFamily: 'Poppins',
      color: AdminTokens.textPrimary(isDark),
    );

    final cards = [
      _KpiItem(
        title: 'Net Revenue',
        value: _inrCurrencyFormat.format(netRevenue),
        subtitle:
            'Gross: ${_inrCurrencyFormat.format(grossRevenue)} · Refunds: ${_inrCurrencyFormat.format(refundedAmount)}',
        icon: Icons.account_balance_wallet_rounded,
        accentColor: Colors.green,
      ),
      _KpiItem(
        title: 'Paid Transactions',
        value: paidCount.toString(),
        subtitle: 'Refunded count: $refundedCount',
        icon: Icons.payment_rounded,
        accentColor: Colors.blue,
      ),
      _KpiItem(
        title: 'Review Unlocks',
        value: reviewCount.toString(),
        subtitle: 'Free Play Store review unlock',
        icon: Icons.rate_review_rounded,
        accentColor: Colors.purple,
      ),
      _KpiItem(
        title: 'Verified Paid Share',
        value: '$verifiedPaidShare%',
        subtitle: 'Paid unlocks / Total unlocks',
        tooltip:
            'Share of verified course unlocks that were monetized via paid transactions vs free review unlocks.',
        icon: Icons.pie_chart_rounded,
        accentColor: Colors.orange,
      ),
    ];

    if (isWide) {
      return Row(
        children: cards
            .map(
              (c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildKpiCard(isDark, c, cardStyle),
                ),
              ),
            )
            .toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth < 400 ? 1 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cols,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: cols == 1 ? 2.8 : 1.5,
          children: cards
              .map((c) => _buildKpiCard(isDark, c, cardStyle))
              .toList(),
        );
      },
    );
  }

  Widget _buildKpiCard(bool isDark, _KpiItem card, TextStyle cardStyle) {
    return AdminGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        card.title.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AdminTokens.textMuted(isDark),
                          letterSpacing: 0.8,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (card.tooltip != null) ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: card.tooltip!,
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 13,
                          color: AdminTokens.textMuted(isDark),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: card.accentColor.withValues(
                    alpha: isDark ? 0.16 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(card.icon, size: 16, color: card.accentColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(card.value, style: cardStyle),
          if (card.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              card.subtitle!,
              style: TextStyle(
                fontSize: 10.5,
                color: AdminTokens.textSecondary(isDark),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('All Purchases', 'all', isDark),
          const SizedBox(width: 8),
          _chip('Paid Only', 'razorpay', isDark),
          const SizedBox(width: 8),
          _chip('Review Unlocks', 'review', isDark),
          const SizedBox(width: 8),
          _chip('Refunded', 'refunded', isDark),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, bool isDark) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AdminTokens.textPrimary(isDark),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AdminTokens.sunken(isDark),
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = value);
      },
    );
  }

  Widget _buildDataTable(List<PurchaseModel> items, bool isDark) {
    return AdminDataTable<PurchaseModel>(
      items: items,
      searchHint: 'Search userId, paymentId, orderId...',
      searchPredicate: (item, query) {
        return item.userId.toLowerCase().contains(query) ||
            item.categoryId.toLowerCase().contains(query) ||
            (item.razorpayPaymentId?.toLowerCase().contains(query) ?? false) ||
            (item.razorpayOrderId?.toLowerCase().contains(query) ?? false);
      },
      columns: [
        AdminColumn<PurchaseModel>(
          label: 'User ID',
          flex: 2,
          cellBuilder: (item) => Text(
            item.userId,
            style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AdminColumn<PurchaseModel>(
          label: 'Course / Category',
          flex: 2,
          cellBuilder: (item) => Text(
            item.categoryId,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        AdminColumn<PurchaseModel>(
          label: 'Method',
          flex: 2,
          cellBuilder: (item) {
            final isReview = item.unlockMethod == 'play_store_review';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isReview ? Colors.purple : Colors.blue).withValues(
                  alpha: isDark ? 0.20 : 0.12,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isReview ? 'Review' : 'Razorpay',
                style: TextStyle(
                  color: isReview ? Colors.purpleAccent : Colors.blueAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
        AdminColumn<PurchaseModel>(
          label: 'Amount',
          cellBuilder: (item) => Text(
            _inrCurrencyFormat.format(item.amountPaidInr),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          comparator: (a, b) => a.amountPaidInr.compareTo(b.amountPaidInr),
        ),
        AdminColumn<PurchaseModel>(
          label: 'Date',
          flex: 2,
          cellBuilder: (item) {
            final dt = DateTime.tryParse(item.purchasedAt);
            if (dt == null) return const Text('—');
            return Text(
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 11, fontFamily: 'Poppins'),
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
          tooltip: 'Issue Refund',
          onPressed: () => _showRefundDialog(context, item),
        );
      },
    );
  }

  Future<void> _showRefundDialog(
    BuildContext context,
    PurchaseModel item,
  ) async {
    final confirmed = await AdminDestructiveDialog.show(
      context: context,
      title: 'Issue Purchase Refund',
      actionName: 'Refund & Revoke Access',
      targetName:
          'Payment ID: ${item.razorpayPaymentId ?? item.id} (User: ${item.userId})',
      blastRadiusDescription:
          'Course "${item.categoryId}" access will be revoked immediately. The amount of ${_inrCurrencyFormat.format(item.amountPaidInr)} will be marked as refunded.',
      confirmButtonLabel:
          'Confirm Refund (${_inrCurrencyFormat.format(item.amountPaidInr)})',
      icon: Icons.replay_circle_filled_rounded,
      onConfirm: () async {
        await ref.read(adminPurchasesProvider.notifier).refundPurchase(item.id);
      },
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refund issued and course access revoked.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _exportToCsv(
    BuildContext context,
    List<PurchaseModel> items,
  ) async {
    final headers = [
      'Purchase ID',
      'User ID',
      'Category ID',
      'Unlock Method',
      'Amount (INR)',
      'Razorpay Payment ID',
      'Razorpay Order ID',
      'Status',
      'Purchased At',
      'Verified At',
    ];

    final rows = items.map((p) {
      return <Object?>[
        p.id,
        p.userId,
        p.categoryId,
        p.unlockMethod,
        p.amountPaidInr,
        p.razorpayPaymentId ?? '',
        p.razorpayOrderId ?? '',
        p.status,
        p.purchasedAt,
        p.verifiedAt ?? '',
      ];
    }).toList();

    final metadata = {
      'Generated At': DateTime.now().toUtc().toIso8601String(),
      'Active Filter': _selectedFilter,
      'Total Records': items.length.toString(),
    };

    final csv = SafeCsvHelper.buildCsv(
      headers: headers,
      rows: rows,
      metadata: metadata,
    );

    final filename =
        'olitun-course-purchases-${DateTime.now().millisecondsSinceEpoch}.csv';

    try {
      await exportAnalyticsCsv(filename: filename, csv: csv);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchases exported as $analyticsCsvExportLabel'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export CSV.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _KpiItem {
  final String title;
  final String value;
  final String? subtitle;
  final String? tooltip;
  final IconData icon;
  final Color accentColor;

  _KpiItem({
    required this.title,
    required this.value,
    this.subtitle,
    this.tooltip,
    required this.icon,
    required this.accentColor,
  });
}
