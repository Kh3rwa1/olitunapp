import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../shared/providers/purchases_provider.dart';
import '../../domain/purchase_metrics_calculator.dart';
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
  final TextEditingController _searchController = TextEditingController();

  static final NumberFormat _inrCurrencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchasesAsync = ref.watch(adminPurchasesProvider);
    final notifier = ref.read(adminPurchasesProvider.notifier);
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
                'Manage course unlocks, review verified metrics, and safely record refunds',
            icon: Icons.shopping_bag_rounded,
            eyebrow: 'PRODUCT OPS · MONETIZATION',
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh Purchases Data',
                onPressed: () async {
                  await ref
                      .read(adminPurchasesProvider.notifier)
                      .loadPurchases(filter: _selectedFilter);
                  if (mounted) setState(() => _lastRefreshed = DateTime.now());
                },
              ),
              const SizedBox(width: 8),
              purchasesAsync.maybeWhen(
                data: (items) => PopupMenuButton<String>(
                  tooltip: 'Export CSV Options',
                  onSelected: (option) => _exportToCsv(
                    context,
                    items,
                    exportFilteredOnly: option == 'filtered',
                  ),
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'filtered',
                      child: Row(
                        children: [
                          const Icon(Icons.filter_list_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Export Filtered (${_getFilteredItems(items).length} rows)',
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'all',
                      child: Row(
                        children: [
                          const Icon(Icons.download_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text('Export All (${items.length} rows)'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.download_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Export CSV',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),

          const SizedBox(height: 12),
          // Data freshness & completeness indicator
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 13,
                color: AdminTokens.textMuted(isDark),
              ),
              const SizedBox(width: 6),
              Text(
                'Data freshness: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_lastRefreshed)} UTC · Loaded: ${purchasesAsync.valueOrNull?.length ?? 0} records',
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
                        .loadPurchases(filter: _selectedFilter),
                  );
                }

                // Authoritative, pure accounting computation
                final metrics = PurchaseMetricsCalculator.calculate(
                  items,
                  isSampledOrPartial: notifier.isSampledOrPartial,
                );

                final filtered = _getFilteredItems(items);

                return Column(
                  children: [
                    // Sampled / Pagination Warning Banner if applicable
                    if (metrics.isSampledOrPartial) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(
                            alpha: isDark ? 0.16 : 0.10,
                          ),
                          borderRadius: BorderRadius.circular(
                            AdminTokens.radiusSm,
                          ),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Displaying first ${items.length} records. Use pagination controls below to load older transactions.',
                                style: AdminTokens.body(
                                  isDark,
                                ).copyWith(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // KPI Row
                    _buildKpiRow(
                      isDark: isDark,
                      isWide: isWideScreen,
                      metrics: metrics,
                    ),
                    const SizedBox(height: 20),

                    // Filter chips row & search
                    _buildFilterChips(isDark),
                    const SizedBox(height: 16),

                    // Data Table
                    Expanded(child: _buildDataTable(filtered, isDark)),

                    // Load More Footer if cursor pagination has more records
                    if (notifier.hasMore) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: notifier.isLoadingMore
                              ? null
                              : () => ref
                                    .read(adminPurchasesProvider.notifier)
                                    .loadNextPage(),
                          icon: notifier.isLoadingMore
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.expand_more_rounded),
                          label: Text(
                            notifier.isLoadingMore
                                ? 'Loading More…'
                                : 'Load Next 50 Purchases',
                          ),
                        ),
                      ),
                    ],
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
                            .loadPurchases(filter: _selectedFilter),
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

  List<PurchaseModel> _getFilteredItems(List<PurchaseModel> items) {
    return items.where((p) {
      if (_selectedFilter == 'razorpay') {
        return p.unlockMethod == 'razorpay' && p.status == 'verified';
      }
      if (_selectedFilter == 'review') {
        return p.unlockMethod == 'play_store_review';
      }
      if (_selectedFilter == 'refunded') {
        return p.status == 'refunded';
      }
      return true;
    }).toList();
  }

  Widget _buildKpiRow({
    required bool isDark,
    required bool isWide,
    required PurchaseMetricsResult metrics,
  }) {
    final kpis = [
      _KpiItem(
        title: 'Net Revenue',
        value: _inrCurrencyFormat.format(metrics.netRevenueInr),
        subtitle:
            'Gross ${_inrCurrencyFormat.format(metrics.grossCollectedInr)} - Refund ${_inrCurrencyFormat.format(metrics.refundedInr)}',
        tooltip:
            'Total net revenue (Gross Collected ₹${metrics.grossCollectedInr} minus Confirmed Refunds ₹${metrics.refundedInr}). Verified paid payments originally collected are never double-subtracted.',
        icon: Icons.account_balance_wallet_rounded,
        accentColor: AppColors.primary,
      ),
      _KpiItem(
        title: 'Gross Collected',
        value: _inrCurrencyFormat.format(metrics.grossCollectedInr),
        subtitle: '${metrics.verifiedPaidCount} paid transactions',
        tooltip:
            'Total payments successfully collected through Razorpay before any refunds. Includes active (₹${metrics.grossCollectedInr - metrics.refundedInr}) and refunded (₹${metrics.refundedInr}).',
        icon: Icons.payments_rounded,
        accentColor: AppColors.success,
      ),
      _KpiItem(
        title: 'Total Refunded',
        value: _inrCurrencyFormat.format(metrics.refundedInr),
        subtitle: '${metrics.refundedCount} transactions refunded',
        tooltip:
            'Total amount recorded as refunded across all processed refunds. Course access is revoked upon refund.',
        icon: Icons.replay_circle_filled_rounded,
        accentColor: Colors.orange,
      ),
      _KpiItem(
        title: 'Verified Paid Share',
        value: '${metrics.verifiedPaidShare.toStringAsFixed(1)}%',
        subtitle:
            '${metrics.activePaidCount} Paid / ${metrics.activePaidCount + metrics.reviewUnlockCount} Unlocks',
        tooltip:
            'Monetized share of verified course unlocks: ${metrics.activePaidCount} paid vs ${metrics.reviewUnlockCount} unlocked via Play Store reviews.',
        icon: Icons.pie_chart_outline_rounded,
        accentColor: Colors.blueAccent,
      ),
    ];

    if (isWide) {
      return Row(
        children: kpis
            .map(
              (kpi) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _buildKpiCard(kpi, isDark),
                ),
              ),
            )
            .toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final halfWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: kpis
              .map(
                (kpi) => SizedBox(
                  width: halfWidth,
                  child: _buildKpiCard(kpi, isDark),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildKpiCard(_KpiItem kpi, bool isDark) {
    final cardContent = AdminGlassCard(
      borderRadius: AdminTokens.radiusMd,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    kpi.title.toUpperCase(),
                    style: AdminTokens.label(isDark).copyWith(
                      letterSpacing: 0.8,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: kpi.accentColor.withValues(
                      alpha: isDark ? 0.16 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(kpi.icon, size: 16, color: kpi.accentColor),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              kpi.value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AdminTokens.textPrimary(isDark),
                letterSpacing: -0.5,
              ),
            ),
            if (kpi.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                kpi.subtitle!,
                style: AdminTokens.label(isDark).copyWith(
                  color: AdminTokens.textSecondary(isDark),
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );

    if (kpi.tooltip != null) {
      return Tooltip(
        message: kpi.tooltip!,
        preferBelow: false,
        decoration: BoxDecoration(
          color: isDark ? Colors.black87 : Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        child: cardContent,
      );
    }

    return cardContent;
  }

  Widget _buildFilterChips(bool isDark) {
    final filters = [
      {'id': 'all', 'label': 'All Transactions', 'icon': Icons.list_rounded},
      {
        'id': 'razorpay',
        'label': 'Razorpay Paid',
        'icon': Icons.payment_rounded,
      },
      {
        'id': 'review',
        'label': 'Review Unlocks',
        'icon': Icons.rate_review_rounded,
      },
      {'id': 'refunded', 'label': 'Refunded', 'icon': Icons.replay_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(
                f['icon'] as IconData,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : AdminTokens.textSecondary(isDark),
              ),
              label: Text(
                f['label'] as String,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                  color: isSelected
                      ? Colors.white
                      : AdminTokens.textPrimary(isDark),
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AdminTokens.sunken(isDark),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : AdminTokens.border(isDark),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = f['id'] as String);
                  ref
                      .read(adminPurchasesProvider.notifier)
                      .loadPurchases(filter: f['id'] as String);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDataTable(List<PurchaseModel> items, bool isDark) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'User: ${item.userId.length > 8 ? "${item.userId.substring(0, 8)}…" : item.userId}',
                  style: AdminTokens.label(isDark).copyWith(
                    color: AdminTokens.textSecondary(isDark),
                    fontSize: 11,
                  ),
                ),
              ],
            );
          },
        ),
        AdminColumn<PurchaseModel>(
          label: 'Course',
          flex: 3,
          cellBuilder: (item) {
            return Text(
              item.categoryId,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            );
          },
          comparator: (a, b) => a.categoryId.compareTo(b.categoryId),
        ),
        AdminColumn<PurchaseModel>(
          label: 'Unlock Method',
          flex: 3,
          cellBuilder: (item) {
            final isRazorpay = item.unlockMethod == 'razorpay';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isRazorpay
                    ? AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.10)
                    : Colors.blue.withValues(alpha: isDark ? 0.16 : 0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isRazorpay ? 'RAZORPAY' : 'REVIEW UNLOCK',
                style: TextStyle(
                  color: isRazorpay ? AppColors.primary : Colors.blueAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            );
          },
        ),
        AdminColumn<PurchaseModel>(
          label: 'Amount',
          flex: 2,
          cellBuilder: (item) => Text(
            _inrCurrencyFormat.format(item.amountPaidInr),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
          tooltip: 'Record Refund in Database & Revoke Access',
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
      title: 'Record External Refund & Revoke Access',
      actionName: 'Record Refund in Database',
      targetName:
          'Payment: ${item.razorpayPaymentId ?? item.id} (User: ${item.userId})',
      blastRadiusDescription:
          'Course "${item.categoryId}" access will be revoked immediately in the Olitun database. Amount of ${_inrCurrencyFormat.format(item.amountPaidInr)} will be marked as refunded.\n\n⚠️ Note: This action updates database access status and does NOT automatically disburse money via Razorpay. Ensure payment refund is issued in Razorpay Dashboard if returning funds.',
      confirmButtonLabel: 'Record Refund & Revoke Access',
      icon: Icons.replay_circle_filled_rounded,
      onConfirm: () async {
        await ref
            .read(adminPurchasesProvider.notifier)
            .recordExternalRefund(item.id);
      },
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Refund recorded in database and course access revoked.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _exportToCsv(
    BuildContext context,
    List<PurchaseModel> items, {
    bool exportFilteredOnly = false,
  }) async {
    final exportList = exportFilteredOnly ? _getFilteredItems(items) : items;

    final headers = [
      'Purchase ID',
      'Masked User ID',
      'Category ID',
      'Unlock Method',
      'Amount (INR)',
      'Razorpay Payment ID',
      'Razorpay Order ID',
      'Status',
      'Purchased At (UTC)',
      'Verified At (UTC)',
    ];

    final rows = exportList.map((p) {
      final maskedUserId = p.userId.length > 6
          ? 'u_${p.userId.substring(0, 4)}***'
          : p.userId;

      return <Object?>[
        p.id,
        maskedUserId,
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
      'Export Date (UTC)': DateTime.now().toUtc().toIso8601String(),
      'Export Scope': exportFilteredOnly
          ? 'Filtered Results'
          : 'All Loaded Records',
      'Active Filter': _selectedFilter,
      'Total Export Rows': exportList.length.toString(),
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
          SnackBar(
            content: Text(
              'Exported ${exportList.length} purchases as $analyticsCsvExportLabel',
            ),
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
