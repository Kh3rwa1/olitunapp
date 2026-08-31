import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../shared/providers/purchases_provider.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_section_header.dart';
import 'utils/purchases_actions_helper.dart';
import 'widgets/purchases_data_table.dart';
import 'widgets/purchases_filter_bar.dart';
import 'widgets/purchases_kpi_section.dart';
import 'widgets/purchases_pagination_footer.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                          PurchasesActionsHelper.exportVisibleRows(
                            context: context,
                            visibleItems: _getFilteredItems(state.items),
                            selectedFilter: _selectedFilter,
                            searchQuery: _searchController.text.trim(),
                          );
                        } else if (option == 'all_matching') {
                          PurchasesActionsHelper.exportAllMatchingRecords(
                            context: context,
                            ref: ref,
                            selectedFilter: _selectedFilter,
                            searchQuery: _searchController.text.trim(),
                            onProgress: (isExporting, count) {
                              if (mounted) {
                                setState(() {
                                  _isExportingAll = isExporting;
                                  _exportFetchedCount = count;
                                });
                              }
                            },
                          );
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
              PurchasesFreshnessHeader(
                lastRefreshed: _lastRefreshed,
                recordCount: state.items.length,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
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
                      PurchasesCompletenessBanner(
                        isSampledOrPartial: state.isSampledOrPartial,
                        recordCount: state.items.length,
                        isDark: isDark,
                      ),
                      PurchasesKpiSection(isDark: isDark, metrics: metrics),
                      const SizedBox(height: 14),
                      PurchasesFilterBar(
                        selectedFilter: _selectedFilter,
                        searchController: _searchController,
                        isDark: isDark,
                        onFilterSelected: (key) {
                          setState(() => _selectedFilter = key);
                          ref
                              .read(adminPurchasesProvider.notifier)
                              .loadPurchases(filter: key);
                        },
                        onSearchSubmitted: (query) {
                          ref
                              .read(adminPurchasesProvider.notifier)
                              .loadPurchases(
                                filter: _selectedFilter,
                                search: query,
                              );
                        },
                      ),
                      const SizedBox(height: 12),
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
                                  child: PurchasesDataTable(
                                    items: filtered,
                                    isDark: isDark,
                                    isProcessingRefund: _isProcessingRefund,
                                    onRefundRequested: (item) {
                                      PurchasesActionsHelper.showRefundDialog(
                                        context: context,
                                        ref: ref,
                                        item: item,
                                        onProcessingChanged: (val) {
                                          if (mounted) {
                                            setState(
                                              () => _isProcessingRefund = val,
                                            );
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ),
                              );
                            }
                            return PurchasesDataTable(
                              items: filtered,
                              isDark: isDark,
                              isProcessingRefund: _isProcessingRefund,
                              onRefundRequested: (item) {
                                PurchasesActionsHelper.showRefundDialog(
                                  context: context,
                                  ref: ref,
                                  item: item,
                                  onProcessingChanged: (val) {
                                    if (mounted) {
                                      setState(() => _isProcessingRefund = val);
                                    }
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                      PurchasesPaginationFooter(
                        state: state,
                        onLoadNextPage: notifier.loadNextPage,
                        isDark: isDark,
                      ),
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
}
