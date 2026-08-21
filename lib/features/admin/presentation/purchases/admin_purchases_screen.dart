import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../shared/providers/purchases_provider.dart';
import '../../domain/purchase_csv_exporter.dart';
import '../../domain/purchase_metrics_calculator.dart';
import '../analytics/admin_analytics_csv_exporter.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_section_header.dart';
import '../widgets/common/admin_destructive_dialog.dart';

class AdminPurchasesScreen extends ConsumerStatefulWidget {
  const AdminPurchasesScreen({super.key});

  @override
  ConsumerState<AdminPurchasesScreen> createState() =>
      _AdminPurchasesScreenState();
}

class _AdminPurchasesScreenState extends ConsumerState<AdminPurchasesScreen> {
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  DateTime _lastRefreshed = DateTime.now();
  bool _isExportingAll = false;
  int _exportFetchedCount = 0;

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
    final state = ref.watch(adminPurchasesProvider);
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
              if (state.items.isNotEmpty)
                PopupMenuButton<String>(
                  tooltip: 'Export CSV Options',
                  enabled: !_isExportingAll,
                  onSelected: (option) {
                    if (option == 'visible') {
                      _exportVisibleRows(
                        context,
                        _getFilteredItems(state.items),
                      );
                    } else if (option == 'all_matching') {
                      _exportAllMatchingRecords(context);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'visible',
                      child: Row(
                        children: [
                          const Icon(Icons.filter_list_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Export Visible Rows (${_getFilteredItems(state.items).length} rows)',
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'all_matching',
                      child: Row(
                        children: [
                          Icon(Icons.cloud_download_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Export All Matching (Server Query)'),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isExportingAll) ...[
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Exporting ($_exportFetchedCount)…',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ] else ...[
                          const Icon(
                            Icons.download_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Export CSV',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                  ),
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
                'Data freshness: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_lastRefreshed)} UTC · Loaded: ${state.items.length} records',
                style: AdminTokens.label(
                  isDark,
                ).copyWith(color: AdminTokens.textMuted(isDark), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main content
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.isInitialLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.hasError && state.items.isEmpty) {
                  return Center(
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
                            state.failure?.userMessage ??
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
                  );
                }

                if (state.items.isEmpty) {
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

                final metrics = state.metrics;
                final filtered = _getFilteredItems(state.items);

                return Column(
                  children: [
                    // Sampled / Pagination Warning or Completeness Banner
                    if (state.isSampledOrPartial) ...[
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
                                'Partial metrics — displaying loaded ${state.items.length} records. Load next pages below to compute complete historical metrics.',
                                style: AdminTokens.body(
                                  isDark,
                                ).copyWith(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (!state.isSampledOrPartial &&
                        state.items.length >= 50) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(
                            alpha: isDark ? 0.16 : 0.10,
                          ),
                          borderRadius: BorderRadius.circular(
                            AdminTokens.radiusSm,
                          ),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              color: Colors.green,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Complete metrics — all ${state.items.length} matching historical records loaded.',
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
                    if (state.hasMore) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: state.isLoadingMore
                              ? null
                              : () => ref
                                    .read(adminPurchasesProvider.notifier)
                                    .loadNextPage(),
                          icon: state.isLoadingMore
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.expand_more_rounded),
                          label: Text(
                            state.isLoadingMore
                                ? 'Loading More…'
                                : 'Load Next 50 Purchases',
                          ),
                        ),
                      ),
                    ] else if (state.hasError && state.items.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AdminTokens.radiusSm,
                          ),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              state.failure?.userMessage ??
                                  'Failed to load older records.',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: notifier.loadNextPage,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
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
        subtitle: metrics.isSampledOrPartial
            ? 'Loaded rows (gross ${_inrCurrencyFormat.format(metrics.grossCollectedInr)} - ref ${_inrCurrencyFormat.format(metrics.refundedInr)})'
            : 'Gross ${_inrCurrencyFormat.format(metrics.grossCollectedInr)} - Refunds ${_inrCurrencyFormat.format(metrics.refundedInr)}',
        tooltip:
            'Net = Gross Collected - Confirmed Refunds. Does not double-subtract.',
        icon: Icons.currency_rupee_rounded,
        accentColor: AppColors.primary,
      ),
      _KpiItem(
        title: 'Verified Unlocks',
        value: '${metrics.activePaidCount + metrics.reviewUnlockCount}',
        subtitle:
            '${metrics.activePaidCount} Paid (${metrics.verifiedPaidShare.toStringAsFixed(0)}%) · ${metrics.reviewUnlockCount} Review',
        tooltip:
            'Combined verified course unlock volume across Razorpay and Review flows.',
        icon: Icons.lock_open_rounded,
        accentColor: Colors.blueAccent,
      ),
      _KpiItem(
        title: 'Confirmed Refunds',
        value: metrics.refundedCount.toString(),
        subtitle: _inrCurrencyFormat.format(metrics.refundedInr),
        tooltip:
            'Total refunded transactions recorded. Amounts subtracted once from gross revenue.',
        icon: Icons.replay_circle_filled_rounded,
        accentColor: Colors.orange,
      ),
      _KpiItem(
        title: 'Failed Payments',
        value: metrics.failedCount.toString(),
        subtitle: 'Abandoned / Failed',
        tooltip:
            'Uncompleted payment attempts. Never counted in collected revenue.',
        icon: Icons.cancel_outlined,
        accentColor: AppColors.error,
      ),
    ];

    if (!isWide) {
      return Column(
        children: kpis
            .map(
              (kpi) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildKpiCard(kpi, isDark),
              ),
            )
            .toList(),
      );
    }

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

  Widget _buildKpiCard(_KpiItem kpi, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        border: Border.all(color: AdminTokens.border(isDark)),
        boxShadow: AdminTokens.raisedShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                kpi.title,
                style: AdminTokens.label(
                  isDark,
                ).copyWith(color: AdminTokens.textMuted(isDark)),
              ),
              Icon(kpi.icon, size: 20, color: kpi.accentColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            kpi.value,
            style: AdminTokens.sectionTitle(
              isDark,
            ).copyWith(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          if (kpi.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              kpi.subtitle!,
              style: AdminTokens.body(
                isDark,
              ).copyWith(fontSize: 11, color: AdminTokens.textMuted(isDark)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final filters = [
      {'key': 'all', 'label': 'All Transactions'},
      {'key': 'razorpay', 'label': 'Verified Paid'},
      {'key': 'review', 'label': 'Play Store Reviews'},
      {'key': 'refunded', 'label': 'Refunded'},
    ];

    return Row(
      children: [
        Wrap(
          spacing: 8,
          children: filters.map((f) {
            final isSelected = _selectedFilter == f['key'];
            return ChoiceChip(
              label: Text(f['label']!),
              selected: isSelected,
              selectedColor: AppColors.primary.withValues(
                alpha: isDark ? 0.35 : 0.20,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = f['key']!);
                  ref
                      .read(adminPurchasesProvider.notifier)
                      .loadPurchases(filter: f['key']!);
                }
              },
            );
          }).toList(),
        ),
        const Spacer(),
        SizedBox(
          width: 220,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Category...',
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                borderSide: BorderSide(color: AdminTokens.border(isDark)),
              ),
            ),
            onSubmitted: (query) {
              ref
                  .read(adminPurchasesProvider.notifier)
                  .loadPurchases(filter: _selectedFilter, search: query);
            },
          ),
        ),
      ],
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
          'Course "${item.categoryId}" access will be revoked in the Olitun database. Amount of ${_inrCurrencyFormat.format(item.amountPaidInr)} will be marked as refunded.\n\n⚠️ Note: Database status updates immediately. Remote client access revokes upon next entitlement sync (within 5 minutes). Payment disbursements must be issued separately in the Razorpay Dashboard.',
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

  Future<void> _exportVisibleRows(
    BuildContext context,
    List<PurchaseModel> visibleItems,
  ) async {
    final csv = PurchaseCsvExporter.generateCsv(
      items: visibleItems,
      exportScope: 'Visible Rows',
      activeFilter: _selectedFilter,
      searchQuery: _searchController.text.trim(),
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

  Future<void> _exportAllMatchingRecords(BuildContext context) async {
    setState(() {
      _isExportingAll = true;
      _exportFetchedCount = 0;
    });

    try {
      final allItems = await ref
          .read(adminPurchasesProvider.notifier)
          .fetchAllMatchingPurchases(
            filter: _selectedFilter,
            search: _searchController.text.trim(),
            onProgress: (count) {
              if (mounted) setState(() => _exportFetchedCount = count);
            },
          );

      final csv = PurchaseCsvExporter.generateCsv(
        items: allItems,
        exportScope: 'All Matching Results',
        activeFilter: _selectedFilter,
        searchQuery: _searchController.text.trim(),
      );

      final filename =
          'olitun-purchases-all-matching-${DateTime.now().millisecondsSinceEpoch}.csv';

      await exportAnalyticsCsv(filename: filename, csv: csv);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Exported all ${allItems.length} matching purchases as CSV',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
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
      if (mounted) setState(() => _isExportingAll = false);
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
