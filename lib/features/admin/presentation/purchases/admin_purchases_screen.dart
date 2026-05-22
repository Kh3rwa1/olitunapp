import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../shared/providers/providers.dart';
import '../widgets/admin_section_header.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_form_widgets.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_glass_card.dart';
import '../analytics/admin_analytics_csv_exporter.dart';

class AdminPurchasesScreen extends ConsumerStatefulWidget {
  const AdminPurchasesScreen({super.key});

  @override
  ConsumerState<AdminPurchasesScreen> createState() =>
      _AdminPurchasesScreenState();
}

class _AdminPurchasesScreenState extends ConsumerState<AdminPurchasesScreen> {
  String _selectedFilter = 'all'; // 'all', 'razorpay', 'review', 'refunded'

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
                'Manage course unlocks, review metrics, and process refunds',
            icon: Icons.shopping_bag_rounded,
            eyebrow: 'PRODUCT OPS · MONETIZATION',
            actions: [
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

          const SizedBox(height: 24),

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

                // Compute metrics
                final totalRevenue = items
                    .where(
                      (p) =>
                          p.status == 'verified' &&
                          p.unlockMethod == 'razorpay',
                    )
                    .fold(0, (sum, p) => sum + p.amountPaidInr);

                final paidCount = items
                    .where(
                      (p) =>
                          p.unlockMethod == 'razorpay' &&
                          p.status == 'verified',
                    )
                    .length;
                final reviewCount = items
                    .where((p) => p.unlockMethod == 'play_store_review')
                    .length;
                final totalCount = items.length;
                final conversionRate = totalCount > 0
                    ? (paidCount / totalCount * 100).toStringAsFixed(1)
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
                      isDark,
                      isWideScreen,
                      totalRevenue,
                      paidCount,
                      reviewCount,
                      conversionRate,
                    ),
                    const SizedBox(height: 24),

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
                child: SelectableText(
                  'Error loading purchases: $error',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(
    bool isDark,
    bool isWide,
    int revenue,
    int paid,
    int reviews,
    String conversion,
  ) {
    final cardStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      fontFamily: 'Poppins',
      color: isDark ? Colors.white : Colors.black87,
    );

    final cards = [
      _KpiItem(
        title: 'Total Revenue',
        value: '₹$revenue',
        icon: Icons.currency_rupee_rounded,
        accentColor: Colors.green,
      ),
      _KpiItem(
        title: 'Paid Sales',
        value: paid.toString(),
        icon: Icons.payment_rounded,
        accentColor: Colors.blue,
      ),
      _KpiItem(
        title: 'Review Unlocks',
        value: reviews.toString(),
        icon: Icons.rate_review_rounded,
        accentColor: Colors.purple,
      ),
      _KpiItem(
        title: 'Paid Conv. Rate',
        value: '$conversion%',
        icon: Icons.insights_rounded,
        accentColor: Colors.orange,
      ),
    ];

    if (isWide) {
      return Row(
        children: cards
            .map(
              (c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildKpiCard(isDark, c, cardStyle),
                ),
              ),
            )
            .toList(),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: cards.map((c) => _buildKpiCard(isDark, c, cardStyle)).toList(),
    );
  }

  Widget _buildKpiCard(bool isDark, _KpiItem card, TextStyle cardStyle) {
    return AdminGlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                card.title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white60 : Colors.black54,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: card.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(card.icon, size: 16, color: card.accentColor),
              ),
            ],
          ),
          Text(card.value, style: cardStyle),
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
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.white70 : Colors.black87),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.05),
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
                  alpha: 0.15,
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
            '₹${item.amountPaidInr}',
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
                color: c.withValues(alpha: 0.15),
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
    final ok = await showAdminConfirmDialog(
      context: context,
      title: 'Refund Purchase',
      message:
          'Are you sure you want to refund this purchase? This will revoke user course access immediately.',
    );

    if (ok == true) {
      try {
        await ref.read(adminPurchasesProvider.notifier).refundPurchase(item.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Refund issued successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Refund failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _exportToCsv(
    BuildContext context,
    List<PurchaseModel> items,
  ) async {
    const header =
        'Purchase ID,User ID,Category ID,Unlock Method,Amount (INR),Razorpay Payment ID,Razorpay Order ID,Status,Purchased At,Verified At\n';

    String escape(String? val) {
      if (val == null) return '';
      if (val.contains(',') || val.contains('"') || val.contains('\n')) {
        return '"${val.replaceAll('"', '""')}"';
      }
      return val;
    }

    final rows = items
        .map((p) {
          return [
            escape(p.id),
            escape(p.userId),
            escape(p.categoryId),
            escape(p.unlockMethod),
            p.amountPaidInr.toString(),
            escape(p.razorpayPaymentId),
            escape(p.razorpayOrderId),
            escape(p.status),
            escape(p.purchasedAt),
            escape(p.verifiedAt),
          ].join(',');
        })
        .join('\n');

    final csv = header + rows;
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
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _KpiItem {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  _KpiItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });
}
