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
  bool _isProcessingRefund = false;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 800;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWideScreen ? 32 : 16,
            vertical: isWideScreen ? 32 : 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                      if (mounted) {
                        setState(() => _lastRefreshed = DateTime.now());
                      }
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
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary),
                          borderRadius: BorderRadius.circular(
                            AdminTokens.radiusSm,
                          ),
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
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Exporting ($_exportFetchedCount)…',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ] else ...[
                              const Icon(
                                Icons.download_rounded,
                                color: AppColors.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              const Flexible(
                                child: Text(
                                  'Export CSV',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
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

              const SizedBox(height: 8),
              // Data freshness & completeness indicator
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: AdminTokens.textMuted(isDark),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Data freshness: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_lastRefreshed)} UTC · Loaded: ${state.items.length} records',
                      overflow: TextOverflow.ellipsis,
                      style: AdminTokens.label(isDark).copyWith(
                        color: AdminTokens.textMuted(isDark),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Main content
              Builder(
                builder: (context) {
                  if (state.isInitialLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (state.hasInitialError && state.items.isEmpty) {
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
                              state.initialFailure?.userMessage ??
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sampled / Pagination Warning or Completeness Banner
                      if (state.isSampledOrPartial) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
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
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Partial metrics — displaying loaded ${state.items.length} records. Load next pages below to compute complete historical metrics.',
                                  style: AdminTokens.body(
                                    isDark,
                                  ).copyWith(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (!state.isSampledOrPartial &&
                          state.items.length >= 50) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
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
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Complete metrics — all ${state.items.length} matching historical records loaded.',
                                  style: AdminTokens.body(
                                    isDark,
                                  ).copyWith(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // KPI Row
                      _buildKpiRow(isDark: isDark, metrics: metrics),
                      const SizedBox(height: 14),

                      // Responsive filter chips & search
                      _buildResponsiveFilters(isDark),
                      const SizedBox(height: 12),

                      // Data Table with intentional horizontal scrolling on narrow viewports
                      SizedBox(
                        height: 480,
                        child: LayoutBuilder(
                          builder: (context, tableConstraints) {
                            const minTableWidth = 720.0;
                            if (tableConstraints.maxWidth < minTableWidth) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: minTableWidth,
                                  child: _buildDataTable(filtered, isDark),
                                ),
                              );
                            }
                            return _buildDataTable(filtered, isDark);
                          },
                        ),
                      ),

                      // Load More Section & Inline Error Alert
                      _buildPaginationFooter(state, notifier, isDark),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaginationFooter(
    AdminPurchasesState state,
    AdminPurchasesNotifier notifier,
    bool isDark,
  ) {
    if (!state.hasMore && !state.hasLoadMoreError) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Inline error alert if pagination failed
          if (state.hasLoadMoreError) ...[
            Semantics(
              liveRegion: true,
              label: 'Load more purchases failed',
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(
                    alpha: isDark ? 0.20 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.loadMoreFailure?.userMessage ??
                            'Failed to load next page of purchases.',
                        style: AdminTokens.body(isDark).copyWith(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: state.isLoadingMore
                          ? null
                          : notifier.loadNextPage,
                      icon: const Icon(Icons.refresh_rounded, size: 14),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Load more button if more records exist
          if (state.hasMore)
            Center(
              child: OutlinedButton.icon(
                onPressed: state.isLoadingMore ? null : notifier.loadNextPage,
                icon: state.isLoadingMore
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more_rounded, size: 18),
                label: Text(
                  state.isLoadingMore
                      ? 'Loading More…'
                      : 'Load Next 50 Purchases',
                  style: const TextStyle(fontSize: 12),
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
    required PurchaseMetricsResult metrics,
  }) {
    final kpis = [
      _KpiItem(
        title: 'Net Revenue',
        value: _inrCurrencyFormat.format(metrics.netRevenueInr),
        subtitle: metrics.isSampledOrPartial
            ? 'Loaded (gross ${_inrCurrencyFormat.format(metrics.grossCollectedInr)} - ref ${_inrCurrencyFormat.format(metrics.refundedInr)})'
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        if (totalWidth >= 900) {
          return Row(
            children: kpis
                .map(
                  (kpi) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildKpiCard(kpi, isDark),
                    ),
                  ),
                )
                .toList(),
          );
        }

        // On medium or narrow screens, use horizontal scrollable strip to prevent vertical crowding
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: kpis
                .map(
                  (kpi) => Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 8),
                    child: _buildKpiCard(kpi, isDark),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildKpiCard(_KpiItem kpi, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        border: Border.all(color: AdminTokens.border(isDark)),
        boxShadow: AdminTokens.raisedShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  kpi.title,
                  overflow: TextOverflow.ellipsis,
                  style: AdminTokens.label(isDark).copyWith(
                    color: AdminTokens.textMuted(isDark),
                    fontSize: 11,
                  ),
                ),
              ),
              Icon(kpi.icon, size: 16, color: kpi.accentColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            kpi.value,
            style: AdminTokens.sectionTitle(
              isDark,
            ).copyWith(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          if (kpi.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              kpi.subtitle!,
              overflow: TextOverflow.ellipsis,
              style: AdminTokens.body(
                isDark,
              ).copyWith(fontSize: 10, color: AdminTokens.textMuted(isDark)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResponsiveFilters(bool isDark) {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'razorpay', 'label': 'Verified Paid'},
      {'key': 'review', 'label': 'Reviews'},
      {'key': 'refunded', 'label': 'Refunded'},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 850;

        final chips = Wrap(
          spacing: 6,
          runSpacing: 6,
          children: filters.map((f) {
            final isSelected = _selectedFilter == f['key'];
            return ChoiceChip(
              label: Text(f['label']!, style: const TextStyle(fontSize: 12)),
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
        );

        final searchField = SizedBox(
          width: isNarrow ? double.infinity : 200,
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Search Category...',
              prefixIcon: const Icon(Icons.search_rounded, size: 16),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
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
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [chips, const SizedBox(height: 8), searchField],
          );
        }

        return Row(
          children: [
            Expanded(child: chips),
            const SizedBox(width: 16),
            searchField,
          ],
        );
      },
    );
  }

  Widget _buildDataTable(List<PurchaseModel> items, bool isDark) {
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
          onPressed: _isProcessingRefund
              ? null
              : () => _showRefundDialog(context, item),
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
          'Course "${item.categoryId}" access will be removed on the user\'s next entitlement sync, normally within 5 minutes. Amount of ${_inrCurrencyFormat.format(item.amountPaidInr)} will be marked as refunded in the database.\n\n⚠️ Note: Payment disbursements must be issued separately in the Razorpay Dashboard if returning funds.',
      confirmButtonLabel: 'Record Refund & Revoke Access',
      icon: Icons.replay_circle_filled_rounded,
      onConfirm: () async {
        setState(() => _isProcessingRefund = true);
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
          if (mounted) setState(() => _isProcessingRefund = false);
        }
      },
    );

    if (confirmed == null && mounted) {
      setState(() => _isProcessingRefund = false);
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
      final exportResult = await ref
          .read(adminPurchasesProvider.notifier)
          .fetchAllMatchingPurchases(
            filter: _selectedFilter,
            search: _searchController.text.trim(),
            onProgress: (count) {
              if (mounted) setState(() => _exportFetchedCount = count);
            },
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
        activeFilter: _selectedFilter,
        searchQuery: _searchController.text.trim(),
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
